import SwiftUI

/// The product details: one product looked up by id in the feed, with loading, empty and error states of its own.
///
/// Switches over the view model's state so each state gets its dedicated view. The product is read from the
/// repository's stream rather than carried from the list, so a refresh while the screen is open updates it; see
/// `docs/DECISIONS.md`, 2026-10-18 "Route by ID". The image lands with #9.
struct ProductDetailView: View {
    @State private var viewModel: ProductDetailViewModel

    /// - Parameter viewModel: built by whoever owns the navigation stack; the view keeps it for its lifetime.
    init(viewModel: ProductDetailViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    // MARK: - View

    var body: some View {
        content
            .navigationTitle(title)
            .toolbarTitleDisplayMode(.inline)
            .task { viewModel.load() }
    }

    // MARK: - Private helpers

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            LoadingView(title: "Fetching details")
        case .empty:
            EmptyStateView(
                title: "Product not found",
                message: "This product is no longer in the catalogue.",
                systemImage: "shippingbox",
            )
        case let .failed(error):
            ErrorView(error: error, retry: viewModel.retry)
        case let .loaded(product):
            ProductDetailContent(product: product)
        }
    }

    /// The product's name once there is one, so the back button on any screen pushed later names it.
    private var title: Text {
        if case let .loaded(product) = viewModel.state {
            Text(product.name)
        } else {
            Text("Details")
        }
    }
}

#Preview("Loaded") {
    NavigationStack {
        ProductDetailView(viewModel: ProductDetailViewModel(
            productID: Product.previews[0].id,
            repository: InMemoryFeedRepository(cached: .preview, refresh: .unchanged),
        ))
    }
}

#Preview("Not found") {
    NavigationStack {
        ProductDetailView(viewModel: ProductDetailViewModel(
            productID: UUID(),
            repository: InMemoryFeedRepository(cached: .preview, refresh: .unchanged),
        ))
    }
}

#Preview("Error") {
    NavigationStack {
        ProductDetailView(viewModel: ProductDetailViewModel(
            productID: UUID(),
            repository: InMemoryFeedRepository(error: .network(.httpStatus(503))),
        ))
    }
}

#Preview("Loading") {
    NavigationStack {
        ProductDetailView(viewModel: ProductDetailViewModel(
            productID: UUID(),
            repository: InMemoryFeedRepository.neverAnswering(),
        ))
    }
}
