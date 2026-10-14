# LeafLoom — User Guide

LeafLoom is a private iPhone app for houseplant owners. It keeps a plant collection, a care schedule, and a growth journal on the phone. It works offline and does not need an account.

## First open

Four short pages introduce the collection, plant identification, and reminders. Tap **Skip** at any time. To see them again, open **Settings** and choose **Replay onboarding**.

The app starts with eight sample plants, including a Swiss cheese plant and basil, so the screens are not empty. Sample plants are marked **Sample**. **Settings → Erase all data** removes them. **Settings → Reset to sample data** brings them back.

Five tabs sit at the bottom: **Home**, **My Plants**, **Identify**, **Care**, and **Insights**.

## Home

Home shows a greeting and a ring for how much of this week's care is done.

- **Today** lists tasks that are due or late. Tap the circle to mark one done, then **Undo** if that was a mistake.
- **Upcoming** shows the next seven days.
- **Needs attention** lists plants with overdue care.
- The gear icon opens Settings.

## My Plants

Search by name or tag. Filter by category, location, or favourites. Sort by recently added, A–Z, or next care. The layout is a grid or a list, chosen in Settings. Tap the heart to favourite a plant.

Tap **+** to add a plant. A name and a category are required. A photo, location, light, humidity, soil, notes, and watering or fertilising interval are optional. If an interval is set, LeafLoom creates a repeating care task. Intervals must be from 1 to 365 days. Closing a form with unsaved changes asks for confirmation.

Open a plant to see its next tasks, care profile, recent history, journal, notes, and tags. **Edit** changes the plant. **Delete plant** asks for confirmation and also removes that plant's tasks and journal entries.

## Identify

1. Choose a photo, take one with the camera on a real iPhone, or tap a sample photo.
2. Tap **Identify**.
3. Review the suggestion and the care tips, or choose another suggestion.
4. Tap **Save to My Plants**. The add-plant form opens already filled in. Check it, then save.

No trained model is included with the app, so Identify does not calculate a confidence score. After a Core ML model is added, results show a confidence level, and a result below 40% shows a low-confidence warning. Suggestions can be wrong. Do not use them to decide whether a plant is safe to eat or safe for pets.

Past identifications stay under **History**. Long-press one to delete it.

## Care

Tasks are split into **Upcoming**, **Overdue**, **Completed**, and **All**, and grouped by day. Swipe a task to complete, undo, edit, or delete it. Open a task to see its details and, for a repeating task, the history of that series.

For a repeating task, the next one is scheduled from the day you actually completed it. A late completion does not create a stack of missed tasks.

**Settings → Reminders** asks for notification permission, turns reminders on or off, and sets a time between 6:00 and 22:00. Each open task gets one reminder on its due date.

## Journal

From a plant's details, **Open journal** adds a note, an optional photo, and an optional height. The date cannot be in the future. With two or more photos, a before/after slider compares the first and the latest. Height entries are summed into a short growth summary.

## Insights

Charts show weekly care completion, the mix of care types, plants by category, and how many plants were added each month. Each chart has a spoken summary for VoiceOver.

## Settings

| Setting | What it does |
|---|---|
| Theme | System, Light, or Dark |
| Collection layout | Grid or List |
| Reminders | Permission, on or off, and reminder time |
| Replay onboarding | Shows the introduction again |
| Reset to sample data | Replaces everything with the eight sample plants, after confirmation |
| Erase all data | Deletes plants, tasks, journal entries, identifications, and photos, after confirmation |
| About LeafLoom | Privacy, how identification works, and the care disclaimer |

## Accessibility and privacy

LeafLoom supports VoiceOver, Dynamic Type, Dark Mode, and Reduce Motion. Status is shown with text and an icon, not colour alone.

Plants, photos, and notes stay on the device. There is no account and no server.
