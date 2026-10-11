import Observation
import SwiftUI

@MainActor
@Observable
final class CareTaskFormViewModel {
    enum Mode: Equatable {
        case create(plantID: UUID?)
        case edit(UUID)
    }

    let mode: Mode
    var draft: CareTaskDraft
    var repeats: Bool
    var errors: [TaskField: String] = [:]
    var saveError: String?
    private let original: CareTaskDraft
    /// The title last generated from category + plant; replaced automatically until the user types their own.
    private var autoTitle: String

    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var hasChanges: Bool { effectiveDraft != original }

    private var effectiveDraft: CareTaskDraft {
        var d = draft
        if !repeats { d.recurrenceIntervalDays = nil }
        return d
    }

    init(mode: Mode, existing: CareTask?, defaultHour: Int, now: Date = .now, calendar: CareCalendar = CareCalendar()) {
        self.mode = mode
        let initial: CareTaskDraft
        switch mode {
        case let .create(plantID):
            var d = CareTaskDraft(plantID: plantID)
            let today = calendar.at(hour: defaultHour, on: calendar.startOfDay(now))
            d.dueDate = today > now ? today : calendar.at(hour: defaultHour, on: calendar.addingDays(1, to: calendar.startOfDay(now)))
            initial = d
        case .edit:
            initial = existing?.draft ?? CareTaskDraft()
        }
        draft = initial
        original = initial
        repeats = initial.recurrenceIntervalDays != nil
        autoTitle = initial.title
    }

    /// Suggests "Water Monty" etc. while the title is still the generated one (or empty).
    func refreshSuggestedTitle(plantName: String?) {
        guard draft.title.isEmpty || draft.title == autoTitle else { return }
        let suggestion = plantName.map { "\(draft.category.verb) \($0)" } ?? draft.category.label
        draft.title = suggestion
        autoTitle = suggestion
    }

    func save(env: AppEnvironment) -> Bool {
        let d = effectiveDraft
        errors = PlantValidator.validate(d)
        if repeats && d.recurrenceIntervalDays == nil { errors[.recurrence] = "Enter how often this repeats, or turn off Repeat." }
        guard errors.isEmpty else { return false }
        do {
            switch mode {
            case .create:
                try env.tasks.create(d)
            case let .edit(id):
                guard let task = env.tasks.task(id: id) else { throw PersistenceError.notFound }
                try env.tasks.update(task, with: d)
            }
            return true
        } catch {
            saveError = error.localizedDescription
            return false
        }
    }
}
