import SwiftUI

/// Full-screen loading state: a labelled spinner, used when a screen has nothing to show yet.
struct LoadingView: View {
    private let title: LocalizedStringResource

    /// - Parameter title: What is being fetched, read by VoiceOver and shown under the spinner.
    init(title: LocalizedStringResource = "Fetching products") {
        self.title = title
    }

    // MARK: - View

    var body: some View {
        ProgressView {
            Text(title)
                .textStyle(.body)
                .foregroundStyle(.foregroundTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundSecondary)
    }
}

#Preview("Products") {
    LoadingView()
}

#Preview("Custom title") {
    LoadingView(title: "Fetching details")
}
