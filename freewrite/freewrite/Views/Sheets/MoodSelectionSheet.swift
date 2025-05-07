import SwiftUI
import PhotosUI // ADDED for PhotosPicker

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

@available(iOS 16.0, macOS 13.0, *) // UPDATED: Set struct availability to match PhotosPicker requirement
struct MoodSelectionSheet: View {
    @EnvironmentObject private var viewModel: ContentViewModel
    @Environment(\.dismiss) var dismiss
    @AppStorage("colorScheme") private var colorSchemeString: String = "light" // Added for consistent color access if needed, though sheet is mostly light-themed

    // State to track the flow
    @State private var selectedEntryType: Mood? = nil // Initially nil
    @State private var selectedEntryTypeForAnimation: Mood? = nil // For animation feedback
    
    // ADDED: State for photo capture flow
    @State private var userSelectedMoodEmoji: MoodEmoji? = nil
    @State private var showPhotoOptionsDialog: Bool = false
    // @State private var showImagePicker: Bool = false // For UIKit ImagePicker, not used with PhotosPicker initially
    // @State private var imagePickerSourceType: UIImagePickerController.SourceType = .camera // For UIKit ImagePicker
    @State private var selectedPhotoItem: PhotosPickerItem? = nil // For SwiftUI PhotosPicker
    @State private var showCameraView: Bool = false // MODIFIED: Will be used to present CameraView

    // ADDED: State to control PhotosPicker presentation
    @State private var isPhotoPickerPresented: Bool = false

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

    // Main body, simplified
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                if selectedEntryType == nil {
                    entryTypeSelectionView
                } else {
                    emojiSelectionView
                }
            }
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        }
        .padding(.vertical)
        .background(BrandColors.cream.ignoresSafeArea()) // Use cream background for the whole sheet
        .confirmationDialog("Add a Check-in Snapshot?", isPresented: $showPhotoOptionsDialog, titleVisibility: .visible) {
            confirmationDialogButtons
        } message: {
            Text("Capture your surroundings or mood with a photo for this check-in.")
        }
        .photosPicker(
            isPresented: $isPhotoPickerPresented, 
            selection: $selectedPhotoItem, 
            matching: .images, 
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotoItem, perform: handlePhotoSelection)
        .sheet(isPresented: $showCameraView, content: cameraSheetContent)
    }

    // Step 1: Select Entry Type View
    private var entryTypeSelectionView: some View {
        VStack(spacing: 30) { // Keep original spacing for this section
            Spacer()
            Text("What kind of dump today?")
                .font(Font.custom("Georgia-Bold", size: 28))
                .foregroundColor(BrandColors.defaultDarkBrown) // MODIFIED
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            ForEach(Mood.allCases) { entryType in 
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        selectedEntryTypeForAnimation = entryType
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        selectedEntryType = entryType
                        selectedEntryTypeForAnimation = nil
                    }
                } label: {
                    HStack(spacing: 15) {
                        Image(imageName(for: entryType))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40) 
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entryType.rawValue)
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(BrandColors.primaryText(for: "light")) // MODIFIED
                            Text(entryType.description)
                                .font(.subheadline)
                                .foregroundColor(BrandColors.secondaryText(for: "light")) // MODIFIED
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .padding(20)
                    .background(BrandColors.mintGreen)
                    .cornerRadius(15)
                    .shadow(color: BrandColors.defaultDarkBrown.opacity(0.08), radius: 5, x: 0, y: 3) // MODIFIED
                    .scaleEffect(selectedEntryTypeForAnimation == entryType ? 1.05 : 1.0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(selectedEntryTypeForAnimation == entryType ? BrandColors.accentPink : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 40)
            Spacer()
            Spacer()
            
             // Add Peeking Raccoon?
            Image("Raccoon_Peeking")
                .resizable()
                .scaledToFit()
                .frame(height: 80) 
                .padding(.bottom, -10) 
                .zIndex(1) 

            Button("Cancel") { dismiss() }
                .font(.headline)
                .foregroundColor(BrandColors.defaultDarkBrown.opacity(0.7)) // MODIFIED
            Spacer()
        }
    }

    // Step 2: Select Emoji Mood View
    private var emojiSelectionView: some View {
        VStack(spacing: 20) { // Keep original spacing for this section
            Text("How are you feeling today?") 
                .font(.title2)
                .fontWeight(.medium)
                .padding(.top)

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(viewModel.availableMoods) { moodEmoji in
                    Button {
                        #if os(iOS)
                        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                        impactGenerator.prepare()
                        impactGenerator.impactOccurred()
                        #endif
                        if selectedEntryType != nil {
                            self.userSelectedMoodEmoji = moodEmoji
                            self.showPhotoOptionsDialog = true
                        } else {
                            print("ERROR: Entry type not selected before choosing mood emoji.")
                        }
                    } label: {
                        Text(moodEmoji.emoji)
                            .font(.system(size: 50))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(BrandColors.secondaryBackground(for: "light").opacity(0.3)) // MODIFIED
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
        }
    }
    
    // Extracted Confirmation Dialog Buttons
    @ViewBuilder
    private var confirmationDialogButtons: some View {
        Button("Take Photo") {
            viewModel.requestCameraPermission { granted in
                DispatchQueue.main.async { 
                    if granted {
                        self.showCameraView = true
                    } else {
                        finalizeWithoutPhoto()
                    }
                }
            }
        }
        Button("Choose from Library") {
            isPhotoPickerPresented = true
        }
        Button("Skip & Continue", role: .destructive) {
            finalizeWithoutPhoto()
        }
        Button("Cancel", role: .cancel) {
            resetPhotoStates()
        }
    }

    // Extracted Camera Sheet Content
    @ViewBuilder
    private func cameraSheetContent() -> some View {
        CameraView { capturedImageData in
            if let imageData = capturedImageData {
                viewModel.selectedImageDataForEntry = imageData
            } else {
                viewModel.selectedImageDataForEntry = nil
            }
            finalizeEntryCreationWithPossiblePhoto()
            showCameraView = false
        }
    }
    
    // Extracted Photo Selection Handling
    private func handlePhotoSelection(_ newItem: PhotosPickerItem?) {
        Task {
            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                viewModel.selectedImageDataForEntry = data
            } else if newItem != nil {
                print("ERROR: Failed to load image data from selected photo item.")
                viewModel.selectedImageDataForEntry = nil
            }
            finalizeEntryCreationWithPossiblePhoto()
        }
    }

    private func finalizeWithoutPhoto() {
        viewModel.selectedImageDataForEntry = nil
        finalizeEntryCreationWithPossiblePhoto()
    }

    private func finalizeEntryCreationWithPossiblePhoto() {
        if let type = selectedEntryType, let emoji = userSelectedMoodEmoji {
            viewModel.finalizeEntryCreation(type: type, emoji: emoji)
            resetPhotoStates()
        } else {
            print("ERROR: Missing entry type or mood emoji during finalization.")
            if viewModel.selectedImageDataForEntry != nil { viewModel.selectedImageDataForEntry = nil } // Clear if photo was loaded but context missing
        }
    }

    private func resetPhotoStates() {
        userSelectedMoodEmoji = nil
        selectedPhotoItem = nil
        showPhotoOptionsDialog = false
        isPhotoPickerPresented = false
    }
}

// MARK: - Preview
#if DEBUG // Keep existing DEBUG flag for previews
@available(iOS 16.0, macOS 13.0, *) // ADDED: Availability check for the preview itself
#Preview {
    let previewViewModel = ContentViewModel()
    return MoodSelectionSheet()
        .environmentObject(previewViewModel)
        // No extra padding or background needed if the sheet uses its own
}
#endif // ADDED: Close the #if DEBUG block 