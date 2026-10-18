import Foundation
import OSLog

/// The production `FeedRepository`: one stream that starts with the cached feed from disk and continues with every
/// feed a conditional fetch saves, and the fetch itself.
///
/// Owns its cache. Two files under `directory` hold the last downloaded bytes and their validators (see
/// `CachedFeedRepository+Disk.swift`). No feed is held in memory: every call starts from disk, so nothing held here
/// can drift from what is saved. The only other state is the list of `feed()` subscribers, each a stream
/// continuation that is handed the feed right after it is written. Disk is read and written on the actor, off
/// whatever task asked; the network call is the only suspension point. See `docs/DECISIONS.md`, "The repository
/// holds no feed in memory" and "One stream, not two calls".
actor CachedFeedRepository: FeedRepository {
    private let client: any FeedClient
    /// Where the two cache files live. Internal so the disk extension can reach it.
    let directory: URL
    /// One continuation per live `feed()` subscription, keyed so a cancelled one can be dropped.
    private var subscribers: [UUID: AsyncStream<Feed?>.Continuation] = [:]

    /// - Parameters:
    ///   - client: the network seam the refresh goes through.
    ///   - directory: the cache directory; tests pass a temporary one.
    init(client: any FeedClient, directory: URL = Constants.defaultDirectory) {
        self.client = client
        self.directory = directory
    }

    deinit {
        for continuation in subscribers.values {
            continuation.finish()
        }
    }

    // MARK: - FeedRepository

    func feed() -> AsyncStream<Feed?> {
        // Newest-one buffering: a subscriber that is mid-render when two downloads land only wants the last, and a
        // cached feed nobody has read yet is superseded the same way.
        let (stream, continuation) = AsyncStream.makeStream(of: Feed?.self, bufferingPolicy: .bufferingNewest(1))
        // Read and register in one actor turn: no refresh can save a feed between the two, so the subscriber sees
        // what disk holds now and then every change, with no gap and no duplicate.
        continuation.yield(readCachedFeed()?.feed)
        let id = UUID()
        subscribers[id] = continuation
        continuation.onTermination = { [weak self] _ in
            // Runs on whatever task cancelled the iteration; the dictionary is actor state, so hop back.
            Task { await self?.forget(id) }
        }
        return stream
    }

    func refresh() async throws(FeedError) -> FeedRefresh {
        // Read, not remembered: validators are only ever sent beside a feed that decodes, and reading the file is
        // what proves that. The header, not the whole feed: `feed()` has already decoded the products this load.
        let cached = readCachedHeader()
        let validators = cached?.validators ?? .empty
        let response: FeedResponse
        do {
            response = try await client.fetch(validators: validators)
        } catch {
            throw .network(error)
        }
        // From here the actor runs to completion without interleaving, so two overlapping refreshes decode and
        // save one after the other and the files never come from different downloads.
        switch response {
        case .unchanged:
            guard validators.isConditional else {
                // Unreachable through the real client, which answers unchanged only to a conditional request. A
                // 304 with nothing to confirm is the same status error the client itself reports for one (see
                // `docs/DECISIONS.md`).
                throw .network(.httpStatus(HTTPStatus.notModified))
            }
            Logger.caching.info("Feed unchanged")
            return .unchanged
        case let .updated(data, validators):
            let feed: Feed
            do {
                feed = try Self.decodeFeed(data)
            } catch {
                Logger.caching.error("Downloaded feed does not decode: \(error)")
                throw .decoding(String(describing: error))
            }
            if feed.version == cached?.version {
                // Same feed by identity (see `docs/DECISIONS.md`): saved anyway, for the new validators.
                Logger.caching.info("""
                Downloaded feed has the cached version \(feed.version, privacy: .public), saving it for the new validators
                """)
            } else {
                Logger.caching.info("Downloaded feed version \(feed.version, privacy: .public)")
            }
            // The caller waits on the write: milliseconds, and the cached feed is already on screen by then.
            write(Download(data: data, validators: validators))
            // Subscribers hear of a feed only after the save is attempted, so what they show is what disk holds unless
            // the write failed, which is logged and does not keep the feed from the screen.
            for continuation in subscribers.values {
                continuation.yield(feed)
            }
            return .updated(feed)
        }
    }

    // MARK: - Private helpers

    private func forget(_ id: UUID) {
        subscribers[id] = nil
    }
}

extension CachedFeedRepository {
    /// The pair on disk, decoded: the feed and the validators that came with its bytes.
    nonisolated struct CachedFeed: Sendable {
        let feed: Feed
        let validators: Validators
    }

    /// What a refresh reads from the cache: the cached feed's version and its validators, without its products.
    nonisolated struct CachedHeader: Sendable {
        let version: String
        let validators: Validators
    }

    /// Fresh bytes and validators the server just sent, as they go to disk.
    nonisolated struct Download: Sendable {
        let data: Data
        let validators: Validators
    }

    /// File names and locations shared by the pipeline, the disk extension and the tests.
    nonisolated enum Constants {
        /// `Library/Caches/Feed/`: purgeable by the system, which the recovery rules tolerate.
        static let defaultDirectory = URL.cachesDirectory.appending(path: "Feed")
        static let feedFile = "feed.json"
        static let validatorsFile = "validators.json"
    }
}
