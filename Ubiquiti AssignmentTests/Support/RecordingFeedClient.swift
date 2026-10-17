import Foundation
import Synchronization
@testable import Ubiquiti_Assignment

/// An `InMemoryFeedClient` that also remembers the validators each fetch was asked with, so tests can prove what
/// the repository sends after loading, or failing to load, its cache.
final nonisolated class RecordingFeedClient: FeedClient, Sendable {
    private let client: InMemoryFeedClient
    private let received = Mutex<[Validators]>([])

    /// Replays `result` on every fetch, like `InMemoryFeedClient(result:)`.
    init(result: Result<FeedResponse, NetworkError>) {
        client = InMemoryFeedClient(result: result)
    }

    /// The validators of every fetch so far, oldest first.
    var receivedValidators: [Validators] {
        received.withLock { $0 }
    }

    // MARK: - FeedClient

    func fetch(validators: Validators) async throws(NetworkError) -> FeedResponse {
        received.withLock { $0.append(validators) }
        return try await client.fetch(validators: validators)
    }
}
