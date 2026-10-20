import Foundation

/// A `FeedRepository` that replays a scripted cached feed and refresh outcome, for view model tests and previews.
///
/// The script is either an outcome every refresh ends in or, through `neverAnswering(cached:)`, a refresh that
/// stays in flight until the task awaiting it is cancelled, for a loading preview and for asserting what shows
/// before the server answers. `script(_:)` swaps the outcome between refreshes, so a test can fail one and let the
/// retry after it succeed.
///
/// An actor, like the production repository, because it keeps the same list of `feed()` subscribers: an updated
/// refresh reaches them as it would in production, and `publish(_:)` lets a test push a feed nobody on screen asked
/// for, as a background refresh or a push notification would. Like production, a saved feed becomes the cached one,
/// so a later subscriber starts from it.
actor InMemoryFeedRepository: FeedRepository {
    private var cached: Feed?
    /// How every refresh ends; `nil` when it never does.
    private var result: Result<FeedRefresh, FeedError>?
    private var subscribers: [UUID: AsyncStream<Feed?>.Continuation] = [:]
    /// How many times `refresh()` has been called, so a test can tell a joined refresh from a second one.
    private(set) var refreshCount = 0

    private init(cached: Feed?, script result: Result<FeedRefresh, FeedError>?) {
        self.cached = cached
        self.result = result
    }

    init(cached: Feed? = nil, result: Result<FeedRefresh, FeedError>) {
        self.init(cached: cached, script: result)
    }

    init(cached: Feed? = nil, refresh: FeedRefresh) {
        self.init(cached: cached, result: .success(refresh))
    }

    init(cached: Feed? = nil, error: FeedError) {
        self.init(cached: cached, result: .failure(error))
    }

    /// A repository holding `cached` (or nothing) whose every refresh stays in flight until its task is cancelled,
    /// then throws the cancellation as the transport would.
    static func neverAnswering(cached: Feed? = nil) -> InMemoryFeedRepository {
        InMemoryFeedRepository(cached: cached, script: nil)
    }

    deinit {
        for continuation in subscribers.values {
            continuation.finish()
        }
    }

    // MARK: - FeedRepository

    func feed() -> AsyncStream<Feed?> {
        let (stream, continuation) = AsyncStream.makeStream(of: Feed?.self, bufferingPolicy: .bufferingNewest(1))
        continuation.yield(cached)
        let id = UUID()
        subscribers[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.forget(id) }
        }
        return stream
    }

    func refresh() async throws(FeedError) -> FeedRefresh {
        refreshCount += 1
        guard let result else { try await waitForCancellation() }
        let outcome = try result.get()
        switch outcome {
        case .unchanged where cached == nil:
            // As in production: nothing cached means nothing a server could confirm, so a scripted unchanged
            // becomes the status error the real repository throws, and previews cannot show a state it never reaches.
            throw .network(.httpStatus(HTTPStatus.notModified))
        case .unchanged:
            break
        case let .updated(feed):
            publish(feed)
        }
        return outcome
    }

    // MARK: - Test hooks

    /// Makes every later refresh end in `result`; one already in flight keeps the outcome it started with.
    func script(_ result: Result<FeedRefresh, FeedError>) {
        self.result = result
    }

    /// Hands `feed` to every subscriber as if a refresh elsewhere had just saved it, and keeps it as the cached feed.
    func publish(_ feed: Feed) {
        cached = feed
        for continuation in subscribers.values {
            continuation.yield(feed)
        }
    }

    // MARK: - Private helpers

    private func forget(_ id: UUID) {
        subscribers[id] = nil
    }

    private func waitForCancellation() async throws(FeedError) -> Never {
        // `Task.sleep` throws as soon as the task is cancelled, so the loop only restarts a sleep that ran out.
        while true {
            do {
                try await Task.sleep(for: Constants.sleep)
            } catch {
                throw .network(.network(URLError(.cancelled)))
            }
        }
    }
}

extension InMemoryFeedRepository {
    private nonisolated enum Constants {
        /// How long one wait for cancellation sleeps before starting the next; any length works.
        static let sleep: Duration = .seconds(3600)
    }
}
