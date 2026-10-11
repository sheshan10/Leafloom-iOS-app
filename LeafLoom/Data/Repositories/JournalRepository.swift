import CoreData
import Foundation

@MainActor
final class JournalRepository {
    private let context: NSManagedObjectContext
    private let images: ImageStore
    private let now: () -> Date

    init(context: NSManagedObjectContext, images: ImageStore, now: @escaping () -> Date = { .now }) {
        self.context = context
        self.images = images
        self.now = now
    }

    func entries(for plant: Plant) -> [JournalEntry] { plant.journalArray }

    func entry(id: UUID) -> JournalEntry? {
        let request = JournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private func plant(id: UUID?) -> Plant? {
        guard let id else { return nil }
        let request = Plant.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    @discardableResult
    func create(_ draft: JournalDraft, imageData: Data? = nil) throws -> JournalEntry {
        let errors = PlantValidator.validate(draft, now: now())
        guard errors.isEmpty, let plant = plant(id: draft.plantID) else {
            throw ValidationFailure(messages: Array(errors.values) + (errors.isEmpty ? ["Choose which plant this entry is about."] : []))
        }
        let filename = try imageData.map { try images.save($0) }
        let stamp = now()
        let entry = JournalEntry(context: context)
        entry.id = UUID()
        entry.createdAt = stamp
        entry.updatedAt = stamp
        entry.entryDate = draft.entryDate
        entry.notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.heightCm = draft.heightCm
        entry.imageFilename = filename
        entry.plant = plant
        do {
            try PersistenceController.save(context)
        } catch {
            images.delete(filename)
            throw error
        }
        return entry
    }

    func update(_ entry: JournalEntry, with draft: JournalDraft, newImageData: Data? = nil, removeImage: Bool = false) throws {
        let errors = PlantValidator.validate(draft, now: now())
        guard errors.isEmpty else { throw ValidationFailure(messages: Array(errors.values)) }
        let old = entry.imageFilename
        var newFilename: String?
        if let newImageData {
            newFilename = try images.save(newImageData)
            entry.imageFilename = newFilename
        } else if removeImage {
            entry.imageFilename = nil
        }
        entry.entryDate = draft.entryDate
        entry.notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.heightCm = draft.heightCm
        if let p = plant(id: draft.plantID) { entry.plant = p }
        entry.updatedAt = now()
        do {
            try PersistenceController.save(context)
        } catch {
            images.delete(newFilename)
            throw error
        }
        if newImageData != nil || removeImage { images.delete(old) }
    }

    func delete(_ entry: JournalEntry) throws {
        let file = entry.imageFilename
        context.delete(entry)
        try PersistenceController.save(context)
        images.delete(file)
    }
}
