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
    // @Environment(\.colorScheme) var colorScheme // REMOVED
    @AppStorage("colorScheme") private var colorSchemeString: String = "light" // ADDED
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
                             EntryRowView(entry: entry, colorSchemeString: colorSchemeString) // MODIFIED
                                 .listRowSeparator(.hidden)
                                 .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)) // Adjust padding around cards
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
        .background(BrandColors.background(for: colorSchemeString).ignoresSafeArea()) // MODIFIED
        .navigationBarHidden(true) 
    }
    
    // Extracted Header View
    private var historyHeader: some View {
         ZStack {
             // Centered Title
             HStack {
                 Spacer()
                 Text("History")
                     .font(Font.custom("Georgia-Bold", size: 28))
                     .foregroundColor(BrandColors.primaryText(for: colorSchemeString)) // MODIFIED
                 Spacer()
             }

             // Done button aligned to the right
             HStack {
                 Spacer() // Pushes button to the right
                 Button("Done") { dismiss() }
                     .font(.headline)
                     .foregroundColor(BrandColors.primaryText(for: colorSchemeString)) // MODIFIED
             }
         }
         .padding(.horizontal)
         .padding(.top, 15)
         .padding(.bottom, 10)
         .background(BrandColors.background(for: colorSchemeString)) // MODIFIED
    }
    
    // Extracted Stats View - Update Icons
    private var statsDisplay: some View {
        HStack {
            StatView(value: "\(viewModel.currentStreak)", label: "Day Streak", iconName: "Raccoon_Streak_Flame", colorSchemeString: colorSchemeString) // MODIFIED
            Spacer()
            StatView(value: "\(viewModel.totalEntries)", label: "Total Dumps", iconName: "Raccoon_Entry_Toss", colorSchemeString: colorSchemeString) // MODIFIED
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
    let colorSchemeString: String // MODIFIED
    
    @State private var loadedUIImage: UIImage? = nil // State for the loaded image
    
    private var hasPhotoFilename: Bool {
        entry.photoFilename != nil && !(entry.photoFilename?.isEmpty ?? true)
    }

    private var isLightBasedTheme: Bool { // ADDED helper
        return colorSchemeString == "light" || colorSchemeString == "sepia" || colorSchemeString == "dracula_lite"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Image Display Area
            ZStack {
                if let uiImage = loadedUIImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else if hasPhotoFilename {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(BrandColors.secondaryBackground(for: colorSchemeString).opacity(0.5)) // MODIFIED
                    Image(systemName: "photo.on.rectangle.angled") // Placeholder icon
                        .font(.title2)
                        .foregroundColor(BrandColors.secondaryText(for: colorSchemeString)) // MODIFIED
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.clear) 
                }
            }
            .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(entry.previewText.isEmpty ? "(Empty Entry)" : entry.previewText)
                    .font(.headline)
                    .foregroundColor(BrandColors.primaryText(for: colorSchemeString)) // MODIFIED
                    .lineLimit(2)
                
                HStack {
                    Image(entry.mood.illustrationName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20) // Consider adjusting size
                    Text(entry.date)
                        .font(.subheadline)
                        .foregroundColor(BrandColors.secondaryText(for: colorSchemeString)) // MODIFIED
                    Spacer() // Add Spacer to push heart to the right
                    if entry.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(BrandColors.accentPink) // Use a brand color for the heart
                            .font(.subheadline) // Match the font style of the date
                    }
                }
            }
            Spacer() 
        }
        .padding(12)
        .background(BrandColors.secondaryBackground(for: colorSchemeString).opacity(isLightBasedTheme ? 0.3 : 0.2)) // MODIFIED
        .cornerRadius(10)
        .onAppear(perform: loadImage)
        // Optional shadow (uncomment to use)
        // .shadow(color: BrandColors.defaultDarkBrown.opacity(0.1), radius: 3, x: 0, y: 2) // MODIFIED if uncommented
    }
    
    private func loadImage() {
        guard let filename = entry.photoFilename, !filename.isEmpty else { return }
        
        // Construct the path to the image in the app's documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let freewriteDirectory = documentsDirectory.appendingPathComponent("Freewrite")
        let fileURL = freewriteDirectory.appendingPathComponent(filename)
        
        // Load the image data
        // Doing this on a background thread to avoid blocking UI, then update state on main
        DispatchQueue.global(qos: .userInitiated).async {
            if let imageData = try? Data(contentsOf: fileURL),
               let uiImage = UIImage(data: imageData) {
                DispatchQueue.main.async {
                    self.loadedUIImage = uiImage
                }
            }
        }
    }
}

// Simple View for displaying a stat
struct StatView: View {
    let value: String
    let label: String
    let iconName: String
    let colorSchemeString: String // MODIFIED

    var body: some View {
        HStack(spacing: 8) { // Added spacing
            Image(iconName) // This now uses the corrected names passed in
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30) // Adjust size
                // .font(.title2) // Remove font modifier
                // .foregroundColor(BrandColors.defaultDarkBrown.opacity(0.8)) // MODIFIED if uncommented
            VStack(alignment: .leading) {
                Text(value)
                    .font(Font.custom("Georgia-Bold", size: 20))
                    .foregroundColor(BrandColors.primaryText(for: colorSchemeString)) // MODIFIED
                Text(label)
                    .font(.caption)
                    .foregroundColor(BrandColors.secondaryText(for: colorSchemeString)) // MODIFIED
            }
        }
    }
}

#endif 
