//
//  CameraManager.swift
//  PhotoBooth
//

import AVFoundation
import Combine
import UIKit

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isSessionRunning = false
    @Published var permissionGranted = false
    @Published var errorMessage: String?

    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.photobooth.sessionQueue")
    private(set) var currentCameraPosition: AVCaptureDevice.Position = .front
    private var captureCompletion: ((UIImage?) -> Void)?

    override init() {
        super.init()
        checkPermissions()
    }

    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted {
                        self?.configureSession()
                    }
                }
            }
        default:
            permissionGranted = false
            errorMessage = "Camera access is disabled. Enable it in Settings to use PhotoBooth."
        }
    }

    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            self.session.inputs.forEach { self.session.removeInput($0) }

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.currentCameraPosition),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Unable to access the camera."
                }
                self.session.commitConfiguration()
                return
            }

            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            if self.session.outputs.isEmpty, self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }

            self.session.commitConfiguration()
            if !self.session.isRunning {
                self.session.startRunning()
            }

            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }

    func switchCamera() {
        currentCameraPosition = currentCameraPosition == .front ? .back : .front
        configureSession()
    }

    /// Captures a single photo and suspends until the image is ready.
    /// Used in sequence by the photo-booth countdown flow to build a multi-shot strip.
    func capturePhoto() async -> UIImage? {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(returning: nil)
                    return
                }

                // Front camera preview is mirrored for a natural selfie view,
                // but captured files aren't mirrored by default — match them so
                // the saved strip looks like what the user actually saw.
                if let connection = self.photoOutput.connection(with: .video),
                   connection.isVideoMirroringSupported {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = (self.currentCameraPosition == .front)
                }

                self.captureCompletion = { image in
                    continuation.resume(returning: image)
                }

                let settings = AVCapturePhotoSettings()
                settings.flashMode = .off
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    /// Restarts a previously-stopped session, e.g. after the app returns from the background.
    func resumeSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
            }
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            DispatchQueue.main.async {
                self.errorMessage = error?.localizedDescription ?? "Failed to capture photo."
                self.captureCompletion?(nil)
                self.captureCompletion = nil
            }
            return
        }

        DispatchQueue.main.async {
            self.captureCompletion?(image)
            self.captureCompletion = nil
        }
    }
}
