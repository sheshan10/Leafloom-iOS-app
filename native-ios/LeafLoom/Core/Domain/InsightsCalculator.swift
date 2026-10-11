import Foundation

struct DashboardSummary: Equatable {
    var totalPlants = 0
    var favorites = 0
    var needsAttentionPlantIDs: [UUID] = []
    var dueTodayCount = 0
    var overdueCount = 0
    var upcomingWeekCount = 0
    var completedThisWeek = 0
    /// completed this week ÷ (completed this week + still-open tasks due this week or overdue).
    var weeklyProgress: Double = 0
    /// Share of plants with no overdue care. A scheduling measure, not a botanical health score.
    var onSchedulePercent = 0
}

struct CountPoint: Identifiable, Equatable {
    var id: Date { start }
    var start: Date
    var count: Int
}

struct CategoryCount<Category: Hashable>: Identifiable, Equatable {
    var id: Category { category }
    var category: Category
    var count: Int
}

/// Pure statistics over stored records. Every number shown in Home and Insights comes from here.
enum InsightsCalculator {
    static func summary(plants: [some PlantRepresentable], tasks: [some CareTaskRepresentable], now: Date = .now, calendar: CareCalendar = CareCalendar()) -> DashboardSummary {
        let weekStart = calendar.startOfWeek(now)
        let weekEnd = calendar.addingDays(7, to: weekStart)
        let open = tasks.filter { !$0.taskIsCompleted }
        let statuses = open.map { ($0, CareStatusEvaluator.status(of: $0, now: now, calendar: calendar)) }
        let overdue = statuses.filter { $0.1 == .overdue }.map(\.0)
        let dueToday = statuses.filter { $0.1 == .dueToday }.map(\.0)
        let upcomingWeek = open.filter {
            let d = calendar.daysBetween(now, $0.taskDueDate)
            return d >= 0 && d <= 7
        }
        let completedThisWeek = tasks.filter {
            guard $0.taskIsCompleted, let c = $0.taskCompletedAt else { return false }
            return c >= weekStart && c < weekEnd
        }.count
        let openThisWeek = open.filter { $0.taskDueDate < weekEnd }.count
        let denominator = completedThisWeek + openThisWeek

        let attention = Set((overdue + dueToday).compactMap(\.taskPlantID))
        let overdueIDs = Set(overdue.compactMap(\.taskPlantID))
        let plantIDs = plants.map(\.plantID)

        var s = DashboardSummary()
        s.totalPlants = plants.count
        s.favorites = plants.filter(\.plantIsFavorite).count
        s.needsAttentionPlantIDs = plantIDs.filter { attention.contains($0) }
        s.dueTodayCount = dueToday.count
        s.overdueCount = overdue.count
        s.upcomingWeekCount = upcomingWeek.count
        s.completedThisWeek = completedThisWeek
        s.weeklyProgress = denominator == 0 ? 0 : Double(completedThisWeek) / Double(denominator)
        let onSchedule = plantIDs.filter { !overdueIDs.contains($0) }.count
        s.onSchedulePercent = plants.isEmpty ? 0 : Int((Double(onSchedule) / Double(plants.count) * 100).rounded())
        return s
    }

    static func plantsByCategory(_ plants: [some PlantRepresentable]) -> [CategoryCount<PlantCategory>] {
        Dictionary(grouping: plants, by: \.plantCategory)
            .map { CategoryCount(category: $0.key, count: $0.value.count) }
            .sorted { $0.count == $1.count ? $0.category.rawValue < $1.category.rawValue : $0.count > $1.count }
    }

    /// Plants added per month for the last `months` months, oldest first.
    static func additionsByMonth(_ plants: [some PlantRepresentable], now: Date = .now, months: Int = 6, calendar: CareCalendar = CareCalendar()) -> [CountPoint] {
        let first = calendar.startOfMonth(now)
        return (0..<months).map { i in
            let start = calendar.addingMonths(-(months - 1 - i), to: first)
            let end = calendar.addingMonths(1, to: start)
            return CountPoint(start: start, count: plants.filter { $0.plantDateAdded >= start && $0.plantDateAdded < end }.count)
        }
    }

    /// Completed tasks per week for the last `weeks` weeks, oldest first.
    static func completionTrend(_ tasks: [some CareTaskRepresentable], now: Date = .now, weeks: Int = 8, calendar: CareCalendar = CareCalendar()) -> [CountPoint] {
        let current = calendar.startOfWeek(now)
        return (0..<weeks).map { i in
            let start = calendar.addingDays(-7 * (weeks - 1 - i), to: current)
            let end = calendar.addingDays(7, to: start)
            return CountPoint(start: start, count: tasks.filter {
                guard let c = $0.taskCompletedAt else { return false }
                return c >= start && c < end
            }.count)
        }
    }

    static func careByCategory(_ tasks: [some CareTaskRepresentable]) -> [CategoryCount<CareCategory>] {
        Dictionary(grouping: tasks.filter(\.taskIsCompleted), by: \.taskCategory)
            .map { CategoryCount(category: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
}
