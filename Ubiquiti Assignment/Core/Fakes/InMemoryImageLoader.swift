import Synchronization
import UIKit

/// An `ImageLoader` that answers from a script at once, for view model tests and previews.
///
/// One default answer for every product, overridable per product id, and a record of every request so a test can
/// assert what a view model asked for. `pending` answers nothing until the awaiting task is cancelled, which is how
/// a loading placeholder is proven: no timers.
final nonisolated class InMemoryImageLoader: ImageLoader, Sendable {
    /// One call to `image(for:size:)`, as recorded.
    struct Request: Hashable, Sendable {
        let productID: Product.ID
        let size: ImageSize
    }

    /// `nil` answers nothing: the call waits until it is cancelled.
    private let answer: Result<UIImage, ImageError>?
    private let overrides: [Product.ID: Result<UIImage, ImageError>]
    private let recorded = Mutex<[Request]>([])

    init(answer: Result<UIImage, ImageError>?, overrides: [Product.ID: Result<UIImage, ImageError>] = [:]) {
        self.answer = answer
        self.overrides = overrides
    }

    /// A loader handing every product `image`, by default a solid grey of hero size.
    convenience init(image: UIImage = .solid(.systemGray4, size: .hero)) {
        self.init(answer: .success(image))
    }

    convenience init(error: ImageError) {
        self.init(answer: .failure(error))
    }

    /// A loader that never answers, so a screen stays on its placeholder.
    static var pending: InMemoryImageLoader {
        InMemoryImageLoader(answer: nil)
    }

    /// Every request so far, oldest first.
    var requests: [Request] {
        recorded.withLock { $0 }
    }

    // MARK: - ImageLoader

    func image(for product: Product, size: ImageSize) async throws(ImageError) -> UIImage {
        recorded.withLock { $0.append(Request(productID: product.id, size: size)) }
        guard let result = overrides[product.id] ?? answer else {
            await waitForCancellation()
            throw .cancelled
        }
        return try result.get()
    }

    // MARK: - Private helpers

    /// Suspends until the current task is cancelled, as a download that never completes would. A stream that never
    /// yields ends its iteration only on cancellation, so nothing wakes before then.
    private func waitForCancellation() async {
        let (stream, continuation) = AsyncStream<Never>.makeStream()
        for await _ in stream {}
        continuation.finish()
    }
}
