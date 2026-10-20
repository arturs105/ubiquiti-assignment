import Foundation

extension DisplayError {
    /// A failed image load as the user reads it, or `nil` for a cancelled one: the slot left the screen, so there is
    /// nothing to show and nobody to show it to.
    init?(_ error: ImageError) {
        switch error {
        case let .network(networkError):
            self.init(networkError)
        case .invalidImage:
            self = .unavailableImage
        case .cancelled:
            return nil
        }
    }
}
