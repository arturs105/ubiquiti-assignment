import Foundation
import Testing
@testable import Ubiquiti_Assignment

@Suite(.timeLimit(.minutes(1)))
struct InMemoryFeedClientTests {
    @Test func replaysTheScriptedResponse() async throws {
        let response = FeedResponse.updated(data: Data("feed".utf8), validators: Validators(etag: #""v1""#))

        let fetched = try await InMemoryFeedClient(response: response).fetch(validators: .empty)

        #expect(fetched == response)
    }

    @Test func replaysTheScriptedFailure() async {
        await #expect(throws: NetworkError.httpStatus(500)) {
            try await InMemoryFeedClient(error: .httpStatus(500)).fetch(validators: .empty)
        }
    }
}
