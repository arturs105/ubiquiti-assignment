import Foundation

/// Whether a product joins a UniFi controller or runs on its own, as the feed's `unifi.adoptability` reports it.
nonisolated enum Adoptability: String, Codable, Hashable, Sendable {
    case adoptable
    case standalone
}
