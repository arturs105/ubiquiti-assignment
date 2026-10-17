import Foundation

/// A `FeedRepository` that replays a scripted cached feed and refresh outcome, for view model tests and previews.
nonisolated struct InMemoryFeedRepository: FeedRepository {
    private let cached: Feed?
    private let result: Result<FeedRefresh, FeedError>

    /// A repository holding `cached` (or nothing) whose every refresh ends in `result`.
    init(cached: Feed? = nil, result: Result<FeedRefresh, FeedError>) {
        self.cached = cached
        self.result = result
    }

    /// A repository holding `cached` (or nothing) whose every refresh returns `refresh`.
    init(cached: Feed? = nil, refresh: FeedRefresh) {
        self.init(cached: cached, result: .success(refresh))
    }

    /// A repository holding `cached` (or nothing) whose every refresh throws `error`.
    init(cached: Feed? = nil, error: FeedError) {
        self.init(cached: cached, result: .failure(error))
    }

    // MARK: - FeedRepository

    func cachedFeed() async -> Feed? {
        cached
    }

    func refresh() async throws(FeedError) -> FeedRefresh {
        try result.get()
    }
}
