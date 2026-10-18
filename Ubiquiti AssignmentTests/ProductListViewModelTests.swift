import Foundation
import Testing
@testable import Ubiquiti_Assignment

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct ProductListViewModelTests {
    @Test func loadsTheDownloadedFeedWhenNothingIsCached() async {
        let viewModel = ProductListViewModel(repository: InMemoryFeedRepository(refresh: .updated(.preview)))

        #expect(viewModel.state == .loading)
        viewModel.load()
        await viewModel.refresh()

        #expect(await settles(viewModel, at: .loaded(Product.previews)))
        #expect(viewModel.staleError == nil)
        #expect(viewModel.isRefreshing == false)
    }

    @Test func loadRendersTheCachedFeedBeforeTheRefreshAnswers() async {
        let viewModel = ProductListViewModel(repository: InMemoryFeedRepository.neverAnswering(cached: .preview))

        viewModel.load()

        #expect(await settles(viewModel, at: .loaded(Product.previews)))
        #expect(viewModel.isRefreshing)
        #expect(viewModel.staleError == nil)
    }

    @Test func loadAloneReplacesTheCachedFeedWithTheRefreshedOne() async {
        let update = Feed(version: "v2", products: [Product.previews[0]])
        let repository = InMemoryFeedRepository(cached: .preview, refresh: .updated(update))
        let viewModel = ProductListViewModel(repository: repository)

        viewModel.load()

        // The new rows and the end of the refresh arrive through two tasks in either order, so wait for both.
        #expect(await settles(viewModel) { $0.state == .loaded([Product.previews[0]]) && !$0.isRefreshing })
        #expect(viewModel.staleError == nil)
    }

    @Test func keepsTheCachedFeedAsStaleWhenTheRefreshFails() async {
        let repository = InMemoryFeedRepository(cached: .preview, error: offline)
        let viewModel = ProductListViewModel(repository: repository)

        viewModel.load()
        await viewModel.refresh()

        #expect(await settles(viewModel, at: .loaded(Product.previews)))
        #expect(viewModel.staleError == offline)
        #expect(viewModel.isRefreshing == false)
    }

    @Test func failsWhenNothingIsCachedAndTheRefreshFails() async {
        let viewModel = ProductListViewModel(repository: InMemoryFeedRepository(error: offline))

        viewModel.load()
        await viewModel.refresh()

        #expect(await settles(viewModel, at: .failed(offline)))
        #expect(viewModel.staleError == nil)
    }

    @Test func anUnchangedRefreshLeavesTheCachedFeedCurrent() async {
        let viewModel = ProductListViewModel(repository: InMemoryFeedRepository(cached: .preview, refresh: .unchanged))

        viewModel.load()
        await viewModel.refresh()

        #expect(await settles(viewModel, at: .loaded(Product.previews)))
        #expect(viewModel.staleError == nil)
    }

    @Test func aFeedWithNoProductsIsEmpty() async {
        let empty = Feed(version: "empty", products: [])
        let viewModel = ProductListViewModel(repository: InMemoryFeedRepository(refresh: .updated(empty)))

        viewModel.load()
        await viewModel.refresh()

        #expect(await settles(viewModel, at: .empty))
        #expect(viewModel.isCatalogueEmpty)
    }

    @Test func anEmptyCatalogueIsEmptyOnEveryTab() async {
        // The screen must not suggest another tab when every tab is empty.
        let empty = Feed(version: "empty", products: [])
        let viewModel = ProductListViewModel(repository: InMemoryFeedRepository(refresh: .updated(empty)))
        viewModel.select(category: .cameras)

        viewModel.load()
        await viewModel.refresh()

        #expect(await settles(viewModel, at: .empty))
        #expect(viewModel.isCatalogueEmpty)
    }

    @Test func placeholderProductsAreShownLikeAnyOther() async {
        let feed = Feed(version: "placeholders", products: [Product.placeholder] + Product.previews)
        let viewModel = ProductListViewModel(repository: InMemoryFeedRepository(refresh: .updated(feed)))

        viewModel.load()
        await viewModel.refresh()

        #expect(await settles(viewModel, at: .loaded(feed.products)))
    }

    @Test func aRefreshThatFailsOverAnEmptyFeedIsAnError() {
        // Through the view model, no feed and a failure is `.failed` too, so a state reached before the cached feed
        // lands would pass without exercising this mapping; the mapping is asserted on its own instead.
        let empty = Feed(version: "empty", products: [])
        let state = ProductListViewModel.state(feed: empty, category: .all, isRefreshing: false, failure: offline)

        #expect(state == .failed(offline))
    }

    @Test func anUpdateNobodyOnScreenAskedForReplacesTheList() async {
        let repository = InMemoryFeedRepository(cached: .preview, refresh: .unchanged)
        let viewModel = ProductListViewModel(repository: repository)
        viewModel.load()
        await viewModel.refresh()
        #expect(await settles(viewModel, at: .loaded(Product.previews)))

        let update = Feed(version: "v2", products: [Product.previews[0]])
        await repository.publish(update)

        #expect(await settles(viewModel, at: .loaded([Product.previews[0]])))
    }

    @Test func aRetryFromTheErrorStateReadsAsLoadingUntilItFails() async {
        let viewModel = ProductListViewModel(repository: InMemoryFeedRepository(error: offline))
        viewModel.load()
        await viewModel.refresh()
        #expect(await settles(viewModel, at: .failed(offline)))

        viewModel.retry()

        #expect(viewModel.state == .loading)
        #expect(viewModel.isRefreshing)
        #expect(await settles(viewModel, at: .failed(offline)))
        #expect(viewModel.isRefreshing == false)
    }

    @Test func aPullWhileARefreshIsInFlightJoinsIt() async {
        let repository = InMemoryFeedRepository(cached: .preview, refresh: .unchanged)
        let viewModel = ProductListViewModel(repository: repository)

        viewModel.load()
        await viewModel.refresh()

        #expect(await repository.refreshCount == 1)
        #expect(viewModel.isRefreshing == false)
    }

    @Test func aPullAfterARefreshHasEndedAsksAgain() async {
        let repository = InMemoryFeedRepository(cached: .preview, refresh: .unchanged)
        let viewModel = ProductListViewModel(repository: repository)

        viewModel.load()
        await viewModel.refresh()
        await viewModel.refresh()

        #expect(await repository.refreshCount == 2)
    }

    @Test func loadingTwiceRefreshesOnce() async {
        let repository = InMemoryFeedRepository(cached: .preview, refresh: .unchanged)
        let viewModel = ProductListViewModel(repository: repository)

        viewModel.load()
        viewModel.load()

        #expect(await settles(viewModel) { $0.state == .loaded(Product.previews) && !$0.isRefreshing })
        #expect(await repository.refreshCount == 1)
    }

    @Test func startsOnTheAllTab() {
        let viewModel = ProductListViewModel(repository: InMemoryFeedRepository(refresh: .unchanged))

        #expect(viewModel.selectedCategory == .all)
    }

    @Test func selectingATabFiltersTheListAtOnce() async {
        let viewModel = ProductListViewModel(repository: InMemoryFeedRepository(cached: .preview, refresh: .unchanged))
        viewModel.load()
        await viewModel.refresh()
        #expect(await settles(viewModel, at: .loaded(Product.previews)))

        viewModel.select(category: .cameras)

        // No `settles`: the tab is an input the pipeline answers synchronously, so the list never lags the tap.
        #expect(viewModel.selectedCategory == .cameras)
        #expect(viewModel.state == .loaded([Product.previews[0]]))

        viewModel.select(category: .iot)
        #expect(viewModel.state == .loaded([Product.previews[2]]))

        viewModel.select(category: .all)
        #expect(viewModel.state == .loaded(Product.previews))
    }

    @Test func aTabWithNoProductsIsEmptyWhileTheCatalogueIsNot() async {
        let networkOnly = Feed(version: "network", products: [Product.previews[1]])
        let viewModel = ProductListViewModel(repository: InMemoryFeedRepository(
            cached: networkOnly,
            refresh: .unchanged,
        ))
        viewModel.load()
        await viewModel.refresh()
        #expect(await settles(viewModel, at: .loaded([Product.previews[1]])))

        viewModel.select(category: .cameras)

        #expect(viewModel.state == .empty)
        #expect(viewModel.isCatalogueEmpty == false)
    }

    @Test func aTabWithNoProductsStaysEmptyWhenTheRefreshFailed() {
        // The catalogue has rows, just none under this tab: the failure is not the state, the user can switch tabs.
        let networkOnly = Feed(version: "network", products: [Product.previews[1]])
        let state = ProductListViewModel.state(
            feed: networkOnly,
            category: .cameras,
            isRefreshing: false,
            failure: offline,
        )

        #expect(state == .empty)
    }

    @Test func aFeedArrivingLaterIsFilteredByTheSelectedTab() async {
        let repository = InMemoryFeedRepository(refresh: .updated(.preview))
        let viewModel = ProductListViewModel(repository: repository)
        viewModel.select(category: .iot)

        viewModel.load()
        await viewModel.refresh()

        #expect(await settles(viewModel, at: .loaded([Product.previews[2]])))
    }

    private let offline = FeedError.network(.network(URLError(.notConnectedToInternet)))
}
