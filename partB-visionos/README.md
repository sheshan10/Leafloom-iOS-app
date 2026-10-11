# LeafLoom Spatial (Part B — visionOS 2)

Arrange your LeafLoom plants life-size in your room and see which spots suit each one.

- **Concept and architecture:** [docs/CONCEPT.md](docs/CONCEPT.md)
- **Similar existing apps:** [docs/COMPETITORS.md](docs/COMPETITORS.md)
- **Pitch** (value proposition, market, revenue model, go-to-market): [docs/PITCH.md](docs/PITCH.md)

## Run (Mac only)

1. Requirements: Xcode 16 or later with the visionOS 2 SDK and simulator.
2. Open `LeafLoomSpatial.xcodeproj`, choose the **LeafLoomSpatial** scheme and an
   **Apple Vision Pro** simulator, then press Run.
3. In the window, choose **Arrange in my room**. In the simulator, drag with the pointer. For
   two-hand rotate and pinch, use the simulator's multi-touch input (see Xcode's visionOS simulator
   help), or adjust plants from the window.
4. Run the unit tests with ⌘U.

If the hand-written project does not open, regenerate it with XcodeGen:
`brew install xcodegen && xcodegen generate`.

**Status:** written on Windows and **not yet compiled or run**. Record real results in
`../docs/TEST_PLAN.md` after building on a Mac.

Without a Mac, the "Spatial (Part B)" tab in `../windows-preview` shows a 2D simulation that uses the
same light-zone logic.
