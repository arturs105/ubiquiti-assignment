import Foundation

extension DisplayError {
    /// A failed image load as the user reads it, or `nil` for a cancelled one: the slot left the screen, so there is
    /// nothing to show and nobody to show it to.
    ///
    /// An error status from the image CDN is this image's problem, not the server's: the list beside it loaded from
    /// the same backend, so "Server unavailable" would contradict the screen. A transport failure still reads like
    /// the feed's, since the user's connection is the same for both.
    init?(_ error: ImageError) {
        switch error {
        case .network(.httpStatus):
            self = .unavailableImage
        case let .network(networkError):
            self.init(networkError)
        case .invalidImage:
            self = .unavailableImage
        case .cancelled:
            return nil
        }
    }
}
