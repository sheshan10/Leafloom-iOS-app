# LeafLoom — Product Requirements Document

**Product:** LeafLoom — AI Plant Care & Smart Gardening
**Tagline:** Grow with confidence.
**Course:** SE4041 Mobile Application Design and Development — Assignment 02 (Swift), Part A
**Platform:** iOS 17+ (native SwiftUI). A browser preview (React/Vite) exists as a Windows development companion only.

---

## 1. Problem statement

Plant owners regularly struggle to:

- identify unfamiliar plants they buy or are given,
- understand each plant's care requirements (light, water, humidity, soil),
- remember recurring care activities such as watering and fertilising,
- notice change over time (growth, decline) without any record to compare against.

The information needed is scattered across plant labels, search engines, notes apps and calendar reminders. LeafLoom brings plant records, identification assistance, scheduled care and a growth journal into one local-first application.

## 2. Objectives

| # | Objective | Measured by |
|---|-----------|-------------|
| O1 | Let a user keep a structured, searchable plant collection | Plant CRUD, search, sort, filter, favourites all persist |
| O2 | Assist identification with on-device machine learning | Core ML/Vision service integrated behind a protocol; clearly labelled demo mode when no model is installed |
| O3 | Make recurring care easy to remember | Care tasks with recurrence, completion history and local notifications |
| O4 | Make plant change visible over time | Growth journal with photos and chronological timeline |
| O5 | Give an at-a-glance view of collection health and care consistency | Dashboard and Insights computed from stored records |
| O6 | Be accessible and pleasant to use | Dynamic Type, Dark Mode, VoiceOver labels, reduced-motion support |

## 3. Target audience

| Segment | Need | How LeafLoom addresses it |
|---------|------|---------------------------|
| Indoor plant owners (primary) | Remember watering; keep plants alive | Recurring reminders, "needs attention" dashboard |
| Beginner gardeners | Learn what a plant is and what it needs | Identification flow with care information, guided add-plant form |
| Students interested in sustainability | Low-cost, approachable entry to gardening | Free, offline, no account required |
| Plant enthusiasts with larger collections | Organise and monitor many plants | Search/filter/sort, tags, locations, insights |

**Justification:** these users are smartphone-first, typically keep 3–30 plants, and do not want an account, subscription or cloud dependency for a personal hobby. A local-first design with on-device ML respects privacy and works offline.

## 4. Functional requirements

### FR1 Onboarding
- FR1.1 Three-page onboarding (collection, identification, reminders) with progress indicator, Skip, Continue and Get Started.
- FR1.2 Completion persisted; replayable from Settings.
- FR1.3 Notification permission requested only from a reminders context, after explaining the benefit.

### FR2 Dashboard
- FR2.1 Greeting with current date.
- FR2.2 Collection summary, plants needing attention, upcoming tasks, recently added plants.
- FR2.3 Quick actions: Add plant, Identify plant.
- FR2.4 Weekly care-progress ring and collection-care summary computed from records.
- FR2.5 Designed empty state when no plants exist.

### FR3 Plant collection (CRUD)
- FR3.1 Create with: name (required), common name, scientific name, category (required), identification status, photo, location, acquisition date, watering/fertilising intervals, sunlight, humidity, soil, notes, tags.
- FR3.2 Validation: name trimmed, 1–60 characters; intervals 1–365 days when provided; acquisition date not in the future.
- FR3.3 Read: grid or list, plant details screen with hero photo, care info, next care, journal timeline, care history.
- FR3.4 Update: prefilled form, identifier preserved, all views refresh.
- FR3.5 Delete: confirmation dialog; cascades to the plant's care tasks and journal entries; identification history is retained with the plant link cleared; pending notifications cancelled.

### FR4 Search, sort, filter
- FR4.1 Search by name, common name, scientific name.
- FR4.2 Filter by category, location, favourites.
- FR4.3 Sort by recently added, alphabetical, next care date.
- FR4.4 Grid/list toggle; Clear filters; helpful empty-results state.

### FR5 Favourites
- FR5.1 Toggle from card and details; persisted; filterable.

### FR6 Plant identification (Core ML)
- FR6.1 Choose a photo from the library (PhotosPicker) or camera when available.
- FR6.2 Preview, cancel, choose another.
- FR6.3 Processing state; work off the main thread.
- FR6.4 Results: top label, alternatives, confidence only when supplied by the model, with a disclaimer that confidence is not a guarantee.
- FR6.5 When no compatible model is installed: results are clearly labelled "Demo identification — connect a compatible Core ML model for real predictions."
- FR6.6 Save to My Plants (prefilled form) and optional identification history.
- FR6.7 No disease diagnosis claims.

### FR7 Care tasks and reminders
- FR7.1 Categories: watering, fertilising, pruning, repotting, cleaning leaves, inspection, custom.
- FR7.2 CRUD, mark complete, undo completion.
- FR7.3 Filter: upcoming, overdue, completed; sorted by due date.
- FR7.4 Recurrence: on completion, the next occurrence is created at `completedAt + interval` days; history preserved.
- FR7.5 Local notifications per task (identifier = task UUID); rescheduled on edit, cancelled on delete/complete.
- FR7.6 App fully functional when notifications are denied.

### FR8 Growth journal
- FR8.1 Entries linked to a plant with date, notes, optional photo.
- FR8.2 Create, edit, delete; chronological timeline on plant details.
- FR8.3 Before/after comparison of the earliest and latest photo entries.

### FR9 Insights
- FR9.1 Totals, plants by category, tasks completed this week, upcoming tasks, additions over time, completion trend (last 8 weeks), favourites.
- FR9.2 Charts with accessible descriptions; empty states when data is insufficient.

### FR10 Settings
- FR10.1 Appearance: System / Light / Dark applied app-wide.
- FR10.2 Reminder preferences (enable, default reminder hour).
- FR10.3 Default collection layout.
- FR10.4 Replay onboarding, privacy information, version, about.
- FR10.5 Reset to sample data and Erase all data, each behind confirmation.

## 5. Non-functional requirements

| ID | Requirement |
|----|-------------|
| NFR1 Privacy | All data stored on device. No network calls. Photos never uploaded. No analytics SDKs. |
| NFR2 Offline | Every feature works without connectivity. |
| NFR3 Accessibility | Dynamic Type, VoiceOver labels/hints, ≥44pt targets, non-colour status indicators, reduced motion. |
| NFR4 Appearance | Designed light and dark themes with WCAG AA text contrast. |
| NFR5 Performance | Lazy grids/lists; images downsampled before display and storage; ML inference off the main thread. |
| NFR6 Robustness | Friendly errors for persistence, image, model and permission failures; no raw errors shown. |
| NFR7 Maintainability | Layered architecture (views → view models → repositories/services), protocol-backed services for testing. |
| NFR8 Testability | Unit tests for validation, recurrence, filtering, statistics, ML mapping; UI tests for main journeys. |

## 6. Main user journeys

1. **First launch:** onboarding → dashboard showing labelled sample plants → user explores or resets to empty.
2. **Add a plant:** My Plants → + → fill form → Save → plant appears with success toast; dashboard counts update.
3. **Identify a plant:** Identify → choose photo → analysing → results (real or labelled demo) → Save to My Plants → prefilled form.
4. **Daily care:** Home → "Today" tasks → tap check → task completes with animation; recurring task's next occurrence appears.
5. **Track growth:** Plant details → Journal → add entry with photo → timeline and before/after update.
6. **Review progress:** Insights → charts reflect completed tasks and collection composition.

## 7. Scope and limitations

**In scope:** everything listed above, local-first, single user, single device.

**Out of scope:** user accounts, cloud sync, social features, plant disease diagnosis, weather integration, purchasing.

**Known limitations:**
- No plant-specific Core ML model is bundled. A reproducible Create ML training workflow is documented in `CORE_ML_GUIDE.md`; until a model is added the app runs in labelled demo mode.
- The browser preview and native app keep separate local datasets; there is no synchronisation.
- Native build, UI tests, notifications and inference require macOS/Xcode and have not been executed in the Windows development environment.
