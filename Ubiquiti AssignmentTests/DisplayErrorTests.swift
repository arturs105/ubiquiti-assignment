import Foundation
import Testing
@testable import Ubiquiti_Assignment

struct DisplayErrorTests {
    @Test(arguments: [
        URLError.Code.notConnectedToInternet,
        .dataNotAllowed,
        .internationalRoamingOff,
    ])
    func aMissingConnectionReadsAsOffline(code: URLError.Code) {
        #expect(DisplayError(NetworkError.network(URLError(code))) == .offline)
    }

    @Test(arguments: [
        URLError.Code.timedOut,
        .networkConnectionLost,
        .cannotFindHost,
        .secureConnectionFailed,
        .unknown
    ])
    func anyOtherTransportFailureReadsAsUnreachable(code: URLError.Code) {
        #expect(DisplayError(NetworkError.network(URLError(code))) == .unreachable)
    }

    @Test(arguments: [HTTPStatus.notModified, HTTPStatus.forbidden, 500, 503])
    func anErrorStatusReadsAsServerUnavailable(status: Int) {
        #expect(DisplayError(NetworkError.httpStatus(status)) == .serverUnavailable)
    }

    @Test func aNonHTTPResponseReadsAsServerUnavailable() {
        #expect(DisplayError(NetworkError.invalidResponse) == .serverUnavailable)
    }

    @Test func aFeedThatDoesNotDecodeReadsAsUnreadableWithoutTheDecoderMessage() {
        let error = DisplayError(FeedError.decoding("keyNotFound(version)"))

        #expect(error == .unreadableFeed)
        #expect(String(localized: error.message).contains("keyNotFound") == false)
    }

    @Test func aFeedNetworkFailureReadsLikeTheNetworkError() {
        let offline = NetworkError.network(URLError(.notConnectedToInternet))

        #expect(DisplayError(FeedError.network(offline)) == DisplayError(offline))
    }

    @Test func anImageTransportFailureReadsLikeTheNetworkError() {
        let offline = NetworkError.network(URLError(.notConnectedToInternet))

        #expect(DisplayError(ImageError.network(offline)) == DisplayError(offline))
    }

    @Test(arguments: [HTTPStatus.forbidden, 404, 503])
    func anImageErrorStatusReadsAsTheImageUnavailable(status: Int) {
        #expect(DisplayError(ImageError.network(.httpStatus(status))) == .unavailableImage)
    }

    @Test func aNonHTTPImageResponseReadsAsServerUnavailable() {
        #expect(DisplayError(ImageError.network(.invalidResponse)) == .serverUnavailable)
    }

    @Test func undecodableImageBytesReadAsUnavailable() {
        #expect(DisplayError(ImageError.invalidImage("not a png")) == .unavailableImage)
    }

    @Test func aCancelledImageLoadIsNothingToShow() {
        #expect(DisplayError(ImageError.cancelled) == nil)
    }
}
