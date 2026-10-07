# OpenCode + Xcode workflow

## Start a session

In Terminal:

```sh
cd ~/Developer/PhotoBooth
opencode
```

Open `PhotoBooth.xcodeproj` in Xcode. Use OpenCode for scoped source edits and Xcode for previews, running, signing, and device debugging. Save edits before switching tools and avoid editing the same file in both at once.

OpenCode automatically reads the root `AGENTS.md`. No project-specific model/provider override is needed; your existing global OpenCode configuration remains in use. Start a fresh session after changing instructions. You can begin with: “Read AGENTS.md, inspect Git status, and summarize the project and build command without editing files.”

## Everyday loop

1. Describe one change and any behavior to preserve.
2. Let OpenCode inspect the relevant code and explain its intended change.
3. Review the diff, build, and run the relevant checks below.
4. Review the result in Xcode. Request a commit only when satisfied.

## Inspect and build

Run from the repository root:

```sh
git status --short --branch
xcodebuild -list -project PhotoBooth.xcodeproj
xcodebuild -showdestinations -project PhotoBooth.xcodeproj -scheme PhotoBooth
```

Build for Simulator without changing project signing settings:

```sh
xcodebuild -project PhotoBooth.xcodeproj \
  -scheme PhotoBooth -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/PhotoBooth-OpenCode-DerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

A successful build verifies compilation, not camera behavior. If Xcode reports a missing SDK or runtime, inspect the selected Xcode and installed components. Do not lower the deployment target or change signing to hide an environment issue.

```sh
git diff --check
git diff --stat
git diff
```

New untracked files are not included in `git diff`; inspect them separately before staging.

## Testing

The project currently has one app target and no automated test target. Use Xcode's PhotoBooth scheme to run on an installed iPhone or iPad simulator for layout checks. If a test target is added later, discover its scheme and destination before using `xcodebuild test`.

For changes affecting capture or saving, check on a real iPhone/iPad:

- Camera permission allowed and denied states.
- Front/back switching, preview orientation, and front-camera mirroring.
- Countdown, complete photo sequence, strip review, filters, and theme selection.
- Background/foreground interruption and capture cancellation recovery.
- Save to Photos with permission granted and denied; inspect the saved strip.
- iPhone and iPad layout and persisted theme choice after relaunch.

Report checks actually performed and those still pending. Do not treat Simulator as proof of physical camera behavior.

## References

- OpenCode project rules: https://opencode.ai/docs/rules/
- OpenCode configuration: https://opencode.ai/docs/config/
