import Foundation

extension Product {
    /// A camera, a switch and a Connect display: enough variety for a list preview and a filter test, with two
    /// lines the filter menu offers and one it does not. Ids are
    /// random per process: nothing compares them across launches, and a literal would only invite a typo. Image ids
    /// are the live feed's, as in the test fixture, so a preview that loads thumbnails finds real images. The camera
    /// carries every optional detail, so the details preview shows every section; the other two carry none.
    nonisolated static let previews: [Product] = [
        Product(
            id: UUID(),
            name: "Camera G3 Dome",
            abbreviation: "G3 Dome",
            sku: "UVC-G3-Dome",
            deviceType: .camera,
            shortnames: ["UVC G3 Dome", "UVC-G3-DOME"],
            defaultImageID: "d8594ad6c9cf32910b210da58ace5d25",
            line: Line(id: .unifiProtect, name: "UniFi Protect"),
            adoptability: .adoptable,
            fieldOfView: 81.3,
            suggestedDistance: 5,
            baseConsumptionWatts: 4.5,
            minimumAdoptVersion: "1.20.0",
            complianceModelName: "UVC-G3-DOME",
            isIndoorOnly: true,
            wifiGeneration: "5e",
            isARSupported: false,
        ),
        Product(
            id: UUID(),
            name: "Switch Flex Mini",
            abbreviation: "USW Flex Mini",
            sku: "USW-Flex-Mini",
            deviceType: DeviceType(rawValue: "switch"),
            defaultImageID: "e3fbf220c145f4301929576039d52d19",
            line: Line(id: .unifiNetwork, name: "UniFi"),
        ),
        Product(
            id: UUID(),
            name: "Display Cast",
            abbreviation: "UC-Cast",
            sku: "UC-Cast",
            deviceType: DeviceType(rawValue: "display"),
            defaultImageID: "0412c32876888899dcb52176ec58d5a5",
            line: Line(id: .unifiConnect, name: "UniFi Connect"),
        ),
    ]

    /// One of the feed's two placeholder entries, listed like any other product.
    nonisolated static let placeholder = Product(
        id: UUID(),
        name: "Unknown Device",
        abbreviation: "Unknown",
        sku: "UNKNOWN",
        deviceType: DeviceType(rawValue: "unknown"),
        defaultImageID: "d9ab7814004a6dd9741efba0e9fd0f3d",
        line: Line(id: .unknown, name: "Unknown"),
    )
}
