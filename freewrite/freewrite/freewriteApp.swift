//
//  freewriteApp.swift
//  freewrite
//
//  Created by thorfinn on 2/14/25.
//

import SwiftUI

@main
struct freewriteApp: App {
    #if os(macOS)
    // macOS specific AppDelegate adaptor
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    @AppStorage("colorScheme") private var colorSchemeString: String = "light"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("hasCompletedGoalSelection") private var hasCompletedGoalSelection: Bool = false
    @AppStorage("justCompletedFullOnboarding") private var justCompletedFullOnboarding: Bool = false
    // State to manage showing the splash screen after onboarding
    @State private var showSplash = true
    
    // Create the single source of truth for the ContentViewModel
    @StateObject private var viewModel = ContentViewModel()
    
    init() {
        // Register Lato font (This might work on iOS too, but review if needed)
        if let fontURL = Bundle.main.url(forResource: "Lato-Regular", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }
     
    var body: some Scene {
        #if os(macOS)
        // macOS specific window setup
        WindowGroup {
            // Use a Group to switch between views
            Group {
                if !hasCompletedOnboarding {
                    OnboardingView(showSplash: $showSplash)
                        .environmentObject(viewModel) // Inject viewModel
                } else if !hasCompletedGoalSelection {
                    GoalSelectionView()
                        .environmentObject(viewModel)
                        .onDisappear {
                            // Check if both onboarding and goal selection are now complete
                            if hasCompletedOnboarding && hasCompletedGoalSelection {
                                justCompletedFullOnboarding = true
                                print("DEBUG: Full onboarding complete, setting justCompletedFullOnboarding to true")
                            }
                        }
                } else {
                    // Onboarding and Goal Selection are complete. Decide whether to show splash or content.
                    if showSplash { // Only show splash if flag is initially true AND not just onboarded
                        WelcomeSplashView()
                            .onAppear {
                                // Set a timer to hide the splash screen after a delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { // 2.5 seconds
                                    withAnimation(.easeInOut) { // Optional smooth fade
                                        showSplash = false
                                    }
                                }
                            }
                    } else { // Splash timer finished or showSplash was set to false by OnboardingView
                         ContentView()
                             .environmentObject(viewModel) // Inject viewModel
                             .accentColor(BrandColors.accentColor(for: colorSchemeString))
                             .preferredColorScheme(determineColorScheme(from: colorSchemeString))
                    }
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1100, height: 600)
        .windowToolbarStyle(.unifiedCompact)
        .windowResizability(.contentSize)
        #elseif os(iOS)
        // Basic iOS scene setup
        WindowGroup {
            // Use a Group to switch between views
            Group {
                 if !hasCompletedOnboarding {
                     OnboardingView(showSplash: $showSplash)
                         .environmentObject(viewModel) // Inject viewModel
                 } else if !hasCompletedGoalSelection {
                     GoalSelectionView()
                         .environmentObject(viewModel)
                 } else {
                    // Onboarding and Goal Selection are complete. Decide whether to show splash or content.
                     if showSplash { // Only show splash if flag is initially true AND not just onboarded
                         WelcomeSplashView()
                             .onAppear {
                                 // Set a timer to hide the splash screen after a delay
                                 DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { // 2.5 seconds
                                     withAnimation(.easeInOut) { // Optional smooth fade
                                         showSplash = false
                                     }
                                 }
                             }
                     } else { // Splash timer finished or showSplash was set to false by OnboardingView
                         ContentView()
                             .environmentObject(viewModel) // Inject viewModel
                             .accentColor(BrandColors.accentColor(for: colorSchemeString))
                             .preferredColorScheme(determineColorScheme(from: colorSchemeString))
                     }
                 }
            }
        }
        #endif
    }
}

// Helper function to determine ColorScheme based on theme string
private func determineColorScheme(from themeString: String) -> ColorScheme? {
    switch themeString {
    case "light", "sepia", "dracula_lite":
        return .light
    case "dark", "nord":
        return .dark
    default:
        return nil // Or .light as a fallback
    }
}

#if os(macOS)
// macOS specific AppDelegate to handle window configuration
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Delay slightly to ensure window is available
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApplication.shared.windows.first {
                // Ensure window starts in windowed mode
                if window.styleMask.contains(.fullScreen) {
                    window.toggleFullScreen(nil)
                }
                
                // Center the window on the screen
                window.center()
            }
        }
    }
} 
#endif 
