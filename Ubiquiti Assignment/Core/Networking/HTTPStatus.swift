import Foundation

/// HTTP status codes the networking layer compares against. Shared so no client inlines the numbers.
nonisolated enum HTTPStatus {
    static let ok = 200
    static let notModified = 304
    /// What the image CDN answers to an uppercase product id, among other refusals.
    static let forbidden = 403
}
