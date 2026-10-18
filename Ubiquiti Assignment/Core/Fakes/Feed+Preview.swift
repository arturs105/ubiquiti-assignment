import Foundation

extension Feed {
    /// The preview products under one fixed version.
    nonisolated static let preview = Feed(version: "preview", products: Product.previews)
}
