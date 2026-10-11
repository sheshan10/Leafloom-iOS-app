import CoreData
import XCTest
@testable import LeafLoom

final class JournalRepositoryTests: XCTestCase {
    @MainActor
    func testCreateRequiresPlantAndNotes() throws {
        let stack = TestStack()
        XCTAssertThrowsError(try stack.journal.create(JournalDraft(plantID: nil, entryDate: Fixtures.now, notes: "Hi")))
        let plant = try stack.makePlant()
        XCTAssertThrowsError(try stack.journal.create(JournalDraft(plantID: plant.id, entryDate: Fixtures.now, notes: "  ")))
        XCTAssertThrowsError(try stack.journal.create(JournalDraft(plantID: UUID(), entryDate: Fixtures.now, notes: "Unknown plant")))
        XCTAssertEqual(try stack.count("JournalEntry"), 0)
    }

    @MainActor
    func testCreateUpdateDelete() throws {
        let stack = TestStack()
        let plant = try stack.makePlant()
        let entry = try stack.journal.create(JournalDraft(plantID: plant.id, entryDate: Fixtures.daysFromNow(-1), notes: "  Repotted  ", heightCm: 42), imageData: Fixtures.jpegData())
        XCTAssertEqual(entry.notes, "Repotted")
        XCTAssertEqual(entry.heightCm, 42)
        XCTAssertNotNil(entry.imageFilename)
        XCTAssertEqual(plant.journalArray.count, 1)

        var draft = entry.draft
        draft.heightCm = nil
        try stack.journal.update(entry, with: draft, removeImage: true)
        XCTAssertNil(entry.heightCm, "Cleared height is stored as 'not measured'")
        XCTAssertNil(entry.imageFilename)
        XCTAssertEqual(stack.imageFileCount(), 0)

        try stack.journal.delete(entry)
        XCTAssertEqual(try stack.count("JournalEntry"), 0)
        XCTAssertEqual(try stack.count("Plant"), 1, "Deleting an entry keeps the plant")
    }

    @MainActor
    func testFutureEntryIsRejected() throws {
        let stack = TestStack()
        let plant = try stack.makePlant()
        XCTAssertThrowsError(try stack.journal.create(JournalDraft(plantID: plant.id, entryDate: Fixtures.daysFromNow(2), notes: "Too early")))
    }

    @MainActor
    func testJournalArrayIsNewestFirst() throws {
        let stack = TestStack()
        let plant = try stack.makePlant()
        try stack.journal.create(JournalDraft(plantID: plant.id, entryDate: Fixtures.daysFromNow(-10), notes: "Old"))
        try stack.journal.create(JournalDraft(plantID: plant.id, entryDate: Fixtures.daysFromNow(-1), notes: "New"))
        XCTAssertEqual(plant.journalArray.map(\.notes), ["New", "Old"])
    }
}

final class IdentificationRepositoryTests: XCTestCase {
    @MainActor
    func testDemoResultIsStoredWithoutConfidence() throws {
        let stack = TestStack()
        let result = IdentificationResult(
            suggestions: [IdentificationSuggestion(label: "aloe_vera", knowledge: PlantKnowledgeBase.shared.entry(forKey: "aloe_vera"), confidence: 0.9)],
            modelIdentifier: DemoPlantIdentificationService.modelIdentifier,
            isDemo: true
        )
        let record = try stack.identifications.save(result, imageData: Fixtures.jpegData())
        XCTAssertTrue(record.isDemoResult)
        XCTAssertNil(record.confidence, "A demo result never stores a confidence, even if one was passed")
        XCTAssertEqual(record.predictedLabel, "Aloe vera")
        XCTAssertNotNil(record.imageFilename)
    }

    @MainActor
    func testModelResultKeepsConfidenceAndHistoryIsNewestFirst() throws {
        let stack = TestStack()
        let first = try stack.identifications.save(
            IdentificationResult(suggestions: [IdentificationSuggestion(label: "mystery_vine", confidence: 0.42)], modelIdentifier: "LeafLoomPlantClassifier", isDemo: false, date: Fixtures.now),
            imageData: nil
        )
        XCTAssertEqual(try XCTUnwrap(first.confidence), 0.42, accuracy: 0.0001)
        XCTAssertEqual(first.predictedLabel, "Mystery Vine")
        XCTAssertEqual(first.modelIdentifier, "LeafLoomPlantClassifier")
        XCTAssertEqual(try stack.identifications.history().count, 1)

        try stack.identifications.delete(first)
        XCTAssertTrue(try stack.identifications.history().isEmpty)
    }

    @MainActor
    func testEmptyResultThrows() {
        let stack = TestStack()
        XCTAssertThrowsError(try stack.identifications.save(IdentificationResult(suggestions: [], modelIdentifier: "x", isDemo: false), imageData: nil)) { error in
            XCTAssertEqual(error as? IdentificationError, .noResults)
        }
    }
}

final class DataMaintenanceTests: XCTestCase {
    @MainActor
    private func makeMaintenance() -> (DataMaintenance, PersistenceController, MockReminderScheduler, UserDefaults) {
        let persistence = PersistenceController(inMemory: true)
        let suite = "DataMaintenanceTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let images = ImageStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(suite))
        let scheduler = MockReminderScheduler()
        return (DataMaintenance(persistence: persistence, images: images, scheduler: scheduler, defaults: defaults), persistence, scheduler, defaults)
    }

    private func count(_ entity: String, in persistence: PersistenceController) throws -> Int {
        try persistence.viewContext.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: entity))
    }

    @MainActor
    func testResetCreatesTheSampleCollection() throws {
        let (maintenance, persistence, scheduler, _) = makeMaintenance()
        try maintenance.resetToSampleData(now: Fixtures.now)
        XCTAssertEqual(try count("Plant", in: persistence), SampleDataSeeder.specs.count)
        XCTAssertEqual(try count("JournalEntry", in: persistence), 4)
        XCTAssertGreaterThan(try count("CareTask", in: persistence), SampleDataSeeder.specs.count)
        XCTAssertEqual(scheduler.cancelAllCount, 1)

        let plants = try persistence.viewContext.fetch(Plant.fetchRequest())
        XCTAssertTrue(plants.allSatisfy(\.isSample))
        XCTAssertTrue(plants.allSatisfy { $0.sampleAssetName?.hasPrefix("Sample") == true })
    }

    @MainActor
    func testSeedOnlyOnceThenEraseEverything() throws {
        let (maintenance, persistence, _, defaults) = makeMaintenance()
        try maintenance.seedIfNeeded(now: Fixtures.now)
        try maintenance.seedIfNeeded(now: Fixtures.now)
        XCTAssertEqual(try count("Plant", in: persistence), SampleDataSeeder.specs.count, "No duplicates on the second launch")
        XCTAssertTrue(defaults.bool(forKey: DataMaintenance.seededKey))

        try maintenance.eraseAll()
        for entity in ["Plant", "CareTask", "JournalEntry", "IdentificationRecord"] {
            XCTAssertEqual(try count(entity, in: persistence), 0, entity)
        }
        try maintenance.seedIfNeeded(now: Fixtures.now)
        XCTAssertEqual(try count("Plant", in: persistence), 0, "Erasing must not bring samples back on next launch")
    }

    @MainActor
    func testSampleDataHasSomethingDueAndOverdue() throws {
        let (maintenance, persistence, _, _) = makeMaintenance()
        try maintenance.resetToSampleData(now: .now)
        let tasks = try persistence.viewContext.fetch(CareTask.fetchRequest())
        let statuses = Set(tasks.map { CareStatusEvaluator.status(of: $0) })
        XCTAssertTrue(statuses.isSuperset(of: [.overdue, .dueToday, .upcoming, .completed]))
    }
}
