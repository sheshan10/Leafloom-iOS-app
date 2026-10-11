# Asset Attribution

Every visual asset, dataset and third-party library used by LeafLoom is listed below with its origin and licence. Nothing was copied from other apps or websites.

## 1. Images and illustrations

| Asset | Location | Origin | Licence / terms |
|---|---|---|---|
| Sample plant photos (monstera, snake plant, pothos, fiddle-leaf fig, peace lily, aloe vera, basil, calathea), 1024 × 768 JPEG | `windows-preview/public/images/plants/`, copied to `native-ios/LeafLoom/Resources/Assets.xcassets/SamplePhotos/Sample*.imageset` | **AI-generated** for this project with the image-generation tool built into Cursor (October 2026). Prompts described a photorealistic potted plant on a neutral background. No real photographs or third-party images were used as input. | Created for this coursework. They are labelled as sample/demo content in the app (the "Sample" badge on sample plants). They are not photographs of real specimens and must not be used as botanical references. |
| Brand mark (`brand-mark.svg`) | `windows-preview/public/illustrations/` | Original vector artwork written by hand as SVG code for this project | Original work for this assignment |
| App icon (`app-icon.svg` → `AppIcon-1024.png`) | same, plus `AppIcon.appiconset` | Original vector artwork; the PNG is rasterised locally with Playwright/Chromium by `scripts/generate-native-assets.mjs` | Original work |
| Onboarding illustrations (`onboarding-*.svg`) | same | Original SVG code | Original work |
| Empty-state illustrations (`empty-*.svg`) | same | Original SVG code | Original work |
| Category icons (`categoryIcons.json`) | `windows-preview/src/data/` → generated template SVGs in `Assets.xcassets/Category*.imageset` | Original 24 × 24 stroke drawings | Original work |
| SF Symbols | Native app only | Apple | Used under the Xcode / Apple SDK licence. Only allowed inside apps for Apple platforms, which is how they are used here. |
| Lucide icons | Preview only (`lucide-react`) | [lucide.dev](https://lucide.dev) | ISC licence |

## 2. Plant care content

`plantKnowledge.json` (14 species) contains short, general care summaries written for this project from widely known houseplant guidance. It is **not** taken from a specific copyrighted source. The app shows the file's disclaimer: guidance is general, conditions vary, and toxicity or plant-health concerns should be checked with a qualified source.

## 3. Machine-learning dataset and model

**No trained model is included in this repository.** No dataset was downloaded during development.

`docs/CORE_ML_GUIDE.md` describes how to train `LeafLoomPlantClassifier.mlmodel` with Create ML. The candidate dataset it names is:

| Dataset | Reported licence | Status |
|---|---|---|
| Pl@ntNet-300K (Garcin et al., NeurIPS Datasets & Benchmarks 2021), hosted on Zenodo | CC BY 4.0 (as stated on the dataset's Zenodo record) | **Verify before use.** Check the licence and attribution requirements on the official record at the time you download it, and record the exact version/DOI here. |

If a model is trained, add a row here for it with the training date, dataset version, class list and evaluation results produced by Create ML. Do not report accuracy figures that were not actually measured.

## 4. Software libraries

### Native app

Apple system frameworks only: SwiftUI, Core Data, Core ML, Vision, PhotosUI, UserNotifications, Charts, XCTest, and RealityKit (Part B). No third-party packages.

### Windows preview (npm)

Exact versions are in `windows-preview/package-lock.json`.

| Package | Licence | Use |
|---|---|---|
| react, react-dom | MIT | UI |
| idb | ISC | IndexedDB wrapper |
| recharts | MIT | Insights charts |
| lucide-react | ISC | Icons |
| vite, @vitejs/plugin-react | MIT | Dev server and build |
| typescript, typescript-eslint | Apache-2.0 / MIT | Type checking and linting |
| eslint and plugins | MIT | Linting |
| vitest, jsdom, fake-indexeddb | MIT / MIT / Apache-2.0 | Unit tests |
| @testing-library/* | MIT | Component tests |
| @playwright/test | Apache-2.0 | End-to-end tests, screenshots, icon rasterising |

## 5. Fonts

None are bundled. The native app uses the system fonts (SF Pro, New York). The preview falls back to the local system fonts (`ui-serif`, Segoe UI and others).
