import Foundation

/// The feed the screen shows right now, together with how far it can be trusted.
nonisolated struct FeedSnapshot: Equatable, Sendable {
    /// How far a snapshot can be trusted. Stale is about the refresh failing, not about age: a day-old cached feed
    /// the server has confirmed is `current`.
    enum Freshness: Equatable, Sendable {
        /// The cached feed, shown while the server is being asked whether it changed.
        case cached
        /// The server answered: this feed is the latest one, downloaded just now or confirmed unchanged.
        case current
        /// The cached feed stands because the refresh failed for the reason carried.
        case stale(FeedError)
    }

    let feed: Feed
    let freshness: Freshness
}
