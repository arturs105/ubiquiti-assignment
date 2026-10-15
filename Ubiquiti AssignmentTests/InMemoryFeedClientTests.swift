import Foundation
import Testing
@testable import Ubiquiti_Assignment

@Suite(.timeLimit(.minutes(1)))
struct InMemoryFeedClientTests {
    @Test func replaysTheScriptedResponse() async {
        let response = FeedResponse.updated(data: Data("feed".utf8), validators: Validators(etag: #""v1""#))

        let result = await InMemoryFeedClient(response: response).fetch(validators: .empty).emissions()

        #expect(result == .success([response]))
    }

    @Test func replaysTheScriptedFailure() async {
        let result = await InMemoryFeedClient(error: .httpStatus(500)).fetch(validators: .empty).emissions()

        #expect(result == .failure(.httpStatus(500)))
    }
}
