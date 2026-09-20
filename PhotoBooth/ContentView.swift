//
//  ContentView.swift
//  PhotoBooth
//
//  Editorial styling inspired by a "Studio Picnic" reference design,
//  now driven by HolidayTheme so the whole app re-skins for PH holidays.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var camera = CameraManager()
    @StateObject private var themeManager = ThemeManager()

    @State private var shots: [UIImage] = []
    @State private var countdown: Int?
    @State private var isRunningSequence = false
    @State private var finalStrip: UIImage?
    @State private var selectedFilter: PhotoFilter = .none
    @State private var saveMessage: String?
    @State private var showThemePicker = false

    private let shotsPerStrip = 4

    private var theme: HolidayTheme { themeManager.current }

    var body: some View {
        ZStack {
            theme.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                themeChip
                Spacer(minLength: 8)
                cameraStage
                controls
                contactSheet
            }
        }
        .animation(.easeInOut(duration: 0.2), value: theme)
        .onAppear { themeManager.refreshIfNeeded() }
        .sheet(isPresented: $showThemePicker) {
            ThemePickerView(themeManager: themeManager)
        }
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
                    theme: theme,
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

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(theme.secondaryAccent)
                .frame(width: 36, height: 36)
                .overlay(
                    Text("PB")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text("POCKET STUDIO")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(theme.ink.opacity(0.55))
                Text("PhotoBooth")
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(theme.ink)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("FRAMES")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(theme.ink.opacity(0.5))
                Text("\(shots.count)/0\(shotsPerStrip)")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundStyle(theme.ink)
            }

            Button {
                camera.switchCamera()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.ink)
            }
            .disabled(isRunningSequence)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var themeChip: some View {
        HStack {
            Button {
                showThemePicker = true
            } label: {
                HStack(spacing: 6) {
                    Text(theme.emoji)
                    Text(theme.name.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(theme.accent)
                .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Camera stage

    private var cameraStage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(theme.ink)

            if camera.permissionGranted {
                CameraPreview(session: camera.session)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                permissionContent
            }

            cropMarksOverlay

            if let countdown {
                Text("\(countdown)")
                    .font(.system(size: 96, weight: .bold, design: .serif))
                    .foregroundStyle(theme.paper)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .padding(.horizontal, 20)
        .shadow(color: .black.opacity(0.18), radius: 18, x: 8, y: 10)
        .animation(.easeInOut(duration: 0.2), value: countdown)
    }

    private var permissionContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 32))
            Text(camera.errorMessage ?? "PhotoBooth needs camera access to take photos.")
                .font(.system(size: 13, weight: .medium))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(theme.accent)
        }
        .foregroundStyle(theme.paper.opacity(0.75))
    }

    private var cropMarksOverlay: some View {
        VStack {
            HStack {
                cropMark(rotation: 0)
                Spacer()
                cropMark(rotation: 90)
            }
            Spacer()
            HStack {
                cropMark(rotation: 270)
                Spacer()
                cropMark(rotation: 180)
            }
        }
        .padding(14)
        .allowsHitTesting(false)
    }

    private func cropMark(rotation: Double) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 16))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 16, y: 0))
        }
        .stroke(theme.paper.opacity(0.7), lineWidth: 2)
        .frame(width: 16, height: 16)
        .rotationEffect(.degrees(rotation))
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 10) {
            if isRunningSequence {
                Text("SHOT \(min(shots.count + 1, shotsPerStrip)) OF \(shotsPerStrip)")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(theme.ink.opacity(0.6))
            }

            ZStack {
                Button {
                    Task { await runPhotoBoothSequence() }
                } label: {
                    ZStack {
                        Circle()
                            .stroke(theme.ink, lineWidth: 3)
                            .frame(width: 78, height: 78)
                        Circle()
                            .fill(isRunningSequence ? theme.ink.opacity(0.25) : theme.accent)
                            .frame(width: 58, height: 58)
                    }
                }
                .disabled(isRunningSequence || !camera.permissionGranted)

                HStack {
                    Button {
                        shots = []
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 15, weight: .semibold))
                            Text("RESET")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1)
                        }
                    }
                    .foregroundStyle(theme.ink.opacity(0.55))
                    .disabled(isRunningSequence || shots.isEmpty)

                    Spacer()
                }
                .padding(.horizontal, 40)
            }
        }
        .padding(.vertical, 18)
    }

    // MARK: - Contact sheet

    private var contactSheet: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CONTACT SHEET")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(theme.ink.opacity(0.5))
                Spacer()
                Text("SESSION SP-\(sessionCode)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(theme.ink.opacity(0.4))
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(shots.enumerated()), id: \.offset) { index, shot in
                        Image(uiImage: shot)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 84, height: 108)
                            .clipped()
                            .overlay(
                                Text("0\(index + 1)")
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(4)
                                    .background(theme.paper)
                                    .foregroundStyle(theme.ink),
                                alignment: .bottomLeading
                            )
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(theme.ink.opacity(0.5), lineWidth: 1))
                    }

                    ForEach(0..<max(0, shotsPerStrip - shots.count), id: \.self) { offset in
                        let index = shots.count + offset
                        RoundedRectangle(cornerRadius: 2)
                            .strokeBorder(theme.ink.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
                            .frame(width: 84, height: 108)
                            .overlay(
                                Text("0\(index + 1)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(theme.ink.opacity(0.3))
                            )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 24)
    }

    private var sessionCode: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMdd"
        return formatter.string(from: Date())
    }

    // MARK: - Capture sequence

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
        finalStrip = PhotoStripComposer.compose(
            images: shots,
            filter: selectedFilter,
            captionText: "\(theme.emoji)  \(theme.stripCaption)",
            captionColor: UIColor(theme.ink),
            backgroundColor: UIColor(theme.paper)
        )
    }

    private func saveCurrentStrip() {
        guard let finalStrip else { return }
        PhotoLibrarySaver.save(finalStrip) { success, error in
            saveMessage = success ? "Saved to your Photos library!" : (error ?? "Couldn't save the photo.")
        }
    }
}

// MARK: - Theme picker

struct ThemePickerView: View {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        themeManager.setAuto()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto").font(.system(size: 15, weight: .bold))
                                Text("Today: \(themeManager.autoDetectedTheme.emoji) \(themeManager.autoDetectedTheme.name)")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if isAutoSelected {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }

                Section("Pick a theme manually") {
                    ForEach(HolidayTheme.all) { theme in
                        Button {
                            themeManager.setManual(theme)
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(theme.accent)
                                    .frame(width: 22, height: 22)
                                    .overlay(Circle().stroke(.black.opacity(0.1), lineWidth: 1))
                                Text("\(theme.emoji) \(theme.name)")
                                    .font(.system(size: 15))
                                Spacer()
                                if isSelected(theme) {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var isAutoSelected: Bool {
        if case .auto = themeManager.mode { return true }
        return false
    }

    private func isSelected(_ theme: HolidayTheme) -> Bool {
        if case .manual(let id) = themeManager.mode, id == theme.id { return true }
        return false
    }
}

// MARK: - Review screen

struct PhotoStripReviewView: View {
    let strip: UIImage
    let theme: HolidayTheme
    @Binding var selectedFilter: PhotoFilter
    let onFilterChange: () -> Void
    let onRetake: () -> Void
    let onSave: () -> Void

    var body: some View {
        ZStack {
            theme.paper.ignoresSafeArea()

            VStack(spacing: 18) {
                Text("\(theme.emoji)  \(theme.stripCaption)")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(theme.ink)
                    .padding(.top, 24)

                ScrollView {
                    Image(uiImage: strip)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 24)
                        .shadow(color: .black.opacity(0.15), radius: 14, x: 6, y: 8)
                }

                Picker("Filter", selection: $selectedFilter) {
                    ForEach(PhotoFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .onChange(of: selectedFilter) { _, _ in
                    onFilterChange()
                }

                HStack(spacing: 14) {
                    Button(action: onRetake) {
                        Text("Retake")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(theme.ink)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(theme.ink.opacity(0.4), lineWidth: 1))
                    }

                    Button(action: onSave) {
                        Text("Save to Photos")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(theme.accent)
                    }

                    ShareLink(
                        item: Image(uiImage: strip),
                        preview: SharePreview("PhotoBooth strip", image: Image(uiImage: strip))
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(theme.secondaryAccent)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    ContentView()
}
