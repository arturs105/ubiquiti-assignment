import SwiftUI

/// The loaded details: the hero image, then the product's attributes in grouped blocks, the general block first
/// and the feed's optional objects as titled sections after it.
///
/// The same inset-grouped block as the list, so both screens share Figma's white rounded block on grey; the hero
/// is the first block (see `docs/DECISIONS.md`, 2026-10-19 "The details hero").
struct ProductDetailContent: View {
    @Environment(\.locale) private var locale
    private let product: Product
    private let hero: ProductImageViewModel

    /// - Parameters:
    ///   - product: The product whose attributes are shown.
    ///   - hero: The hero slot, built by the details view model.
    init(product: Product, hero: ProductImageViewModel) {
        self.product = product
        self.hero = hero
    }

    // MARK: - View

    var body: some View {
        List {
            Section {
                ProductDetailHero(viewModel: hero)
                    .insetGroupedRow()
            }
            ForEach(ProductAttributeSection.sections(for: product, locale: locale)) { section in
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
        }
        .insetGroupedScreen()
    }
}

#Preview("Every section") {
    NavigationStack {
        ProductDetailContent(product: Product.previews[0], hero: ProductImageViewModel(
            product: Product.previews[0],
            size: .hero,
            loader: InMemoryImageLoader(image: .solid(.systemBlue, size: .hero)),
        ))
        .navigationTitle(Product.previews[0].name)
    }
}

#Preview("General only") {
    NavigationStack {
        ProductDetailContent(product: Product.previews[1], hero: ProductImageViewModel(
            product: Product.previews[1],
            size: .hero,
            loader: InMemoryImageLoader.pending,
        ))
        .navigationTitle(Product.previews[1].name)
    }
}
