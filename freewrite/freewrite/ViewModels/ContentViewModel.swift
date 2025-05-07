//
//  ContentViewModel.swift
//  freewrite
//
//  Created by Benjamin // AI Assistant on 4/25/25. 
//

import Foundation
import SwiftUI // Import SwiftUI for @Published, ColorScheme, etc. if needed later
import SafariServices
import AVFoundation // ADDED for camera access
import Photos // ADDED for photo library access
import PhotosUI // ADDED for PhotoPicker

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
    
    @Published var selectedInsightMode: InsightMode = .standard {
        didSet {
            UserDefaults.standard.set(selectedInsightMode.rawValue, forKey: "selectedInsightMode")
            print("DEBUG: Insight mode saved: \\(selectedInsightMode.rawValue)")
        }
    }
    
    // ADDED: For Prompt Chaining
    @Published var lastAskedGuidingQuestion: String? = nil
    
    // ADDED: For Check-in Snapshot image data
    @Published var selectedImageDataForEntry: Data? = nil
    
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
    You are an AI assistant. Your SOLE task is to provide ONE SINGLE concise, open-ended question based on the user\'s text below.
    The question should encourage further reflection or exploration.
    OUTPUT ONLY THE QUESTION. Do NOT provide any preamble, summary, or analysis.
    The question should be short and directly related to their writing.
    If the user\'s text is very short or unclear, ask a general open-ended question like "What else is on your mind regarding this?" or "How does this make you feel?".
    Do NOT use markdown.

    User\'s Mood (if provided): [MOOD]
    User\'s Recent Text:
    """
    
    private let aiPoemPrompt = """
    Analyze the following journal entry. Your task is to generate a short, insightful, and creative poem (either a 3-line haiku or a 2-4 line freeform verse) that captures the core essence, a key theme, or a poignant feeling from the text.

    The poem should:
    - Be reflective and offer a moment of beauty or gentle insight.
    - Use vivid imagery and employ sensory details.
    - Evoke a strong emotion or offer a fresh perspective related to the entry's content.
    - Resonate with the user on an emotional level, offering a sense of connection or a beautiful new way to see their own words.
    - Not be a summary of the entry.
    - **Stylistic Influence:** If appropriate for the content, try to evoke the style of a renowned mystical poet like Rumi, focusing on themes of inner reflection, connection, and the search for meaning. Otherwise, maintain a contemporary freeform style.
    - The poem should have a serene and contemplative tone.

    Do not include any introductory or concluding phrases, just the poem itself. 
    Avoid quotation marks around the poem unless they are part of the poem's content. Output only the poem.

    Journal Entry:
    """
    
    // ADDED: New prompt for follow-up guiding questions
    private let aiFollowUpGuidingQuestionPrompt = """
    You are an AI assistant. The user was previously asked: "[PREVIOUS_QUESTION]"
    They have since added to their text. Their complete current text is below.
    Your SOLE task is to provide ONE SINGLE concise, open-ended follow-up question based on their newest additions and the previous question.
    The question should encourage further reflection. Aim to introduce a new angle or deeper dive.
    OUTPUT ONLY THE QUESTION. Do NOT provide any preamble, summary, or analysis.
    The question should be short. Do NOT repeat the previous question.
    Do NOT use markdown.

    User's Current Text (including response to your last question):
    """
    
    // Poem Generation State
    @Published var generatedPoem: String? = nil // Will be integrated into aiResponseSections
    @Published var isFetchingPoem: Bool = false
    @Published var poemError: String? = nil {
        didSet {
            poemErrorDismissTimer?.invalidate()
            if poemError != nil {
                poemErrorDismissTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                    Task { @MainActor in
                        self?.poemError = nil
                    }
                }
            }
        }
    }
    private var poemErrorDismissTimer: Timer?
    
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
        let savedModeRawValue = UserDefaults.standard.string(forKey: "selectedInsightMode") ?? InsightMode.standard.rawValue
        self.selectedInsightMode = InsightMode(rawValue: savedModeRawValue) ?? .standard
        print("DEBUG: Insight mode loaded: \\(self.selectedInsightMode.rawValue)")
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

    // MARK: - AI Prompt Generation
    private func systemPromptForCurrentMode() -> String {
        let baseInstructions = """
        Treat the entry below like a pile of thoughts someone just brain-dumped. Your job isn't to be a therapist, but more like that one insightful friend who listens, connects dots the person might miss, and maybe offers a gentle nudge or a different perspective.
        - **What NOT to do:** Don't just summarize point-by-point. Don't give generic advice. Don't use overly therapeutic jargon. Don't sound *exactly* like the user, be a distinct friendly voice.
        - **Format:**
          - Structure your response with Markdown headings (e.g., `# Key Observation`, `## Supporting Detail`) to create 2-3 distinct sections. Each section should fit well on a single card.
          - Within each section, use concise paragraphs (2-4 sentences long is ideal).
          - If listing multiple related ideas or steps within a section, use bullet points (e.g., `* First idea`, `- Second idea`).
          - Use markdown bolding **only** for truly key takeaways or shifts in perspective you want to highlight (use sparingly).
          - The overall response should be easily digestible, aiming for around 150-250 words in total.
        """

        switch selectedInsightMode {
        case .standard:
            return """
            Okay, friend, thanks for dumping this here. Let's sort through it.
            \(baseInstructions)
            - **Tone:** Casual, warm, empathetic, maybe a tiny bit playful (like a friendly raccoon helper!). Avoid clinical language, overly formal structures, or sounding like a generic chatbot.
            - **Goal:** Help the user feel seen, understood, and maybe a little lighter or clearer. Make connections *between* different points they raised if possible.
            Example opening lines (pick one or adapt):
            * "Whoa, okay, thanks for sharing all that. My first thought is..."
            * "Got it. Reading through this, what jumps out at me is..."
            * "Alright, let's unpack this dump..."

            Here's the entry:
            """
        case .reflective:
            return """
            Alright, let's take a moment with these thoughts.
            \(baseInstructions)
            - **Tone:** Gentle, curious, and encouraging deeper thought. Think of yourself as a guide helping them explore their own landscape.
            - **Goal:** Identify a core emotion or theme the user expresses. Based on this, ask one or two open-ended questions that help them explore its origins, impact, or underlying meaning. For example, "You mentioned feeling X; I wonder what lies beneath that feeling for you?" or "This experience with Y seems significant. What might it be trying to teach you?"
            - **Focus:** Encourage self-discovery rather than providing direct answers.
            Example opening lines:
            * "Thanks for sharing this. Reading it, I'm curious about..."
            * "This is a rich tapestry of thoughts. Let's explore one thread: ..."

            Here's the entry:
            """
        case .toughLove:
            return """
            Okay, let's be real for a second. Thanks for putting this out there.
            \(baseInstructions)
            - **Tone:** Direct, honest, but still supportive. Not harsh or judgmental, but doesn't shy away from challenging the user if their writing suggests a pattern or a contradiction they might be overlooking.
            - **Goal:** Help the user see a potentially hard truth or a pattern they might be stuck in. For example, "You\'ve mentioned X a few times. What's one thing you know you need to stop lying to yourself about regarding X?" or "I'm hearing a lot of frustration, but also a sense of wanting things to be different. What's one small, bold step you could take?"
            - **Focus:** Gentle confrontation for growth.
            Example opening lines:
            * "Appreciate the honesty here. Let's cut to the chase..."
            * "Reading this, it sounds like you're grappling with something important. My direct take is..."

            Here's the entry:
            """
        case .comfort:
            return """
            Hey, thank you for sharing this. It sounds like a lot is on your mind.
            \(baseInstructions)
            - **Tone:** Warm, validating, and reassuring. Like a comforting presence.
            - **Goal:** Make the user feel heard, validated, and less alone in their feelings. Offer gentle reassurance. For example, "It's okay to feel this way. You did enough today. Rest is the win." or "That sounds really tough, and it's understandable why you'd feel X."
            - **Focus:** Empathy and validation.
            Example opening lines:
            * "Sending a virtual hug after reading that. It's clear you're going through it."
            * "Thanks for trusting this space. What I'm hearing most is..."

            Here's the entry:
            """
        }
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

        let currentSystemPrompt = systemPromptForCurrentMode()
        let systemMessage = OpenAIMessage(role: "system", content: currentSystemPrompt)
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
                    // self.activeSheet = .aiResponse // MOVED DOWN

                    // ADDED: Fetch poem after main insights are processed
                    if !parsedSections.isEmpty { // Optionally, only fetch poem if main insights exist
                        await self.fetchGeneratedPoem() // Will append to aiResponseSections
                    }
                    self.activeSheet = .aiResponse // Now show the sheet with all content
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
        // ADDED: Reset prompt chain after full analysis is shown
        if self.activeSheet == .aiResponse {
           self.lastAskedGuidingQuestion = nil
           print("DEBUG: Prompt chain reset after full AI analysis.")
        }
    }
    
    // MARK: - Poem Generation Function
    func fetchGeneratedPoem() async {
        if isFetchingAIResponse || isFetchingPoem { return } // Prevent multiple simultaneous calls

        isFetchingPoem = true
        poemError = nil
        // generatedPoem = nil // Clear previous poem, will be added as a section

        guard let apiKey = getApiKey() else {
            poemError = "API Key not configured."
            isFetchingPoem = false
            return
        }
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            poemError = "Invalid API endpoint URL."
            isFetchingPoem = false
            return
        }

        let entryText = self.currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !entryText.isEmpty else {
            poemError = "Cannot generate poem from an empty entry."
            isFetchingPoem = false
            return
        }
        
        // It might be good to also check a minimum length here, similar to fetchAIResponse
        guard entryText.count > 20 else { // Arbitrary short length check
            poemError = "Please write a bit more before requesting a poem."
            isFetchingPoem = false
            return
        }

        let systemMessage = OpenAIMessage(role: "system", content: aiPoemPrompt)
        let userMessage = OpenAIMessage(role: "user", content: entryText)
        
        // Using a model known for creativity, max_tokens can be relatively small for a short poem
        let requestBody = OpenAIRequest(model: "gpt-4o", messages: [systemMessage, userMessage], max_tokens: 100) 

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            print("Sending request to OpenAI for poem generation...")

            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                 print("HTTP Error generating poem: \(httpResponse.statusCode)")
                 if let decodedError = try? JSONDecoder().decode(OpenAIResponse.self, from: data), let apiError = decodedError.error {
                     self.poemError = "Poem API Error: \(apiError.message)"
                 } else {
                     self.poemError = "Received HTTP status \(httpResponse.statusCode) for poem."
                 }
            } else {
                let decoder = JSONDecoder()
                let openAIResponse = try decoder.decode(OpenAIResponse.self, from: data)

                if let apiError = openAIResponse.error {
                     print("Poem API Error: \(apiError.message)")
                     self.poemError = "Poem API Error: \(apiError.message)"
                } else {
                    guard let firstChoice = openAIResponse.choices.first else {
                        print("Error: No poem choices received")
                        self.poemError = "No poem content received."
                        throw URLError(.cannotParseResponse) 
                    }

                    let poemText = firstChoice.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("Poem received: \(poemText)")
                    
                    if !poemText.isEmpty {
                        let poemSection = MarkdownSection(title: "Poetic Reflection", content: poemText)
                        // Append to existing sections. This will make it appear as a new card.
                        self.aiResponseSections.append(poemSection)
                        
                        // If an entry is selected, also save this appended AI response
                        if let currentFilename = self.entries.first(where: { $0.id == self.selectedEntryId })?.filename {
                            await saveAIResponse(sections: self.aiResponseSections, for: currentFilename)
                        }
                        
                    } else {
                        self.poemError = "The generated poem was empty."
                    }
                }
            }
        } catch let error as URLError {
             print("Poem URL Error: \(error)")
             self.poemError = "Network error for poem: \(error.localizedDescription)"
        } catch let error as DecodingError {
            print("Poem Decoding Error: \(error)")
            self.poemError = "Failed to process poem response."
        } catch let error as EncodingError {
            print("Poem Encoding Error: \(error)")
            self.poemError = "Failed to prepare poem request data."
        } catch {
            print("Unexpected Poem Error: \(error)")
            self.poemError = "An unexpected error occurred while fetching poem: \(error.localizedDescription)"
        }
        
        isFetchingPoem = false
    }
    
    // MARK: - AI Guiding Question Functionality
    // MODIFIED: This is now the main dispatcher
    func fetchGuidingQuestion() async {
        if isFetchingAIResponse || isFetchingPoem { return } // Prevent overlap

        isFetchingAIResponse = true // Use the main AI loading flag
        // let originalError = aiError // Preserve any existing general AI error
        aiError = nil // Clear general AI error for this specific operation

        if let previousQuestion = lastAskedGuidingQuestion, !previousQuestion.isEmpty {
            print("DEBUG: Fetching FOLLOW-UP guiding question.")
            await fetchFollowUpGuidingQuestion(basedOn: previousQuestion)
        } else {
            print("DEBUG: Fetching INITIAL guiding question.")
            await fetchInitialGuidingQuestion()
        }
        
        isFetchingAIResponse = false
    }

    // NEW: Private function for Initial Guiding Question
    private func fetchInitialGuidingQuestion() async {
        guard let apiKey = getApiKey() else {
            // getApiKey() already sets self.aiError
            return
        }
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            self.aiError = "Invalid API endpoint URL for initial question."
            return
        }

        let moodDescription = selectedMood?.description ?? "Not specified"
        let textToAnalyze: String
        let trimmedFullText = self.currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        let maxChars = 500
        if trimmedFullText.count <= maxChars {
            textToAnalyze = trimmedFullText
        } else {
            let startIndex = trimmedFullText.index(trimmedFullText.endIndex, offsetBy: -maxChars)
            textToAnalyze = String(trimmedFullText[startIndex...])
        }

        guard textToAnalyze.count > 10 else {
            self.aiError = "Write a little more before asking for a guiding question."
            return
        }

        let systemPromptContent = aiGuidingQuestionPrompt
            .replacingOccurrences(of: "[MOOD]", with: moodDescription)
        let systemMessage = OpenAIMessage(role: "system", content: systemPromptContent)
        let userMessage = OpenAIMessage(role: "user", content: textToAnalyze)
        let requestBody = OpenAIRequest(model: "gpt-4o", messages: [systemMessage, userMessage], max_tokens: 80)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            print("Sending request for INITIAL guiding question (Mood: \(moodDescription), Text length: \(textToAnalyze.count))...")
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                self.aiError = "Initial Question Error (HTTP \(httpResponse.statusCode)): \(errorBody.prefix(100))" // Limit error length
            } else {
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                if let apiErr = openAIResponse.error {
                    self.aiError = "Initial Question API Error: \(apiErr.message)"
                } else if let firstChoice = openAIResponse.choices.first {
                    let responseText = firstChoice.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !responseText.isEmpty {
                        self.currentText += "\n\n✨ \(responseText)\n"
                        self.lastAskedGuidingQuestion = responseText // STORE the asked question
                        saveCurrentEntry(currentText: self.currentText)
                    } else {
                        self.aiError = "Received an empty initial question."
                    }
                } else {
                    self.aiError = "No initial question content received."
                }
            }
        } catch let error {
            self.aiError = "Failed to fetch initial question: \(error.localizedDescription)"
        }
    }

    // NEW: Private function for Follow-up Guiding Question
    private func fetchFollowUpGuidingQuestion(basedOn previousQuestion: String) async {
        guard let apiKey = getApiKey() else { return } // getApiKey already sets self.aiError
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            self.aiError = "Invalid API endpoint URL for follow-up."
            return
        }

        let fullTextContext = self.currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Ensure there's some new text after the previous question.
        // This is a basic check; more sophisticated checks might be needed.
        guard fullTextContext.count > (previousQuestion.count + 5) else {
            self.aiError = "Please write a response before asking for a follow-up."
            return
        }

        let systemPromptContent = aiFollowUpGuidingQuestionPrompt
            .replacingOccurrences(of: "[PREVIOUS_QUESTION]", with: previousQuestion)
        let systemMessage = OpenAIMessage(role: "system", content: systemPromptContent)
        let userMessage = OpenAIMessage(role: "user", content: fullTextContext)
        let requestBody = OpenAIRequest(model: "gpt-4o", messages: [systemMessage, userMessage], max_tokens: 80)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            print("Sending request for FOLLOW-UP guiding question (Prev Q: \(previousQuestion))...")
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                self.aiError = "Follow-up Question Error (HTTP \(httpResponse.statusCode)): \(errorBody.prefix(100))" // Limit error length
            } else {
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                if let apiErr = openAIResponse.error {
                    self.aiError = "Follow-up Question API Error: \(apiErr.message)"
                } else if let firstChoice = openAIResponse.choices.first {
                    let responseText = firstChoice.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                     if !responseText.isEmpty {
                        self.currentText += "\n\n↪️ \(responseText)\n" // Different emoji for follow-up
                        self.lastAskedGuidingQuestion = responseText // UPDATE with the new question
                        saveCurrentEntry(currentText: self.currentText)
                    } else {
                        self.aiError = "Received an empty follow-up question."
                    }
                } else {
                    self.aiError = "No follow-up question content received."
                }
            }
        } catch let error {
            self.aiError = "Failed to fetch follow-up question: \(error.localizedDescription)"
        }
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
            print("ERROR: Failed to save AI response for \(originalFilename): \(error)")
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
                let pattern = "\\[(.*?)\\]-\\[(\\d{4}-\\d{2}-\\d{2}-\\d{2}-\\d{2}-\\d{2})\\](?:-\\[([VEP])\\])?\\.md"
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
            
            // Load favorite statuses after entries are loaded and before selection logic
            loadFavoriteStatuses()

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
        self.lastAskedGuidingQuestion = nil // ADDED: Reset prompt chain
        print("DEBUG: Prompt chain reset due to new entry selection: \(entry.filename)")
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
    func finalizeEntryCreation(type: Mood, emoji: MoodEmoji) { // Removed photoData parameter
        print("DEBUG: Finalizing new entry. Type: \(type.rawValue), Mood: \(emoji.emoji) (\(emoji.description))")
        
        var newEntry = HumanEntry.createNew(mood: type) // Create as var to modify photoFilename

        // --- Handle saving snapshot image if present ---
        if let imageData = self.selectedImageDataForEntry {
            if let savedPhotoFilename = saveImageToDocuments(imageData: imageData, forEntryId: newEntry.id) {
                newEntry.photoFilename = savedPhotoFilename
                print("DEBUG: Snapshot image saved as \(savedPhotoFilename) for entry \(newEntry.id)")
            } else {
                print("ERROR: Failed to save snapshot image for entry \(newEntry.id)")
                // Optionally, set an error state for the UI to show?
            }
        }
        // --- End snapshot handling ---

        // --- Define initial content based on BOTH type and emoji ---
        let initialContent = "\(emoji.emoji)\n" // Combine emoji and type-specific prompt

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
            self.lastAskedGuidingQuestion = nil // ADDED: Reset prompt chain
            print("DEBUG: Prompt chain reset due to new entry finalization.")

            // Play success haptic
            #if os(iOS)
            let hapticGenerator = UINotificationFeedbackGenerator()
            hapticGenerator.prepare()
            hapticGenerator.notificationOccurred(.success)
            #endif

        } catch {
            print("ERROR: Failed to save initial file for new entry: \(newEntry.filename), Error: \(error)")
            // Handle error - maybe revert state?
        }
        
        // Clear the selected image data for the next entry
        self.selectedImageDataForEntry = nil
        
        // Dismiss the sheet (assuming activeSheet is managed elsewhere or this is the end of the flow)
        self.activeSheet = nil 
    }

    // MARK: - Image Saving Helper
    private func saveImageToDocuments(imageData: Data, forEntryId id: UUID) -> String? {
        let filename = "\(id.uuidString)-photo.jpg" // Or .png if you prefer
        let fileURL = documentsDirectory.appendingPathComponent(filename) // documentsDirectory is already defined

        do {
            try imageData.write(to: fileURL, options: [.atomic])
            return filename
        } catch {
            print("ERROR: Could not write image to documents directory: \(error)")
            return nil
        }
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
            print("WARN: Cannot toggle favorite, entry ID \\(entryId) not found.")
            return
        }
        entries[index].isFavorite.toggle()
        print("DEBUG: Toggled favorite for entry \\(entries[index].filename) to \\(entries[index].isFavorite).")
        saveFavoriteStatus() // Call to persist the change
    }

    private func saveFavoriteStatus() {
        let favoriteEntryIDs = entries.filter { $0.isFavorite }.map { $0.id.uuidString }
        let fileURL = documentsDirectory.appendingPathComponent("favorites.json")
        
        do {
            let data = try JSONEncoder().encode(favoriteEntryIDs)
            try data.write(to: fileURL, options: .atomic)
            print("DEBUG: Favorite statuses saved to favorites.json")
        } catch {
            print("ERROR: Failed to save favorite statuses: \\(error)")
        }
    }

    private func loadFavoriteStatuses() {
        let fileURL = documentsDirectory.appendingPathComponent("favorites.json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("DEBUG: No favorites.json file found. No favorites loaded.")
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let favoriteEntryIDs = try JSONDecoder().decode([String].self, from: data)
            let favoriteUUIDs = Set(favoriteEntryIDs.compactMap { UUID(uuidString: $0) }) // Use Set for faster lookups
            
            for i in 0..<entries.count {
                if favoriteUUIDs.contains(entries[i].id) {
                    entries[i].isFavorite = true
                } else {
                    entries[i].isFavorite = false // Ensure it's false if not in the list
                }
            }
            print("DEBUG: Favorite statuses loaded. \\(favoriteUUIDs.count) favorites found.")
        } catch {
            print("ERROR: Failed to load or decode favorite statuses: \\(error)")
            // Optionally clear all favorites if loading fails to avoid inconsistent state
            // for i in 0..<entries.count { entries[i].isFavorite = false }
        }
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

    // MARK: - Camera Permission
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            print("DEBUG: Camera permission already authorized.")
            completion(true)
            
        case .notDetermined: // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    print("DEBUG: Camera permission requested. Granted: \(granted)")
                    completion(granted)
                }
            }
            
        case .denied: // The user has previously denied access.
            print("DEBUG: Camera permission denied.")
            // TODO: Optionally, set a state here to guide user to settings
            completion(false)
            
        case .restricted: // The user can't grant access due to restrictions.
            print("DEBUG: Camera permission restricted.")
            completion(false)
            
        @unknown default:
            print("WARN: Unknown camera authorization status.")
            completion(false)
        }
    }

    // MARK: - Photo Library Permission
    func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let requiredAccessLevel: PHAccessLevel = .readWrite // Or .addOnly if just saving new photos
        PHPhotoLibrary.requestAuthorization(for: requiredAccessLevel) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited: // Limited access still allows selection via picker
                    print("DEBUG: Photo Library permission authorized or limited.")
                    completion(true)
                case .denied, .restricted:
                    print("DEBUG: Photo Library permission denied or restricted.")
                    completion(false)
                case .notDetermined:
                    print("DEBUG: Photo Library permission not determined (should have prompted).")
                    completion(false) // Should ideally not happen if prompt was shown
                @unknown default:
                    print("WARN: Unknown Photo Library authorization status.")
                    completion(false)
                }
            }
        }
    }
} 