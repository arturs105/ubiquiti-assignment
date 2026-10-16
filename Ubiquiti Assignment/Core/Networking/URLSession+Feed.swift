import Foundation

extension URLSession {
    /// The session the feed client uses by default. Images use a separate, cached session.
    nonisolated static let feed = URLSession(configuration: .feed())
}
