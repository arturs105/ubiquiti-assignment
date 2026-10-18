import Foundation

/// The three filter tabs over the catalogue. A category is a rule over a product's line, never its device type;
/// the mapping is recorded in `docs/DECISIONS.md`, 2026-10-15.
nonisolated enum ProductCategory: CaseIterable, Hashable, Identifiable, Sendable {
    /// Every product in the feed.
    case all
    /// The UniFi Protect line: cameras, and the NVRs, sensors and accessories sold alongside them.
    case cameras
    /// The lines whose products are connected devices rather than network or video gear.
    case iot

    var id: Self { self }

    /// Whether `product` belongs under this tab.
    func contains(_ product: Product) -> Bool {
        switch self {
        case .all: true
        case .cameras: product.line.id == .unifiProtect
        case .iot: Constants.iotLines.contains(product.line.id)
        }
    }
}

extension ProductCategory {
    private nonisolated enum Constants {
        /// The lines the IoT tab gathers. A line not listed here, and not Protect, appears only under All.
        static let iotLines: Set<Line.ID> = [.unifiConnect, .unifiAccess, .unifiLED, .unifiTalk, .mfi]
    }
}
