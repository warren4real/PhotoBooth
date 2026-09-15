//
//  ContentView.swift
//  PhotoBooth
//

import SwiftUI

struct ContentView: View {
    @StateObject private var camera = CameraManager()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if camera.permissionGranted {
                CameraPreview(session: camera.session)
                    .ignoresSafeArea()

                VStack {
                    topBar
                    Spacer()
                    captureBar
                }
            } else {
                permissionPrompt
            }
        }
        .sheet(isPresented: Binding(
            get: { camera.capturedImage != nil },
            set: { isPresented in
                if !isPresented { camera.capturedImage = nil }
            }
        )) {
            if let image = camera.capturedImage {
                PhotoReviewView(image: image) {
                    camera.capturedImage = nil
                }
            }
        }
        .alert("Camera Error", isPresented: .constant(camera.errorMessage != nil)) {
            Button("OK") { camera.errorMessage = nil }
        } message: {
            Text(camera.errorMessage ?? "")
        }
    }

    private var topBar: some View {
        HStack {
            Text("PhotoBooth")
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            Button {
                camera.switchCamera()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .background(.black.opacity(0.3))
    }

    private var captureBar: some View {
        HStack {
            Spacer()
            Button {
                camera.capturePhoto()
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(.white, lineWidth: 4)
                        .frame(width: 78, height: 78)
                    Circle()
                        .fill(.white)
                        .frame(width: 66, height: 66)
                }
            }
            Spacer()
        }
        .padding(.bottom, 40)
    }

    private var permissionPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white)
            Text(camera.errorMessage ?? "PhotoBooth needs camera access to take photos.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct PhotoReviewView: View {
    let image: UIImage
    let onRetake: () -> Void

    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding()

            HStack(spacing: 24) {
                Button("Retake", role: .cancel, action: onRetake)
                    .buttonStyle(.bordered)

                ShareLink(
                    item: Image(uiImage: image),
                    preview: SharePreview("PhotoBooth photo", image: Image(uiImage: image))
                )
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
