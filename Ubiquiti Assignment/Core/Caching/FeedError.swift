import Foundation

/// Why the repository could not produce a current feed. Disk failures are logged, never surfaced.
nonisolated enum FeedError: Error, Equatable, Sendable {
    /// The download failed at the transport or HTTP level.
    case network(NetworkError)
    /// The server sent bytes that do not decode as a feed. Carries the decoding error's description, a `String`
    /// so the enum stays `Equatable` for tests and the display mapper.
    case decoding(String)
}
