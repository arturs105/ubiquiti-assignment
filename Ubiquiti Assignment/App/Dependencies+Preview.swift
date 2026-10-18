import Foundation

extension Dependencies {
    /// A graph on the in-memory fakes, for previews of the root view and every screen under it: nothing cached,
    /// every refresh failing offline, and a solid grey square for every image. A placeholder script until a fixture
    /// feed lands in the app target.
    static func preview() -> Dependencies {
        Dependencies(
            feedRepository: InMemoryFeedRepository(error: .network(.network(URLError(.notConnectedToInternet)))),
            imageLoader: InMemoryImageLoader(),
        )
    }
}
