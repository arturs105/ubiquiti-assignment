import SwiftUI

/// Inline notice shown above a list that is rendering a cached snapshot because the refresh failed.
///
/// Non-blocking by design: the cached content stays on screen and the banner carries the Retry instead.
struct StaleDataBanner: View {
    private let retry: (() -> Void)?

    /// - Parameter retry: Runs when the user taps Retry. Pass `nil` while a refresh is already in flight.
    init(retry: (() -> Void)? = nil) {
        self.retry = retry
    }

    // MARK: - View

    var body: some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: "wifi.slash")
                .foregroundStyle(.foregroundTertiary)
                .accessibilityHidden(true)
            Text("Showing saved products. Couldn’t refresh.")
                .textStyle(.caption)
                .foregroundStyle(.foregroundSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let retry {
                Button("Retry", action: retry)
                    .textStyle(.caption)
                    .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, Spacing.large)
        .frame(minHeight: Metrics.minimumTapTarget)
        .background(.backgroundPrimary, in: .rect(cornerRadius: Metrics.rowCornerRadius))
        .accessibilityElement(children: .combine)
    }
}

#Preview("With retry") {
    StaleDataBanner {}
        .padding(Spacing.large)
        .background(.backgroundSecondary)
}

#Preview("Refreshing") {
    StaleDataBanner()
        .padding(Spacing.large)
        .background(.backgroundSecondary)
}
