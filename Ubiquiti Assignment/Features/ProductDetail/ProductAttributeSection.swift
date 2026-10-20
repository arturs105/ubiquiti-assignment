import Foundation

/// One block of rows on the details screen: a group and the attributes the product has in it.
struct ProductAttributeSection: Identifiable, Equatable {
    let group: ProductAttributeGroup
    let attributes: [ProductAttribute]

    var id: ProductAttributeGroup { group }

    /// The sections to show for `product`, in screen order, leaving out groups the product has no values in.
    /// Numbers are formatted for `locale`, which the view reads from its environment.
    static func sections(for product: Product, locale: Locale) -> [ProductAttributeSection] {
        ProductAttributeGroup.allCases.compactMap { group in
            let attributes = group.attributes(of: product, locale: locale)
            guard !attributes.isEmpty else { return nil }
            return ProductAttributeSection(group: group, attributes: attributes)
        }
    }
}
