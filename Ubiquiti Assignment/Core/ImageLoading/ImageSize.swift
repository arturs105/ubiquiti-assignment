import Foundation

/// Which rendition of a product image a screen asks for. The raw value is the pixel width the CDN renders.
nonisolated enum ImageSize: Int, CaseIterable, Hashable, Sendable {
    /// The small image in a list row: 28pt in Figma, 84px at 3x. 128 is the nearest width the assignment names,
    /// with headroom for a larger row later.
    case thumbnail = 128
    /// The large image at the top of the details screen. The assignment's suggestion; the Figma frame has not been
    /// measured yet.
    case hero = 640

    /// The width in pixels the CDN is asked for.
    var pixelWidth: Int { rawValue }
}
