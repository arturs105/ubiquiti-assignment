import Foundation

extension URLSessionConfiguration {
    /// A fresh configuration for the feed: no cache, so the feed's 24-hour `max-age` can never hide a changed feed
    /// from the conditional request, and no waiting for connectivity, so an offline launch fails fast and falls
    /// back to the cached feed. Default timeouts. A function, not a constant, because configurations are mutable
    /// and tests add a stub protocol to theirs.
    nonisolated static func feed() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.waitsForConnectivity = false
        return configuration
    }
}
