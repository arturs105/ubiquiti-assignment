import Foundation
import Testing
import UIKit
@testable import Ubiquiti_Assignment

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct ProductImageViewModelTests {
    private let product = Product.previews[0]

    @Test func loadAsksForTheSizeAndShowsTheImage() async {
        let image = UIImage.solid(.blue, size: .thumbnail)
        let loader = InMemoryImageLoader(image: image)
        let viewModel = ProductImageViewModel(product: product, size: .thumbnail, loader: loader)

        #expect(viewModel.state == .loading)
        await viewModel.load()

        #expect(viewModel.state == .loaded(image))
        #expect(loader.requests == [InMemoryImageLoader.Request(productID: product.id, size: .thumbnail)])
    }

    @Test func aFailureShowsTheFailureImage() async {
        let loader = InMemoryImageLoader(error: .network(.httpStatus(HTTPStatus.forbidden)))
        let viewModel = ProductImageViewModel(product: product, size: .thumbnail, loader: loader)

        await viewModel.load()

        #expect(viewModel.state == .failed)
    }

    @Test func cancellingTheLoadKeepsThePlaceholder() async {
        let loader = InMemoryImageLoader.pending
        let viewModel = ProductImageViewModel(product: product, size: .thumbnail, loader: loader)

        let task = Task { await viewModel.load() }
        // Cancel a load that is waiting on the loader, not a task that has not reached it yet.
        while loader.requests.isEmpty {
            await Task.yield()
        }
        task.cancel()
        await task.value

        #expect(viewModel.state == .loading)
    }

    @Test func aSecondLoadKeepsALoadedImageWithoutAskingAgain() async {
        let loader = InMemoryImageLoader(image: .solid(.blue, size: .thumbnail))
        let viewModel = ProductImageViewModel(product: product, size: .thumbnail, loader: loader)

        await viewModel.load()
        await viewModel.load()

        #expect(loader.requests.count == 1)
    }

    @Test func aSecondLoadRetriesAFailedImage() async {
        let loader = InMemoryImageLoader(error: .invalidImage("not a png"))
        let viewModel = ProductImageViewModel(product: product, size: .thumbnail, loader: loader)

        await viewModel.load()
        await viewModel.load()

        #expect(loader.requests.count == 2)
    }
}
