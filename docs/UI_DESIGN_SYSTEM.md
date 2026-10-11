# LeafLoom UI Design System

LeafLoom aims for a **premium, calm, botanical** look. It should feel natural and trustworthy, not like a generic template. The same tokens are used in two places:

| Where | File(s) |
|---|---|
| Native SwiftUI app | `native-ios/LeafLoom/Core/DesignSystem/` (`LeafColor.swift`, `LeafTypography.swift`, `LeafSpacing.swift`, `LeafMotion.swift`) and the colour sets in `Assets.xcassets` |
| Windows browser preview | `windows-preview/src/styles/tokens.css` |

Components must use tokens, never raw hex values. If you change a value, change it in both places.

## 1. Brand

- **Name:** LeafLoom. A leaf plus a loom: care routines woven together.
- **Tagline:** "Grow with confidence."
- **Brand mark:** a single leaf whose midrib and veins are drawn as an interlaced weave (`windows-preview/public/illustrations/brand-mark.svg`).
- **App icon:** a forest-green gradient tile with a sage leaf and a small amber "sun" dot (`app-icon.svg`, rasterised to a 1024 × 1024 PNG for `AppIcon.appiconset`).

## 2. Colour

### Brand palette (theme-independent)

| Token | Hex | Use |
|---|---|---|
| Forest | `#214E3D` | Primary actions and brand surfaces (light mode) |
| Deep | `#17382E` | Pressed states, deep gradients |
| Leaf | `#75A77A` | Accents, chart series, progress |
| Sage | `#B8CDB6` | Illustrations, soft fills |
| Cream | `#F7F5EF` | Light background |
| Amber | `#DDAA52` | "Due today" and warnings, sunlight motif |
| Terracotta | `#C7794F` | Pots, warm illustration accents, chart series |

### Semantic tokens

| Token | Light | Dark |
|---|---|---|
| background | `#F7F5EF` | `#0E1A16` |
| surface | `#FFFFFF` | `#15251F` |
| surface-alt | `#EEF2EA` | `#1C3029` |
| text | `#242B27` | `#ECF1EA` |
| text-secondary | `#5E6A61` | `#A9B8AC` |
| text-tertiary | `#646F67` | `#84958A` |
| border | `#E1E6DD` | `#2A4037` |
| primary | `#214E3D` | `#8FC495` |
| on-primary | `#FFFFFF` | `#0E1A16` |
| danger | `#B3261E` | `#F2726B` |
| success | `#24653D` | `#7CCB91` |
| amber-text (on amber-soft) | `#7A5410` | `#F0CD8C` |

The dark theme is **designed, not inverted**. It uses deep botanical greens instead of neutral grey, and the primary colour moves to a lighter leaf green so it keeps enough contrast.

### Contrast (WCAG 2.1)

These ratios were computed with the WCAG relative-luminance formula in a Node script during development (see `docs/DEVELOPMENT_REPORT.md`). AA requires 4.5:1 for body text and 3:1 for large text and UI components.

| Pair | Light | Dark |
|---|---|---|
| text / background | 13.29 | 15.57 |
| text / surface | 14.48 | 13.93 |
| text-secondary / surface | 5.66 | 7.70 |
| text-tertiary / surface | 5.23 | 5.05 |
| on-primary / primary | 9.45 | 8.91 |
| danger / surface | 6.54 | 5.62 |
| amber-text / amber-soft | 5.68 | 8.51 |

Two light-mode values originally failed AA: tertiary text at 3.68:1 and success text at 4.42:1. They were darkened to the values shown above. Status is never shown by colour alone. Every status badge also has a text label and an icon.

## 3. Typography

| Style | Native | Preview size | Use |
|---|---|---|---|
| Large title | `.largeTitle`, `.serif` design (New York) | 34 | Screen titles, plant names on the hero |
| Title / Title 2 / Title 3 | `.title`, `.title2`, `.title3` | 28 / 22 / 20 | Section and card titles |
| Headline | `.headline` | 17 semibold | Row titles |
| Body | `.body` | 17 | Content |
| Callout / Subheadline | `.callout`, `.subheadline` | 16 / 15 | Secondary content |
| Footnote / Caption | `.footnote`, `.caption` | 13 / 12 | Metadata, badges |

- Native text uses only semantic text styles, so **Dynamic Type** scales everything, including accessibility sizes. Layouts switch from `HStack` to `VStack` at accessibility sizes using `ViewThatFits` / `dynamicTypeSize.isAccessibilitySize`.
- Large titles use the system serif (New York) for an editorial, botanical feel. Everything else uses SF Pro.
- The preview simulates Dynamic Type with `--type-scale` (Small 0.88, Default 1, Large 1.18, XL 1.35).

## 4. Spacing, radius and sizing

- **Spacing scale (pt):** 4, 8, 12, 16, 24, 32, 48 (`LeafSpacing.xxs … xxxl`).
- **Radii:** 8 (chips), 12 (inputs, small cards), 18 (cards), 26 (hero, sheets), plus pill.
- **Touch targets:** at least 44 × 44 pt.
- **Controls:** 50 pt primary button height.
- **Icons:** 16, 20 or 24 pt.
- **Tab bar:** 64 pt plus the safe area.

## 5. Elevation

Shadows are soft and green-tinted in light mode (`0 4 14 rgba(23,56,46,0.06)`). Dark mode mostly relies on surface tone rather than shadow. Cards use the `.leafCard()` ViewModifier natively and the `.card` class in the preview.

## 6. Components

| Component | Native | Preview |
|---|---|---|
| Primary / secondary / ghost / destructive buttons | `PrimaryButtonStyle`, `SecondaryButtonStyle` (custom `ButtonStyle`), `.destructive` role | `Button.tsx` |
| Card | `.leafCard()` ViewModifier | `Card` in `Layout.tsx` |
| Plant card / row | `PlantCardView`, `PlantRowView` | `PlantCard.tsx` |
| Progress ring | `ProgressRing` (custom `Shape` + animatable trim) | `ProgressRing.tsx` |
| Statistic card | `StatisticCard` | `StatisticCard.tsx` |
| Care task row | `CareTaskRow` (check button with symbol effect) | `CareTaskRow.tsx` |
| Status badge | `StatusBadge` (icon + text + colour) | `StatusBadge.tsx` |
| Search bar / filter chips | `.searchable` + `FilterChip` | `SearchBar.tsx` |
| Empty / error / loading | `EmptyStateView`, `ErrorStateView`, `LoadingView` (sprout animation), `.shimmer()` | `States.tsx` |
| Tab bar | `CustomTabBar` with a raised central Identify button | `TabBar.tsx` |
| Toast with Undo | `ToastView` overlay | `Toast.tsx` |
| Sheet | `.sheet` with detents | `Sheet.tsx` (focus-trapped) |
| Confirmation | `.confirmationDialog` | `ConfirmDialog.tsx` (`alertdialog`) |

## 7. Iconography and illustration

- **Native:** SF Symbols, plus template-rendered category icons generated from `windows-preview/src/data/categoryIcons.json` by `scripts/generate-native-assets.mjs`.
- **Preview:** Lucide icons (ISC licence), plus the same category icon JSON.
- **Illustrations** (onboarding, empty states) are original SVGs drawn for this project in the brand palette. Their flat, rounded style uses leaf, pot and sun motifs.
- **Photos:** AI-generated sample plant photos (see `ASSET_ATTRIBUTION.md`).

## 8. Motion

| Token | Duration | Use |
|---|---|---|
| fast | 150 ms | Press feedback, chip toggles |
| base | 250 ms | Sheet and toast transitions, task completion |
| slow | 420 ms | Screen transitions, ring progress, onboarding |

- Native code uses spring animations (`.spring(response: 0.35, dampingFraction: 0.8)`), `matchedGeometryEffect` for the plant card to the details hero, `symbolEffect` on completion, and `PhaseAnimator` for the loading sprout.
- **Reduce Motion:** native code checks `accessibilityReduceMotion` and swaps movement for cross-fades. The preview zeroes every duration when `prefers-reduced-motion` or the dev panel toggle is on.
- Motion always confirms an action or shows hierarchy. Nothing loops forever except loading indicators.

## 9. Accessibility checklist

- Every icon-only button has an accessibility label, for example "Add plant" or "Edit Monty".
- Plant cards are combined into one accessibility element with name, category and next-care summary.
- The task check button is announced as a checkbox with its state ("Mark Water Monty as done").
- Charts have an `accessibilityLabel` summary plus a text alternative list.
- Form errors are announced (`role="alert"` / `.accessibilityAddTraits`), and focus moves to the first invalid field.
- Visible focus rings are shown in the preview (`--focus-ring`).
- Colour is never the only status indicator.
