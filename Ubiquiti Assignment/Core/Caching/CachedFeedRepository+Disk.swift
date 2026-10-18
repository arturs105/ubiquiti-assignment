import Foundation
import OSLog

/// The two cache files: `feed.json`, the downloaded bytes verbatim, and `validators.json` beside them. Every
/// method here runs on the actor, so reads and writes never interleave.
extension CachedFeedRepository {
    /// The pair on disk, or `nil` when there is none or after recovering from whatever is wrong with it. A missing
    /// feed is no cache: only validators left behind on their own are removed. Missing validators are not wrong
    /// either: the feed loads and the next request is unconditional. An unreadable or undecodable feed is: both
    /// files go, because validators are never sent when nothing could be confirmed by a 304.
    func readCachedFeed() -> CachedFeed? {
        guard let data = readFeedFile() else { return nil }
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

    /// What a refresh needs from the cache: the cached feed's version and the validators saved beside it, under the
    /// same recovery rules as `readCachedFeed()`. Proves the file is a feed without decoding its products, so a load
    /// (`feed()` then `refresh()`) decodes the cached products once and logs the lenient decoder's drops once.
    func readCachedHeader() -> CachedHeader? {
        guard let data = readFeedFile() else { return nil }
        let header: FeedHeader
        do {
            header = try JSONDecoder().decode(FeedHeader.self, from: data)
        } catch {
            recover(reason: "\(Constants.feedFile) does not decode: \(error)")
            return nil
        }
        let validators = readValidators()
        Logger.caching.debug("""
        Read cached feed header \(header.version, privacy: .public), \
        validators \(validators.isConditional ? "present" : "absent", privacy: .public)
        """)
        return CachedHeader(version: header.version, validators: validators)
    }

    /// Writes the downloaded bytes and their validators as the two files, each atomically (temporary file then
    /// rename). Two renames cannot be one, so the old validators go first: a crash or a throw at any step leaves
    /// either the previous pair, the previous feed alone, the new feed alone or the new pair. A feed without
    /// validators is a valid cache (the next request is unconditional); new bytes beside old validators, which a 304
    /// would wrongly confirm, never exist. Failures are logged and swallowed: the user has the feed already.
    func write(data: Data, validators: Validators) {
        do {
            let encodedValidators = try JSONEncoder().encode(validators)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: validatorsFileURL.path) {
                try FileManager.default.removeItem(at: validatorsFileURL)
            }
            try data.write(to: feedFileURL, options: .atomic)
            try encodedValidators.write(to: validatorsFileURL, options: .atomic)
            let path = directory.path
            Logger.caching.info("Saved \(data.count) bytes and validators to \(path, privacy: .public)")
        } catch {
            Logger.caching.error("Could not save the feed: \(error)")
        }
    }

    // MARK: - Private helpers

    /// The cached feed's bytes, or `nil`. A missing file is no cache, not a broken one (first launch, a purged
    /// `Library/Caches`): nothing to recover unless validators were left behind on their own. An unreadable one is.
    private func readFeedFile() -> Data? {
        do {
            return try Data(contentsOf: feedFileURL)
        } catch CocoaError.fileReadNoSuchFile {
            if FileManager.default.fileExists(atPath: validatorsFileURL.path) {
                recover(reason: "\(Constants.validatorsFile) without \(Constants.feedFile)")
            } else {
                Logger.caching.info("No cached feed")
            }
            return nil
        } catch {
            recover(reason: "\(Constants.feedFile) is unreadable: \(error)")
            return nil
        }
    }

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

    /// The top level of a feed document: decodes exactly when `Feed` does, because `Feed` decodes each product
    /// leniently and only fails on a missing `version` or a `devices` value that is not an array.
    private nonisolated struct FeedHeader: Decodable {
        let version: String

        private enum CodingKeys: String, CodingKey {
            case version
            case devices
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            version = try container.decode(String.self, forKey: .version)
            _ = try container.nestedUnkeyedContainer(forKey: .devices)
        }
    }
}
