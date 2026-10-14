# LeafLoom — Technical Documentation

LeafLoom is a SwiftUI app for iOS 17. The Xcode project is `LeafLoom.xcodeproj` at the root of this repository. The bundle identifier is `com.leafloom.LeafLoom`.

## How to build

1. Install Xcode 16 or later on a Mac.
2. Open `LeafLoom.xcodeproj`.
3. For the simulator, choose an iPhone running iOS 17 or later and press **⌘R**.
4. For a physical iPhone, connect the phone, sign in under **Xcode → Settings → Accounts**, then in the LeafLoom target open **Signing & Capabilities**, enable automatic signing, and choose your Personal Team. Press **⌘R**. On the phone, trust the developer under **Settings → General → VPN & Device Management**.

If the project file does not open, install XcodeGen and run `xcodegen generate` in this folder. That rebuilds the project from `project.yml`.

Press **⌘U** to run the unit tests and UI tests.

## Layout

| Path | Role |
|---|---|
| `LeafLoom/App` | App entry, `AppEnvironment`, navigation router, preferences |
| `LeafLoom/Features` | Screens: Home, collection, details, care, journal, identify, insights, settings, onboarding |
| `LeafLoom/Core` | Design system, shared components, validation, recurrence, and insight calculations |
| `LeafLoom/Data` | Core Data model, repositories, image files, sample data |
| `LeafLoom/Services` | Core ML identification and local reminders |
| `LeafLoomTests` | Unit tests |
| `LeafLoomUITests` | UI tests |

## Architecture

The app is split into presentation, domain logic, and services.

- Screens are SwiftUI views. Lists read Core Data with `@FetchRequest`. They do not save the context themselves.
- `AppEnvironment` is created once in `LeafLoomApp` and passed through the environment. It owns the persistence controller, repositories, image store, reminder scheduler, identifier, router, and preferences.
- Navigation uses a `NavigationStack` per tab, driven by `AppRouter`.
- Forms and the identify flow use `@Observable` view models.
- Validation, recurrence, filtering, and chart numbers are pure Swift functions, so they can be tested without the simulator.
- Writes go through repositories: `PlantRepository`, `CareTaskRepository`, `JournalRepository`, and `IdentificationRepository`.

## Data

Core Data stores four entities in `LeafLoom/Data/LeafLoom.xcdatamodeld`:

| Entity | Holds | Delete behaviour |
|---|---|---|
| Plant | Name, category, photo filename, care profile, tags | Deleting a plant cascades to its tasks and journal entries |
| CareTask | Due date, completion, repeat interval, series id | Belongs to one plant |
| JournalEntry | Note, optional photo, optional height, date | Belongs to one plant |
| IdentificationRecord | Predicted label, optional confidence, demo flag, photo | Link to a plant is cleared if the plant is deleted |

Photos are files in the app's Application Support directory, managed by `ImageStore`. The database stores the filename only.

A repeating care task does not create a backlog. `RecurrenceCalculator` schedules the next due date from the completion date, keeping the same time of day.

## Identification

`PlantIdentifying` has two implementations:

- `CoreMLPlantIdentificationService` runs a Vision request (`VNCoreMLRequest`) on device when a compiled Core ML model is present.
- `DemoPlantIdentificationService` is used when no model is in the bundle. It does not analyse the photo and does not return a confidence score.

`IdentificationViewModel` loads a library photo, a camera photo, or a bundled sample, then calls the identifier. Saving a result opens the add-plant form with the suggestion filled in.

No `.mlmodel` file is in the repository. A model can be trained with Create ML and added to the LeafLoom target. Results below 40% confidence show a low-confidence warning.

## Notifications

`ReminderScheduler` uses `UserNotifications`. Each open task gets one calendar notification on its due date at the hour chosen in Settings (6:00–22:00). The notification identifier is the task id, so completing or deleting a task removes the pending reminder.

## Interface

Custom interface pieces include `ProgressRing`, `CustomTabBar`, `BeforeAfterView`, and the `.leafCard()` modifier. Colours are asset-catalog sets with light and dark variants. Text uses Dynamic Type styles. Reduce Motion turns off decorative animation. Charts use Swift Charts, and each chart has an accessibility summary.

## Tests

`LeafLoomTests` contains 84 unit tests for validation, recurrence, repositories, insights, identification, and reminders. They use an in-memory Core Data store. `LeafLoomUITests` contains 7 UI tests. Record the Xcode **⌘U** result in the development report after running them on a Mac.
