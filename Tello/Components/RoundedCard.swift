// Purpose: A reusable card style modifier applied to any view to give it
// a consistent rounded white card appearance with a soft shadow.

import SwiftUI

// MARK: - RoundedCard Modifier
struct RoundedCardModifier: ViewModifier {

    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color("AppCardBackground"))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
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
