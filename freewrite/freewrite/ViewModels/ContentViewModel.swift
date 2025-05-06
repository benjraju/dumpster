//
//  ContentViewModel.swift
//  freewrite
//
//  Created by Benjamin // AI Assistant on 4/25/25. 
//

import Foundation
import SwiftUI // Import SwiftUI for @Published, ColorScheme, etc. if needed later
import SafariServices

// MARK: - Removed Model Definitions (Moved to Models/AppDataModels.swift)
/*
// Define the MarkdownSection struct here as well, or move it to a shared file
struct MarkdownSection: Identifiable { ... }

// Define OpenAI API Structures here or move to a shared file
struct OpenAIRequest: Codable { ... }
struct OpenAIMessage: Codable { ... }
struct OpenAIResponse: Codable { ... }
struct OpenAIChoice: Codable { ... }
struct OpenAIUsage: Codable { ... }
struct OpenAIError: Codable { ... }
*/

// Required for file operations
private let fileManager = FileManager.default

@MainActor // Ensure @Published properties are updated on the main thread
class ContentViewModel: ObservableObject {
    
    // MARK: - App Storage Flags
    // @AppStorage("shouldStartInitialSession") var shouldStartInitialSession: Bool = false // REMOVED

    // MARK: - Core Data State (Moved from ContentView)
    @Published var entries: [HumanEntry] = []
    @Published var selectedEntryId: UUID? = nil
    @Published var currentText: String = "" // Main text content, synced with View
    @Published var selectedMood: Mood? = nil // ADDED: Track selected mood
    @Published var entryJustCreated: Bool = false // ADDED: Flag for focusing editor

    // MARK: - AI Properties (Moved from ContentView)
    @Published var aiResponseSections: [MarkdownSection] = []
    @Published var isFetchingAIResponse: Bool = false
    @Published var aiError: String? = nil {
        didSet {
            errorDismissTimer?.invalidate()
            if aiError != nil {
                errorDismissTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                    // Schedule the change directly on the main actor
                    Task { @MainActor in
                        self?.aiError = nil 
                    }
                }
            }
        }
    }
    @Published var activeSheet: ActiveSheet? = nil // <-- Use the enum here
    // @Published var showingAIResponseSheet: Bool = false 
    
    // Timer for auto-dismissing errors
    private var errorDismissTimer: Timer?
    
    // MARK: - Timer State (REMOVED)
    // @Published var timeRemaining: Int = 900
    // @Published var timerIsRunning: Bool = false
    // private var countdownTimer: Timer?
    
    // MARK: - Prompt State (REMOVED)
    // @Published var showingDumpDurationPrompt = false 
    // @Published var showingTimerFinishedPrompt = false 
    
    // MARK: - Initial Session State (REMOVED)
    // @Published var initialSessionMessage: String? = nil 
    // @Published var showingInitialSessionPrompt = false 
    
    // MARK: - Other Published Properties (Add as needed)
    // @Published var text: String = "" // Renamed to currentText for clarity
    
    // Keep prompts internal for now
    private let aiChatPrompt = """
    Okay, friend, thanks for dumping this here. Let's sort through it.
    
    Treat the entry below like a pile of thoughts someone just brain-dumped. Your job isn't to be a therapist, but more like that one insightful friend who listens, connects dots the person might miss, and maybe offers a gentle nudge or a different perspective. 
    
    - **Tone:** Casual, warm, empathetic, maybe a tiny bit playful (like a friendly raccoon helper!). Avoid clinical language, overly formal structures, or sounding like a generic chatbot.
    - **Goal:** Help the user feel seen, understood, and maybe a little lighter or clearer. Make connections *between* different points they raised if possible.
    - **What NOT to do:** Don't just summarize point-by-point. Don't give generic advice. Don't use overly therapeutic jargon. Don't sound *exactly* like the user, be a distinct friendly voice.
    - **Format:** Use simple paragraphs. Use markdown bolding **only** for truly key takeaways or shifts in perspective you want to highlight (use sparingly).
    
    Example opening lines (pick one or adapt):
    * "Whoa, okay, thanks for sharing all that. My first thought is..."
    * "Got it. Reading through this, what jumps out at me is..."
    * "Alright, let's unpack this dump..."

    Here's the entry:
    """
    
    // ADDED: New prompt for in-line guiding questions
    private let aiGuidingQuestionPrompt = """
    You are an AI assistant integrated into a writing app. The user has written the text below and pressed a button requesting a prompt to help them dive deeper or keep writing.
    Analyze the user's text (and potentially their stated mood) and provide ONE SINGLE concise, open-ended question that gently encourages further reflection or exploration based on what they've written.
    The question should feel like a natural continuation or a gentle nudge, tailored to the user's mood if provided.
    Keep it short (ideally under 15 words).
    Do NOT offer summaries, analysis, or multiple questions.
    Do NOT use markdown.
    Focus on asking "what", "how", "why", or "tell me more" style questions related to the *content* of their writing.

    User's Mood (if provided): [MOOD]
    User's Recent Text:
    """
    
    // TODO: Move other relevant state/logic here later (e.g., entries, text, save/load) -> Done for entries/selectedId/text

    // MARK: - State for Custom Calendar
    @Published var displayedMonth: Date = {
        // Get the current date and modify it to the first day of the current month
        let today = Date()
        var calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: today)
        components.day = 1 // First day of the current month
        return calendar.date(from: components) ?? today
    }()

    // MARK: - Mood Properties
    let availableMoods: [MoodEmoji] = MoodEmoji.allMoods // Make moods available

    init() {
        // Initialization logic if needed
        // No need to load entries here, View's onAppear will trigger it
    }
    
    // MARK: - Timer Management (REMOVED)
    // private func startTimer() { ... }
    // private func stopTimer() { ... }
    
    // MARK: - Initial Session Handling (REMOVED)
    // func handleInitialSession() { ... }
    // func startTimedInitialSession() { ... }
    // func declineInitialSession() { ... }

    // MARK: - API Key Helper (Moved from ContentView)
    private func getApiKey() -> String? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "OpenAIAPIKey") as? String, !key.isEmpty, key != "your_openai_api_key_here" else {
            print("Error: API Key not found or not set in Info.plist.") 
            self.aiError = "API Key not configured. Please check setup." // Update published property
            return nil
        }
        return key
    }

    // MARK: - Markdown Parsing (Moved from ContentView)
     private func parseMarkdown(_ markdown: String) -> [MarkdownSection] {
        var sections: [MarkdownSection] = []
        var currentTitle: String? = nil
        var currentContentLines: [String] = []

        let lines = markdown.split(whereSeparator: \.isNewline)

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Check for heading lines (#, ##, ###, etc.)
            if trimmedLine.hasPrefix("#") {
                // Save the previous section if it has content
                let processedContent = currentContentLines.joined(separator: "\n")
                                                         .trimmingCharacters(in: .whitespacesAndNewlines)
                if !processedContent.isEmpty || currentTitle != nil {
                    sections.append(MarkdownSection(title: currentTitle, content: processedContent)) 
                }
                // Start new section
                // Clean the title itself (remove #, trim whitespace)
                currentTitle = trimmedLine.drop { $0 == "#" }.trimmingCharacters(in: .whitespaces)
                currentContentLines = []
            } else {
                // Add non-heading line (as original string with potential whitespace) to current content
                currentContentLines.append(String(line)) 
            }
        }
        
        // Add the last section
        let lastProcessedContent = currentContentLines.joined(separator: "\n")
                                                  .trimmingCharacters(in: .whitespacesAndNewlines)
        if !lastProcessedContent.isEmpty || currentTitle != nil {
           sections.append(MarkdownSection(title: currentTitle, content: lastProcessedContent)) 
        }
        
        // If markdown had no headings at all
        if sections.isEmpty && !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
             sections.append(MarkdownSection(title: nil, content: markdown.trimmingCharacters(in: .whitespacesAndNewlines)))
        }

        print("Parsed markdown into \(sections.count) sections.")
        return sections
    }

    // MARK: - API Call Function
    // Needs the selected entry's filename to save the response
    func fetchAIResponse(/* Removed currentText: String */ entryFilename: String?) async { // Use self.currentText
        // Ensure error is nil at the start, triggering didSet if it wasn't
        if aiError != nil { aiError = nil } 
        isFetchingAIResponse = true
        aiResponseSections = [] 
        activeSheet = nil 

        guard let apiKey = getApiKey() else {
            isFetchingAIResponse = false
            return
        }
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            print("Error: Invalid API URL")
            aiError = "Invalid API endpoint URL."
            isFetchingAIResponse = false
            return
        }

        let systemMessage = OpenAIMessage(role: "system", content: aiChatPrompt)
        let userMessage = OpenAIMessage(role: "user", content: self.currentText.trimmingCharacters(in: .whitespacesAndNewlines)) // Use self.currentText
        
        guard userMessage.content.count > 25 else {
            print("User text too short (less than 25 chars after trimming)")
            aiError = "Please write a bit more before requesting feedback."
            isFetchingAIResponse = false
            return
        }

        let requestBody = OpenAIRequest(model: "gpt-4o", messages: [systemMessage, userMessage])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(requestBody)
            print("Sending request to OpenAI...")

            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                 print("HTTP Error: \(httpResponse.statusCode)")
                 if let decodedError = try? JSONDecoder().decode(OpenAIResponse.self, from: data), let apiError = decodedError.error {
                     self.aiError = "API Error: \(apiError.message)" // Use self
                 } else {
                     self.aiError = "Received HTTP status \(httpResponse.statusCode)" // Use self
                 }
            } else {
                let decoder = JSONDecoder()
                let openAIResponse = try decoder.decode(OpenAIResponse.self, from: data)

                if let apiError = openAIResponse.error {
                     print("API Error: \(apiError.message)")
                     self.aiError = "API Error: \(apiError.message)" // Use self
                } else {
                    guard let firstChoice = openAIResponse.choices.first else {
                        print("Error: No response choices received")
                        throw URLError(.cannotParseResponse) 
                    }

                    let responseText = firstChoice.message.content
                    print("\nDEBUG: Raw AI Response Text Received:\n------\n\(responseText)\n------\n") // Log the raw response
                    print("AI Response received (length: \(responseText.count))")
                    
                    // --- Parse the response --- 
                    var parsedSections = self.parseMarkdown(responseText) 
                    
                    // --- Remove common greeting if it's the first section --- 
                    // Check if first section exists and has no title
                    if let firstSection = parsedSections.first, firstSection.title == nil {
                        let processedContent = firstSection.content.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                        let greeting1 = "hey, thanks for showing me this. my thoughts:"
                        let greeting2 = "hey thanks for showing me this. my thoughts:"

                        // Check if the content *starts with* the greeting 
                        // AND consider if the section is *only* the greeting (or very short after)
                        // For simplicity now, just remove if it starts with it.
                        if processedContent.hasPrefix(greeting1) || processedContent.hasPrefix(greeting2) {
                             print("DEBUG: First section starts with greeting, removing entire section.")
                             parsedSections.removeFirst()
                        }
                    }
                    // --- End remove greeting --- 
                    
                    // --- Save AI Response --- 
                    if let filename = entryFilename, !parsedSections.isEmpty {
                        await saveAIResponse(sections: parsedSections, for: filename)
                    }
                    // --- End Save --- 
                    
                    // Update state on main thread
                    self.aiResponseSections = parsedSections 
                    // Always show the sheet on success, even if sections became empty after cleaning
                    self.activeSheet = .aiResponse 
                }
            }
        } catch let error as URLError {
             print("URL Error: \(error)")
             self.aiError = "Network error: \(error.localizedDescription)" // Use self
        } catch let error as DecodingError {
            print("Decoding Error: \(error)")
            self.aiError = "Failed to process AI response." // Use self
        } catch let error as EncodingError {
            print("Encoding Error: \(error)")
            self.aiError = "Failed to prepare request data." // Use self
        } catch {
            print("Unexpected Error: \(error)")
            self.aiError = "An unexpected error occurred: \(error.localizedDescription)" // Use self
        }
        
        // Reset loading state regardless of outcome
        self.isFetchingAIResponse = false // Use self
    }
    
    // MARK: - NEW: AI Guiding Question Function
    func fetchGuidingQuestion() async {
        // Simple error/loading for now
        if isFetchingAIResponse { return } // Don't overlap calls
        isFetchingAIResponse = true // Reuse indicator for now
        let originalError = aiError
        aiError = nil

        guard let apiKey = getApiKey() else {
            isFetchingAIResponse = false
            aiError = originalError // Restore previous error if any
            return
        }

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            print("Error: Invalid API URL")
            aiError = "Invalid API endpoint URL."
            isFetchingAIResponse = false
            return
        }

        // --- Prepare Context ---
        // Get mood description
        let moodDescription = selectedMood?.description ?? "Not specified"

        // Get last ~500 characters of text (or less if text is shorter)
        let textToAnalyze: String
        let trimmedFullText = self.currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        let maxChars = 500
        if trimmedFullText.count <= maxChars {
            textToAnalyze = trimmedFullText
        } else {
            let startIndex = trimmedFullText.index(trimmedFullText.endIndex, offsetBy: -maxChars)
            textToAnalyze = String(trimmedFullText[startIndex...])
        }
        // --- End Prepare Context ---


        // Construct the prompt for the system message
        let systemPromptContent = aiGuidingQuestionPrompt.replacingOccurrences(of: "[MOOD]", with: moodDescription)

        let systemMessage = OpenAIMessage(role: "system", content: systemPromptContent)
        // The user message now only contains the text snippet
        let userMessage = OpenAIMessage(role: "user", content: textToAnalyze)

        // Maybe add a minimum length check here too?
        guard textToAnalyze.count > 10 else { // Check the snippet length
            print("User text snippet too short for guiding question")
            aiError = "Write a little more first!"
            isFetchingAIResponse = false
            return
        }

        // Using a cheaper/faster model might be suitable here if available/desired
        let requestBody = OpenAIRequest(model: "gpt-4o", messages: [systemMessage, userMessage], max_tokens: 50) // Limit response length

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            print("Sending request to OpenAI for guiding question (Mood: \(moodDescription), Text length: \(textToAnalyze.count))...")

            let (data, response) = try await URLSession.shared.data(for: request)

            // Basic HTTP error check
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                 let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                 print("HTTP Error: \(httpResponse.statusCode) - \(errorBody)")
                 self.aiError = "Couldn't get suggestion (HTTP \(httpResponse.statusCode))"
            } else {
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

                if let apiError = openAIResponse.error {
                     print("API Error: \(apiError.message)")
                     self.aiError = "Suggestion Error: \(apiError.message)"
                } else if let firstChoice = openAIResponse.choices.first {
                    let responseText = firstChoice.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("Guiding question received: \(responseText)")
                    // Append the question to the current text
                    self.currentText += "\n\n✨ " + responseText + "\n" // Added sparkle for fun!
                    // Trigger save for the appended text
                    saveCurrentEntry(currentText: self.currentText) // SAVE the appended text
                } else {
                    print("Error: No response choices received for guiding question")
                    self.aiError = "Couldn't get suggestion."
                }
            }
        } catch {
            print("Error fetching guiding question: \(error)")
            self.aiError = "Couldn't get suggestion: \(error.localizedDescription)"
        }

        // Reset loading state
        isFetchingAIResponse = false // Reuse the loading flag
    }
    
    // MARK: - AI Response Saving
    private func saveAIResponse(sections: [MarkdownSection], for originalFilename: String) async {
        guard let aiFilename = aiFilename(from: originalFilename) else { return }
        let fileURL = documentsDirectory.appendingPathComponent(aiFilename) // Assuming documentsDirectory is accessible or passed in
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // Optional: for readability

        print("DEBUG: Attempting to save AI response to \(fileURL.path)")
        do {
            let data = try encoder.encode(sections) // Encode the array of sections
            try data.write(to: fileURL, options: [.atomic])
            print("DEBUG: Successfully saved AI response.")
        } catch {
            print("ERROR: Failed to save AI response: \(error)")
        }
    }

    // MARK: - AI Response Loading/Clearing (Moved from ContentView)
    func loadAIResponse(for originalFilename: String) {
        guard let aiFilename = aiFilename(from: originalFilename) else { return }
        let fileURL = documentsDirectory.appendingPathComponent(aiFilename)
        
        print("DEBUG: Checking for AI response at \(fileURL.path)")
        if FileManager.default.fileExists(atPath: fileURL.path) { // Use default manager
            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                let sections = try decoder.decode([MarkdownSection].self, from: data)
                // Update sections on main thread
                DispatchQueue.main.async { // Ensure main thread update
                    self.aiResponseSections = sections
                    print("DEBUG: Successfully loaded \(sections.count) AI sections.")
                }
            } catch {
                print("ERROR: Failed to load or decode AI response: \(error)")
                DispatchQueue.main.async {
                    self.aiResponseSections = [] // Clear if loading fails
                }
            }
        } else {
            print("DEBUG: No AI response file found.")
             DispatchQueue.main.async {
                 self.aiResponseSections = [] // Clear if no file found
             }
        }
    }

    func clearAIResponse() {
         DispatchQueue.main.async {
            self.aiResponseSections = []
            self.activeSheet = nil // Ensure sheet isn't trying to show old data
         }
    }

    // Make helper public or internal so ContentView can use it
    /*private*/ func aiFilename(from originalFilename: String) -> String? {
        // Assuming format [uuid]-[date].md
        guard let range = originalFilename.range(of: ".md") else { return nil }
        return originalFilename[..<range.lowerBound] + "-ai.json"
    }
    
    // Need access to documentsDirectory (move from ContentView or re-implement)
    private var documentsDirectory: URL {
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Freewrite")
        // Create Freewrite directory if it doesn't exist
        if !fileManager.fileExists(atPath: directory.path) {
            // Use try? to attempt creation and ignore error if it fails (silences unreachable catch warning)
            if (try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)) != nil {
                print("Successfully created Freewrite directory")
            } else {
                print("Error creating Freewrite directory (or it already exists). Proceeding anyway.")
            }
        }
        return directory
    }

    // MARK: - File Management (Moved from ContentView)

    // Load all entries from disk
    func loadExistingEntries() {
        print("DEBUG: ViewModel loading existing entries...")
        var loadedEntries: [HumanEntry] = []
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            let mdFiles = fileURLs.filter { $0.pathExtension == "md" }
            
            let entriesWithDates = mdFiles.compactMap { fileURL -> (entry: HumanEntry, date: Date)? in
                let filename = fileURL.lastPathComponent
                
                // Updated Regex to capture UUID, Date, and optional Mood Initial
                let pattern = "\\[(.*?)\\]-\\[(\\d{4}-\\d{2}-\\d{2}-\\d{2}-\\d{2}-\\d{2})\\](?:-\\[([VEP])\\])?\\\\.md"
                guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
                      let match = regex.firstMatch(in: filename, options: [], range: NSRange(location: 0, length: filename.utf16.count))
                else {
                    print("WARN: Skipping file, failed to parse filename structure: \(filename)")
                    return nil
                }

                // Extract UUID
                guard let uuidRange = Range(match.range(at: 1), in: filename),
                      let uuid = UUID(uuidString: String(filename[uuidRange])) else {
                     print("WARN: Skipping file, failed to extract UUID from: \(filename)")
                    return nil
                }
                
                // Extract Date String and Parse Date Object
                guard let dateRange = Range(match.range(at: 2), in: filename) else {
                    print("WARN: Skipping file, failed to extract date string from: \(filename)")
                    return nil
                }
                let dateString = String(filename[dateRange])
                let fileDateFormatter = DateFormatter()
                fileDateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
                
                guard let fileDate = fileDateFormatter.date(from: dateString) else {
                     print("WARN: Skipping file, failed to parse date string: \(dateString) from filename: \(filename)")
                    return nil
                }
                
                // Extract Mood Initial (Optional)
                var entryMood: Mood = .explore // Default mood if not found or invalid
                if match.range(at: 3).location != NSNotFound, let moodRange = Range(match.range(at: 3), in: filename) {
                    let moodInitial = String(filename[moodRange])
                    switch moodInitial {
                    case "V": entryMood = .vent
                    case "E": entryMood = .explore
                    case "P": entryMood = .plan
                    default: print("WARN: Unknown mood initial '\(moodInitial)' in filename: \(filename). Defaulting to Explore.")
                    }
                }
                
                // Create Display Date String
                let displayDateFormatter = DateFormatter()
                displayDateFormatter.dateFormat = "MMM d"
                let displayDate = displayDateFormatter.string(from: fileDate)
                
                // Create entry with parsed mood and actual date
                return (
                    entry: HumanEntry(id: uuid, date: displayDate, filename: filename, previewText: "(Loading...)", mood: entryMood, actualDate: fileDate), // Pass actualDate
                    date: fileDate // Keep this for sorting initially
                )
            }
            
            // Sort by actual file date, descending
            loadedEntries = entriesWithDates
                .sorted { $0.date > $1.date } // Sort tuple based on the Date
                .map { $0.entry } // Extract just the HumanEntry
                
            self.entries = loadedEntries
            print("DEBUG: Loaded \(self.entries.count) entry references.")

            // Update previews asynchronously after loading references
            Task {
                await updateAllPreviews()
            }

            // Select first entry if none selected or if selected is invalid
            // If no entries, don't automatically create one here. Let the UI prompt for mood first.
            if !self.entries.isEmpty {
                if selectedEntryId == nil || !self.entries.contains(where: { $0.id == selectedEntryId }) {
                    print("DEBUG: Selecting first entry.")
                    selectEntry(entry: self.entries[0]) // Selects and loads
                } else {
                    // If a valid entry IS selected, reload its content.
                    print("DEBUG: Valid entry already selected, reloading content.")
                    if let selectedEntry = self.entries.first(where: { $0.id == selectedEntryId }) {
                        loadEntryContent(entry: selectedEntry)
                    }
                }
            } else {
                 print("DEBUG: No existing entries found.")
                 // Do nothing here, wait for user to create one via mood selection
                 self.currentText = "" // Ensure text editor is empty
                 self.selectedEntryId = nil
                 self.selectedMood = nil
            }
            
        } catch {
            print("ERROR: Failed to load entries: \(error)")
             // Handle error case - maybe clear state?
             self.entries = []
             self.currentText = ""
             self.selectedEntryId = nil
             self.selectedMood = nil
        }
    }

    // Selects an entry and loads its content
    func selectEntry(entry: HumanEntry) {
        guard let entryIndex = entries.firstIndex(where: { $0.id == entry.id }) else {
            print("ERROR: Cannot select entry, not found in array: \(entry.filename)")
            return
        }
        print("DEBUG: Selecting entry: \(entry.filename)")
        selectedEntryId = entry.id
        selectedMood = entry.mood // ADDED: Load mood from entry
        loadEntryContent(entry: entries[entryIndex]) // Load content for the selected entry
        loadAIResponse(for: entries[entryIndex].filename) // Load associated AI response
    }


    // Renamed from saveCurrentEntry and takes text explicitly for clarity from View's perspective
    func saveCurrentEntry(currentText: String) {
        guard let currentId = selectedEntryId,
              let currentEntryIndex = entries.firstIndex(where: { $0.id == currentId }) else {
            print("WARN: Cannot save, no valid entry selected.")
            return
        }
        let entry = entries[currentEntryIndex]
        let fileURL = documentsDirectory.appendingPathComponent(entry.filename)
        
        // Update the ViewModel's currentText first
        self.currentText = currentText

        // Save the text to file
        do {
            try currentText.write(to: fileURL, atomically: true, encoding: .utf8)
            // print("DEBUG: Successfully saved entry: \(entry.filename)") // Reduce log noise
            // Update preview text after successful save
            updatePreviewText(for: entry.id, savedContent: currentText)
            // Maybe trigger AI analysis automatically after saving here?
            // Consider adding a check if text is substantial enough
            // Task {
            //    await fetchAIResponse(entryFilename: entry.filename)
            // }
        } catch {
            print("ERROR: Failed to save entry: \(entry.filename), Error: \(error)")
            // Maybe set an error state?
        }
    }

    // Loads content for a specific entry into currentText
    private func loadEntryContent(entry: HumanEntry) {
        print("DEBUG: Loading content for entry: \(entry.filename)")
        let fileURL = documentsDirectory.appendingPathComponent(entry.filename)
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                let loadedContent = try String(contentsOf: fileURL, encoding: .utf8)
                self.currentText = loadedContent
                print("DEBUG: Successfully loaded content (length: \(loadedContent.count)) for \(entry.filename)")
            } else {
                 print("WARN: File not found when loading content for entry: \(entry.filename)")
                 self.currentText = "\\n\\n" // Reset to default empty state
            }
        } catch {
            print("ERROR: Error loading entry content for \(entry.filename): \(error)")
             self.currentText = "\\n\\n" // Reset on error
        }
    }

    // Modifies this to trigger the mood selection sheet.
    func createNewEntry() {
        print("DEBUG: User initiated new entry flow.")
        clearAIResponse() // Clear old AI response when starting anew
        // Setting .moodSelection will now show the first step (Vent/Explore/Plan)
        self.activeSheet = .moodSelection 
    }

    // RENAMED from selectMoodAndCreateEntry
    // Called by MoodSelectionSheet after an emoji is tapped.
    func finalizeEntryCreation(type: Mood, emoji: MoodEmoji) { // Added type parameter
        print("DEBUG: Finalizing new entry. Type: \(type.rawValue), Mood: \(emoji.emoji) (\(emoji.description))")
        
        // Create the HumanEntry using the selected entry type (Mood enum)
        let newEntry = HumanEntry.createNew(mood: type) 

        // --- Define initial content based on BOTH type and emoji ---
        let typePrompt: String
        switch type {
            case .vent: typePrompt = "spill the tea..."
            case .explore: typePrompt = "vibing with some ideas..."
            case .plan: typePrompt = "okay, what's the vibe check for today?"
        }
        let initialContent = "\(emoji.emoji)\n\n\(typePrompt)\n" // Combine emoji and type-specific prompt

        // --- Save the initial file ---
        self.currentText = initialContent 
        let fileURL = documentsDirectory.appendingPathComponent(newEntry.filename)
        do {
            try self.currentText.write(to: fileURL, atomically: true, encoding: .utf8)
            print("DEBUG: Successfully saved initial file: \(newEntry.filename)")

            // Insert new entry, select it, and update state
            entries.insert(newEntry, at: 0)
            selectedEntryId = newEntry.id
            selectedMood = type // Set selectedMood based on the chosen type
            clearAIResponse() 
            updatePreviewText(for: newEntry.id, savedContent: self.currentText)
            self.entryJustCreated = true // Signal to focus editor

        } catch {
            print("ERROR: Failed to save initial file for new entry: \(newEntry.filename), Error: \(error)")
            // Handle error - maybe revert state?
        }
        
        // Dismiss the sheet
        self.activeSheet = nil 
    }


    // Deletes an entry from the array and the filesystem
    func deleteEntry(entry: HumanEntry) {
        print("DEBUG: Attempting to delete entry: \(entry.filename)")
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else {
            print("ERROR: Cannot delete entry, not found in array: \(entry.filename)")
            return
        }
        
        // Attempt to delete the file
        let fileURL = documentsDirectory.appendingPathComponent(entry.filename)
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                 try fileManager.removeItem(at: fileURL)
                 print("DEBUG: Successfully deleted file: \(entry.filename)")
            } else {
                 print("WARN: File not found for deletion, removing from list anyway: \(entry.filename)")
            }
           
            // Also delete associated AI response file if it exists
            if let aiFilename = aiFilename(from: entry.filename) {
                let aiFileURL = documentsDirectory.appendingPathComponent(aiFilename)
                 if fileManager.fileExists(atPath: aiFileURL.path) {
                    do {
                         try fileManager.removeItem(at: aiFileURL)
                         print("DEBUG: Successfully deleted AI file: \(aiFilename)")
                    } catch {
                        print("ERROR: Failed to delete AI file: \(aiFilename), Error: \(error)")
                    }
                 }
            }

            // Remove from the array
            entries.remove(at: index)
            print("DEBUG: Removed entry from array.")
            
            // Handle selection change
            if selectedEntryId == entry.id {
                 selectedEntryId = nil // Deselect
                 currentText = ""      // Clear text
                 selectedMood = nil    // Clear mood
                if let firstEntry = entries.first {
                    print("DEBUG: Deleted entry was selected, selecting first available.")
                    selectEntry(entry: firstEntry) // Selects and loads content/AI/mood
                } else {
                    print("DEBUG: Deleted last entry. Waiting for new entry creation.")
                    // Don't automatically create a new one, wait for user interaction
                }
            }
        } catch {
            print("ERROR: Failed to delete file: \(entry.filename), Error: \(error)")
            // Consider only removing from array if file deletion succeeds? For now, remove anyway.
             entries.remove(at: index) // Ensure removal from UI list even if file delete fails
             // Re-check selection logic if removal happens despite file delete error
             if selectedEntryId == entry.id {
                if let firstEntry = entries.first { selectEntry(entry: firstEntry) } else { createNewEntry() }
             }
        }
    }

    // Updates the preview text for a single entry in the array (using provided content)
    private func updatePreviewText(for entryId: UUID, savedContent: String) {
        guard let index = entries.firstIndex(where: { $0.id == entryId }) else { return }
        
        let previewContent = savedContent
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let truncatedPreview = previewContent.isEmpty ? "(Empty Entry)" : (previewContent.count > 30 ? String(previewContent.prefix(30)) + "..." : previewContent)
        
        if entries[index].previewText != truncatedPreview {
            // print("DEBUG: Updating preview in array for \(entries[index].filename) to: \(truncatedPreview)")
            entries[index].previewText = truncatedPreview
        }
    }
    
    // Updates previews for all entries by reading their files (can be slow)
    // Call this asynchronously after initial load.
    private func updateAllPreviews() async {
        print("DEBUG: Updating all entry previews...")
        var updatedEntries = self.entries // Work on a copy

        for i in 0..<updatedEntries.count {
            let entry = updatedEntries[i]
            let fileURL = documentsDirectory.appendingPathComponent(entry.filename)
            do {
                if fileManager.fileExists(atPath: fileURL.path) {
                    let content = try String(contentsOf: fileURL, encoding: .utf8)
                     let previewContent = content
                        .replacingOccurrences(of: "\n", with: " ")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    let truncatedPreview = previewContent.isEmpty ? "(Empty Entry)" : (previewContent.count > 30 ? String(previewContent.prefix(30)) + "..." : previewContent)
                    
                    if updatedEntries[i].previewText != truncatedPreview {
                         updatedEntries[i].previewText = truncatedPreview
                    }
                } else {
                     if updatedEntries[i].previewText != "(File Missing)" {
                         updatedEntries[i].previewText = "(File Missing)"
                     }
                }
            } catch {
                 print("ERROR: Failed to read file for preview update: \(entry.filename), Error: \(error)")
                 if updatedEntries[i].previewText != "(Error)" {
                      updatedEntries[i].previewText = "(Error)"
                 }
            }
        }
        
        // Update the main entries array on the main thread
         await MainActor.run {
             self.entries = updatedEntries
             print("DEBUG: Finished updating all previews.")
         }
    }


    // MARK: - URL Opening Functions (Moved from ContentView)
    func openChatGPT(/* Removed currentText: String */) { // Use self.currentText
        let trimmedText = self.currentText.trimmingCharacters(in: .whitespacesAndNewlines) // Use self.currentText
        // Use the prompt defined within this ViewModel
        let fullText = aiChatPrompt + "\n\n" + trimmedText 
        
        if let encodedText = fullText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://chat.openai.com/?m=" + encodedText) {
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #elseif os(iOS)
            // Ensure UIKit is available if using this on iOS target
             guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
             guard let window = scene.windows.first else { return }
             window.rootViewController?.present(SFSafariViewController(url: url), animated: true)
            // UIApplication.shared.open(url) // Less preferred, opens externally
            #endif
        } else {
            print("Error creating ChatGPT URL")
        }
    }

    // MARK: - Entry Actions

    func toggleFavorite(for entryId: UUID) {
        guard let index = entries.firstIndex(where: { $0.id == entryId }) else {
            print("WARN: Cannot toggle favorite, entry ID \(entryId) not found.")
            return
        }
        entries[index].isFavorite.toggle()
        let isNowFavorite = entries[index].isFavorite
        print("DEBUG: Toggled favorite for entry \(entryId) to \(isNowFavorite).")
        // TODO: Add persistence logic here later (e.g., save to UserDefaults, CoreData, etc.)
    }

    func copyAIResponseToClipboard(sections: [MarkdownSection]) {
        let combinedText = sections.map { section in
            var text = ""
            if let title = section.title, !title.isEmpty {
                text += "\n## \(title)\n\n"
            }
            text += section.content
            return text
        }.joined(separator: "\n\n")

        if !combinedText.isEmpty {
            #if os(iOS)
            UIPasteboard.general.string = combinedText
            print("DEBUG: AI Response copied to clipboard.")
            // Maybe show a brief confirmation message?
            #elseif os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(combinedText, forType: .string)
            print("DEBUG: AI Response copied to clipboard.")
            // Maybe show confirmation?
            #endif
        } else {
            print("WARN: Attempted to copy empty AI response.")
        }
    }

    // MARK: - Computed Properties for Calendar & Stats

    var wordCount: Int {
        currentText
            .split { $0.isWhitespace || $0.isNewline }
            .filter { !$0.isEmpty }
            .count
    }

    var groupedEntriesByDay: [Date: [HumanEntry]] {
        Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.actualDate)
        }
    }

    var entryDates: Set<Date> {
        Set(entries.map { Calendar.current.startOfDay(for: $0.actualDate) })
    }

    var totalEntries: Int {
        entries.count
    }

    var currentStreak: Int {
        var streak = 0
        let sortedDates = entryDates.sorted(by: >) // Sort dates descending
        
        guard !sortedDates.isEmpty else { return 0 }
        
        var currentDate = Calendar.current.startOfDay(for: Date()) // Today
        
        // Check if today has an entry
        if sortedDates.first == currentDate {
            streak += 1
            // Check previous days
            for i in 1..<sortedDates.count {
                if let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: currentDate),
                   sortedDates[i] == previousDay {
                    streak += 1
                    currentDate = previousDay // Move to the previous day
                } else {
                    break // Streak broken
                }
            }
        } else {
             // Check if yesterday has an entry (if today doesn't)
             if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: currentDate),
                sortedDates.first == yesterday
             {
                 streak += 1
                 currentDate = yesterday // Start checking from yesterday
                 // Check previous days
                 for i in 1..<sortedDates.count {
                     if let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: currentDate),
                        sortedDates[i] == previousDay {
                         streak += 1
                         currentDate = previousDay // Move to the previous day
                     } else {
                         break // Streak broken
                     }
                 }
             } else {
                 // No entry today or yesterday
                 return 0
             }
        }

        return streak
    }

    // Helper to generate the days grid for the displayed month
    func generateDaysForDisplayedMonth() -> [Date] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: displayedMonth),
              let monthLastWeek = Calendar.current.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1) // Use end-1 day for last week calculation
        else {
            return []
        }
        
        // Calculate the first day to display (might be from previous month)
        let firstDayOfMonth = monthInterval.start
        let firstWeekdayOfMonth = Calendar.current.component(.weekday, from: firstDayOfMonth)
        let calendarFirstWeekday = Calendar.current.firstWeekday
        let daysToShift = (firstWeekdayOfMonth - calendarFirstWeekday + 7) % 7
        guard let gridStartDate = Calendar.current.date(byAdding: .day, value: -daysToShift, to: firstDayOfMonth) else {
            return []
        }
        
        // Calculate the end date for the grid
        let endDate = monthLastWeek.end
        
        var days: [Date] = []
        var currentDate = gridStartDate
        while currentDate < endDate {
            days.append(currentDate)
            guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDay
        }
        
        return days
    }

    // Functions to change displayed month
    func changeMonth(by amount: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: amount, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
} 