import SwiftUI

/// Full-screen error state: a warning symbol, the error's own description and a Retry button.
///
/// The view does not interpret the error; whoever builds the `LocalizedError` owns the wording.
struct ErrorView: View {
    private let error: any LocalizedError
    private let retry: () -> Void

    /// - Parameters:
    ///   - error: Supplies the message through `errorDescription`.
    ///   - retry: Runs when the user taps Retry.
    init(error: any LocalizedError, retry: @escaping () -> Void) {
        self.error = error
        self.retry = retry
    }

    // MARK: - View

    var body: some View {
        ContentUnavailableView {
            Label {
                Text("Something went wrong")
                    .textStyle(.bodyBold)
                    .foregroundStyle(.foregroundPrimary)
            } icon: {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            }
        } description: {
            Text(error.errorDescription ?? error.localizedDescription)
                .textStyle(.body)
                .foregroundStyle(.foregroundPrimary)
        } actions: {
            Button("Retry", systemImage: "arrow.clockwise", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .background(.backgroundSecondary)
    }
}

#Preview("Offline") {
    struct PreviewError: LocalizedError {
        var errorDescription: String? { "You appear to be offline. Check your connection and try again." }
    }
    return ErrorView(error: PreviewError()) {}
}

#Preview("Server") {
    struct PreviewError: LocalizedError {
        var errorDescription: String? { "The server could not be reached (HTTP 503)." }
    }
    return ErrorView(error: PreviewError()) {}
}
