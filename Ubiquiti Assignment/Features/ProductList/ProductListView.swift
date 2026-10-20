import SwiftUI

/// The product list: the feed's products under the selected tab and the checked lines, one row each, pushing the
/// product's details on tap.
///
/// Switches over the view model's state so loading, empty and error each get their dedicated view. The tab bar and
/// the line filter button sit above the list and the empty state, the two states a feed can produce, and not above
/// loading or error, where there is nothing to filter. A feed that is on screen while a refresh fails stays on screen
/// with the stale banner under the tab bar, whether the tab has rows or is empty; the view never decides what is
/// stale, it only renders what the view model derived.
struct ProductListView: View {
    @State private var viewModel: ProductListViewModel

    /// - Parameter viewModel: Built by whoever owns the navigation stack; the view keeps it for its lifetime.
    init(viewModel: ProductListViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    // MARK: - View

    var body: some View {
        content
            .task { viewModel.load() }
    }

    // MARK: - Private helpers

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            LoadingView()
        case .empty:
            // Scrollable so a pull can ask the server again; the state has no rows and no other way out.
            ScrollView {
                emptyState
                    .containerRelativeFrame([.horizontal, .vertical])
            }
            .background(.backgroundSecondary)
            .refreshable(action: viewModel.refresh)
            .safeAreaBar(edge: .top) { topBar }
        case let .failed(error):
            ErrorView(error: error, isRetrying: viewModel.isRefreshing, retry: viewModel.retry)
        case let .loaded(products):
            ProductListContent(products: products, thumbnail: viewModel.thumbnailViewModel, refresh: viewModel.refresh)
                .safeAreaBar(edge: .top) { topBar }
        }
    }

    /// Figma's "Tab Bar Container", the tabs stretching and the filter button fixed beside them 8pt apart, with the
    /// stale banner under it while the refresh behind the feed on screen has failed.
    ///
    /// Pinned with `safeAreaBar`, not `safeAreaInset`, so the system draws its soft scroll-edge blur under the bar
    /// once rows scroll beneath it, the treatment a navigation bar gets; at rest the bar sits on the plain background.
    /// The banner lives here and not in the list so an empty tab reports the failed refresh too.
    private var topBar: some View {
        VStack(spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                CategoryTabBar(selection: viewModel.selectedCategory) { viewModel.select(category: $0) }
                LineFilterMenu(lines: viewModel.availableLines, selection: viewModel.selectedLines) {
                    viewModel.toggle(line: $0)
                }
            }
            if let error = viewModel.staleError {
                // The banner shows its spinner in place of Retry while `isRetrying`, so Retry needs no gating here.
                StaleDataBanner(error: error, isRetrying: viewModel.isRefreshing, retry: viewModel.retry)
            }
        }
        .padding(.horizontal, Spacing.large)
        .padding(.top, Spacing.small)
        // Figma's 8pt gap to the first row is the bar's, not the list's content margin, so the system blur spans it.
        .padding(.bottom, Spacing.small)
    }

    /// Which empty it is: the whole catalogue, or only the selected tab. The view model derives the first; the
    /// second's copy comes from the tab on screen. Checked lines never empty a tab: the menu offers only lines
    /// with a product, and a line an update drops unchecks itself.
    @ViewBuilder
    private var emptyState: some View {
        if viewModel.isCatalogueEmpty {
            EmptyStateView(title: "No products", message: "The product list is empty. Pull down to try again.")
        } else {
            EmptyStateView(
                title: viewModel.selectedCategory.emptyTitle,
                message: ProductCategory.emptyMessage,
                systemImage: ProductCategory.emptySymbol,
            )
        }
    }
}

#Preview("Loaded") {
    NavigationStack {
        ProductListView(viewModel: ProductListViewModel(
            repository: InMemoryFeedRepository(cached: .preview, refresh: .unchanged),
            imageLoader: InMemoryImageLoader(),
        ))
    }
}

#Preview("Stale") {
    NavigationStack {
        ProductListView(viewModel: ProductListViewModel(
            repository: InMemoryFeedRepository(
                cached: .preview,
                error: .network(.network(URLError(.notConnectedToInternet))),
            ),
            imageLoader: InMemoryImageLoader(),
        ))
    }
}

#Preview("Empty") {
    NavigationStack {
        ProductListView(viewModel: ProductListViewModel(
            repository: InMemoryFeedRepository(refresh: .updated(Feed(version: "empty", products: []))),
            imageLoader: InMemoryImageLoader(),
        ))
    }
}

#Preview("Empty tab") {
    NavigationStack {
        let viewModel = ProductListViewModel(
            repository: InMemoryFeedRepository(refresh: .updated(Feed(
                version: "network",
                products: [Product.previews[1]],
            ))),
            imageLoader: InMemoryImageLoader(),
        )
        ProductListView(viewModel: viewModel)
            .task { viewModel.select(category: .cameras) }
    }
}

#Preview("Line filter") {
    NavigationStack {
        let viewModel = ProductListViewModel(
            repository: InMemoryFeedRepository(cached: .preview, refresh: .unchanged),
            imageLoader: InMemoryImageLoader(),
        )
        ProductListView(viewModel: viewModel)
            .task { viewModel.toggle(line: .unifiProtect) }
    }
}

#Preview("Stale, empty tab") {
    NavigationStack {
        let viewModel = ProductListViewModel(
            repository: InMemoryFeedRepository(
                cached: Feed(version: "network", products: [Product.previews[1]]),
                error: .network(.httpStatus(503)),
            ),
            imageLoader: InMemoryImageLoader(),
        )
        ProductListView(viewModel: viewModel)
            .task { viewModel.select(category: .cameras) }
    }
}

#Preview("Error, offline") {
    NavigationStack {
        ProductListView(viewModel: ProductListViewModel(
            repository: InMemoryFeedRepository(error: .network(.network(URLError(.notConnectedToInternet)))),
            imageLoader: InMemoryImageLoader(),
        ))
    }
}

#Preview("Error, server") {
    NavigationStack {
        ProductListView(viewModel: ProductListViewModel(
            repository: InMemoryFeedRepository(error: .network(.httpStatus(503))),
            imageLoader: InMemoryImageLoader(),
        ))
    }
}

#Preview("Error, unreadable feed") {
    NavigationStack {
        ProductListView(viewModel: ProductListViewModel(
            repository: InMemoryFeedRepository(error: .decoding("keyNotFound(version)")),
            imageLoader: InMemoryImageLoader(),
        ))
    }
}

#Preview("Loading") {
    NavigationStack {
        ProductListView(viewModel: ProductListViewModel(
            repository: InMemoryFeedRepository.neverAnswering(),
            imageLoader: InMemoryImageLoader.pending,
        ))
    }
}
