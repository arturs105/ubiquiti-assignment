import SwiftUI

/// The loaded list: product rows in one grouped block, the stale banner pinned above them when a refresh failed.
///
/// Pull to refresh awaits the view model's refresh, so the system indicator ends when the server has answered.
struct ProductListContent: View {
    private let products: [Product]
    private let isStale: Bool
    private let isRefreshing: Bool
    private let refresh: @Sendable () async -> Void
    private let retry: () -> Void

    /// - Parameters:
    ///   - products: The rows, in feed order.
    ///   - isStale: Whether the refresh behind the rows failed; the stale banner then shows above them.
    ///   - isRefreshing: Whether a refresh is in flight; the banner then shows a spinner in place of Retry.
    ///   - refresh: Runs on pull to refresh and returns when the server has answered.
    ///   - retry: Runs when the banner's Retry is tapped.
    init(
        products: [Product],
        isStale: Bool,
        isRefreshing: Bool,
        refresh: @escaping @Sendable () async -> Void,
        retry: @escaping () -> Void,
    ) {
        self.products = products
        self.isStale = isStale
        self.isRefreshing = isRefreshing
        self.refresh = refresh
        self.retry = retry
    }

    // MARK: - View

    var body: some View {
        List(products) { product in
            NavigationLink(value: Route.product(product.id)) {
                ProductRow(product: product)
            }
            .insetGroupedRow()
        }
        .insetGroupedScreen()
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
            isStale: true,
            isRefreshing: true,
            refresh: {},
            retry: {},
        )
        .navigationTitle("Products")
    }
}
