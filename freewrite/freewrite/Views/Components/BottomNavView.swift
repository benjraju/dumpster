import SwiftUI

#if os(macOS)
struct BottomNavView: View {
    // Access ViewModel via EnvironmentObject
    @EnvironmentObject var viewModel: ContentViewModel
    
    // Bindings to state owned by ContentView
    @Binding var fontSize: CGFloat
    @Binding var selectedFont: String
    @Binding var timeRemaining: Int
    @Binding var timerIsRunning: Bool
    @Binding var colorSchemeString: String // MODIFIED from colorScheme
    @Binding var initiateAICall: Bool // Trigger for AI
    @Binding var isFullscreen: Bool // Only if needed directly by this view
    @Binding var activeSheet: ActiveSheet?
    
    // Actions owned by ContentView (passed as closures)
    let createNewEntryAction: () -> Void
    let saveCurrentEntryAction: () -> Void // Needed before showing history
    
    // Internal state for hover effects etc.
    @State private var isHoveringTimer = false
    @State private var isHoveringFullscreen = false
    @State private var hoveredFont: String? = nil
    @State private var isHoveringSize = false
    @State private var isHoveringChat = false
    @State private var isHoveringNewEntry = false
    @State private var isHoveringClock = false
    @State private var isHoveringThemeToggle = false
    @State private var lastClickTime: Date? = nil
    @State private var isHoveringInfo = false

    // Constants / Computed Props (can be moved from ContentView)
    let fontSizes: [CGFloat] = [16, 18, 20, 22, 24, 26] // Example
    let availableFonts = NSFontManager.shared.availableFontFamilies // Example
    
    // Helper to determine if the current theme is light-based for more complex conditional logic if needed
    // For simple text/icon colors, BrandColors should be used directly.
    private var isLightBasedTheme: Bool {
        return colorSchemeString == "light" || colorSchemeString == "sepia" || colorSchemeString == "dracula_lite"
    }

    // Computed properties moved/adapted from ContentView
    var fontSizeButtonTitle: String { "\(Int(fontSize))px" }
    var randomButtonTitle: String { "Random" } // Simplified for now
    var timerButtonTitle: String { /* ... copy logic from ContentView ... */
        if !timerIsRunning && timeRemaining == 900 { return "15:00" }
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    var timerColor: Color {
         if timerIsRunning {
            return isHoveringTimer ? BrandColors.primaryText(for: colorSchemeString) : BrandColors.secondaryText(for: colorSchemeString)
        } else {
            return isHoveringTimer ? BrandColors.primaryText(for: colorSchemeString) : BrandColors.secondaryText(for: colorSchemeString)
        }
    }
    var textColor: Color { BrandColors.secondaryText(for: colorSchemeString) } 
    var textHoverColor: Color { BrandColors.primaryText(for: colorSchemeString) } 
    var dividerColor: Color { BrandColors.secondaryText(for: colorSchemeString).opacity(0.5) }
    
    var body: some View {
        HStack {
            // --- Remove Font Buttons Cluster --- 
            /*
            HStack(spacing: 8) {
                Button(fontSizeButtonTitle) { ... }
                 
                Text("•").foregroundColor(.gray)
                
                Button("Lato") { ... }
                
                // ... other font buttons ...
                Text("•").foregroundColor(.gray)
                Button(randomButtonTitle) { ... }

            }
            .padding(8)
            .cornerRadius(6)
            */
            // --- End Remove --- 
            
            Spacer() // Keep spacer to push utility buttons right
            
            // Utility buttons (moved to right)
            HStack(spacing: 20) { 
                // Timer Button
                Button { /* Timer toggle/reset logic */ } label: { 
                     VStack(spacing: 3) {
                        Image("crumplednote") 
                             .resizable().scaledToFit()
                             .frame(width: 24, height: 24)
                             .foregroundColor(timerColor) // Apply timerColor to image if it's a template
                         Text("Timer")
                             .font(.caption)
                             .foregroundColor(timerColor)
                     }
                 }
                .buttonStyle(.plain)
                .onHover { hovering in isHoveringTimer = hovering }
                
                Text("•").foregroundColor(dividerColor)
                
                // AI Chat Button
                Button { /* ... */ } label: { 
                     VStack(spacing: 3) {
                        Image("IconChatRaccoonActive").resizable().scaledToFit() 
                            .frame(width: 24, height: 24)
                         Text("Ask Scribbles")
                             .font(.caption)
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isFetchingAIResponse) 
                .foregroundColor(isHoveringChat ? textHoverColor : textColor)
                .onHover { hovering in isHoveringChat = hovering }
                
                Text("•").foregroundColor(dividerColor)
                
                // Fullscreen Button
                Button { isFullscreen.toggle() } label: { 
                     VStack(spacing: 3) {
                        Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .resizable().scaledToFit()
                            .frame(width: 18, height: 18) // Adjusted size for SF Symbol
                        Text(isFullscreen ? "Minimize" : "Fullscreen")
                            .font(.caption)
                     }
                }
                .buttonStyle(.plain)
                .foregroundColor(isHoveringFullscreen ? textHoverColor : textColor)
                .onHover { hovering in isHoveringFullscreen = hovering }
                
                Text("•").foregroundColor(dividerColor)
                
                // New Entry Button
                Button { 
                    viewModel.activeSheet = .newEntryPrompt
                } label: { 
                     VStack(spacing: 3) {
                        Image("banana").resizable().scaledToFit()
                            .frame(width: 24, height: 24)
                         Text("New Entry")
                             .font(.caption)
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(isHoveringNewEntry ? textHoverColor : textColor)
                .onHover { hovering in isHoveringNewEntry = hovering }
                
                Text("•").foregroundColor(dividerColor)
                
                // History Button
                Button {
                    saveCurrentEntryAction()
                    activeSheet = .history 
                } label: { 
                    VStack(spacing: 3) {
                        Image("cutedumpster").resizable().scaledToFit()
                            .frame(width: 24, height: 24)
                        Text("Dumps")
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(isHoveringClock ? textHoverColor : textColor) // Assuming isHoveringClock for history
                .onHover { hovering in isHoveringClock = hovering } // Assuming isHoveringClock for history
            }
            .padding(8)
            .cornerRadius(6)
        }
    }
}
#endif 