# LeafLoom — User Guide

_Grow with confidence._ LeafLoom keeps your plant collection, care schedule and growth journal in
one place, on your iPhone. It works offline and needs no account.

> Screenshots in `docs/screenshots/preview/` come from the Windows browser preview, which mirrors the
> iPhone app's screens. The browser preview simulates plant identification and reminders.

## Getting started

When you first open LeafLoom, four short pages welcome you and introduce collections, plant
identification and reminders. Tap **Skip** at any time. To see them again, go to Settings → **Replay onboarding**.

The app starts with eight sample plants (Monty the Swiss cheese plant, Basil, and others), so you
can explore straight away. Sample plants have a **Sample** badge. To remove them, go to Settings →
**Erase all data**. To bring them back, use **Reset to sample data**.

The tab bar has five tabs: **Home**, **My Plants**, **Identify**, **Care** and **Insights**. Tapping
the tab you are already on takes you back to its first screen.

## Home

- A greeting and a progress ring show how much of this week's care is done.
- **Today** lists tasks that are due or overdue. Tap the circle to mark one done, then **Undo** if that was a mistake.
- **Upcoming** shows the next 7 days.
- **Needs attention** shows plants with overdue care.
- The gear button opens **Settings**.

## My Plants

- **Search** by name, common name, scientific name or tag.
- **Filter** by category, location or favourites, and **sort** by Recently added, A–Z or Next care.
- Switch between the **grid** and **list** layouts in Settings.
- Tap the heart to make a plant a favourite.
- Tap **+** to add a plant.

### Adding or editing a plant

- **Required:** a name and a category.
- **Optional:** common and scientific names, a photo (from your library, or the camera on a real iPhone), location, acquisition date, light, humidity, soil, notes and tags.
- If you set a watering or fertilising interval, LeafLoom creates a repeating care task for it.
- Mistakes are shown under the field they apply to, such as a missing name or an interval outside 1–365 days.
- If you close a form with unsaved changes, LeafLoom asks before throwing them away.

### Plant details

The details screen shows:
- the next care tasks, with **Add task**,
- the care profile,
- recent care history,
- a journal preview,
- notes and tags.

Use **Edit** to change the plant. **Delete plant** asks for confirmation and tells you how many
tasks and journal entries will be removed with it.

## Identify

1. Choose a photo from your library, take one (real iPhone only), or tap a sample photo.
2. Tap **Identify**.
3. Review the suggestion and its general care tips, or pick one of the alternatives.
4. Tap **Save to My Plants**. The add-plant form opens prefilled; check it, then save.

**Demo mode.** If no Core ML model is installed, a **Demo identification** banner appears. Demo
results only show how the feature works: they are not a real identification and never show a
confidence score.

**With a model installed**, results show a confidence level. Below 40% you will see a
low-confidence warning. Even confident suggestions can be wrong, so always check before relying on
one.

Previous identifications appear under **History**. Long-press one to delete it.

## Care

- The segments are **Upcoming**, **Overdue**, **Completed** and **All**. The Overdue segment shows how many tasks are late.
- Tasks are grouped by day.
- Swipe a task to mark it done, undo, edit or delete it.
- **Repeating tasks:** when you complete one, the next occurrence is scheduled from the day you completed it, at the same time of day. Completing late never piles up a backlog.
- Tap a task to see its details and the history of that repeating series.

### Reminders

Go to Settings → **Reminders** to allow notifications, turn reminders on or off, and choose the
time of day (6:00–22:00). Each open task gets one reminder on its due date. If you denied
permission earlier, LeafLoom shows a button that opens the system Settings.

## Growth journal

Open it from a plant's details (**Open journal**). For each entry:
- **Required:** notes.
- **Optional:** a photo and a height in centimetres. Dates cannot be in the future.

With two or more photos, a **before/after** slider compares the first and the latest. Drag the
slider, or with VoiceOver swipe up and down to adjust it. Height entries add up to a growth
summary, such as "Grew 12 cm across 4 measurements".

## Insights

Charts show:
- weekly care completion,
- the mix of care types,
- plants by category,
- plants added per month.

Each chart has a spoken summary for VoiceOver.

## Settings

| Setting | What it does |
|---|---|
| Theme | System, Light or Dark |
| Collection layout | Grid or List |
| Reminders | Permission, on/off and reminder time |
| Replay onboarding | Shows the introduction again |
| Reset to sample data | Replaces everything with the eight sample plants (asks first) |
| Erase all data | Permanently deletes all plants, tasks, journal entries, identifications and photos (asks first) |
| About LeafLoom | Privacy, how identification works, care disclaimer, credits |

## Accessibility

LeafLoom supports:
- VoiceOver,
- Dynamic Type, including the largest accessibility sizes,
- Dark Mode,
- Reduce Motion, which turns off decorative animation.

Status is always shown with text and an icon, not colour alone.

## Privacy

Your plants, photos and journal stay on your device. LeafLoom has no account, no analytics and no
server. Identification with a model runs entirely on device.

## Care disclaimer

Care tips are general guidance, not expert advice. Plants vary, so watch how yours respond.
Identification suggestions can be wrong; never use them to decide whether a plant is safe to eat
or safe for pets.

## LeafLoom Spatial (Apple Vision Pro prototype)

1. Pick a plant in the window to see its care card. **View in 3D** opens it on a turntable.
2. **Arrange in my room** places your plants life-size on the floor.
3. Drag the translucent window marker to where your real window is.
4. Move plants around. Each tag shows whether that spot's estimated light suits the plant. The estimate is based only on distance from the window marker.

See `partB-visionos/README.md`.
