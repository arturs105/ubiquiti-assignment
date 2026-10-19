import Foundation

/// Why a download failed, at the transport or HTTP level: the feed's, or an image's inside `ImageError`. Decoding
/// failures belong to the caller (the repository, the image loader).
nonisolated enum NetworkError: Error, Equatable, Sendable {
    /// The request never completed: offline, timed out, DNS, TLS. Carries the system's reason.
    case network(URLError)
    /// The server answered with a status the caller cannot use, such as the image CDN's 403. For the feed, 304
    /// lands here too when no validators were sent.
    case httpStatus(Int)
    /// The response was not HTTP at all.
    case invalidResponse
}
