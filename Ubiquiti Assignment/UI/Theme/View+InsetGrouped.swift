import SwiftUI

extension View {
    /// Figma's white rounded block on the grey screen: an inset-grouped list with the system radius and separators,
    /// its horizontal margin at the screen-edge spacing token, over the screen background. Both screens use it so
    /// they read as one design; see `docs/DECISIONS.md`, 2026-10-18 "Row subtitle is the line name".
    func insetGroupedScreen() -> some View {
        listStyle(.insetGrouped)
            .contentMargins(.horizontal, Spacing.large, for: .scrollContent)
            .scrollContentBackground(.hidden)
            .background(.backgroundSecondary)
    }

    /// One row inside `insetGroupedScreen()`: inset to the row spacing token on the block background.
    func insetGroupedRow() -> some View {
        listRowInsets(EdgeInsets(top: 0, leading: Spacing.large, bottom: 0, trailing: Spacing.large))
            .listRowBackground(Color.backgroundPrimary)
    }
}
