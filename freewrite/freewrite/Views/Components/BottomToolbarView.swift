import SwiftUI

#if os(iOS)
struct BottomToolbarView: View {
    // Access ViewModel via EnvironmentObject
    @EnvironmentObject var viewModel: ContentViewModel
    
    // Bindings to state owned by ContentView
    @Binding var activeSheet: ActiveSheet?
    @Binding var initiateAICall: Bool
    
    // Actions owned by ContentView (passed as closures)
    let saveCurrentEntryAction: () -> Void
    
    var body: some View {
        HStack {
             // --- REMOVED Timer Button ---
             /*
             Button { activeSheet = .timer } label: {
                 VStack(spacing: 2) {
                     Image("crumplednote")
                         .resizable().scaledToFit()
                         .frame(width: 30, height: 30)
                     Text("Timer") // Static text
                         .font(.caption2)
                 }
             }
             Spacer()
             */

             // New Entry Button (Action Changed)
             Button { 
                 // Action: Show mood selection sheet
                 print("DEBUG: New Entry button tapped, showing mood selection.")
                 activeSheet = .moodSelection 
             } label: {
                 VStack(spacing: 2) {
                    Image("banana") 
                        .resizable().scaledToFit()
                        .frame(width: 30, height: 30) // Match Raccoon size
                    Text("New") // Shortened Text
                         .font(.caption2)
                 }
             }
             
             Spacer()
             
             // Font/Display Settings Button
             Button {
                 activeSheet = .font
             } label: {
                 VStack(spacing: 2) {
                    Image(systemName: "textformat.size") // Icon for font/display
                        .resizable().scaledToFit()
                        .frame(width: 30, height: 30) 
                    Text("Display") // Shortened Text
                         .font(.caption2)
                 }
             }
             
             Spacer()

             // History Button (Keep as is)
             Button {
                 saveCurrentEntryAction() // Save before showing history
                 activeSheet = .history
             } label: { 
                 VStack(spacing: 2) {
                    Image("cutedumpster") 
                        .resizable().scaledToFit()
                        .frame(width: 30, height: 30) // Match Raccoon size
                     Text("History") // Shortened Text
                         .font(.caption2)
                 }
             }

             Spacer()

             // View Insights Button (NEW)
             Button {
                 print("DEBUG: View Insights button tapped")
                 activeSheet = .aiResponse
             } label: {
                 VStack(spacing: 2) {
                    Image(systemName: "sparkles.rectangle.stack") // New icon
                        .resizable().scaledToFit()
                        .frame(width: 30, height: 30)
                    Text("Insights") // New label
                         .font(.caption2)
                 }
             }
             .disabled(viewModel.aiResponseSections.isEmpty) // Disable if no insights loaded

             Spacer()

             // "Done Dumping?" / Generate AI Button
             Button {
                 print("DEBUG: Done Dumping button tapped")
                 saveCurrentEntryAction() // Save the current entry text
                 // Automatically trigger AI analysis
                 initiateAICall = true
                 // Optionally hide keyboard?
                 #if os(iOS)
                 UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                 #endif
             } label: {
                 VStack(spacing: 2) {
                    Image("IconChatRaccoonActive") // Keep icon? Or new one?
                        .resizable().scaledToFit()
                        .frame(width: 32, height: 32) // Keep larger size
                    Text("Insights") // Shortened label
                         .font(.caption2)
                 }
             }
             // Disable while AI is fetching OR if text is empty/too short?
             // For now, just disable during fetch.
             .disabled(viewModel.isFetchingAIResponse || viewModel.currentText.trimmingCharacters(in: .whitespacesAndNewlines).count < 25)

        }
        .padding(.horizontal, 10) // Add some padding
        .padding(.vertical, 5) // Reduce vertical padding slightly
        .accentColor(.primary) // Use primary accent color
    }
}
#endif