import Combine
import Foundation
import OSLog
import Synchronization

/// The production `FeedRepository`: the cached feed from memory or disk first, then a conditional fetch.
///
/// Owns its cache. Two files under `directory` hold the last downloaded bytes and their validators (see
/// `CachedFeedRepository+Disk.swift`), and the in-memory copy in front of them, behind a `Mutex`, is what a second
/// subscription reads. Every step is synchronous, so the pipeline is one `Deferred` chain with no async bridge;
/// `subscribe(on:)` keeps the disk read off the subscriber's thread. See `docs/DECISIONS.md`, "Mutex, not actor".
final nonisolated class CachedFeedRepository: FeedRepository, Sendable {
    private let client: any FeedClient
    /// Where the two cache files live. Internal so the disk extension can reach it.
    let directory: URL
    private let memory = Mutex<Memory>(.unread)

    /// - Parameters:
    ///   - client: the network seam the refresh goes through.
    ///   - directory: the cache directory; tests pass a temporary one.
    init(client: any FeedClient, directory: URL = Constants.defaultDirectory) {
        self.client = client
        self.directory = directory
    }

    // MARK: - FeedRepository

    func feed() -> AnyPublisher<FeedSnapshot, FeedError> {
        Deferred { [self] in
            let cached = cachedFeed()
            let refresh = client.fetch(validators: cached?.validators ?? .empty)
                .mapError(FeedError.network)
                .flatMap { [self] response in integrate(response) }
            guard let cached else { return refresh.eraseToAnyPublisher() }
            // A cached feed makes a failed refresh a stale snapshot instead of an error.
            return refresh
                .catch { error in Self.emit(cached.feed, as: .stale(error)) }
                .prepend(FeedSnapshot(feed: cached.feed, freshness: .cached))
                .eraseToAnyPublisher()
        }
        .subscribe(on: Constants.queue)
        .eraseToAnyPublisher()
    }

    /// One snapshot, then completion: the shape every branch of the pipeline ends in.
    private static func emit(
        _ feed: Feed,
        as freshness: FeedSnapshot.Freshness,
    ) -> AnyPublisher<FeedSnapshot, FeedError> {
        Just(FeedSnapshot(feed: feed, freshness: freshness)).setFailureType(to: FeedError.self).eraseToAnyPublisher()
    }

    // MARK: - Pipeline steps

    /// The cached feed from memory, read from disk the first time and remembered, present or not, after that.
    private func cachedFeed() -> CachedFeed? {
        memory.withLock { memory in
            if case let .loaded(cached) = memory {
                return cached
            }
            let cached = readCachedFeed()
            memory = .loaded(cached)
            return cached
        }
    }

    /// Turns the server's answer into the snapshot to emit, updating the in-memory copy, then saves the download
    /// after the snapshot is out so the screen never waits on disk. Saves nothing on unchanged or on bytes that do
    /// not decode; with a cached feed in memory the failure becomes stale upstream.
    private func integrate(_ response: FeedResponse) -> AnyPublisher<FeedSnapshot, FeedError> {
        switch response {
        case .unchanged:
            guard let held = memory.withLock(\.cachedFeed) else {
                // Unreachable through the real client, which answers unchanged only to a conditional request, and
                // validators only exist beside a cached feed. A 304 with nothing to confirm is the same status error
                // the client itself reports for one (see `docs/DECISIONS.md`).
                return Fail(error: .network(.httpStatus(HTTPStatus.notModified))).eraseToAnyPublisher()
            }
            Logger.caching.info("Feed unchanged, version \(held.feed.version, privacy: .public)")
            return Self.emit(held.feed, as: .current)
        case let .updated(data, validators):
            let downloaded: Feed
            do {
                downloaded = try JSONDecoder().decode(Feed.self, from: data)
            } catch {
                Logger.caching.error("Downloaded feed does not decode: \(error)")
                return Fail(error: .decoding(String(describing: error))).eraseToAnyPublisher()
            }
            let shown = remember(downloaded, validators: validators)
            return Self.emit(shown, as: .current)
                .append(Deferred { [self] in
                    write(Download(data: data, validators: validators))
                    return Empty<FeedSnapshot, FeedError>()
                })
                .eraseToAnyPublisher()
        }
    }

    /// Puts the download in memory and returns the feed to show: the held one when the version is unchanged,
    /// because `version` is the feed's identity (see `docs/DECISIONS.md`), otherwise the downloaded one.
    private func remember(_ downloaded: Feed, validators: Validators) -> Feed {
        memory.withLock { memory in
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
        /// Where the cache read runs, so a subscription from the main thread never blocks on disk.
        static let queue = DispatchQueue(label: "feed-cache", qos: .userInitiated)
    }
}
