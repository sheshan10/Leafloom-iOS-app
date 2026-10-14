# LeafLoom — Development Report

SE4041 Mobile Application Design and Development, Assignment 02, Part A.

**Product:** LeafLoom, a private iPhone app for houseplant care.

## 1. Purpose and audience

Houseplant owners often forget watering dates and keep care notes in separate places. LeafLoom is for that person. It stores the collection, the schedule, and the growth record on the phone, without an account.

The audience is an iPhone user who keeps plants at home and wants a calm, offline tool rather than a social network.

## 2. What was built

| Area | Implementation |
|---|---|
| Screens | Home, My Plants, Identify, Care, and Insights, plus details, journal, settings, and forms |
| Navigation | `NavigationStack` on each tab, coordinated by `AppRouter` |
| Persistence | Core Data with four entities and repository types |
| Emerging technology | Core ML and Vision for on-device identification, with a demo path when no model is installed |
| Custom UI | Progress ring, custom tab bar, before/after journal slider, `.leafCard()` |
| Accessibility | Dark Mode, Dynamic Type, VoiceOver labels, Reduce Motion |
| Tests | 84 unit tests and 7 UI tests in the Xcode project |

The app has been opened in the iOS simulator on a Mac after compile errors in the Care and Identify screens were fixed.

## 3. Design decisions

- **Local first.** There is no server. Photos stay in the app sandbox. This matches the privacy need and removes a network dependency.
- **Care is counted from the day the task was done.** A late watering schedules the next one from that day, so missed days do not pile up.
- **Identification stays reviewable.** A suggestion opens the add-plant form already filled in. The person checks it before it is saved. Without a model, the app does not invent a confidence percentage.
- **One environment object.** `AppEnvironment` owns persistence, repositories, and services so screens do not create their own stores.
- **Domain logic is separate from SwiftUI.** Validation, recurrence, and chart maths are plain functions, which is why most tests do not need a view.

The visual design uses a deep green primary colour, warm surfaces, and rounded cards so the app feels botanical and consistent in light and dark mode.

## 4. Challenges

- The Swift project was first written on Windows, where Xcode cannot compile it. The first Mac build failed in `CareTaskListView` because the delete confirmation called a function that did not exist. That also made the Swift type checker give up on the large view body. Adding `delete(_:)` and splitting the view fixed the build.
- Identify produced a Swift concurrency warning because `previewImage` was read inside a closure that can leave the main actor. The image is now read on the main actor before those closures use it.
- Core ML needs a trained `.mlmodel`. None is bundled, so identification cannot yet claim a real prediction. The code path is in `CoreMLPlantIdentificationService`; the running app uses the demo service until a model is added.
- Signing onto a physical iPhone needs an Apple ID team in Xcode. The simulator does not.

## 5. Testing

| Check | State |
|---|---|
| App launches in the iOS simulator | Done on a Mac |
| Unit tests (84) | Written in `LeafLoomTests`. Run with **⌘U** and paste the Xcode result here. |
| UI tests (7) | Written in `LeafLoomUITests`. Run with **⌘U** and paste the result here. |
| People using the app | Not done yet. Ask two or three people to add a plant, complete a task, and open Insights. Note what confused them. |

## 6. Limitations and next steps

- Add a Create ML model so Identify analyses the photo and shows confidence.
- Run **⌘U** on the Mac and fill in the test result above.
- Record a short user test.
- Prepare the viva around Home, adding a plant, completing care, the journal slider, Insights, and Identify.

## 7. Reflection

The useful part of the project is not the plant list by itself. It is keeping the schedule honest when someone is late, and keeping identification on the device where the photo never has to be uploaded. The costly part was the first Xcode build: code that looked complete still failed until it was compiled. Building on a Mac early would have found the missing `delete` function sooner.
