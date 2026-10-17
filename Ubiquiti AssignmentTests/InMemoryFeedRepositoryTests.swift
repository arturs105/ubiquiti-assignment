import Foundation
import Testing
@testable import Ubiquiti_Assignment

@Suite(.timeLimit(.minutes(1)))
struct InMemoryFeedRepositoryTests {
    @Test func replaysTheCachedFeedThenTheScriptedRefresh() async {
        let result = await InMemoryFeedRepository(cached: feed, refresh: .unchanged).load()

        #expect(result == FeedLoad(cached: feed, refresh: .success(.unchanged)))
    }

    @Test func withoutACachedFeedReplaysOnlyTheScriptedRefresh() async {
        let result = await InMemoryFeedRepository(refresh: .updated(feed)).load()

        #expect(result == FeedLoad(cached: nil, refresh: .success(.updated(feed))))
    }

    @Test func replaysTheScriptedFailureBesideTheCachedFeed() async {
        let result = await InMemoryFeedRepository(cached: feed, error: .decoding("bad")).load()

        #expect(result == FeedLoad(cached: feed, refresh: .failure(.decoding("bad"))))
    }

    private let feed = try! JSONDecoder().decode(Feed.self, from: Data(#"{"version": "v1", "devices": []}"#.utf8))
}
