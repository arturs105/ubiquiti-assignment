import Foundation

extension ProductCategory {
    /// The tab's label, as Figma spells it.
    var title: LocalizedStringResource {
        switch self {
        case .all: "All"
        case .cameras: "Cameras"
        case .iot: "IoT"
        }
    }

    /// Headline of the empty state when the catalogue has products but none under this tab. `all` holds every
    /// product, so its copy is the catalogue's own and is never reached while the catalogue has rows.
    var emptyTitle: LocalizedStringResource {
        switch self {
        case .all: "No products"
        case .cameras: "No cameras"
        case .iot: "No IoT devices"
        }
    }

    /// One line under `emptyTitle`, the same for every tab: the way out is another tab, not a refresh.
    static let emptyMessage: LocalizedStringResource = "Nothing in this category yet. Try another tab."

    /// Symbol above `emptyTitle`: a filter, since the catalogue is not empty, only the tab is.
    static let emptySymbol = "line.3.horizontal.decrease.circle"
}
