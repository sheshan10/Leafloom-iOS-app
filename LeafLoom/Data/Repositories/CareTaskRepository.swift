import CoreData
import Foundation

/// Care-task CRUD, completion with recurrence, undo, and reminder synchronisation.
@MainActor
final class CareTaskRepository {
    private let context: NSManagedObjectContext
    private let scheduler: ReminderScheduling
    private let calendar: CareCalendar
    private let now: () -> Date
    /// Returns the reminder hour, or nil when reminders are switched off in Settings.
    var reminderHour: () -> Int?

    init(context: NSManagedObjectContext, scheduler: ReminderScheduling, calendar: CareCalendar = CareCalendar(), now: @escaping () -> Date = { .now }, reminderHour: @escaping () -> Int? = { 9 }) {
        self.context = context
        self.scheduler = scheduler
        self.calendar = calendar
        self.now = now
        self.reminderHour = reminderHour
    }

    func fetchAll() throws -> [CareTask] {
        let request = CareTask.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CareTask.dueDate, ascending: true)]
        return try context.fetch(request)
    }

    func task(id: UUID) -> CareTask? {
        let request = CareTask.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    func series(of task: CareTask) -> [CareTask] {
        let request = CareTask.fetchRequest()
        request.predicate = NSPredicate(format: "seriesID == %@", task.seriesID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CareTask.dueDate, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    private func plant(id: UUID?) -> Plant? {
        guard let id else { return nil }
        let request = Plant.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    @discardableResult
    func create(_ draft: CareTaskDraft) throws -> CareTask {
        let errors = PlantValidator.validate(draft)
        guard errors.isEmpty else { throw ValidationFailure(messages: Array(errors.values)) }
        let stamp = now()
        let task = CareTask(context: context)
        task.id = UUID()
        task.seriesID = UUID()
        task.isCompleted = false
        task.isSample = false
        task.createdAt = stamp
        apply(draft, to: task, stamp: stamp)
        try PersistenceController.save(context)
        scheduleReminders(for: [task])
        return task
    }

    func update(_ task: CareTask, with draft: CareTaskDraft) throws {
        let errors = PlantValidator.validate(draft)
        guard errors.isEmpty else { throw ValidationFailure(messages: Array(errors.values)) }
        apply(draft, to: task, stamp: now())
        try PersistenceController.save(context)
        if task.isCompleted { cancelReminders(for: [task.id]) } else { scheduleReminders(for: [task]) }
    }

    private func apply(_ draft: CareTaskDraft, to task: CareTask, stamp: Date) {
        task.title = PlantValidator.collapseWhitespace(draft.title)
        task.descriptionText = draft.descriptionText.nilIfEmpty
        task.notes = draft.notes.nilIfEmpty
        task.category = draft.category
        task.dueDate = draft.dueDate
        task.recurrenceIntervalDays = draft.recurrenceIntervalDays
        task.plant = plant(id: draft.plantID)
        task.updatedAt = stamp
    }

    func delete(_ task: CareTask) throws {
        let id = task.id
        context.delete(task)
        try PersistenceController.save(context)
        cancelReminders(for: [id])
    }

    /// Marks the task done. Recurring tasks stay in history and spawn the next occurrence in the same series.
    @discardableResult
    func complete(_ task: CareTask) throws -> CareTask? {
        guard !task.isCompleted else { return nil }
        let stamp = now()
        var spawned: CareTask?
        if let next = RecurrenceCalculator.nextDueDate(originalDue: task.dueDate, intervalDays: task.recurrenceIntervalDays, completedAt: stamp, calendar: calendar) {
            let n = CareTask(context: context)
            n.id = UUID()
            n.seriesID = task.seriesID
            n.title = task.title
            n.descriptionText = task.descriptionText
            n.category = task.category
            n.recurrenceIntervalDays = task.recurrenceIntervalDays
            n.plant = task.plant
            n.dueDate = next
            n.isCompleted = false
            n.isSample = task.isSample
            n.createdAt = stamp
            n.updatedAt = stamp
            spawned = n
        }
        task.isCompleted = true
        task.completedAt = stamp
        task.spawnedTaskID = spawned?.id
        task.updatedAt = stamp
        try PersistenceController.save(context)
        cancelReminders(for: [task.id])
        if let spawned { scheduleReminders(for: [spawned]) }
        return spawned
    }

    /// Reverses a completion. The spawned occurrence is removed only if the user hasn't touched it.
    func undoCompletion(_ task: CareTask) throws {
        guard task.isCompleted else { return }
        var removedID: UUID?
        if let spawnedID = task.spawnedTaskID, let spawned = self.task(id: spawnedID),
           RecurrenceCalculator.shouldDeleteSpawnedOnUndo(spawnedIsCompleted: spawned.isCompleted, spawnedCreatedAt: spawned.createdAt, spawnedUpdatedAt: spawned.updatedAt) {
            removedID = spawned.id
            context.delete(spawned)
        }
        task.isCompleted = false
        task.completedAt = nil
        task.spawnedTaskID = nil
        task.updatedAt = now()
        try PersistenceController.save(context)
        if let removedID { cancelReminders(for: [removedID]) }
        scheduleReminders(for: [task])
    }

    /// Builds (unsaved) recurring watering/fertilising tasks for a new plant at the reminder hour.
    func makeSchedule(for plant: Plant) -> [CareTask] {
        let hour = reminderHour() ?? 9
        let stamp = now()
        var out: [CareTask] = []
        func make(_ category: CareCategory, interval: Int, firstInDays: Int) {
            let t = CareTask(context: context)
            t.id = UUID()
            t.seriesID = UUID()
            t.title = "\(category.verb) \(plant.name)"
            t.category = category
            t.recurrenceIntervalDays = interval
            t.dueDate = calendar.at(hour: hour, on: calendar.addingDays(firstInDays, to: calendar.startOfDay(stamp)))
            t.isCompleted = false
            t.isSample = false
            t.plant = plant
            t.createdAt = stamp
            t.updatedAt = stamp
            out.append(t)
        }
        if let w = plant.wateringIntervalDays { make(.watering, interval: w, firstInDays: 1) }
        if let f = plant.fertilizingIntervalDays { make(.fertilizing, interval: f, firstInDays: f) }
        return out
    }

    // MARK: Reminders

    func scheduleReminders(for tasks: [CareTask]) {
        guard let hour = reminderHour() else {
            cancelReminders(for: tasks.map(\.id))
            return
        }
        let requests = tasks.filter { !$0.isCompleted }.map {
            ReminderRequest(taskID: $0.id, title: $0.title, plantName: $0.plant?.name, dueDate: $0.dueDate)
        }
        let scheduler = scheduler
        Task {
            for r in requests { await scheduler.schedule(r, hour: hour) }
        }
    }

    func cancelReminders(for ids: [UUID]) {
        scheduler.cancel(taskIDs: ids)
    }

    /// Re-creates every pending reminder, e.g. after the reminder hour changes or permission is granted.
    func rescheduleAll() {
        scheduler.cancelAll()
        let open = (try? fetchAll())?.filter { !$0.isCompleted } ?? []
        scheduleReminders(for: open)
    }
}
