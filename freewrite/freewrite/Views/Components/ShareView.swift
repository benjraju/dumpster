import SwiftUI

struct ShareView: View {
    // Data needed for the template
    let insightText: String
    let mood: Mood?
    let entryDate: String // Display date like "May 4"
    
    // TODO: Add template selection state later
    
    var body: some View {
        // Template 1: Simple Text on Gradient
        template1
            // Force a specific aspect ratio (e.g., 9:16 for stories)
            // The actual size will depend on the rendering context.
            .aspectRatio(9 / 16, contentMode: .fit)
            // Add a border or background for previewing the bounds
            .border(Color.gray)
    }
    
    // Template 1 Design
    private var template1: some View {
        ZStack(alignment: .center) {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [BrandColors.accentPink.opacity(0.7), BrandColors.mintGreen.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 20) {
                // Optional: Mood Icon
                if let mood = mood {
                    Text(mood.icon)
                        .font(.system(size: 60))
                        .padding(.top, 50)
                }
                
                // Insight Text
                Text(insightText)
                    .font(.title2) // Adjust font
                    .foregroundColor(BrandColors.primaryText(for: .light))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .minimumScaleFactor(0.5) // Allow text to shrink
                
                Spacer()
                
                // Footer: Date & App Name
                HStack {
                    Text(entryDate)
                    Spacer()
                    Text("Dumpster Note") // Or add logo image
                }
                .font(.caption)
                .foregroundColor(BrandColors.secondaryText(for: .light).opacity(0.8))
                .padding(.horizontal, 25)
                .padding(.bottom, 30)
            }
        }
    }
    
    // TODO: Add Template 2 later
}

#Preview {
    ShareView(
        insightText: "It sounds like you're excited about the new project but also a bit nervous about the deadline. Remember to break it down!",
        mood: .explore,
        entryDate: "May 4"
    )
    .frame(width: 300) // Scale down for preview
} 