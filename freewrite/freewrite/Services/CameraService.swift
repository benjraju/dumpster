import AVFoundation
import SwiftUI
import os.log

class CameraService: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var session = AVCaptureSession()
    @Published var photoOutput = AVCapturePhotoOutput()
    @Published var isCameraAuthorized: Bool = false // Reflects permission status
    @Published var capturedPhotoData: Data? = nil
    
    private var backCamera: AVCaptureDevice? = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    private var frontCamera: AVCaptureDevice? = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    @Published var currentCamera: AVCaptureDevice? // To allow flipping

    // Logger for better debugging
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "CameraService")

    override init() {
        super.init()
        self.currentCamera = backCamera // Default to back camera
        checkPermissionsAndSetup()
    }

    private func checkPermissionsAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isCameraAuthorized = granted
                    if granted {
                        self?.setupSession()
                    } else {
                        self?.logger.error("Camera access denied by user.")
                    }
                }
            }
        default:
            isCameraAuthorized = false
            logger.warning("Camera access is not authorized (denied or restricted).")
        }
    }

    func setupSession() {
        guard isCameraAuthorized, let camera = currentCamera else {
            logger.error("Cannot setup session: Camera not authorized or not available.")
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset = .photo // Set appropriate preset

        // Remove existing inputs
        session.inputs.forEach { input in
            session.removeInput(input)
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                logger.error("Could not add camera input to session.")
                session.commitConfiguration()
                return
            }

            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            } else {
                logger.error("Could not add photo output to session.")
                session.commitConfiguration()
                return
            }
            
            session.commitConfiguration()
            logger.debug("Camera session setup complete with device: \(camera.localizedName)")

        } catch {
            logger.error("Error setting up camera input: \(error.localizedDescription)")
            session.commitConfiguration() // Ensure configuration is committed even on error
        }
    }

    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.session.isRunning && self.isCameraAuthorized {
                self.session.startRunning()
                self.logger.debug("Camera session started.")
            }
        }
    }

    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.session.isRunning {
                self.session.stopRunning()
                self.logger.debug("Camera session stopped.")
            }
        }
    }

    func capturePhoto() {
        guard session.isRunning else {
            logger.warning("Attempted to capture photo, but session is not running.")
            return
        }
        let settings = AVCapturePhotoSettings()
        // Configure settings as needed (e.g., flash, format)
        photoOutput.capturePhoto(with: settings, delegate: self)
        logger.debug("Photo capture initiated.")
    }
    
    func flipCamera() {
        session.beginConfiguration()
        session.inputs.forEach { input in
            session.removeInput(input)
        }
        
        if currentCamera?.position == .back {
            currentCamera = frontCamera
        } else {
            currentCamera = backCamera
        }
        
        guard let newCamera = currentCamera else {
            logger.error("Failed to get camera for flipping.")
            session.commitConfiguration()
            return
        }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newCamera)
            if session.canAddInput(newInput) {
                session.addInput(newInput)
            } else {
                logger.error("Could not add new camera input after flip.")
            }
        } catch {
            logger.error("Error setting up new camera input after flip: \(error.localizedDescription)")
        }
        session.commitConfiguration()
        logger.debug("Camera flipped to: \(newCamera.localizedName)")
    }

    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            logger.error("Error capturing photo: \(error.localizedDescription)")
            self.capturedPhotoData = nil
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            logger.error("Could not get image data from captured photo.")
            self.capturedPhotoData = nil
            return
        }
        
        DispatchQueue.main.async {
            self.capturedPhotoData = imageData
            self.logger.debug("Photo captured successfully, data size: \(imageData.count) bytes.")
        }
    }
} 