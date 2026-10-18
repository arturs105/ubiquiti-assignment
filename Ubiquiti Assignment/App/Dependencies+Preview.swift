import Foundation

extension Dependencies {
    /// A graph on the in-memory fake, for previews of the root view and every screen under it: the preview feed
    /// cached, and every refresh confirming it.
    static func preview() -> Dependencies {
        Dependencies(feedRepository: InMemoryFeedRepository(cached: .preview, refresh: .unchanged))
    }
}
