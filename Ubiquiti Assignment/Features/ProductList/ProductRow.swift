import SwiftUI

/// One product in the list: a thumbnail slot, the name over its line, 48pt tall as in Figma.
///
/// The slot is a flat square in the screen background colour, unrounded as the Figma image frame is, until #9
/// loads thumbnails into it; it keeps the row's geometry stable so the image lands without a reflow. The whole row is
/// one accessibility element reading name then line.
struct ProductRow: View {
    private let product: Product

    /// - Parameter product: the product to show.
    init(product: Product) {
        self.product = product
    }

    // MARK: - View

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Color.backgroundSecondary
                .frame(width: Metrics.thumbnail, height: Metrics.thumbnail)
                .accessibilityHidden(true)
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

#Preview {
    List(Product.previews) { product in
        ProductRow(product: product)
    }
}
