import SwiftUI

struct EditorView: View {
    @EnvironmentObject var viewModel: ContentViewModel 
    
    @Binding var text: String
    @Binding var selectedFont: String
    @Binding var fontSize: CGFloat
    @Binding var colorScheme: ColorScheme
    var editorFocus: FocusState<Bool>.Binding

    // Placeholder logic needs state internal to EditorView or passed in
    @State private var placeholderText: String = "" 
    private let placeholderOptions = [
        "\n\nBegin writing",
        "\n\nPick a thought and go",
        "\n\nStart typing",
        "\n\nWhat's on your mind",
        "\n\nJust start",
        "\n\nType your first thought",
        "\n\nStart with one sentence",
        "\n\nJust say it"
    ]
    
    // Compute necessary values based on props
    private var lineHeight: CGFloat {
        #if os(macOS)
        // Simplified calculation, consider passing if complex
        let font = NSFont(name: selectedFont, size: fontSize) ?? .systemFont(ofSize: fontSize)
        return font.pointSize * 0.5 // Adjust line spacing factor if needed
        #elseif os(iOS)
        let font = UIFont(name: selectedFont, size: fontSize) ?? .systemFont(ofSize: fontSize)
        return font.lineHeight * 0.5 
        #endif
    }
    
    // Placeholder top padding offset
    private var placeholderPaddingTop: CGFloat {
        #if os(macOS)
        // Adjust based on TextEditor padding and font metrics if needed
        return 10 // Example
        #elseif os(iOS)
        return 8 // Default TextEditor padding
        #endif
    }
    
    // TextEditor internal horizontal padding
    private let textEditorHPadding: CGFloat = 15
    // TextEditor internal vertical padding
    private let textEditorVPadding: CGFloat = 10

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: Binding(
                get: { text },
                set: { newValue in
                    // Preserve leading newlines if user adds them intentionally
                    // Or enforce starting content after prompt? For now, allow.
                    text = newValue
                    /* Original prefix logic:
                    if !newValue.hasPrefix("\n\n") {
                        text = "\n\n" + newValue.trimmingCharacters(in: .newlines)
                    } else {
                        text = newValue
                    }
                    */
                }
            ))
                // Remove macOS specific background, it will be handled by the ZStack background
                #if os(iOS)
                .background(Color.clear) // Keep iOS clear
                #endif
                .focused(editorFocus)
                .font(.custom(selectedFont, size: fontSize))
                .foregroundColor(BrandColors.primaryText(for: colorScheme))
                .modifier(ScrollCleanupModifier()) // Assume ScrollCleanupModifier is accessible
                .lineSpacing(lineHeight)
                // .frame(maxWidth: 650) // Max width might be controlled by outer padding now
                .id("Editor-\(selectedFont)-\(fontSize)-\(colorScheme)") // Unique ID based on props
                // Apply padding *inside* the box frame
                .padding(.horizontal, textEditorHPadding)
                .padding(.vertical, textEditorVPadding)

            // --- Placeholder Text Overlay --- 
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(placeholderText)
                    .font(.custom(selectedFont, size: fontSize))
                    .foregroundColor(BrandColors.secondaryText(for: colorScheme))
                    .allowsHitTesting(false)
                    // Align placeholder with TextEditor's internal padding
                    .padding(.leading, textEditorHPadding + 5) // Add 5 for default TextEditor internal offset
                    .padding(.top, textEditorVPadding + placeholderPaddingTop)
            }
        }
        // Apply the box styling and external padding to the ZStack
        .background(
            RoundedRectangle(cornerRadius: 15) // Rounded corners
                .fill(BrandColors.secondaryBackground(for: colorScheme)) // Box background color
                .shadow(color: Color.black.opacity(colorScheme == .light ? 0.08 : 0.2), radius: 4, x: 0, y: 2) // Subtle shadow
        )
        // Padding OUTSIDE the box to position it
        .padding(.horizontal, 20) // Space left/right of the box
        .padding(.top, 30)        // Space above the box (reduced)
        .padding(.bottom, 10)     // Space below the box (reduced)
        .onAppear { // Set initial random placeholder when view appears
            placeholderText = placeholderOptions.randomElement() ?? "\n\nBegin writing"
        }
    }
}

// Need ScrollCleanupModifier definition accessible if not already global
// REMOVING the definition below as it's likely declared elsewhere.
/*
struct ScrollCleanupModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .scrollContentBackground(.hidden)
                .scrollIndicators(.never)
        } else {
            // Fallback for older iOS versions if needed
             content
                .onAppear {
                    UITextView.appearance().backgroundColor = .clear
                }
                .onDisappear {
                    UITextView.appearance().backgroundColor = nil
                }
        }
    }
}
*/ 