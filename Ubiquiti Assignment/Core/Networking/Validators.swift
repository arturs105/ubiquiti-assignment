import Foundation

/// The server's `ETag` and `Last-Modified` values for a feed download, kept verbatim.
///
/// They are sent back on the next request so the server can answer 304 instead of resending the feed. They are
/// not the feed's fingerprint; `Feed.version` is. Both are optional because a response may carry either, both or
/// neither header; with neither, the next request is unconditional.
nonisolated struct Validators: Codable, Hashable, Sendable {
    /// The `ETag` response header, unparsed, quotes included.
    let etag: String?
    /// The `Last-Modified` response header, unparsed. No date parsing: RFC 9110 wants it echoed as received.
    let lastModified: String?

    init(etag: String? = nil, lastModified: String? = nil) {
        self.etag = etag
        self.lastModified = lastModified
    }

    /// No validators: the request is unconditional and a 304 would be a server error.
    static let empty = Validators()

    var isConditional: Bool { etag != nil || lastModified != nil }
}
