import UIKit

/// Hands a screen the picture of a product at a size: fetched from the image CDN, cached in memory and on disk.
///
/// The one seam between the screens and the image CDN. `KingfisherImageLoader` is the production implementation;
/// `InMemoryImageLoader` the fake. The loader never resizes: the CDN renders the width `ImageSize` names, so a
/// thumbnail arrives small and a hero arrives large. Nothing outside the production type knows which library does
/// the work. See `docs/DECISIONS.md`, 2026-10-18 "Images load through Kingfisher".
nonisolated protocol ImageLoader: Sendable {
    /// The product's image at `size`: from memory, else disk, else the CDN, then cached.
    ///
    /// Concurrent calls for one product and size share a single download. Cancelling the task that awaits this
    /// stops waiting and throws `ImageError.cancelled`; the download is cancelled once no caller awaits it. A view
    /// model ignores that case. Any other failure is one the screen shows as the failure image.
    func image(for product: Product, size: ImageSize) async throws(ImageError) -> UIImage
}
