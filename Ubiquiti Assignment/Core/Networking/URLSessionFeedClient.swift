import Combine
import Foundation
import OSLog

/// The production `FeedClient`: one conditional GET against the public UIDB URL on a cache-free session.
nonisolated struct URLSessionFeedClient: FeedClient {
    private let url: URL
    private let session: URLSession

    init(url: URL = Constants.feedURL, session: URLSession = .feed) {
        self.url = url
        self.session = session
    }

    // MARK: - FeedClient

    func fetch(validators: Validators) -> AnyPublisher<FeedResponse, NetworkError> {
        Deferred { [url, session] in
            let request = Self.request(for: url, validators: validators)
            Logger.networking.info("GET \(url) \(validators.isConditional ? "conditional" : "unconditional")")
            return session.dataTaskPublisher(for: request)
                .mapError(NetworkError.network)
                .flatMap { data, response in
                    Self.feedResponse(data: data, response: response, conditional: validators.isConditional).publisher
                }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Private helpers

    private static func request(for url: URL, validators: Validators) -> URLRequest {
        var request = URLRequest(url: url)
        if let etag = validators.etag {
            request.setValue(etag, forHTTPHeaderField: Constants.ifNoneMatch)
        }
        if let lastModified = validators.lastModified {
            request.setValue(lastModified, forHTTPHeaderField: Constants.ifModifiedSince)
        }
        return request
    }

    private static func feedResponse(
        data: Data,
        response: URLResponse,
        conditional: Bool,
    ) -> Result<FeedResponse, NetworkError> {
        guard let http = response as? HTTPURLResponse else {
            Logger.networking.error("Non-HTTP response from \(response.url?.absoluteString ?? "feed")")
            return .failure(.invalidResponse)
        }
        Logger.networking.info("HTTP \(http.statusCode), \(data.count) bytes")
        switch http.statusCode {
        case Constants.ok:
            let validators = Validators(
                etag: http.value(forHTTPHeaderField: Constants.etag),
                lastModified: http.value(forHTTPHeaderField: Constants.lastModified),
            )
            return .success(.updated(data: data, validators: validators))
        case Constants.notModified where conditional:
            // Only a conditional request can legitimately be answered 304; an unconditional one must send the feed.
            return .success(.unchanged)
        default:
            return .failure(.httpStatus(http.statusCode))
        }
    }
}

extension URLSessionFeedClient {
    nonisolated enum Constants {
        /// The public UIDB feed. The only endpoint the app talks to for product data.
        static let feedURL = URL(string: "https://static.ui.com/fingerprint/ui/public.json")!

        static let ifNoneMatch = "If-None-Match"
        static let ifModifiedSince = "If-Modified-Since"
        static let etag = "ETag"
        static let lastModified = "Last-Modified"
        static let ok = 200
        static let notModified = 304
    }
}

extension URLSession {
    /// A session for the feed only: no cache, so the feed's 24-hour `max-age` can never hide a changed feed from
    /// the conditional request, and no waiting for connectivity, so an offline launch fails fast and falls back to
    /// the cached feed. Images use a separate, cached session.
    nonisolated static let feed: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }()
}
