import Combine
import Foundation

/// State and intents of the product details: one product, looked up by id in the feed the repository streams.
///
/// Inputs enter as subjects, as in the list: the feed, whether a refresh is in flight, and how the last refresh
/// ended. The screen state is a `CombineLatest` over the three, so no intent method computes a state by hand; see
/// the Concurrency and Combine section of `docs/CODING_STANDARDS.md`. The list refreshed on its way here, so
/// `load()` only subscribes and asks the server again when the cached feed does not hold the product; see
/// `docs/DECISIONS.md`, 2026-10-18 "The details screen refreshes only when its product is missing". The hero
/// image's slot is built here too, so the views never see the image loader.
@Observable
final class ProductDetailViewModel {
    private(set) var state: LoadState<Product> = .loading

    private let productID: Product.ID
    private let repository: any FeedRepository
    private let imageLoader: any ImageLoader
    private let feedSubject = CurrentValueSubject<Feed?, Never>(nil)
    private let refreshingSubject = CurrentValueSubject<Bool, Never>(false)
    private let refreshFailureSubject = CurrentValueSubject<FeedError?, Never>(nil)
    // Plumbing, not state a view reads: kept out of observation so a task swap never invalidates a view.
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var feedTask: Task<Void, Never>?
    @ObservationIgnored private var refreshTask: Task<Void, Never>?

    init(productID: Product.ID, repository: any FeedRepository, imageLoader: any ImageLoader) {
        self.productID = productID
        self.repository = repository
        self.imageLoader = imageLoader

        Publishers.CombineLatest3(
            feedSubject.removeDuplicates { $0?.version == $1?.version },
            refreshingSubject,
            refreshFailureSubject,
        )
        .map { [productID] feed, isRefreshing, failure in
            Self.state(productID: productID, feed: feed, isRefreshing: isRefreshing, failure: failure)
        }
        .removeDuplicates()
        .sink { [weak self] state in self?.state = state }
        .store(in: &cancellables)
    }

    isolated deinit {
        feedTask?.cancel()
        refreshTask?.cancel()
    }

    // MARK: - Intents

    /// Subscribes to the feed, once. The server is asked only when the feed the subscription opens with does not
    /// hold the product: the list refreshed a moment ago, so a conditional request would otherwise buy nothing.
    func load() {
        guard feedTask == nil else { return }
        feedTask = Task { [weak self, repository] in
            var isFirst = true
            for await feed in await repository.feed() {
                guard let self else { return }
                // The refresh flag goes up before the feed lacking the product goes in, so the pipeline never
                // emits empty for a feed the server is about to be asked about.
                if isFirst, !(feed?.products.contains { $0.id == productID } ?? false) {
                    startRefresh()
                }
                isFirst = false
                feedSubject.send(feed)
            }
        }
    }

    /// Asks the server again after a failure, without waiting; the Retry button calls it.
    func retry() {
        startRefresh()
    }

    // MARK: - Child view models

    /// The hero slot at the top of the loaded screen. Built on every render of the content and kept by its view as
    /// `@State`, like the rows' thumbnails; see `docs/DECISIONS.md`, 2026-10-19.
    func heroViewModel(for product: Product) -> ProductImageViewModel {
        ProductImageViewModel(product: product, size: .hero, loader: imageLoader)
    }

    // MARK: - Private helpers

    private func startRefresh() {
        guard refreshTask == nil else { return }
        refreshingSubject.send(true)
        refreshTask = Task { [weak self, repository] in
            var refreshed: Feed?
            var failure: FeedError?
            do throws(FeedError) {
                if case let .updated(feed) = try await repository.refresh() {
                    refreshed = feed
                }
            } catch {
                failure = error
            }
            // Only `deinit` cancels a refresh, and by then there is no view model to update.
            guard let self else { return }
            refreshTask = nil
            // The stream delivers the same feed on the feed task, in an order the scheduler picks; sending it here
            // first means the flag never clears over the old feed, and the stream's copy is dropped by version.
            if let refreshed {
                feedSubject.send(refreshed)
            }
            refreshFailureSubject.send(failure)
            refreshingSubject.send(false)
        }
    }

    /// The state pipeline's `map`: the product when the feed holds it; otherwise loading while the server is being
    /// asked, the failure when it could not be reached, or empty once it has answered without the product.
    private static func state(
        productID: Product.ID,
        feed: Feed?,
        isRefreshing: Bool,
        failure: FeedError?,
    ) -> LoadState<Product> {
        if let product = feed?.products.first(where: { $0.id == productID }) {
            return .loaded(product)
        }
        if isRefreshing {
            return .loading
        }
        if let failure {
            return .failed(failure)
        }
        return feed == nil ? .loading : .empty
    }
}
