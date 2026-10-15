import Foundation

/// One Ubiquiti hardware item as the UIDB feed describes it.
///
/// The feed nests display fields under `product`, `images` and `line`; this type flattens the ones a screen renders
/// and ignores the rest. See `docs/DECISIONS.md`, "Model depth".
nonisolated struct Product: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    /// Full display name ("Camera G3 Dome").
    let name: String
    /// Short display name used in compact rows ("G3 Dome").
    let abbreviation: String
    let sku: String
    /// Functional kind as the feed reports it (camera, switch, sensor…). A string until a screen needs it typed.
    let deviceType: String
    let shortnames: [String]
    /// Identifier of the default product image on the Ubiquiti CDN; the URL is built by the image loader.
    let defaultImageID: String
    let line: Line

    // MARK: - Details, nil when the feed has none for this product

    /// Unknown feed values decode to nil rather than failing the product.
    let adoptability: Adoptability?
    /// Camera field of view in degrees.
    let fieldOfView: Double?
    /// Suggested camera mounting distance in metres.
    let suggestedDistance: Double?
    /// Idle power draw in watts; the feed mixes integers and decimals.
    let baseConsumptionWatts: Double?
    /// Minimum controller version that can adopt the product, whichever of the `net` or `protect` keys is present.
    let minimumAdoptVersion: String?
    let complianceModelName: String?
    let isARSupported: Bool?

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id
        case product
        case sku
        case deviceType
        case shortnames
        case images
        case line
        case unifi
        case power
        case minAdoptVersion
        case compliance
        case isARSupported
    }

    private enum ProductKeys: String, CodingKey {
        case name
        case abbrev
    }

    private enum ImagesKeys: String, CodingKey {
        case `default`
    }

    private enum UnifiKeys: String, CodingKey {
        case adoptability
        case protect
    }

    private enum ProtectKeys: String, CodingKey {
        case fov
        case suggestedDistance
    }

    private enum PowerKeys: String, CodingKey {
        case baseConsumption
    }

    private enum MinAdoptVersionKeys: String, CodingKey {
        case net
        case protect
    }

    private enum ComplianceKeys: String, CodingKey {
        case modelName
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let product = try container.nestedContainer(keyedBy: ProductKeys.self, forKey: .product)
        let images = try container.nestedContainer(keyedBy: ImagesKeys.self, forKey: .images)

        id = try container.decode(UUID.self, forKey: .id)
        name = try product.decode(String.self, forKey: .name)
        abbreviation = try product.decode(String.self, forKey: .abbrev)
        sku = try container.decode(String.self, forKey: .sku)
        deviceType = try container.decode(String.self, forKey: .deviceType)
        shortnames = try container.decode([String].self, forKey: .shortnames)
        defaultImageID = try images.decode(String.self, forKey: .default)
        line = try container.decode(Line.self, forKey: .line)

        let unifi = try container.decodeNestedContainerIfPresent(keyedBy: UnifiKeys.self, forKey: .unifi)
        let protect = try unifi?.decodeNestedContainerIfPresent(keyedBy: ProtectKeys.self, forKey: .protect)
        let power = try container.decodeNestedContainerIfPresent(keyedBy: PowerKeys.self, forKey: .power)
        let minAdopt = try container.decodeNestedContainerIfPresent(
            keyedBy: MinAdoptVersionKeys.self,
            forKey: .minAdoptVersion,
        )
        let compliance = try container.decodeNestedContainerIfPresent(
            keyedBy: ComplianceKeys.self,
            forKey: .compliance,
        )

        adoptability = try unifi?.decodeIfPresent(String.self, forKey: .adoptability)
            .flatMap(Adoptability.init(rawValue:))
        fieldOfView = try protect?.decodeIfPresent(Double.self, forKey: .fov)
        suggestedDistance = try protect?.decodeIfPresent(Double.self, forKey: .suggestedDistance)
        baseConsumptionWatts = try power?.decodeIfPresent(Double.self, forKey: .baseConsumption)
        minimumAdoptVersion = try minAdopt?.decodeIfPresent(String.self, forKey: .net)
            ?? minAdopt?.decodeIfPresent(String.self, forKey: .protect)
        complianceModelName = try compliance?.decodeIfPresent(String.self, forKey: .modelName)
        isARSupported = try container.decodeIfPresent(Bool.self, forKey: .isARSupported)
    }

    /// Mirrors the feed's nesting so an encoded product decodes back to itself.
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var product = container.nestedContainer(keyedBy: ProductKeys.self, forKey: .product)
        var images = container.nestedContainer(keyedBy: ImagesKeys.self, forKey: .images)

        try container.encode(id, forKey: .id)
        try product.encode(name, forKey: .name)
        try product.encode(abbreviation, forKey: .abbrev)
        try container.encode(sku, forKey: .sku)
        try container.encode(deviceType, forKey: .deviceType)
        try container.encode(shortnames, forKey: .shortnames)
        try images.encode(defaultImageID, forKey: .default)
        try container.encode(line, forKey: .line)

        if adoptability != nil || fieldOfView != nil || suggestedDistance != nil {
            var unifi = container.nestedContainer(keyedBy: UnifiKeys.self, forKey: .unifi)
            try unifi.encodeIfPresent(adoptability, forKey: .adoptability)
            if fieldOfView != nil || suggestedDistance != nil {
                var protect = unifi.nestedContainer(keyedBy: ProtectKeys.self, forKey: .protect)
                try protect.encodeIfPresent(fieldOfView, forKey: .fov)
                try protect.encodeIfPresent(suggestedDistance, forKey: .suggestedDistance)
            }
        }
        if let baseConsumptionWatts {
            var power = container.nestedContainer(keyedBy: PowerKeys.self, forKey: .power)
            try power.encode(baseConsumptionWatts, forKey: .baseConsumption)
        }
        if let minimumAdoptVersion {
            // The source key (net or protect) is not kept; `net` is the one the decoder reads first.
            var minAdopt = container.nestedContainer(keyedBy: MinAdoptVersionKeys.self, forKey: .minAdoptVersion)
            try minAdopt.encode(minimumAdoptVersion, forKey: .net)
        }
        if let complianceModelName {
            var compliance = container.nestedContainer(keyedBy: ComplianceKeys.self, forKey: .compliance)
            try compliance.encode(complianceModelName, forKey: .modelName)
        }
        try container.encodeIfPresent(isARSupported, forKey: .isARSupported)
    }
}
