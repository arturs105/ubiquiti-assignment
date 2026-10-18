import Foundation
import Kingfisher
import OSLog
import UIKit

/// The production `ImageLoader`: Kingfisher's manager over a cache and a downloader of this loader's own.
///
/// The only file that imports Kingfisher. The library owns what the caching standard once asked of a hand-rolled
/// actor: one download per URL however many rows ask at once, a memory cache that empties on a memory warning, and
/// a disk cache that expires. This type holds no state of its own beyond the manager, so it is a `final class`
/// rather than an actor: nothing here needs isolating. Why a library over the actor is in `docs/DECISIONS.md`,
/// 2026-10-18 "Images load through Kingfisher".
final nonisolated class KingfisherImageLoader: ImageLoader, Sendable {
    private let manager: KingfisherManager

    /// The production loader: Kingfisher's default cache location under `Library/Caches`.
    ///
    /// - Parameter sessionConfiguration: the downloader's session. Fail-fast and cache-free by default.
    convenience init(sessionConfiguration: URLSessionConfiguration = .images()) {
        self.init(cache: ImageCache(name: Constants.cacheName), sessionConfiguration: sessionConfiguration)
    }

    /// A loader whose disk cache lives under `directory`, for tests that want a cache of their own to inspect and
    /// remove. Throws when the directory cannot be created.
    convenience init(directory: URL, sessionConfiguration: URLSessionConfiguration = .images()) throws {
        let cache = try ImageCache(name: Constants.cacheName, cacheDirectoryURL: directory)
        self.init(cache: cache, sessionConfiguration: sessionConfiguration)
    }

    private init(cache: ImageCache, sessionConfiguration: URLSessionConfiguration) {
        cache.diskStorage.config.expiration = .days(Constants.diskExpirationDays)
        cache.diskStorage.config.sizeLimit = Constants.diskSizeLimit
        let downloader = ImageDownloader(name: Constants.downloaderName)
        downloader.sessionConfiguration = sessionConfiguration
        manager = KingfisherManager(downloader: downloader, cache: cache)
    }

    // MARK: - ImageLoader

    func image(for product: Product, size: ImageSize) async throws(ImageError) -> UIImage {
        let url = product.imageURL(size: size)
        let result: RetrieveImageResult
        do {
            // Background decode: the first draw of a hero must not decode a PNG on the main thread. No processor:
            // the CDN already rendered the requested width.
            result = try await manager.retrieveImage(with: url, options: [.backgroundDecode])
        } catch let error as KingfisherError {
            let mapped = Self.imageError(from: error)
            if mapped != .cancelled {
                Logger.images.error("""
                \(String(describing: size), privacy: .public) image for \(product.id, privacy: .public) failed: \
                \(error.localizedDescription, privacy: .public)
                """)
            }
            throw mapped
        } catch is CancellationError {
            // A task cancelled before the download starts gets Swift's error, not Kingfisher's.
            throw .cancelled
        } catch {
            // `retrieveImage` documents `KingfisherError` as its only other failure. Anything else is wrapped so
            // the failure type stays `ImageError` and the original error is still inspectable.
            throw .network(.network(URLError(.unknown, userInfo: [NSUnderlyingErrorKey: error])))
        }
        Logger.images.debug("""
        \(String(describing: size), privacy: .public) image for \(product.id, privacy: .public) from \
        \(String(describing: result.cacheType), privacy: .public)
        """)
        return result.image
    }

    // MARK: - Private helpers

    /// Kingfisher's error tree folded into the three cases a screen can act on.
    private static func imageError(from error: KingfisherError) -> ImageError {
        switch error {
        case .requestError(.taskCancelled), .requestError(.asyncTaskContextCancelled):
            .cancelled
        case let .responseError(.URLSessionError(underlying)):
            Self.imageError(fromSession: underlying)
        case let .responseError(.invalidHTTPStatusCode(response)):
            .network(.httpStatus(response.statusCode))
        case .responseError(.invalidURLResponse), .responseError(.noURLResponse):
            .network(.invalidResponse)
        default:
            // Undecodable bytes (`processorError`), a cache that could not hand the file back, a request Kingfisher
            // refused: the screen shows the failure image for each, and the reason is in the log.
            .invalidImage
        }
    }

    private static func imageError(fromSession underlying: any Error) -> ImageError {
        guard let urlError = underlying as? URLError else {
            return .network(.network(URLError(.unknown, userInfo: [NSUnderlyingErrorKey: underlying])))
        }
        // The session reports a cancelled task as `URLError.cancelled` when the cancel lands before Kingfisher's
        // own bookkeeping does; it is the same cancellation to the caller.
        return urlError.code == .cancelled ? .cancelled : .network(.network(urlError))
    }
}

extension KingfisherImageLoader {
    nonisolated enum Constants {
        /// Names the disk cache directory and the IO queue. Not "default": Kingfisher reserves that name.
        static let cacheName = "ProductImages"
        static let downloaderName = "ProductImages"
        /// Product images change essentially never; 30 days means a weekly user never re-downloads a thumbnail.
        static let diskExpirationDays = 30
        /// 698 products at two sizes stays well under this; the cap only bounds a cache that never expires in use.
        static let diskSizeLimit: UInt = 100 * 1024 * 1024
    }
}
