import SwiftUI

/// The product list: every product in the feed, one row each, pushing the product's details on tap.
///
/// Switches over the view model's state so loading, empty and error each get their dedicated view. A list that is
/// on screen while a refresh fails stays on screen with the stale banner above it; the view never decides what
/// is stale, it only renders what the view model derived.
struct ProductListView: View {
    @State private var viewModel: ProductListViewModel

    /// - Parameter viewModel: built by whoever owns the navigation stack; the view keeps it for its lifetime.
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
                EmptyStateView(title: "No products", message: "The product list is empty. Pull down to try again.")
                    .containerRelativeFrame([.horizontal, .vertical])
            }
            .background(.backgroundSecondary)
            .refreshable(action: viewModel.refresh)
        case let .failed(error):
            ErrorView(error: error, retry: viewModel.retry)
        case let .loaded(products):
            ProductListContent(
                products: products,
                isStale: viewModel.staleError != nil,
                isRefreshing: viewModel.isRefreshing,
                refresh: viewModel.refresh,
                retry: viewModel.retry,
            )
        }
    }
}

#Preview("Loaded") {
    NavigationStack {
        ProductListView(viewModel: ProductListViewModel(
            repository: InMemoryFeedRepository(cached: .preview, refresh: .unchanged),
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
        ))
    }
}

#Preview("Empty") {
    NavigationStack {
        ProductListView(viewModel: ProductListViewModel(
            repository: InMemoryFeedRepository(refresh: .updated(Feed(version: "empty", products: []))),
        ))
    }
}

#Preview("Error") {
    NavigationStack {
        ProductListView(viewModel: ProductListViewModel(
            repository: InMemoryFeedRepository(error: .network(.httpStatus(503))),
        ))
    }
}

#Preview("Loading") {
    NavigationStack {
        ProductListView(viewModel: ProductListViewModel(repository: InMemoryFeedRepository.neverAnswering()))
    }
}
