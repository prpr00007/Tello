// Purpose: Manages font styling across the app, supporting standard and dyslexia-friendly modes.
// FontManager provides a centralised way to apply consistent, accessible typography.

import SwiftUI

// MARK: - Font Style Enum
enum AppFontStyle {
    case standard
    case dyslexic
}

// MARK: - Font Manager
class FontManager: ObservableObject {

    // Persists the user's font preference across app launches
    @AppStorage("isDyslexicFont") var isDyslexicFont: Bool = false

    // Persists the user's preferred text size (1 = small, 2 = medium, 3 = large)
    @AppStorage("textSizePreference") var textSizePreference: Int = 2

    // MARK: - Size Multiplier
    /// Returns a multiplier based on the user's text size preference
    var sizeMultiplier: CGFloat {
        switch textSizePreference {
        case 1: return 0.85
        case 3: return 1.2
        default: return 1.0
        }
    }

    // MARK: - Font Provider
    /// Returns the correct font for story/reading content based on current settings
    /// - Parameter baseSize: The base font size before multiplier is applied
    func storyFont(size baseSize: CGFloat) -> Font {
        let size = baseSize * sizeMultiplier
        if isDyslexicFont {
            // OpenDyslexic is not bundled by default — fallback to a rounded system font
            // with increased tracking (letter spacing) to simulate dyslexia-friendly reading
            return .system(size: size, weight: .regular, design: .rounded)
        } else {
            return .system(size: size, weight: .regular, design: .default)
        }
    }

    /// Returns a bold variant of the story font
    func storyFontBold(size baseSize: CGFloat) -> Font {
        let size = baseSize * sizeMultiplier
        if isDyslexicFont {
            return .system(size: size, weight: .bold, design: .rounded)
        } else {
            return .system(size: size, weight: .bold, design: .default)
        }
    }

    /// Returns a font suitable for UI labels (not story content)
    func uiFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .rounded)
    }
}
