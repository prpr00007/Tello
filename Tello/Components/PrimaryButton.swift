// Purpose: A reusable primary action button used throughout the app.
// Large tap target, spring animation, consistent branding.

import SwiftUI

// MARK: - Primary Button
struct PrimaryButton: View {

    let label: String
    let icon: String?         // Optional SF Symbol name
    let action: () -> Void

    @State private var isPressed = false

    // MARK: - Init
    init(label: String, icon: String? = nil, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.action = action
    }

    // MARK: - Body
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 64)
            .background(
                LinearGradient(
                    colors: [Color("AppPrimary"), Color("AppPrimary").opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    .blendMode(.overlay)
            )
            .shadow(color: Color("AppPrimary").opacity(0.45), radius: 14, x: 0, y: 6)
            .shadow(color: Color(hex: "#2E3D2F").opacity(0.06), radius: 10)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        PrimaryButton(label: "Let's Go!", icon: "arrow.right") {
            print("Tapped!")
        }
        PrimaryButton(label: "Start Reading") {
            print("Tapped!")
        }
    }
    .padding()
    .background(Color("AppBackground"))
}
