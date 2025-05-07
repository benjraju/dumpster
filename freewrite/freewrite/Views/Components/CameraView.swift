import SwiftUI
import AVFoundation

// UIViewRepresentable for Camera Preview
struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraService: CameraService

    func makeUIView(context: Context) -> UIView {
        let uiView = UIView(frame: UIScreen.main.bounds)
        
        // Create and configure the preview layer via the coordinator
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraService.session) // Assign session immediately
        previewLayer.frame = uiView.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        uiView.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer // Store in coordinator
        
        print("CameraPreviewView: makeUIView - Preview layer created and added. Frame: \(previewLayer.frame)")
        print("CameraPreviewView: makeUIView - Session assigned: \(cameraService.session)")
        print("CameraPreviewView: makeUIView - Session inputs: \(cameraService.session.inputs)")
        return uiView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let previewLayer = context.coordinator.previewLayer else {
            print("CameraPreviewView: updateUIView - Coordinator previewLayer is nil")
            return
        }
        
        print("CameraPreviewView: updateUIView - UIView bounds: \(uiView.bounds)")
        print("CameraPreviewView: updateUIView - PreviewLayer frame BEFORE update: \(previewLayer.frame)")
        print("CameraPreviewView: updateUIView - CameraService session isRunning: \(cameraService.session.isRunning)")
        print("CameraPreviewView: updateUIView - CameraService session inputs: \(cameraService.session.inputs.count)")

        // Ensure the session is still correctly assigned
        if previewLayer.session != cameraService.session {
            print("CameraPreviewView: updateUIView - Re-assigning session to previewLayer.")
            previewLayer.session = cameraService.session
        }
        
        // Update the frame of the preview layer ONLY if the uiView's bounds are non-zero
        if uiView.bounds != .zero {
            previewLayer.frame = uiView.bounds
            print("CameraPreviewView: updateUIView - PreviewLayer frame AFTER update (non-zero UIView bounds): \(previewLayer.frame)")
        } else {
            print("CameraPreviewView: updateUIView - UIView bounds are ZERO. SKIPPING previewLayer frame update. Current layer frame: \(previewLayer.frame)")
        }

        // Defensive check: Ensure layer is still part of the view hierarchy
        if previewLayer.superlayer == nil && uiView.window != nil { // Only re-add if view is in a window
            print("CameraPreviewView: updateUIView - PreviewLayer was detached. Re-adding.")
            uiView.layer.addSublayer(previewLayer)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: CameraPreviewView
        var previewLayer: AVCaptureVideoPreviewLayer?

        init(_ parent: CameraPreviewView) {
            self.parent = parent
            super.init()
        }
    }
}

struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    var onImageCaptured: (Data?) -> Void
    
    @StateObject private var cameraService = CameraService() // Instantiated CameraService

    var body: some View {
        ZStack {
            // Camera Preview
            if cameraService.isCameraAuthorized { // Only show preview if authorized
                CameraPreviewView(cameraService: cameraService)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            } else {
                // Placeholder or message if camera is not authorized
                VStack {
                    Text("Camera access is required to take photos.")
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Open Settings") { // TODO: Implement open settings functionality
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.ignoresSafeArea())
            }
            
            VStack {
                // Top bar for cancel and flip camera buttons
                HStack {
                    Button {
                        cameraService.flipCamera()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.title)
                            .padding()
                            .foregroundColor(.white)
                    }
                    .padding(.leading)
                    
                    Spacer()
                    
                    Button("Cancel") {
                        onImageCaptured(nil) 
                        dismiss()
                    }
                    .padding()
                    .foregroundColor(.white)
                }
                .padding(.top, 20) // Adjust top padding as needed
                
                Spacer() 
                
                // Capture Button
                Button(action: {
                    cameraService.capturePhoto()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                    }
                }
                .disabled(!cameraService.isCameraAuthorized) // Disable if not authorized
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            // Dispatch to allow the view hierarchy to settle before starting the session
            DispatchQueue.main.async {
                if !cameraService.isCameraAuthorized {
                    // Permissions might have been denied before this view appeared
                    // The CameraService init already tries to check/request.
                    // If still not authorized, the view shows the message.
                    // Consider re-triggering permission check if appropriate or guide to settings
                }
                // Session start is handled by CameraService's setup or a manual start if needed
                // For now, let's ensure it's started if authorized and not already running
                if cameraService.isCameraAuthorized && !cameraService.session.isRunning {
                     cameraService.startSession() // Explicitly start if needed
                }
            }
        }
        .onDisappear {
            cameraService.stopSession()
        }
        .onChange(of: cameraService.capturedPhotoData) { newData in
            if let data = newData {
                onImageCaptured(data)
                dismiss()
            }
        }
    }
}

// Preview 
#if DEBUG
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(onImageCaptured: { data in
            // Simplified print statement to avoid complex interpolation issues
            print("Preview: Image captured. Data is nil: \(data == nil). Byte count if not nil: \(data?.count ?? 0)")
        })
    }
}
#endif 