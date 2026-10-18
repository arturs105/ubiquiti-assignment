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

    func fetch(validators: Validators) async throws(NetworkError) -> FeedResponse {
        let request = Self.request(for: url, validators: validators)
        Logger.networking.info("""
        GET \(url, privacy: .public) \(validators.isConditional ? "conditional" : "unconditional", privacy: .public)
        """)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw .network(error)
        } catch {
            // `URLSession.data(for:)` throws untyped. In practice it is always a `URLError`; anything else is
            // wrapped so the failure type stays `NetworkError` and the original error is still inspectable.
            throw .network(URLError(.unknown, userInfo: [NSUnderlyingErrorKey: error]))
        }
        return try Self.feedResponse(data: data, response: response, conditional: validators.isConditional).get()
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
            let source = response.url?.absoluteString ?? "feed"
            Logger.networking.error("Non-HTTP response from \(source, privacy: .public)")
            return .failure(.invalidResponse)
        }
        Logger.networking.info("HTTP \(http.statusCode), \(data.count) bytes")
        switch http.statusCode {
        case HTTPStatus.ok:
            let validators = Validators(
                etag: http.value(forHTTPHeaderField: Constants.etag),
                lastModified: http.value(forHTTPHeaderField: Constants.lastModified),
            )
            return .success(.updated(data: data, validators: validators))
        case HTTPStatus.notModified where conditional:
            // Only a conditional request can legitimately be answered 304; an unconditional one must send the feed.
            return .success(.unchanged)
        default:
            return .failure(.httpStatus(http.statusCode))
        }
    }
}

extension URLSessionFeedClient {
    nonisolated enum Constants {
        /// The public UIDB feed. The only endpoint the app talks to for product data. The force unwrap on a
        /// compile-time literal is the one accepted exception to the standard; a test evaluates it on every run.
        /// See `docs/DECISIONS.md`.
        static let feedURL = URL(string: "https://static.ui.com/fingerprint/ui/public.json")!

        static let ifNoneMatch = "If-None-Match"
        static let ifModifiedSince = "If-Modified-Since"
        static let etag = "ETag"
        static let lastModified = "Last-Modified"
    }
}
