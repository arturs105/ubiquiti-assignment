import UIKit

extension UIImage {
    /// A square of `color` at the pixel width of `size`, for previews and tests that need an image with no network.
    nonisolated static func solid(_ color: UIColor, size: ImageSize) -> UIImage {
        let side = CGFloat(size.pixelWidth)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        }
    }
}
