//
//  ContentView.swift
//  PhotoBooth
//

import SwiftUI

struct ContentView: View {
    @StateObject private var camera = CameraManager()

    @State private var shots: [UIImage] = []
    @State private var countdown: Int?
    @State private var isRunningSequence = false
    @State private var finalStrip: UIImage?
    @State private var selectedFilter: PhotoFilter = .none
    @State private var saveMessage: String?

    private let shotsPerStrip = 4

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if camera.permissionGranted {
                CameraPreview(session: camera.session)
                    .ignoresSafeArea()

                VStack {
                    topBar
                    Spacer()
                    if isRunningSequence {
                        Text("Shot \(min(shots.count + 1, shotsPerStrip)) of \(shotsPerStrip)")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                    }
                    captureBar
                }

                if let countdown {
                    Text("\(countdown)")
                        .font(.system(size: 120, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            } else {
                permissionPrompt
            }
        }
        .animation(.easeInOut(duration: 0.2), value: countdown)
        .sheet(isPresented: Binding(
            get: { finalStrip != nil },
            set: { isPresented in
                if !isPresented {
                    finalStrip = nil
                    shots = []
                }
            }
        )) {
            if let finalStrip {
                PhotoStripReviewView(
                    strip: finalStrip,
                    selectedFilter: $selectedFilter,
                    onFilterChange: { recomposeStrip() },
                    onRetake: {
                        self.finalStrip = nil
                        shots = []
                    },
                    onSave: { saveCurrentStrip() }
                )
            }
        }
        .alert("Camera Error", isPresented: .constant(camera.errorMessage != nil)) {
            Button("OK") { camera.errorMessage = nil }
        } message: {
            Text(camera.errorMessage ?? "")
        }
        .alert("PhotoBooth", isPresented: Binding(
            get: { saveMessage != nil },
            set: { if !$0 { saveMessage = nil } }
        )) {
            Button("OK") { saveMessage = nil }
        } message: {
            Text(saveMessage ?? "")
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
            .disabled(isRunningSequence)
        }
        .padding()
        .background(.black.opacity(0.3))
    }

    private var captureBar: some View {
        HStack {
            Spacer()
            Button {
                Task { await runPhotoBoothSequence() }
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(.white, lineWidth: 4)
                        .frame(width: 78, height: 78)
                    Circle()
                        .fill(isRunningSequence ? Color.gray : Color.white)
                        .frame(width: 66, height: 66)
                }
            }
            .disabled(isRunningSequence)
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

    @MainActor
    private func runPhotoBoothSequence() async {
        isRunningSequence = true
        shots = []
        selectedFilter = .none

        for _ in 0..<shotsPerStrip {
            for tick in stride(from: 3, through: 1, by: -1) {
                countdown = tick
                try? await Task.sleep(nanoseconds: 800_000_000)
            }
            countdown = nil

            if let image = await camera.capturePhoto() {
                shots.append(image)
            }

            try? await Task.sleep(nanoseconds: 400_000_000)
        }

        isRunningSequence = false
        recomposeStrip()
    }

    private func recomposeStrip() {
        finalStrip = PhotoStripComposer.compose(images: shots, filter: selectedFilter)
    }

    private func saveCurrentStrip() {
        guard let finalStrip else { return }
        PhotoLibrarySaver.save(finalStrip) { success, error in
            saveMessage = success ? "Saved to your Photos library!" : (error ?? "Couldn't save the photo.")
        }
    }
}

struct PhotoStripReviewView: View {
    let strip: UIImage
    @Binding var selectedFilter: PhotoFilter
    let onFilterChange: () -> Void
    let onRetake: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                Image(uiImage: strip)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }

            Picker("Filter", selection: $selectedFilter) {
                ForEach(PhotoFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: selectedFilter) { _, _ in
                onFilterChange()
            }

            HStack(spacing: 16) {
                Button("Retake", role: .cancel, action: onRetake)
                    .buttonStyle(.bordered)

                Button("Save to Photos", action: onSave)
                    .buttonStyle(.borderedProminent)

                ShareLink(
                    item: Image(uiImage: strip),
                    preview: SharePreview("PhotoBooth strip", image: Image(uiImage: strip))
                )
                .buttonStyle(.bordered)
            }
            .padding(.bottom)
        }
    }
}

#Preview {
    ContentView()
}
