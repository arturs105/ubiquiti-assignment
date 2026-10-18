import Foundation

extension Dependencies {
    /// A graph on the in-memory fakes, for previews of the root view and every screen under it: the preview feed
    /// cached, every refresh confirming it, and a solid grey square for every image.
    static func preview() -> Dependencies {
        Dependencies(
            feedRepository: InMemoryFeedRepository(cached: .preview, refresh: .unchanged),
            imageLoader: InMemoryImageLoader(),
        )
    }
}
