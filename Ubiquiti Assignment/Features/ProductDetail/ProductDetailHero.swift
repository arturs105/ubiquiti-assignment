import SwiftUI

/// The product image at the top of the details screen: one block of the inset-grouped list, the image centred in
/// it at a fixed height so the rows below do not move when it arrives.
///
/// Decorative while loading or loaded: the navigation title already names the product. A failed image names its
/// failure and offers Retry in the block (see `docs/DECISIONS.md`, 2026-10-19 "The details hero" and 2026-10-20
/// "The hero names its failure and retries in place").
struct ProductDetailHero: View {
    private let viewModel: ProductImageViewModel

    /// - Parameter viewModel: The hero slot, built by the details view model.
    init(viewModel: ProductImageViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - View

    var body: some View {
        ProductImageView(viewModel: viewModel, failureStyle: .detailed)
            .padding(Spacing.large)
            .frame(maxWidth: .infinity)
            .frame(height: Metrics.heroHeight)
    }
}

#Preview("Loaded") {
    List {
        ProductDetailHero(viewModel: ProductImageViewModel(
            product: Product.previews[0],
            size: .hero,
            loader: InMemoryImageLoader(image: .solid(.systemBlue, size: .hero)),
        ))
    }
}

#Preview("Loading") {
    List {
        ProductDetailHero(viewModel: ProductImageViewModel(
            product: Product.previews[0],
            size: .hero,
            loader: InMemoryImageLoader.pending,
        ))
    }
}

#Preview("Failed") {
    List {
        ProductDetailHero(viewModel: ProductImageViewModel(
            product: Product.previews[0],
            size: .hero,
            loader: InMemoryImageLoader(error: .network(.httpStatus(HTTPStatus.forbidden))),
        ))
    }
}

#Preview("Failed, offline") {
    List {
        ProductDetailHero(viewModel: ProductImageViewModel(
            product: Product.previews[0],
            size: .hero,
            loader: InMemoryImageLoader(error: .network(.network(URLError(.notConnectedToInternet)))),
        ))
    }
}
