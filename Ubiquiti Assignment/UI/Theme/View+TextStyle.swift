import SwiftUI

extension View {
    /// Applies one Figma text style: its font and, where Figma sets it, its tracking.
    func textStyle(_ style: TextStyle) -> some View {
        font(style.font).tracking(style.tracking)
    }
}
