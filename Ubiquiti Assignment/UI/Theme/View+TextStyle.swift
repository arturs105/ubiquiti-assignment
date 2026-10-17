import SwiftUI

extension View {
    /// Applies one Figma text style. Tracking is left to the system font, which sets it per point size.
    func textStyle(_ style: TextStyle) -> some View {
        font(style.font)
    }
}
