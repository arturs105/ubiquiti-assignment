import SwiftUI

/// The headline of a full-screen state view: a tinted symbol over a bold title in the primary text colour.
struct StateLabel: View {
    private let title: LocalizedStringResource
    private let systemImage: String
    private let tint: Color

    /// - Parameters:
    ///   - title: Short headline under the symbol.
    ///   - systemImage: SF Symbol shown above the title.
    ///   - tint: Colour of the symbol; the title is always `foregroundPrimary`.
    init(title: LocalizedStringResource, systemImage: String, tint: Color) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
    }

    // MARK: - View

    var body: some View {
        Label {
            Text(title)
                .textStyle(.bodyBold)
                .foregroundStyle(.foregroundPrimary)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
        }
    }
}

#Preview {
    StateLabel(title: "No products", systemImage: "tray", tint: .foregroundTertiary)
}
