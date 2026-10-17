import Foundation

/// A `FeedRepository` that replays a scripted cached feed and refresh outcome, for view model tests and previews.
///
/// An actor, like the production repository, because it keeps the same list of `updates()` subscribers: an updated
/// refresh reaches them as it would in production, and `publish(_:)` lets a test push a feed nobody on screen asked
/// for, as a background refresh or a push notification would.
actor InMemoryFeedRepository: FeedRepository {
    private let cached: Feed?
    private let result: Result<FeedRefresh, FeedError>
    private var subscribers: [UUID: AsyncStream<Feed>.Continuation] = [:]

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

    deinit {
        for continuation in subscribers.values {
            continuation.finish()
        }
    }

    // MARK: - FeedRepository

    func cachedFeed() -> Feed? {
        cached
    }

    func refresh() throws(FeedError) -> FeedRefresh {
        let outcome = try result.get()
        if case let .updated(feed) = outcome {
            publish(feed)
        }
        return outcome
    }

    func updates() -> AsyncStream<Feed> {
        let (stream, continuation) = AsyncStream.makeStream(of: Feed.self, bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        subscribers[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.forget(id) }
        }
        return stream
    }

    // MARK: - Test hooks

    /// Hands `feed` to every subscriber as if a refresh elsewhere had just saved it.
    func publish(_ feed: Feed) {
        for continuation in subscribers.values {
            continuation.yield(feed)
        }
    }

    // MARK: - Private helpers

    private func forget(_ id: UUID) {
        subscribers[id] = nil
    }
}
