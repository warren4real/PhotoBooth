# PhotoBooth in VS Code

Open this repository folder in VS Code, rather than opening only the Swift source folder. PhotoBooth remains the same Swift/SwiftUI Xcode project.

## Build and run

1. Open the SweetPad sidebar in VS Code.
2. Select the PhotoBooth scheme and an iOS 26.5 simulator (the app requires iOS 26.5).
3. Use SweetPad's Build & Run action. Xcode must stay installed, but its editor does not need to be open.
4. For debugging, use SweetPad's debug configuration command and the CodeLLDB extension.

## Swift autocomplete

The workspace points the Swift extension to Xcode's toolchain. `buildServer.json` connects the project to the installed SweetPad CLI; its configuration has been checked with `sweetpad bsp doctor`. Build once after opening the folder. If autocomplete needs refreshing, run `SweetPad: Set up Swift code intelligence (BSP)` from the command palette.

## What still benefits from Xcode

Use Xcode for SwiftUI Canvas previews, signing/capabilities, and App Store distribution. Simulator can check layout; test camera capture and Photos saving on a real device.

Save files before switching editors. Follow AGENTS.md and the verification steps in OPENCODE-WORKFLOW.md when changing app code.

Flutter experiments live in a separate project and do not change PhotoBooth's language or app implementation.
