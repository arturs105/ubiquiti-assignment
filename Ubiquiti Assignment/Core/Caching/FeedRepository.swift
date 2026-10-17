import Foundation

/// Hands the app the feed to show, as snapshots whose freshness improves as more is known.
///
/// The one seam between the view models and the data layer. A load is two calls in order: `cachedSnapshot()`
/// for what can be shown at once, then `refresh()` for what the server says. Pull to refresh and retry call
/// `refresh()` again. Both run on the caller's task and never touch the main actor; a view model awaits them from
/// its own isolation and assigns the result there.
nonisolated protocol FeedRepository: Sendable {
    /// The cached feed as a `cached` snapshot, or `nil` when there is none. Never touches the network.
    func cachedSnapshot() async -> FeedSnapshot?

    /// Asks the server for the feed, conditionally when a cached one is held.
    ///
    /// Returns `current` when the server answered with a new feed or with unchanged. When the refresh fails and a
    /// cached feed stands, returns it as `stale` with the reason. Throws only when nothing can be shown: no cached
    /// feed and the refresh failed.
    func refresh() async throws(FeedError) -> FeedSnapshot
}
