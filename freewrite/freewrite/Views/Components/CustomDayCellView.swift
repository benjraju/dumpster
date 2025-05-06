import SwiftUI

struct CustomDayCellView: View {
    let date: Date
    let isMarked: Bool          // Does this day have an entry?
    let isSelected: Bool        // Is this day the selected day?
    let isPadding: Bool         // Is this day from the previous/next month?
    let onDateSelected: (Date) -> Void // Callback when tapped
    
    @Environment(\.colorScheme) var colorScheme // Add color scheme environment

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
                        .fill(isSelected ? BrandColors.darkBrown : (isToday ? BrandColors.background(for: colorScheme).opacity(0.5) : Color.clear))
                        .overlay(
                            Circle()
                                .stroke(isToday ? BrandColors.primaryText(for: colorScheme).opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                )
            
            // Dot indicator
            Circle()
                .fill(isMarked ? BrandColors.primaryText(for: colorScheme).opacity(0.7) : Color.clear)
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
            return Color.white
        } else if isPadding {
            return BrandColors.secondaryText(for: colorScheme).opacity(0.5) // Faded for padding days
        } else if isToday {
            return BrandColors.primaryText(for: colorScheme)
        } else {
            return BrandColors.primaryText(for: colorScheme).opacity(0.8)
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
} 