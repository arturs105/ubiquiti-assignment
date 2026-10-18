import SwiftUI

/// The loaded list: product rows in one grouped block, the stale banner pinned above them when a refresh failed.
///
/// Pull to refresh awaits the view model's refresh, so the system indicator ends when the server has answered.
struct ProductListContent: View {
    private let products: [Product]
    private let staleError: FeedError?
    private let isRefreshing: Bool
    private let refresh: @Sendable () async -> Void
    private let retry: () -> Void

    /// - Parameters:
    ///   - products: The rows, in feed order.
    ///   - staleError: Why the rows are stale, or `nil` when they are current.
    ///   - isRefreshing: Whether a refresh is in flight; the banner then shows a spinner in place of Retry.
    ///   - refresh: Runs on pull to refresh and returns when the server has answered.
    ///   - retry: Runs when the banner's Retry is tapped.
    init(
        products: [Product],
        staleError: FeedError?,
        isRefreshing: Bool,
        refresh: @escaping @Sendable () async -> Void,
        retry: @escaping () -> Void,
    ) {
        self.products = products
        self.staleError = staleError
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
            .listRowInsets(EdgeInsets(top: 0, leading: Spacing.large, bottom: 0, trailing: Spacing.large))
            .listRowBackground(Color.backgroundPrimary)
        }
        .listStyle(.insetGrouped)
        .contentMargins(.horizontal, Spacing.large, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .background(.backgroundSecondary)
        .refreshable(action: refresh)
        .safeAreaInset(edge: .top) {
            if staleError != nil {
                StaleDataBanner(isLoading: isRefreshing, retry: isRefreshing ? nil : retry)
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
            staleError: nil,
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
            staleError: .network(.network(URLError(.notConnectedToInternet))),
            isRefreshing: false,
            refresh: {},
            retry: {},
        )
        .navigationTitle("Products")
    }
}
