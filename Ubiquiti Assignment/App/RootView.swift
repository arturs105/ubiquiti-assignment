import SwiftUI

struct RootView: View {
    private let dependencies: Dependencies
    @State private var path: [Route] = []

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    // MARK: - View

    var body: some View {
        NavigationStack(path: $path) {
            ProductListView(viewModel: ProductListViewModel(
                repository: dependencies.feedRepository,
                imageLoader: dependencies.imageLoader,
            ))
            .navigationDestination(for: Route.self, destination: destination)
        }
    }

    // MARK: - Private helpers

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case let .product(product):
            ProductDetailView(viewModel: ProductDetailViewModel(
                product: product,
                imageLoader: dependencies.imageLoader,
            ))
        }
    }
}

#Preview {
    RootView(dependencies: .preview())
}
