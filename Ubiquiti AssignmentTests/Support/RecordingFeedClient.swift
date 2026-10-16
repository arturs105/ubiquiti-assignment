import Combine
import Foundation
import Synchronization
@testable import Ubiquiti_Assignment

/// An `InMemoryFeedClient` that also remembers the validators each fetch was asked with, so tests can prove what
/// the repository sends after loading, or failing to load, its cache.
final class RecordingFeedClient: FeedClient, Sendable {
    init(result: Result<FeedResponse, NetworkError>) {
        client = InMemoryFeedClient(result: result)
    }

    /// The validators of every fetch so far, oldest first.
    var receivedValidators: [Validators] {
        received.withLock { $0 }
    }

    // MARK: - FeedClient

    func fetch(validators: Validators) -> AnyPublisher<FeedResponse, NetworkError> {
        received.withLock { $0.append(validators) }
        return client.fetch(validators: validators)
    }

    private let client: InMemoryFeedClient
    private let received = Mutex<[Validators]>([])
}
