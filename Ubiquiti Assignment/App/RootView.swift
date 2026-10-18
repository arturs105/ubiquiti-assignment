import SwiftUI

/// The navigation stack every screen sits in, and the one place screens are built from `Dependencies`.
///
/// Owns the path so a push is a value appended to it, and registers the single destination for `Route`. Screens
/// receive their view model by initialiser and know nothing about the stack; see the SwiftUI section of
/// `docs/CODING_STANDARDS.md`.
struct RootView: View {
    /// What `body` builds the list view model from; #11 builds the details view model from it in `destination(for:)`.
    private let dependencies: Dependencies
    @State private var path: [Route] = []

    /// - Parameter dependencies: the Core services the screens' view models are built from.
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    // MARK: - View

    var body: some View {
        NavigationStack(path: $path) {
            ProductListView(viewModel: ProductListViewModel(repository: dependencies.feedRepository))
                .navigationDestination(for: Route.self, destination: destination)
        }
    }

    // MARK: - Private helpers

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case let .product(id):
            ProductDetailView(productID: id)
        }
    }
}

#Preview {
    RootView(dependencies: .preview())
}
