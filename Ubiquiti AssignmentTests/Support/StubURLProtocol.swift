import Foundation
import Synchronization
@testable import Ubiquiti_Assignment

/// Replays a scripted answer for each URL and records the requests it saw, so `URLSessionFeedClient` and
/// `KingfisherImageLoader` are tested without the live servers. Scripts are keyed by URL and every test uses its
/// own URL, so tests run in parallel.
final nonisolated class StubURLProtocol: URLProtocol {
    /// What the stub answers for one URL.
    enum Script: Sendable {
        case http(status: Int, headers: [String: String] = [:], body: Data = Data())
        case nonHTTP
        case failure(URLError)
        /// Never answers, so a test can cancel the task that waits on it.
        case hang
        /// Answers like `http` once `release(_:)` is called for the URL, so a test can start several callers
        /// against one request before it completes.
        case held(status: Int, body: Data = Data())
    }

    private static let scripts = Mutex<[URL: Script]>([:])
    private static let requests = Mutex<[URL: [URLRequest]]>([:])
    private static let released = Mutex<Set<URL>>([])
    /// How often a held request checks whether it was released, in seconds.
    private static let releasePollInterval: TimeInterval = 0.01

    /// The production feed configuration with every request routed through the stub.
    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.feed()
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    /// Registers `script` under a fresh URL and returns that URL for the client under test.
    static func script(_ script: Script) -> URL {
        let url = URL(string: "https://stub.invalid/\(UUID().uuidString)")!
        self.script(script, at: url)
        return url
    }

    /// Registers `script` under `url`, for a client that builds its own URLs. The caller keeps `url` unique.
    static func script(_ script: Script, at url: URL) {
        scripts.withLock { $0[url] = script }
    }

    /// The last request the stub received for `url`, if any.
    static func request(for url: URL) -> URLRequest? {
        requests.withLock { $0[url]?.last }
    }

    /// How many requests the stub received for `url`.
    static func requestCount(for url: URL) -> Int {
        requests.withLock { $0[url]?.count ?? 0 }
    }

    /// Lets every `held` request for `url` answer.
    static func release(_ url: URL) {
        _ = released.withLock { $0.insert(url) }
    }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let client, let url = request.url else { return }
        Self.requests.withLock { $0[url, default: []].append(request) }
        guard let script = Self.scripts.withLock({ $0[url] }) else {
            client.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        switch script {
        case let .http(status, headers, body):
            answer(status: status, headers: headers, body: body, url: url, client: client)
        case .nonHTTP:
            let response = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
            client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client.urlProtocolDidFinishLoading(self)
        case let .failure(error):
            client.urlProtocol(self, didFailWithError: error)
        case .hang:
            break
        case .held:
            answerWhenReleased()
        }
    }

    override func stopLoading() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }

    // MARK: - Private helpers

    /// Checks on the loading thread's run loop, where `URLProtocol` expects its client to be called, until the
    /// test releases the URL; a cancelled request stops the checks in `stopLoading()`.
    @objc private func answerWhenReleased() {
        guard let client, let url = request.url, case let .held(status, body) = Self.scripts.withLock({ $0[url] })
        else { return }
        guard Self.released.withLock({ $0.contains(url) }) else {
            perform(#selector(answerWhenReleased), with: nil, afterDelay: Self.releasePollInterval)
            return
        }
        answer(status: status, headers: [:], body: body, url: url, client: client)
    }

    private func answer(status: Int, headers: [String: String], body: Data, url: URL, client: any URLProtocolClient) {
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)!
        client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client.urlProtocol(self, didLoad: body)
        client.urlProtocolDidFinishLoading(self)
    }
}
