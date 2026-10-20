import SwiftUI

/// The product image at the top of the details screen: one block of the inset-grouped list, the image centred in
/// it at a fixed height so the rows below do not move when it arrives.
///
/// Decorative: the navigation title already names the product, and the slot's own spinner and failure image say
/// the rest without words (see `docs/DECISIONS.md`, 2026-10-19 "The details hero").
struct ProductDetailHero: View {
    private let viewModel: ProductImageViewModel

    /// - Parameter viewModel: The hero slot, built by the details view model.
    init(viewModel: ProductImageViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - View

    var body: some View {
        ProductImageView(viewModel: viewModel)
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
