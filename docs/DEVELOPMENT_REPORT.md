# LeafLoom — Development Report

SE4041 Mobile Application Design and Development, Assignment 02.
Product: **LeafLoom — AI Plant Care & Smart Gardening** ("Grow with confidence.").

> This report describes what was built and how it was checked. Sections marked **(complete on the
> Mac)** need results that only exist after building in Xcode; fill them in yourself.

## 1. Summary

LeafLoom is a local-first iPhone app for houseplant owners. It covers:
- a plant collection with photos,
- care tasks with repeating schedules and reminders,
- a growth journal with before/after photos,
- insights charts,
- on-device plant identification with Core ML.

When no model is installed, identification falls back to a clearly labelled demo mode.

Part B, **LeafLoom Spatial**, is a visionOS 2 prototype. It places the user's plants life-size in
their room and estimates whether each spot's light suits the plant.

There are three deliverables:

| Deliverable | Folder | State |
|---|---|---|
| Native SwiftUI app (iOS 17) | `native-ios/` | Source complete. **Not compiled yet** — needs Xcode on a Mac. |
| Windows browser preview (React + TypeScript) | `windows-preview/` | Complete and verified on Windows: lint, 58 unit tests, build, 5 end-to-end flows, screenshots |
| Part B visionOS prototype | `partB-visionos/` | Source and docs complete. **Not compiled yet.** |

## 2. Development environment and its constraint

All development happened on Windows 11, which cannot run Xcode, the iOS simulator or the Swift
toolchain for Apple platforms. Two decisions follow from this:

1. **A browser preview was built first.** It mirrors the app's screens, data model and rules
   (recurrence, filters, statistics, validation), and stores data in IndexedDB. This made the design
   and logic testable on Windows, and it doubles as a demo for markers without a Mac.
2. **The Swift code was written carefully against the iOS 17 and visionOS 2 SDKs but not compiled.**
   Every document marks it "needs Mac". `scripts/verify-native.sh` and `WINDOWS_TO_MAC_GUIDE.md`
   make the first Mac session a matter of copying the folder, running one script and recording
   results.

Version control (git) was deliberately not used, at the developer's request. The project is a
plain folder, transferred to the Mac by copy, OneDrive or zip.

## 3. Requirements mapping

| Brief requirement | How LeafLoom meets it |
|---|---|
| At least 3 navigable screens | Five tabs (Home, My Plants, Identify, Care, Insights) plus details, journal, settings, reminders, about, and five form sheets. One `NavigationStack` per tab, driven by `AppRouter`. |
| Core Data | Four entities (Plant, CareTask, JournalEntry, IdentificationRecord) with cascade and nullify delete rules, `@MainActor` repositories, background seeding, and lightweight migration settings. |
| Emerging technology | Core ML through Vision (`VNCoreMLRequest`), with a model-agnostic service and a Create ML training guide (`CORE_ML_GUIDE.md`). Part B uses visionOS (RealityKit, volumes, ImmersiveSpace). |
| Custom component and modifier | `ProgressRing`, `CustomTabBar`, `BeforeAfterView`, `PlantCardView`; the `.leafCard()` modifier and LeafLoom button styles (see `UI_DESIGN_SYSTEM.md`). |
| Dark Mode and Dynamic Type | 26 light/dark colour sets in the asset catalog; text styles throughout; layouts adapt at accessibility sizes. |
| Unit, UI and acceptance tests | 84 unit tests, 7 UI tests, 12 visionOS unit tests (written, not yet run); a UAT script; 58 preview unit tests and 5 end-to-end flows (run and passing). See `TEST_PLAN.md`. |
| Documentation | `docs/`: requirements, architecture, design system, Core ML guide, test plan, user guide, Mac guide, this report, AI log, asset attribution, checklist. |
| Part B: prototype, competitor review, pitch | `partB-visionos/` with `CONCEPT.md`, `COMPETITORS.md`, `PITCH.md` |
| AI usage log | `AI_USAGE_LOG.md` |

## 4. Design

The visual language is calm and botanical:
- a deep green primary with sage and terracotta accents,
- rounded cards on warm neutral surfaces,
- original SVG illustrations for onboarding and empty states.

Sample plant photos are AI-generated and listed in `ASSET_ATTRIBUTION.md`. The preview's design tokens
and assets are the source of truth (`UI_DESIGN_SYSTEM.md`). `scripts/generate-native-assets.mjs`
generates the iOS asset catalog from them: colour sets, photos, illustrations, category icons and
the app icon. This keeps the two apps consistent.

Key UX decisions:
- **Honest AI.** Demo identification never shows a confidence score and always carries a banner.
  Real model results below 40% confidence show a warning. Plants saved from a model result
  are marked "suggested", and plants saved from a demo result are marked "unknown", so neither looks
  like a confirmed identification.
- **Forgiving actions.**
  - Completing a task can be undone.
  - Deletes ask for confirmation and say what else will be removed.
  - Forms ask before discarding changes.
- **Recurrence that does not punish lateness.** The next occurrence counts from the day the task
  was actually completed, so a late watering does not leave a backlog of overdue tasks.
- **Accessibility as a default.**
  - Status always uses text and an icon, not just colour.
  - Every chart has a spoken summary.
  - The before/after slider is adjustable with VoiceOver.
  - Reduce Motion removes decorative animation.

## 5. Architecture

Full detail is in `ARCHITECTURE.md`.

- **Reads:** views read Core Data reactively with `@FetchRequest`.
- **Writes:** every write goes through a repository, which also keeps notifications and image
  files in sync.
- **Domain logic:** validation, recurrence, filtering and insights are pure functions over small
  protocols, so they can be unit-tested without a database.
- **Services:** framework-facing services (identification, reminders) sit behind protocols and are
  injected through `AppEnvironment`.
- **Images:** stored as downsampled JPEG files in Application Support, not as blobs in the store.
- **Identification:** a `PlantIdentifying` protocol with Core ML and demo implementations. The
  Core ML service loads `LeafLoomPlantClassifier.mlmodelc` if one is bundled and runs Vision off
  the main actor.
- **Part B:** a separate project. A single `@Observable` `GardenStore` feeds a window, a
  volumetric window and a mixed ImmersiveSpace. Plants are generated procedurally from RealityKit
  primitives, so no third-party 3D assets are needed.

## 6. Testing and quality

Verified on Windows (9 Oct 2026, final code):

| Check | Result |
|---|---|
| ESLint | No problems |
| Vitest | 58/58 tests passed (8 files) |
| Production build | Passed |
| Playwright end-to-end | 5/5 passed |
| Screenshots | 15 captured and inspected |

End-to-end testing in a real browser found a crash that unit tests in jsdom missed: a `useEffect`
returned the Promise from `Element.scrollTo`. It also found five other defects; all are listed in
`TEST_PLAN.md` §2. This was the strongest argument for running real-browser tests, not just jsdom.

Native tests **(complete on the Mac)**: run `./scripts/verify-native.sh`, then record:
- the build result,
- the number of tests passed and failed,
- each compile error you fixed.

## 7. Challenges

| Challenge | Response |
|---|---|
| No Mac during development | Browser preview with the same rules and tests; careful API use; a verification script and handover guide; honest "needs Mac" labelling everywhere. |
| No trained plant model or licensed dataset | Model-agnostic service, a labelled demo mode, and a reproducible Create ML guide with dataset licences flagged "verify before use". No accuracy is claimed. |
| Hand-writing an Xcode project file | Synchronized folders (Xcode 16) keep `project.pbxproj` small. `project.yml` lets XcodeGen regenerate the project if needed. |
| Spatial assets without licensing risk | Procedural RealityKit plants, seeded per plant so they look the same every launch. |

## 8. Limitations

- Native code is uncompiled. Expect some compile fixes on the first Mac build.
- There is no bundled Core ML model, so identification is demo-only until one is trained.
- Reminders are local notifications at a fixed hour. There is no smart scheduling based on weather or season.
- There is no iCloud sync between devices, or between the iPhone app and LeafLoom Spatial.
- The spatial light estimate uses distance only. It is not a measurement.

## 9. Future work

1. Train and evaluate a Create ML model on a properly licensed dataset, and report real metrics.
2. Core Data + CloudKit sync, shared by the iPhone and Vision Pro apps.
3. Widgets and Live Activities for today's care.
4. ARKit plane detection and light estimation in LeafLoom Spatial.

## 10. Reflection (complete yourself)

- What did you learn about SwiftUI, Core Data and Core ML from reviewing and fixing this code?
- Which AI-generated parts did you change, and why? (Cross-reference `AI_USAGE_LOG.md`.)
- What would you do differently with a Mac from the start?
