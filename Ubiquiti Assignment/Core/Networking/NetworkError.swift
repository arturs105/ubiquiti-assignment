import Foundation

/// Why a feed download failed, at the transport level. Decoding failures belong to the repository.
nonisolated enum NetworkError: Error, Equatable, Sendable {
    /// The request never completed: offline, timed out, DNS, TLS. Carries the system's reason.
    case network(URLError)
    /// The server answered, but not with a usable feed. 304 lands here too when no validators were sent.
    case httpStatus(Int)
    /// The response was not HTTP at all.
    case invalidResponse
}
