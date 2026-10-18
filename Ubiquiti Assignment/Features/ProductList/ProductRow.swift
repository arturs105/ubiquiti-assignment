import SwiftUI

/// One product in the list: the thumbnail, the name over its line, 48pt tall as in Figma.
///
/// The thumbnail slot is a fixed 28pt square, unrounded as the Figma image frame is, so the image lands without a
/// reflow whether it is still loading, arrived or failed. The whole row is one accessibility element reading name
/// then line; the slot is decorative.
struct ProductRow: View {
    private let product: Product
    private let imageLoader: any ImageLoader

    /// - Parameters:
    ///   - product: The product to show.
    ///   - imageLoader: The image seam the thumbnail loads through.
    init(product: Product, imageLoader: any ImageLoader) {
        self.product = product
        self.imageLoader = imageLoader
    }

    // MARK: - View

    var body: some View {
        HStack(spacing: Spacing.medium) {
            ProductImageView(viewModel: ProductImageViewModel(product: product, size: .thumbnail, loader: imageLoader))
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
        ProductRow(product: product, imageLoader: InMemoryImageLoader(image: .solid(.systemBlue, size: .thumbnail)))
    }
}

#Preview("Loading") {
    List(Product.previews) { product in
        ProductRow(product: product, imageLoader: InMemoryImageLoader.pending)
    }
}

#Preview("Failed") {
    List(Product.previews) { product in
        ProductRow(product: product, imageLoader: InMemoryImageLoader(error: .network(.httpStatus(403))))
    }
}
