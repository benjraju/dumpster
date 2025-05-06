import SwiftUI
import UIKit // Need UIKit for UIHostingController and UIGraphicsImageRenderer

// RENAMED Helper function to render a SwiftUI view to a UIImage
@MainActor // Ensure UI operations happen on the main thread
func renderViewToImage<Content: View>(view: Content, targetSize: CGSize? = nil) -> UIImage? {
    // Create a hosting controller for the SwiftUI view
    let controller = UIHostingController(rootView: view)
    
    // Determine the size needed for rendering
    let desiredSize = targetSize ?? controller.view.intrinsicContentSize
    
    // Make sure size is valid
    guard desiredSize.width > 0, desiredSize.height > 0 else {
        print("WARN: Invalid snapshot size (\(desiredSize)). Using intrinsic size.")
        // Fallback to intrinsic size if targetSize was invalid
        let fallbackSize = controller.view.intrinsicContentSize
        guard fallbackSize.width > 0, fallbackSize.height > 0 else {
             print("ERROR: Cannot snapshot view with zero intrinsic size.")
             return nil
        }
        controller.view.bounds = CGRect(origin: .zero, size: fallbackSize)
        controller.view.backgroundColor = .clear // Ensure transparency if needed
        controller.view.layoutIfNeeded() // Allow layout pass
        return nil
    }
    
    // Ensure the view has the correct bounds before snapshotting
    controller.view.bounds = CGRect(origin: .zero, size: desiredSize)
    controller.view.backgroundColor = .clear // Ensure transparency
    controller.view.layoutIfNeeded() // Allow layout pass

    // Use UIGraphicsImageRenderer for high-quality rendering
    let renderer = UIGraphicsImageRenderer(size: desiredSize)
    
    let image = renderer.image { _ in
        controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
    }
    
    print("DEBUG: Snapshot created with size \(image.size).")
    return image
}

// Extension on View for easier snapshotting (optional but convenient)
extension View {
    @MainActor
    func snapshot(targetSize: CGSize? = nil) -> UIImage? {
        // Wrap the view in a container that respects safe areas if needed,
        // or ensure the view itself defines its layout clearly.
        // For story-like views, forcing the frame/aspectRatio is often enough.
        
        // Important: Apply fixed frame *before* snapshotting if using targetSize
        let viewToSnapshot = self
            .frame(width: targetSize?.width, height: targetSize?.height)
        
        // Call the RENAMED global function
        return freewriteOS.renderViewToImage(view: viewToSnapshot, targetSize: targetSize)
    }
} 