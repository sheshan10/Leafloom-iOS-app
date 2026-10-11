import CoreData
import XCTest
@testable import LeafLoom

final class CareTaskRepositoryTests: XCTestCase {
    @MainActor
    func testCreateValidatesTitleAndInterval() throws {
        let stack = TestStack()
        var draft = CareTaskDraft()
        draft.title = " "
        XCTAssertThrowsError(try stack.tasks.create(draft))
        draft.title = "Mist leaves"
        draft.recurrenceIntervalDays = 400
        XCTAssertThrowsError(try stack.tasks.create(draft))
        XCTAssertEqual(try stack.count("CareTask"), 0)
    }

    @MainActor
    func testGeneralTaskWithoutPlantIsAllowed() throws {
        let stack = TestStack()
        let task = try stack.makeTask(for: nil, title: "Check all plants for pests", category: .inspection)
        XCTAssertNil(task.plant)
        XCTAssertEqual(task.category, .inspection)
    }

    @MainActor
    func testCompletingRecurringTaskSpawnsNextInSameSeries() async throws {
        let stack = TestStack()
        let plant = try stack.makePlant()
        let task = try stack.makeTask(for: plant, due: Fixtures.daysFromNow(-3, hour: 8), every: 7)

        let next = try XCTUnwrap(try stack.tasks.complete(task))
        XCTAssertTrue(task.isCompleted)
        XCTAssertEqual(task.completedAt, Fixtures.now)
        XCTAssertEqual(task.spawnedTaskID, next.id)
        XCTAssertEqual(next.seriesID, task.seriesID)
        XCTAssertEqual(next.dueDate, Fixtures.daysFromNow(7, hour: 8), "From the completion day, at the original time")
        XCTAssertFalse(next.isCompleted)
        XCTAssertEqual(next.plant, plant)
        XCTAssertEqual(stack.tasks.series(of: next).count, 2)
        XCTAssertTrue(stack.scheduler.cancelled.contains(task.id))
        await stack.scheduler.waitForScheduled(atLeast: 2)
        XCTAssertTrue(stack.scheduler.scheduled.contains { $0.taskID == next.id })
    }

    @MainActor
    func testCompletingOneOffTaskSpawnsNothing() throws {
        let stack = TestStack()
        let task = try stack.makeTask(for: nil)
        XCTAssertNil(try stack.tasks.complete(task))
        XCTAssertNil(try stack.tasks.complete(task), "Completing twice is a no-op")
        XCTAssertEqual(try stack.count("CareTask"), 1)
    }

    @MainActor
    func testUndoRemovesUntouchedSpawn() throws {
        let stack = TestStack()
        let task = try stack.makeTask(for: nil, every: 3)
        _ = try stack.tasks.complete(task)
        XCTAssertEqual(try stack.count("CareTask"), 2)

        try stack.tasks.undoCompletion(task)
        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completedAt)
        XCTAssertNil(task.spawnedTaskID)
        XCTAssertEqual(try stack.count("CareTask"), 1)
    }

    @MainActor
    func testUndoKeepsSpawnTheUserEdited() throws {
        var clock = Fixtures.now
        let persistence = PersistenceController(inMemory: true)
        let scheduler = MockReminderScheduler()
        let repo = CareTaskRepository(context: persistence.viewContext, scheduler: scheduler, calendar: Fixtures.calendar, now: { clock })
        var draft = CareTaskDraft()
        draft.title = "Water"
        draft.dueDate = Fixtures.now
        draft.recurrenceIntervalDays = 5
        let task = try repo.create(draft)
        let spawned = try XCTUnwrap(try repo.complete(task))

        clock = Fixtures.now.addingTimeInterval(120)
        var edit = spawned.draft
        edit.notes = "Use rainwater"
        try repo.update(spawned, with: edit)

        try repo.undoCompletion(task)
        XCTAssertFalse(task.isCompleted)
        XCTAssertNotNil(repo.task(id: spawned.id), "Edited occurrence is kept")
    }

    @MainActor
    func testUpdateAndDeleteSyncReminders() async throws {
        let stack = TestStack()
        let task = try stack.makeTask(for: nil, due: Fixtures.daysFromNow(2))
        var draft = task.draft
        draft.title = "Water the ferns"
        try stack.tasks.update(task, with: draft)
        XCTAssertEqual(task.title, "Water the ferns")
        await stack.scheduler.waitForScheduled(atLeast: 2)
        XCTAssertTrue(stack.scheduler.scheduled.contains { $0.taskID == task.id && $0.title == "Water the ferns" })

        let id = task.id
        try stack.tasks.delete(task)
        XCTAssertNil(stack.tasks.task(id: id))
        XCTAssertTrue(stack.scheduler.cancelled.contains(id))
    }

    @MainActor
    func testRemindersOffCancelsInsteadOfScheduling() async throws {
        let stack = TestStack(reminderHour: nil)
        let task = try stack.makeTask(for: nil, due: Fixtures.daysFromNow(1))
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertTrue(stack.scheduler.scheduled.isEmpty)
        XCTAssertTrue(stack.scheduler.cancelled.contains(task.id))
    }

    @MainActor
    func testRescheduleAllCoversOnlyOpenTasks() async throws {
        let stack = TestStack()
        let open = try stack.makeTask(for: nil, title: "Open", due: Fixtures.daysFromNow(1))
        let done = try stack.makeTask(for: nil, title: "Done", due: Fixtures.daysFromNow(0))
        _ = try stack.tasks.complete(done)
        await stack.scheduler.waitForScheduled(atLeast: 2)
        let before = stack.scheduler.scheduled.count

        stack.tasks.rescheduleAll()
        await stack.scheduler.waitForScheduled(atLeast: before + 1)
        XCTAssertEqual(stack.scheduler.cancelAllCount, 1)
        let rescheduled = stack.scheduler.scheduled.dropFirst(before).map(\.taskID)
        XCTAssertEqual(rescheduled, [open.id])
    }
}
