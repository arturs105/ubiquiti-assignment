import Foundation
import OSLog

/// The whole UIDB document: a version fingerprint plus the list of products.
///
/// Decoding is lenient: a structurally broken product is dropped and logged with its index, so one bad record never
/// blanks the catalogue. See `docs/DECISIONS.md`, "Lenient feed decoding".
nonisolated struct Feed: Codable, Hashable, Sendable {
    /// Opaque fingerprint of the feed contents; caching compares it to detect a changed feed.
    let version: String
    let products: [Product]

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

/// Decodes one array element without failing the array: a broken element becomes `.failed` instead of an error.
private nonisolated enum Lenient<Wrapped: Decodable>: Decodable {
    case decoded(Wrapped)
    case failed(any Error)

    init(from decoder: any Decoder) {
        do {
            self = try .decoded(Wrapped(from: decoder))
        } catch {
            self = .failed(error)
        }
    }
}
