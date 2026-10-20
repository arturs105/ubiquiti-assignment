import Foundation

extension DisplayError {
    /// A transport or HTTP failure as the user reads it. Shared by the feed and the images: offline reads as the
    /// user's own connection, any other transport error as the server being out of reach, and a status or a non-HTTP
    /// answer as the server's fault.
    init(_ error: NetworkError) {
        switch error {
        case let .network(urlError) where Constants.offlineCodes.contains(urlError.code):
            self = .offline
        case .network:
            self = .unreachable
        case .httpStatus, .invalidResponse:
            self = .serverUnavailable
        }
    }

    private nonisolated enum Constants {
        /// The `URLError` codes that mean the device itself has no connection, as opposed to a connection that
        /// failed on the way. `networkConnectionLost` is the latter: a request cut mid-flight, often by a Wi-Fi to
        /// cellular handoff, on a device that is usually online again by the time the user reads the message.
        static let offlineCodes: Set<URLError.Code> = [
            .notConnectedToInternet,
            .dataNotAllowed,
            .internationalRoamingOff,
        ]
    }
}
