# PhotoBooth iOS project

## Scope and starting a task
- This repository is the native Swift/SwiftUI iPhone and iPad app. Do not apply Flutter, Dart, Gradle, or Android conventions here.
- Read relevant source and `git status --short --branch` before editing. Explain the intended change briefly, then make the smallest change that fulfills the request.
- Preserve existing user edits and working behavior. Do not perform unrelated refactors, broad formatting, file moves, or dependency upgrades.
- Read `OPENCODE-WORKFLOW.md` for build commands and manual checks when implementing or verifying a change.

## Project map
- `PhotoBooth.xcodeproj`: Xcode project; app target/scheme `PhotoBooth`, Debug and Release configurations.
- `PhotoBooth/PhotoBoothApp.swift`: app entry point.
- `PhotoBooth/ContentView.swift`: capture flow, countdown, review, and theme picker views. ThemePickerView and PhotoStripReviewView are declared here, not in separate files.
- `PhotoBooth/CameraManager.swift`: AVFoundation permissions, serial session queue, camera switching, and async photo capture.
- `PhotoBooth/CameraPreview.swift`: SwiftUI bridge to the camera preview.
- `PhotoBooth/PhotoBoothKit.swift`: filters, strip composition, and Photos saving.
- `PhotoBooth/HolidayThemes.swift`: holiday definitions, date calculations, and persisted theme selection.
- `PhotoBooth/Assets.xcassets`: app assets.

## Swift and SwiftUI
- Follow surrounding naming, indentation, and access-control conventions. Retain existing ObservableObject, @Published, and @StateObject ownership unless a requested change needs otherwise.
- Keep view state updates on the main actor. Respect the project's default MainActor isolation and existing explicit queue/delegate boundaries.
- Preserve serial camera-session work off the main thread. Do not add blocking work to SwiftUI rendering or move capture session start/stop onto the main thread.
- Preserve continuation completion, cancellation cleanup, camera lifecycle, front-camera mirroring, photo orientation, and photo-saving error handling.
- Maintain iPhone and iPad layouts, portrait behavior, existing filters, and theme persistence unless explicitly changing them.
- Do not suppress concurrency diagnostics or add unchecked Sendable declarations merely to make a build pass; investigate the isolation boundary.

## Xcode and safe editing
- Current settings: iOS deployment target 26.5, Swift language mode 5.0, approachable concurrency enabled, default actor isolation MainActor. Check actual project settings before relying on these values.
- Keep bundle ID, signing team, provisioning, capabilities, privacy descriptions, deployment target, and build settings unchanged unless required by the task.
- The source folder uses Xcode filesystem-synchronized groups. Verify target membership when adding files; do not mechanically add duplicate project references.
- Keep documentation and agent files at repository root, outside the synchronized app source folder.
- No third-party package dependencies or test targets are currently configured. Do not add packages, test targets, formatters, or project generators just to set up tooling.
- Never store credentials, signing assets, private photos, or secrets in source or instructions. Do not edit generated build products or user-specific Xcode state.

## Git
- Inspect the diff before and after work. Never discard, reset, stash, or overwrite user changes automatically.
- Do not commit, push, rewrite history, switch branches, or modify remotes unless requested. When a commit is requested, stage only relevant files and inspect the staged diff.
- Keep DerivedData, build output, xcuserdata, and local logs out of commits; respect the existing .gitignore.

## Verification and reporting
- For Swift or project changes, run the documented simulator build when available. Do not alter app settings to work around a missing local SDK or runtime.
- There is currently no automated test target: do not claim tests passed or run an invented test scheme. If tests are later added, discover their scheme and choose an installed simulator before running them.
- Check UI layout in Simulator when relevant. Camera capture, permissions, mirroring, lifecycle, and Photos saving require real-device checks; report which checks remain manual.
- For documentation-only changes, check content, paths, and `git diff --check`; rebuilding is optional.
- Finish with changed files, a concise explanation, verification results, and any remaining limitation. Separate pre-existing warnings from regressions.
