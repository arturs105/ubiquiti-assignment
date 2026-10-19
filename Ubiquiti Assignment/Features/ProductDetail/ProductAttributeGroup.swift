import Foundation

/// The groups the details screen splits a product's attributes into, in screen order.
///
/// `general` holds what every product has; the other three mirror the feed's optional `unifi`, `power` and
/// `compliance` objects and only show for products that carry them. See `docs/DECISIONS.md`, 2026-10-18 "Details
/// attributes: the feed's always-present fields, then its optional objects as sections".
enum ProductAttributeGroup: CaseIterable {
    case general
    case unifi
    case power
    case compliance

    /// The section header; the general group has none, as the Figma block has none.
    var title: LocalizedStringResource? {
        switch self {
        case .general: nil
        case .unifi: "UniFi"
        case .power: "Power"
        case .compliance: "Compliance"
        }
    }

    /// The rows this group shows for `product`, numbers formatted for `locale`; empty when the product carries none
    /// of its fields.
    func attributes(of product: Product, locale: Locale) -> [ProductAttribute] {
        switch self {
        case .general: Self.general(of: product, locale: locale)
        case .unifi: Self.unifi(of: product, locale: locale)
        case .power: Self.power(of: product, locale: locale)
        case .compliance: Self.compliance(of: product)
        }
    }

    // MARK: - Private helpers

    private static func general(of product: Product, locale: Locale) -> [ProductAttribute] {
        var attributes = [
            ProductAttribute("Product line", value: product.line.name, isHighlighted: true),
            ProductAttribute("Line ID", value: product.line.id.rawValue, isHighlighted: true),
            ProductAttribute("Name", value: product.name),
            ProductAttribute("Short name", value: product.abbreviation),
            ProductAttribute("SKU", value: product.sku),
            ProductAttribute("Device type", value: product.deviceType.rawValue),
        ]
        if !product.shortnames.isEmpty {
            attributes.append(ProductAttribute(
                "Also known as",
                value: product.shortnames.formatted(.list(type: .and, width: .narrow).locale(locale)),
            ))
        }
        if let isARSupported = product.isARSupported {
            attributes.append(ProductAttribute("AR view", value: Self.yesOrNo(isARSupported)))
        }
        return attributes
    }

    private static func unifi(of product: Product, locale: Locale) -> [ProductAttribute] {
        var attributes: [ProductAttribute] = []
        if let adoptability = product.adoptability {
            attributes.append(ProductAttribute("Adoption", value: Self.describe(adoptability)))
        }
        if let version = product.minimumAdoptVersion {
            attributes.append(ProductAttribute("Minimum version", value: version))
        }
        if let fieldOfView = product.fieldOfView {
            // Narrow, not abbreviated: abbreviated spells degrees "deg" where narrow draws the degree sign.
            let angle = Measurement(value: fieldOfView, unit: UnitAngle.degrees)
            let degrees = angle.formatted(.measurement(width: .narrow, usage: .asProvided).locale(locale))
            attributes.append(ProductAttribute("Field of view", value: degrees))
        }
        if let distance = product.suggestedDistance {
            let length = Measurement(value: distance, unit: UnitLength.meters)
            attributes.append(ProductAttribute("Suggested distance", value: Self.format(length, locale: locale)))
        }
        return attributes
    }

    private static func power(of product: Product, locale: Locale) -> [ProductAttribute] {
        guard let watts = product.baseConsumptionWatts else { return [] }
        let power = Measurement(value: watts, unit: UnitPower.watts)
        return [ProductAttribute("Base consumption", value: Self.format(power, locale: locale))]
    }

    private static func compliance(of product: Product) -> [ProductAttribute] {
        var attributes: [ProductAttribute] = []
        if let modelName = product.complianceModelName {
            attributes.append(ProductAttribute("Model name", value: modelName))
        }
        if let isIndoorOnly = product.isIndoorOnly {
            attributes.append(ProductAttribute("Indoor only", value: Self.yesOrNo(isIndoorOnly)))
        }
        if let generation = product.wifiGeneration {
            attributes.append(ProductAttribute("Wi-Fi generation", value: generation))
        }
        return attributes
    }

    /// The feed's unit, abbreviated, with the locale's digits: "5 m", "4.5 W" in English. `asProvided` keeps metres
    /// as metres in a locale that measures in feet, so the value stays the one Ubiquiti published.
    private static func format(_ measurement: Measurement<some Dimension>, locale: Locale) -> String {
        measurement.formatted(.measurement(width: .abbreviated, usage: .asProvided).locale(locale))
    }

    private static func yesOrNo(_ value: Bool) -> String {
        value ? String(localized: "Yes") : String(localized: "No")
    }

    private static func describe(_ adoptability: Adoptability) -> String {
        switch adoptability {
        case .adoptable: String(localized: "Adoptable")
        case .standalone: String(localized: "Standalone")
        }
    }
}
