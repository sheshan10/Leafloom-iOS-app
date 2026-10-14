# LeafLoom

LeafLoom is a private iPhone app for people who keep houseplants. It helps you remember what each plant needs, when to care for it, and how it is growing. There is no account and no server. Plants, photos, and notes stay on the phone.

Built with Swift and SwiftUI for iOS 17.

## What you can do

- **My Plants.** Save each plant with a photo, category, location, light, and notes. Search, filter, and sort the collection.
- **Care.** Schedule watering, fertilising, and other tasks. Completing a repeating task schedules the next one from the day you actually did it. Reminders stay on the device.
- **Journal.** Record notes, photos, and height. Compare the first and latest photo with a before/after slider.
- **Insights.** See weekly care completion, care types, plants by category, and plants added each month.
- **Identify.** Suggest a plant from a photo using Core ML and Vision on the device. Until a trained model is added, Identify runs in a labelled demo mode and does not show a confidence score.

## Run it

You need a Mac with Xcode 16 or later.

1. Clone this repository.
2. Open `LeafLoom.xcodeproj`.
3. Choose an iPhone simulator.
4. Press **⌘R**.

If the Xcode project does not open, install [XcodeGen](https://github.com/yonaskolb/XcodeGen) and run `xcodegen generate` in this folder. That rebuilds `LeafLoom.xcodeproj` from `project.yml`.

## Documentation

| Document | Contents |
|---|---|
| [User guide](docs/USER_GUIDE.md) | How to use every screen |
| [Technical documentation](docs/TECHNICAL_DOCUMENTATION.md) | Build steps, architecture, data, Core ML, tests |
| [Development report](docs/DEVELOPMENT_REPORT.md) | Purpose, design decisions, challenges, testing, reflection |

## Project layout

| Path | Contents |
|---|---|
| `LeafLoom/` | SwiftUI app: screens, Core Data, Core ML, and reminders |
| `LeafLoomTests/` | Unit tests |
| `LeafLoomUITests/` | UI tests |
| `LeafLoom.xcodeproj` | Xcode project |
| `project.yml` | XcodeGen fallback, used only if the project file needs to be regenerated |
