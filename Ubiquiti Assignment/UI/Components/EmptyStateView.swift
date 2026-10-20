import SwiftUI

/// Full-screen empty state: a symbol, a title and one line explaining why there is nothing to show.
///
/// Named `EmptyStateView` because SwiftUI already owns `EmptyView`.
struct EmptyStateView: View {
    private let title: LocalizedStringResource
    private let message: LocalizedStringResource
    private let systemImage: String

    /// - Parameters:
    ///   - title: Short headline, such as "No products".
    ///   - message: One sentence on why the screen is empty and what the user can do.
    ///   - systemImage: SF Symbol shown above the title.
    init(title: LocalizedStringResource, message: LocalizedStringResource, systemImage: String = "tray") {
        self.title = title
        self.message = message
        self.systemImage = systemImage
    }

    // MARK: - View

    var body: some View {
        ContentUnavailableView {
            StateLabel(title: title, systemImage: systemImage, tint: .foregroundTertiary)
        } description: {
            Text(message)
                .textStyle(.body)
                .foregroundStyle(.foregroundTertiary)
        }
        .background(.backgroundSecondary)
    }
}

#Preview("No products") {
    EmptyStateView(title: "No products", message: "The product list is empty. Pull down to try again.")
}

#Preview("Nothing in category") {
    EmptyStateView(
        title: "No cameras",
        message: "Nothing in this category yet. Try another tab.",
        systemImage: "line.3.horizontal.decrease.circle",
    )
}
