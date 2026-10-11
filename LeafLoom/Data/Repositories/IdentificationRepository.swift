import CoreData
import Foundation

@MainActor
final class IdentificationRepository {
    private let context: NSManagedObjectContext
    private let images: ImageStore
    private let now: () -> Date

    init(context: NSManagedObjectContext, images: ImageStore, now: @escaping () -> Date = { .now }) {
        self.context = context
        self.images = images
        self.now = now
    }

    func history() throws -> [IdentificationRecord] {
        let request = IdentificationRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \IdentificationRecord.dateCreated, ascending: false)]
        return try context.fetch(request)
    }

    /// Stores the top suggestion. Confidence is only persisted when a real model supplied it.
    @discardableResult
    func save(_ result: IdentificationResult, imageData: Data?) throws -> IdentificationRecord {
        guard let top = result.suggestions.first else { throw IdentificationError.noResults }
        let filename = try imageData.map { try images.save($0) }
        let record = IdentificationRecord(context: context)
        record.id = UUID()
        record.dateCreated = now()
        record.predictedLabel = top.displayName
        record.confidence = result.isDemo ? nil : top.confidence
        record.modelIdentifier = result.modelIdentifier
        record.isDemoResult = result.isDemo
        record.imageFilename = filename
        do {
            try PersistenceController.save(context)
        } catch {
            images.delete(filename)
            throw error
        }
        return record
    }

    func link(_ record: IdentificationRecord, to plant: Plant) throws {
        record.plant = plant
        try PersistenceController.save(context)
    }

    func delete(_ record: IdentificationRecord) throws {
        let file = record.imageFilename
        context.delete(record)
        try PersistenceController.save(context)
        images.delete(file)
    }
}
