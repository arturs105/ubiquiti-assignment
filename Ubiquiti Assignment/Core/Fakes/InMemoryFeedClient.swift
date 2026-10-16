import Combine
import Foundation

/// A `FeedClient` that replays one scripted outcome, for tests and previews that must not touch the network.
nonisolated struct InMemoryFeedClient: FeedClient {
    private let result: Result<FeedResponse, NetworkError>

    init(result: Result<FeedResponse, NetworkError>) {
        self.result = result
    }

    /// A client whose every fetch succeeds with `response`.
    init(response: FeedResponse) {
        self.init(result: .success(response))
    }

    /// A client whose every fetch fails with `error`.
    init(error: NetworkError) {
        self.init(result: .failure(error))
    }

    // MARK: - FeedClient

    func fetch(validators _: Validators) -> AnyPublisher<FeedResponse, NetworkError> {
        result.publisher.eraseToAnyPublisher()
    }
}
