import SwiftUI

/// The loaded list: product rows in one grouped block.
///
/// Pull to refresh awaits the view model's refresh, so the system indicator ends when the server has answered. The
/// stale banner is not here but in the screen's top bar, so an empty tab shows it too.
///
/// A tab or line change replaces `products`; the rows are keyed by product id, so the list animates the rows that
/// leave and arrive while the rest slide into place, or cuts straight when Reduce Motion is on.
struct ProductListContent: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let products: [Product]
    private let thumbnail: (Product) -> ProductImageViewModel
    private let refresh: @Sendable () async -> Void

    /// - Parameters:
    ///   - products: The rows, in feed order.
    ///   - thumbnail: Builds the thumbnail slot of one row; the list view model provides it.
    ///   - refresh: Runs on pull to refresh and returns when the server has answered.
    init(
        products: [Product],
        thumbnail: @escaping (Product) -> ProductImageViewModel,
        refresh: @escaping @Sendable () async -> Void,
    ) {
        self.products = products
        self.thumbnail = thumbnail
        self.refresh = refresh
    }

    // MARK: - View

    var body: some View {
        List(products) { product in
            NavigationLink(value: Route.product(product)) {
                ProductRow(product: product, thumbnail: thumbnail(product))
            }
            .insetGroupedRow()
        }
        .insetGroupedScreen()
        .animation(reduceMotion ? nil : .default, value: products)
        // The inset-grouped default leaves a section's worth of air under the tab bar; the gap is the bar's padding.
        .contentMargins(.top, 0, for: .scrollContent)
        .refreshable(action: refresh)
    }
}

#Preview {
    NavigationStack {
        ProductListContent(
            products: Product.previews,
            thumbnail: { ProductImageViewModel(product: $0, size: .thumbnail, loader: InMemoryImageLoader()) },
            refresh: {},
        )
        .navigationTitle("Products")
    }
}
