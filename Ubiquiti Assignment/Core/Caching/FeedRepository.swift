import Combine
import Foundation

/// Hands the app the feed to show, from the cache first and then from the network.
///
/// The one seam between the view models and the data layer. `CachedFeedRepository` is the production
/// implementation; `InMemoryFeedRepository` the fake for tests and previews.
nonisolated protocol FeedRepository: Sendable {
    /// Runs one cache-then-network pass.
    ///
    /// With a cached feed: emits it as `cached`, then exactly one of `current` (the server answered) or `stale` (it
    /// did not), then completes. Without one: emits `current` and completes, or fails with the reason nothing can
    /// be shown. Every subscription runs the pass again, so pull to refresh and retry subscribe anew. May emit on
    /// any queue; callers that touch main-actor state `receive(on:)` main themselves.
    func feed() -> AnyPublisher<FeedSnapshot, FeedError>
}
