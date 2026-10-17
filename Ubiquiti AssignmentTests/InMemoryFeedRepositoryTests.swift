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

    @Test func anUpdatedRefreshReachesASubscriber() async {
        let repository = InMemoryFeedRepository(refresh: .updated(feed))
        let updates = await repository.updates()

        _ = await repository.load()

        #expect(await updates.firstElement() == feed)
    }

    @Test func publishReachesASubscriberWithoutARefresh() async {
        let repository = InMemoryFeedRepository(cached: feed, refresh: .unchanged)
        let updates = await repository.updates()

        await repository.publish(feed)

        #expect(await updates.firstElement() == feed)
    }

    @Test func unchangedAndFailedRefreshesHandSubscribersNothing() async throws {
        var repository: InMemoryFeedRepository? = InMemoryFeedRepository(cached: feed, error: .decoding("bad"))
        let updates = try await #require(repository).updates()

        _ = await repository?.load()
        repository = nil

        let collected = await updates.collect()
        #expect(collected.isEmpty)
    }

    private let feed = try! JSONDecoder().decode(Feed.self, from: Data(#"{"version": "v1", "devices": []}"#.utf8))
}
