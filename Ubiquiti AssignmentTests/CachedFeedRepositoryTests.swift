import Foundation
import Testing
@testable import Ubiquiti_Assignment

/// A class, not a struct, so `deinit` can remove each test's cache directory once the test is over.
@Suite(.timeLimit(.minutes(1)))
final class CachedFeedRepositoryTests {
    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func noCacheAndANewFeedYieldsOneCurrentSnapshotAndWritesBothFiles() async throws {
        let repository = repository(.success(.updated(data: v1, validators: validators1)))

        let result = await repository.load()

        #expect(try result == .success([FeedSnapshot(feed: feed(v1), freshness: .current)]))
        #expect(try cachedBytes() == v1)
        #expect(try cachedValidators() == validators1)
    }

    @Test func cachedFeedAndUnchangedYieldsCachedThenCurrentWithTheSameFeed() async throws {
        try seed(bytes: v1, validators: validators1)
        let repository = repository(.success(.unchanged))

        let result = await repository.load()

        let cached = try feed(v1)
        #expect(result == .success([
            FeedSnapshot(feed: cached, freshness: .cached),
            FeedSnapshot(feed: cached, freshness: .current),
        ]))
        #expect(try cachedBytes() == v1)
        #expect(try cachedValidators() == validators1)
    }

    @Test func cachedFeedAndANewVersionYieldsCachedThenCurrentWithTheNewFeedAndRewritesTheFiles() async throws {
        try seed(bytes: v1, validators: validators1)
        let repository = repository(.success(.updated(data: v2, validators: validators2)))

        let result = await repository.load()

        #expect(try result == .success([
            FeedSnapshot(feed: feed(v1), freshness: .cached),
            FeedSnapshot(feed: feed(v2), freshness: .current),
        ]))
        #expect(try cachedBytes() == v2)
        #expect(try cachedValidators() == validators2)
    }

    @Test func cachedFeedAndTheSameVersionYieldsCurrentWithTheHeldFeedAndStillSavesTheDownload() async throws {
        try seed(bytes: v1, validators: validators1)
        let repository = repository(.success(.updated(data: v1Reissued, validators: validators2)))

        let result = await repository.load()

        let held = try feed(v1)
        #expect(result == .success([
            FeedSnapshot(feed: held, freshness: .cached),
            FeedSnapshot(feed: held, freshness: .current),
        ]))
        #expect(try cachedBytes() == v1Reissued)
        #expect(try cachedValidators() == validators2)
    }

    @Test func cachedFeedAndAFailedFetchYieldsCachedThenStaleAndLeavesTheFilesAlone() async throws {
        try seed(bytes: v1, validators: validators1)
        let repository = repository(.failure(.network(URLError(.notConnectedToInternet))))

        let result = await repository.load()

        let cached = try feed(v1)
        #expect(result == .success([
            FeedSnapshot(feed: cached, freshness: .cached),
            FeedSnapshot(feed: cached, freshness: .stale(.network(.network(URLError(.notConnectedToInternet))))),
        ]))
        #expect(try cachedBytes() == v1)
        #expect(try cachedValidators() == validators1)
    }

    @Test func noCacheAndAFailedFetchFailsWithTheNetworkError() async {
        let repository = repository(.failure(.httpStatus(503)))

        let result = await repository.load()

        #expect(result == .failure(.network(.httpStatus(503))))
        #expect(FileManager.default.fileExists(atPath: directory.path) == false)
    }

    @Test func cachedFeedAndUndecodableBytesYieldsCachedThenStaleWithTheDecodingErrorAndLeavesTheFilesAlone(
    ) async throws {
        try seed(bytes: v1, validators: validators1)
        let repository = repository(.success(.updated(data: Data("<html>".utf8), validators: validators2)))

        let result = await repository.load()

        let cached = try feed(v1)
        let snapshots = try result.get()
        #expect(snapshots.count == 2)
        #expect(snapshots.first == FeedSnapshot(feed: cached, freshness: .cached))
        #expect(snapshots.last?.feed == cached)
        guard case .stale(.decoding) = snapshots.last?.freshness else {
            Issue.record("Expected a stale snapshot with a decoding error, got \(String(describing: snapshots.last))")
            return
        }
        #expect(try cachedBytes() == v1)
        #expect(try cachedValidators() == validators1)
    }

    @Test func noCacheAndUndecodableBytesFailsWithTheDecodingErrorAndWritesNothing() async {
        let repository = repository(.success(.updated(data: Data("<html>".utf8), validators: validators2)))

        let result = await repository.load()

        guard case .failure(.decoding) = result else {
            Issue.record("Expected a decoding failure, got \(result)")
            return
        }
        #expect(FileManager.default.fileExists(atPath: directory.path) == false)
    }

    @Test func cachedFeedWithoutValidatorsLoadsAndFetchesUnconditionally() async throws {
        try seed(bytes: v1, validators: nil)
        let client = RecordingFeedClient(result: .success(.updated(data: v2, validators: validators2)))

        let result = await repository(client).load()

        #expect(client.receivedValidators == [.empty])
        #expect(try result == .success([
            FeedSnapshot(feed: feed(v1), freshness: .cached),
            FeedSnapshot(feed: feed(v2), freshness: .current),
        ]))
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
        #expect(result == .failure(.network(.httpStatus(500))))
        #expect(FileManager.default.fileExists(atPath: validatorsFileURL.path) == false)
    }

    @Test(arguments: [Data("not json".utf8), Data(#"{"version": 1}"#.utf8), Data(#"{"devices": []}"#.utf8)])
    func anUndecodableFeedFileIsNoCacheAndBothFilesAreDeleted(bytes: Data) async throws {
        try seed(bytes: bytes, validators: validators1)
        let client = RecordingFeedClient(result: .failure(.httpStatus(500)))

        let result = await repository(client).load()

        #expect(client.receivedValidators == [.empty])
        #expect(result == .failure(.network(.httpStatus(500))))
        #expect(FileManager.default.fileExists(atPath: feedFileURL.path) == false)
        #expect(FileManager.default.fileExists(atPath: validatorsFileURL.path) == false)
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
        #expect(result == .failure(.network(.httpStatus(500))))
        #expect(FileManager.default.fileExists(atPath: feedFileURL.path) == false)
        #expect(FileManager.default.fileExists(atPath: validatorsFileURL.path) == false)
    }

    @Test func aCachedFeedWithNoProductsIsAValidEmptyCache() async throws {
        try seed(bytes: v1, validators: validators1)
        let client = RecordingFeedClient(result: .success(.unchanged))

        let result = await repository(client).load()

        #expect(client.receivedValidators == [validators1])
        #expect(try result.get().first?.feed.products.isEmpty == true)
    }

    @Test func aSecondLoadServesTheCachedFeedFromMemoryNotDisk() async throws {
        try seed(bytes: v1, validators: validators1)
        let repository = repository(.failure(.httpStatus(500)))
        _ = await repository.load()
        try FileManager.default.removeItem(at: directory)

        let result = await repository.load()

        let cached = try feed(v1)
        #expect(result == .success([
            FeedSnapshot(feed: cached, freshness: .cached),
            FeedSnapshot(feed: cached, freshness: .stale(.network(.httpStatus(500)))),
        ]))
    }

    @Test func aSecondLoadSendsTheValidatorsOfTheLastDownload() async {
        let client = RecordingFeedClient(result: .success(.updated(data: v1, validators: validators1)))
        let repository = repository(client)
        _ = await repository.load()

        _ = await repository.load()

        #expect(client.receivedValidators == [.empty, validators1])
    }

    @Test func unchangedWithoutACacheIsAStatusErrorNotASnapshot() async {
        // The real client never answers unchanged to an unconditional request; the repository treats it the same way.
        let repository = repository(.success(.unchanged))

        let result = await repository.load()

        #expect(result == .failure(.network(.httpStatus(304))))
    }

    @Test func refreshWithoutAskingForTheCachedSnapshotStillLoadsTheCache() async throws {
        // Pull to refresh calls refresh() alone; the validators and the stale fallback must not depend on
        // cachedSnapshot() having run first.
        try seed(bytes: v1, validators: validators1)
        let client = RecordingFeedClient(result: .failure(.httpStatus(500)))

        let snapshot = try await repository(client).refresh()

        #expect(client.receivedValidators == [validators1])
        #expect(try snapshot == FeedSnapshot(feed: feed(v1), freshness: .stale(.network(.httpStatus(500)))))
    }

    @Test func refreshWithoutACacheAndAFailedFetchThrows() async {
        let repository = repository(.failure(.httpStatus(503)))

        await #expect(throws: FeedError.network(.httpStatus(503))) {
            try await repository.refresh()
        }
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

    private func repository(_ client: RecordingFeedClient) -> CachedFeedRepository {
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
