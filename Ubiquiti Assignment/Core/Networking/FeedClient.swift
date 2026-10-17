import Foundation

/// Downloads the UIDB feed bytes, conditionally when the caller has validators from the last download.
///
/// The one seam between the app and the network: the repository and view models depend on this, not on
/// `URLSession`. `URLSessionFeedClient` is the production implementation; `InMemoryFeedClient` the fake.
nonisolated protocol FeedClient: Sendable {
    /// Requests the feed, sending `validators` as a conditional request when they are present.
    ///
    /// Returns exactly one `FeedResponse` or throws one `NetworkError`. No retry: the caller decides when to try
    /// again. Runs on the caller's task; nothing here touches the main actor.
    func fetch(validators: Validators) async throws(NetworkError) -> FeedResponse
}
