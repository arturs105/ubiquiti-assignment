import Combine
import Foundation

/// State and intents of the product list: the feed filtered by the selected tab and the checked lines, kept on
/// screen across refreshes.
///
/// Inputs enter as subjects: the feed the repository streams, the selected category, the checked lines, whether a
/// refresh is in flight, and how the last refresh ended. Category and lines combine into one `ProductFilter`, the
/// screen state is a `CombineLatest` over the feed, the filter and the two refresh inputs, and the stale error over
/// two of them, so no intent method computes a state by hand; see the Concurrency and Combine section of
/// `docs/CODING_STANDARDS.md`. `init` only wires the pipeline; `load()` starts the subscription and the first refresh.
@Observable
final class ProductListViewModel {
    /// What the screen shows: the products under the selected tab.
    private(set) var state: LoadState<[Product]> = .loading
    /// The tab the list is filtered by.
    private(set) var selectedCategory: ProductCategory = .all
    /// The lines checked in the filter menu; empty means every line under the tab.
    private(set) var selectedLines: Set<Line.ID> = []
    /// The lines the filter menu offers: those with a product under the selected tab, in the order the feed first
    /// lists them.
    private(set) var availableLines: [Line] = []
    /// The feed on screen has no products at all, so an `empty` state is the catalogue's, not the tab's.
    private(set) var isCatalogueEmpty = false
    /// Why the list on screen is stale: the refresh behind it failed. `nil` while the list has no rows, since the
    /// failure is then the state itself.
    private(set) var staleError: FeedError?
    /// A refresh is in flight; the stale banner shows a spinner in place of Retry.
    private(set) var isRefreshing = false

    private let repository: any FeedRepository
    private let feedSubject = CurrentValueSubject<Feed?, Never>(nil)
    private let categorySubject = CurrentValueSubject<ProductCategory, Never>(.all)
    private let linesSubject = CurrentValueSubject<Set<Line.ID>, Never>([])
    private let refreshingSubject = CurrentValueSubject<Bool, Never>(false)
    private let refreshFailureSubject = CurrentValueSubject<FeedError?, Never>(nil)
    // Plumbing, not state a view reads: kept out of observation so a task swap never invalidates a view.
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var feedTask: Task<Void, Never>?
    @ObservationIgnored private var refreshTask: Task<Void, Never>?

    /// - Parameter repository: the feed seam the list reads and refreshes through.
    init(repository: any FeedRepository) {
        self.repository = repository

        let feed = feedSubject.removeDuplicates { $0?.version == $1?.version }
        let filter = Publishers.CombineLatest(categorySubject, linesSubject)
            .map(ProductFilter.init)
            .removeDuplicates()

        Publishers.CombineLatest4(feed, filter, refreshingSubject, refreshFailureSubject)
            .map(Self.state)
            .removeDuplicates()
            .sink { [weak self] state in self?.state = state }
            .store(in: &cancellables)

        categorySubject
            .removeDuplicates()
            .sink { [weak self] category in self?.selectedCategory = category }
            .store(in: &cancellables)

        linesSubject
            .removeDuplicates()
            .sink { [weak self] lines in self?.selectedLines = lines }
            .store(in: &cancellables)

        Publishers.CombineLatest(feed, categorySubject)
            .map(Self.lines)
            .removeDuplicates()
            .sink { [weak self] lines in self?.availableLines = lines }
            .store(in: &cancellables)

        feedSubject
            .map { $0?.products.isEmpty ?? false }
            .removeDuplicates()
            .sink { [weak self] isEmpty in self?.isCatalogueEmpty = isEmpty }
            .store(in: &cancellables)

        Publishers.CombineLatest(feedSubject, refreshFailureSubject)
            .map { feed, failure in (feed?.products.isEmpty ?? true) ? nil : failure }
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
    /// offers a different set.
    func select(category: ProductCategory) {
        guard category != categorySubject.value else { return }
        linesSubject.send([])
        categorySubject.send(category)
    }

    /// Checks `line` in the filter menu, or unchecks it when it is on. Synchronous like `select(category:)`.
    func toggle(line: Line.ID) {
        var lines = linesSubject.value
        if lines.remove(line) == nil {
            lines.insert(line)
        }
        linesSubject.send(lines)
    }

    // MARK: - Private helpers

    /// The refresh in flight, or a new one when none is.
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
        isRefreshing: Bool,
        failure: FeedError?,
    ) -> LoadState<[Product]> {
        let catalogue = feed?.products ?? []
        let products = catalogue.filter(filter.contains)
        guard products.isEmpty else { return .loaded(products) }
        // Rows exist, just none under this tab or these lines: the user widens the filter, and a failed refresh has
        // nothing to add.
        guard catalogue.isEmpty else { return .empty }
        // No rows to keep on screen, cached or not: the failure is the state until a retry is under way, which
        // reads as loading again. An empty list over a failed refresh would claim the catalogue is empty.
        if let failure {
            return isRefreshing ? .loading : .failed(failure)
        }
        return feed == nil ? .loading : .empty
    }

    /// The lines under `category`, each once, in the order the feed first lists a product of theirs.
    static func lines(feed: Feed?, category: ProductCategory) -> [Line] {
        var seen: Set<Line.ID> = []
        return (feed?.products ?? [])
            .filter(category.contains)
            .map(\.line)
            .filter { seen.insert($0.id).inserted }
    }
}
