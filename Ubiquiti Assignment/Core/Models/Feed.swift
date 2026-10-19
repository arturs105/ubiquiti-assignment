import Foundation
import OSLog

/// The whole UIDB document: a version fingerprint plus the list of products.
///
/// Decoding is lenient: a structurally broken product is dropped and logged with its index, so one bad record never
/// blanks the catalogue. See `docs/DECISIONS.md`, "Lenient feed decoding".
nonisolated struct Feed: Codable, Hashable, Identifiable, Sendable {
    /// Opaque fingerprint of the feed contents, and the feed's whole identity: two feeds with the same version are the
    /// same document, so the view model compares versions, not contents, to tell a changed feed from a reissue.
    let version: String
    let products: [Product]

    var id: String { version }

    /// Builds a feed directly, for previews and tests; the live feed always arrives through `init(from:)`.
    init(version: String, products: [Product]) {
        self.version = version
        self.products = products
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case version
        case products = "devices"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(String.self, forKey: .version)
        let elements = try container.decode([Lenient<Product>].self, forKey: .products)
        products = elements.enumerated().compactMap { index, element in
            switch element {
            case let .decoded(product):
                return product
            case let .failed(error):
                Logger.decoding.error("Dropped product at index \(index): \(error)")
                return nil
            }
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(products, forKey: .products)
    }
}
