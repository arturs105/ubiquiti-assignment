import Foundation

/// Hands the app the feed to show: the cached one at once, then every feed a refresh saves.
///
/// The one seam between the view models and the data layer, one read and one write. `feed()` is the read: a
/// stream whose first element is the cached feed (or `nil` when there is none) and whose later elements are every
/// feed any refresh saves, whoever asked for it. A screen subscribes once in `load()` and never has to look
/// anywhere else. `refresh()` is the write: it asks the server, saves what comes back, and returns the outcome to
/// the caller so a spinner can end or stale can clear without waiting on the stream. Pull to refresh, retry, a
/// second screen, a background refresh or a push notification all only call `refresh()`. The repository holds no
/// feed between calls, only its subscribers; the view model keeps the feed on screen and decides what a refresh
/// outcome means for it (swap, keep, mark stale). Every call runs on the caller's task and never touches the main
/// actor; a view model awaits them from its own isolation and assigns the result there.
nonisolated protocol FeedRepository: Sendable {
    /// The cached feed first, then every feed saved by a refresh from now on.
    ///
    /// The first element arrives at once and never touches the network: the cached feed, or `nil` when there is
    /// none, so the caller knows to show loading rather than wait. Every later element is a feed a refresh has
    /// just saved, from whichever caller triggered it; `nil` never appears again. Failures are not elements: those
    /// go to the caller of `refresh()`. A subscriber that cannot keep up gets the latest feed, not every one. Each
    /// call is a new subscription, started from what is on disk at that moment, that ends when the task iterating
    /// it is cancelled.
    func feed() async -> AsyncStream<Feed?>

    /// Asks the server for the feed, conditionally when a cached one is on disk.
    ///
    /// Returns `unchanged` when the server confirmed the cached feed, `updated` with the new feed otherwise. Throws
    /// when the download failed or its bytes do not decode; the caller keeps what it shows, as stale. An updated
    /// feed also goes to every `feed()` subscriber, the caller included.
    func refresh() async throws(FeedError) -> FeedRefresh
}
