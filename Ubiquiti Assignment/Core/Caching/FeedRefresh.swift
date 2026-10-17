import Foundation

/// What a refresh found out, decoded. The caller keeps whatever it shows until this says otherwise.
nonisolated enum FeedRefresh: Equatable, Sendable {
    /// The server confirmed the cached feed is current. Nothing new to show.
    case unchanged
    /// The server sent a feed, already saved as the cached feed.
    case updated(Feed)
}
