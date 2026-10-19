import SwiftUI

/// One product image slot: a spinner until the image arrives, the image, or the failure image.
///
/// Sized by its parent, which knows whether it is a row thumbnail or the details hero; the image scales to fit.
/// Decorative by contract: the product's name is always beside it, so VoiceOver skips the slot rather than reading
/// "image" or "photo" a few hundred times down the list. The load is awaited from `.task`, so the slot leaving the
/// screen cancels the download, and a slot that comes back loads again (`ProductImageViewModel.load()`).
struct ProductImageView: View {
    @State private var viewModel: ProductImageViewModel

    /// - Parameter viewModel: built by the parent for one product and size; the view keeps it for its lifetime.
    init(viewModel: ProductImageViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    // MARK: - View

    var body: some View {
        // A container, so the slot is one view whichever branch shows and the parent's frame centres each.
        ZStack {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case let .loaded(image):
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            case .failed:
                Image(systemName: "photo")
                    .foregroundStyle(.foregroundQuaternary)
            }
        }
        .accessibilityHidden(true)
        .task { await viewModel.load() }
    }
}

#Preview("Loaded") {
    ProductImageView(viewModel: ProductImageViewModel(
        product: Product.previews[0],
        size: .thumbnail,
        loader: InMemoryImageLoader(image: .solid(.systemBlue, size: .thumbnail)),
    ))
    .frame(width: Metrics.thumbnail, height: Metrics.thumbnail)
}

#Preview("Loading") {
    ProductImageView(viewModel: ProductImageViewModel(
        product: Product.previews[0],
        size: .thumbnail,
        loader: InMemoryImageLoader.pending,
    ))
    .frame(width: Metrics.thumbnail, height: Metrics.thumbnail)
}

#Preview("Failed") {
    ProductImageView(viewModel: ProductImageViewModel(
        product: Product.previews[0],
        size: .thumbnail,
        loader: InMemoryImageLoader(error: .network(.httpStatus(HTTPStatus.forbidden))),
    ))
    .frame(width: Metrics.thumbnail, height: Metrics.thumbnail)
}
