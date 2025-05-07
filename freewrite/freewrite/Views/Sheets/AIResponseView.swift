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
    @EnvironmentObject var viewModel: ContentViewModel
    let sections: [MarkdownSection]
    @AppStorage("colorScheme") private var colorSchemeString: String = "light" // ADDED
    
    @State private var currentCardIndex = 0
    private var isCurrentEntryFavorite: Bool {
        guard let entryId = viewModel.selectedEntryId,
              let entry = viewModel.entries.first(where: { $0.id == entryId }) else { return false }
        return entry.isFavorite
    }

    @State private var showShareSheet = false
    @State private var sharedImage: UIImage? = nil
    @State private var isPreparingShareImage = false
    @State private var entryUIImage: UIImage? = nil

    var body: some View {
        NavigationView { 
            VStack(spacing: 0) { 
                if sections.isEmpty {
                    emptyStateView
                } else {
                    contentAndControlsView
                }
            }
            .accentColor(BrandColors.accentColor(for: colorSchemeString)) // MODIFIED
            .background(BrandColors.background(for: colorSchemeString).ignoresSafeArea()) // MODIFIED
            .onAppear(perform: loadEntryImage)
            .sheet(isPresented: $showShareSheet, content: shareSheetContent)
        }
        .navigationViewStyle(.stack)
    }

    // Extracted Empty State View
    private var emptyStateView: some View {
        Text("No feedback generated or content was only a greeting.")
            .foregroundStyle(BrandColors.secondaryText(for: colorSchemeString)) // MODIFIED
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BrandColors.background(for: colorSchemeString)) // MODIFIED
    }

    // Extracted Content and Controls View
    private var contentAndControlsView: some View {
        VStack(spacing: 0) {
            tabViewContent
            actionButtonsView
            if sections.count > 1 {
                progressPillsView
            }
        }
        .background(BrandColors.background(for: colorSchemeString)) // MODIFIED
        .navigationTitle("Entry Insights")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
    }

    // Extracted TabView Content
    private var tabViewContent: some View {
        TabView(selection: $currentCardIndex) {
            ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                Group {
                    if section.title == "Poetic Reflection", let image = entryUIImage {
                        poeticReflectionCard(section: section, image: image)
                    } else {
                        standardInsightCard(section: section, userImage: entryUIImage)
                    }
                }
               .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    // Extracted Poetic Reflection Card
    @ViewBuilder
    private func poeticReflectionCard(section: MarkdownSection, image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Poetic Reflection")
                .font(Font.custom("Georgia-Bold", size: 22))
                .foregroundColor(BrandColors.primaryText(for: colorSchemeString)) // MODIFIED
            ZStack {
                Image(uiImage: image).resizable().scaledToFill().cornerRadius(10).clipped()
                VStack { 
                    Spacer()
                    Text(section.content).font(.custom("Lato-Regular", size: 19)).foregroundColor(.white)
                        .multilineTextAlignment(.center).padding(10).background(Color.black.opacity(0.4)).cornerRadius(8)
                    Spacer()
                }.padding(15)
            }
            .frame(width: UIScreen.main.bounds.width - 30, height: UIScreen.main.bounds.width - 30)
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(BrandColors.secondaryBackground(for: colorSchemeString)) // MODIFIED
        .cornerRadius(15)
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(BrandColors.lightBrown.opacity(0.5), lineWidth: 1))
        .shadow(color: BrandColors.defaultDarkBrown.opacity(0.1), radius: 5, x: 0, y: 3) // MODIFIED
        .padding(.horizontal, 15)
        .padding(.bottom, 10)
    }

    // Extracted Standard Insight Card
    @ViewBuilder
    private func standardInsightCard(section: MarkdownSection, userImage: UIImage?) -> some View {
        ScrollView(.vertical, showsIndicators: true) { 
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 15) {
                    if let uImage = userImage {
                        Image(uiImage: uImage).resizable().scaledToFit().frame(maxWidth: .infinity).frame(maxHeight: 250).cornerRadius(10).clipped()
                    } else {
                        Image("AICardIllustration").resizable().scaledToFit().frame(height: 100)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        if let title = section.title, !title.isEmpty { 
                            Text(title).font(Font.custom("Georgia-Bold", size: 24))
                                .foregroundColor(BrandColors.primaryText(for: colorSchemeString)) // MODIFIED
                                .padding(.bottom, 2)
                        }
                        Text(LocalizedStringKey(section.content)).font(.custom("Lato-Regular", size: 17)).lineSpacing(5)
                            .foregroundColor(BrandColors.primaryText(for: colorSchemeString).opacity(0.9)) // MODIFIED
                            .multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .leading)
                    }.padding(.horizontal, 20)
                }.padding(.vertical, 20)
                Image("Raccoon_Lightbulb").resizable().scaledToFit().frame(width: 40, height: 40).padding(12).opacity(0.9)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BrandColors.secondaryBackground(for: colorSchemeString)) // MODIFIED
        .cornerRadius(15)
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(BrandColors.lightBrown.opacity(0.5), lineWidth: 1))
        .shadow(color: BrandColors.defaultDarkBrown.opacity(0.1), radius: 5, x: 0, y: 3) // MODIFIED
        .padding(.horizontal, 15)
        .padding(.bottom, 10)
    }

    // Extracted Action Buttons View
    private var actionButtonsView: some View {
        VStack(spacing: 5) {
            HStack(spacing: 20) {
                Spacer()
                Button {
                    #if os(iOS)
                    let impactGenerator = UIImpactFeedbackGenerator(style: .medium) // Medium for favorite
                    impactGenerator.prepare()
                    impactGenerator.impactOccurred()
                    #endif
                    if let entryId = viewModel.selectedEntryId { viewModel.toggleFavorite(for: entryId) }
                } label: { Label("Favorite", systemImage: isCurrentEntryFavorite ? "heart.fill" : "heart").labelStyle(.iconOnly).font(.title2)
                    .foregroundColor(isCurrentEntryFavorite ? BrandColors.accentPink : BrandColors.primaryText(for: colorSchemeString).opacity(0.7)) // MODIFIED
                }
                Button {
                    #if os(iOS)
                    let impactGenerator = UIImpactFeedbackGenerator(style: .light) // Light for copy
                    impactGenerator.prepare()
                    impactGenerator.impactOccurred()
                    #endif
                    viewModel.copyAIResponseToClipboard(sections: sections)
                } label: { Label("Copy", systemImage: "doc.on.doc").labelStyle(.iconOnly).font(.title2)
                    .foregroundColor(BrandColors.primaryText(for: colorSchemeString).opacity(0.7)) // MODIFIED
                }
                Button {
                    #if os(iOS)
                    let impactGenerator = UIImpactFeedbackGenerator(style: .light) // Light for share
                    impactGenerator.prepare()
                    impactGenerator.impactOccurred()
                    #endif
                    Task { await prepareShareImage() }
                } label: { Label("Share", systemImage: "square.and.arrow.up").labelStyle(.iconOnly).font(.title2)
                    .foregroundColor(BrandColors.primaryText(for: colorSchemeString).opacity(0.7)) // MODIFIED
                }.disabled(isPreparingShareImage)
                Button {
                    Task { await viewModel.fetchGeneratedPoem() }
                } label: { Label("Get Poem", systemImage: "wand.and.stars").labelStyle(.iconOnly).font(.title2)
                    .foregroundColor(BrandColors.primaryText(for: colorSchemeString).opacity(0.7)) // MODIFIED
                }.disabled(viewModel.isFetchingPoem || viewModel.isFetchingAIResponse)
                Spacer()
            }
            .padding(.vertical, 10).padding(.horizontal)
            .overlay { if isPreparingShareImage || viewModel.isFetchingPoem { ProgressView().tint(BrandColors.primaryText(for: colorSchemeString)) } } // MODIFIED
            if let poemError = viewModel.poemError {
                Text(poemError).font(.caption).foregroundColor(.red).padding(.horizontal).transition(.opacity)
            }
        }
        .padding(.bottom, 5)
        .background(BrandColors.background(for: colorSchemeString)) // MODIFIED
    }

    // Extracted Progress Pills View
    private var progressPillsView: some View {
        HStack(spacing: 8) {
            ForEach(0..<sections.count, id: \.self) { index in
                Circle()
                    .fill(index == currentCardIndex ? BrandColors.primaryText(for: colorSchemeString) : BrandColors.lightBrown.opacity(0.6)) // MODIFIED
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.bottom, 10)
        .transition(.opacity)
    }

    // Extracted Toolbar Content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done") { viewModel.activeSheet = nil }
        }
    }
    
    // Extracted Share Sheet Content
    @ViewBuilder
    private func shareSheetContent() -> some View {
        if let imageToShare = sharedImage {
            ActivityViewController(activityItems: [imageToShare])
        } else {
            Text("Could not prepare image for sharing.")
        }
    }

    // Function to load the entry's associated image
    private func loadEntryImage() {
        guard let entryId = viewModel.selectedEntryId,
              let entry = viewModel.entries.first(where: { $0.id == entryId }),
              let filename = entry.photoFilename, !filename.isEmpty 
        else { return }
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let freewriteDirectory = documentsDirectory.appendingPathComponent("Freewrite")
        let fileURL = freewriteDirectory.appendingPathComponent(filename)
        DispatchQueue.global(qos: .userInitiated).async {
            if let imageData = try? Data(contentsOf: fileURL), let uiImage = UIImage(data: imageData) {
                DispatchQueue.main.async { self.entryUIImage = uiImage }
            }
        }
    }
    
    // Function to generate the snapshot
    @MainActor
    private func prepareShareImage() async {
        isPreparingShareImage = true
        sharedImage = nil
        
        // Get the current section based on currentCardIndex
        guard sections.indices.contains(currentCardIndex) else {
            print("Error: currentCardIndex is out of bounds for sections.")
            isPreparingShareImage = false
            return
        }
        let currentSection = sections[currentCardIndex]
        let shareTitle = currentSection.title
        let shareContent = currentSection.content
        
        let currentEntry = viewModel.entries.first { $0.id == viewModel.selectedEntryId }
        
        let shareContentView = ShareView(
            title: shareTitle,
            contentText: shareContent,
            mood: currentEntry?.mood,
            entryDate: currentEntry?.date ?? "",
            snapshotImage: (shareTitle == "Poetic Reflection") ? self.entryUIImage : nil
        )
        
        let targetSize = CGSize(width: 1080, height: 1920) // Standard story size
        // Ensure the view is sized appropriately before snapshotting
        let finalViewToSnapshot = shareContentView
            .frame(width: targetSize.width, height: targetSize.height)
            
        sharedImage = freewriteOS.renderViewToImage(view: finalViewToSnapshot, targetSize: targetSize) // Updated to call the global function
        
        isPreparingShareImage = false
        if sharedImage != nil {
            showShareSheet = true
        }
    }
}

// MARK: - ActivityViewController for Share Sheet
struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 