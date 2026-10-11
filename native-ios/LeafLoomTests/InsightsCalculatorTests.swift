import XCTest
@testable import LeafLoom

final class InsightsCalculatorTests: XCTestCase {
    private let cal = Fixtures.calendar

    func testSummaryCountsAndProgress() {
        let a = PlantSnapshot(plantName: "A", plantIsFavorite: true)
        let b = PlantSnapshot(plantName: "B")
        let c = PlantSnapshot(plantName: "C")
        let tasks = [
            // Overdue for A
            CareTaskSnapshot(taskPlantID: a.plantID, taskDueDate: Fixtures.daysFromNow(-2)),
            // Due today for B
            CareTaskSnapshot(taskPlantID: b.plantID, taskDueDate: Fixtures.daysFromNow(0)),
            // Upcoming this week (Sunday 11 Oct) and next week
            CareTaskSnapshot(taskPlantID: c.plantID, taskDueDate: Fixtures.daysFromNow(4)),
            CareTaskSnapshot(taskPlantID: c.plantID, taskDueDate: Fixtures.daysFromNow(9)),
            // Completed this week (Monday) and last week
            CareTaskSnapshot(taskPlantID: c.plantID, taskDueDate: Fixtures.daysFromNow(-2), taskIsCompleted: true, taskCompletedAt: Fixtures.daysFromNow(-2)),
            CareTaskSnapshot(taskPlantID: c.plantID, taskDueDate: Fixtures.daysFromNow(-8), taskIsCompleted: true, taskCompletedAt: Fixtures.daysFromNow(-8)),
        ]
        let s = InsightsCalculator.summary(plants: [a, b, c], tasks: tasks, now: Fixtures.now, calendar: cal)

        XCTAssertEqual(s.totalPlants, 3)
        XCTAssertEqual(s.favorites, 1)
        XCTAssertEqual(s.overdueCount, 1)
        XCTAssertEqual(s.dueTodayCount, 1)
        XCTAssertEqual(Set(s.needsAttentionPlantIDs), [a.plantID, b.plantID])
        XCTAssertEqual(s.upcomingWeekCount, 2, "Today and the next 7 days")
        XCTAssertEqual(s.completedThisWeek, 1)
        // 1 completed ÷ (1 completed + overdue + today + Sunday's task) = 1/4
        XCTAssertEqual(s.weeklyProgress, 0.25, accuracy: 0.0001)
        // Only A has overdue care → 2 of 3 on schedule.
        XCTAssertEqual(s.onSchedulePercent, 67)
    }

    func testEmptySummaryIsZero() {
        let s = InsightsCalculator.summary(plants: [PlantSnapshot](), tasks: [CareTaskSnapshot](), now: Fixtures.now, calendar: cal)
        XCTAssertEqual(s, DashboardSummary())
    }

    func testPlantsByCategorySortedByCountThenName() {
        let plants = [
            PlantSnapshot(plantName: "1", plantCategory: .succulent),
            PlantSnapshot(plantName: "2", plantCategory: .succulent),
            PlantSnapshot(plantName: "3", plantCategory: .herb),
            PlantSnapshot(plantName: "4", plantCategory: .fern),
        ]
        let result = InsightsCalculator.plantsByCategory(plants)
        XCTAssertEqual(result.map(\.category), [.succulent, .fern, .herb])
        XCTAssertEqual(result.map(\.count), [2, 1, 1])
    }

    func testAdditionsByMonthCoversSixMonthsOldestFirst() {
        let plants = [
            PlantSnapshot(plantName: "Oct", plantDateAdded: Fixtures.date(2026, 10, 2)),
            PlantSnapshot(plantName: "Aug", plantDateAdded: Fixtures.date(2026, 8, 31, 23)),
            PlantSnapshot(plantName: "Old", plantDateAdded: Fixtures.date(2026, 1, 15)),
        ]
        let points = InsightsCalculator.additionsByMonth(plants, now: Fixtures.now, calendar: cal)
        XCTAssertEqual(points.count, 6)
        XCTAssertEqual(points.first?.start, Fixtures.date(2026, 5, 1, 0))
        XCTAssertEqual(points.last?.start, Fixtures.date(2026, 10, 1, 0))
        XCTAssertEqual(points.map(\.count), [0, 0, 0, 1, 0, 1])
    }

    func testCompletionTrendBucketsByMondayWeeks() {
        let tasks = [
            CareTaskSnapshot(taskDueDate: Fixtures.now, taskIsCompleted: true, taskCompletedAt: Fixtures.date(2026, 10, 5, 0, 30)),
            CareTaskSnapshot(taskDueDate: Fixtures.now, taskIsCompleted: true, taskCompletedAt: Fixtures.date(2026, 10, 4, 23)),
            CareTaskSnapshot(taskDueDate: Fixtures.now, taskIsCompleted: true, taskCompletedAt: Fixtures.date(2026, 10, 7)),
        ]
        let points = InsightsCalculator.completionTrend(tasks, now: Fixtures.now, calendar: cal)
        XCTAssertEqual(points.count, 8)
        XCTAssertEqual(points.last?.start, Fixtures.date(2026, 10, 5, 0))
        XCTAssertEqual(points.last?.count, 2)
        XCTAssertEqual(points[6].count, 1, "Sunday belongs to the previous week")
    }

    func testCareByCategoryCountsCompletedOnly() {
        let tasks = [
            CareTaskSnapshot(taskCategory: .watering, taskDueDate: Fixtures.now, taskIsCompleted: true),
            CareTaskSnapshot(taskCategory: .watering, taskDueDate: Fixtures.now, taskIsCompleted: true),
            CareTaskSnapshot(taskCategory: .pruning, taskDueDate: Fixtures.now, taskIsCompleted: true),
            CareTaskSnapshot(taskCategory: .repotting, taskDueDate: Fixtures.now),
        ]
        let result = InsightsCalculator.careByCategory(tasks)
        XCTAssertEqual(result.first?.category, .watering)
        XCTAssertEqual(result.first?.count, 2)
        XCTAssertFalse(result.contains { $0.category == .repotting })
    }
}
