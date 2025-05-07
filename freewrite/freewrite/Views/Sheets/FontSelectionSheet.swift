import SwiftUI

#if os(iOS)
// Define ThemeOption struct and options array
struct ThemeOption: Identifiable, Hashable {
    let id: String // Value to store in AppStorage (e.g., "sepia")
    let displayName: String // Value to show in Picker (e.g., "Sepia")
}

let themeOptions: [ThemeOption] = [
    ThemeOption(id: "light", displayName: "Light"),
    ThemeOption(id: "dark", displayName: "Dark"),
    ThemeOption(id: "sepia", displayName: "Sepia"),
    ThemeOption(id: "nord", displayName: "Nord"),
    ThemeOption(id: "dracula_lite", displayName: "Dracula Lite")
]

struct FontSelectionSheet: View {
    @Binding var selectedFont: String
    @Binding var fontSize: CGFloat
    @Binding var colorSchemeString: String // Changed from colorScheme
    @Binding var selectedInsightMode: InsightMode
    let availableFonts: [String] // Consider moving font lists to a shared place or model
    let standardFonts: [String]
    let fontSizes: [CGFloat]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .padding([.top, .trailing])
                    .padding(.bottom, 5)
            }
            
            Form {
                Section("Font Size") {
                    Picker("Size", selection: $fontSize) {
                        ForEach(fontSizes, id: \.self) { size in
                            Text("\(Int(size))px").tag(size)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                Section("Font Family") {
                    List(standardFonts, id: \.self) { fontName in
                        Button(action: { selectedFont = fontName }) {
                            HStack {
                                Text(fontName)
                                Spacer()
                                if selectedFont == fontName {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section("Theme") {
                    Picker("Theme", selection: $colorSchemeString) {
                        ForEach(themeOptions) { option in
                            Text(option.displayName).tag(option.id)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                Section("AI Insight Style") {
                    Picker("Style", selection: $selectedInsightMode) {
                        ForEach(InsightMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .accentColor(BrandColors.accentColor(for: colorSchemeString))
    }
}
#endif 