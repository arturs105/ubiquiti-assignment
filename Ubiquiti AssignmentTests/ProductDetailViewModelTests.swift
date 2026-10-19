import Foundation
import Testing
@testable import Ubiquiti_Assignment

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct ProductDetailViewModelTests {
    @Test func showsTheProductFromTheCachedFeedWithoutAskingTheServer() async {
        let repository = InMemoryFeedRepository(cached: .preview, refresh: .unchanged)
        let viewModel = makeViewModel(repository: repository)

        #expect(viewModel.state == .loading)
        viewModel.load()

        #expect(await settles(viewModel, at: .loaded(camera)))
        #expect(await repository.refreshCount == 0)
    }

    @Test func asksTheServerWhenTheCachedFeedDoesNotHoldTheProduct() async {
        let others = Feed(version: "v1", products: Array(Product.previews.dropFirst()))
        let repository = InMemoryFeedRepository(cached: others, refresh: .updated(.preview))
        let viewModel = makeViewModel(repository: repository)

        viewModel.load()

        #expect(await settles(viewModel, at: .loaded(camera)))
        #expect(await repository.refreshCount == 1)
    }

    @Test func isEmptyWhenTheServerConfirmsAFeedWithoutTheProduct() async {
        let others = Feed(version: "v1", products: Array(Product.previews.dropFirst()))
        let repository = InMemoryFeedRepository(cached: others, refresh: .unchanged)
        let viewModel = makeViewModel(repository: repository)

        viewModel.load()

        #expect(await settles(viewModel, at: .empty))
        #expect(await repository.refreshCount == 1)
    }

    @Test func readsAsLoadingWhileTheServerIsAskedForAProductTheCacheLacks() async {
        let others = Feed(version: "v1", products: Array(Product.previews.dropFirst()))
        let repository = InMemoryFeedRepository.neverAnswering(cached: others)
        let viewModel = makeViewModel(repository: repository)

        viewModel.load()
        // The cached feed reaches the pipeline before the refresh starts, so once the server is asked the screen
        // has seen a feed without the product and must still read as loading.
        while await repository.refreshCount == 0 {
            try? await Task.sleep(for: Settling.interval)
        }

        #expect(viewModel.state == .loading)
        #expect(await repository.refreshCount == 1)
    }

    @Test func failsWhenNothingIsCachedAndTheRefreshFails() async {
        let viewModel = makeViewModel(repository: InMemoryFeedRepository(error: offline))

        viewModel.load()

        #expect(await settles(viewModel, at: .failed(offline)))
    }

    @Test func aRetryFromTheErrorStateReadsAsLoadingUntilItFails() async {
        let viewModel = makeViewModel(repository: InMemoryFeedRepository(error: offline))
        viewModel.load()
        #expect(await settles(viewModel, at: .failed(offline)))

        viewModel.retry()

        #expect(viewModel.state == .loading)
        #expect(await settles(viewModel, at: .failed(offline)))
    }

    @Test func anUpdateAfterAFailureLoadsTheProduct() async {
        let repository = InMemoryFeedRepository(result: .failure(offline))
        let viewModel = makeViewModel(repository: repository)
        viewModel.load()
        #expect(await settles(viewModel, at: .failed(offline)))

        await repository.publish(.preview)

        #expect(await settles(viewModel, at: .loaded(camera)))
    }

    @Test func anUpdateNobodyOnScreenAskedForReplacesTheProduct() async {
        let repository = InMemoryFeedRepository(cached: .preview, refresh: .unchanged)
        let viewModel = makeViewModel(repository: repository)
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
        let viewModel = makeViewModel(repository: repository)
        viewModel.load()
        #expect(await settles(viewModel, at: .loaded(camera)))

        await repository.publish(Feed(version: "v2", products: Array(Product.previews.dropFirst())))

        #expect(await settles(viewModel, at: .empty))
    }

    @Test func loadingTwiceRefreshesOnce() async {
        let repository = InMemoryFeedRepository(refresh: .updated(.preview))
        let viewModel = makeViewModel(repository: repository)

        viewModel.load()
        viewModel.load()

        #expect(await settles(viewModel, at: .loaded(camera)))
        #expect(await repository.refreshCount == 1)
    }

    @Test func theHeroSlotAsksTheLoaderForTheHeroOfItsProduct() async {
        let loader = InMemoryImageLoader()
        let viewModel = ProductDetailViewModel(
            productID: camera.id,
            repository: InMemoryFeedRepository(cached: .preview, refresh: .unchanged),
            imageLoader: loader,
        )

        await viewModel.heroViewModel(for: camera).load()

        #expect(loader.requests == [InMemoryImageLoader.Request(productID: camera.id, size: .hero)])
    }

    private let camera = Product.previews[0]
    private let offline = FeedError.network(.network(URLError(.notConnectedToInternet)))

    private func makeViewModel(repository: any FeedRepository) -> ProductDetailViewModel {
        ProductDetailViewModel(productID: camera.id, repository: repository, imageLoader: InMemoryImageLoader())
    }
}
