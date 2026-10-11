import Foundation

/// Editable plant fields. Used by the form view model and the repository.
struct PlantDraft: Equatable, Sendable {
    var name = ""
    var commonName = ""
    var scientificName = ""
    var category: PlantCategory? = nil
    var identificationStatus: IdentificationStatus = .unknown
    var location = ""
    var acquisitionDate: Date? = nil
    var wateringIntervalDays: Int? = nil
    var fertilizingIntervalDays: Int? = nil
    var sunlightPreference: SunlightPreference? = nil
    var humidityPreference: HumidityPreference? = nil
    var soilPreference = ""
    var notes = ""
    var tags: [String] = []
    var isFavorite = false
}

struct CareTaskDraft: Equatable, Sendable {
    var plantID: UUID? = nil
    var title = ""
    var descriptionText = ""
    var category: CareCategory = .watering
    var dueDate: Date = .now
    var recurrenceIntervalDays: Int? = nil
    var notes = ""
}

struct JournalDraft: Equatable, Sendable {
    var plantID: UUID? = nil
    var entryDate: Date = .now
    var notes = ""
    var heightCm: Double? = nil
}

enum PlantField: Hashable { case name, category, wateringInterval, fertilizingInterval, acquisitionDate, notes }
enum TaskField: Hashable { case title, dueDate, recurrence }
enum JournalField: Hashable { case plant, notes, entryDate, height }

enum PlantValidator {
    static let nameMax = 60
    static let notesMax = 1000
    static let tagMax = 10
    static let intervalRange = 1...365

    static func collapseWhitespace(_ s: String) -> String {
        s.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// Lowercased, trimmed, de-duplicated (order preserved) and capped at 10.
    static func normaliseTags(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for raw in tags {
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !t.isEmpty, !seen.contains(t) else { continue }
            seen.insert(t)
            out.append(t)
            if out.count == tagMax { break }
        }
        return out
    }

    static func parseTags(_ input: String) -> [String] {
        normaliseTags(input.components(separatedBy: ","))
    }

    static func normalised(_ d: PlantDraft) -> PlantDraft {
        var n = d
        n.name = collapseWhitespace(d.name)
        n.commonName = collapseWhitespace(d.commonName)
        n.scientificName = collapseWhitespace(d.scientificName)
        n.location = collapseWhitespace(d.location)
        n.soilPreference = collapseWhitespace(d.soilPreference)
        n.notes = d.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        n.tags = normaliseTags(d.tags)
        return n
    }

    private static func intervalError(_ value: Int?) -> String? {
        guard let value else { return nil }
        return intervalRange.contains(value) ? nil : "Enter a whole number of days between 1 and 365."
    }

    static func validate(_ d: PlantDraft, now: Date = .now, calendar: CareCalendar = CareCalendar()) -> [PlantField: String] {
        var errors: [PlantField: String] = [:]
        let name = collapseWhitespace(d.name)
        if name.isEmpty {
            errors[.name] = "Give your plant a name."
        } else if name.count > nameMax {
            errors[.name] = "Keep the name under \(nameMax) characters."
        }
        if d.category == nil { errors[.category] = "Choose a category." }
        if let e = intervalError(d.wateringIntervalDays) { errors[.wateringInterval] = e }
        if let e = intervalError(d.fertilizingIntervalDays) { errors[.fertilizingInterval] = e }
        if let date = d.acquisitionDate, calendar.startOfDay(date) > calendar.startOfDay(now) {
            errors[.acquisitionDate] = "The acquisition date cannot be in the future."
        }
        if d.notes.count > notesMax { errors[.notes] = "Notes can be up to \(notesMax) characters." }
        return errors
    }

    static func validate(_ d: CareTaskDraft) -> [TaskField: String] {
        var errors: [TaskField: String] = [:]
        let title = collapseWhitespace(d.title)
        if title.isEmpty {
            errors[.title] = "Add a short title for this task."
        } else if title.count > nameMax {
            errors[.title] = "Keep the title under \(nameMax) characters."
        }
        if let e = intervalError(d.recurrenceIntervalDays) { errors[.recurrence] = e }
        return errors
    }

    static func validate(_ d: JournalDraft, now: Date = .now, calendar: CareCalendar = CareCalendar()) -> [JournalField: String] {
        var errors: [JournalField: String] = [:]
        if d.plantID == nil { errors[.plant] = "Choose which plant this entry is about." }
        let notes = d.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if notes.isEmpty {
            errors[.notes] = "Write a short note about what you observed."
        } else if d.notes.count > notesMax {
            errors[.notes] = "Notes can be up to \(notesMax) characters."
        }
        if calendar.startOfDay(d.entryDate) > calendar.startOfDay(now) {
            errors[.entryDate] = "Journal entries cannot be dated in the future."
        }
        if let h = d.heightCm, !(h > 0 && h <= 1000) {
            errors[.height] = "Height must be greater than 0 and at most 1000 cm."
        }
        return errors
    }
}
