import Foundation
import Testing
import UIKit
@testable import Ubiquiti_Assignment

struct InMemoryImageLoaderTests {
    @Test func defaultAnswerGoesToEveryProductAndEveryRequestIsRecorded() async throws {
        let image = UIImage.solid(.blue, size: .thumbnail)
        let loader = InMemoryImageLoader(image: image)
        let first = try Product.stub()
        let second = try Product.stub()

        let firstImage = try await loader.image(for: first, size: .thumbnail)
        let secondImage = try await loader.image(for: second, size: .hero)

        #expect(firstImage === image)
        #expect(secondImage === image)
        #expect(loader.requests == [
            InMemoryImageLoader.Request(productID: first.id, size: .thumbnail),
            InMemoryImageLoader.Request(productID: second.id, size: .hero),
        ])
    }

    @Test func overrideBeatsTheDefaultForItsProduct() async throws {
        let product = try Product.stub()
        let loader = InMemoryImageLoader(
            answer: .success(.solid(.blue, size: .thumbnail)),
            overrides: [product.id: .failure(.invalidImage)],
        )

        await #expect(throws: ImageError.invalidImage) {
            try await loader.image(for: product, size: .thumbnail)
        }
        _ = try await loader.image(for: Product.stub(), size: .thumbnail)
    }

    @Test func pendingAnswersOnlyWithCancellation() async throws {
        let product = try Product.stub()
        let loader = InMemoryImageLoader.pending

        let task = Task {
            try await loader.image(for: product, size: .thumbnail)
        }
        task.cancel()

        await #expect(throws: ImageError.cancelled) {
            try await task.value
        }
    }
}
