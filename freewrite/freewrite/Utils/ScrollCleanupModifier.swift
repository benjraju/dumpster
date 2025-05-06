import SwiftUI

// --- Custom ViewModifier for iOS 16+ Scroll Modifiers --- 
struct ScrollCleanupModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            // Apply modifiers only on iOS 16+
            content
                .scrollContentBackground(.hidden)
                .scrollIndicators(.never)
        } else {
            // Return content unmodified on older versions
            content
        }
    }
} 