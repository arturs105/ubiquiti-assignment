import Foundation
import Synchronization
@testable import Ubiquiti_Assignment

/// A `FeedClient` that replays scripted outcomes in order and remembers the validators each fetch was asked with,
/// so tests can prove what the repository sends after loading, or failing to load, its cache.
final nonisolated class RecordingFeedClient: FeedClient, Sendable {
    private let state: Mutex<State>

    private struct State {
        var pending: [Result<FeedResponse, NetworkError>]
        var received: [Validators] = []
    }

    /// Replays `result` on every fetch, like `InMemoryFeedClient(result:)`.
    convenience init(result: Result<FeedResponse, NetworkError>) {
        self.init(results: [result])
    }

    /// Replays `results` one per fetch, in order, then the last one on every fetch after.
    init(results: [Result<FeedResponse, NetworkError>]) {
        precondition(results.isEmpty == false, "A client needs at least one outcome to replay")
        state = Mutex(State(pending: results))
    }

    /// The validators of every fetch so far, oldest first.
    var receivedValidators: [Validators] {
        state.withLock { $0.received }
    }

    // MARK: - FeedClient

    func fetch(validators: Validators) async throws(NetworkError) -> FeedResponse {
        let result = state.withLock { state in
            state.received.append(validators)
            return state.pending.count > 1 ? state.pending.removeFirst() : state.pending[0]
        }
        return try result.get()
    }
}
