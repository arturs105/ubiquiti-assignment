import Foundation
import OSLog

extension Logger {
    private nonisolated static let subsystem = Bundle.main.bundleIdentifier ?? "Ubiquiti Assignment"

    /// Data problems found while decoding the feed, so dropped products are visible in Console.
    nonisolated static let decoding = Logger(subsystem: subsystem, category: "Decoding")

    /// Feed requests and responses, so conditional requests and 304 answers are visible in Console.
    nonisolated static let networking = Logger(subsystem: subsystem, category: "Networking")
}
