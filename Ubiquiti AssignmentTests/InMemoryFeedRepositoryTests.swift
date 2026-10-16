import Foundation
import Testing
@testable import Ubiquiti_Assignment

@Suite(.timeLimit(.minutes(1)))
struct InMemoryFeedRepositoryTests {
    @Test func replaysTheScriptedSnapshotsInOrder() async {
        let snapshots = [
            FeedSnapshot(feed: feed, freshness: .cached),
            FeedSnapshot(feed: feed, freshness: .stale(.network(.httpStatus(500)))),
        ]

        let result = await InMemoryFeedRepository(snapshots: snapshots).feed().emissions()

        #expect(result == .success(snapshots))
    }

    @Test func replaysTheScriptedFailure() async {
        let result = await InMemoryFeedRepository(error: .decoding("bad")).feed().emissions()

        #expect(result == .failure(.decoding("bad")))
    }

    private let feed = try! JSONDecoder().decode(Feed.self, from: Data(#"{"version": "v1", "devices": []}"#.utf8))
}
