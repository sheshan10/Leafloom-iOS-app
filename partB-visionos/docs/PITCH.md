# LeafLoom Spatial — pitch

**Grow with confidence. See where every plant will thrive before you move a single pot.**

## Value proposition

| For | Who | LeafLoom Spatial | Unlike |
|---|---|---|---|
| Houseplant owners with a Vision Pro | struggle to judge where each plant gets the right light | lets them arrange their own plants life-size in their room and shows, per plant, whether the spot suits it | phone care apps (one spot at a time, flat screen) and AR furniture apps (fit, not health) |

Benefits:
- **Fewer losses.** Placement mistakes are caught before they cost a plant.
- **Less guesswork.** Each plant says why a spot is good or poor, and which way to move it.
- **One collection everywhere.** The same plants and care history as the iPhone app (planned sync).

## Target market

**Primary:** Vision Pro owners who keep houseplants, especially people furnishing or redesigning a room.

**Secondary:**
- Interior designers and home stagers who want to show clients plant arrangements.
- Plant shops and nurseries that want a "see it in your room" experience.

**Sizing approach.** We have not included market-size figures, because none were verified for this
assignment. To size the market, multiply:
1. Vision Pro installed base (from analyst estimates; cite the source and date),
2. the share of households with houseplants (from a national survey; cite it),
3. an expected adoption rate (state the assumption).

Present this as a range with sources rather than a single number.

**Why now.**
- visionOS gives windows, volumes and immersive spaces with hand-tracked gestures. Life-size,
  in-room placement is native to the platform, where on a phone it is a workaround.
- Houseplant ownership and care apps are established categories, as the competitor review shows.

## Revenue model (proposal)

| Tier | Price (proposed, to validate) | Includes |
|---|---|---|
| **Free** | £0 | Up to 5 plants, room layout, light estimate, care cards. |
| **LeafLoom Plus** | one-off unlock, or a low annual subscription | Unlimited plants, multiple rooms, sync with the iPhone app, saved layouts per season. |
| **Pro / Business** | per-seat subscription | For designers and shops: client rooms, branded plant catalogues, export of layouts. |

Principles:
- No ads.
- No selling of user data. Room layouts never leave the device unless the user turns on sync.

Validation: test a one-off price against a subscription with early users. Competitors mostly use
subscriptions, so a fair one-off unlock may convert well with Vision Pro owners.

Partnership revenue (later): nurseries pay to list plants that users can preview in their room,
clearly labelled as sponsored.

## Go-to-market

**1. Prototype (this assignment).**
- Build the visionOS prototype in Xcode.
- Record a simulator walkthrough.
- Gather feedback from 5–10 plant owners using the Windows/browser 2D simulation, since few testers will own a headset.

**2. Beta.**
- Run a TestFlight beta for Vision Pro owners, recruited through plant-care and Vision Pro communities (Reddit, Discord, local plant swaps).
- Measure: plants placed per session, moves made after a "poor light" warning, and 2-week retention.

**3. Launch.**
- Launch on the visionOS App Store alongside the iPhone app. Lead with a short video of a plant turning from "poor" to "great" as it is dragged toward the window.
- Pitch to Apple's App Store editorial team for visionOS features.

**4. Partners.**
- Pilot with one or two independent plant shops: an in-store Vision Pro demo, plus a QR code that adds the plant to the customer's LeafLoom collection.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Small headset installed base | The iPhone app is the main product. Spatial is a premium add-on, and its logic is shared and already shown in the browser preview. |
| Light estimate is too simple | Label it as an estimate (done). Next, add ARKit light estimation and optional lux readings. |
| Competitors add spatial features | Move fast on care-in-context and iPhone sync. Own the "will it thrive here?" question. |
| Comfort and accessibility in immersive mode | Mixed immersion only, floor-bound plants, and button alternatives for every gesture. VoiceOver labels on entities. |

## Ask (for the assignment pitch)

Feedback on the core question: **would seeing light fit in your own room change where you put your
plants?**
