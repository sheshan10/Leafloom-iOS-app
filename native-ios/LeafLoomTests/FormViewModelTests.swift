import XCTest
@testable import LeafLoom

final class FormViewModelTests: XCTestCase {
    @MainActor
    func testNewTaskDefaultsToNextReminderHour() {
        let model = CareTaskFormViewModel(mode: .create(plantID: nil), existing: nil, defaultHour: 9, now: Fixtures.now, calendar: Fixtures.calendar)
        XCTAssertEqual(model.draft.dueDate, Fixtures.daysFromNow(1, hour: 9), "09:00 has passed at 10:00, so tomorrow")

        let evening = CareTaskFormViewModel(mode: .create(plantID: nil), existing: nil, defaultHour: 18, now: Fixtures.now, calendar: Fixtures.calendar)
        XCTAssertEqual(evening.draft.dueDate, Fixtures.daysFromNow(0, hour: 18))
        XCTAssertFalse(evening.repeats)
        XCTAssertFalse(evening.hasChanges)
    }

    @MainActor
    func testSuggestedTitleFollowsCategoryUntilUserTypes() {
        let model = CareTaskFormViewModel(mode: .create(plantID: UUID()), existing: nil, defaultHour: 9, now: Fixtures.now, calendar: Fixtures.calendar)
        model.refreshSuggestedTitle(plantName: "Monty")
        XCTAssertEqual(model.draft.title, "Water Monty")
        model.draft.category = .fertilizing
        model.refreshSuggestedTitle(plantName: "Monty")
        XCTAssertEqual(model.draft.title, "Fertilise Monty")

        model.draft.title = "Feed with worm tea"
        model.draft.category = .pruning
        model.refreshSuggestedTitle(plantName: "Monty")
        XCTAssertEqual(model.draft.title, "Feed with worm tea", "A typed title is never overwritten")
    }

    @MainActor
    func testRepeatToggleControlsInterval() {
        let model = CareTaskFormViewModel(mode: .create(plantID: nil), existing: nil, defaultHour: 9, now: Fixtures.now, calendar: Fixtures.calendar)
        model.draft.recurrenceIntervalDays = 7
        XCTAssertFalse(model.hasChanges, "An interval without Repeat on is ignored")
        model.repeats = true
        XCTAssertTrue(model.hasChanges)
    }

    @MainActor
    func testPlantFormPrefillAndChangeTracking() {
        var prefill = PlantDraft()
        prefill.name = "Sweet basil"
        prefill.category = .herb
        prefill.tags = ["kitchen", "edible"]
        let model = PlantFormViewModel(mode: .create(prefill: prefill, identificationID: nil), existing: nil)
        XCTAssertEqual(model.draft.name, "Sweet basil")
        XCTAssertEqual(model.tagsText, "kitchen, edible")
        XCTAssertFalse(model.isEditing)
        XCTAssertFalse(model.hasChanges)

        model.draft.name = ""
        XCTAssertTrue(model.hasChanges)
        XCTAssertFalse(model.validate())
        XCTAssertNotNil(model.errors[.name])
    }

    @MainActor
    func testIdentificationPrefillStatus() throws {
        let kb = PlantKnowledgeBase.shared
        let entry = try XCTUnwrap(kb.entry(forKey: "monstera_deliciosa"))
        XCTAssertEqual(entry.plantDraft(status: .unknown).identificationStatus, .unknown)
        XCTAssertEqual(entry.plantDraft(status: .suggested).wateringIntervalDays, entry.wateringIntervalDays)
    }
}
