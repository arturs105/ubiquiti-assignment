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

    @Test func unchangedWithoutACachedFeedThrowsTheStatusErrorLikeProduction() async {
        let result = await InMemoryFeedRepository(refresh: .unchanged).load()

        #expect(result == FeedLoad(cached: nil, refresh: .failure(.network(.httpStatus(304)))))
    }

    @Test func replaysTheScriptedFailureBesideTheCachedFeed() async {
        let result = await InMemoryFeedRepository(cached: feed, error: .decoding("bad")).load()

        #expect(result == FeedLoad(cached: feed, refresh: .failure(.decoding("bad"))))
    }

    @Test func theStreamOpensWithTheCachedFeedOrNil() async {
        #expect(await InMemoryFeedRepository(cached: feed, refresh: .unchanged).feed().firstElement() == feed)
        #expect(await InMemoryFeedRepository(refresh: .unchanged).feed().firstElement() == .some(nil))
    }

    @Test func anUpdatedRefreshFollowsTheCachedFeed() async throws {
        var repository: InMemoryFeedRepository? = InMemoryFeedRepository(refresh: .updated(feed))
        let feeds = try await #require(repository).feed()
        #expect(await feeds.firstElement() == .some(nil))

        _ = await repository?.load()
        repository = nil

        #expect(await feeds.collect() == [feed])
    }

    @Test func publishReachesASubscriberWithoutARefreshAndBecomesTheCachedFeed() async {
        let repository = InMemoryFeedRepository(refresh: .unchanged)
        let feeds = await repository.feed()
        _ = await feeds.firstElement()

        await repository.publish(feed)

        #expect(await feeds.firstElement() == feed)
        #expect(await repository.feed().firstElement() == feed)
    }

    @Test func unchangedAndFailedRefreshesHandSubscribersOnlyTheCachedFeed() async throws {
        var repository: InMemoryFeedRepository? = InMemoryFeedRepository(cached: feed, error: .decoding("bad"))
        let feeds = try await #require(repository).feed()

        _ = await repository?.load()
        repository = nil

        #expect(await feeds.collect() == [feed])
    }

    private let feed = try! JSONDecoder().decode(Feed.self, from: Data(#"{"version": "v1", "devices": []}"#.utf8))
}
