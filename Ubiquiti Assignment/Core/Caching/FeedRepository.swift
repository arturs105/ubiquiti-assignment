import Combine
import Foundation

/// Hands the app the feed to show, as a sequence of snapshots whose freshness improves as more is known.
///
/// The one seam between the view models and the data layer.
nonisolated protocol FeedRepository: Sendable {
    /// Runs one pass.
    ///
    /// With a cached feed: emits it as `cached`, then exactly one of `current` or `stale`, then completes.
    /// Without one: emits `current` and completes, or fails with the reason nothing can be shown. Every
    /// subscription runs the pass again, so pull to refresh and retry subscribe anew. May emit on any queue;
    /// callers that touch main-actor state `receive(on:)` main themselves.
    func feed() -> AnyPublisher<FeedSnapshot, FeedError>
}
