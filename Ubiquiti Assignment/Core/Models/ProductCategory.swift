import Foundation

/// The three filter tabs over the catalogue. Cameras is a rule over the device type; IoT is a rule over the line,
/// plus the Protect products whose device type senses or actuates. The mapping is recorded in `docs/DECISIONS.md`,
/// 2026-10-15 and 2026-10-19.
nonisolated enum ProductCategory: CaseIterable, Hashable, Identifiable, Sendable {
    /// Every product in the feed.
    case all
    /// Every product the feed reports as a camera, whatever its line.
    case cameras
    /// Smart-building devices: the Access, Connect, LED and mFi lines in full, and Protect's sensors, lights, locks,
    /// chimes and alarms, which sit beside its cameras in the feed.
    case iot

    var id: Self { self }

    /// Whether `product` belongs under this tab.
    func contains(_ product: Product) -> Bool {
        switch self {
        case .all: true
        case .cameras: product.deviceType == .camera
        case .iot: Self.isIoT(product)
        }
    }

    // MARK: - Private helpers

    private static func isIoT(_ product: Product) -> Bool {
        if Constants.iotLines.contains(product.line.id) {
            return true
        }
        return product.line.id == .unifiProtect && Constants.iotProtectKinds.contains(product.deviceType)
    }
}

extension ProductCategory {
    private nonisolated enum Constants {
        /// The lines the IoT tab gathers in full. Talk is left out: its products are desk phones.
        static let iotLines: Set<Line.ID> = [.unifiConnect, .unifiAccess, .unifiLED, .mfi]
        /// The Protect device types the IoT tab gathers; the line's cameras, consoles, gateways and speakers stay out.
        static let iotProtectKinds: Set<Product.DeviceType> = [.sensor, .light, .doorlock, .chime, .alarm]
    }
}
