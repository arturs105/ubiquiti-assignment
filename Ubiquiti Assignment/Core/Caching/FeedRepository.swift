import Foundation

/// Hands the app the feed to show: the cached one at once, then what the server says.
///
/// The one seam between the view models and the data layer. A load is two calls in order: `cachedFeed()` for what
/// can be shown at once, then `refresh()` for what the server says. Pull to refresh and retry call `refresh()`
/// again. The repository holds nothing between calls; the view model keeps the feed on screen and decides what a
/// refresh outcome means for it (swap, keep, mark stale). Both calls run on the caller's task and never touch the
/// main actor; a view model awaits them from its own isolation and assigns the result there.
nonisolated protocol FeedRepository: Sendable {
    /// The cached feed, or `nil` when there is none. Never touches the network.
    func cachedFeed() async -> Feed?

    /// Asks the server for the feed, conditionally when a cached one is on disk.
    ///
    /// Returns `unchanged` when the server confirmed the cached feed, `updated` with the new feed otherwise. Throws
    /// when the download failed or its bytes do not decode; the caller keeps what it shows, as stale.
    func refresh() async throws(FeedError) -> FeedRefresh
}
