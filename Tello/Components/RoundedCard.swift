// Purpose: A reusable card style modifier applied to any view to give it
// a consistent rounded card appearance with a soft shadow.

import SwiftUI

// MARK: - RoundedCard Modifier
struct RoundedCardModifier: ViewModifier {

    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color("AppCardBackground"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
            )
            .shadow(color: Color(hex: "#2C1810").opacity(0.08), radius: 12)
    }
}

// MARK: - View Extension
extension View {
    /// Applies the standard rounded card style
    /// - Parameter padding: Inner padding of the card. Defaults to 16.
    func roundedCard(padding: CGFloat = 16) -> some View {
        modifier(RoundedCardModifier(padding: padding))
    }
}
