import Foundation

extension Dependencies {
    /// A graph on the in-memory fake, for previews of the root view and every screen under it: nothing cached, and
    /// every refresh failing offline. A placeholder script until a fixture feed lands in the app target.
    static func preview() -> Dependencies {
        Dependencies(
            feedRepository: InMemoryFeedRepository(error: .network(.network(URLError(.notConnectedToInternet)))),
        )
    }
}
