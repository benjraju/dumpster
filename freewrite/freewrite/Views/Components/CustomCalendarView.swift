import SwiftUI

struct CustomCalendarView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    @Binding var selectedDate: Date? // Bind to the state in HistoryView

    // Define grid layout
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let daysOfWeek = Date.capitalizedFirstLettersOfWeekdays // Assumes Date extension exists

    var body: some View {
        VStack(spacing: 15) {
            // Header: Month Name and Navigation Buttons
            monthHeader
            
            // Weekday Initials Row
            weekdayHeader
            
            // Calendar Grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(viewModel.generateDaysForDisplayedMonth(), id: \.self) { date in
                    let isPadding = !Calendar.current.isDate(date, equalTo: viewModel.displayedMonth, toGranularity: .month)
                    let isMarked = viewModel.entryDates.contains(Calendar.current.startOfDay(for: date))
                    let isSelected = selectedDate != nil && Calendar.current.isDate(date, inSameDayAs: selectedDate!)
                    
                    CustomDayCellView(
                        date: date,
                        isMarked: isMarked,
                        isSelected: isSelected,
                        isPadding: isPadding,
                        onDateSelected: { selectedDay in
                            selectedDate = selectedDay // Update state in parent (HistoryView)
                        }
                    )
                }
            }
        }
        .padding(.horizontal) // Padding for the overall calendar view
        .onAppear {
            // If no date is selected, default to today
            if selectedDate == nil {
                selectedDate = Date()
            }
            
            // Ensure the displayed month shows the selected date
            if let selected = selectedDate {
                let selectedMonth = Calendar.current.dateComponents([.month, .year], from: selected)
                let displayedMonth = Calendar.current.dateComponents([.month, .year], from: viewModel.displayedMonth)
                
                // If the selected date is in a different month, update displayed month
                if selectedMonth.month != displayedMonth.month || selectedMonth.year != displayedMonth.year {
                    viewModel.displayedMonth = Calendar.current.date(from: selectedMonth) ?? viewModel.displayedMonth
                }
            }
        }
    }
    
    // Extracted Month Header View
    private var monthHeader: some View {
        HStack {
            Button {
                viewModel.changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(BrandColors.defaultDarkBrown)
            }
            
            Spacer()
            
            // Use DateFormatter for wider compatibility
            Text(viewModel.displayedMonth, formatter: monthYearFormatter)
                .font(Font.custom("Georgia-Bold", size: 20))
                .foregroundColor(BrandColors.defaultDarkBrown)
                
            Spacer()
            
            Button {
                viewModel.changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(BrandColors.defaultDarkBrown)
            }
        }
    }
    
    // Date Formatter for Month Header
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy" // e.g., "May 2025"
        return formatter
    }
    
    // Extracted Weekday Header
    private var weekdayHeader: some View {
        HStack {
            ForEach(daysOfWeek, id: \.self) { dayInitial in
                Text(dayInitial)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BrandColors.defaultDarkBrown.opacity(0.6))
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// Assumes Date extension exists for daysOfWeek
extension Date {
    static var capitalizedFirstLettersOfWeekdays: [String] {  
        let calendar = Calendar.current  
        var weekdays = calendar.shortWeekdaySymbols  
        // Adjust for first day of week if needed (e.g., Sunday vs Monday)
        if Calendar.current.firstWeekday > 1 {  
            for _ in 1..<Calendar.current.firstWeekday {  
                if let first = weekdays.first {  
                    weekdays.append(first)  
                    weekdays.removeFirst()  
                }  
            }  
        }  
        return weekdays.map { String($0.prefix(1)).capitalized } // Use only first letter
    } 
}

#Preview {
    CustomCalendarView(selectedDate: .constant(Date()))
        .environmentObject(ContentViewModel())
} 