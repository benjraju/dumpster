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
    @Binding var colorScheme: ColorScheme
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
    
    // Computed properties moved/adapted from ContentView
    var fontSizeButtonTitle: String { "\(Int(fontSize))px" }
    var randomButtonTitle: String { "Random" } // Simplified for now
    var timerButtonTitle: String { /* ... copy logic from ContentView ... */
        if !timerIsRunning && timeRemaining == 900 { return "15:00" }
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    var timerColor: Color { /* ... copy logic from ContentView ... */
         if timerIsRunning {
            return isHoveringTimer ? (colorScheme == .light ? .black : .white) : .gray.opacity(0.8)
        } else {
            return isHoveringTimer ? (colorScheme == .light ? .black : .white) : (colorScheme == .light ? .gray : .gray.opacity(0.8))
        }
    }
    // Use standard adaptive colors
    var textColor: Color { Color.secondary } // Standard secondary color for less emphasis
    var textHoverColor: Color { Color.primary } // Standard primary color for emphasis
    
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
                         Text("Timer")
                             .font(.caption)
                     }
                 }
                .buttonStyle(.plain)
                
                Text("•").foregroundColor(.gray)
                
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
                
                Text("•").foregroundColor(.gray)
                
                // Fullscreen Button
                Button(isFullscreen ? "Minimize" : "Fullscreen") { /* ... */ }
                     .buttonStyle(.plain)
                     .foregroundColor(isHoveringFullscreen ? textHoverColor : textColor)
                
                Text("•").foregroundColor(.gray)
                
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
                
                Text("•").foregroundColor(.gray)
                
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
            }
            .padding(8)
            .cornerRadius(6)
        }
    }
}
#endif 