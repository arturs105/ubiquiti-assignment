import SwiftUI

/// One attribute row: the label leading, the value trailing, 44pt tall as in Figma.
///
/// The value is tertiary text unless highlighted, when it takes the positive tint Figma gives the line name and
/// id. The row is one accessibility element reading label then value.
struct ProductDetailRow: View {
    private let attribute: ProductAttribute

    init(attribute: ProductAttribute) {
        self.attribute = attribute
    }

    // MARK: - View

    var body: some View {
        LabeledContent {
            Text(attribute.value)
                .textStyle(.body)
                .foregroundStyle(attribute.isHighlighted ? Color.positive : Color.foregroundTertiary)
                .multilineTextAlignment(.trailing)
        } label: {
            Text(attribute.label)
                .textStyle(.body)
                .foregroundStyle(.foregroundPrimary)
        }
        .frame(minHeight: Metrics.detailRowHeight)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        ProductDetailRow(attribute: ProductAttribute("Product line", value: "UniFi Protect", isHighlighted: true))
        ProductDetailRow(attribute: ProductAttribute("Name", value: "Camera G3 Dome"))
    }
}
