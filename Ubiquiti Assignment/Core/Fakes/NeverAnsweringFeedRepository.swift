import Foundation

/// A `FeedRepository` with nothing cached whose refresh never returns, for previewing a loading state.
///
/// Not an actor: it holds no state. The stream opens with `nil` and stays open; `refresh()` sleeps until the task
/// awaiting it is cancelled, then throws the cancellation, which the view model discards.
nonisolated struct NeverAnsweringFeedRepository: FeedRepository {
    func feed() -> AsyncStream<Feed?> {
        AsyncStream { continuation in
            continuation.yield(nil)
        }
    }

    func refresh() async throws(FeedError) -> FeedRefresh {
        while !Task.isCancelled {
            try? await Task.sleep(for: Constants.nap)
        }
        throw .network(.network(URLError(.cancelled)))
    }
}

extension NeverAnsweringFeedRepository {
    private nonisolated enum Constants {
        /// How long each wait for cancellation sleeps; short enough that a cancelled preview task ends promptly.
        static let nap: Duration = .milliseconds(100)
    }
}
