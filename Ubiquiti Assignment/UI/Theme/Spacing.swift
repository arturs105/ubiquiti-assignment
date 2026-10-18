import Foundation

/// Spacing scale read from the Figma frames. Views pass these to `padding` and stack `spacing`, never a literal.
enum Spacing {
    /// 4pt: tab bar inset, gap between a title and its trailing glyph.
    static let xSmall: CGFloat = 4

    /// 8pt: gap between trailing row accessories and between the two tab bars.
    static let small: CGFloat = 8

    /// 12pt: gap between a row thumbnail and its text.
    static let medium: CGFloat = 12

    /// 16pt: screen edge and row inset.
    static let large: CGFloat = 16
}
