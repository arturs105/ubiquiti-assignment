import Foundation
import Testing
@testable import Ubiquiti_Assignment

@Suite(.timeLimit(.minutes(1)))
struct InMemoryFeedRepositoryTests {
    @Test func replaysTheCachedFeedThenTheScriptedSnapshot() async {
        let stale = FeedSnapshot(feed: feed, freshness: .stale(.network(.httpStatus(500))))

        let result = await InMemoryFeedRepository(cached: feed, snapshot: stale).load()

        #expect(result == .success([FeedSnapshot(feed: feed, freshness: .cached), stale]))
    }

    @Test func withoutACachedFeedReplaysOnlyTheScriptedSnapshot() async {
        let current = FeedSnapshot(feed: feed, freshness: .current)

        let result = await InMemoryFeedRepository(snapshot: current).load()

        #expect(result == .success([current]))
    }

    @Test func replaysTheScriptedFailure() async {
        let result = await InMemoryFeedRepository(error: .decoding("bad")).load()

        #expect(result == .failure(.decoding("bad")))
    }

    private let feed = try! JSONDecoder().decode(Feed.self, from: Data(#"{"version": "v1", "devices": []}"#.utf8))
}
