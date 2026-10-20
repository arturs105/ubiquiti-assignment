import UIKit

/// What a product image slot shows, as one value the view switches over exhaustively.
///
/// Separate from `LoadState`: an image has no `empty`. The failure carries the error as the user reads it, so the
/// hero can say why and offer a retry; a thumbnail ignores it and shows the failure image. See `docs/DECISIONS.md`,
/// 2026-10-20 "The hero names its failure and retries in place".
enum ImageState: Equatable {
    /// The image has not arrived yet; the slot shows a placeholder.
    case loading
    case loaded(UIImage)
    /// The image could not be loaded.
    case failed(DisplayError)
}
