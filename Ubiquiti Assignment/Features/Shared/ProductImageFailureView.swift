import SwiftUI

/// What a large image slot shows when its image could not be loaded: the failure's symbol and headline over a
/// Retry button, where a thumbnail would show only the failure image.
struct ProductImageFailureView: View {
    private let error: DisplayError
    private let retry: () -> Void

    /// - Parameters:
    ///   - error: Why the image failed, as the user reads it.
    ///   - retry: Runs when the user taps Retry.
    init(error: DisplayError, retry: @escaping () -> Void) {
        self.error = error
        self.retry = retry
    }

    // MARK: - View

    var body: some View {
        VStack(spacing: Spacing.small) {
            StateLabel(title: error.title, systemImage: error.systemImage, tint: .foregroundTertiary)
                .labelStyle(.titleAndIcon)
            Button("Retry", systemImage: "arrow.clockwise", action: retry)
                .textStyle(.caption)
                // Bordered, so only the button takes the tap and not the whole list row around it.
                .buttonStyle(.bordered)
        }
    }
}

#Preview("Offline") {
    ProductImageFailureView(error: .offline) {}
}

#Preview("Unavailable") {
    ProductImageFailureView(error: .unavailableImage) {}
}
