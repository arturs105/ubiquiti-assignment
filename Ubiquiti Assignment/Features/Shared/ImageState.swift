import UIKit

/// What a product image slot shows, as one value the view switches over exhaustively.
///
/// Separate from `LoadState`: an image has no `empty`, and its failure carries no error, because every failure shows
/// the same failure image (see `docs/DECISIONS.md`, 2026-10-18 "Thumbnails load through a per-row view model").
enum ImageState: Equatable {
    /// The image has not arrived yet; the slot shows a placeholder.
    case loading
    /// The image, ready to draw.
    case loaded(UIImage)
    /// The image could not be loaded; the slot shows the failure image until the row reappears.
    case failed
}
