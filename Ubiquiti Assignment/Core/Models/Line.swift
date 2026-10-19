import Foundation

/// The product family a product belongs to, such as UniFi Protect or airMAX. Categories are rules over lines.
nonisolated struct Line: Codable, Hashable, Identifiable, Sendable {
    let id: ID
    /// Display name as the feed spells it ("UniFi Protect", "airMAX").
    let name: String
}

extension Line {
    /// Feed identifier of a line. Open on purpose: the feed can add lines, so an unseen id decodes like any other.
    /// Constants exist for the lines the category rules and the filter menu name.
    nonisolated struct ID: RawRepresentable, Codable, Hashable, Sendable {
        let rawValue: String

        init(rawValue: String) {
            self.rawValue = rawValue
        }

        static let unifiNetwork = ID(rawValue: "unifi-network")
        static let unifiLTE = ID(rawValue: "unifi-lte")
        static let unifiProtect = ID(rawValue: "unifi-protect")
        static let unifiConnect = ID(rawValue: "unifi-connect")
        static let unifiAccess = ID(rawValue: "unifi-access")
        static let unifiLED = ID(rawValue: "unifi-led")
        static let mfi = ID(rawValue: "mfi")
        /// The two placeholder products ("Unknown Device", "Unknown Console") sit under this line.
        static let unknown = ID(rawValue: "unknown")
    }
}
