# AI Usage Log

The SE4041 brief requires documenting AI-assisted development. This log records **actual** interactions only. Add a new row for every significant AI-assisted session.

## How to use this log

For each interaction record: the date, the tool, the prompt or task, what the AI produced, how you reviewed it, and what you changed yourself. Keep prompts verbatim or summarised faithfully; do not reconstruct conversations from memory.

## Log

| # | Date | Tool | Prompt / task | Generated assistance | Review performed | Developer changes |
|---|------|------|---------------|----------------------|------------------|-------------------|
| 1 | 2026-10-09 | Cursor (agent mode, Claude model) | "Master project prompt — LeafLoom": the full product specification (native SwiftUI app, Windows browser preview, Core ML, Core Data, docs). The developer's answers to clarifying questions: include Part B (visionOS "LeafLoom Spatial"); Core ML through a model-agnostic service with demo mode and a Create ML guide; a hand-written Xcode project with synchronized folders; and later, "dont use any git parts". | Implementation plan (`.cursor/plans/`, outside this folder). | Developer read the plan and accepted it. | Developer chose the Part B platform, the Core ML approach and the project format, and ruled out git. |
| 2 | 2026-10-09 | Cursor (agent mode, Claude model) | "Implement the plan as specified … Don't stop until you have completed all the to-dos." | Everything in this folder: <ul><li>documentation (`docs/`)</li><li>design tokens, original SVG illustrations, AI-generated sample photos</li><li>React/TypeScript/Vite preview with IndexedDB, Vitest and Playwright tests</li><li>asset generator script</li><li>native SwiftUI source: Core Data model, repositories, Core ML/Vision and demo services, PhotosUI and camera, notifications, Swift Charts, 84 unit and 7 UI tests</li><li>visionOS 2 prototype: RealityKit procedural plants, window, volume, immersive space, 12 unit tests</li><li>Part B concept, competitor and pitch docs</li><li>`scripts/verify-native.sh`</li></ul> | The agent ran these on Windows: `npm run lint`, `npx vitest run` (58 passed), `npm run build`, Playwright flows (5/5) and screenshots (15 images, inspected). It fixed six defects these checks found (`TEST_PLAN.md` §2). It cross-checked Swift asset names against the generated catalog, and syntax-checked `verify-native.sh` with `bash -n`. **Swift code not compiled** — no Xcode on Windows. | _Developer to complete: review notes, compile fixes made on the Mac, design changes._ |
| 3 | | | | | | |

## Reflection prompts (complete before submission)

- Which generated parts did you understand fully and could explain in the viva?
- Which parts did you rewrite, and why?
- What errors did the AI introduce that you had to fix on the Mac?
- How did you verify that generated assets are free to use (see `ASSET_ATTRIBUTION.md`)?
