import Foundation

/// The minimal view of a care task the domain logic needs. Implemented by the Core Data entity and
/// by `CareTaskSnapshot`, so rules can be unit-tested without a persistent store.
protocol CareTaskRepresentable {
    var taskID: UUID { get }
    var taskPlantID: UUID? { get }
    var taskCategory: CareCategory { get }
    var taskDueDate: Date { get }
    var taskIsCompleted: Bool { get }
    var taskCompletedAt: Date? { get }
    var taskRecurrenceDays: Int? { get }
}

struct CareTaskSnapshot: CareTaskRepresentable, Hashable, Sendable {
    var taskID = UUID()
    var taskPlantID: UUID?
    var taskCategory: CareCategory = .watering
    var taskDueDate: Date
    var taskIsCompleted = false
    var taskCompletedAt: Date?
    var taskRecurrenceDays: Int?
}

enum CareStatus: String, Sendable {
    case completed, overdue, dueToday, upcoming

    var label: String {
        switch self {
        case .completed: "Done"
        case .overdue: "Overdue"
        case .dueToday: "Due today"
        case .upcoming: "Upcoming"
        }
    }

    var symbol: String {
        switch self {
        case .completed: "checkmark.circle.fill"
        case .overdue: "exclamationmark.circle.fill"
        case .dueToday: "clock.fill"
        case .upcoming: "calendar"
        }
    }
}

enum CareStatusEvaluator {
    static func status(of task: some CareTaskRepresentable, now: Date = .now, calendar: CareCalendar = CareCalendar()) -> CareStatus {
        if task.taskIsCompleted { return .completed }
        let diff = calendar.daysBetween(now, task.taskDueDate)
        if diff < 0 { return .overdue }
        if diff == 0 { return .dueToday }
        return .upcoming
    }

    static func needsAttention(_ task: some CareTaskRepresentable, now: Date = .now, calendar: CareCalendar = CareCalendar()) -> Bool {
        let s = status(of: task, now: now, calendar: calendar)
        return s == .overdue || s == .dueToday
    }
}

enum RecurrenceCalculator {
    /// Next occurrence = start of the completion day + interval, at the original due time of day.
    /// Basing it on the completion day (not the old due date) avoids a backlog of overdue occurrences
    /// when a task is completed late.
    static func nextDueDate(originalDue: Date, intervalDays: Int?, completedAt: Date, calendar: CareCalendar = CareCalendar()) -> Date? {
        guard let interval = intervalDays, interval >= 1 else { return nil }
        let day = calendar.addingDays(interval, to: calendar.startOfDay(completedAt))
        return calendar.combine(day: day, timeOf: originalDue)
    }

    /// The spawned occurrence is only removed on undo if the user has not touched it since.
    static func shouldDeleteSpawnedOnUndo(spawnedIsCompleted: Bool, spawnedCreatedAt: Date, spawnedUpdatedAt: Date) -> Bool {
        !spawnedIsCompleted && spawnedCreatedAt == spawnedUpdatedAt
    }
}

enum TaskFilter: String, CaseIterable, Identifiable {
    case upcoming, overdue, completed, all

    var id: String { rawValue }

    var label: String {
        switch self {
        case .upcoming: "Upcoming"
        case .overdue: "Overdue"
        case .completed: "Completed"
        case .all: "All"
        }
    }

    func includes(_ task: some CareTaskRepresentable, now: Date = .now, calendar: CareCalendar = CareCalendar()) -> Bool {
        let s = CareStatusEvaluator.status(of: task, now: now, calendar: calendar)
        switch self {
        case .upcoming: return s == .upcoming || s == .dueToday
        case .overdue: return s == .overdue
        case .completed: return s == .completed
        case .all: return true
        }
    }

    /// Filters and sorts: completed newest first, everything else by due date.
    func apply<T: CareTaskRepresentable>(_ tasks: [T], now: Date = .now, calendar: CareCalendar = CareCalendar()) -> [T] {
        let list = tasks.filter { includes($0, now: now, calendar: calendar) }
        if self == .completed {
            return list.sorted { ($0.taskCompletedAt ?? .distantPast) > ($1.taskCompletedAt ?? .distantPast) }
        }
        return list.sorted { $0.taskDueDate < $1.taskDueDate }
    }
}
