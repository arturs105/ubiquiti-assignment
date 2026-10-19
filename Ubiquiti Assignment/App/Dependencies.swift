import Foundation

/// The Core services the app runs on, built once by the App and handed down by initialiser.
///
/// The composition root: `live()` is the one place that names the production types, so a reviewer reads here which
/// repository and client the app ships with. `RootView` takes a `Dependencies` and builds every screen's view model
/// from it; the struct itself never enters `Features/`, so a screen only ever sees the one protocol it needs. A
/// value rather than a container or environment key because the graph is small and explicit injection keeps it
/// visible. See `docs/DECISIONS.md`, 2026-10-18 "`Dependencies` is a value built once by the App and passed by
/// initialiser".
nonisolated struct Dependencies: Sendable {
    /// The feed seam every screen reads and refreshes through.
    let feedRepository: any FeedRepository
    /// The image seam every row and the details hero load through.
    let imageLoader: any ImageLoader

    /// The production graph: the cached repository over a conditional `URLSession` fetch, and Kingfisher for images.
    static func live() -> Dependencies {
        Dependencies(
            feedRepository: CachedFeedRepository(client: URLSessionFeedClient()),
            imageLoader: KingfisherImageLoader(),
        )
    }
}
