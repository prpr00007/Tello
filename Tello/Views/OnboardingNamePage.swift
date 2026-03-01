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

            Color.clear.frame(height: 88)

            Spacer()

            VStack(spacing: 40) {

                // MARK: - Emoji + Heading
                VStack(spacing: 20) {
                    Text("👋")
                        .font(.system(size: 72))

                    Text("What's your name?")
                        .font(fontManager.storyFontBold(size: 40))
                        .foregroundColor(Color("AppText"))
                        .multilineTextAlignment(.center)

                    Text("We'll use it in your stories!")
                        .font(fontManager.storyFont(size: 22))
                        .foregroundColor(Color("AppSecondaryText"))
                }

                // MARK: - Name Text Field
                VStack(spacing: 12) {
                    TextField("Type your name here...", text: $nameInput)
                        .font(fontManager.storyFont(size: 28))
                        .foregroundColor(Color("AppText"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color("AppCardBackground"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(
                                            isTextFieldFocused ? Color("AppPrimary") : Color("AppSecondaryText").opacity(0.2),
                                            lineWidth: isTextFieldFocused ? 3 : 1.5
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
                        )
                        .focused($isTextFieldFocused)
                        .offset(x: shakeOffset)
                        .accessibilityLabel("Enter your name")
                        .accessibilityHint("Type at least 2 characters to continue")
                        .onSubmit {
                            handleContinue()
                        }
                }
                .frame(maxWidth: 520)

                // MARK: - Continue Button
                PrimaryButton(label: "That's me! →", icon: nil) {
                    handleContinue()
                }
                .frame(maxWidth: 420)
                .opacity(isNameValid ? 1.0 : 0.5)
            }
            .frame(maxWidth: 700)
            .padding(.horizontal, 48)
            .opacity(contentOpacity)

            Spacer()
            Color.clear.frame(height: 72)
        }
        .onAppear {
            nameInput = childName
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                contentOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isTextFieldFocused = true
            }
        }
    }

    // MARK: - Handle Continue
    private func handleContinue() {
        let trimmed = nameInput.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.35)) {
                shakeOffset = 12
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.35)) {
                    shakeOffset = 0
                }
            }
            return
        }
        childName = trimmed
        isTextFieldFocused = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            currentPage = 2
        }
    }
}

#Preview {
    OnboardingNamePage(currentPage: .constant(1))
        .environmentObject(FontManager())
        .background(Color("AppBackground"))
}
