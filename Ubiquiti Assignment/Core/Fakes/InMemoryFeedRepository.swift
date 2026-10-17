import Foundation

/// A `FeedRepository` that replays a scripted cached feed and refresh outcome, for view model tests and previews.
nonisolated struct InMemoryFeedRepository: FeedRepository {
    private let cached: Feed?
    private let result: Result<FeedSnapshot, FeedError>

    /// A repository holding `cached` (or nothing) whose every refresh ends in `result`.
    init(cached: Feed? = nil, result: Result<FeedSnapshot, FeedError>) {
        self.cached = cached
        self.result = result
    }

    /// A repository holding `cached` (or nothing) whose every refresh returns `snapshot`.
    init(cached: Feed? = nil, snapshot: FeedSnapshot) {
        self.init(cached: cached, result: .success(snapshot))
    }

    /// A repository holding nothing whose every refresh throws `error`.
    init(error: FeedError) {
        self.init(result: .failure(error))
    }

    // MARK: - FeedRepository

    func cachedSnapshot() async -> FeedSnapshot? {
        cached.map { FeedSnapshot(feed: $0, freshness: .cached) }
    }

    func refresh() async throws(FeedError) -> FeedSnapshot {
        try result.get()
    }
}
