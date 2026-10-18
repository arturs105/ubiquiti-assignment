import Foundation

extension URLSessionConfiguration {
    /// A fresh configuration for image downloads: ephemeral, so the system `URLCache` never doubles the loader's
    /// own disk cache, and no waiting for connectivity, matching the feed session: an offline row fails fast and
    /// shows the failure image instead of a spinner that never ends. Default timeouts; the loader has its own.
    nonisolated static func images() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.waitsForConnectivity = false
        return configuration
    }
}
