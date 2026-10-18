import Foundation

/// One row of the details screen: a label and the product's value for it, already formatted for display.
struct ProductAttribute: Identifiable, Equatable {
    /// What the row names ("Product line", "SKU").
    let label: LocalizedStringResource
    /// The value as shown, verbatim: a feed string or a number formatted with its unit.
    let value: String
    /// Drawn in the positive tint, as Figma draws the line name and id, rather than the tertiary text colour.
    let isHighlighted: Bool

    /// One row per label within a section.
    var id: String { label.key }

    init(_ label: LocalizedStringResource, value: String, isHighlighted: Bool = false) {
        self.label = label
        self.value = value
        self.isHighlighted = isHighlighted
    }
}
