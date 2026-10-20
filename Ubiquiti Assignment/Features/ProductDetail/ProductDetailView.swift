import SwiftUI

/// The product details: the product carried on the route, its name as the title and its hero image above the rows.
///
/// The product arrives complete from the list, so the screen has no loading, empty or error state of its own;
/// the hero slot shows a spinner until its image lands, or the failure with a Retry when it does not. See
/// `docs/DECISIONS.md`, 2026-10-20 "Route by value".
struct ProductDetailView: View {
    @State private var viewModel: ProductDetailViewModel

    /// - Parameter viewModel: built by whoever owns the navigation stack; the view keeps it for its lifetime.
    init(viewModel: ProductDetailViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    // MARK: - View

    var body: some View {
        ProductDetailContent(product: viewModel.product, hero: viewModel.hero)
            .navigationTitle(viewModel.product.name)
            .toolbarTitleDisplayMode(.inline)
    }
}

#Preview("Loaded") {
    NavigationStack {
        ProductDetailView(viewModel: ProductDetailViewModel(
            product: Product.previews[0],
            imageLoader: InMemoryImageLoader(image: .solid(.systemBlue, size: .hero)),
        ))
    }
}

#Preview("Image failed") {
    NavigationStack {
        ProductDetailView(viewModel: ProductDetailViewModel(
            product: Product.previews[0],
            imageLoader: InMemoryImageLoader(error: .network(.httpStatus(503))),
        ))
    }
}

#Preview("Image loading") {
    NavigationStack {
        ProductDetailView(viewModel: ProductDetailViewModel(
            product: Product.previews[0],
            imageLoader: InMemoryImageLoader.pending,
        ))
    }
}
