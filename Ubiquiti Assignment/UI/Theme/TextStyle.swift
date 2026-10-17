import SwiftUI

/// The five Figma text styles mapped onto semantic system text styles, so each scales with Dynamic Type.
///
/// SF Pro Text is the system font, so `body` and `caption` match Figma at the default size. The tab styles are
/// UI Sans in Figma, which is not bundled, and fall back to `subheadline`. See `docs/DECISIONS.md`.
enum TextStyle {
    /// `Mobile/16pt-SF-Pro`: row titles, detail labels, error copy.
    case body

    /// `Mobile/16pt-SF-Pro-Bold`: navigation titles.
    case bodyBold

    /// `Mobile/12pt-SF-Pro`: row subtitles.
    case caption

    /// `Mobile/14pt-Regular`: an unselected tab label.
    case tab

    /// `Mobile/14pt-Bold`: the selected tab label.
    case tabSelected

    var font: Font {
        switch self {
        case .body: .body
        case .bodyBold: .body.bold()
        case .caption: .caption
        case .tab: .subheadline
        case .tabSelected: .subheadline.bold()
        }
    }

    /// Figma sets -0.208 tracking on the 16pt styles only.
    var tracking: CGFloat {
        switch self {
        case .body, .bodyBold: -0.208
        case .caption, .tab, .tabSelected: 0
        }
    }
}
