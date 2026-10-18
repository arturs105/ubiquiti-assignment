import Foundation

/// Lets `ErrorView` show a feed failure before #15 maps failures to user-facing wording.
///
/// The descriptions are the technical ones: the transport's `URLError` text, the HTTP status, the decoder's
/// message. #15 replaces this with a presentation-layer `DisplayError` and the conformance goes with it.
extension FeedError: LocalizedError {
    nonisolated var errorDescription: String? {
        switch self {
        case let .network(.network(error)): error.localizedDescription
        case let .network(.httpStatus(status)): "The server answered with HTTP \(status)."
        case .network(.invalidResponse): "The server sent a response that is not HTTP."
        case let .decoding(description): "The product list could not be read: \(description)"
        }
    }
}
