import Foundation

extension DisplayError {
    /// A failed feed refresh as the user reads it. The decoder's message stays in the log; the screen only learns
    /// that the feed could not be read.
    init(_ error: FeedError) {
        switch error {
        case let .network(networkError):
            self.init(networkError)
        case .decoding:
            self = .unreadableFeed
        }
    }
}
