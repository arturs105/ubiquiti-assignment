import Combine
import Foundation

/// State and intents of the product list: the feed filtered by the selected tab and the checked lines, kept on
/// screen across refreshes.
///
/// Inputs enter as subjects: the feed the repository streams, the filter (the selected category and the checked
/// lines, one `ProductFilter` so a tab change is one send), whether a refresh is in flight, and how the last refresh
/// ended. The lines the menu offers derive from feed and category, the filter the list applies is the input filter
/// narrowed to those lines, the screen state is a `CombineLatest` over the feed, that filter and how the last
/// refresh ended, and the stale error over the feed and that outcome, so no intent method computes a state by hand;
/// see the Concurrency and Combine section of `docs/CODING_STANDARDS.md`. Whether a refresh is in flight feeds only
/// `isRefreshing`, which the views read beside the state. `init` only wires the pipeline; `load()` starts the
/// subscription and the first refresh. The rows' thumbnails are built here too, so the views never see the image
/// loader.
@Observable
final class ProductListViewModel {
    /// What the screen shows: the products under the selected tab.
    private(set) var state: LoadState<[Product]> = .loading
    /// The tab the list is filtered by.
    private(set) var selectedCategory: ProductCategory = .all
    /// The lines checked in the filter menu, among those it offers; empty means every line under the tab.
    private(set) var selectedLines: Set<Line.ID> = []
    /// The lines the filter menu offers: Figma's four, those of them with a product under the selected tab, in
    /// Figma's order.
    private(set) var availableLines: [Line] = []
    /// The feed on screen has no products at all, so an `empty` state is the catalogue's, not the tab's.
    private(set) var isCatalogueEmpty = false
    /// Why the list on screen is stale, as the user reads it: the refresh behind it failed. `nil` while the feed has
    /// no rows, since the failure is then the state itself.
    private(set) var staleError: DisplayError?
    /// A refresh is in flight; the stale banner and the error view show a spinner in place of Retry.
    private(set) var isRefreshing = false

    private let repository: any FeedRepository
    private let imageLoader: any ImageLoader
    private let feedSubject = CurrentValueSubject<Feed?, Never>(nil)
    private let filterSubject = CurrentValueSubject<ProductFilter, Never>(ProductFilter(category: .all))
    private let refreshingSubject = CurrentValueSubject<Bool, Never>(false)
    private let refreshFailureSubject = CurrentValueSubject<FeedError?, Never>(nil)
    // Plumbing, not state a view reads: kept out of observation so a task swap never invalidates a view.
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var feedTask: Task<Void, Never>?
    @ObservationIgnored private var refreshTask: Task<Void, Never>?

    init(repository: any FeedRepository, imageLoader: any ImageLoader) {
        self.repository = repository
        self.imageLoader = imageLoader

        let feed = feedSubject.removeDuplicates { $0?.version == $1?.version }
        let category = filterSubject.map(\.category).removeDuplicates()
        let availableLines = Publishers.CombineLatest(feed, category)
            .map(Self.lines)
            .removeDuplicates()
        // A checked line an update dropped from the tab unchecks itself: the menu would have no entry for it.
        let filter = Publishers.CombineLatest(filterSubject, availableLines)
            .map { filter, lines in filter.keeping(lines.map(\.id)) }
            .removeDuplicates()

        // A refresh that succeeds with nothing on screen clears its failure before the stream task delivers the feed,
        // in an order the scheduler picks; the failure is held until a feed is present, so the screen stays on the
        // error view through that gap instead of flashing the loading view. The hold is a `scan` over the same tuple
        // the state maps, not a publisher of its own beside it: a subject delivers to its subscribers in no fixed
        // order, so a second subscription to the feed could clear the failure before the state saw the feed.
        Publishers.CombineLatest3(feed, filter, refreshFailureSubject)
            .scan((failure: FeedError?.none, state: LoadState<[Product]>.loading)) { last, input in
                let (feed, filter, refreshFailure) = input
                let failure = Self.failure(held: last.failure, feed: feed, refreshFailure: refreshFailure)
                return (failure, Self.state(feed: feed, filter: filter, failure: failure))
            }
            .map(\.state)
            .removeDuplicates()
            .sink { [weak self] state in self?.state = state }
            .store(in: &cancellables)

        category
            .sink { [weak self] category in self?.selectedCategory = category }
            .store(in: &cancellables)

        filter
            .map(\.lines)
            .removeDuplicates()
            .sink { [weak self] lines in self?.selectedLines = lines }
            .store(in: &cancellables)

        availableLines
            .sink { [weak self] lines in self?.availableLines = lines }
            .store(in: &cancellables)

        feedSubject
            .map { $0?.products.isEmpty ?? false }
            .removeDuplicates()
            .sink { [weak self] isEmpty in self?.isCatalogueEmpty = isEmpty }
            .store(in: &cancellables)

        Publishers.CombineLatest(feedSubject, refreshFailureSubject)
            .map { feed, failure in (feed?.products.isEmpty ?? true) ? nil : failure.map(DisplayError.init) }
            .removeDuplicates()
            .sink { [weak self] error in self?.staleError = error }
            .store(in: &cancellables)

        refreshingSubject
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
                feedSubject.send(feed)
            }
        }
        startRefresh()
    }

    /// Asks the server for the feed and returns once it has answered; pull to refresh awaits it. A refresh already
    /// in flight is joined, not restarted, so the pull's spinner ends when the server has answered.
    func refresh() async {
        await startRefresh().value
    }

    /// Asks the server again after a failure, without waiting; the Retry button calls it.
    func retry() {
        startRefresh()
    }

    /// Filters the list by `category`. The pipeline answers synchronously, so the list changes with the tap. The
    /// checked lines are cleared: a line checked under one tab says nothing about another, and the new tab's menu
    /// offers a different set. One send, so the pipeline sees one filter change.
    func select(category: ProductCategory) {
        guard category != filterSubject.value.category else { return }
        filterSubject.send(ProductFilter(category: category))
    }

    /// Checks `line` in the filter menu, or unchecks it when it is on. Synchronous like `select(category:)`. Starts
    /// from the lines on screen, so a line the pipeline already unchecked does not come back.
    func toggle(line: Line.ID) {
        var lines = selectedLines
        if lines.remove(line) == nil {
            lines.insert(line)
        }
        filterSubject.send(ProductFilter(category: filterSubject.value.category, lines: lines))
    }

    // MARK: - Child view models

    /// The thumbnail slot of one row. Built on every render of the row and kept by its view as `@State`, like the
    /// screen view models the root builds; see `docs/DECISIONS.md`, 2026-10-19.
    func thumbnailViewModel(for product: Product) -> ProductImageViewModel {
        ProductImageViewModel(product: product, size: .thumbnail, loader: imageLoader)
    }

    // MARK: - Private helpers

    @discardableResult
    private func startRefresh() -> Task<Void, Never> {
        if let refreshTask {
            return refreshTask
        }
        refreshingSubject.send(true)
        let task = Task { [weak self, repository] in
            var failure: FeedError?
            do throws(FeedError) {
                _ = try await repository.refresh()
            } catch {
                failure = error
            }
            // Only `deinit` cancels a refresh, and by then there is no view model to update.
            guard let self else { return }
            refreshTask = nil
            refreshFailureSubject.send(failure)
            refreshingSubject.send(false)
        }
        // The task cannot run before this assignment: both are on the main actor and this method does not suspend.
        refreshTask = task
        return task
    }

    /// The state pipeline's `map`, internal so tests can pin a mapping whose inputs arrive through two tasks in an
    /// order the scheduler picks.
    static func state(
        feed: Feed?,
        filter: ProductFilter,
        failure: FeedError?,
    ) -> LoadState<[Product]> {
        let catalogue = feed?.products ?? []
        let products = catalogue.filter(filter.contains)
        guard products.isEmpty else { return .loaded(products) }
        // Rows exist, just none under this tab or these lines: the user widens the filter, and a failed refresh has
        // nothing to add.
        guard catalogue.isEmpty else { return .empty }
        // No rows to keep on screen, cached or not: the failure is the state, through a retry too, so the error view
        // shows the retry in place instead of giving way to the loading view and coming back on a second failure.
        // An empty list over a failed refresh would claim the catalogue is empty.
        if let failure {
            return .failed(DisplayError(failure))
        }
        return feed == nil ? .loading : .empty
    }

    /// The failure the state reads: how the last refresh ended, except that a success over no feed keeps the
    /// failure `held` until the feed it downloaded arrives through the stream. Internal, like `state`, so a test can
    /// pin the order in which the two tasks deliver.
    static func failure(held: FeedError?, feed: Feed?, refreshFailure: FeedError?) -> FeedError? {
        guard refreshFailure == nil, feed == nil else { return refreshFailure }
        return held
    }

    /// The menu's lines (`ProductFilter.menuLines`) that have a product under `category`, in the menu's order.
    static func lines(feed: Feed?, category: ProductCategory) -> [Line] {
        let present = (feed?.products ?? []).filter(category.contains).map(\.line)
        return ProductFilter.menuLines.compactMap { id in present.first { $0.id == id } }
    }
}
