import Foundation
import UIKit

/// State and intent of one product image slot: a thumbnail in a row or the hero on the details screen.
///
/// `load()` is awaited by the view's `.task`, so the row leaving the screen cancels the download through structured
/// concurrency and no `cancel()` exists; see `docs/DECISIONS.md`, 2026-10-18 "Thumbnails load through a per-row
/// view model".
@Observable
final class ProductImageViewModel {
    /// What the slot shows.
    private(set) var state: ImageState = .loading

    private let product: Product
    private let size: ImageSize
    private let loader: any ImageLoader

    /// - Parameters:
    ///   - product: Whose image to show.
    ///   - size: Which rendition the slot needs.
    ///   - loader: The image seam the slot loads through.
    init(product: Product, size: ImageSize, loader: any ImageLoader) {
        self.product = product
        self.size = size
        self.loader = loader
    }

    // MARK: - Intents

    /// Loads the image and returns once the slot has something to show. A loaded image is kept; a failed one is
    /// asked for again, so a row that scrolls back after an offline failure retries. The view awaits this from its
    /// `.task`, so a row leaving the screen cancels the load.
    func load() async {
        if case .loaded = state {
            return
        }
        state = .loading
        do throws(ImageError) {
            state = try await .loaded(loader.image(for: product, size: size))
        } catch .cancelled {
            // The row left the screen: nothing to show and nobody looking. A new load starts if it comes back.
        } catch {
            state = .failed
        }
    }
}
