import CoreData
import OSLog

enum PersistenceError: LocalizedError {
    case storeLoadFailed(underlying: Error)
    case saveFailed(underlying: Error)
    case notFound

    var errorDescription: String? {
        switch self {
        case .storeLoadFailed: "LeafLoom couldn’t open its data store."
        case .saveFailed: "Your change couldn’t be saved. Please try again."
        case .notFound: "This item no longer exists."
        }
    }
}

/// Owns the Core Data stack. One instance per app launch (or per test, using `inMemory: true`).
final class PersistenceController: @unchecked Sendable {
    static let modelName = "LeafLoom"
    private static let logger = Logger(subsystem: "com.leafloom.LeafLoom", category: "Persistence")

    /// Loaded once: creating several `NSManagedObjectModel`s for the same entities confuses Core Data
    /// ("multiple NSEntityDescriptions claim the subclass"), which matters when tests create many stores.
    static let model: NSManagedObjectModel = {
        guard let url = Bundle.main.url(forResource: modelName, withExtension: "momd")
                ?? Bundle(for: PersistenceController.self).url(forResource: modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("LeafLoom.momd is missing from the app bundle — the data model must be part of the LeafLoom target.")
        }
        return model
    }()

    let container: NSPersistentContainer
    private(set) var loadError: Error?

    var viewContext: NSManagedObjectContext { container.viewContext }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: Self.modelName, managedObjectModel: Self.model)
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("No persistent store description")
        }
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        // Lightweight migration for future model versions (see docs/ARCHITECTURE.md §4).
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.setOption(FileProtectionType.completeUntilFirstUserAuthentication as NSObject, forKey: NSPersistentStoreFileProtectionKey)

        var capturedError: Error?
        container.loadPersistentStores { _, error in
            if let error {
                Self.logger.error("Store failed to load: \(error.localizedDescription, privacy: .public)")
                capturedError = error
            }
        }
        loadError = capturedError

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.name = "viewContext"
        container.viewContext.undoManager = nil
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// Saves only when there are changes; rolls back and rethrows a friendly error on failure.
    static func save(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            logger.error("Save failed: \(error.localizedDescription, privacy: .public)")
            context.rollback()
            throw PersistenceError.saveFailed(underlying: error)
        }
    }
}
