import Foundation

extension Product {
    /// A camera, a switch and a Connect display: enough variety for a list preview and a filter test. Ids are
    /// random per process: nothing compares them across launches, and a literal would only invite a typo.
    static let previews: [Product] = [
        Product(
            id: UUID(),
            name: "Camera G3 Dome",
            abbreviation: "G3 Dome",
            sku: "UVC-G3-Dome",
            deviceType: "camera",
            defaultImageID: "d8594ad6c9cf32910b210da58ace5d25",
            line: Line(id: .unifiProtect, name: "UniFi Protect"),
        ),
        Product(
            id: UUID(),
            name: "Switch Flex Mini",
            abbreviation: "USW Flex Mini",
            sku: "USW-Flex-Mini",
            deviceType: "switch",
            defaultImageID: "1f8ff7a7ed9b42a5f4b7a9f2a2c3d4e5",
            line: Line(id: Line.ID(rawValue: "unifi-network"), name: "UniFi"),
        ),
        Product(
            id: UUID(),
            name: "Display Cast",
            abbreviation: "UC-Cast",
            sku: "UC-Cast",
            deviceType: "display",
            defaultImageID: "a1b2c3d4e5f60718293a4b5c6d7e8f90",
            line: Line(id: .unifiConnect, name: "UniFi Connect"),
        ),
    ]

    /// One of the feed's two placeholder entries, which the list hides.
    static let placeholder = Product(
        id: UUID(),
        name: "Unknown Device",
        abbreviation: "Unknown",
        sku: "UNKNOWN",
        deviceType: "unknown",
        defaultImageID: "00000000000000000000000000000000",
        line: Line(id: .unknown, name: "Unknown"),
    )
}
