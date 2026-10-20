import Foundation

/// A `FeedClient` that replays one scripted outcome, for tests and previews that must not touch the network.
nonisolated struct InMemoryFeedClient: FeedClient {
    private let result: Result<FeedResponse, NetworkError>

    init(result: Result<FeedResponse, NetworkError>) {
        self.result = result
    }

    init(response: FeedResponse) {
        self.init(result: .success(response))
    }

    init(error: NetworkError) {
        self.init(result: .failure(error))
    }

    // MARK: - FeedClient

    func fetch(validators _: Validators) async throws(NetworkError) -> FeedResponse {
        try result.get()
    }
}
