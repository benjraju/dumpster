import SwiftUI

struct WelcomeSplashView: View {
    
    // Format the date
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d" // e.g., April 27
        return formatter.string(from: Date())
    }
    
    // Use the yellow background color from the onboarding asset
    private let yellowBackground = Color(red: 1.0, green: 0.9, blue: 0.6)

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Welcome back!")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(BrandColors.darkBrown.opacity(0.8))
            
            Text(currentDateString)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(BrandColors.darkBrown.opacity(0.6))
                .padding(.bottom, 30)
                
            Image("OnboardingTypewriter") // Reuse the typewriter image
                .resizable()
                .scaledToFit()
                .frame(height: UIScreen.main.bounds.height * 0.25) 
                .padding(.bottom, 20)

            Text("LET IT ALL OUT.")
                .font(Font.custom("Georgia-Bold", size: 34))
                .multilineTextAlignment(.center)
                .foregroundColor(BrandColors.darkBrown)

            Text("Dump your thoughts safely and freely.")
                .font(.system(size: 18, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundColor(BrandColors.darkBrown.opacity(0.8))
                .padding(.horizontal)
                .lineSpacing(4)
                
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(yellowBackground.ignoresSafeArea())
    }
}

#Preview {
    WelcomeSplashView()
} 