import Foundation

/// Fixed sizes read from the Figma frames.
enum Metrics {
    /// Product thumbnail in a list row.
    static let thumbnail: CGFloat = 28

    /// Height of a product row and a detail row.
    static let rowHeight: CGFloat = 48

    /// `UI Globals/radius-row`: corner radius of a grouped row block.
    static let rowCornerRadius: CGFloat = 10

    /// Apple's minimum tap target, and the Figma toolbar button size.
    static let minimumTapTarget: CGFloat = 44

    /// Horizontal inset of a tab label inside the tab bar.
    static let tabLabelInset: CGFloat = 18

    /// Height of one tab, and of its selection pill; the bar is this plus the 4pt inset on each side.
    static let tabHeight: CGFloat = 36
}
