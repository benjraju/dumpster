import SwiftUI

#if os(iOS)
struct FontSelectionSheet: View {
    @Binding var selectedFont: String
    @Binding var fontSize: CGFloat
    @Binding var colorScheme: ColorScheme
    let toggleThemeAction: () -> Void
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
                    Toggle("Dark Mode", isOn: Binding<Bool>( 
                        get: { colorScheme == .dark },
                        set: { _ in toggleThemeAction() }
                    ))
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .accentColor(BrandColors.darkBrown)
    }
}
#endif 