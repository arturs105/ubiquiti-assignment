import SwiftUI

/// Inline notice shown above a list that is rendering a cached snapshot because the refresh failed.
///
/// Non-blocking by design: the cached content stays on screen and the banner carries the Retry instead. The banner
/// names the failure (its symbol and headline), so an offline refresh and a server error read differently.
struct StaleDataBanner: View {
    private let error: DisplayError
    private let isRetrying: Bool
    private let retry: () -> Void

    /// - Parameters:
    ///   - error: Why the refresh failed, as the user reads it.
    ///   - isRetrying: Whether a retry is in flight; a spinner then replaces Retry.
    ///   - retry: Runs when the user taps Retry.
    init(error: DisplayError, isRetrying: Bool = false, retry: @escaping () -> Void) {
        self.error = error
        self.isRetrying = isRetrying
        self.retry = retry
    }

    // MARK: - View

    var body: some View {
        HStack(spacing: Spacing.small) {
            label
            accessoryView
        }
        .padding(.horizontal, Spacing.large)
        .frame(minHeight: Metrics.minimumTapTarget)
        .background(.backgroundPrimary, in: .rect(cornerRadius: Metrics.rowCornerRadius))
    }

    var label: some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: error.systemImage)
                .foregroundStyle(.foregroundTertiary)
                .accessibilityHidden(true)
            Text("Showing saved products. \(Text(error.title))")
                .textStyle(.caption)
                .foregroundStyle(.foregroundSecondary)
        }
        // Padding on the message, not the row, so wrapped text clears the edges at large Dynamic Type sizes
        // without growing the default row past the 44pt Retry target.
        .padding(.vertical, Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    var accessoryView: some View {
        if isRetrying {
            ProgressView()
        } else {
            retryButton
        }
    }

    var retryButton: some View {
        Button(action: retry) {
            // The frame sits inside the label because a borderless button only takes taps on its label.
            Text("Retry")
                .frame(minWidth: Metrics.minimumTapTarget, minHeight: Metrics.minimumTapTarget)
                .contentShape(.rect)
        }
        .textStyle(.caption)
        .buttonStyle(.borderless)
    }
}

#Preview("Offline") {
    StaleDataBanner(error: .offline) {}
        .padding(Spacing.large)
        .background(.backgroundSecondary)
}

#Preview("Server") {
    StaleDataBanner(error: .serverUnavailable) {}
        .padding(Spacing.large)
        .background(.backgroundSecondary)
}

#Preview("Refreshing") {
    StaleDataBanner(error: .offline, isRetrying: true) {}
        .padding(Spacing.large)
        .background(.backgroundSecondary)
}
