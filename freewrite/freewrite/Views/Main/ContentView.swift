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

    // MARK: - UI State (Owned by ContentView or specific subviews)
    @State private var isFullscreen = false // Potentially move to BottomNavView if only used there
    @State private var selectedFont: String = "Lato-Regular" // Font state remains in View
    @State private var fontSize: CGFloat = 18 // Font state remains in View
    @State private var colorScheme: ColorScheme = .light // Theme state remains in View
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

    init() {
        let savedScheme = UserDefaults.standard.string(forKey: "colorScheme") ?? "light"
        _colorScheme = State(initialValue: savedScheme == "dark" ? .dark : .light)
    }
    
    // UI Helpers (toggleTheme might move to ViewModel if it modifies ViewModel state)
    private func hideKeyboard() { 
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
    private func toggleTheme() {
         colorScheme = (colorScheme == .light) ? .dark : .light
         UserDefaults.standard.set(colorScheme == .dark ? "dark" : "light", forKey: "colorScheme")
     }
    
    var body: some View {
        // let navHeight: CGFloat = 68 // Keep if used for padding -> REMOVED as unused
        
        // Create ImagePaint for tiling
        let backgroundPattern = ImagePaint(image: Image("Pattern_PastelPaperTile"), scale: 0.2) // Adjust scale as needed
        
        HStack(spacing: 0) {
            // Main content
            ZStack { 
                 // Apply tiled background FIRST
                 Rectangle()
                     .fill(backgroundPattern)
                     .ignoresSafeArea()
                     // Optionally overlay a base color if pattern has transparency
                     // .background(BrandColors.cream)
                 
                 // Apply base color if pattern isn't used or needs tint
                 BrandColors.background(for: colorScheme)
                     .ignoresSafeArea()
                     // Add blend mode if desired
                     // .blendMode(.multiply) 
                     // .opacity(0.9) 
                 
                 // --- Word Count Overlay ---
                 VStack {
                     HStack {
                         Spacer()
                         Text("\(viewModel.wordCount) words")
                             .font(.caption)
                             .foregroundColor(.secondary)
                             .padding(.trailing)
                             .padding(.top, 8)
                     }
                     Spacer() // Pushes the word count to the top
                 }
                 .zIndex(1) // Ensure it draws above the EditorView if overlapping
                 // --- End Word Count Overlay ---
                 
                 EditorView(
                    text: $viewModel.currentText,
                    selectedFont: $selectedFont, 
                    fontSize: $fontSize, 
                    colorScheme: $colorScheme, 
                    editorFocus: $editorFocus
                 )
                 .ignoresSafeArea(.container, edges: .bottom)
                 
                 // --- Loading/Error Overlays --- 
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
            .onTapGesture { hideKeyboard() }
            .sheet(item: $viewModel.activeSheet) { sheetType in // Use viewModel.activeSheet
                switch sheetType {
                    case .font:
                        FontSelectionSheet(
                            selectedFont: $selectedFont, 
                            fontSize: $fontSize, 
                            colorScheme: $colorScheme,
                            toggleThemeAction: toggleTheme,
                            availableFonts: availableFonts, 
                            standardFonts: standardFonts, 
                            fontSizes: fontSizes
                        )
                    // case .timer: // REMOVED
                    //    TimerSelectionSheet(timeRemaining: $viewModel.timeRemaining, timerIsRunning: $viewModel.timerIsRunning)
                    case .history:
                        HistoryView(
                            // REMOVED bindings, pass only actions
                            // entries: $viewModel.entries, 
                            // selectedEntryId: $viewModel.selectedEntryId,
                            // activeSheet: $viewModel.activeSheet,
                            loadEntryAction: viewModel.selectEntry,
                            deleteEntryAction: viewModel.deleteEntry,
                            saveCurrentEntryAction: { viewModel.saveCurrentEntry(currentText: viewModel.currentText) }
                        )
                        .environmentObject(viewModel) // Ensure HistoryView has ViewModel
                    case .aiResponse: 
                        AIResponseView(sections: viewModel.aiResponseSections)
                           .environmentObject(viewModel)
                    case .tutorial:
                        TutorialView()
                    case .newEntryPrompt: // This might be redundant now?
                         // If "New Entry" always goes to mood selection, this might not be used.
                         // Keeping it for now, maybe repurpose later?
                         OnboardingView(showSplash: .constant(false))
                             .environmentObject(viewModel)
                    case .moodSelection: // ADDED
                        MoodSelectionSheet()
                            .environmentObject(viewModel)
                }
            }
            .environmentObject(viewModel) // Inject ViewModel for subviews
           
            // Right sidebar (macOS)
            #if os(macOS)
            if showingSidebar {
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
                .background(Color(colorScheme == .light ? .white : NSColor.black))
            }
            #endif
        }
        #if os(macOS)
        // Apply macOS specific overlay and animation
        .overlay(alignment: .bottom) { 
             BottomNavView(
                fontSize: $fontSize,
                selectedFont: $selectedFont,
                timeRemaining: $viewModel.timeRemaining,
                timerIsRunning: $viewModel.timerIsRunning,
                colorScheme: $colorScheme,
                activeSheet: $viewModel.activeSheet,
                initiateAICall: $initiateAICall,
                isFullscreen: $isFullscreen,
                createNewEntryAction: viewModel.createNewEntry,
                saveCurrentEntryAction: { viewModel.saveCurrentEntry(currentText: viewModel.currentText) }
             )
             .padding() 
             .background(BrandColors.background(for: colorScheme)) 
             .opacity(bottomNavOpacity) // Assuming bottomNavOpacity is defined for macOS
        }
        .animation(.easeInOut(duration: 0.2), value: showingSidebar) // Move animation inside #if block
        #endif
        // These modifiers apply to both platforms
        .preferredColorScheme(colorScheme)
        .accentColor(.primary)
        .onAppear {
            #if os(macOS)
            showingSidebar = false // Still seems relevant here
            #endif
            viewModel.loadExistingEntries() // Call ViewModel method
            // viewModel.handleInitialSession() // REMOVED Call
        }
        .onChange(of: viewModel.currentText) { newText in 
             // Only save if an entry is actually selected
             if viewModel.selectedEntryId != nil {
                 viewModel.saveCurrentEntry(currentText: newText) 
             }
        }
        .onChange(of: initiateAICall) { newValue in 
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
        .onChange(of: viewModel.entryJustCreated) { newValue in
            if newValue {
                // Brief delay to allow UI update before focusing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    editorFocus = true
                    viewModel.entryJustCreated = false // Reset the flag
                }
            }
        }
        // REMOVED alert modifier for initial session prompt
        /*
        .alert("Quick Write?", isPresented: $viewModel.showingInitialSessionPrompt) { ... }
        */
        // --- iOS Toolbar Definition --- 
        #if os(iOS)
        .toolbar { // Keep this structure
             // --- Restore Keyboard Toolbar --- 
             ToolbarItemGroup(placement: .keyboard) {
                  // --- Add AI Prompt Buttons Here ---
                  HStack {
                      Button("AI Dive Deeper") {
                          // initiateAICall = true // OLD: Triggered full analysis sheet
                          // NEW: Call the specific function for inline question
                          Task {
                              await viewModel.fetchGuidingQuestion()
                          }
                      }
                      .buttonStyle(.borderedProminent) // Basic styling
                      .tint(.purple.opacity(0.4)) // Change to pastel purple
                      
                      // Add more prompts here later if needed
                      // Button("Daily Gratitude") { ... }
                  }
                  .padding(.leading) // Add some padding from the left edge
                  // --- End AI Prompt Buttons ---
                  
                  Spacer() // Push button to the right edge
                  Button("Done") {
                      editorFocus = false // Action to remove focus
                  }
              }
             // --- End Restore --- 
            
            // Bottom Bar Toolbar
            ToolbarItemGroup(placement: .bottomBar) {
                 BottomToolbarView(
                    activeSheet: $viewModel.activeSheet,
                    // timerIsRunning: $viewModel.timerIsRunning, // REMOVED
                    // timeRemaining: $viewModel.timeRemaining, // REMOVED
                    // colorScheme: $colorScheme, // REMOVED
                    initiateAICall: $initiateAICall, 
                    // text: $viewModel.currentText, // REMOVED
                    // selectedEntryId: $viewModel.selectedEntryId, // REMOVED
                    // entries: $viewModel.entries, // REMOVED
                    // toggleThemeAction: toggleTheme, // REMOVED
                    saveCurrentEntryAction: { viewModel.saveCurrentEntry(currentText: viewModel.currentText) }
                 )
                 .environmentObject(viewModel) 
             }
        }
        #endif
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