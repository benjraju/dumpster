import SwiftUI

// Removed placeholder BrandColors struct
/*
// Assuming BrandColors are defined elsewhere
struct BrandColors { 
    static let cream = Color.yellow.opacity(0.1) // Placeholder
    static let mintGreen = Color.green.opacity(0.1) // Placeholder
    static let accentPink = Color.pink.opacity(0.8) // Placeholder
    static let darkBrown = Color.brown // Placeholder
    static func primaryText(for scheme: ColorScheme) -> Color { return .primary } // Placeholder
    static func secondaryText(for scheme: ColorScheme) -> Color { return .secondary } // Placeholder
    static func secondaryBackground(for scheme: ColorScheme) -> Color { return Color.gray.opacity(0.2)} // Placeholder
    static func background(for scheme: ColorScheme) -> Color { return Color.white } // Placeholder
}
*/

struct MoodSelectionSheet: View {
    @EnvironmentObject private var viewModel: ContentViewModel
    @Environment(\.dismiss) var dismiss

    // State to track the flow
    @State private var selectedEntryType: Mood? = nil // Initially nil
    @State private var selectedEntryTypeForAnimation: Mood? = nil // For animation feedback

    // Define grid layout for emojis
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 4)

    // Helper to get raccoon image name based on Mood enum
    private func imageName(for mood: Mood) -> String {
        switch mood {
            case .vent: return "Raccoon_Mood_Venting"
            case .explore: return "Raccoon_Mood_Exploring"
            case .plan: return "Raccoon_Planning"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 30) { // Increased spacing for entry type options
                // Step 1: Select Entry Type (Vent/Explore/Plan)
                if selectedEntryType == nil {
                    Spacer()
                    Text("What kind of dump today?")
                        .font(Font.custom("Georgia-Bold", size: 28)) // Use specified font
                        .foregroundColor(BrandColors.darkBrown) // Use BrandColors
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Display Vent/Explore/Plan options using the recreated style
                    ForEach(Mood.allCases) { entryType in 
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedEntryTypeForAnimation = entryType // For visual feedback
                            }
                             // Delay setting the actual state to allow animation to start
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                selectedEntryType = entryType // Set the type to move to step 2
                                selectedEntryTypeForAnimation = nil // Reset animation state
                            }
                        } label: {
                            // Recreated MoodOptionView structure
                             HStack(spacing: 15) {
                                Image(imageName(for: entryType)) // Use helper func for image name
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40) 

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(entryType.rawValue) // e.g., Vent
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(BrandColors.primaryText(for: .light)) // Use BrandColors

                                    Text(entryType.description) // e.g., "Just need to let it all out."
                                        .font(.subheadline)
                                        .foregroundColor(BrandColors.secondaryText(for: .light)) // Use BrandColors
                                        .fixedSize(horizontal: false, vertical: true) // Allow text wrapping
                                }
                                Spacer() // Push content left
                            }
                            .padding(20) // Generous padding
                            .background(BrandColors.mintGreen) // Use pastel BrandColor
                            .cornerRadius(15)
                            .shadow(color: BrandColors.darkBrown.opacity(0.08), radius: 5, x: 0, y: 3) // Subtle shadow
                            .scaleEffect(selectedEntryTypeForAnimation == entryType ? 1.05 : 1.0) // Scale effect
                            .overlay( // Add a subtle border highlight if selected
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(selectedEntryTypeForAnimation == entryType ? BrandColors.accentPink : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 40) // Add padding around the buttons

                    Spacer()
                    Spacer()
                    
                     // Add Peeking Raccoon?
                    Image("Raccoon_Peeking")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80) 
                        .padding(.bottom, -10) 
                        .zIndex(1) 

                    // Optional: Cancel button
                    Button("Cancel") { dismiss() }
                        .font(.headline)
                        .foregroundColor(BrandColors.darkBrown.opacity(0.7))
                    
                    Spacer()

                // Step 2: Select Emoji Mood
                } else {
                    // --- Emoji Selection Part (Keep as is for now) ---
                    Text("How are you feeling today?") 
                        .font(.title2)
                        .fontWeight(.medium)
                        .padding(.top)

                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(viewModel.availableMoods) { moodEmoji in
                            Button {
                                if let type = selectedEntryType {
                                    viewModel.finalizeEntryCreation(type: type, emoji: moodEmoji)
                                }
                            } label: {
                                Text(moodEmoji.emoji)
                                    .font(.system(size: 50))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(BrandColors.secondaryBackground(for: .light).opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer() 

                    Button("Back") {
                        withAnimation {
                            selectedEntryType = nil
                        }
                    }
                    .padding(.bottom)
                    // --- End Emoji Selection Part ---
                }
            }
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        }
        .padding(.vertical)
        .background(BrandColors.cream.ignoresSafeArea()) // Use cream background for the whole sheet
    }
}

// MARK: - Preview
#Preview {
    let previewViewModel = ContentViewModel()
    return MoodSelectionSheet()
        .environmentObject(previewViewModel)
        // No extra padding or background needed if the sheet uses its own
} 