import SwiftUI

/// One product image slot: a spinner until the image arrives, the image, or the failure.
///
/// Sized by its parent, which knows whether it is a row thumbnail or the details hero; the image scales to fit. A
/// thumbnail shows a failure as the `photo` symbol and is decorative throughout: the product's name is always beside
/// it, so VoiceOver skips the slot rather than reading "image" or "photo" a few hundred times down the list. The
/// hero (`failureStyle: .detailed`) names the failure and offers Retry, and is then an accessibility element, since a
/// hidden button cannot be pressed. The load is awaited from `.task`, so the slot leaving the screen cancels the
/// download, a slot that comes back loads again, and Retry re-runs the same task (`ProductImageViewModel.load()`).
struct ProductImageView: View {
    /// How a slot shows a failed image.
    enum FailureStyle {
        /// The `photo` symbol alone: a thumbnail, whose row has no room for words.
        case symbol
        /// The failure's symbol and headline with a Retry button: the hero.
        case detailed
    }

    @State private var viewModel: ProductImageViewModel
    @State private var attempt = 0
    private let failureStyle: FailureStyle

    /// - Parameters:
    ///   - viewModel: Built by the parent for one product and size; the view keeps it for its lifetime.
    ///   - failureStyle: What a failed image looks like; `symbol` by default.
    init(viewModel: ProductImageViewModel, failureStyle: FailureStyle = .symbol) {
        _viewModel = State(wrappedValue: viewModel)
        self.failureStyle = failureStyle
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
            case let .failed(error):
                failure(error)
            }
        }
        .accessibilityHidden(isDecorative)
        // Keyed by attempt, so Retry cancels nothing in flight and starts the same structured load again.
        .task(id: attempt) { await viewModel.load() }
    }

    // MARK: - Private helpers

    @ViewBuilder
    private func failure(_ error: DisplayError) -> some View {
        switch failureStyle {
        case .symbol:
            Image(systemName: "photo")
                .foregroundStyle(.foregroundQuaternary)
        case .detailed:
            ProductImageFailureView(error: error) { attempt += 1 }
        }
    }

    /// Hidden from VoiceOver unless the slot is showing a Retry button.
    private var isDecorative: Bool {
        guard case .failed = viewModel.state else { return true }
        return failureStyle == .symbol
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

#Preview("Failed, detailed") {
    ProductImageView(
        viewModel: ProductImageViewModel(
            product: Product.previews[0],
            size: .hero,
            loader: InMemoryImageLoader(error: .network(.network(URLError(.notConnectedToInternet)))),
        ),
        failureStyle: .detailed,
    )
    .frame(height: Metrics.heroHeight)
}
