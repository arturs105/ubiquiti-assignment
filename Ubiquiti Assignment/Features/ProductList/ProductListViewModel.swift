import Combine
import Foundation

/// State and intents of the product list: the feed as a list of products, kept on screen across refreshes.
///
/// Inputs enter as subjects: the feed the repository streams, whether a refresh is in flight, and how the last
/// refresh ended. The screen state is a `CombineLatest` over the three and the stale error over two of them, so
/// no intent method computes a state by hand; see the Concurrency and Combine section of `docs/CODING_STANDARDS.md`.
/// `init` only wires the pipeline; `load()` starts the subscription and the first refresh.
@Observable
final class ProductListViewModel {
    /// What the screen shows.
    private(set) var state: LoadState<[Product]> = .loading
    /// Why the list on screen is stale: the refresh behind it failed. `nil` while the list has no rows, since the
    /// failure is then the state itself.
    private(set) var staleError: FeedError?
    /// A refresh is in flight; the stale banner shows a spinner in place of Retry.
    private(set) var isRefreshing = false

    private let repository: any FeedRepository
    private let feed = CurrentValueSubject<Feed?, Never>(nil)
    private let refreshing = CurrentValueSubject<Bool, Never>(false)
    private let refreshFailure = CurrentValueSubject<FeedError?, Never>(nil)
    // Plumbing, not state a view reads: kept out of observation so a task swap never invalidates a view.
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var feedTask: Task<Void, Never>?
    @ObservationIgnored private var refreshTask: Task<Void, Never>?

    /// - Parameter repository: the feed seam the list reads and refreshes through.
    init(repository: any FeedRepository) {
        self.repository = repository

        Publishers.CombineLatest3(
            feed.removeDuplicates { $0?.version == $1?.version },
            refreshing,
            refreshFailure,
        )
        .map(Self.state)
        .removeDuplicates()
        .sink { [weak self] state in self?.state = state }
        .store(in: &cancellables)

        Publishers.CombineLatest(feed, refreshFailure)
            .map { feed, failure in Self.visibleProducts(in: feed).isEmpty ? nil : failure }
            .removeDuplicates()
            .sink { [weak self] error in self?.staleError = error }
            .store(in: &cancellables)

        refreshing
            .removeDuplicates()
            .sink { [weak self] isRefreshing in self?.isRefreshing = isRefreshing }
            .store(in: &cancellables)
    }

    isolated deinit {
        feedTask?.cancel()
        refreshTask?.cancel()
    }

    // MARK: - Intents

    /// Subscribes to the feed, once, and refreshes it. The cached feed renders before the network answers.
    func load() {
        guard feedTask == nil else { return }
        feedTask = Task { [weak self, repository] in
            for await feed in await repository.feed() {
                guard let self else { return }
                self.feed.send(feed)
            }
        }
        refreshTask = startRefresh()
    }

    /// Asks the server for the feed and returns once it has answered; pull to refresh awaits it.
    func refresh() async {
        let task = startRefresh()
        refreshTask = task
        await task.value
    }

    /// Asks the server again after a failure, without waiting; the Retry button calls it.
    func retry() {
        refreshTask = startRefresh()
    }

    // MARK: - Private helpers

    private func startRefresh() -> Task<Void, Never> {
        refreshTask?.cancel()
        refreshing.send(true)
        return Task { [weak self, repository] in
            var failure: FeedError?
            do throws(FeedError) {
                _ = try await repository.refresh()
            } catch {
                failure = error
            }
            // A cancelled refresh was replaced by a newer one, which owns the state from here.
            guard let self, !Task.isCancelled else { return }
            refreshFailure.send(failure)
            refreshing.send(false)
        }
    }

    private static func state(feed: Feed?, isRefreshing: Bool, failure: FeedError?) -> LoadState<[Product]> {
        let products = visibleProducts(in: feed)
        guard products.isEmpty else { return .loaded(products) }
        // No rows to keep on screen, cached or not: the failure is the state until a retry is under way, which
        // reads as loading again. An empty list over a failed refresh would claim the catalogue is empty.
        if let failure {
            return isRefreshing ? .loading : .failed(failure)
        }
        return feed == nil ? .loading : .empty
    }

    /// The feed's two placeholder entries decode like any product; hiding them is this screen's rule.
    private static func visibleProducts(in feed: Feed?) -> [Product] {
        feed?.products.filter { $0.line.id != .unknown } ?? []
    }
}
