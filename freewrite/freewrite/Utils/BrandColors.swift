import SwiftUI

// Helper extension to initialize Color from a hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0) // Default to black if invalid
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Central definition for app branding colors
struct BrandColors {
    // Original Palette (retained for default light/dark)
    static let mintGreen = Color(red: 0.85, green: 0.95, blue: 0.9)
    static let cream = Color(red: 0.98, green: 0.97, blue: 0.94)
    static let lightBrown = Color(red: 0.85, green: 0.78, blue: 0.65)
    static let defaultDarkBrown = Color(red: 0.4, green: 0.3, blue: 0.25) // Renamed to avoid conflict
    static let accentPink = Color(red: 1.0, green: 0.8, blue: 0.8)

    // Sepia Theme
    static let sepiaBackground = Color(hex: "F5EFEB")
    static let sepiaText = Color(hex: "5D4037")
    static let sepiaAccent = Color(hex: "A1887F")

    // Nord Theme
    static let nordBackground = Color(hex: "2E3440")
    static let nordText = Color(hex: "D8DEE9")
    static let nordAccent = Color(hex: "88C0D0")

    // Dracula Lite Theme
    static let draculaLiteBackground = Color(hex: "F8F8F2")
    static let draculaLiteText = Color(hex: "6272A4")
    static let draculaLiteAccent = Color(hex: "FF79C6")
    
    // Default Dark Theme (can be customized further if needed)
    static let defaultDarkBackground = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let defaultDarkText = cream // Using original cream for text

    // Convenience for primary text based on theme string
    static func primaryText(for theme: String) -> Color {
        switch theme {
        case "sepia":
            return sepiaText
        case "nord":
            return nordText
        case "dracula_lite":
            return draculaLiteText
        case "dark":
            return defaultDarkText
        default: // "light" or any other unknown
            return defaultDarkBrown
        }
    }

    // Convenience for secondary text based on theme string
    static func secondaryText(for theme: String) -> Color {
        return primaryText(for: theme).opacity(0.7) // General rule, can be customized
    }

    // Convenience for backgrounds based on theme string
    static func background(for theme: String) -> Color {
        switch theme {
        case "sepia":
            return sepiaBackground
        case "nord":
            return nordBackground
        case "dracula_lite":
            return draculaLiteBackground
        case "dark":
            return defaultDarkBackground
        default: // "light"
            return cream
        }
    }

    static func secondaryBackground(for theme: String) -> Color {
        switch theme {
        case "sepia":
            return sepiaBackground.opacity(0.8) // Example, adjust as needed
        case "nord":
            return Color(hex: "3B4252") // Nord darker background element
        case "dracula_lite":
            return draculaLiteBackground.opacity(0.8) // Example, adjust as needed
        case "dark":
            return Color(red: 0.15, green: 0.15, blue: 0.15)
        default: // "light"
            return Color(.secondarySystemGroupedBackground)
        }
    }
    
    // Accent color based on theme string
    static func accentColor(for theme: String) -> Color {
        switch theme {
        case "sepia":
            return sepiaAccent
        case "nord":
            return nordAccent
        case "dracula_lite":
            return draculaLiteAccent
        // For light and dark, we can use the original accent or define new ones
        case "dark":
            return accentPink // Or a new dark theme accent
        default: // "light"
            return defaultDarkBrown // Using darkBrown as accent for light
        }
    }

    // MARK: - REMOVED Colors for Custom Prompts
    /*
    static func buttonBackground(for scheme: ColorScheme) -> Color { ... }
    static func buttonText(for scheme: ColorScheme) -> Color { ... }
    static func sheetBackground(for scheme: ColorScheme) -> Color { ... }
    */
} 