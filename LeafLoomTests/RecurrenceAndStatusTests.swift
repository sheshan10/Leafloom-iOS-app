import XCTest
@testable import LeafLoom

final class RecurrenceAndStatusTests: XCTestCase {
    private let cal = Fixtures.calendar

    // MARK: RecurrenceCalculator

    func testNextDueIsBasedOnCompletionDayAndKeepsTimeOfDay() {
        let due = Fixtures.date(2026, 10, 5, 8, 30)
        let completed = Fixtures.date(2026, 10, 7, 18)
        let next = RecurrenceCalculator.nextDueDate(originalDue: due, intervalDays: 7, completedAt: completed, calendar: cal)
        XCTAssertEqual(next, Fixtures.date(2026, 10, 14, 8, 30))
    }

    func testCompletingEarlyStillSchedulesFromCompletionDay() {
        let due = Fixtures.date(2026, 10, 10, 9)
        let next = RecurrenceCalculator.nextDueDate(originalDue: due, intervalDays: 3, completedAt: Fixtures.now, calendar: cal)
        XCTAssertEqual(next, Fixtures.date(2026, 10, 10, 9))
    }

    func testNoRecurrenceForMissingOrInvalidInterval() {
        XCTAssertNil(RecurrenceCalculator.nextDueDate(originalDue: Fixtures.now, intervalDays: nil, completedAt: Fixtures.now, calendar: cal))
        XCTAssertNil(RecurrenceCalculator.nextDueDate(originalDue: Fixtures.now, intervalDays: 0, completedAt: Fixtures.now, calendar: cal))
    }

    func testMonthBoundary() {
        let next = RecurrenceCalculator.nextDueDate(originalDue: Fixtures.date(2026, 10, 30, 9), intervalDays: 5, completedAt: Fixtures.date(2026, 10, 30, 12), calendar: cal)
        XCTAssertEqual(next, Fixtures.date(2026, 11, 4, 9))
    }

    func testUndoDeletesOnlyUntouchedSpawn() {
        let t = Fixtures.now
        XCTAssertTrue(RecurrenceCalculator.shouldDeleteSpawnedOnUndo(spawnedIsCompleted: false, spawnedCreatedAt: t, spawnedUpdatedAt: t))
        XCTAssertFalse(RecurrenceCalculator.shouldDeleteSpawnedOnUndo(spawnedIsCompleted: false, spawnedCreatedAt: t, spawnedUpdatedAt: t.addingTimeInterval(5)))
        XCTAssertFalse(RecurrenceCalculator.shouldDeleteSpawnedOnUndo(spawnedIsCompleted: true, spawnedCreatedAt: t, spawnedUpdatedAt: t))
    }

    // MARK: CareStatusEvaluator

    func testStatusBoundaries() {
        func status(_ due: Date, done: Bool = false) -> CareStatus {
            CareStatusEvaluator.status(of: CareTaskSnapshot(taskDueDate: due, taskIsCompleted: done), now: Fixtures.now, calendar: cal)
        }
        XCTAssertEqual(status(Fixtures.date(2026, 10, 6, 23, 59)), .overdue)
        XCTAssertEqual(status(Fixtures.date(2026, 10, 7, 0, 1)), .dueToday, "Earlier today is due, not overdue")
        XCTAssertEqual(status(Fixtures.date(2026, 10, 7, 23)), .dueToday)
        XCTAssertEqual(status(Fixtures.date(2026, 10, 8, 0, 1)), .upcoming)
        XCTAssertEqual(status(Fixtures.date(2026, 9, 1), done: true), .completed)
    }

    func testNeedsAttention() {
        let overdue = CareTaskSnapshot(taskDueDate: Fixtures.daysFromNow(-2))
        let today = CareTaskSnapshot(taskDueDate: Fixtures.daysFromNow(0))
        let later = CareTaskSnapshot(taskDueDate: Fixtures.daysFromNow(3))
        XCTAssertTrue(CareStatusEvaluator.needsAttention(overdue, now: Fixtures.now, calendar: cal))
        XCTAssertTrue(CareStatusEvaluator.needsAttention(today, now: Fixtures.now, calendar: cal))
        XCTAssertFalse(CareStatusEvaluator.needsAttention(later, now: Fixtures.now, calendar: cal))
    }

    // MARK: TaskFilter

    func testTaskFilters() {
        let overdue = CareTaskSnapshot(taskDueDate: Fixtures.daysFromNow(-1))
        let today = CareTaskSnapshot(taskDueDate: Fixtures.daysFromNow(0))
        let later = CareTaskSnapshot(taskDueDate: Fixtures.daysFromNow(4))
        let doneOld = CareTaskSnapshot(taskDueDate: Fixtures.daysFromNow(-9), taskIsCompleted: true, taskCompletedAt: Fixtures.daysFromNow(-9))
        let doneNew = CareTaskSnapshot(taskDueDate: Fixtures.daysFromNow(-2), taskIsCompleted: true, taskCompletedAt: Fixtures.daysFromNow(-1))
        let all = [later, doneOld, overdue, doneNew, today]

        XCTAssertEqual(TaskFilter.upcoming.apply(all, now: Fixtures.now, calendar: cal).map(\.taskID), [today, later].map(\.taskID))
        XCTAssertEqual(TaskFilter.overdue.apply(all, now: Fixtures.now, calendar: cal).map(\.taskID), [overdue.taskID])
        XCTAssertEqual(TaskFilter.completed.apply(all, now: Fixtures.now, calendar: cal).map(\.taskID), [doneNew, doneOld].map(\.taskID), "Newest completion first")
        XCTAssertEqual(TaskFilter.all.apply(all, now: Fixtures.now, calendar: cal).count, 5)
    }

    // MARK: CareCalendar / formatting

    func testWeekStartsOnMonday() {
        XCTAssertEqual(cal.startOfWeek(Fixtures.now), Fixtures.date(2026, 10, 5, 0))
    }

    func testDaysBetweenUsesCalendarDays() {
        XCTAssertEqual(cal.daysBetween(Fixtures.date(2026, 10, 7, 23), Fixtures.date(2026, 10, 8, 1)), 1)
        XCTAssertEqual(cal.daysBetween(Fixtures.now, Fixtures.date(2026, 10, 7, 1)), 0)
        XCTAssertEqual(cal.daysBetween(Fixtures.now, Fixtures.date(2026, 10, 1)), -6)
    }

    func testRelativeDayFormatter() {
        XCTAssertEqual(RelativeDayFormatter.string(for: Fixtures.daysFromNow(0), now: Fixtures.now, calendar: cal), "Today")
        XCTAssertEqual(RelativeDayFormatter.string(for: Fixtures.daysFromNow(1), now: Fixtures.now, calendar: cal), "Tomorrow")
        XCTAssertEqual(RelativeDayFormatter.string(for: Fixtures.daysFromNow(-1), now: Fixtures.now, calendar: cal), "Yesterday")
        XCTAssertEqual(RelativeDayFormatter.string(for: Fixtures.daysFromNow(-3), now: Fixtures.now, calendar: cal), "3 days ago")
    }

    func testGreeting() {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        XCTAssertEqual(RelativeDayFormatter.greeting(for: Fixtures.date(2026, 10, 7, 8), calendar: c), "Good morning")
        XCTAssertEqual(RelativeDayFormatter.greeting(for: Fixtures.date(2026, 10, 7, 13), calendar: c), "Good afternoon")
        XCTAssertEqual(RelativeDayFormatter.greeting(for: Fixtures.date(2026, 10, 7, 21), calendar: c), "Good evening")
    }
}
