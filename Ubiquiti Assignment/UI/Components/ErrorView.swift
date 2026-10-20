import SwiftUI

/// Full-screen error state: the error's symbol and headline, its message and a Retry button.
///
/// The view does not interpret the error; the `DisplayError` mapping owns the wording. While a retry runs the state
/// behind the view stays failed, so the button shows a spinner in place of its symbol instead of the screen
/// swapping to the loading view and back.
struct ErrorView: View {
    private let error: DisplayError
    private let isRetrying: Bool
    private let retry: () -> Void

    /// - Parameters:
    ///   - error: The failure as the user reads it: headline, message and symbol.
    ///   - isRetrying: Whether a retry is in flight; the button is then disabled and shows a spinner.
    ///   - retry: Runs when the user taps Retry.
    init(error: DisplayError, isRetrying: Bool = false, retry: @escaping () -> Void) {
        self.error = error
        self.isRetrying = isRetrying
        self.retry = retry
    }

    // MARK: - View

    var body: some View {
        ContentUnavailableView {
            StateLabel(title: error.title, systemImage: error.systemImage, tint: .red)
        } description: {
            Text(error.message)
                .textStyle(.body)
                .foregroundStyle(.foregroundPrimary)
        } actions: {
            retryButton
        }
        .background(.backgroundSecondary)
    }

    // MARK: - Private helpers

    private var retryButton: some View {
        Button(action: retry) {
            Label {
                Text("Retry")
            } icon: {
                if isRetrying {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isRetrying)
    }
}

#Preview("Offline") {
    ErrorView(error: .offline) {}
}

#Preview("Server") {
    ErrorView(error: .serverUnavailable) {}
}

#Preview("Unreadable feed") {
    ErrorView(error: .unreadableFeed) {}
}

#Preview("Retrying") {
    ErrorView(error: .unreachable, isRetrying: true) {}
}
