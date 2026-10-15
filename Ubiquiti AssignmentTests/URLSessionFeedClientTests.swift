import Foundation
import Testing
@testable import Ubiquiti_Assignment

struct URLSessionFeedClientTests {
    private let body = Data(#"{"version": "v1", "devices": []}"#.utf8)
    private let validators = Validators(etag: #""abc""#, lastModified: "Wed, 15 Oct 2026 08:00:00 GMT")

    @Test func fullResponseCarriesTheExactBytesAndBothValidators() async {
        let url = StubURLProtocol.script(.http(
            status: 200,
            headers: ["ETag": #""abc""#, "Last-Modified": "Wed, 15 Oct 2026 08:00:00 GMT"],
            body: body,
        ))

        let result = await client(url).fetch(validators: .none).emissions()

        #expect(result == .success([.updated(data: body, validators: validators)]))
    }

    @Test func fullResponseWithoutValidatorHeadersYieldsNilValidators() async {
        let url = StubURLProtocol.script(.http(status: 200, body: body))

        let result = await client(url).fetch(validators: .none).emissions()

        #expect(result == .success([.updated(data: body, validators: .none)]))
    }

    @Test func validatorsAreSentVerbatimAsConditionalHeaders() async {
        let url = StubURLProtocol.script(.http(status: 304))

        _ = await client(url).fetch(validators: validators).emissions()

        let request = StubURLProtocol.request(for: url)
        #expect(request?.value(forHTTPHeaderField: "If-None-Match") == #""abc""#)
        #expect(request?.value(forHTTPHeaderField: "If-Modified-Since") == "Wed, 15 Oct 2026 08:00:00 GMT")
    }

    @Test func noValidatorsMeansNoConditionalHeaders() async {
        let url = StubURLProtocol.script(.http(status: 200, body: body))

        _ = await client(url).fetch(validators: .none).emissions()

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

        let result = await client(url).fetch(validators: .none).emissions()

        #expect(result == .failure(.httpStatus(304)))
    }

    @Test func serverErrorStatusIsReportedAsIs() async {
        let url = StubURLProtocol.script(.http(status: 404, body: Data("not found".utf8)))

        let result = await client(url).fetch(validators: .none).emissions()

        #expect(result == .failure(.httpStatus(404)))
    }

    @Test func transportFailureCarriesTheURLError() async {
        let url = StubURLProtocol.script(.failure(URLError(.notConnectedToInternet)))

        let result = await client(url).fetch(validators: .none).emissions()

        // The session adds its task to the error's userInfo, so compare the code, which is what callers map on.
        guard case let .failure(.network(error)) = result else {
            Issue.record("Expected a network failure, got \(result)")
            return
        }
        #expect(error.code == .notConnectedToInternet)
    }

    @Test func nonHTTPResponseIsInvalid() async {
        let url = StubURLProtocol.script(.nonHTTP)

        let result = await client(url).fetch(validators: .none).emissions()

        #expect(result == .failure(.invalidResponse))
    }

    // MARK: - Helpers

    private func client(_ url: URL) -> URLSessionFeedClient {
        URLSessionFeedClient(url: url, session: StubURLProtocol.session())
    }
}
