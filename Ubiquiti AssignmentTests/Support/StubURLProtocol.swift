import Foundation
import Synchronization
@testable import Ubiquiti_Assignment

/// Replays a scripted answer for each URL and records the request it saw, so `URLSessionFeedClient` is tested
/// without the live server. Scripts are keyed by URL and every test uses its own URL, so tests run in parallel.
final nonisolated class StubURLProtocol: URLProtocol {
    /// What the stub answers for one URL.
    enum Script: Sendable {
        case http(status: Int, headers: [String: String] = [:], body: Data = Data())
        case nonHTTP
        case failure(URLError)
    }

    private static let scripts = Mutex<[URL: Script]>([:])
    private static let requests = Mutex<[URL: URLRequest]>([:])

    /// The production feed configuration with every request routed through the stub.
    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.feed()
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    /// Registers `script` under a fresh URL and returns that URL for the client under test.
    static func script(_ script: Script) -> URL {
        let url = URL(string: "https://stub.invalid/\(UUID().uuidString)")!
        scripts.withLock { $0[url] = script }
        return url
    }

    /// The request the stub received for `url`, if any.
    static func request(for url: URL) -> URLRequest? {
        requests.withLock { $0[url] }
    }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let client, let url = request.url else { return }
        Self.requests.withLock { $0[url] = request }
        guard let script = Self.scripts.withLock({ $0[url] }) else {
            client.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        switch script {
        case let .http(status, headers, body):
            let response = HTTPURLResponse(
                url: url,
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: headers,
            )!
            client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client.urlProtocol(self, didLoad: body)
            client.urlProtocolDidFinishLoading(self)
        case .nonHTTP:
            let response = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
            client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client.urlProtocolDidFinishLoading(self)
        case let .failure(error):
            client.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
