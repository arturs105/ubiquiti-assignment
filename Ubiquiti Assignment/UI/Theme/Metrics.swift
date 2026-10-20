import Foundation

/// Fixed sizes read from the Figma frames.
enum Metrics {
    static let thumbnail: CGFloat = 28

    static let rowHeight: CGFloat = 48

    static let detailRowHeight: CGFloat = 44

    /// Height of the hero image block on the details screen. Not in Figma, whose details frame has no image; see
    /// `docs/DECISIONS.md`, 2026-10-19 "The details hero".
    static let heroHeight: CGFloat = 240

    /// `UI Globals/radius-row`: corner radius of a grouped row block.
    static let rowCornerRadius: CGFloat = 10

    /// Apple's minimum tap target, and the Figma toolbar button size.
    static let minimumTapTarget: CGFloat = 44

    static let tabLabelInset: CGFloat = 18

    /// Height of one tab, and of its selection pill; the bar is this plus the 4pt inset on each side.
    static let tabHeight: CGFloat = 36
}
