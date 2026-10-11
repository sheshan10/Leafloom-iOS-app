# LeafLoom Spatial — concept

> Part B prototype for SE4041 Assignment 02. Platform: **visionOS 2** (Apple Vision Pro).
> Status: source written on Windows; **not yet built or run** — see "Verification" below.

## The problem

Most houseplant problems come from where the plant lives, not how it is watered. People put a
sun-loving aloe in a dim corner, or a calathea next to a hot window, because a flat phone screen
cannot show *where in the room* the light is. LeafLoom on iPhone tracks care; it cannot see the room.

## The idea

LeafLoom Spatial puts your plant collection into your actual room. You mark where your window is,
then drag life-size plants around the floor. Each plant tells you, in place, whether that spot suits
it — before you move a real pot.

## Experience

| Scene | visionOS type | What it does |
|---|---|---|
| Garden window | `WindowGroup` | Plant list with a light-fit badge, a care card (preferred light, estimated light here, advice, next watering, tip), "View in 3D" and "Watered today". An ornament holds "Arrange in my room", "Reset layout" and a count of plants needing water. |
| Planter volume | `WindowGroup` + `.volumetric` | One plant on a turntable. Drag to spin, pinch to zoom; VoiceOver users can adjust rotation. A compact care card sits in an ornament below. |
| Room | `ImmersiveSpace`, mixed immersion | All plants stand on the real floor. Drag to move, two-hand rotate around the vertical axis, pinch to scale (0.5×–2×). Tap to select; the selected plant's tag expands into a care card. A translucent window marker can be dragged to match the real window, and floor rings show the light zones. |

## Light estimate

`LightZone.estimate(distanceFromWindow:)` maps floor distance to the window marker to a zone:

| Distance | Zone |
|---|---|
| < 0.6 m | Full sun |
| 0.6 – 1.5 m | Bright indirect |
| 1.5 – 3.0 m | Medium |
| ≥ 3.0 m | Low |

`LightFit` compares that with the plant's preference: same zone = great, one step away = acceptable,
further = poor, with "move closer / further from the window" advice.

**This is a heuristic, not a measurement.** It ignores window orientation, season, time of day,
curtains and obstructions. The UI labels it "Here (estimate)". A production version could use
ARKit's environment light estimation or the user's own lux readings; neither is in this prototype.

The 2D "Spatial (Part B)" tab in the Windows browser preview
(`windows-preview/src/features/spatial/SpatialPreview.tsx`) uses the same four zones and the same
fit rule on a normalised floor plan, so the concept can be demonstrated without a headset. The zone
boundaries there are fractions of the room width, not metres.

## Design decisions

- **Procedural plants.** Plants are built from RealityKit primitives (cylinders, spheres, boxes,
  cones) in `PlantEntityFactory`. There are no downloaded USDZ models, so there are no licensing
  questions. Each plant's shape is seeded from its UUID, so it looks the same every launch.
- **Shared sample data.** The eight sample plants match the iPhone app's seed data (Monty, Sunny,
  Goldie, Figgy, Lily, Aloe, Basil, Orbi).
- **Local only.** Layout, window position and watering dates persist in `UserDefaults`. No account,
  network or camera access. Mixed immersion uses the system's passthrough; the app never reads
  camera frames.
- **Comfort.** Plants stay on the floor plane (`y ≥ 0`), scale is clamped, and tags use
  `BillboardComponent` so they face the user without needing to walk around.
- **Accessibility.** Plant entities carry `AccessibilityComponent` labels, tags combine into one
  VoiceOver element, the volume supports an adjustable rotation action, and every gesture-driven
  action also has a button in the window (select, water, reset).

## Architecture

```
LeafLoomSpatial/
  App/LeafLoomSpatialApp.swift      three scenes, shared GardenStore in the environment
  Model/SpatialPlant.swift          Sunlight, PlantShape, SpatialPlant (watering due logic)
  Model/LightZone.swift             LightZone + LightFit (pure, unit tested)
  Model/SampleGarden.swift          stable sample plants
  Model/GardenStore.swift           @Observable state, placements, persistence
  Rendering/PlantEntityFactory.swift procedural plants, window marker, fit ring, SeededGenerator
  Views/GardenWindowView.swift      main window + ornament
  Views/PlanterVolumeView.swift     volumetric turntable
  Views/RoomImmersiveView.swift     ImmersiveSpace, gestures, attachments
  Views/CareCardView.swift          care card, fit badge, watering line
LeafLoomSpatialTests/               XCTest: light zones, fit, sample data, store, persistence
```

Gestures update the store with `persist: false` while moving and call `commitLayout()` once when
they end, so dragging does not write to disk every frame.

## Verification

Nothing in this folder has been compiled. It was written against the visionOS 2 SDK
documentation on a Windows machine with no Xcode. On a Mac with Xcode 16 or later and the visionOS
simulator, run:

```bash
cd partB-visionos
xcodebuild -project LeafLoomSpatial.xcodeproj -scheme LeafLoomSpatial \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build test
```

or use `scripts/verify-native.sh` from the repository root, which runs this after the iOS checks.
Record the real output in `docs/TEST_PLAN.md`.

## Limitations and next steps

- The light estimate is distance-only (see above).
- The room has no plane detection; plants sit on the immersive-space floor at the origin's height.
  ARKit `PlaneDetectionProvider` with world anchors would let plants rest on real tables and
  shelves and stay put between sessions.
- No sync with the iPhone app yet. A shared Core Data + CloudKit store would let both apps see the
  same plants.
- The app has no visionOS icon (a layered image stack); it uses the system placeholder.
