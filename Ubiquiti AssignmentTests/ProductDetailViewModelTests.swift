import Foundation
import Testing
@testable import Ubiquiti_Assignment

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct ProductDetailViewModelTests {
    @Test func showsTheProductFromTheCachedFeedWithoutAskingTheServer() async {
        let repository = InMemoryFeedRepository(cached: .preview, refresh: .unchanged)
        let viewModel = ProductDetailViewModel(productID: camera.id, repository: repository)

        #expect(viewModel.state == .loading)
        viewModel.load()

        #expect(await settles(viewModel, at: .loaded(camera)))
        #expect(await repository.refreshCount == 0)
    }

    @Test func asksTheServerWhenTheCachedFeedDoesNotHoldTheProduct() async {
        let others = Feed(version: "v1", products: Array(Product.previews.dropFirst()))
        let repository = InMemoryFeedRepository(cached: others, refresh: .updated(.preview))
        let viewModel = ProductDetailViewModel(productID: camera.id, repository: repository)

        viewModel.load()

        #expect(await settles(viewModel, at: .loaded(camera)))
        #expect(await repository.refreshCount == 1)
    }

    @Test func isEmptyWhenTheServerConfirmsAFeedWithoutTheProduct() async {
        let others = Feed(version: "v1", products: Array(Product.previews.dropFirst()))
        let repository = InMemoryFeedRepository(cached: others, refresh: .unchanged)
        let viewModel = ProductDetailViewModel(productID: camera.id, repository: repository)

        viewModel.load()

        #expect(await settles(viewModel, at: .empty))
    }

    @Test func failsWhenNothingIsCachedAndTheRefreshFails() async {
        let viewModel = ProductDetailViewModel(productID: camera.id, repository: InMemoryFeedRepository(error: offline))

        viewModel.load()

        #expect(await settles(viewModel, at: .failed(offline)))
    }

    @Test func aRetryFromTheErrorStateReadsAsLoadingUntilItFails() async {
        let viewModel = ProductDetailViewModel(productID: camera.id, repository: InMemoryFeedRepository(error: offline))
        viewModel.load()
        #expect(await settles(viewModel, at: .failed(offline)))

        viewModel.retry()

        #expect(viewModel.state == .loading)
        #expect(await settles(viewModel, at: .failed(offline)))
    }

    @Test func anUpdateAfterAFailureLoadsTheProduct() async {
        let repository = InMemoryFeedRepository(result: .failure(offline))
        let viewModel = ProductDetailViewModel(productID: camera.id, repository: repository)
        viewModel.load()
        #expect(await settles(viewModel, at: .failed(offline)))

        await repository.publish(.preview)

        #expect(await settles(viewModel, at: .loaded(camera)))
    }

    @Test func anUpdateNobodyOnScreenAskedForReplacesTheProduct() async {
        let repository = InMemoryFeedRepository(cached: .preview, refresh: .unchanged)
        let viewModel = ProductDetailViewModel(productID: camera.id, repository: repository)
        viewModel.load()
        #expect(await settles(viewModel, at: .loaded(camera)))

        let renamed = Product(
            id: camera.id,
            name: "Camera G3 Dome Mk II",
            abbreviation: camera.abbreviation,
            sku: camera.sku,
            deviceType: camera.deviceType,
            defaultImageID: camera.defaultImageID,
            line: camera.line,
        )
        await repository.publish(Feed(version: "v2", products: [renamed]))

        #expect(await settles(viewModel, at: .loaded(renamed)))
    }

    @Test func anUpdateThatDropsTheProductIsEmpty() async {
        let repository = InMemoryFeedRepository(cached: .preview, refresh: .unchanged)
        let viewModel = ProductDetailViewModel(productID: camera.id, repository: repository)
        viewModel.load()
        #expect(await settles(viewModel, at: .loaded(camera)))

        await repository.publish(Feed(version: "v2", products: Array(Product.previews.dropFirst())))

        #expect(await settles(viewModel, at: .empty))
    }

    @Test func loadingTwiceRefreshesOnce() async {
        let repository = InMemoryFeedRepository(refresh: .updated(.preview))
        let viewModel = ProductDetailViewModel(productID: camera.id, repository: repository)

        viewModel.load()
        viewModel.load()

        #expect(await settles(viewModel, at: .loaded(camera)))
        #expect(await repository.refreshCount == 1)
    }

    private let camera = Product.previews[0]
    private let offline = FeedError.network(.network(URLError(.notConnectedToInternet)))
}
