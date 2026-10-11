import CoreData
import Foundation

@objc(CareTask)
final class CareTask: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    /// Shared by every occurrence of a recurring task.
    @NSManaged var seriesID: UUID
    @NSManaged var title: String
    @NSManaged var descriptionText: String?
    @NSManaged var categoryRaw: String
    @NSManaged var dueDate: Date
    @NSManaged var completedAt: Date?
    @NSManaged var isCompleted: Bool
    @NSManaged var recurrenceIntervalRaw: Int16
    /// The next occurrence created when this task was completed (used by undo).
    @NSManaged var spawnedTaskID: UUID?
    @NSManaged var notes: String?
    @NSManaged var isSample: Bool
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var plant: Plant?

    @nonobjc class func fetchRequest() -> NSFetchRequest<CareTask> {
        NSFetchRequest<CareTask>(entityName: "CareTask")
    }
}

extension CareTask {
    var category: CareCategory {
        get { CareCategory(rawValue: categoryRaw) ?? .custom }
        set { categoryRaw = newValue.rawValue }
    }

    /// 0 in the store means "does not repeat".
    var recurrenceIntervalDays: Int? {
        get { recurrenceIntervalRaw > 0 ? Int(recurrenceIntervalRaw) : nil }
        set { recurrenceIntervalRaw = Int16(clamping: newValue ?? 0) }
    }

    var status: CareStatus { CareStatusEvaluator.status(of: self) }

    var draft: CareTaskDraft {
        CareTaskDraft(
            plantID: plant?.id,
            title: title,
            descriptionText: descriptionText ?? "",
            category: category,
            dueDate: dueDate,
            recurrenceIntervalDays: recurrenceIntervalDays,
            notes: notes ?? ""
        )
    }

    var recurrenceDescription: String? {
        guard let n = recurrenceIntervalDays else { return nil }
        return n == 1 ? "Every day" : n == 7 ? "Every week" : "Every \(n) days"
    }
}

extension CareTask: CareTaskRepresentable {
    var taskID: UUID { id }
    var taskPlantID: UUID? { plant?.id }
    var taskCategory: CareCategory { category }
    var taskDueDate: Date { dueDate }
    var taskIsCompleted: Bool { isCompleted }
    var taskCompletedAt: Date? { completedAt }
    var taskRecurrenceDays: Int? { recurrenceIntervalDays }
}
