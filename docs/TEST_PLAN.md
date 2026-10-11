# LeafLoom — Test Plan and Results

This plan covers the Windows browser preview, the native iOS app and the Part B visionOS prototype.

**Honesty rule:** a result is only recorded here if the command was actually run. Anything not
yet run says **"Not run — needs Mac"**. Fill those in after running `scripts/verify-native.sh`
(see `WINDOWS_TO_MAC_GUIDE.md`).

---

## 1. Strategy

| Level | Native iOS (XCTest) | Browser preview | visionOS prototype |
|---|---|---|---|
| Pure logic (validation, recurrence, filters, statistics, label mapping) | Unit tests | Vitest | Unit tests (light zones, fit) |
| Persistence | In-memory Core Data store per test | Vitest with `fake-indexeddb` | A dedicated `UserDefaults` suite, cleared before and after each test |
| Services | `MockReminderScheduler`; deterministic demo identifier | — | — |
| UI flows | XCUITest with launch arguments (`-uiTesting -resetData -skipOnboarding`, `-emptyState`) | React Testing Library and Playwright (Chromium) | Manual in the simulator |
| User acceptance | Scripted UAT (section 5) with real users | Same script, on the preview | Same script, spatial tasks |
| Accessibility | Manual checklist (section 6) and Xcode Accessibility Inspector | Accessible queries in tests; keyboard checks | Manual |

The browser preview mirrors the native rules, so the same cases appear in both suites. For
example, both suites check that the next due date counts from the completion day, and that undo
deletes only an untouched spawned task.

---

## 2. Executed results — Windows browser preview

Environment: Windows 11 (10.0.26200), Node.js with npm, Vite 7.3.7, Vitest 5.0.3, Playwright Chromium.

Run on 9 Oct 2026, in `windows-preview/`, on the final code.

| Command | Result |
|---|---|
| `npm run lint` | **Pass** — ESLint reported no problems |
| `npx vitest run` | **Pass** — 8 test files, **58 tests passed**, 0 failed (≈7.4 s) |
| `npm run build` | **Pass** — `tsc` and Vite build. `index` JS 364.57 kB (112.24 kB gzip), `charts` JS 413.16 kB (119.53 kB gzip), CSS 55.93 kB (10.95 kB gzip) |
| `npx playwright test e2e/flows.spec.ts` | **Pass** — **5/5** end-to-end flows (15.5 s) |
| `npm run screenshots` | **Pass** — 3/3 specs. 15 PNGs written to `docs/screenshots/preview/`, each inspected by eye |

### Unit and component tests (Vitest)

| File | Tests | Covers |
|---|---|---|
| `src/utils/validation.test.ts` | 12 | Plant name, interval, date, notes and tag rules; care-task title, due date and recurrence; journal plant, notes, date and height |
| `src/utils/recurrence.test.ts` | 10 | Status classification, next due from completion day with time of day kept, month boundary, one-off and recurring completion, idempotence, both undo rules, task segments |
| `src/utils/filters.test.ts` | 8 | Search fields (case- and diacritic-insensitive), sorts, combined filters, distinct locations |
| `src/utils/stats.test.ts` | 6 | Empty state, weekly progress and attention, category counts, monthly additions, weekly completions, care mix |
| `src/data/sampleData.test.ts` | 9 | Seed integrity and determinism; label matching; simulated identifier is deterministic and never reports confidence; sample photo mapping |
| `src/data/repository.test.ts` | 5 | IndexedDB defaults, CRUD and reload, cascade delete that unlinks identifications, atomic task writes, seed and erase |
| `src/data/store.test.tsx` | 5 | Seeds once, add plant with schedule, complete and undo, cascade delete, erase and reset |
| `src/app/PhoneApp.test.tsx` | 3 | Onboarding into the dashboard, add-plant validation then details, simulated identification labelling |

### End-to-end flows (Playwright)

1. Onboarding completes and persists across reloads.
2. Add, edit, favourite and delete a plant; the data persists in IndexedDB.
3. Completing a care task can be undone.
4. Simulated identification is clearly labelled and can be saved.
5. Dark mode and the visionOS simulation are reachable from the dev panel.

### Defects found by testing (all fixed and re-verified)

| # | Found by | Defect | Fix |
|---|---|---|---|
| 1 | Playwright | App crashed after onboarding with "destroy is not a function". Current Chromium returns a Promise from `Element.scrollTo`, and an arrow-bodied `useEffect` returned it. jsdom returns `undefined`, so unit tests missed it. | Block-bodied effects in `Layout.tsx` |
| 2 | Screenshots | Filter panel always visible: CSS `display:flex` overrode the `hidden` attribute | `[hidden]{display:none !important}` |
| 3 | Playwright | Identify screen showed only 6 of 8 sample photos (Basil missing) | Show every sample with an image |
| 4 | Screenshots | Charts captured mid-animation; Recharts ignored the reduced-motion setting | Disable chart animation when reduced motion is on |
| 5 | Build | Empty `react` manual chunk | Removed |
| 6 | Asset script | ESM import of `@playwright/test` lost its named export | `createRequire` |

---

## 3. Native iOS — tests written, not yet run

**Status: Not run — needs Mac.** The Swift code was written on Windows without Xcode. It has not been compiled.

Run with:

```bash
./scripts/verify-native.sh ios
```

Then fill in the result column.

### Unit tests (`LeafLoomTests`, 84 tests)

| File | Tests | Covers | Result |
|---|---|---|---|
| `PlantValidatorTests` | 11 | Required name (after whitespace collapse), length limits, category, interval bounds, future date, notes, tags, care-task and journal validation | Not run — needs Mac |
| `RecurrenceAndStatusTests` | 12 | Next due from completion day, early completion, month boundary, undo rule, status boundaries, needs-attention, filters, Monday weeks, calendar days, relative-day text, greeting | Not run — needs Mac |
| `PlantQueryTests` | 5 | Search, filters, sorts, next-care index, distinct locations | Not run — needs Mac |
| `InsightsCalculatorTests` | 6 | Summary and weekly progress, empty state, category ordering, monthly additions, weekly trend, care mix | Not run — needs Mac |
| `IdentificationTests` | 11 | Knowledge base bundled, label normalisation and matching, unknown labels, prefill draft; demo never reports confidence; determinism; errors; sample-first ordering; mode matches whether a model is bundled | Not run — needs Mac |
| `ReminderAndImageTests` | 8 | Reminder fire-date rules (future day, before or after the preferred hour, overdue); image save/load/delete, downsampling, invalid data | Not run — needs Mac |
| `PlantRepositoryTests` | 7 | Create with validation and normalisation, schedules and reminders, image replacement, invalid update, favourite, cascade delete and cleanup | Not run — needs Mac |
| `CareTaskRepositoryTests` | 9 | Validation, general tasks, recurring spawn in the same series, one-off tasks, undo (untouched or edited spawn), reminder sync, reminders off, reschedule all | Not run — needs Mac |
| `JournalIdentificationMaintenanceTests` | 10 | Journal CRUD, validation, future entry rejected, ordering; identification history (demo without confidence, model with confidence); seeding, reset, erase | Not run — needs Mac |
| `FormViewModelTests` | 5 | Default reminder hour, suggested title, repeat toggle, plant form prefill and change tracking, identification prefill status | Not run — needs Mac |

### UI tests (`LeafLoomUITests`, 7 tests)

| Test | Checks | Result |
|---|---|---|
| `testOnboardingCanBeSkipped` | Skip reaches Home and the tab bar | Not run — needs Mac |
| `testTabsAreReachable` | All five tabs show their screen | Not run — needs Mac |
| `testAddPlantShowsValidationThenSaves` | Saving empty shows name and category errors; a valid plant saves and opens its details | Not run — needs Mac |
| `testCompletingATaskOffersUndo` | Completing a task shows Undo, and undo reopens the task | Not run — needs Mac |
| `testDemoIdentificationIsLabelledAndPrefillsForm` | Demo banner shown, no "%" shown, form prefilled with "Sweet basil" | Not run — needs Mac |
| `testEmptyStateLaunchArgument` | `-emptyState` shows the empty collection | Not run — needs Mac |
| `testDeletePlantAsksForConfirmation` | Delete requires confirmation, then the plant is removed | Not run — needs Mac |

**Expected first-run risk.** The UI tests depend on accessibility identifiers and system controls
(menus, confirmation dialogs) whose element types can differ between iOS versions. If a query
fails, check it with the Accessibility Inspector first, then decide whether the app or the test
needs fixing.

---

## 4. visionOS prototype — tests written, not yet run

**Status: Not run — needs Mac.** Run with:

```bash
./scripts/verify-native.sh visionos
```

| Suite | Tests | Covers | Result |
|---|---|---|---|
| `LightZoneTests` | 3 | Zone boundaries, floor-plane distance, fit and advice | Not run — needs Mac |
| `SampleGardenTests` | 3 | Stable unique ids, watering due, deterministic procedural seed | Not run — needs Mac |
| `GardenStoreTests` | 6 | Default floor layout, scale clamp and yaw normalisation, light changes on move, persistence across launches, uncommitted moves not saved, reset | Not run — needs Mac |

Manual simulator checks (fill in on the Mac):

| # | Step | Expected | Result |
|---|---|---|---|
| V1 | Launch, select Aloe | Care card shows preference, estimate, advice | |
| V2 | View in 3D | Volume opens; drag spins, pinch zooms | |
| V3 | Arrange in my room | Plants on the floor with tags; window marker visible | |
| V4 | Drag Aloe next to the window marker | Tag changes to "Great light match" | |
| V5 | Leave room, relaunch app, re-enter | Layout preserved | |
| V6 | Reset layout | Default arc restored | |

---

## 5. User acceptance tests (UAT)

Run with 3–5 real users (classmates or family) on the Mac simulator or a device. Use the browser
preview if no Mac is available, and record which one was used. Do not fill in results on users'
behalf.

| # | Scenario (task given to the user) | Acceptance criteria | Tester / date | Pass? | Notes |
|---|---|---|---|---|---|
| U1 | "Add your own plant called Fern with a 7-day watering schedule." | Done in under 2 minutes without help; plant appears with a watering task | | | |
| U2 | "Find all plants in the Living room." | Uses search or filter correctly | | | |
| U3 | "Water today's plants, then undo one by mistake." | Task completes; undo restores it | | | |
| U4 | "Identify the basil sample photo and save it." | User notices the demo label; plant saved with review status | | | |
| U5 | "Add a journal entry with a height for Monty." | Entry appears in the timeline; growth summary updates | | | |
| U6 | "Turn on Dark Mode and make the text bigger." | Both work; nothing is clipped | | | |
| U7 | "Delete a plant." | Confirmation explains what will be removed; plant gone | | | |
| U8 | (visionOS) "Find a better spot for the aloe." | Moves it toward the window and sees the fit improve | | | |

Satisfaction question after the session (1–5): "How confident would you feel using LeafLoom to
look after your plants?" Record the answers.

---

## 6. Accessibility checklist (manual, on the Mac)

| Check | How | Result |
|---|---|---|
| VoiceOver reads every control with a meaningful label | VoiceOver on simulator or device; swipe through each tab | |
| Status is not conveyed by colour alone | Overdue, due and fit states have text and icons | |
| Dynamic Type up to AX5 does not clip or overlap | Environment Overrides → Text size | |
| Dark Mode contrast is legible | Environment Overrides → Dark | |
| Reduce Motion disables decorative animation | Settings → Accessibility → Motion | |
| Tap targets are at least 44 × 44 pt | Accessibility Inspector audit | |
| Accessibility Inspector audit has no errors | Xcode → Open Developer Tool → Accessibility Inspector → Audit | |

---

## 7. Recording results

After running on the Mac:

1. Copy the summary printed by `verify-native.sh` (also in `verification-logs/<timestamp>/summary.txt`) into sections 3 and 4.
2. Note any compile errors you fixed, and add them to `AI_USAGE_LOG.md` under "Developer changes".
3. Keep the `.xcresult` bundles as evidence; Xcode opens them.
