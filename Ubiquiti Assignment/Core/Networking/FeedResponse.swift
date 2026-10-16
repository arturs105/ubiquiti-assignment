import Foundation

/// What the server said about the feed when asked with the caller's validators.
nonisolated enum FeedResponse: Hashable, Sendable {
    /// The server answered 304: the feed the caller already has is current.
    case unchanged
    /// A new feed: the raw bytes exactly as sent, plus the validators to use next time.
    case updated(data: Data, validators: Validators)
}
