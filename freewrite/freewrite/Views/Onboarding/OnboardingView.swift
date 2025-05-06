import SwiftUI

// Removed the old OnboardingScreenData struct
// Removed onboardingPages data

struct OnboardingView: View {
    // Inject the ContentViewModel
    @EnvironmentObject var viewModel: ContentViewModel // Keep ViewModel if needed later, maybe not?

    // AppStorage flag to track completion
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    // Binding to control the splash screen visibility in the parent view
    @Binding var showSplash: Bool

    // State to track which part of the onboarding is shown - REMOVED
    // @State private var showingCardSelection: Bool

    // Initializer to accept the initial state for showing cards - REMOVED
    // init(showSplash: Binding<Bool>, startWithCards: Bool = false) { ... }
    // Simplified initializer
    init(showSplash: Binding<Bool>) {
        self._showSplash = showSplash // Use underscore prefix for @Binding
    }

    var body: some View {
        ZStack {
            // Use a primary brand background
            BrandColors.cream // Or another pastel like mintGreen?
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Replace placeholder with actual mascot image
                Image("Raccoon_Onboarding") // CORRECTED Filename
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150) // Adjust frame as needed
                    // .foregroundColor(BrandColors.darkBrown.opacity(0.5)) // Remove foreground color if image has color
                    .padding(.bottom, 20)

                Text("Dumpster Note")
                    .font(Font.custom("Georgia-Bold", size: 34))
                    .foregroundColor(BrandColors.darkBrown) // Use dark brown for main title

                Text("Empty your mind → Get instant insights → Feel lighter.")
                    .font(.system(size: 18, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(BrandColors.secondaryText(for: .light)) // Use secondary text color
                    .padding(.horizontal, 40)
                    .lineSpacing(5)

                Spacer()

                // Start Dumping Button - Use accent color?
                Button {
                    // Action: Complete onboarding & hide splash
                    print("Onboarding complete. Starting app.")
                    hasCompletedOnboarding = true
                    showSplash = false // Immediately transition to ContentView
                } label: {
                    Text("Start Dumping")
                        .font(.headline)
                        .fontWeight(.semibold)
                        // Use primary text color on accent background
                        .foregroundColor(BrandColors.primaryText(for: .light)) 
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity)
                        .background(BrandColors.accentPink) // Use accent color for button
                        .cornerRadius(25)
                        // Remove overlay or use a subtle dark border?
                        // .overlay(
                        //     RoundedRectangle(cornerRadius: 25)
                        //         .stroke(BrandColors.darkBrown.opacity(0.5), lineWidth: 1)
                        // )
                }
                .padding(.horizontal, 50) 

                Spacer()
            }
            .padding(.bottom, 30) 
        }
    }
}

#Preview {
    // Provide a constant binding for the preview
    OnboardingView(showSplash: .constant(true))
        .environmentObject(ContentViewModel()) // Provide ViewModel if needed for preview
} 