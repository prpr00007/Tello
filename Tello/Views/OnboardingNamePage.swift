// Purpose: Second onboarding page. Asks for the child's name in a warm,
// friendly way. Saves name to AppStorage for use throughout the app.

import SwiftUI

struct OnboardingNamePage: View {

    @Binding var currentPage: Int
    @EnvironmentObject var fontManager: FontManager

    @AppStorage("childName") private var childName = ""
    @State private var nameInput = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var contentOpacity: CGFloat = 0
    @State private var shakeOffset: CGFloat = 0

    var isNameValid: Bool {
        nameInput.trimmingCharacters(in: .whitespaces).count >= 2
    }

    var body: some View {
        VStack(spacing: 0) {

            // Space for accessibility toolbar
            Color.clear.frame(height: 80)

            Spacer()

            VStack(spacing: 36) {

                // MARK: - Emoji + Heading
                VStack(spacing: 16) {
                    Text("👋")
                        .font(.system(size: 64))

                    Text("What's your name?")
                        .font(fontManager.storyFontBold(size: 36))
                        .foregroundColor(Color("AppText"))
                        .multilineTextAlignment(.center)

                    Text("We'll use it in your stories!")
                        .font(fontManager.storyFont(size: 20))
                        .foregroundColor(Color("AppSecondaryText"))
                }

                // MARK: - Name Text Field
                VStack(spacing: 8) {
                    TextField("Type your name here...", text: $nameInput)
                        .font(fontManager.storyFont(size: 28))
                        .foregroundColor(Color("AppText"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .background(Color("AppCardBackground"))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isTextFieldFocused ? Color("AppPrimary") : Color.clear, lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                        .focused($isTextFieldFocused)
                        .offset(x: shakeOffset)
                        .accessibilityLabel("Enter your name")
                        .accessibilityHint("Type at least 2 characters to continue")
                        .onSubmit {
                            handleContinue()
                        }
                }
                .frame(maxWidth: 500)

                // MARK: - Continue Button
                PrimaryButton(label: "That's me! →", icon: nil) {
                    handleContinue()
                }
                .frame(maxWidth: 400)
                .opacity(isNameValid ? 1.0 : 0.5)
            }
            .frame(maxWidth: 700)
            .padding(.horizontal, 40)
            .opacity(contentOpacity)

            Spacer()
            Color.clear.frame(height: 60)
        }
        .onAppear {
            nameInput = childName
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                contentOpacity = 1.0
            }
            // Auto focus the text field after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isTextFieldFocused = true
            }
        }
    }

    // MARK: - Handle Continue
    private func handleContinue() {
        let trimmed = nameInput.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            // Shake animation if name too short
            withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
                shakeOffset = 10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
                    shakeOffset = 0
                }
            }
            return
        }
        childName = trimmed
        isTextFieldFocused = false
        withAnimation {
            currentPage = 2
        }
    }
}

#Preview {
    OnboardingNamePage(currentPage: .constant(1))
        .environmentObject(FontManager())
        .background(Color("AppBackground"))
}
