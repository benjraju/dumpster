import SwiftUI

struct ShareView: View {
    // Data needed for the template
    let title: String? // Optional title for the content
    let contentText: String // Renamed from insightText for clarity
    let mood: Mood?
    let entryDate: String // Display date like "May 4"
    let snapshotImage: UIImage? // New parameter for the user's image
    
    private let cardBackgroundColor = BrandColors.background(for: "light") // e.g., cream
    private let overallBackgroundColor = BrandColors.secondaryBackground(for: "light").opacity(0.3) // Even more subtle outer bg
    private let textColor = BrandColors.primaryText(for: "light")
    private let secondaryTextColor = BrandColors.secondaryText(for: "light")

    var body: some View {
        ZStack {
            overallBackgroundColor
                .ignoresSafeArea()

            // Conditional layout for Poem with image vs. Standard card
            if title == "Poetic Reflection" && snapshotImage != nil {
                poemCardView
            } else {
                standardCardView
            }
        }
        .aspectRatio(9 / 16, contentMode: .fit)
    }

    // Standard content card (for insights, etc.)
    private var standardCardView: some View {
        VStack(spacing: 0) {
            if let mood = mood {
                Text(mood.icon)
                    .font(.system(size: 40))
                    .padding(.top, 25)
                    .padding(.bottom, 10)
            }
            
            if let title = title, !title.isEmpty {
                Text(title)
                    .font(Font.custom("Georgia-Bold", size: 24))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, title.isEmpty ? 0 : 8)
            }

            Text(contentText)
                .font(Font.custom("Lato-Regular", size: 18))
                .foregroundColor(textColor.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 25)
                .minimumScaleFactor(0.6)
                .padding(.bottom, 20)

            Spacer()
            
            HStack {
                Text(entryDate)
                Spacer()
                Text("Dumpster Note")
            }
            .font(.caption)
            .foregroundColor(secondaryTextColor.opacity(0.8))
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 50)
        .background(cardBackgroundColor)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(BrandColors.lightBrown.opacity(0.4), lineWidth: 1)
        )
    }

    // Card view specifically for poems with a background image
    private var poemCardView: some View {
        ZStack {
            if let uiImage = snapshotImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            }

            Color.black.opacity(0.40)

            VStack {
                Spacer(minLength: UIScreen.main.bounds.height * 0.1)
                Text(contentText) 
                    .font(Font.custom("Georgia-Bold", size: 22))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 25)
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 1, y: 1)
                
                Spacer()
                
                HStack {
                    Text(entryDate)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("Dumpster Note")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .padding(.vertical, 10)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 40)
        .background(Color.gray)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .clipped()
    }
}

// Preview for standard card
#Preview("Standard Insight Card") {
    ShareView(
        title: "An Insight",
        contentText: "This is a standard insight card without an image background, focusing on the text.",
        mood: .explore,
        entryDate: "May 7",
        snapshotImage: nil
    )
    .frame(width: 300, height: (300.0 * 16.0 / 9.0))
}

// Preview for Poem Card
#Preview("Poem Card with Image") {
    let placeholderImage = UIImage(systemName: "photo.artframe") ?? UIImage()
    ShareView(
        title: "Poetic Reflection",
        contentText: "In a dance of data,\nVisions unfold, whispering,\nImpressions of light.",
        mood: nil, 
        entryDate: "May 8",
        snapshotImage: placeholderImage
    )
    .frame(width: 300, height: (300.0 * 16.0 / 9.0))
} 