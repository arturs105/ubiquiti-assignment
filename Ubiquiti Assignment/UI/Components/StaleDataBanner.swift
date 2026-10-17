import SwiftUI

/// Inline notice shown above a list that is rendering a cached snapshot because the refresh failed.
///
/// Non-blocking by design: the cached content stays on screen and the banner carries the Retry instead.
struct StaleDataBanner: View {
    private let message: LocalizedStringResource
    private let retry: (() -> Void)?

    /// - Parameters:
    ///   - message: What is stale and why, in one line.
    ///   - retry: Runs when the user taps Retry. Pass `nil` while a refresh is already in flight.
    init(message: LocalizedStringResource = "Showing saved products. Couldn’t refresh.", retry: (() -> Void)? = nil) {
        self.message = message
        self.retry = retry
    }

    // MARK: - View

    var body: some View {
        HStack(spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Image(systemName: "wifi.slash")
                    .foregroundStyle(.foregroundTertiary)
                    .accessibilityHidden(true)
                Text(message)
                    .textStyle(.caption)
                    .foregroundStyle(.foregroundSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            if let retry {
                Button(action: retry) {
                    // The frame sits inside the label because a borderless button only takes taps on its label.
                    Text(ButtonTitle.retry)
                        .frame(minWidth: Metrics.minimumTapTarget, minHeight: Metrics.minimumTapTarget)
                        .contentShape(.rect)
                }
                .textStyle(.caption)
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, Spacing.large)
        .frame(minHeight: Metrics.minimumTapTarget)
        .background(.backgroundPrimary, in: .rect(cornerRadius: Metrics.rowCornerRadius))
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
