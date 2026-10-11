import CoreData
import Foundation

struct PlantDeletionSummary: Equatable {
    var taskCount: Int
    var journalCount: Int
}

/// All plant mutations go through here so validation, images, schedules and reminders stay consistent.
@MainActor
final class PlantRepository {
    private let context: NSManagedObjectContext
    private let images: ImageStore
    private let tasks: CareTaskRepository
    private let now: () -> Date

    init(context: NSManagedObjectContext, images: ImageStore, tasks: CareTaskRepository, now: @escaping () -> Date = { .now }) {
        self.context = context
        self.images = images
        self.tasks = tasks
        self.now = now
    }

    func fetchAll() throws -> [Plant] {
        let request = Plant.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Plant.dateAdded, ascending: false)]
        return try context.fetch(request)
    }

    func plant(id: UUID) -> Plant? {
        let request = Plant.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Creates a plant. Optionally generates recurring watering/fertilising tasks from its intervals.
    @discardableResult
    func create(_ draft: PlantDraft, imageData: Data? = nil, createCareSchedule: Bool = false, identification: IdentificationRecord? = nil) throws -> Plant {
        let errors = PlantValidator.validate(draft, now: now())
        guard errors.isEmpty else { throw ValidationFailure(messages: Array(errors.values)) }

        let filename = try imageData.map { try images.save($0) }
        let stamp = now()
        let plant = Plant(context: context)
        plant.id = UUID()
        plant.dateAdded = stamp
        plant.createdAt = stamp
        plant.isSample = false
        plant.imageFilename = filename
        plant.apply(draft, now: stamp)
        identification?.plant = plant

        var schedule: [CareTask] = []
        if createCareSchedule {
            schedule = tasks.makeSchedule(for: plant)
        }
        do {
            try PersistenceController.save(context)
        } catch {
            images.delete(filename)
            throw error
        }
        tasks.scheduleReminders(for: schedule)
        return plant
    }

    func update(_ plant: Plant, with draft: PlantDraft, newImageData: Data? = nil, removeImage: Bool = false) throws {
        let errors = PlantValidator.validate(draft, now: now())
        guard errors.isEmpty else { throw ValidationFailure(messages: Array(errors.values)) }

        let oldFilename = plant.imageFilename
        var newFilename: String?
        if let newImageData {
            newFilename = try images.save(newImageData)
            plant.imageFilename = newFilename
            plant.sampleAssetName = nil
        } else if removeImage {
            plant.imageFilename = nil
            plant.sampleAssetName = nil
        }
        plant.apply(draft, now: now())
        do {
            try PersistenceController.save(context)
        } catch {
            images.delete(newFilename)
            throw error
        }
        if newImageData != nil || removeImage { images.delete(oldFilename) }
        // Task titles/notifications mention the plant name.
        tasks.scheduleReminders(for: plant.tasksArray.filter { !$0.isCompleted })
    }

    func toggleFavorite(_ plant: Plant) throws {
        plant.isFavorite.toggle()
        plant.updatedAt = now()
        try PersistenceController.save(context)
    }

    func deletionSummary(for plant: Plant) -> PlantDeletionSummary {
        PlantDeletionSummary(taskCount: plant.careTasks?.count ?? 0, journalCount: plant.journalEntries?.count ?? 0)
    }

    /// Deletes the plant. Core Data cascades to its tasks and journal entries and nullifies identifications;
    /// this method also cancels reminders and removes image files so nothing is orphaned.
    func delete(_ plant: Plant) throws {
        let taskIDs = plant.tasksArray.map(\.id)
        let files = [plant.imageFilename] + plant.journalArray.map(\.imageFilename)
        context.delete(plant)
        try PersistenceController.save(context)
        tasks.cancelReminders(for: taskIDs)
        files.forEach(images.delete)
    }
}

struct ValidationFailure: LocalizedError {
    var messages: [String]
    var errorDescription: String? { messages.first ?? "Please check the highlighted fields." }
}
