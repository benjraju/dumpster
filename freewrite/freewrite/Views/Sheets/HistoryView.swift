import SwiftUI
// REMOVED Import for ElegantCalendar
// import ElegantCalendar

#if os(iOS)
// REMOVED Global constants for ElegantCalendar
/*
let calendarStartDate = ...
let calendarEndDate = ...
*/

struct HistoryView: View {
    // REMOVED Redundant Bindings
    // @Binding var entries: [HumanEntry]
    // @Binding var selectedEntryId: UUID?
    // @Binding var activeSheet: ActiveSheet?
    
    // Keep Action Closures
    var loadEntryAction: (HumanEntry) -> Void
    var deleteEntryAction: (HumanEntry) -> Void
    let saveCurrentEntryAction: () -> Void
    
    // Keep Environment properties
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme // Add color scheme environment
    @EnvironmentObject var viewModel: ContentViewModel // Use this for data
    
    // Keep state for selected date
    @State private var selectedDate: Date? = Date() // Initialize with current date
    
    // State for individual word counts
    @State private var individualWordCounts: [UUID: Int]? = nil // Optional for loading state
    
    // Define background color from asset - REMOVED, use BrandColors
    // private let yellowBackground = Color(red: 1.0, green: 0.95, blue: 0.8)
    
    // Computed property for selected day's entries
    private var entriesForSelectedDate: [HumanEntry] {
        guard let date = selectedDate else { return [] }
        let startOfDay = Calendar.current.startOfDay(for: date)
        return viewModel.groupedEntriesByDay[startOfDay] ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            historyHeader
            
            CustomCalendarView(selectedDate: $selectedDate)
                .frame(height: 350)
                .padding(.bottom, 10)
            
            // --- Stats Display --- 
            statsDisplay
                .padding(.vertical, 10)
            
            // --- Entries for Selected Date --- 
            if !entriesForSelectedDate.isEmpty {
                List {
                    Section(header: Text("Entries for \(selectedDateFormatted)")) {
                        ForEach(entriesForSelectedDate) { entry in
                             EntryRowView(entry: entry, colorScheme: colorScheme)
                                 .onTapGesture {
                                     saveCurrentEntryAction()
                                     loadEntryAction(entry) // Select and load this entry
                                     dismiss()
                                 }
                        }
                        .onDelete(perform: deleteSelectedEntries)
                    }
                }
                .listStyle(.plain)
            } else if selectedDate != nil {
                 // Use Empty State Illustration
                 VStack {
                     Spacer()
                     Image("EmptyState_RaccoonShrug") // CORRECTED Filename
                         .resizable()
                         .scaledToFit()
                         .frame(height: 120) 
                     Text("No dumps on this day.")
                         .foregroundColor(.secondary)
                         .padding(.top, 10)
                     Spacer()
                 }
                 .frame(maxHeight: .infinity) 
            } else {
                 // Initial state before date selection
                 VStack {
                     Spacer()
                     // Maybe a different illustration here? Or just text?
                     Image(systemName: "calendar.badge.clock") // Placeholder
                         .font(.largeTitle)
                         .foregroundColor(.secondary)
                         .padding(.bottom, 5)
                     Text("Select a date to see entries.")
                         .foregroundColor(.secondary)
                     Spacer()
                 }
                 .frame(maxHeight: .infinity) 
            }
        }
        .background(BrandColors.background(for: colorScheme).ignoresSafeArea()) // Use dynamic background
        .navigationBarHidden(true) 
    }
    
    // Extracted Header View
    private var historyHeader: some View {
         HStack {
             Spacer()
             Text("History")
                 .font(Font.custom("Georgia-Bold", size: 28))
                 .foregroundColor(BrandColors.primaryText(for: colorScheme)) // Use dynamic color
             Spacer()
             Button("Done") { dismiss() }
                 .font(.headline)
                 .foregroundColor(BrandColors.primaryText(for: colorScheme)) // Use dynamic color
         }
         .padding(.horizontal)
         .padding(.top, 15)
         .padding(.bottom, 10)
         .background(BrandColors.background(for: colorScheme)) // Use dynamic background
    }
    
    // Extracted Stats View - Update Icons
    private var statsDisplay: some View {
        HStack {
            StatView(value: "\(viewModel.currentStreak)", label: "Day Streak", iconName: "Raccoon_Streak_Flame", colorScheme: colorScheme) // Pass colorScheme
            Spacer()
            StatView(value: "\(viewModel.totalEntries)", label: "Total Dumps", iconName: "Raccoon_Entry_Toss", colorScheme: colorScheme) // Pass colorScheme
        }
        .padding(.horizontal, 30)
    }
    
    // Formatted date string
    private var selectedDateFormatted: String {
        guard let date = selectedDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Delete entries from the selected day's list
    private func deleteSelectedEntries(at offsets: IndexSet) {
        let entriesToDelete = offsets.map { entriesForSelectedDate[$0] }
        entriesToDelete.forEach { deleteEntryAction($0) }
        // Optionally clear selectedDate if no entries remain?
        // if entriesForSelectedDate.isEmpty { selectedDate = nil }
    }
}

// MARK: - Helper Views for History

// REMOVED DayView specific to ElegantCalendar
/*
struct DayView: View { ... }
*/

// Row View for displaying an entry in the list below calendar
struct EntryRowView: View {
    let entry: HumanEntry
    let colorScheme: ColorScheme // Add colorScheme parameter
    
    var body: some View {
         VStack(alignment: .leading, spacing: 4) {
             Text(entry.previewText.isEmpty ? "(Empty Entry)" : entry.previewText)
                 .font(.headline)
                 .foregroundColor(BrandColors.primaryText(for: colorScheme)) // Use dynamic color
                 .lineLimit(1)
             HStack {
                 Text(entry.mood.icon)
                 Text(entry.date)
                    .font(.subheadline)
                    .foregroundColor(BrandColors.secondaryText(for: colorScheme)) // Use dynamic color
             }
         }
         .padding(.vertical, 8)
         // Add background to row?
         // .background(BrandColors.mintGreen.opacity(0.3))
         // .cornerRadius(8)
    }
}

// Simple View for displaying a stat
struct StatView: View {
    let value: String
    let label: String
    let iconName: String
    let colorScheme: ColorScheme // Add colorScheme parameter

    var body: some View {
        HStack(spacing: 8) { // Added spacing
            Image(iconName) // This now uses the corrected names passed in
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30) // Adjust size
                // .font(.title2) // Remove font modifier
                // .foregroundColor(BrandColors.darkBrown.opacity(0.8))
            VStack(alignment: .leading) {
                Text(value)
                    .font(Font.custom("Georgia-Bold", size: 20))
                    .foregroundColor(BrandColors.primaryText(for: colorScheme)) // Use dynamic color
                Text(label)
                    .font(.caption)
                    .foregroundColor(BrandColors.secondaryText(for: colorScheme)) // Use dynamic color
            }
        }
    }
}

#endif 
