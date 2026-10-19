import SwiftUI

/// The three category tabs in one capsule, as Figma's "Tab Bar" frame: a 4pt inset, equal-width tabs, the selected
/// one on a `tabSelectedFill` pill in bold accent text, the others in secondary text.
///
/// The bar is a row of buttons, not a `Picker`: the segmented style draws the system's own chrome and cannot take
/// the Figma colours or the bold/regular pair. The pill slides between tabs with a matched geometry effect, or
/// jumps when Reduce Motion is on.
struct CategoryTabBar: View {
    private let selection: ProductCategory
    private let select: (ProductCategory) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var pill

    /// - Parameter select: Runs with the tapped tab; the owner feeds it to the view model.
    init(selection: ProductCategory, select: @escaping (ProductCategory) -> Void) {
        self.selection = selection
        self.select = select
    }

    // MARK: - View

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProductCategory.allCases) { category in
                tab(category)
            }
        }
        .padding(Spacing.xSmall)
        .glassEffect(.regular, in: .capsule)
        .animation(reduceMotion ? nil : .default, value: selection)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isTabBar)
        .accessibilityLabel("Category")
    }

    // MARK: - Private helpers

    private func tab(_ category: ProductCategory) -> some View {
        let isSelected = category == selection
        return Button {
            select(category)
        } label: {
            Text(category.title)
                .textStyle(isSelected ? .tabSelected : .tab)
                .foregroundStyle(isSelected ? Color.accentColor : .foregroundSecondary)
                .lineLimit(1)
                .padding(.horizontal, Metrics.tabLabelInset)
                .padding(.vertical, Spacing.small)
                .frame(maxWidth: .infinity, minHeight: Metrics.tabHeight)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .background {
            if isSelected {
                Capsule()
                    .fill(.tabSelectedFill)
                    .matchedGeometryEffect(id: Constants.pillID, in: pill)
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension CategoryTabBar {
    private nonisolated enum Constants {
        /// The one pill the matched geometry effect moves between tabs.
        static let pillID = "pill"
    }
}

#Preview("All") {
    @Previewable @State var selection = ProductCategory.all
    CategoryTabBar(selection: selection) { selection = $0 }
        .padding(Spacing.large)
        .background(.backgroundSecondary)
}

#Preview("IoT") {
    CategoryTabBar(selection: .iot) { _ in }
        .padding(Spacing.large)
        .background(.backgroundSecondary)
}
