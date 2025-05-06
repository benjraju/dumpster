import SwiftUI

// Define Brand Colors (can be moved to a dedicated file later)
/*
struct BrandColors {
    static let mintGreen = Color(red: 0.85, green: 0.95, blue: 0.9) 
    static let cream = Color(red: 0.98, green: 0.97, blue: 0.94) 
    static let lightBrown = Color(red: 0.85, green: 0.78, blue: 0.65)
    static let darkBrown = Color(red: 0.4, green: 0.3, blue: 0.25) 
    static let accentPink = Color(red: 1.0, green: 0.8, blue: 0.8) 
}
*/

// MARK: - AI Response Sheet View
struct AIResponseView: View {
    // Remove isPresented binding if sheet is controlled by .sheet(item:)
    // @Binding var isPresented: Bool 
    @EnvironmentObject var viewModel: ContentViewModel // Access ViewModel
    let sections: [MarkdownSection] // Keep receiving sections
    
    // Add state to track the current visible card index and favorite status
    @State private var currentCardIndex = 0
    // Get the current entry's favorite status (needs access to the entry ID)
    private var isCurrentEntryFavorite: Bool {
        guard let entryId = viewModel.selectedEntryId,
              let entry = viewModel.entries.first(where: { $0.id == entryId }) else {
            return false
        }
        return entry.isFavorite
    }

    // State for sharing
    @State private var showShareSheet = false
    @State private var sharedImage: UIImage? = nil
    @State private var isPreparingShareImage = false

    // Define color from reference - Use BrandColors
    // private let cardBackgroundColor = Color(red: 1.0, green: 0.96, blue: 0.86)

    // Use brand colors
    // private let gradientStart = Color(red: 0.9, green: 0.85, blue: 1.0) // Lavender-ish
    // private let gradientEnd = Color(red: 0.85, green: 0.95, blue: 0.9)   // Mint-ish
    // private let activePillColor = Color(red: 0.6, green: 0.9, blue: 0.8) // Mint green

    var body: some View {
        NavigationView { 
            VStack(spacing: 0) { 
                if sections.isEmpty {
                    Text("No feedback generated or content was only a greeting.")
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(BrandColors.cream) // Use cream background
                } else {
                    VStack(spacing: 0) { // Main container for TabView + Pills
                        TabView(selection: $currentCardIndex) {
                            ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                                // --- Card View --- 
                                ScrollView(.vertical, showsIndicators: true) { 
                                    ZStack(alignment: .topTrailing) { // Use ZStack for overlay
                                        VStack(spacing: 20) { // Arrange card content vertically
                                            Spacer()
                                            
                                            Image("AICardIllustration") // Use your asset name
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 100) // Adjust size
                                                
                                            VStack(alignment: .center, spacing: 10) {
                                                if let title = section.title, !title.isEmpty { 
                                                    Text(title) 
                                                         // Use serif font
                                                        .font(Font.custom("Georgia-Bold", size: 28))
                                                        .foregroundColor(BrandColors.darkBrown)
                                                        .padding(.bottom, 5)
                                                }
                                                Text(LocalizedStringKey(section.content)) 
                                                    .font(.system(size: 17)) // Standard body size
                                                    .lineSpacing(5) 
                                                    .foregroundColor(BrandColors.darkBrown.opacity(0.9))
                                                    .multilineTextAlignment(.leading) // Align text to the left
                                                    // Ensure text takes available width 
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            .padding(.horizontal, 25)
                                            
                                            Spacer()
                                            Spacer()
                                        } // End VStack Content
                                        
                                        // Add Accent Raccoon Image Overlay
                                        Image("Raccoon_Lightbulb")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50) // Adjust size
                                            .padding(15) // Padding from corner
                                            .opacity(0.8) // Make it slightly subtle
                                    }
                                } // End ScrollView
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.vertical, 20) // Add vertical padding inside card
                                // Use a card background color
                                .background(BrandColors.mintGreen.opacity(0.6)) // Example: mint green
                                .cornerRadius(20) // More rounded corners for card
                                .padding(.horizontal, 20) // Padding around card
                                .padding(.bottom, 10) // Space above pills
                               .tag(index) 
                               // --- End Card View --- 
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never)) 
                        
                        // --- Action Buttons --- 
                        HStack(spacing: 20) {
                            Spacer() // Push buttons to center

                            // Favorite Button
                            Button {
                                if let entryId = viewModel.selectedEntryId {
                                    viewModel.toggleFavorite(for: entryId)
                                    // Force view update if necessary, though @EnvironmentObject should handle it
                                }
                            } label: {
                                Label("Favorite", systemImage: isCurrentEntryFavorite ? "heart.fill" : "heart")
                                    .labelStyle(.iconOnly)
                                    .font(.title2)
                                    .foregroundColor(isCurrentEntryFavorite ? BrandColors.accentPink : BrandColors.darkBrown.opacity(0.7)) // Use accentPink
                            }
                            
                            // Copy Button
                            Button {
                                viewModel.copyAIResponseToClipboard(sections: sections)
                                // Add user feedback? Maybe a temporary message?
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .labelStyle(.iconOnly)
                                    .font(.title2)
                                    .foregroundColor(BrandColors.darkBrown.opacity(0.7))
                            }

                            // Share Button
                            Button {
                                Task {
                                    await prepareShareImage()
                                }
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .labelStyle(.iconOnly)
                                    .font(.title2)
                                    .foregroundColor(BrandColors.darkBrown.opacity(0.7))
                            }
                            .disabled(isPreparingShareImage) // Disable while generating image

                            Spacer() // Push buttons to center
                        }
                        .padding(.vertical, 15)
                        .padding(.horizontal)
                        .background(BrandColors.cream) // Match main background
                        // Add overlay for preparing image indicator?
                        .overlay {
                            if isPreparingShareImage {
                                ProgressView()
                                    .tint(BrandColors.darkBrown)
                            }
                        }
                        // --- End Action Buttons ---
                        
                        // --- Progress Pill Hint --- 
                        if sections.count > 1 {
                            HStack(spacing: 8) {
                                ForEach(0..<sections.count, id: \.self) { index in
                                    Circle()
                                        // Use brand colors for pills
                                        .fill(index == currentCardIndex ? BrandColors.darkBrown : BrandColors.lightBrown.opacity(0.6))
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.bottom, 10)
                            .transition(.opacity)
                        }
                        // --- End Progress Pill Hint --- 
                    }
                    .background(BrandColors.cream) // Ensure VStack background is set
                    .navigationTitle("Entry Insights")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { viewModel.activeSheet = nil }
                        }
                    }
                }
            }
            .accentColor(BrandColors.darkBrown)
            .background(BrandColors.cream.ignoresSafeArea()) // Apply to whole NavigationView content
            // --- Share Sheet Modifier --- 
            .sheet(isPresented: $showShareSheet) {
                // Present share sheet AFTER image is prepared
                if let imageToShare = sharedImage {
                    ActivityViewController(activityItems: [imageToShare])
                } else {
                    // Optional: Show an error or placeholder if image generation failed
                    Text("Could not prepare image for sharing.")
                }
            }
        }
        .navigationViewStyle(.stack) // Add stack style for consistent presentation
    }
    
    // Function to generate the snapshot
    @MainActor
    private func prepareShareImage() async {
        print("DEBUG: Preparing share image...")
        isPreparingShareImage = true
        sharedImage = nil // Clear previous image
        
        // Construct the view to snapshot
        let insightToShare = sections.map { $0.content }.joined(separator: "\n\n") // Combine sections for now
        let currentEntry = viewModel.entries.first { $0.id == viewModel.selectedEntryId }
        let shareContentView = ShareView(
            insightText: insightToShare,
            mood: currentEntry?.mood,
            entryDate: currentEntry?.date ?? ""
        )
        
        // Define the target rendering size (e.g., higher resolution for sharing)
        let targetSize = CGSize(width: 1080, height: 1920) // Example 9:16 aspect ratio

        // Add a small delay to allow UI to potentially settle if needed
        // await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Generate the snapshot using the RENAMED utility function
        sharedImage = renderViewToImage(view: shareContentView.frame(width: targetSize.width), targetSize: targetSize)
                                
        isPreparingShareImage = false
        
        if sharedImage != nil {
            print("DEBUG: Share image prepared successfully.")
            showShareSheet = true // Trigger the share sheet
        } else {
            print("ERROR: Failed to generate snapshot for sharing.")
            // Optionally show an error alert to the user
        }
    }
}

// MARK: - ActivityViewController for Share Sheet
// Helper to wrap UIActivityViewController for SwiftUI
struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 