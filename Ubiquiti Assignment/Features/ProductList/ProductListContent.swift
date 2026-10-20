import SwiftUI

/// The loaded list: product rows in one grouped block, the stale banner pinned above them when a refresh failed.
///
/// Pull to refresh awaits the view model's refresh, so the system indicator ends when the server has answered.
///
/// A tab or line change replaces `products`; the rows are keyed by product id, so the list animates the rows that
/// leave and arrive while the rest slide into place, or cuts straight when Reduce Motion is on.
struct ProductListContent: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let products: [Product]
    private let thumbnail: (Product) -> ProductImageViewModel
    private let isStale: Bool
    private let isRefreshing: Bool
    private let refresh: @Sendable () async -> Void
    private let retry: () -> Void

    /// - Parameters:
    ///   - products: The rows, in feed order.
    ///   - thumbnail: Builds the thumbnail slot of one row; the list view model provides it.
    ///   - isStale: Whether the refresh behind the rows failed; the stale banner then shows above them.
    ///   - isRefreshing: Whether a refresh is in flight; the banner then shows a spinner in place of Retry.
    ///   - refresh: Runs on pull to refresh and returns when the server has answered.
    ///   - retry: Runs when the banner's Retry is tapped.
    init(
        products: [Product],
        thumbnail: @escaping (Product) -> ProductImageViewModel,
        isStale: Bool,
        isRefreshing: Bool,
        refresh: @escaping @Sendable () async -> Void,
        retry: @escaping () -> Void,
    ) {
        self.products = products
        self.thumbnail = thumbnail
        self.isStale = isStale
        self.isRefreshing = isRefreshing
        self.refresh = refresh
        self.retry = retry
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
        .safeAreaInset(edge: .top) {
            if isStale {
                // The banner shows its spinner in place of Retry while `isLoading`, so Retry needs no gating here.
                StaleDataBanner(isLoading: isRefreshing, retry: retry)
                    .padding(.horizontal, Spacing.large)
                    .padding(.top, Spacing.small)
            }
        }
    }
}

#Preview("Current") {
    NavigationStack {
        ProductListContent(
            products: Product.previews,
            thumbnail: { ProductImageViewModel(product: $0, size: .thumbnail, loader: InMemoryImageLoader()) },
            isStale: false,
            isRefreshing: false,
            refresh: {},
            retry: {},
        )
        .navigationTitle("Products")
    }
}

#Preview("Stale") {
    NavigationStack {
        ProductListContent(
            products: Product.previews,
            thumbnail: { ProductImageViewModel(product: $0, size: .thumbnail, loader: InMemoryImageLoader()) },
            isStale: true,
            isRefreshing: false,
            refresh: {},
            retry: {},
        )
        .navigationTitle("Products")
    }
}

#Preview("Stale, refreshing") {
    NavigationStack {
        ProductListContent(
            products: Product.previews,
            thumbnail: { ProductImageViewModel(product: $0, size: .thumbnail, loader: InMemoryImageLoader()) },
            isStale: true,
            isRefreshing: true,
            refresh: {},
            retry: {},
        )
        .navigationTitle("Products")
    }
}
