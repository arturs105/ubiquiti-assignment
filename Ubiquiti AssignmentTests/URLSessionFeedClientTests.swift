import Foundation
import Testing
@testable import Ubiquiti_Assignment

@Suite(.timeLimit(.minutes(1)))
struct URLSessionFeedClientTests {
    private let body = Data(#"{"version": "v1", "devices": []}"#.utf8)
    private let etag = #""abc""#
    private let lastModified = "Wed, 15 Oct 2026 08:00:00 GMT"
    private var validators: Validators { Validators(etag: etag, lastModified: lastModified) }

    @Test func defaultFeedURLIsThePublicUIDBFeed() {
        // Evaluates the force-unwrapped literal, so a typo that made it unparseable fails here, not at launch.
        let url = URLSessionFeedClient.Constants.feedURL

        #expect(url.absoluteString == "https://static.ui.com/fingerprint/ui/public.json")
        #expect(url.host() == "static.ui.com")
    }

    @Test func fullResponseCarriesTheExactBytesAndBothValidators() async throws {
        let url = StubURLProtocol.script(.http(
            status: 200,
            headers: ["ETag": etag, "Last-Modified": lastModified],
            body: body,
        ))

        let response = try await client(url).fetch(validators: .empty)

        #expect(response == .updated(data: body, validators: validators))
    }

    @Test func fullResponseWithoutValidatorHeadersYieldsNilValidators() async throws {
        let url = StubURLProtocol.script(.http(status: 200, body: body))

        let response = try await client(url).fetch(validators: .empty)

        #expect(response == .updated(data: body, validators: .empty))
    }

    @Test func validatorsAreSentVerbatimAsConditionalHeaders() async throws {
        let url = StubURLProtocol.script(.http(status: 304))

        _ = try await client(url).fetch(validators: validators)

        let request = StubURLProtocol.request(for: url)
        #expect(request?.value(forHTTPHeaderField: "If-None-Match") == etag)
        #expect(request?.value(forHTTPHeaderField: "If-Modified-Since") == lastModified)
    }

    @Test func etagAloneIsSentWithoutIfModifiedSince() async throws {
        let url = StubURLProtocol.script(.http(status: 304))

        _ = try await client(url).fetch(validators: Validators(etag: etag, lastModified: nil))

        let request = StubURLProtocol.request(for: url)
        #expect(request?.value(forHTTPHeaderField: "If-None-Match") == etag)
        #expect(request?.value(forHTTPHeaderField: "If-Modified-Since") == nil)
    }

    @Test func lastModifiedAloneIsSentWithoutIfNoneMatch() async throws {
        let url = StubURLProtocol.script(.http(status: 304))

        _ = try await client(url).fetch(validators: Validators(etag: nil, lastModified: lastModified))

        let request = StubURLProtocol.request(for: url)
        #expect(request?.value(forHTTPHeaderField: "If-None-Match") == nil)
        #expect(request?.value(forHTTPHeaderField: "If-Modified-Since") == lastModified)
    }

    @Test func noValidatorsMeansNoConditionalHeaders() async throws {
        let url = StubURLProtocol.script(.http(status: 200, body: body))

        _ = try await client(url).fetch(validators: .empty)

        let request = StubURLProtocol.request(for: url)
        #expect(request != nil)
        #expect(request?.value(forHTTPHeaderField: "If-None-Match") == nil)
        #expect(request?.value(forHTTPHeaderField: "If-Modified-Since") == nil)
    }

    @Test func notModifiedAfterAConditionalRequestIsUnchanged() async throws {
        let url = StubURLProtocol.script(.http(status: 304))

        let response = try await client(url).fetch(validators: validators)

        #expect(response == .unchanged)
    }

    @Test func notModifiedWithoutValidatorsIsAStatusError() async {
        let url = StubURLProtocol.script(.http(status: 304))

        await #expect(throws: NetworkError.httpStatus(304)) {
            try await client(url).fetch(validators: .empty)
        }
    }

    @Test func serverErrorStatusIsReportedAsIs() async {
        let url = StubURLProtocol.script(.http(status: 404, body: Data("not found".utf8)))

        await #expect(throws: NetworkError.httpStatus(404)) {
            try await client(url).fetch(validators: .empty)
        }
    }

    @Test func transportFailureCarriesTheURLError() async {
        let url = StubURLProtocol.script(.failure(URLError(.notConnectedToInternet)))

        let error = await #expect(throws: NetworkError.self) {
            try await client(url).fetch(validators: .empty)
        }

        // The session adds its task to the error's userInfo, so compare the code, which is what callers map on.
        guard case let .network(urlError) = error else {
            Issue.record("Expected a network failure, got \(String(describing: error))")
            return
        }
        #expect(urlError.code == .notConnectedToInternet)
    }

    @Test func nonHTTPResponseIsInvalid() async {
        let url = StubURLProtocol.script(.nonHTTP)

        await #expect(throws: NetworkError.invalidResponse) {
            try await client(url).fetch(validators: .empty)
        }
    }

    // MARK: - Helpers

    private func client(_ url: URL) -> URLSessionFeedClient {
        URLSessionFeedClient(url: url, session: StubURLProtocol.session())
    }
}
