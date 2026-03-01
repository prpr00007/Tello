// Purpose: Onboarding page 2. Asks for the child's age (4-11) and sets
// difficulty level and optional extra-large text for beginners.

import SwiftUI

struct OnboardingAgePage: View {

    @Binding var currentPage: Int
    @EnvironmentObject var fontManager: FontManager

    @AppStorage("childName") private var childName = ""
    @AppStorage("childAge") private var childAge = 7
    @AppStorage("difficultyLevel") private var difficultyLevel = "explorer"
    @State private var contentOpacity: CGFloat = 0

    private let ages = Array(4...11)

    private var level: DifficultyLevel {
        DifficultyLevel.from(age: childAge)
    }

    var body: some View {
        VStack(spacing: 0) {

            Color.clear.frame(height: 88)

            Spacer()

            VStack(spacing: 36) {

                Text("How old are you, \(childName.isEmpty ? "" : childName)?")
                    .font(fontManager.storyFontBold(size: 34))
                    .foregroundColor(Color("AppText"))
                    .multilineTextAlignment(.center)

                // Age buttons in a horizontal row
                HStack(spacing: 12) {
                    ForEach(ages, id: \.self) { age in
                        ageButton(age: age)
                    }
                }
                .frame(maxWidth: 520)

                // Level card
                VStack(spacing: 8) {
                    Text("You are a \(level.displayName) reader!")
                        .font(fontManager.storyFontBold(size: 22))
                        .foregroundColor(Color("AppText"))
                    Text(level.ageRange)
                        .font(fontManager.storyFont(size: 17))
                        .foregroundColor(Color("AppSecondaryText"))
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Color("AppCardBackground"))
                .cornerRadius(20)
                .shadow(color: Color(hex: "#2E3D2F").opacity(0.06), radius: 10)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: level.rawValue)

                PrimaryButton(label: "That is me!", icon: nil) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        currentPage = 3
                    }
                }
                .frame(maxWidth: 400)
            }
            .frame(maxWidth: 700)
            .padding(.horizontal, 40)
            .opacity(contentOpacity)

            Spacer()
            Color.clear.frame(height: 72)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                contentOpacity = 1.0
            }
        }
    }

    private func ageButton(age: Int) -> some View {
        let isSelected = childAge == age
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                childAge = age
                difficultyLevel = DifficultyLevel.from(age: age).rawValue
                if age <= 6 {
                    fontManager.textSizePreference = 3
                }
            }
        } label: {
            Text("\(age)")
                .font(fontManager.uiFont(size: 22, weight: .bold))
                .foregroundColor(isSelected ? .white : Color("AppText"))
                .frame(minWidth: 60, minHeight: 60)
                .background(Circle().fill(isSelected ? Color("AppPrimary") : Color("AppCardBackground")))
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.clear : Color("AppSecondaryText").opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Age \(age), \(isSelected ? "selected" : "")")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    OnboardingAgePage(currentPage: .constant(2))
        .environmentObject(FontManager())
        .background(Color("AppBackground"))
}
