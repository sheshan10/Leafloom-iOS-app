import Foundation
import OSLog
import UserNotifications

enum ReminderAuthorization: Equatable {
    case notDetermined, authorized, denied
}

/// What the scheduler needs to know about a task. Built on the main actor from a `CareTask`.
struct ReminderRequest: Equatable, Sendable {
    var taskID: UUID
    var title: String
    var plantName: String?
    var dueDate: Date
}

protocol ReminderScheduling: AnyObject, Sendable {
    func authorizationStatus() async -> ReminderAuthorization
    func requestAuthorization() async -> Bool
    func schedule(_ request: ReminderRequest, hour: Int) async
    func cancel(taskIDs: [UUID])
    func cancelAll()
}

/// Schedules one local notification per open care task, identified by the task UUID so that editing
/// replaces it and completing/deleting cancels it.
final class ReminderScheduler: ReminderScheduling, @unchecked Sendable {
    private let center: UNUserNotificationCenter
    private let calendar: Calendar
    private let logger = Logger(subsystem: "com.leafloom.LeafLoom", category: "Reminders")

    init(center: UNUserNotificationCenter = .current(), calendar: Calendar = .current) {
        self.center = center
        self.calendar = calendar
    }

    func authorizationStatus() async -> ReminderAuthorization {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            logger.error("Authorization request failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func schedule(_ request: ReminderRequest, hour: Int) async {
        let id = request.taskID.uuidString
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard await authorizationStatus() == .authorized,
              let fireDate = Self.fireDate(for: request.dueDate, hour: hour, now: .now, calendar: calendar) else { return }

        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.plantName.map { "\($0) is ready for some care." } ?? "A care task is due."
        content.sound = .default
        content.threadIdentifier = "care"
        content.userInfo = ["taskID": request.taskID.uuidString]

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        do {
            try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        } catch {
            logger.error("Scheduling failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func cancel(taskIDs: [UUID]) {
        guard !taskIDs.isEmpty else { return }
        let ids = taskIDs.map(\.uuidString)
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    /// The preferred hour on the due date. If that hour has passed today, one minute from now.
    /// Tasks due on an earlier day are already shown as overdue in the app, so they get no new alert.
    static func fireDate(for dueDate: Date, hour: Int, now: Date, calendar: Calendar) -> Date? {
        if calendar.startOfDay(for: dueDate) < calendar.startOfDay(for: now) { return nil }
        let preferred = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: dueDate) ?? dueDate
        return preferred > now ? preferred : now.addingTimeInterval(60)
    }
}

/// Used by UI tests and previews so no system permission prompt appears.
final class NoopReminderScheduler: ReminderScheduling, @unchecked Sendable {
    func authorizationStatus() async -> ReminderAuthorization { .denied }
    func requestAuthorization() async -> Bool { false }
    func schedule(_ request: ReminderRequest, hour: Int) async {}
    func cancel(taskIDs: [UUID]) {}
    func cancelAll() {}
}
