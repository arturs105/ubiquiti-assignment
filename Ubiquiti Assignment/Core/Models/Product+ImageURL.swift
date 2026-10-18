import Foundation

nonisolated extension Product {
    /// The CDN URL of this product's image rendered at `size`.
    ///
    /// Shape, from the assignment: `https://images.svc.ui.com/?u=<static image URL>&w=<width>&q=75`. The static
    /// image path carries the product id lowercased: the CDN answers 403 to the uppercase form `UUID.uuidString`
    /// produces (see `docs/DECISIONS.md`, 2026-10-15 "`Product.ID` is Foundation's `UUID`").
    /// `URL.appending(queryItems:)`
    /// leaves `:` and `/` in the inner URL bare; the CDN accepts both that and the percent-encoded form.
    func imageURL(size: ImageSize) -> URL {
        let source = "\(Constants.staticImageBase)/\(id.uuidString.lowercased())/default/\(defaultImageID).png"
        return Constants.imageService.appending(queryItems: [
            URLQueryItem(name: Constants.sourceParameter, value: source),
            URLQueryItem(name: Constants.widthParameter, value: String(size.pixelWidth)),
            URLQueryItem(name: Constants.qualityParameter, value: String(Constants.quality)),
        ])
    }

    nonisolated enum Constants {
        /// The resizing image service. The second accepted force unwrap on a compile-time literal, beside the feed
        /// URL; a test evaluates it on every run. See `docs/DECISIONS.md`.
        static let imageService = URL(string: "https://images.svc.ui.com/")!
        /// Where the original product images live; the service fetches and resizes from here.
        static let staticImageBase = "https://static.ui.com/fingerprint/ui/images"
        static let sourceParameter = "u"
        static let widthParameter = "w"
        static let qualityParameter = "q"
        /// JPEG-style quality the assignment's example URL uses.
        static let quality = 75
    }
}
