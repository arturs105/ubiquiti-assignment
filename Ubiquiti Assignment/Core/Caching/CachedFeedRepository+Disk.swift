import Foundation
import OSLog

/// The two cache files: `feed.json`, the downloaded bytes verbatim, and `validators.json` beside them. Every
/// method here runs on the actor, so reads and writes never interleave.
extension CachedFeedRepository {
    /// The pair on disk, or `nil` after recovering from whatever is wrong with it. Missing validators are not
    /// wrong: the feed loads and the next request is unconditional. A missing, unreadable or undecodable feed is:
    /// both files go, because validators are never sent when nothing could be confirmed by a 304.
    func readCachedFeed() -> CachedFeed? {
        guard let data = try? Data(contentsOf: feedFileURL) else {
            recover(reason: "no readable \(Constants.feedFile)")
            return nil
        }
        let feed: Feed
        do {
            feed = try Self.decodeFeed(data)
        } catch {
            recover(reason: "\(Constants.feedFile) does not decode: \(error)")
            return nil
        }
        let validators = readValidators()
        Logger.caching.info("""
        Loaded cached feed \(feed.version, privacy: .public), \(feed.products.count) products, \
        validators \(validators.isConditional ? "present" : "absent", privacy: .public)
        """)
        return CachedFeed(feed: feed, validators: validators)
    }

    /// Writes the download as both files, each atomically (temporary file then rename), so a crash mid-write leaves
    /// the previous pair intact. Failures are logged and swallowed: the user has the feed already.
    func write(_ download: Download) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try download.data.write(to: feedFileURL, options: .atomic)
            try JSONEncoder().encode(download.validators).write(to: validatorsFileURL, options: .atomic)
            let path = directory.path
            Logger.caching.info("Saved \(download.data.count) bytes and validators to \(path, privacy: .public)")
        } catch {
            Logger.caching.error("Could not save the feed: \(error)")
        }
    }

    /// The one place feed bytes become a `Feed`, for the download and for the cached file alike.
    static func decodeFeed(_ data: Data) throws -> Feed {
        try JSONDecoder().decode(Feed.self, from: data)
    }

    // MARK: - Private helpers

    /// `Validators.empty` when the file is missing or broken: the feed still loads, the next request is unconditional.
    private func readValidators() -> Validators {
        guard let data = try? Data(contentsOf: validatorsFileURL) else { return .empty }
        do {
            return try JSONDecoder().decode(Validators.self, from: data)
        } catch {
            Logger.caching.error("\(Constants.validatorsFile) does not decode, fetching unconditionally: \(error)")
            return .empty
        }
    }

    /// Removes both files so the next launch starts from no cache. A file that is already gone is not an error.
    private func recover(reason: String) {
        Logger.caching.notice("No usable cached feed (\(reason, privacy: .public)), removing the cache files")
        for url in [feedFileURL, validatorsFileURL] where FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                Logger.caching.error("Could not remove \(url.lastPathComponent, privacy: .public): \(error)")
            }
        }
    }

    private var feedFileURL: URL {
        directory.appending(path: Constants.feedFile)
    }

    private var validatorsFileURL: URL {
        directory.appending(path: Constants.validatorsFile)
    }
}
