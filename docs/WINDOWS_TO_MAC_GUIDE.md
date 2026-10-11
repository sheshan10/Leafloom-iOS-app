# Moving LeafLoom from Windows to a Mac

The native app and the visionOS prototype need Xcode, which only runs on macOS. This guide moves
the project folder to a Mac without git, then builds, tests and records the results.

## 1. What you need on the Mac

| Item | Version | Notes |
|---|---|---|
| macOS | 14.5 (Sonoma) or later | Required by Xcode 16 |
| Xcode | 16 or later | The projects use synchronized folders (`objectVersion = 77`), which need Xcode 16 |
| iOS Simulator runtime | iOS 17 or later | Xcode → Settings → Components |
| visionOS Simulator runtime | visionOS 2 or later | Only for Part B; same place (large download) |
| Apple ID | free account is fine | For signing on a real device; the simulator needs no account |

Optional: Node.js 20+ if you also want to run the browser preview on the Mac.

## 2. Copy the project (choose one)

Leave these folders out. They are large, platform-specific, and recreated automatically:

- `windows-preview/node_modules/`
- `windows-preview/dist/`
- `windows-preview/test-results/`
- `windows-preview/playwright-report/`

### Option A — OneDrive (the project already lives in OneDrive)

1. On Windows, right-click the `ios_mobile_app` folder → **Always keep on this device**, and wait for the sync to finish.
2. On the Mac, install OneDrive, sign in with the same account and open the folder.
3. In Finder, right-click the folder → **Always Keep on This Device**. Xcode cannot build from cloud-only placeholder files.
4. Better still, copy the folder out of OneDrive to `~/Developer/LeafLoom` before building. Sync clients can lock files during a build.

### Option B — Zip file (USB drive, AirDrop or email)

In PowerShell on Windows, run from the folder that contains `ios_mobile_app`. This creates a zip
without `node_modules` and build output:

```powershell
$src = "ios_mobile_app"
$tmp = Join-Path $env:TEMP "leafloom-export"
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
robocopy $src $tmp /E /XD node_modules dist test-results playwright-report | Out-Null
Compress-Archive -Path "$tmp\*" -DestinationPath "LeafLoom.zip" -Force
```

Copy `LeafLoom.zip` to the Mac and double-click it to unzip, for example into `~/Developer/LeafLoom`.

### Option C — Plain folder copy

Copy the whole folder to a USB drive. Leave out `node_modules`, or delete it on the Mac afterwards.
Copy it to a local folder on the Mac before opening it in Xcode.

### After copying

The shell script loses its executable bit on Windows. Restore it with:

```bash
cd ~/Developer/LeafLoom
chmod +x scripts/verify-native.sh
```

## 3. Build and run the iOS app

1. Open `native-ios/LeafLoom.xcodeproj` in Xcode.
2. Select the **LeafLoom** scheme and an iPhone simulator (for example iPhone 16).
3. Press **⌘R**. On first launch you should see onboarding, then the sample collection.
4. **Real device only:** select the LeafLoom target → Signing & Capabilities → choose your Team. If the bundle id `com.leafloom.LeafLoom` is taken, change it to something unique, such as `com.yourname.LeafLoom`.

Useful launch arguments (Product → Scheme → Edit Scheme → Run → Arguments):

| Argument | Effect |
|---|---|
| `-skipOnboarding` | Skip onboarding |
| `-resetData` | Re-seed sample data on launch |
| `-emptyState` | Start with no data |
| `-uiTesting` | In-memory store and no permission prompts (used by UI tests) |

### Optional: add a Core ML model

Without a model, identification runs in a clearly labelled demo mode. To use a real model, follow
`CORE_ML_GUIDE.md`. Train with Create ML, name the file `LeafLoomPlantClassifier.mlmodel` (or
`.mlpackage`), and drop it into `native-ios/LeafLoom/Resources/`. Synchronized folders add it to
the target automatically.

## 4. Build and run the visionOS prototype

1. Open `partB-visionos/LeafLoomSpatial.xcodeproj`.
2. Select the **LeafLoomSpatial** scheme and the **Apple Vision Pro** simulator, then press **⌘R**.
3. Choose **Arrange in my room** to open the immersive space.

## 5. Run every check and record the results

From the project root:

```bash
./scripts/verify-native.sh          # iOS build + tests, then visionOS build + tests
./scripts/verify-native.sh ios      # iOS only
IOS_SIMULATOR="iPhone 16" ./scripts/verify-native.sh ios
```

The script prints a PASS/FAIL summary and saves logs and `.xcresult` bundles to
`verification-logs/<timestamp>/`. Then:

1. Copy the summary into `docs/TEST_PLAN.md` sections 3 and 4, replacing "Not run — needs Mac".
2. Update `docs/CHECKLIST.md`: change "Done (needs Mac)" to "Done (verified on Mac)" only for items that passed.
3. Record the compile fixes you made in `docs/AI_USAGE_LOG.md`.
4. Take simulator screenshots (**⌘S** in the Simulator) for the report.

## 6. Troubleshooting

| Symptom | Likely cause and fix |
|---|---|
| "The project file cannot be opened" or "unknown object version" | Xcode is older than 16. Update it, or regenerate the project with XcodeGen: `brew install xcodegen && cd native-ios && xcodegen generate` (also works in `partB-visionos`). |
| "Multiple commands produce … Info.plist" | A file named `Info.plist` was added inside `native-ios/LeafLoom/`. Synchronized folders bundle everything there; move it out. |
| Files are missing in Xcode, or the build reads stale files | OneDrive placeholders. Make the folder available offline, or copy it to a local folder. |
| A Swift compile error | Expected on the first build, because this code has not been compiled. Read the first error, fix it, rebuild, and log the fix in `AI_USAGE_LOG.md`. |
| UI test cannot find an element | Use Xcode's Accessibility Inspector on the running simulator to check the identifier, then fix the app or the test. |
| Notifications never appear | Allow them when prompted, or in Settings → LeafLoom. The simulator shows them while the app is in the background. |
| Camera button is missing | Expected on the simulator, which has no camera. Use the photo library or the sample photos instead. |
| "No such module 'RealityKit'" in the visionOS project | The destination is not a visionOS simulator. Choose Apple Vision Pro. |
| The script says "visionOS SDK not installed" | Install the visionOS platform in Xcode → Settings → Components. |
