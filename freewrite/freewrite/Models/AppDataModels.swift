import Foundation

// MARK: - Entry Model
struct HumanEntry: Identifiable, Equatable {
    let id: UUID
    let date: String // Display date (e.g., "May 4")
    let filename: String
    var previewText: String
    let mood: Mood
    var isFavorite: Bool = false
    let actualDate: Date // Precise date for logic
    
    // Conformance to Equatable based on ID
    static func == (lhs: HumanEntry, rhs: HumanEntry) -> Bool {
        lhs.id == rhs.id
    }
    
    // Static factory method might belong here or in a dedicated manager later
    static func createNew(mood: Mood) -> HumanEntry {
        let id = UUID()
        let now = Date() // Get the current date and time
        let dateFormatter = DateFormatter()
        
        // For filename string
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let dateString = dateFormatter.string(from: now)
        
        // For display string
        dateFormatter.dateFormat = "MMM d"
        let displayDate = dateFormatter.string(from: now)
        
        // Filename now includes mood initial
        let moodInitial: String
        switch mood {
        case .vent: moodInitial = "V"
        case .explore: moodInitial = "E"
        case .plan: moodInitial = "P"
        }
        let filename = "[\(id)]-[\(dateString)]-[\(moodInitial)].md"
        
        return HumanEntry(
            id: id,
            date: displayDate, // Store display date string
            filename: filename,
            previewText: "", // Start with empty preview
            mood: mood, // Store the passed-in mood
            isFavorite: false, // Default favorite to false
            actualDate: now // Store the actual Date object
        )
    }
}

// MARK: - AI Response Models
struct MarkdownSection: Identifiable, Codable {
    let id = UUID()
    let title: String? 
    let content: String

    // Explicitly define coding keys to exclude 'id' from JSON
    enum CodingKeys: String, CodingKey {
        case title
        case content
    }
    
    // No custom init(from:) or encode(to:) needed if we just exclude keys
}

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    var max_tokens: Int? // ADDED: Optional max_tokens parameter
}

struct OpenAIMessage: Codable {
    let role: String 
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage? 
    let error: OpenAIError? 
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
    let finish_reason: String?
}

struct OpenAIUsage: Codable {
    let prompt_tokens: Int?
    let completion_tokens: Int?
    let total_tokens: Int?
}

struct OpenAIError: Codable {
    let message: String
    let type: String?
    let param: String?
    let code: String?
}

// MARK: - Other Models (if any)
// E.g., HeartEmoji if it's still used
/*
struct HeartEmoji: Identifiable {
    let id = UUID()
    var position: CGPoint
    var offset: CGFloat = 0
}
*/

// MARK: - Sheet Identifier Enum
enum ActiveSheet: Identifiable {
    case font, history, aiResponse, tutorial, newEntryPrompt, moodSelection
    // case timer // REMOVED
    // case durationPrompt // REMOVED
    // case timerFinishedPrompt // REMOVED
    // Add cases for any other sheets you might add later
    
    var id: Int { // Simple identifiable conformance
        hashValue
    }
}

// MARK: - Mood Enum
enum Mood: String, CaseIterable, Identifiable {
    case vent = "Vent"
    case explore = "Explore"
    case plan = "Plan"

    var id: String { self.rawValue }

    // Optional: Add associated details
    var description: String {
        switch self {
        case .vent: return "Just need to let it all out."
        case .explore: return "Digging into ideas or creativity."
        case .plan: return "Organizing thoughts, plans, or goals."
        }
    }

    var icon: String {
        switch self {
        case .vent: return "🌀"
        case .explore: return "🌱"
        case .plan: return "��"
        }
    }
}

// MARK: - Mood Tracking

struct MoodEmoji: Identifiable, Hashable { // Added Hashable for potential use in grids/sets
    let id = UUID()
    let emoji: String
    let description: String // e.g., "Happy", "Sad", "Anxious"

    // Static list of predefined moods
    static let allMoods: [MoodEmoji] = [
        MoodEmoji(emoji: "😊", description: "Happy"),
        MoodEmoji(emoji: "😢", description: "Sad"),
        MoodEmoji(emoji: "🤔", description: "Thoughtful"),
        MoodEmoji(emoji: "😠", description: "Angry"),
        MoodEmoji(emoji: "😌", description: "Calm"),
        MoodEmoji(emoji: "😴", description: "Tired"),
        MoodEmoji(emoji: "🥳", description: "Excited"),
        MoodEmoji(emoji: "😅", description: "Anxious"),
        // Add more moods as needed
    ]
} 