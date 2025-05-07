// Swift 5.0
//
//  ContentView.swift
//  freewrite
//
//  Created by thorfinn on 2/14/25.
//

import SwiftUI
#if os(macOS)
import AppKit // Only import AppKit on macOS
#elseif os(iOS)
import UIKit // Import UIKit on iOS for potential future use
#endif
import UniformTypeIdentifiers
import PDFKit
import Foundation

// MARK: - Removed Model Definitions (Moved to Models/AppDataModels.swift)
/*
struct HumanEntry: Identifiable { ... }
struct HeartEmoji: Identifiable { ... }
*/

// MARK: - Markdown Section Structure
// This struct is now defined in Models/AppDataModels.swift
/*
struct MarkdownSection: Identifiable {
    let id = UUID()
    let title: String? // The heading (e.g., "# Heading") or nil if no heading
    let content: String // The paragraph(s) following the heading
}
*/

struct ContentView: View {
    // MARK: - View Model
    @EnvironmentObject private var viewModel: ContentViewModel
    @AppStorage("colorScheme") private var colorSchemeString: String = "light" // Added AppStorage for theme

    // MARK: - UI State (Owned by ContentView or specific subviews)
    @State private var isFullscreen = false // Potentially move to BottomNavView if only used there
    @State private var selectedFont: String = "Lato-Regular" // Font state remains in View
    @State private var fontSize: CGFloat = 18 // Font state remains in View
    @State private var initiateAICall = false // Trigger for AI call - Keep for BottomToolbarView
    @FocusState private var editorFocus: Bool // Editor focus state

    let entryHeight: CGFloat = 40 // Used in HistoryView?
    
    #if os(macOS)
    let availableFonts = NSFontManager.shared.availableFontFamilies 
    #elseif os(iOS)
    let availableFonts: [String] = UIFont.familyNames.flatMap { family -> [String] in
        UIFont.fontNames(forFamilyName: family)
    }.sorted() // Get iOS fonts
    #endif
    let standardFonts = ["Lato-Regular", "Arial", ".AppleSystemUIFont", "Times New Roman", "Georgia"] // Added Georgia
    let fontSizes: [CGFloat] = [16, 18, 20, 22, 24, 26]
    
    // macOS Specific UI State (Could be moved to MacSidebarView if extracted)
    #if os(macOS)
    @State private var hoveredEntryId: UUID? = nil 
    @State private var showingSidebar = false 
    @State private var hoveredTrashId: UUID? = nil 
    @State private var hoveredExportId: UUID? = nil 
    @State private var isHoveringHistory = false 
    #endif

    // General UI State - REMOVED showingFontSheet, showingTimerSheet
    // @State private var showingFontSheet = false 
    // @State private var showingTimerSheet = false 
    // @State private var activeSheet: ActiveSheet? = nil // MOVED to ViewModel

    @AppStorage("justCompletedFullOnboarding") private var justCompletedFullOnboarding: Bool = false // Access the flag

    init() {
        // REMOVED init related to old colorScheme state
    }
    
    // UI Helpers (toggleTheme might move to ViewModel if it modifies ViewModel state)
    private func hideKeyboard() { 
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
    
    var body: some View {
        // let navHeight: CGFloat = 68 // Keep if used for padding -> REMOVED as unused
        
        HStack(spacing: 0) {
            mainContentArea
            #if os(macOS)
            if showingSidebar {
                macOSSidebar
            }
            #endif
        }
        #if os(macOS)
        .overlay(alignment: .bottom) { macOSBottomNav }
        .animation(.easeInOut(duration: 0.2), value: showingSidebar)
        #endif
        .onAppear(perform: onAppearActions)
        .onChange(of: viewModel.currentText, perform: handleTextChange)
        .onChange(of: initiateAICall, perform: handleAICallChange)
        .onChange(of: viewModel.entryJustCreated, perform: handleEntryCreation)
        #if os(iOS)
        .toolbar { 
            iosKeyboardToolbar
            iosBottomToolbar
        }
        #endif
    }

    // MARK: - Main Content Area
    private var mainContentArea: some View {
        ZStack {
            // DEFINE backgroundPattern here, within the scope where it's used
            let backgroundPattern = ImagePaint(image: Image("Pattern_PastelPaperTile"), scale: 0.2)
            
            Rectangle().fill(backgroundPattern).ignoresSafeArea()
            BrandColors.background(for: colorSchemeString).ignoresSafeArea()
            
            wordCountOverlay
            
            EditorView(
                text: $viewModel.currentText,
                selectedFont: $selectedFont, 
                fontSize: $fontSize, 
                colorSchemeString: $colorSchemeString,
                editorFocus: $editorFocus
            )
            .ignoresSafeArea(.container, edges: .bottom)
            
            loadingAndErrorOverlays
        }
        .onTapGesture { hideKeyboard() }
        .sheet(item: $viewModel.activeSheet) { sheetType in
            viewForSheet(type: sheetType)
                .environmentObject(viewModel)
        }
        .environmentObject(viewModel)
    }

    // MARK: - Overlays
    private var wordCountOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Text("\(viewModel.wordCount) words")
                    .font(.caption)
                    .foregroundColor(BrandColors.secondaryText(for: colorSchemeString)) // MODIFIED
                    .padding(.trailing)
                    .padding(.top, 8)
            }
            Spacer() // Pushes the word count to the top
        }.zIndex(1) // Ensure it draws above the EditorView if overlapping
    }

    private var loadingAndErrorOverlays: some View {
        Group {
            if viewModel.isFetchingAIResponse { 
                LoadingView()
            } else if let error = viewModel.aiError { 
                let _ = print("DEBUG: Displaying error overlay: \(error)")
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .transition(.opacity)
            }
        }
    }

    // MARK: - macOS Specific Views
    #if os(macOS)
    private var macOSSidebar: some View {
        Group {
            Divider()
            VStack(spacing: 0) {
                // --- Sidebar Header --- 
                Button(action: { 
                     // TODO: Move getDocumentsDirectory() call? Maybe viewModel.openDocumentsDirectory()
                     // NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: getDocumentsDirectory().path)
                }) { /* ... Sidebar Header UI ... */ }
                 .buttonStyle(.plain)
                 .padding(.horizontal, 16)
                 .padding(.vertical, 12)
                 .onHover { hovering in isHoveringHistory = hovering }
                Divider()
                // --- Sidebar Entries List --- 
                ScrollView { LazyVStack(spacing: 0) { ForEach(viewModel.entries) { entry in /* ... Sidebar Entry Row UI ... */ } } }
                 .scrollIndicators(.never)
            }
            .frame(width: 200)
            .background(BrandColors.secondaryBackground(for: colorSchemeString)) // MODIFIED
        }
    }

    private var macOSBottomNav: some View {
        BottomNavView(
            fontSize: $fontSize,
            selectedFont: $selectedFont,
            timeRemaining: $viewModel.timeRemaining,
            timerIsRunning: $viewModel.timerIsRunning,
            colorSchemeString: $colorSchemeString, // MODIFIED
            activeSheet: $viewModel.activeSheet,
            initiateAICall: $initiateAICall,
            isFullscreen: $isFullscreen,
            createNewEntryAction: viewModel.createNewEntry,
            saveCurrentEntryAction: { viewModel.saveCurrentEntry(currentText: viewModel.currentText) }
        )
        .padding() 
        .background(BrandColors.background(for: colorSchemeString)) // MODIFIED
    }
    #endif

    // MARK: - Sheet Content Logic
    @ViewBuilder
    private func viewForSheet(type: ActiveSheet) -> some View {
        switch type {
            case .font: fontSelectionSheet()
            case .history: historySheet()
            case .aiResponse: aiResponseSheet()
            case .tutorial: tutorialSheet()
            case .newEntryPrompt: newEntryPromptSheet()
            case .moodSelection: moodSelectionSheet()
        }
    }

    private func fontSelectionSheet() -> some View {
        FontSelectionSheet(
            selectedFont: $selectedFont, 
            fontSize: $fontSize, 
            colorSchemeString: $colorSchemeString, // MODIFIED to pass colorSchemeString
            selectedInsightMode: $viewModel.selectedInsightMode,
            availableFonts: availableFonts, 
            standardFonts: standardFonts, 
            fontSizes: fontSizes
        )
    }

    private func historySheet() -> some View {
        HistoryView(
            loadEntryAction: viewModel.selectEntry,
            deleteEntryAction: viewModel.deleteEntry,
            saveCurrentEntryAction: { viewModel.saveCurrentEntry(currentText: viewModel.currentText) }
        )
    }

    private func aiResponseSheet() -> some View {
        AIResponseView(sections: viewModel.aiResponseSections)
    }

    private func tutorialSheet() -> some View {
        TutorialView()
    }

    private func newEntryPromptSheet() -> some View {
        OnboardingView(showSplash: .constant(false))
    }

    private func moodSelectionSheet() -> some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            return AnyView(MoodSelectionSheet())
        } else {
            return AnyView(VStack {
                Text("Sorry! This feature requires iOS 16 or newer.")
                    .padding()
                Button("OK") {
                    viewModel.activeSheet = nil // Dismiss the sheet
                }
                .padding()
            })
        }
    }
    
    // MARK: - iOS Specific Toolbars
    #if os(iOS) // Ensure definitions are within iOS-specific block
    @ToolbarContentBuilder
    private var iosKeyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            HStack {
                Button("Dumpster Dive") {
                    // Prepare and trigger haptic feedback
                    let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                    impactGenerator.prepare()
                    impactGenerator.impactOccurred()
                    
                    Task { await viewModel.fetchGuidingQuestion() }
                }
                .buttonStyle(.borderedProminent).tint(.purple.opacity(0.4))
            }
            .padding(.leading)
            Spacer()
            Button("Done") { editorFocus = false }
        }
    }

    @ToolbarContentBuilder
    private var iosBottomToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            BottomToolbarView(
                activeSheet: $viewModel.activeSheet,
                initiateAICall: $initiateAICall,
                saveCurrentEntryAction: { viewModel.saveCurrentEntry(currentText: viewModel.currentText) }
            )
            .environmentObject(viewModel)
        }
    }
    #endif // End of #if os(iOS) for toolbar definitions

    // MARK: - View Lifecycle and Event Handlers
    private func onAppearActions() {
        #if os(macOS)
        showingSidebar = false // Still seems relevant here
        #endif
        viewModel.loadExistingEntries() // Call ViewModel method

        if justCompletedFullOnboarding {
            print("DEBUG: ContentView appeared after full onboarding. Skipping initial MoodSelectionSheet.")
            justCompletedFullOnboarding = false // Reset the flag
            // Ensure editor gets focus if it was the first entry created via onboarding
            if viewModel.entryJustCreated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Slight delay may be needed
                    editorFocus = true
                    viewModel.entryJustCreated = false // Reset this flag too
                }
            }
        } else {
            print("DEBUG: ContentView appeared normally. Showing MoodSelectionSheet.")
            viewModel.activeSheet = .moodSelection // Always show mood selection on appear
        }
    }

    private func handleTextChange(newText: String) {
        if viewModel.selectedEntryId != nil {
            viewModel.saveCurrentEntry(currentText: newText) 
        }
    }

    private func handleAICallChange(newValue: Bool) {
        if newValue == true {
            // Ensure an entry is selected before fetching AI
            if let currentFilename = viewModel.entries.first(where: { $0.id == viewModel.selectedEntryId })?.filename {
                Task { 
                    await viewModel.fetchAIResponse(entryFilename: currentFilename) // Call ViewModel method
                    initiateAICall = false 
                }
            } else {
                print("WARN: Cannot fetch AI response, no entry selected.")
                initiateAICall = false // Reset flag if no entry selected
            }
        }
    }

    private func handleEntryCreation(newValue: Bool) {
        if newValue {
            // Brief delay to allow UI update before focusing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                editorFocus = true
                viewModel.entryJustCreated = false // Reset the flag
            }
        }
    }
}

#if os(macOS)
// Helper function to calculate line height (macOS specific)
func getLineHeight(font: NSFont) -> CGFloat {
    return font.ascender - font.descender + font.leading
}
// ... (other macOS helpers) ...
#endif

#Preview { 
    ContentView()
        .environmentObject(ContentViewModel()) // Ensure Preview has ViewModel
}

// MARK: - Removed Inline View Definitions
/*
// --- iOS Specific Sheet Views ---
#if os(iOS)
struct FontSelectionSheet: View { ... }
struct TimerSelectionSheet: View { ... }
struct HistoryView: View { ... }
#endif

// --- Custom ViewModifier for iOS 16+ Scroll Modifiers --- 
struct ScrollCleanupModifier: ViewModifier { ... }

// --- Loading View --- 
struct LoadingView: View { ... }

// --- AI Response Sheet View --- 
struct AIResponseView: View { ... }
*/ 