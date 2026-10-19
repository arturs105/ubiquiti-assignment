import SwiftUI

/// A toggle drawn as Figma's menu row: a square check box leading the label, filled with a check while on.
///
/// The box is the `square` / `checkmark.square` pair, swapped with a symbol replace effect so the check draws in
/// rather than snapping, or cut straight when Reduce Motion is on. The whole row is the tap target, and the toggle
/// keeps its on/off semantics for VoiceOver.
struct CheckboxToggleStyle: ToggleStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: Spacing.medium) {
                Image(systemName: configuration.isOn ? Constants.onSymbol : Constants.offSymbol)
                    .imageScale(.large)
                    .foregroundStyle(configuration.isOn ? Color.accentColor : .foregroundTertiary)
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)
                configuration.label
                    .textStyle(.body)
                    .foregroundStyle(.foregroundPrimary)
                Spacer(minLength: 0)
            }
            .frame(minHeight: Metrics.minimumTapTarget)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .default, value: configuration.isOn)
    }
}

extension CheckboxToggleStyle {
    private nonisolated enum Constants {
        static let onSymbol = "checkmark.square"
        static let offSymbol = "square"
    }
}

extension ToggleStyle where Self == CheckboxToggleStyle {
    /// Figma's menu check box: `square` off, `checkmark.square` on.
    static var checkbox: CheckboxToggleStyle { CheckboxToggleStyle() }
}

#Preview {
    @Previewable @State var isOn = true
    Toggle("UniFi Protect", isOn: $isOn)
        .toggleStyle(.checkbox)
        .padding(Spacing.large)
        .background(.backgroundPrimary)
}
