import Foundation

/// Why the loader could not hand back a product image.
nonisolated enum ImageError: Error, Equatable, Sendable {
    /// The download failed at the transport or HTTP level: offline, timed out, or the CDN answered with a status
    /// such as 403.
    case network(NetworkError)
    /// Bytes arrived, or sat in the cache, but no image could be made of them. The underlying reason is logged.
    case invalidImage
    /// The task awaiting the image was cancelled, typically because its row left the screen. Not a failure to show.
    case cancelled
}
