# LeafLoom Requirements Checklist

Status key:
- **Done (verified)**: implemented and checked by a command that was actually run on Windows. The evidence is named.
- **Done (needs Mac)**: implemented in Swift but not compiled or run, because Xcode is unavailable on Windows.
- **Pending**: not done yet.

Final state at the end of Windows development (9 Oct 2026). After running
`scripts/verify-native.sh` on a Mac, change "needs Mac" to "verified on Mac" only for items that
actually passed.

## Assignment requirements (SE4041 Assignment 02)

| # | Requirement | Where | Status |
|---|---|---|---|
| A1 | Native iOS app built with Swift and SwiftUI (iOS 17) | `native-ios/` | Done (needs Mac) |
| A2 | Core Data persistence with full CRUD, delete rules, migration settings | `native-ios/LeafLoom/Data/` | Done (needs Mac) |
| A3 | Core ML integration (Vision) with a clearly labelled demo fallback, plus a Create ML guide | `native-ios/LeafLoom/Services/ML/`, `docs/CORE_ML_GUIDE.md` | Done (needs Mac). No model is bundled; demo mode is used until one is trained. |
| A4 | Multiple screens with navigation (5 tabs, details, forms, settings) | `native-ios/LeafLoom/Features/`, `App/AppRouter.swift` | Done (needs Mac) |
| A5 | Unit tests (XCTest), 84 written | `native-ios/LeafLoomTests/` | Done (needs Mac) — written, not run |
| A6 | UI tests (XCUITest), 7 written, deterministic launch arguments | `native-ios/LeafLoomUITests/` | Done (needs Mac) — written, not run |
| A7 | Custom component and custom modifier | `ProgressRing`, `CustomTabBar`, `BeforeAfterView`; `.leafCard()` | Done (needs Mac) |
| A8 | Dark Mode, Dynamic Type, VoiceOver, Reduce Motion | Asset catalog colour sets; `docs/UI_DESIGN_SYSTEM.md` | Done (needs Mac). Manual checklist in `TEST_PLAN.md` §6. |
| A9 | Photos (PhotosPicker) and camera | `IdentifyView`, `PlantFormView`, `FormComponents.swift` | Done (needs Mac) |
| A10 | Local notifications with permission handling | `Services/Notifications/ReminderScheduler.swift`, `ReminderSettingsView` | Done (needs Mac) |
| A11 | Charts (Swift Charts) | `Features/Insights/InsightsView.swift` | Done (needs Mac) |
| A12 | User acceptance testing | `docs/TEST_PLAN.md` §5 | Script ready. **Pending: sessions with real users.** |
| B1 | Part B prototype on an emerging Apple platform (visionOS 2: window, volume, ImmersiveSpace, gestures) | `partB-visionos/` | Done (needs Mac) — 12 unit tests written, not run |
| B2 | Write-up of similar existing apps | `partB-visionos/docs/COMPETITORS.md` | Done. Check the listings and fill in "Checked on" before submitting. |
| B3 | Pitch: value proposition, market, revenue model, go-to-market | `partB-visionos/docs/PITCH.md` | Done. Market-size figures intentionally left to be sourced. |
| D1 | Documentation | `README.md`, `docs/` | Done |
| D2 | AI usage log | `docs/AI_USAGE_LOG.md` | Done for the AI sessions. The developer's own review and changes are still to be added. |

## Windows browser preview

| # | Requirement | Status |
|---|---|---|
| W1 | iPhone device frame, three device sizes, dev panel (screen info, navigation, theme, text size, reduce motion, reset/erase) | Done (verified: `npm run build`, Playwright flow 5) |
| W2 | Real CRUD persisted in IndexedDB (plants, tasks, journal, identifications, preferences) | Done (verified: Vitest `repository.test.ts`, `store.test.tsx`; Playwright flow 2) |
| W3 | Simulated ML and notifications, clearly labelled | Done (verified: Vitest `PhoneApp.test.tsx`; Playwright flow 4) |
| W4 | Responsive layout (desktop, tablet, mobile widths) | Done (verified: `npm run screenshots`, 15 images in `docs/screenshots/preview/`, inspected) |
| W5 | Lint, unit tests and build pass | Done (verified: `npm run lint`, `npx vitest run` 58/58, `npm run build`) |
| W6 | Part B spatial 2D simulation | Done (verified: Playwright flow 5, screenshot `12-visionos-simulation.png`) |

## Mac handover

| # | Item | Status |
|---|---|---|
| M1 | `scripts/verify-native.sh` (iOS and visionOS build and test, logs, summary) | Done. `bash -n` syntax check passed; on Windows it exits cleanly with "xcodebuild not found". Real run needs a Mac. |
| M2 | `docs/WINDOWS_TO_MAC_GUIDE.md` (OneDrive, zip or folder copy; no git) | Done |
| M3 | XcodeGen fallback (`project.yml`) for both projects | Done (needs Mac) |

## Rules from the brief

| Rule | Status |
|---|---|
| No fabricated build or test results, model files, accuracy figures or licences | Followed. Every claim names its evidence; Mac-only steps are marked "needs Mac". |
| Simulated results labelled | Followed: demo banner, "Simulated" labels, no confidence for demo results. |
| No secrets, no unnecessary backend, local-first | Followed: no network calls, no keys. |
| No unverified dependencies | Followed: Apple frameworks only in native code; well-known npm packages in the preview. |
| No git usage (developer instruction) | Followed |
