import Foundation

/// What the product list is narrowed by: the selected tab, and within it the lines the user checked in the filter
/// menu. No checked line means every line under the tab, so a fresh tab shows all of its products.
nonisolated struct ProductFilter: Hashable, Sendable {
    let category: ProductCategory
    /// Lines to keep under `category`; empty keeps them all.
    let lines: Set<Line.ID>

    /// - Parameters:
    ///   - category: The tab the list is filtered by.
    ///   - lines: The lines checked in the filter menu; empty by default.
    init(category: ProductCategory, lines: Set<Line.ID> = []) {
        self.category = category
        self.lines = lines
    }

    /// Whether `product` passes the tab and, when any line is checked, the line filter.
    func contains(_ product: Product) -> Bool {
        guard category.contains(product) else { return false }
        return lines.isEmpty || lines.contains(product.line.id)
    }

    /// The same filter with any checked line that is not among `offered` unchecked, so a line an update dropped
    /// from the tab does not keep narrowing the list with no menu entry to uncheck it.
    func keeping(_ offered: some Sequence<Line.ID>) -> ProductFilter {
        ProductFilter(category: category, lines: lines.intersection(offered))
    }

    /// The lines the filter menu can offer, in the order Figma lists them. Every other line in the feed is reached
    /// through All with nothing checked. See `docs/DECISIONS.md`, 2026-10-19.
    static let menuLines: [Line.ID] = [.unifiNetwork, .unifiLTE, .unifiProtect, .unifiAccess]
}
