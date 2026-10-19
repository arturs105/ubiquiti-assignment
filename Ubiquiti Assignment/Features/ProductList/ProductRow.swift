import SwiftUI

/// One product in the list: the thumbnail, the name over its line, 48pt tall as in Figma.
///
/// The thumbnail slot is a fixed 28pt square, unrounded as the Figma image frame is, so the image lands without a
/// reflow whether it is still loading, arrived or failed. The whole row is one accessibility element reading name
/// then line; the slot is decorative.
struct ProductRow: View {
    private let product: Product
    private let thumbnail: ProductImageViewModel

    /// - Parameter thumbnail: The thumbnail slot, built by the list view model.
    init(product: Product, thumbnail: ProductImageViewModel) {
        self.product = product
        self.thumbnail = thumbnail
    }

    // MARK: - View

    var body: some View {
        HStack(spacing: Spacing.medium) {
            ProductImageView(viewModel: thumbnail)
                .frame(width: Metrics.thumbnail, height: Metrics.thumbnail)
            VStack(alignment: .leading) {
                Text(product.name)
                    .textStyle(.body)
                    .foregroundStyle(.foregroundPrimary)
                Text(product.line.name)
                    .textStyle(.caption)
                    .foregroundStyle(.foregroundTertiary)
            }
        }
        .frame(minHeight: Metrics.rowHeight)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Loaded") {
    List(Product.previews) { product in
        ProductRow(product: product, thumbnail: ProductImageViewModel(
            product: product,
            size: .thumbnail,
            loader: InMemoryImageLoader(image: .solid(.systemBlue, size: .thumbnail)),
        ))
    }
}

#Preview("Loading") {
    List(Product.previews) { product in
        ProductRow(product: product, thumbnail: ProductImageViewModel(
            product: product,
            size: .thumbnail,
            loader: InMemoryImageLoader.pending,
        ))
    }
}

#Preview("Failed") {
    List(Product.previews) { product in
        ProductRow(product: product, thumbnail: ProductImageViewModel(
            product: product,
            size: .thumbnail,
            loader: InMemoryImageLoader(error: .network(.httpStatus(HTTPStatus.forbidden))),
        ))
    }
}
