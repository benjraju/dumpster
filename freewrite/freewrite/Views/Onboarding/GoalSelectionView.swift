import SwiftUI

struct GoalSelectionView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    @AppStorage("hasCompletedGoalSelection") private var hasCompletedGoalSelection: Bool = false

    let goals = UserGoal.allCases

    // Define onboarding-specific colors, ignoring system theme for this view
    private let onboardingBackgroundColor = BrandColors.cream
    private let onboardingPrimaryTextColor = BrandColors.defaultDarkBrown
    private let onboardingSecondaryTextColor = BrandColors.secondaryText(for: "light") // Explicitly light theme secondary
    private let onboardingAccentColor = BrandColors.accentPink // Or another suitable accent from BrandColors
    private let onboardingButtonBackgroundColor = BrandColors.mintGreen.opacity(0.7) // Or another light, contrasting color

    var body: some View {
        NavigationView {
            VStack(spacing: 25) { // Slightly reduced spacing
                Spacer()

                Image("Raccoon_Planning") 
                    .resizable()
                    .scaledToFit()
                    .frame(height: 110) // Slightly smaller
                    .padding(.bottom, 15)

                Text("What's your intention for this dump?")
                    .font(Font.custom("Georgia-Bold", size: 24))
                    .foregroundColor(onboardingPrimaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text("Picking a focus can help guide your thoughts, but it's okay to just write too!")
                    .font(.system(size: 15))
                    .foregroundColor(onboardingSecondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 35)
                    .lineSpacing(4)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(goals) { goal in
                            Button {
                                print("Goal selected: \(goal.rawValue)")
                                hasCompletedGoalSelection = true
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        if let iconName = goal.iconName {
                                            Image(iconName)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 22, height: 22)
                                                .foregroundColor(onboardingPrimaryTextColor) // Icon color matches primary text
                                        } else {
                                            Image(systemName: "pencil.circle.fill") // Filled icon for better visibility
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 22, height: 22)
                                                .foregroundColor(onboardingPrimaryTextColor)
                                        }
                                        Text(goal.rawValue)
                                            .font(Font.custom("Georgia-Bold", size: 17)) // Bolder title
                                    }
                                    Text(goal.description)
                                        .font(.system(size: 14)) // Slightly smaller description
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(EdgeInsets(top: 12, leading: 15, bottom: 12, trailing: 15))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(onboardingPrimaryTextColor) // Text color for the button
                                .background(onboardingButtonBackgroundColor)
                                .cornerRadius(12)
                                // .shadow(color: onboardingPrimaryTextColor.opacity(0.1), radius: 3, x: 0, y: 2) // Optional subtle shadow
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 25) // Adjusted padding
                    .padding(.top, 10)
                }
                Spacer()
            }
            .padding(.vertical)
            .background(onboardingBackgroundColor.ignoresSafeArea())
            .navigationTitle("Set Your Focus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { // Centered Title
                    Text("Set Your Focus")
                        .font(Font.custom("Georgia-Bold", size: 18))
                        .foregroundColor(onboardingPrimaryTextColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip for Now") {
                        print("Goal selection skipped.")
                        hasCompletedGoalSelection = true
                    }
                    .font(.headline)
                    .foregroundColor(onboardingAccentColor) // Use a distinct accent for skip
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    GoalSelectionView()
        .environmentObject(ContentViewModel())
} 