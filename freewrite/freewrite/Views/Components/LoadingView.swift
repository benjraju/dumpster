import SwiftUI

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false // State to control animation

    var body: some View {
        VStack(spacing: 15) {
            // Replace placeholder with actual thinking raccoon
            Image("Raccoon_Thinking") // CORRECTED Filename
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180) // Keep original size or adjust
            Text("Thinking...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(30)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 15))
        .transition(.opacity.combined(with: .scale))
    }
} 