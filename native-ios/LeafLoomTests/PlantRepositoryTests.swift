import CoreData
import XCTest
@testable import LeafLoom

final class PlantRepositoryTests: XCTestCase {
    @MainActor
    func testCreateValidatesAndNormalises() throws {
        let stack = TestStack()
        var draft = PlantDraft()
        draft.name = "   "
        XCTAssertThrowsError(try stack.plants.create(draft)) { error in
            XCTAssertTrue(error is ValidationFailure)
        }
        XCTAssertEqual(try stack.count("Plant"), 0)

        draft.name = "  Big   Monty "
        draft.category = .foliage
        draft.tags = ["Indoor", "indoor", "Rare"]
        draft.location = "  "
        let plant = try stack.plants.create(draft)
        XCTAssertEqual(plant.name, "Big Monty")
        XCTAssertEqual(plant.tags, ["indoor", "rare"])
        XCTAssertNil(plant.location)
        XCTAssertEqual(plant.dateAdded, Fixtures.now)
        XCTAssertFalse(plant.isSample)
        XCTAssertEqual(try stack.count("Plant"), 1)
    }

    @MainActor
    func testCreateWithScheduleMakesRecurringTasksAndReminders() async throws {
        let stack = TestStack()
        let plant = try stack.makePlant(water: 7, fertilise: 30, schedule: true)
        let tasks = plant.tasksArray.sorted { $0.dueDate < $1.dueDate }
        XCTAssertEqual(tasks.count, 2)
        XCTAssertEqual(tasks.map(\.category), [.watering, .fertilizing])
        XCTAssertEqual(tasks[0].recurrenceIntervalDays, 7)
        XCTAssertEqual(tasks[0].dueDate, Fixtures.daysFromNow(1, hour: 9), "First watering tomorrow at the reminder hour")
        XCTAssertEqual(tasks[1].dueDate, Fixtures.daysFromNow(30, hour: 9))
        XCTAssertEqual(tasks[0].title, "Water Monty")
        await stack.scheduler.waitForScheduled(atLeast: 2)
        XCTAssertEqual(Set(stack.scheduler.scheduled.map(\.taskID)), Set(tasks.map(\.id)))
    }

    @MainActor
    func testCreateWithoutIntervalsMakesNoSchedule() throws {
        let stack = TestStack()
        let plant = try stack.makePlant(schedule: true)
        XCTAssertTrue(plant.tasksArray.isEmpty)
    }

    @MainActor
    func testUpdateReplacesImageAndDeletesOldFile() throws {
        let stack = TestStack()
        let plant = try stack.makePlant(imageData: Fixtures.jpegData())
        let first = try XCTUnwrap(plant.imageFilename)
        XCTAssertEqual(stack.imageFileCount(), 1)

        var draft = plant.draft
        draft.name = "Monty II"
        try stack.plants.update(plant, with: draft, newImageData: Fixtures.jpegData(color: .systemRed))
        XCTAssertEqual(plant.name, "Monty II")
        XCTAssertNotEqual(plant.imageFilename, first)
        XCTAssertEqual(stack.imageFileCount(), 1, "Old photo removed")

        try stack.plants.update(plant, with: draft, removeImage: true)
        XCTAssertNil(plant.imageFilename)
        XCTAssertEqual(stack.imageFileCount(), 0)
    }

    @MainActor
    func testInvalidUpdateLeavesPlantUnchanged() throws {
        let stack = TestStack()
        let plant = try stack.makePlant()
        var draft = plant.draft
        draft.wateringIntervalDays = 0
        XCTAssertThrowsError(try stack.plants.update(plant, with: draft))
        XCTAssertNil(plant.wateringIntervalDays)
    }

    @MainActor
    func testToggleFavorite() throws {
        let stack = TestStack()
        let plant = try stack.makePlant()
        try stack.plants.toggleFavorite(plant)
        XCTAssertTrue(plant.isFavorite)
        try stack.plants.toggleFavorite(plant)
        XCTAssertFalse(plant.isFavorite)
    }

    @MainActor
    func testDeleteCascadesAndCleansUp() throws {
        let stack = TestStack()
        let plant = try stack.makePlant(imageData: Fixtures.jpegData())
        let task = try stack.makeTask(for: plant)
        try stack.journal.create(JournalDraft(plantID: plant.id, entryDate: Fixtures.now, notes: "New leaf"), imageData: Fixtures.jpegData())
        let record = try stack.identifications.save(
            IdentificationResult(suggestions: [IdentificationSuggestion(label: "monstera_deliciosa", confidence: nil)], modelIdentifier: "demo-mode", isDemo: true),
            imageData: nil
        )
        try stack.identifications.link(record, to: plant)

        XCTAssertEqual(stack.plants.deletionSummary(for: plant), PlantDeletionSummary(taskCount: 1, journalCount: 1))
        let taskID = task.id
        try stack.plants.delete(plant)

        XCTAssertEqual(try stack.count("Plant"), 0)
        XCTAssertEqual(try stack.count("CareTask"), 0, "Tasks cascade")
        XCTAssertEqual(try stack.count("JournalEntry"), 0, "Journal cascades")
        XCTAssertEqual(try stack.count("IdentificationRecord"), 1, "History is kept…")
        XCTAssertNil(record.plant, "…but unlinked (nullify)")
        XCTAssertTrue(stack.scheduler.cancelled.contains(taskID))
        XCTAssertEqual(stack.imageFileCount(), 0, "Plant and journal photos removed")
    }
}
