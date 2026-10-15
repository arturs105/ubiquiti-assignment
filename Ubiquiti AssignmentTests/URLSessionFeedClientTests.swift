import Foundation
import Testing
@testable import Ubiquiti_Assignment

@Suite(.timeLimit(.minutes(1)))
struct URLSessionFeedClientTests {
    private let body = Data(#"{"version": "v1", "devices": []}"#.utf8)
    private let etag = #""abc""#
    private let lastModified = "Wed, 15 Oct 2026 08:00:00 GMT"
    private var validators: Validators { Validators(etag: etag, lastModified: lastModified) }

    @Test func fullResponseCarriesTheExactBytesAndBothValidators() async {
        let url = StubURLProtocol.script(.http(
            status: 200,
            headers: ["ETag": etag, "Last-Modified": lastModified],
            body: body,
        ))

        let result = await client(url).fetch(validators: .empty).emissions()

        #expect(result == .success([.updated(data: body, validators: validators)]))
    }

    @Test func fullResponseWithoutValidatorHeadersYieldsNilValidators() async {
        let url = StubURLProtocol.script(.http(status: 200, body: body))

        let result = await client(url).fetch(validators: .empty).emissions()

        #expect(result == .success([.updated(data: body, validators: .empty)]))
    }

    @Test func validatorsAreSentVerbatimAsConditionalHeaders() async {
        let url = StubURLProtocol.script(.http(status: 304))

        _ = await client(url).fetch(validators: validators).emissions()

        let request = StubURLProtocol.request(for: url)
        #expect(request?.value(forHTTPHeaderField: "If-None-Match") == etag)
        #expect(request?.value(forHTTPHeaderField: "If-Modified-Since") == lastModified)
    }

    @Test func noValidatorsMeansNoConditionalHeaders() async {
        let url = StubURLProtocol.script(.http(status: 200, body: body))

        _ = await client(url).fetch(validators: .empty).emissions()

        let request = StubURLProtocol.request(for: url)
        #expect(request != nil)
        #expect(request?.value(forHTTPHeaderField: "If-None-Match") == nil)
        #expect(request?.value(forHTTPHeaderField: "If-Modified-Since") == nil)
    }

    @Test func notModifiedAfterAConditionalRequestIsUnchanged() async {
        let url = StubURLProtocol.script(.http(status: 304))

        let result = await client(url).fetch(validators: validators).emissions()

        #expect(result == .success([.unchanged]))
    }

    @Test func notModifiedWithoutValidatorsIsAStatusError() async {
        let url = StubURLProtocol.script(.http(status: 304))

        let result = await client(url).fetch(validators: .empty).emissions()

        #expect(result == .failure(.httpStatus(304)))
    }

    @Test func serverErrorStatusIsReportedAsIs() async {
        let url = StubURLProtocol.script(.http(status: 404, body: Data("not found".utf8)))

        let result = await client(url).fetch(validators: .empty).emissions()

        #expect(result == .failure(.httpStatus(404)))
    }

    @Test func transportFailureCarriesTheURLError() async {
        let url = StubURLProtocol.script(.failure(URLError(.notConnectedToInternet)))

        let result = await client(url).fetch(validators: .empty).emissions()

        // The session adds its task to the error's userInfo, so compare the code, which is what callers map on.
        guard case let .failure(.network(error)) = result else {
            Issue.record("Expected a network failure, got \(result)")
            return
        }
        #expect(error.code == .notConnectedToInternet)
    }

    @Test func nonHTTPResponseIsInvalid() async {
        let url = StubURLProtocol.script(.nonHTTP)

        let result = await client(url).fetch(validators: .empty).emissions()

        #expect(result == .failure(.invalidResponse))
    }

    // MARK: - Helpers

    private func client(_ url: URL) -> URLSessionFeedClient {
        URLSessionFeedClient(url: url, session: StubURLProtocol.session())
    }
}
