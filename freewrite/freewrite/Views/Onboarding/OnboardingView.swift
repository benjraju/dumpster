import SwiftUI

// Data structure for each onboarding screen
struct OnboardingPage: Identifiable {
    let id = UUID()
    var imageName: String? = nil // Optional image for the page
    let title: String
    let subtitle: String
    let detailPoints: [String]? // For bullet points or detailed explanations
    let isLastPage: Bool // To show the final button
    let showOnlyButton: Bool // New flag for the very last page
    let isFirstPage: Bool // To show the swipe arrow

    // Example of how you might use a custom illustration per page
    static let pages: [OnboardingPage] = [
        OnboardingPage( // Page 0
            imageName: "Raccoon_Onboarding", // Existing welcome Raccoon
            title: "Hey, welcome to your dumpster! 👋",
            subtitle: "This is your freewrite zone. Type it, don't tidy it. Let Scribbles the raccoon sort the note later.",
            detailPoints: nil,
            isLastPage: false,
            showOnlyButton: false,
            isFirstPage: true
        ),
        OnboardingPage( // Page 1
            imageName: "Raccoon_Thinking", // Placeholder
            title: "Why even bother dumping? 🤔",
            subtitle: "Unlock these cool perks:",
            detailPoints: [
                "🧠 Instant Mental Declutter: Empty your mind's cache.",
                "✨ Idea-Spark Machine: Discover new ideas and epiphanies.",
                "😌 Feelings Dump: Calm the chaos and find more chill."
            ],
            isLastPage: false,
            showOnlyButton: false,
            isFirstPage: false
        ),
        OnboardingPage( // Page 2 (was Page 4)
            imageName: "Raccoon_Entry_Toss", // Placeholder - needs a "features" raccoon
            title: "Unlock Your Dumpster's Potential ✨",
            subtitle: "A few of Scribbles' special tools:",
            detailPoints: [
                "🤔 **Dumpster Dive:** Stuck? Tap 'Dumpster Dive' while writing for a nudge.",
                "📸 **Snapshots:** Add a photo to your mood check-in.",
                "🎨 **Customize:** Change themes & fonts in 'Display'.",
                "📚 **History:** Revisit past dumps & insights."
            ],
            isLastPage: false,
            showOnlyButton: false,
            isFirstPage: false
        ),
        OnboardingPage( // Page 3 (was Page 5) - Final page
            imageName: "Raccoon_Happy", // Placeholder - an encouraging raccoon
            title: "Ready to Lighten Your Load?",
            subtitle: "Your dumpster awaits!",
            detailPoints: nil,
            isLastPage: true, // This is the actual last page with the button
            showOnlyButton: true,
            isFirstPage: false
        )
    ]
}

struct OnboardingView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @Binding var showSplash: Bool

    @State private var currentPageIndex = 0 // To track current page in TabView

    init(showSplash: Binding<Bool>) {
        self._showSplash = showSplash
    }

    var body: some View {
        TabView(selection: $currentPageIndex) {
            ForEach(Array(OnboardingPage.pages.enumerated()), id: \.offset) { item in
                OnboardingPageView(page: item.element, currentPageIndex: $currentPageIndex, pageCount: OnboardingPage.pages.count, showSplash: $showSplash, hasCompletedOnboarding: $hasCompletedOnboarding)
                    .tag(item.offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .background(BrandColors.cream.ignoresSafeArea())
        .animation(.easeInOut, value: currentPageIndex)
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @Binding var currentPageIndex: Int
    let pageCount: Int
    @Binding var showSplash: Bool
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            if page.showOnlyButton {
                if let imageName = page.imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 180)
                        .padding(.bottom, 20)
                }
                Text(page.title)
                    .font(Font.custom("Georgia-Bold", size: 30))
                    .foregroundColor(BrandColors.defaultDarkBrown)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Text(page.subtitle)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(BrandColors.secondaryText(for: "light"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 35)
                    .lineSpacing(4)
                    .padding(.bottom, 30)
            } else {
                if let imageName = page.imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 130)
                        .padding(.bottom, 15)
                } else {
                    Image("Raccoon_Thinking")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 110)
                        .padding(.bottom, 15)
                }

                Text(page.title)
                    .font(Font.custom("Georgia-Bold", size: 26))
                    .foregroundColor(BrandColors.defaultDarkBrown)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text(page.subtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(BrandColors.secondaryText(for: "light"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .lineSpacing(4)
                    .padding(.bottom, 10)

                if let details = page.detailPoints, !details.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(details, id: \.self) { pointString in
                            HStack(alignment: .top, spacing: 5) {
                                Text("•")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(BrandColors.defaultDarkBrown.opacity(0.9))
                                Text(LocalizedStringKey(pointString))
                                    .font(.system(size: 16))
                                    .foregroundColor(BrandColors.defaultDarkBrown.opacity(0.9))
                                    .lineSpacing(4)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 35)
                    .padding(.top, 5)
                }
            }

            Spacer()

            // Logic for button or swipe hint
            if page.isLastPage {
                Button {
                    print("Onboarding complete. Starting app.")
                    hasCompletedOnboarding = true
                    showSplash = false
                } label: {
                    Text("Start Dumping!")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(BrandColors.primaryText(for: "light"))
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity)
                        .background(BrandColors.accentPink)
                        .cornerRadius(25)
                }
                .padding(.horizontal, 50)
                 Spacer().frame(height: 20) // Space below button before page dots if last page
            } else if page.isFirstPage {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title)
                    .foregroundColor(BrandColors.defaultDarkBrown.opacity(0.5))
                    .padding(.bottom, 10) // Adjust padding as needed
                Spacer().frame(height: 60) // Keep space consistent with button area + bottom padding
            } else {
                Spacer().frame(height: 70 + 10) // Approx button height + potential arrow padding
            }
        }
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OnboardingView(showSplash: .constant(true))
        .environmentObject(ContentViewModel())
} 