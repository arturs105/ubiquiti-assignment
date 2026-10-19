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
}
