import Foundation

/// Calendar arithmetic used by the domain logic. Takes an explicit calendar so tests are deterministic.
struct CareCalendar: Sendable {
    var calendar: Calendar

    init(calendar: Calendar = .current) {
        var cal = calendar
        cal.firstWeekday = 2 // Weeks start on Monday, matching the browser preview.
        self.calendar = cal
    }

    func startOfDay(_ date: Date) -> Date { calendar.startOfDay(for: date) }

    func addingDays(_ days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date.addingTimeInterval(TimeInterval(days) * 86_400)
    }

    /// Whole calendar days from `from` to `to` (negative when `to` is earlier).
    func daysBetween(_ from: Date, _ to: Date) -> Int {
        calendar.dateComponents([.day], from: startOfDay(from), to: startOfDay(to)).day ?? 0
    }

    func startOfWeek(_ date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? startOfDay(date)
    }

    func startOfMonth(_ date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? startOfDay(date)
    }

    func addingMonths(_ months: Int, to date: Date) -> Date {
        calendar.date(byAdding: .month, value: months, to: date) ?? date
    }

    /// `day` at the hour/minute of `time`.
    func combine(day: Date, timeOf time: Date) -> Date {
        let t = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: t.hour ?? 9, minute: t.minute ?? 0, second: 0, of: day) ?? day
    }

    func at(hour: Int, on day: Date) -> Date {
        calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }
}

enum RelativeDayFormatter {
    static func string(for date: Date, now: Date = .now, calendar: CareCalendar = CareCalendar()) -> String {
        let diff = calendar.daysBetween(now, date)
        switch diff {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case -1: return "Yesterday"
        case 2...6: return date.formatted(.dateTime.weekday(.wide))
        case let d where d < -1 && d > -7: return "\(-d) days ago"
        default: return date.formatted(.dateTime.day().month(.abbreviated))
        }
    }

    static func greeting(for date: Date = .now, calendar: Calendar = .current) -> String {
        switch calendar.component(.hour, from: date) {
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        default: "Good evening"
        }
    }
}
