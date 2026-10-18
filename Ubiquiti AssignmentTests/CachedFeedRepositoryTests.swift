import Foundation
import Testing
@testable import Ubiquiti_Assignment

/// Feed files `Feed` rejects, which the header `refresh()` reads must reject too. `devices` null and `devices` an
/// object are where a header that read `devices` with `decodeIfPresent`, or not at all, would part from `Feed`.
private nonisolated let undecodableFeedFiles = [
    Data("not json".utf8),
    Data(#"{"version": 1}"#.utf8),
    Data(#"{"devices": []}"#.utf8),
    Data(#"{"version": "v", "devices": null}"#.utf8),
    Data(#"{"version": "v", "devices": {}}"#.utf8),
]

/// A class, not a struct, so `deinit` can remove each test's cache directory once the test is over.
@Suite(.timeLimit(.minutes(1)))
final class CachedFeedRepositoryTests {
    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func noCacheAndANewFeedYieldsNoCachedFeedThenTheDownloadAndWritesBothFiles() async throws {
        let repository = repository(.success(.updated(data: v1, validators: validators1)))

        let result = await repository.load()

        #expect(try result == FeedLoad(cached: nil, refresh: .success(.updated(feed(v1)))))
        #expect(try cachedBytes() == v1)
        #expect(try cachedValidators() == validators1)
    }

    @Test func cachedFeedAndUnchangedYieldsTheCachedFeedThenUnchangedAndLeavesTheFilesAlone() async throws {
        try seed(bytes: v1, validators: validators1)
        let repository = repository(.success(.unchanged))

        let result = await repository.load()

        #expect(try result == FeedLoad(cached: feed(v1), refresh: .success(.unchanged)))
        #expect(try cachedBytes() == v1)
        #expect(try cachedValidators() == validators1)
    }

    @Test func cachedFeedAndANewVersionYieldsTheCachedFeedThenTheDownloadAndRewritesTheFiles() async throws {
        try seed(bytes: v1, validators: validators1)
        let repository = repository(.success(.updated(data: v2, validators: validators2)))

        let result = await repository.load()

        #expect(try result == FeedLoad(cached: feed(v1), refresh: .success(.updated(feed(v2)))))
        #expect(try cachedBytes() == v2)
        #expect(try cachedValidators() == validators2)
    }

    @Test func cachedFeedAndTheSameVersionYieldsTheDownloadAsIsAndSavesIt() async throws {
        // Whether a same-version download replaces what is on screen is the view model's call, not the
        // repository's: it holds nothing to compare against (see `docs/DECISIONS.md`).
        try seed(bytes: v1, validators: validators1)
        let repository = repository(.success(.updated(data: v1Reissued, validators: validators2)))

        let result = await repository.load()

        #expect(try result == FeedLoad(cached: feed(v1), refresh: .success(.updated(feed(v1Reissued)))))
        #expect(try cachedBytes() == v1Reissued)
        #expect(try cachedValidators() == validators2)
    }

    @Test func cachedFeedAndAFailedFetchYieldsTheCachedFeedThenTheErrorAndLeavesTheFilesAlone() async throws {
        try seed(bytes: v1, validators: validators1)
        let repository = repository(.failure(.network(URLError(.notConnectedToInternet))))

        let result = await repository.load()

        #expect(try result == FeedLoad(
            cached: feed(v1),
            refresh: .failure(.network(.network(URLError(.notConnectedToInternet)))),
        ))
        #expect(try cachedBytes() == v1)
        #expect(try cachedValidators() == validators1)
    }

    @Test func noCacheAndAFailedFetchYieldsNothingThenTheNetworkError() async {
        let repository = repository(.failure(.httpStatus(503)))

        let result = await repository.load()

        #expect(result == FeedLoad(cached: nil, refresh: .failure(.network(.httpStatus(503)))))
        #expect(FileManager.default.fileExists(atPath: directory.path) == false)
    }

    @Test func cachedFeedAndUndecodableBytesYieldsTheCachedFeedThenTheDecodingErrorAndLeavesTheFilesAlone(
    ) async throws {
        try seed(bytes: v1, validators: validators1)
        let repository = repository(.success(.updated(data: Data("<html>".utf8), validators: validators2)))

        let result = await repository.load()

        #expect(try result.cached == feed(v1))
        guard case .failure(.decoding) = result.refresh else {
            Issue.record("Expected a decoding failure, got \(result.refresh)")
            return
        }
        #expect(try cachedBytes() == v1)
        #expect(try cachedValidators() == validators1)
    }

    @Test func noCacheAndUndecodableBytesFailsWithTheDecodingErrorAndWritesNothing() async {
        let repository = repository(.success(.updated(data: Data("<html>".utf8), validators: validators2)))

        let result = await repository.load()

        #expect(result.cached == nil)
        guard case .failure(.decoding) = result.refresh else {
            Issue.record("Expected a decoding failure, got \(result.refresh)")
            return
        }
        #expect(FileManager.default.fileExists(atPath: directory.path) == false)
    }

    @Test func cachedFeedWithoutValidatorsLoadsAndFetchesUnconditionally() async throws {
        try seed(bytes: v1, validators: nil)
        let client = RecordingFeedClient(result: .success(.updated(data: v2, validators: validators2)))

        let result = await repository(client).load()

        #expect(client.receivedValidators == [.empty])
        #expect(try result == FeedLoad(cached: feed(v1), refresh: .success(.updated(feed(v2)))))
    }

    @Test func cachedFeedWithValidatorsIsFetchedConditionally() async throws {
        try seed(bytes: v1, validators: validators1)
        let client = RecordingFeedClient(result: .success(.unchanged))

        _ = await repository(client).load()

        #expect(client.receivedValidators == [validators1])
    }

    @Test func validatorsWithoutAFeedFileAreNeverSentAndAreDeleted() async throws {
        try seed(bytes: nil, validators: validators1)
        let client = RecordingFeedClient(result: .failure(.httpStatus(500)))

        let result = await repository(client).load()

        #expect(client.receivedValidators == [.empty])
        #expect(result == FeedLoad(cached: nil, refresh: .failure(.network(.httpStatus(500)))))
        #expect(FileManager.default.fileExists(atPath: validatorsFileURL.path) == false)
    }

    @Test(arguments: undecodableFeedFiles)
    func anUndecodableFeedFileIsNoCacheAndBothFilesAreDeleted(bytes: Data) async throws {
        try seed(bytes: bytes, validators: validators1)
        let client = RecordingFeedClient(result: .failure(.httpStatus(500)))

        let result = await repository(client).load()

        #expect(client.receivedValidators == [.empty])
        #expect(result == FeedLoad(cached: nil, refresh: .failure(.network(.httpStatus(500)))))
        #expect(FileManager.default.fileExists(atPath: feedFileURL.path) == false)
        #expect(FileManager.default.fileExists(atPath: validatorsFileURL.path) == false)
    }

    @Test(arguments: undecodableFeedFiles)
    func refreshAloneTreatsAnUndecodableFeedFileAsNoCache(bytes: Data) async throws {
        // refresh() checks only the feed's top level; it must reject exactly what feed() rejects.
        try seed(bytes: bytes, validators: validators1)
        let client = RecordingFeedClient(result: .failure(.httpStatus(500)))
        let repository = repository(client)

        await #expect(throws: FeedError.network(.httpStatus(500))) {
            try await repository.refresh()
        }

        #expect(client.receivedValidators == [.empty])
        #expect(FileManager.default.fileExists(atPath: feedFileURL.path) == false)
        #expect(FileManager.default.fileExists(atPath: validatorsFileURL.path) == false)
    }

    @Test func refreshAloneSendsTheValidatorsBesideAFeedWithBrokenProducts() async throws {
        // Products decode leniently, so a feed whose products are all broken is still a feed.
        try seed(bytes: Data(#"{"version": "v1", "devices": [1, "two"]}"#.utf8), validators: validators1)
        let client = RecordingFeedClient(result: .success(.unchanged))

        _ = try await repository(client).refresh()

        #expect(client.receivedValidators == [validators1])
    }

    @Test func anUnreadableFeedFileIsNoCacheAndBothFilesAreDeleted() async throws {
        // A directory where the file should be: exists, cannot be read as data.
        try seed(bytes: nil, validators: validators1)
        try FileManager.default.createDirectory(
            at: feedFileURL,
            withIntermediateDirectories: false,
        )
        let client = RecordingFeedClient(result: .failure(.httpStatus(500)))

        let result = await repository(client).load()

        #expect(client.receivedValidators == [.empty])
        #expect(result == FeedLoad(cached: nil, refresh: .failure(.network(.httpStatus(500)))))
        #expect(FileManager.default.fileExists(atPath: feedFileURL.path) == false)
        #expect(FileManager.default.fileExists(atPath: validatorsFileURL.path) == false)
    }

    @Test func aCachedFeedWithNoProductsIsAValidEmptyCache() async throws {
        try seed(bytes: v1, validators: validators1)
        let client = RecordingFeedClient(result: .success(.unchanged))

        let result = await repository(client).load()

        #expect(client.receivedValidators == [validators1])
        #expect(result.cached?.products.isEmpty == true)
    }

    @Test func aPurgedCacheDirectoryIsNoCacheOnTheNextLoad() async throws {
        // The system may empty Library/Caches at any time. Nothing is held in memory, so the next load sees it.
        try seed(bytes: v1, validators: validators1)
        let client = RecordingFeedClient(result: .failure(.httpStatus(500)))
        let repository = repository(client)
        _ = await repository.load()
        try FileManager.default.removeItem(at: directory)

        let result = await repository.load()

        #expect(client.receivedValidators == [validators1, .empty])
        #expect(result == FeedLoad(cached: nil, refresh: .failure(.network(.httpStatus(500)))))
    }

    @Test func aSecondLoadSendsTheValidatorsOfTheLastDownload() async {
        let client = RecordingFeedClient(result: .success(.updated(data: v1, validators: validators1)))
        let repository = repository(client)
        _ = await repository.load()

        _ = await repository.load()

        #expect(client.receivedValidators == [.empty, validators1])
    }

    @Test func unchangedWithoutACacheIsAStatusErrorNotAnOutcome() async {
        // The real client never answers unchanged to an unconditional request; the repository treats it the same way.
        let repository = repository(.success(.unchanged))

        let result = await repository.load()

        #expect(result == FeedLoad(cached: nil, refresh: .failure(.network(.httpStatus(304)))))
    }

    @Test func refreshAloneSendsTheCachedValidators() async throws {
        // Pull to refresh calls refresh() alone; the conditional request must not depend on feed() having run.
        try seed(bytes: v1, validators: validators1)
        let client = RecordingFeedClient(result: .success(.unchanged))

        let outcome = try await repository(client).refresh()

        #expect(client.receivedValidators == [validators1])
        #expect(outcome == .unchanged)
    }

    @Test func refreshWithoutACacheAndAFailedFetchThrows() async {
        let repository = repository(.failure(.httpStatus(503)))

        await #expect(throws: FeedError.network(.httpStatus(503))) {
            try await repository.refresh()
        }
    }

    // MARK: - The feed stream

    @Test func theStreamOpensWithNilWhenThereIsNoCache() async {
        let repository = repository(.failure(.httpStatus(503)))

        let first = await repository.feed().firstElement()

        #expect(first == .some(nil))
    }

    @Test func theStreamOpensWithTheCachedFeed() async throws {
        try seed(bytes: v1, validators: validators1)
        let repository = repository(.failure(.httpStatus(503)))

        let first = await repository.feed().firstElement()

        #expect(try first == feed(v1))
    }

    @Test func anUpdatedRefreshFollowsTheCachedFeedOnceItIsSaved() async throws {
        // A subscriber reads the opening element before the refresh, as a view model iterating the stream would;
        // one that does not is covered by the falls-behind test. Dropping the repository ends every stream, so
        // collecting the rest proves exactly what was handed out.
        try seed(bytes: v1, validators: validators1)
        var repository: CachedFeedRepository? = repository(.success(.updated(data: v2, validators: validators2)))
        let feeds = try await #require(repository).feed()
        let opening = await feeds.firstElement()

        _ = await repository?.load()
        repository = nil

        #expect(try opening == feed(v1))
        #expect(try await feeds.collect() == [feed(v2)])
        #expect(try cachedBytes() == v2)
    }

    @Test func everySubscriberHearsTheSameUpdate() async throws {
        var repository: CachedFeedRepository? = repository(.success(.updated(data: v1, validators: validators1)))
        let first = try await #require(repository).feed()
        let second = try await #require(repository).feed()
        #expect(await first.firstElement() == .some(nil))
        #expect(await second.firstElement() == .some(nil))

        _ = await repository?.load()
        repository = nil

        #expect(try await first.collect() == [feed(v1)])
        #expect(try await second.collect() == [feed(v1)])
    }

    @Test func unchangedAndFailedRefreshesHandSubscribersOnlyTheCachedFeed() async throws {
        // A repository that re-sent the cached feed on a 304 would fail here.
        try seed(bytes: v1, validators: validators1)
        var repository: CachedFeedRepository? = repository(RecordingFeedClient(results: [
            .success(.unchanged),
            .failure(.httpStatus(503)),
        ]))
        let feeds = try await #require(repository).feed()

        _ = await repository?.load()
        _ = await repository?.load()
        repository = nil

        let collected = await feeds.collect()
        #expect(try collected == [feed(v1)])
    }

    @Test func aFailedWriteStillReachesTheCallerAndEverySubscriber() async throws {
        // A file where the cache directory should be: nothing can be saved, and the user still gets the feed.
        try Data().write(to: directory)
        var repository: CachedFeedRepository? = repository(.success(.updated(data: v1, validators: validators1)))
        let feeds = try await #require(repository).feed()
        #expect(await feeds.firstElement() == .some(nil))

        let outcome = try await repository?.refresh()
        repository = nil

        #expect(try outcome == .updated(feed(v1)))
        #expect(try await feeds.collect() == [feed(v1)])
    }

    @Test func aFailedFeedWriteLeavesNoOldValidatorsBehind() async throws {
        // The old validators go before the new bytes are written: were the order reversed, a failed feed write
        // would leave them beside a feed they do not describe, for a 304 to wrongly confirm. A non-empty directory
        // put where the feed file is, after the cache has been read, makes the write fail.
        try seed(bytes: v1, validators: validators1)
        let obstruct = feedFileURL
        let client = SideEffectFeedClient(response: .updated(data: v2, validators: validators2)) {
            try? FileManager.default.removeItem(at: obstruct)
            try? FileManager.default.createDirectory(at: obstruct, withIntermediateDirectories: false)
            try? Data().write(to: obstruct.appending(path: "occupied"))
        }

        let outcome = try await repository(client).refresh()

        #expect(try outcome == .updated(feed(v2)))
        #expect(FileManager.default.fileExists(atPath: validatorsFileURL.path) == false)
    }

    @Test func aLateSubscriberStartsFromTheLastSavedFeed() async throws {
        // Nothing to catch up on by hand: the stream opens with whatever the earlier refresh left on disk.
        var repository: CachedFeedRepository? = repository(RecordingFeedClient(results: [
            .success(.updated(data: v1, validators: validators1)),
            .success(.updated(data: v2, validators: validators2)),
        ]))
        _ = await repository?.load()
        let feeds = try await #require(repository).feed()
        let opening = await feeds.firstElement()

        _ = await repository?.load()
        repository = nil

        #expect(try opening == feed(v1))
        #expect(try await feeds.collect() == [feed(v2)])
    }

    @Test func aSubscriberThatFallsBehindGetsTheLatestFeedOnly() async throws {
        // The unread opening element is superseded like any other: a subscriber that only starts reading after
        // two downloads sees the second download, not the cache that preceded it.
        var repository: CachedFeedRepository? = repository(RecordingFeedClient(results: [
            .success(.updated(data: v1, validators: validators1)),
            .success(.updated(data: v2, validators: validators2)),
        ]))
        let feeds = try await #require(repository).feed()

        _ = await repository?.load()
        _ = await repository?.load()
        repository = nil

        let collected = await feeds.collect()
        #expect(try collected == [feed(v2)])
    }

    @Test func cancellingOneSubscriptionLeavesTheOthersReceivingUpdates() async throws {
        var repository: CachedFeedRepository? = repository(.success(.updated(data: v1, validators: validators1)))
        let cancelled = try await #require(repository).feed()
        let kept = try await #require(repository).feed()
        _ = await kept.firstElement()
        let iteration = Task { await cancelled.firstElement() }
        iteration.cancel()
        _ = await iteration.value

        _ = await repository?.load()
        repository = nil

        #expect(try await kept.collect() == [feed(v1)])
    }

    /// A directory of its own per test, so Swift Testing's parallel execution never shares a cache.
    private let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)

    private let v1 = Data(#"{"version": "v1", "devices": []}"#.utf8)
    private let v2 = Data(#"{"version": "v2", "devices": []}"#.utf8)
    /// Version v1 again, but with a product: the same feed by identity, different bytes.
    private let v1Reissued = Data(#"""
    {"version": "v1", "devices": [{"id": "00000000-0000-0000-0000-000000000001",
     "product": {"name": "Minimal", "abbrev": "Min"}, "sku": "MIN", "deviceType": "tool", "shortnames": ["MIN"],
     "images": {"default": "0"}, "line": {"id": "airmax", "name": "airMAX"}}]}
    """#.utf8)
    private let validators1 = Validators(etag: #""one""#, lastModified: "Wed, 15 Oct 2026 08:00:00 GMT")
    private let validators2 = Validators(etag: #""two""#)

    // MARK: - Helpers

    private var feedFileURL: URL {
        directory.appending(path: CachedFeedRepository.Constants.feedFile)
    }

    private var validatorsFileURL: URL {
        directory.appending(path: CachedFeedRepository.Constants.validatorsFile)
    }

    /// Puts a cached pair on disk as the repository would have left it.
    private func seed(bytes: Data?, validators: Validators?) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try bytes?.write(to: feedFileURL)
        guard let validators else { return }
        try JSONEncoder().encode(validators).write(to: validatorsFileURL)
    }

    private func repository(_ result: Result<FeedResponse, NetworkError>) -> CachedFeedRepository {
        CachedFeedRepository(client: InMemoryFeedClient(result: result), directory: directory)
    }

    private func repository(_ client: any FeedClient) -> CachedFeedRepository {
        CachedFeedRepository(client: client, directory: directory)
    }

    private func feed(_ data: Data) throws -> Feed {
        try JSONDecoder().decode(Feed.self, from: data)
    }

    private func cachedBytes() throws -> Data {
        try Data(contentsOf: feedFileURL)
    }

    private func cachedValidators() throws -> Validators {
        try JSONDecoder().decode(Validators.self, from: Data(contentsOf: validatorsFileURL))
    }
}

/// Runs `sideEffect` during the fetch, after the repository has read its cache and before it writes, then answers
/// `response`. For changing the disk under a refresh in flight.
private nonisolated struct SideEffectFeedClient: FeedClient {
    let response: FeedResponse
    let sideEffect: @Sendable () -> Void

    func fetch(validators _: Validators) async throws(NetworkError) -> FeedResponse {
        sideEffect()
        return response
    }
}
