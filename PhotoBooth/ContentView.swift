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
    @State private var captureTask: Task<Void, Never>?

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let shotsPerStrip = 4

    private var theme: HolidayTheme { themeManager.current }
    private var isPad: Bool { horizontalSizeClass == .regular }
    private var metrics: Metrics { Metrics(isPad: isPad) }

    private struct Metrics {
        let isPad: Bool
        var horizontalPadding: CGFloat { isPad ? 56 : 20 }
        var badgeSize: CGFloat { isPad ? 48 : 36 }
        var badgeFont: CGFloat { isPad ? 16 : 12 }
        var kickerFont: CGFloat { isPad ? 13 : 10 }
        var titleFont: CGFloat { isPad ? 25 : 18 }
        var framesLabelFont: CGFloat { isPad ? 12 : 9 }
        var framesValueFont: CGFloat { isPad ? 17 : 13 }
        var iconFont: CGFloat { isPad ? 22 : 16 }
        var chipFont: CGFloat { isPad ? 13 : 10 }
        var chipChevronFont: CGFloat { isPad ? 10 : 8 }
        var chipPaddingH: CGFloat { isPad ? 16 : 12 }
        var chipPaddingV: CGFloat { isPad ? 9 : 6 }
        var cropMarkLength: CGFloat { isPad ? 30 : 16 }
        var cropMarkWidth: CGFloat { isPad ? 3 : 2 }
        var cropMarkInset: CGFloat { isPad ? 24 : 14 }
        var countdownFont: CGFloat { isPad ? 180 : 96 }
        var shotLabelFont: CGFloat { isPad ? 15 : 11 }
        var shutterOuter: CGFloat { isPad ? 108 : 78 }
        var shutterInner: CGFloat { isPad ? 82 : 58 }
        var shutterStroke: CGFloat { isPad ? 4 : 3 }
        var controlsSideInset: CGFloat { isPad ? 64 : 40 }
        var resetIconFont: CGFloat { isPad ? 20 : 15 }
        var resetLabelFont: CGFloat { isPad ? 11 : 9 }
        var contactHeaderFont: CGFloat { isPad ? 13 : 10 }
        var thumbWidth: CGFloat { isPad ? 128 : 84 }
        var thumbHeight: CGFloat { isPad ? 164 : 108 }
        var thumbLabelFont: CGFloat { isPad ? 12 : 9 }
    }

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
        .onAppear {
            themeManager.refreshIfNeeded()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                captureTask?.cancel()
                camera.stopSession()
                UIApplication.shared.isIdleTimerDisabled = false
            case .active:
                camera.resumeSession()
                themeManager.refreshIfNeeded()
                UIApplication.shared.isIdleTimerDisabled = true
            default:
                break
            }
        }
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
                .frame(width: metrics.badgeSize, height: metrics.badgeSize)
                .overlay(
                    Text("PB")
                        .font(.system(size: metrics.badgeFont, weight: .bold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text("POCKET STUDIO")
                    .font(.system(size: metrics.kickerFont, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(theme.ink.opacity(0.55))
                Text("PhotoBooth")
                    .font(.system(size: metrics.titleFont, weight: .bold, design: .serif))
                    .foregroundStyle(theme.ink)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("FRAMES")
                    .font(.system(size: metrics.framesLabelFont, weight: .bold))
                    .foregroundStyle(theme.ink.opacity(0.5))
                Text("\(shots.count)/0\(shotsPerStrip)")
                    .font(.system(size: metrics.framesValueFont, weight: .bold, design: .serif))
                    .foregroundStyle(theme.ink)
            }

            Button {
                camera.switchCamera()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: metrics.iconFont, weight: .semibold))
                    .foregroundStyle(theme.ink)
            }
            .disabled(isRunningSequence)
        }
        .padding(.horizontal, metrics.horizontalPadding)
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
                        .font(.system(size: metrics.chipFont, weight: .bold))
                        .tracking(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: metrics.chipChevronFont, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, metrics.chipPaddingH)
                .padding(.vertical, metrics.chipPaddingV)
                .background(theme.accent)
                .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(.horizontal, metrics.horizontalPadding)
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
                    .font(.system(size: metrics.countdownFont, weight: .bold, design: .serif))
                    .foregroundStyle(theme.paper)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .padding(.horizontal, metrics.horizontalPadding)
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
        .padding(metrics.cropMarkInset)
        .allowsHitTesting(false)
    }

    private func cropMark(rotation: Double) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: metrics.cropMarkLength))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: metrics.cropMarkLength, y: 0))
        }
        .stroke(theme.paper.opacity(0.7), lineWidth: metrics.cropMarkWidth)
        .frame(width: metrics.cropMarkLength, height: metrics.cropMarkLength)
        .rotationEffect(.degrees(rotation))
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 10) {
            if isRunningSequence {
                Text("SHOT \(min(shots.count + 1, shotsPerStrip)) OF \(shotsPerStrip)")
                    .font(.system(size: metrics.shotLabelFont, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(theme.ink.opacity(0.6))
            }

            ZStack {
                Button {
                    captureTask = Task { await runPhotoBoothSequence() }
                } label: {
                    ZStack {
                        Circle()
                            .stroke(theme.ink, lineWidth: metrics.shutterStroke)
                            .frame(width: metrics.shutterOuter, height: metrics.shutterOuter)
                        Circle()
                            .fill(isRunningSequence ? theme.ink.opacity(0.25) : theme.accent)
                            .frame(width: metrics.shutterInner, height: metrics.shutterInner)
                    }
                }
                .disabled(isRunningSequence || !camera.permissionGranted)

                HStack {
                    Button {
                        shots = []
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: metrics.resetIconFont, weight: .semibold))
                            Text("RESET")
                                .font(.system(size: metrics.resetLabelFont, weight: .bold))
                                .tracking(1)
                        }
                    }
                    .foregroundStyle(theme.ink.opacity(0.55))
                    .disabled(isRunningSequence || shots.isEmpty)

                    Spacer()
                }
                .padding(.horizontal, metrics.controlsSideInset)
            }
        }
        .padding(.vertical, 18)
    }

    // MARK: - Contact sheet

    private var contactSheet: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CONTACT SHEET")
                    .font(.system(size: metrics.contactHeaderFont, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(theme.ink.opacity(0.5))
                Spacer()
                Text("SESSION SP-\(sessionCode)")
                    .font(.system(size: metrics.contactHeaderFont, weight: .bold))
                    .foregroundStyle(theme.ink.opacity(0.4))
            }
            .padding(.horizontal, metrics.horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(shots.enumerated()), id: \.offset) { index, shot in
                        Image(uiImage: shot)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: metrics.thumbWidth, height: metrics.thumbHeight)
                            .clipped()
                            .overlay(
                                Text("0\(index + 1)")
                                    .font(.system(size: metrics.thumbLabelFont, weight: .bold))
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
                            .frame(width: metrics.thumbWidth, height: metrics.thumbHeight)
                            .overlay(
                                Text("0\(index + 1)")
                                    .font(.system(size: metrics.thumbLabelFont, weight: .bold))
                                    .foregroundStyle(theme.ink.opacity(0.3))
                            )
                    }
                }
                .padding(.horizontal, metrics.horizontalPadding)
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
                if Task.isCancelled { return abandonSequence() }
                countdown = tick
                try? await Task.sleep(nanoseconds: 800_000_000)
            }
            if Task.isCancelled { return abandonSequence() }
            countdown = nil

            if let image = await camera.capturePhoto() {
                shots.append(image)
            }

            if Task.isCancelled { return abandonSequence() }
            try? await Task.sleep(nanoseconds: 400_000_000)
        }

        isRunningSequence = false
        captureTask = nil
        recomposeStrip()
    }

    /// Resets UI state cleanly when a sequence is interrupted (e.g. the app was backgrounded).
    private func abandonSequence() {
        isRunningSequence = false
        countdown = nil
        shots = []
        captureTask = nil
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

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        ZStack {
            theme.paper.ignoresSafeArea()

            VStack(spacing: isPad ? 26 : 18) {
                Text("\(theme.emoji)  \(theme.stripCaption)")
                    .font(.system(size: isPad ? 30 : 22, weight: .bold, design: .serif))
                    .foregroundStyle(theme.ink)
                    .padding(.top, isPad ? 32 : 24)

                ScrollView {
                    Image(uiImage: strip)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: isPad ? 420 : .infinity)
                        .padding(.horizontal, 24)
                        .shadow(color: .black.opacity(0.15), radius: 14, x: 6, y: 8)
                }

                Picker("Filter", selection: $selectedFilter) {
                    ForEach(PhotoFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: isPad ? 480 : .infinity)
                .padding(.horizontal, 24)
                .onChange(of: selectedFilter) { _, _ in
                    onFilterChange()
                }

                HStack(spacing: 14) {
                    Button(action: onRetake) {
                        Text("Retake")
                            .font(.system(size: isPad ? 16 : 14, weight: .bold))
                            .foregroundStyle(theme.ink)
                            .padding(.vertical, isPad ? 14 : 12)
                            .frame(maxWidth: .infinity)
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(theme.ink.opacity(0.4), lineWidth: 1))
                    }

                    Button(action: onSave) {
                        Text("Save to Photos")
                            .font(.system(size: isPad ? 16 : 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.vertical, isPad ? 14 : 12)
                            .frame(maxWidth: .infinity)
                            .background(theme.accent)
                    }

                    ShareLink(
                        item: Image(uiImage: strip),
                        preview: SharePreview("PhotoBooth strip", image: Image(uiImage: strip))
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: isPad ? 18 : 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(isPad ? 14 : 12)
                            .background(theme.secondaryAccent)
                    }
                }
                .frame(maxWidth: isPad ? 480 : .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, isPad ? 32 : 24)
            }
        }
    }
}

#Preview {
    ContentView()
}
