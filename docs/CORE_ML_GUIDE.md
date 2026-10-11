# Core ML Guide — adding a real plant classifier to LeafLoom

LeafLoom is built so that a Core ML image classifier can be dropped in **without changing any code**.
This repository does **not** include a trained model, so the app runs in a clearly labelled **demo mode**
until you add one. No accuracy figures are claimed anywhere in this project, because none have been measured.

---

## 1. How identification works in the app

```
IdentifyView ──► IdentificationViewModel ──► PlantIdentifying (protocol)
                                               ├─ CoreMLPlantIdentificationService  (Vision + Core ML)
                                               └─ DemoPlantIdentificationService    (no analysis, labelled demo)
                                   │
                                   ▼
                          LabelMapper ──► plantKnowledge.json (care guidance)
                                   │
                                   ▼
                     IdentificationRepository (history in Core Data)
```

- At launch, `AppEnvironment.makeIdentifier` looks for `LeafLoomPlantClassifier.mlmodelc` in the app bundle.
  - **Found and loads** → `CoreMLPlantIdentificationService` (mode `.model(name:)`).
  - **Missing or fails to load** → `DemoPlantIdentificationService` (mode `.demo`).
- The photo is downsampled to 1024 px (`ImageStore.downsample`) and passed to Vision as a `CGImage`.
  `VNCoreMLRequest` uses `.centerCrop`, runs on a detached task (off the main actor), and the top 5
  labels with confidence > 0.01 are returned.
- `LabelMapper` normalises each label (case, `_`, `-`, whitespace) and matches it against the knowledge
  base's `key`, `commonName`, `scientificName` and `aliases`. Unmatched labels still appear, using a
  human-readable version of the label and the note "not in LeafLoom's care library yet".
- Each run is saved as an `IdentificationRecord` (label, model identifier, demo flag, optional photo).
  Confidence is stored **only** for real model results.

### What the user sees

| Situation | UI behaviour |
| --- | --- |
| Demo mode | Amber "Demo identification" banner and badge. No percentage is shown anywhere. |
| Model, confidence ≥ 40 % | Suggested plant + "NN % model confidence" pill, alternatives with percentages. |
| Model, confidence < 40 % | Extra "Low confidence — compare the alternatives" warning (`IdentificationResultView.lowConfidenceThreshold`). |
| No usable result | "LeafLoom couldn't recognise a plant in this photo…" (`IdentificationError.noResults`). |

"Save to My Plants" opens the Add Plant form **pre-filled** for review. Model results are saved with the
status *AI suggestion*; demo results with *Not identified*. The user can change anything before saving.

---

## 2. Option A (recommended): train with Create ML on the Mac

Create ML is part of Xcode (Xcode ▸ Open Developer Tool ▸ Create ML). It runs entirely on the Mac.

### 2.1 Prepare the dataset

Use one folder per label. **Name the folders with the knowledge-base keys** so every prediction maps to
care guidance automatically (aliases and common names also work, see `LabelMapper`).

```
PlantDataset/
  Training/
    monstera_deliciosa/        img_0001.jpg …
    dracaena_trifasciata/   …
    epipremnum_aureum/         …
    …
  Testing/
    monstera_deliciosa/        (different photos from Training)
    …
```

The current keys are listed in `windows-preview/src/data/plantKnowledge.json` (copied into
`native-ios/LeafLoom/Resources/plantKnowledge.json` by `npm run native-assets`). To support more plants,
add entries there first, then re-run `npm run native-assets` in `windows-preview/`.

Guidelines:

- Apple's Create ML documentation recommends **at least 10 images per label**; in practice, more and
  more varied photos (different light, angles, pots, backgrounds, growth stages) usually help.
- Keep classes roughly balanced and keep test photos separate from training photos.
- Only use images you are **allowed** to use (see §4).

### 2.2 Train

1. Create ML ▸ **New Document** ▸ **Image Classification**. Name it `LeafLoomPlantClassifier`.
2. Drag `Training/` into **Training Data**. Leave **Validation Data** on *Automatic* (or supply a folder).
3. Drag `Testing/` into **Testing Data**.
4. Choose the newest **Feature Extractor** offered by your Xcode version (Image Feature Print).
5. Optional **Augmentations** (flip, rotate, crop, blur, noise, exposure) for small datasets.
6. Click **Train**. When it finishes, open the **Evaluation** tab and review per-class precision/recall
   on the *Testing* set. Use the **Preview** tab to try your own photos.

> Record the metrics you actually observe in `docs/TEST_PLAN.md` if you want to report them.
> Do not quote numbers you have not measured.

### 2.3 Export into the project

1. In the **Output** tab, click **Get** and save as **`LeafLoomPlantClassifier.mlmodel`**.
2. Copy the file to **`native-ios/LeafLoom/Resources/`**.
   The project uses *synchronized folders*, so Xcode adds it to the LeafLoom target automatically and
   compiles it to `LeafLoomPlantClassifier.mlmodelc` at build time. (If you use the XcodeGen fallback,
   re-run `xcodegen` after adding the file.)
3. Build and run. Check that:
   - Settings ▸ *Plant identification* shows **On-device model**.
   - The Identify tab no longer shows the demo banner.
   - About ▸ *About identification* names the model.

The filename matters: `CoreMLPlantIdentificationService.defaultModelName` is `LeafLoomPlantClassifier`.

---

## 3. Option B: convert an existing PyTorch / TensorFlow model

If you already have a trained classifier, convert it with Apple's `coremltools` (Python, on the Mac).
Match the preprocessing (input size, scale, per-channel bias) to how the model was trained.

```python
import coremltools as ct
import torch

model = load_your_trained_model()        # e.g. a torchvision MobileNet fine-tuned on your labels
model.eval()
example = torch.rand(1, 3, 224, 224)
traced = torch.jit.trace(model, example)

labels = ["monstera_deliciosa", "dracaena_trifasciata", "epipremnum_aureum"]  # same order as training

mlmodel = ct.convert(
    traced,
    inputs=[ct.ImageType(name="image", shape=example.shape, scale=1 / 255.0, bias=[0, 0, 0])],
    classifier_config=ct.ClassifierConfig(labels),
    minimum_deployment_target=ct.target.iOS17,
)
mlmodel.save("LeafLoomPlantClassifier.mlpackage")
```

Copy `LeafLoomPlantClassifier.mlpackage` into `native-ios/LeafLoom/Resources/`. Xcode compiles an
`.mlpackage` to `.mlmodelc` as well. The model **must be a classifier** (Vision returns
`VNClassificationObservation`s); otherwise the service reports "Identification failed".

If the model was trained with ImageNet normalisation, fold the mean/std into `scale`/`bias` (or add a
normalisation layer before tracing) — otherwise predictions will be poor.

---

## 4. Datasets and licensing

| Source | Notes |
| --- | --- |
| **Your own photos** | Simplest licensing. Photograph each plant in several conditions. |
| **Pl@ntNet-300K** | Research dataset of plant images. Listed as **CC BY 4.0 — verify before use**: check the current licence, attribution requirements and per-image terms on the official dataset page before training or distributing a model. |
| **iNaturalist / other community photos** | Licences vary per photo (some are non-commercial or all-rights-reserved). **Verify every image's licence** and keep attribution records. |

Rules for this project:

- Never put a dataset inside the app bundle — only the trained model.
- Add any dataset or model you use to `docs/ASSET_ATTRIBUTION.md` with its licence and source.
- If the licence is unclear, don't use it.

---

## 5. Testing the integration

Automated (XCTest, `LeafLoomTests`):

- `LabelMapperTests` — normalisation, alias/scientific-name matching, unknown labels.
- `DemoIdentificationServiceTests` — deterministic output, never a confidence, `.demo` mode.
- `IdentificationRepositoryTests` — demo results are stored without a confidence.

Manual (with a model installed):

1. Identify each sample photo from the Identify tab; note the top label and confidence.
2. Try a non-plant photo — expect low confidence or "couldn't recognise".
3. Save a result to My Plants and confirm the form is pre-filled and the status is *AI suggestion*.
4. Turn on VoiceOver and confirm confidence is announced as "Model confidence NN percent".

---

## 6. Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| Still in demo mode after adding the model | Wrong filename, file not in `LeafLoom/Resources/`, or not in the LeafLoom target. Clean build folder (⇧⌘K). |
| "The identification model couldn't be loaded" | Model targets a newer iOS than the device/simulator, or is corrupted. Re-export with an iOS 17 target. |
| "Identification failed" | The model isn't an image classifier, or its input isn't an image. |
| Predictions never get care info | Labels don't match knowledge keys/aliases — rename training folders or add aliases to `plantKnowledge.json`. |
| Very low confidence for everything | Preprocessing mismatch (Option B) or too little / too uniform training data. |
