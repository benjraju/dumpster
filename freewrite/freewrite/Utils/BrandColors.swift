import SwiftUI

// Central definition for app branding colors
struct BrandColors {
    static let mintGreen = Color(red: 0.85, green: 0.95, blue: 0.9) // Approx from icon
    static let cream = Color(red: 0.98, green: 0.97, blue: 0.94) // Approx from icon
    static let lightBrown = Color(red: 0.85, green: 0.78, blue: 0.65) // Approx from icon
    static let darkBrown = Color(red: 0.4, green: 0.3, blue: 0.25) // Approx from icon
    static let accentPink = Color(red: 1.0, green: 0.8, blue: 0.8) // Approx from icon
    
    // Convenience for primary text based on scheme
    static func primaryText(for scheme: ColorScheme) -> Color {
        return scheme == .light ? darkBrown : cream
    }
    
    // Convenience for secondary text based on scheme
    static func secondaryText(for scheme: ColorScheme) -> Color {
         return scheme == .light ? darkBrown.opacity(0.7) : cream.opacity(0.7)
    }
    
    // Convenience for backgrounds
    static func background(for scheme: ColorScheme) -> Color {
        return scheme == .light ? cream : Color(red: 0.1, green: 0.1, blue: 0.1) // Darker background for dark mode
    }
    
    static func secondaryBackground(for scheme: ColorScheme) -> Color {
        return scheme == .light ? Color(.secondarySystemGroupedBackground) : Color(red: 0.15, green: 0.15, blue: 0.15)
    }
    
    // MARK: - REMOVED Colors for Custom Prompts
    /*
    static func buttonBackground(for scheme: ColorScheme) -> Color { ... }
    static func buttonText(for scheme: ColorScheme) -> Color { ... }
    static func sheetBackground(for scheme: ColorScheme) -> Color { ... }
    */
} 