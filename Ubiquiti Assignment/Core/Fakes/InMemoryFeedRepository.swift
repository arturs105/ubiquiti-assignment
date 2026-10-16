import Combine
import Foundation

/// A `FeedRepository` that replays scripted snapshots or one failure, for view model tests and previews.
nonisolated struct InMemoryFeedRepository: FeedRepository {
    private let result: Result<[FeedSnapshot], FeedError>

    init(result: Result<[FeedSnapshot], FeedError>) {
        self.result = result
    }

    /// A repository whose every pass emits `snapshots` in order, then completes.
    init(snapshots: [FeedSnapshot]) {
        self.init(result: .success(snapshots))
    }

    /// A repository whose every pass fails with `error` before emitting anything.
    init(error: FeedError) {
        self.init(result: .failure(error))
    }

    // MARK: - FeedRepository

    func feed() -> AnyPublisher<FeedSnapshot, FeedError> {
        switch result {
        case let .success(snapshots):
            snapshots.publisher.setFailureType(to: FeedError.self).eraseToAnyPublisher()
        case let .failure(error):
            Fail(error: error).eraseToAnyPublisher()
        }
    }
}
