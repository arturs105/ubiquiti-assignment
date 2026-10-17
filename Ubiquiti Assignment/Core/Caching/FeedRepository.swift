import Foundation

/// Hands the app the feed to show: the cached one at once, then what the server says, then every later change.
///
/// The one seam between the view models and the data layer. A load is two calls in order: `cachedFeed()` for what
/// can be shown at once, then `refresh()` for what the server says. Pull to refresh and retry call `refresh()`
/// again. A screen that wants to stay current subscribes to `updates()` once and is handed every feed any refresh
/// saves, whoever asked for it, so a second screen, a background refresh or a push notification only has to call
/// `refresh()`. The repository holds no feed between calls, only its subscribers; the view model keeps the feed on
/// screen and decides what a refresh outcome means for it (swap, keep, mark stale). Every call runs on the caller's
/// task and never touches the main actor; a view model awaits them from its own isolation and assigns the result
/// there.
nonisolated protocol FeedRepository: Sendable {
    /// The cached feed, or `nil` when there is none. Never touches the network.
    func cachedFeed() async -> Feed?

    /// Asks the server for the feed, conditionally when a cached one is on disk.
    ///
    /// Returns `unchanged` when the server confirmed the cached feed, `updated` with the new feed otherwise. Throws
    /// when the download failed or its bytes do not decode; the caller keeps what it shows, as stale. An updated
    /// feed also goes to every `updates()` subscriber, the caller included.
    func refresh() async throws(FeedError) -> FeedRefresh

    /// Every feed saved by a refresh from now on, from whichever caller triggered it. Never the cached feed, which
    /// `cachedFeed()` already hands out, and never a failure: those go to the caller of `refresh()`. A subscriber
    /// that cannot keep up gets the latest feed, not every one. Each call is a new subscription that ends when the
    /// task iterating it is cancelled.
    func updates() async -> AsyncStream<Feed>
}
