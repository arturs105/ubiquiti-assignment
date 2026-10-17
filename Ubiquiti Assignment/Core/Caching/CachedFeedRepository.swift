import Foundation
import OSLog

/// The production `FeedRepository`: the cached feed from disk, then a conditional fetch that replaces it.
///
/// Owns its cache. Two files under `directory` hold the last downloaded bytes and their validators (see
/// `CachedFeedRepository+Disk.swift`), and that is all the state there is: every call starts from disk, so nothing
/// held here can drift from what is saved. Disk is read and written on the actor, off whatever task asked; the
/// network call is the only suspension point. See `docs/DECISIONS.md`, "The repository holds no feed in memory".
actor CachedFeedRepository: FeedRepository {
    private let client: any FeedClient
    /// Where the two cache files live. Internal so the disk extension can reach it.
    let directory: URL

    /// - Parameters:
    ///   - client: the network seam the refresh goes through.
    ///   - directory: the cache directory; tests pass a temporary one.
    init(client: any FeedClient, directory: URL = Constants.defaultDirectory) {
        self.client = client
        self.directory = directory
    }

    // MARK: - FeedRepository

    func cachedFeed() -> Feed? {
        readCachedFeed()?.feed
    }

    func refresh() async throws(FeedError) -> FeedRefresh {
        // Read, not remembered: validators are only ever sent beside a feed that decodes, and reading the pair is
        // what proves that. Milliseconds for one feed, on the actor, off the main actor.
        let validators = readCachedFeed()?.validators ?? .empty
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
            Logger.caching.info("Downloaded feed version \(feed.version, privacy: .public)")
            // The caller waits on the write: milliseconds, and the cached feed is already on screen by then.
            write(Download(data: data, validators: validators))
            return .updated(feed)
        }
    }
}

extension CachedFeedRepository {
    /// The pair on disk, decoded: the feed and the validators that came with its bytes.
    nonisolated struct CachedFeed: Sendable {
        let feed: Feed
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
