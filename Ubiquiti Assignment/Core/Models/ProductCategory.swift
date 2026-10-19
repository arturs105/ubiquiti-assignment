import Foundation

/// The three filter tabs over the catalogue. Cameras is a rule over the device type, IoT over the line; the mapping
/// is recorded in `docs/DECISIONS.md`, 2026-10-15 and 2026-10-19.
nonisolated enum ProductCategory: CaseIterable, Hashable, Identifiable, Sendable {
    /// Every product in the feed.
    case all
    /// Every product the feed reports as a camera, whatever its line.
    case cameras
    /// The lines whose products are connected devices rather than network or video gear.
    case iot

    var id: Self { self }

    /// Whether `product` belongs under this tab.
    func contains(_ product: Product) -> Bool {
        switch self {
        case .all: true
        case .cameras: product.deviceType == .camera
        case .iot: Constants.iotLines.contains(product.line.id)
        }
    }
}

extension ProductCategory {
    private nonisolated enum Constants {
        /// The lines the IoT tab gathers. A product outside them that is not a camera appears only under All.
        static let iotLines: Set<Line.ID> = [.unifiConnect, .unifiAccess, .unifiLED, .unifiTalk, .mfi]
    }
}
