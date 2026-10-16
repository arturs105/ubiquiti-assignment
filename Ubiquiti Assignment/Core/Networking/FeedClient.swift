import Combine
import Foundation

/// Downloads the UIDB feed bytes, conditionally when the caller has validators from the last download.
///
/// The one seam between the app and the network: the repository and view models depend on this, not on
/// `URLSession`. `URLSessionFeedClient` is the production implementation; `InMemoryFeedClient` the fake.
nonisolated protocol FeedClient: Sendable {
    /// Requests the feed, sending `validators` as a conditional request when they are present.
    ///
    /// Emits exactly one `FeedResponse` then completes, or fails once with a `NetworkError`. No retry: the caller
    /// decides when to try again. May emit on any queue, including synchronously on the subscribing one (the
    /// in-memory fake does); callers that touch main-actor state must `receive(on:)` main themselves.
    func fetch(validators: Validators) -> AnyPublisher<FeedResponse, NetworkError>
}
