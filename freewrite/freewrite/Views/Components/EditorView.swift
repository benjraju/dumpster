import SwiftUI

struct EditorView: View {
    @EnvironmentObject var viewModel: ContentViewModel 
    
    @Binding var text: String
    @Binding var selectedFont: String
    @Binding var fontSize: CGFloat
    @Binding var colorSchemeString: String
    var editorFocus: FocusState<Bool>.Binding

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
    
    // TextEditor internal horizontal padding
    private let textEditorHPadding: CGFloat = 15
    // TextEditor internal vertical padding
    private let textEditorVPadding: CGFloat = 10

    // Helper to determine if the current theme is light-based
    private var isLightBasedTheme: Bool {
        return colorSchemeString == "light" || colorSchemeString == "sepia" || colorSchemeString == "dracula_lite"
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: Binding(
                get: { text },
                set: { newValue in
                    text = newValue
                }
            ))
                #if os(iOS)
                .background(Color.clear) 
                #endif
                .focused(editorFocus)
                .font(.custom(selectedFont, size: fontSize))
                .foregroundColor(BrandColors.primaryText(for: colorSchemeString))
                .modifier(ScrollCleanupModifier()) 
                .lineSpacing(lineHeight)
                .id("Editor-\(selectedFont)-\(fontSize)-\(colorSchemeString)")
                .padding(.horizontal, textEditorHPadding)
                .padding(.vertical, textEditorVPadding)

        }
        .background(
            RoundedRectangle(cornerRadius: 15) 
                .fill(BrandColors.secondaryBackground(for: colorSchemeString))
                .shadow(color: Color.black.opacity(isLightBasedTheme ? 0.08 : 0.2), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 20) 
        .padding(.top, 30)        
        .padding(.bottom, 10)     
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