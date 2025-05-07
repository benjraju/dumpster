import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: ContentViewModel // Needed for dismiss logic if using activeSheet

    var body: some View {
        NavigationView { // Wrap in NavigationView for Title and Done button
            ScrollView {
                VStack(alignment: .leading, spacing: 30) { // Increased main spacing
                    
                    // TODO: Add Header Illustration here
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hey, welcome to your dumpster! 👋") // Added emoji
                            .font(Font.custom("Georgia-Bold", size: 30))
                            .foregroundColor(BrandColors.defaultDarkBrown)

                        Text("This is your freewrite zone. Type it, don't tidy it. Let Scribbles the raccoon sort the note later.")
                            .font(.system(size: 17))
                            .foregroundColor(BrandColors.defaultDarkBrown.opacity(0.9))
                            .lineSpacing(4)
                    }

                    SectionView(title: "Why even bother? 🤔") { // Added emoji + Section helper
                        VStack(alignment: .leading, spacing: 15) {
                            BenefitView(boost: "Instant Mental Declutter 🧠", reason: "Writing non-stop forces working-memory to empty its cache.", win: "Leave with an uncluttered head & a to-do.")
                            BenefitView(boost: "Idea-Spark Machine ✨", reason: "Stream-of-consciousness links random neurons.", win: "New ideas, dreams, epiphanies — they pop up uninvited.")
                            BenefitView(boost: "Feelings Dump 😌", reason: "Writing calms your amygdala.", win: "Fewer 3 a.m. doom-scrolls, more chill.")
                        }
                    }
                    
                    SectionView(title: "The 30-Second Habit Starter 🚦") { // Added emoji + Section helper
                        // TODO: Add Habit Illustration here
                        VStack(alignment: .leading, spacing: 12) { // Slightly increased spacing
                            Text("• Pick a vibe — tap a prompt if you don't know where to start.")
                            Text("• Set a 5-min timer — small on purpose; you can build up to 15 mins.")
                            Text("• Type like your keyboard's on fire — no backspace, no spell-check.")
                            Text("• Hit \"Done\" — then tap 💬 for your AI Mirror that hands back with a helpful insight.")
                            Text("• Come back tomorrow — Dumpster Note pings you; streaks unlock surprise stickers.")
                        }
                        .font(.system(size: 16))
                        .foregroundColor(BrandColors.defaultDarkBrown.opacity(0.9))
                        .lineSpacing(4)
                    }

                    SectionView(title: "Tiny Rules 📝") { // Added emoji + Section helper
                         VStack(alignment: .leading, spacing: 12) { // Slightly increased spacing
                            Text("• No editing!")
                            Text("• Spelling mistakes are OKAY. Don't worry about grammar or if it even makes sense.")
                            Text("• Short pauses = okay but don't stop writing.")
                            Text("• Zero judgment — Scribbles is sworn to secrecy.")
                        }
                        .font(.system(size: 16))
                        .foregroundColor(BrandColors.defaultDarkBrown.opacity(0.9))
                        .lineSpacing(4)
                    }
                    
                    SectionView(title: "Pro-Tip 🚀") { // Added emoji + Section helper
                        Text("Try this for three mornings:\n\"What's the one thing I'm doing today & why does it actually matter?\"\nWrite 15 min straight. No breaks. See if you notice a change.")
                            .font(.system(size: 16))
                            .foregroundColor(BrandColors.defaultDarkBrown.opacity(0.9))
                            .lineSpacing(4)
                            .padding(15)
                            .frame(maxWidth: .infinity, alignment: .leading) // Ensure frame for background
                            .background(BrandColors.cream.opacity(0.6)) // Slightly stronger bg
                            .cornerRadius(10)
                            .overlay( // Add subtle border
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(BrandColors.lightBrown.opacity(0.5), lineWidth: 1)
                            )
                    }

                    SectionView(title: "Bonus Goodies 🎁") { // Added emoji + Section helper
                        VStack(alignment: .leading, spacing: 12) { // Slightly increased spacing
                            Text("• AI Chat (💬): 50+ chars unlock a custom reflection prompt.")
                            Text("• Fonts (Aa): Match your mood — whisper, yell, or typewriter-tap.")
                            Text("• History (🕰️): Swipe left to yeet an entry, long-press to favorite")
                        }
                        .font(.system(size: 16))
                        .foregroundColor(BrandColors.defaultDarkBrown.opacity(0.9))
                        .lineSpacing(4)
                    }
                    
                    // TODO: Add Footer Illustration here
                    Spacer(minLength: 20) // Add some space at the bottom

                }
                .padding() // Add padding around the main VStack
            }
            .navigationTitle("Quick Guide") // Set the title
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss() // Simplify dismissal
                    }
                }
            }
            .background(BrandColors.background(for: "light").ignoresSafeArea())
            .accentColor(BrandColors.defaultDarkBrown)
        }
        // On iOS, NavigationViews in sheets often need this style
        .navigationViewStyle(.stack) 
    }
}

// --- New Section Helper View ---
struct SectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 15) { // Spacing between title and content
            Text(title)
                .font(Font.custom("Georgia-Bold", size: 24))
                .foregroundColor(BrandColors.defaultDarkBrown)
            
            content // Embed the content passed in
        }
        .padding(.top, 10) // Add a little space above each section title
        // Removed Divider() - using spacing and structure instead
    }
}

// Helper View for the Benefits Section
struct BenefitView: View {
    let boost: String
    let reason: String
    let win: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(boost)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(BrandColors.defaultDarkBrown)
            Text("Reason: \(reason)")
                .font(.subheadline)
                .foregroundColor(BrandColors.defaultDarkBrown.opacity(0.8))
            Text("Win: \(win)")
                .font(.subheadline)
                .foregroundColor(BrandColors.defaultDarkBrown.opacity(0.8))
                .padding(.bottom, 5)
        }
    }
}


#Preview {
    TutorialView()
        .environmentObject(ContentViewModel()) // Add ViewModel for Preview
} 
 