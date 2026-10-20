import Foundation
import Testing
@testable import Ubiquiti_Assignment

@MainActor
struct ProductDetailViewModelTests {
    @Test func showsTheProductItWasGiven() {
        let viewModel = ProductDetailViewModel(product: camera, imageLoader: InMemoryImageLoader())

        #expect(viewModel.product == camera)
    }

    @Test func theHeroSlotAsksTheLoaderForTheHeroOfItsProduct() async {
        let loader = InMemoryImageLoader()
        let viewModel = ProductDetailViewModel(product: camera, imageLoader: loader)

        await viewModel.hero.load()

        #expect(loader.requests == [InMemoryImageLoader.Request(productID: camera.id, size: .hero)])
    }

    private let camera = Product.previews[0]
}
