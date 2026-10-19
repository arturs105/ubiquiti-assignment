import SwiftUI

/// The filter button beside the tab bar: a 44pt glass circle with the slider glyph, as Figma's trailing "Tab Bar"
/// frame, opening a menu of the lines under the selected tab with a check against each line that is on.
///
/// A `Menu` of `Toggle`s, not a custom popover: the menu is the system's and Figma's "Menu" frame is its glass
/// rendering, and a toggle inside a menu draws the leading check the design shows. The menu stays open across
/// taps, since several lines can be checked. The glyph turns accent while any line is checked, so an active filter
/// is visible with the menu closed; VoiceOver reads the count as the button's value.
struct LineFilterMenu: View {
    private let lines: [Line]
    private let selection: Set<Line.ID>
    private let toggle: (Line.ID) -> Void

    /// - Parameters:
    ///   - lines: The lines the menu offers, in the order they are listed.
    ///   - selection: The lines currently checked.
    ///   - toggle: Runs with the tapped line; the owner flips it in the view model.
    init(lines: [Line], selection: Set<Line.ID>, toggle: @escaping (Line.ID) -> Void) {
        self.lines = lines
        self.selection = selection
        self.toggle = toggle
    }

    // MARK: - View

    var body: some View {
        Menu {
            ForEach(lines) { line in
                Toggle(line.name, isOn: binding(for: line.id))
            }
        } label: {
            Image(systemName: Constants.symbol)
                .imageScale(.large)
                .foregroundStyle(selection.isEmpty ? Color.foregroundSecondary : .accentColor)
                .frame(width: Metrics.minimumTapTarget, height: Metrics.minimumTapTarget)
                .contentShape(.circle)
        }
        .menuActionDismissBehavior(.disabled)
        .buttonStyle(.plain)
        .glassEffect(.regular, in: .circle)
        // A tab with no products offers no line to check; the button stays so the bar keeps its shape.
        .disabled(lines.isEmpty)
        .accessibilityLabel("Filter by line")
        .accessibilityValue(accessibilityValue)
    }

    // MARK: - Private helpers

    private var accessibilityValue: Text {
        selection.isEmpty ? Text("No lines checked") : Text("^[\(selection.count) line](inflect: true) checked")
    }

    /// A toggle wants a binding; the view holds no state, so the setter forwards to the owner's intent and the
    /// getter reads the selection the owner passed back. A set to the value already shown is not a toggle.
    private func binding(for id: Line.ID) -> Binding<Bool> {
        Binding(
            get: { selection.contains(id) },
            set: { isOn in
                if isOn != selection.contains(id) {
                    toggle(id)
                }
            },
        )
    }
}

extension LineFilterMenu {
    private nonisolated enum Constants {
        /// Figma's glyph: three bars with a knob each, which is this SF Symbol.
        static let symbol = "slider.horizontal.3"
    }
}

#Preview("Off") {
    @Previewable @State var selection: Set<Line.ID> = []
    LineFilterMenu(lines: Product.previews.map(\.line), selection: selection) { id in
        selection.formSymmetricDifference([id])
    }
    .padding(Spacing.large)
    .background(.backgroundSecondary)
}

#Preview("On") {
    LineFilterMenu(lines: Product.previews.map(\.line), selection: [.unifiProtect]) { _ in }
        .padding(Spacing.large)
        .background(.backgroundSecondary)
}

#Preview("No lines") {
    LineFilterMenu(lines: [], selection: []) { _ in }
        .padding(Spacing.large)
        .background(.backgroundSecondary)
}
