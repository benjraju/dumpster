import SwiftUI

struct CustomDayCellView: View {
    let date: Date
    let isMarked: Bool          // Does this day have an entry?
    let isSelected: Bool        // Is this day the selected day?
    let isPadding: Bool         // Is this day from the previous/next month?
    let onDateSelected: (Date) -> Void // Callback when tapped
    
    @AppStorage("colorScheme") private var colorSchemeString: String = "light"

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .foregroundColor(foregroundColor)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(isSelected ? BrandColors.accentColor(for: colorSchemeString) : (isToday ? BrandColors.background(for: colorSchemeString).opacity(0.5) : Color.clear))
                        .overlay(
                            Circle()
                                .stroke(isToday ? BrandColors.primaryText(for: colorSchemeString).opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                )
            
            // Dot indicator
            Circle()
                .fill(isMarked ? BrandColors.primaryText(for: colorSchemeString).opacity(0.7) : Color.clear)
                .frame(width: 5, height: 5)
                .offset(y: -5) // Position dot slightly below number
                .opacity(isPadding ? 0 : 1) // Hide dot for padding days
        }
        .frame(height: 40) // Ensure consistent cell height
        .contentShape(Rectangle()) // Make entire area tappable
        .onTapGesture {
            if !isPadding { // Only allow selecting days in the current month
                onDateSelected(date)
            }
        }
    }
    
    // Determine text color based on state
    private var foregroundColor: Color {
        if isSelected {
            return determineForegroundColorForAccent(BrandColors.accentColor(for: colorSchemeString))
        } else if isPadding {
            return BrandColors.secondaryText(for: colorSchemeString).opacity(0.5)
        } else if isToday {
            return BrandColors.primaryText(for: colorSchemeString)
        } else {
            return BrandColors.primaryText(for: colorSchemeString).opacity(0.8)
        }
    }

    // Helper function to determine if an accent color is perceived as light or dark
    private func isColorLight(_ color: Color) -> Bool {
        guard let cgColor = color.cgColor else { return true } // Default to light if conversion fails
        guard let components = cgColor.components, components.count >= 3 else { return true }
        // Calculate perceived brightness (luminance)
        let r = components[0]
        let g = components[1]
        let b = components[2]
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.5 // Threshold for being considered light
    }

    private func determineForegroundColorForAccent(_ accentColor: Color) -> Color {
        if isColorLight(accentColor) {
            return BrandColors.primaryText(for: "dark")
        } else {
            return BrandColors.primaryText(for: "light")
        }
    }
}

#Preview {
    // Example previews for different states
    HStack {
        CustomDayCellView(date: Date(), isMarked: true, isSelected: false, isPadding: false, onDateSelected: { _ in })
        CustomDayCellView(date: Date(), isMarked: false, isSelected: true, isPadding: false, onDateSelected: { _ in })
        CustomDayCellView(date: Date.now.addingTimeInterval(-86400*5), isMarked: true, isSelected: false, isPadding: true, onDateSelected: { _ in })
    }.padding()
        .environmentObject(ContentViewModel())
} 