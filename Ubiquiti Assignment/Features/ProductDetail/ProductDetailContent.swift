import SwiftUI

/// The loaded details: the product's attributes in grouped blocks, the general block first and the feed's optional
/// objects as titled sections after it.
///
/// The same inset-grouped block as the list, so both screens share Figma's white rounded block on grey.
struct ProductDetailContent: View {
    @Environment(\.locale) private var locale
    private let product: Product

    /// - Parameter product: the product whose attributes are shown.
    init(product: Product) {
        self.product = product
    }

    // MARK: - View

    var body: some View {
        List(ProductAttributeSection.sections(for: product, locale: locale)) { section in
            Section {
                ForEach(section.attributes) { attribute in
                    ProductDetailRow(attribute: attribute)
                        .insetGroupedRow()
                }
            } header: {
                if let title = section.group.title {
                    Text(title)
                }
            }
        }
        .insetGroupedScreen()
    }
}

#Preview("Every section") {
    NavigationStack {
        ProductDetailContent(product: Product.previews[0])
            .navigationTitle(Product.previews[0].name)
    }
}

#Preview("General only") {
    NavigationStack {
        ProductDetailContent(product: Product.previews[1])
            .navigationTitle(Product.previews[1].name)
    }
}
