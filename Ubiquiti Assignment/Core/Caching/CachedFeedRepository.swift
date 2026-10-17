import Foundation
import OSLog

/// The production `FeedRepository`: the cached feed from memory or disk first, then a conditional fetch.
///
/// Owns its cache. Two files under `directory` hold the last downloaded bytes and their validators (see
/// `CachedFeedRepository+Disk.swift`), and the in-memory copy in front of them is actor state, so a second load
/// reads memory. Disk is read and written on the actor, off whatever task asked; the network call is the only
/// suspension point. See `docs/DECISIONS.md`, "`CachedFeedRepository` is an `actor` with two async methods".
actor CachedFeedRepository: FeedRepository {
    private let client: any FeedClient
    /// Where the two cache files live. Internal so the disk extension can reach it.
    let directory: URL
    private var memory = Memory.unread

    /// - Parameters:
    ///   - client: the network seam the refresh goes through.
    ///   - directory: the cache directory; tests pass a temporary one.
    init(client: any FeedClient, directory: URL = Constants.defaultDirectory) {
        self.client = client
        self.directory = directory
    }

    // MARK: - FeedRepository

    func cachedSnapshot() -> FeedSnapshot? {
        cachedFeed().map { FeedSnapshot(feed: $0.feed, freshness: .cached) }
    }

    func refresh() async throws(FeedError) -> FeedSnapshot {
        let validators = cachedFeed()?.validators ?? .empty
        let response: FeedResponse
        do {
            response = try await client.fetch(validators: validators)
        } catch {
            return try staleOrThrow(.network(error))
        }
        // Memory is read again after the await: a concurrent refresh may have landed a newer feed meanwhile, and
        // the actor runs this method to completion without interleaving from here on.
        do {
            return try integrate(response)
        } catch {
            return try staleOrThrow(error)
        }
    }

    // MARK: - Pipeline steps

    /// The cached feed from memory, read from disk the first time and remembered, present or not, after that.
    private func cachedFeed() -> CachedFeed? {
        if case let .loaded(cached) = memory {
            return cached
        }
        let cached = readCachedFeed()
        memory = .loaded(cached)
        return cached
    }

    /// Turns the server's answer into the snapshot to return, updating the in-memory copy and saving the download.
    /// Saves nothing on unchanged or on bytes that do not decode; with a cached feed the failure becomes stale
    /// in the caller.
    private func integrate(_ response: FeedResponse) throws(FeedError) -> FeedSnapshot {
        switch response {
        case .unchanged:
            guard let held = memory.cachedFeed else {
                // Unreachable through the real client, which answers unchanged only to a conditional request, and
                // validators only exist beside a cached feed. A 304 with nothing to confirm is the same status error
                // the client itself reports for one (see `docs/DECISIONS.md`).
                throw .network(.httpStatus(HTTPStatus.notModified))
            }
            Logger.caching.info("Feed unchanged, version \(held.feed.version, privacy: .public)")
            return FeedSnapshot(feed: held.feed, freshness: .current)
        case let .updated(data, validators):
            let downloaded: Feed
            do {
                downloaded = try Self.decodeFeed(data)
            } catch {
                Logger.caching.error("Downloaded feed does not decode: \(error)")
                throw .decoding(String(describing: error))
            }
            let shown = remember(downloaded, validators: validators)
            // The write is on the actor, so two overlapping refreshes save their pairs one after the other and the
            // files never come from different downloads. The caller waits on it: milliseconds, and the cached
            // snapshot is already on screen by then.
            write(Download(data: data, validators: validators))
            return FeedSnapshot(feed: shown, freshness: .current)
        }
    }

    /// Puts the download in memory and returns the feed to show: the held one when the version is unchanged,
    /// because `version` is the feed's identity (see `docs/DECISIONS.md`), otherwise the downloaded one.
    private func remember(_ downloaded: Feed, validators: Validators) -> Feed {
        let feed: Feed
        if let held = memory.cachedFeed, held.feed.version == downloaded.version {
            Logger.caching.info("Downloaded feed has the held version \(held.feed.version, privacy: .public)")
            feed = held.feed
        } else {
            Logger.caching.info("New feed version \(downloaded.version, privacy: .public)")
            feed = downloaded
        }
        memory = .loaded(CachedFeed(feed: feed, validators: validators))
        return feed
    }

    /// A failed refresh is a stale snapshot while a cached feed stands, and the error itself when nothing can be
    /// shown.
    private func staleOrThrow(_ error: FeedError) throws(FeedError) -> FeedSnapshot {
        guard let held = memory.cachedFeed else { throw error }
        return FeedSnapshot(feed: held.feed, freshness: .stale(error))
    }
}

extension CachedFeedRepository {
    /// What the repository holds in memory: the decoded feed and the validators that came with its bytes.
    nonisolated struct CachedFeed: Sendable {
        let feed: Feed
        let validators: Validators
    }

    /// Fresh bytes and validators the server just sent, as they go to disk.
    nonisolated struct Download: Sendable {
        let data: Data
        let validators: Validators
    }

    /// Whether disk has been consulted yet, and what it or the last download left in memory.
    private nonisolated enum Memory {
        case unread
        case loaded(CachedFeed?)

        var cachedFeed: CachedFeed? {
            if case let .loaded(cached) = self {
                return cached
            }
            return nil
        }
    }

    /// File names and locations shared by the pipeline, the disk extension and the tests.
    nonisolated enum Constants {
        /// `Library/Caches/Feed/`: purgeable by the system, which the recovery rules tolerate.
        static let defaultDirectory = URL.cachesDirectory.appending(path: "Feed")
        static let feedFile = "feed.json"
        static let validatorsFile = "validators.json"
    }
}
