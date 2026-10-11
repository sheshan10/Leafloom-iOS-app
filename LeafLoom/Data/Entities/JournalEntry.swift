import CoreData
import Foundation

@objc(JournalEntry)
final class JournalEntry: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var entryDate: Date
    @NSManaged var notes: String
    @NSManaged var imageFilename: String?
    @NSManaged var heightRaw: Double
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var plant: Plant?

    @nonobjc class func fetchRequest() -> NSFetchRequest<JournalEntry> {
        NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
    }
}

extension JournalEntry {
    /// -1 in the store means "not measured".
    var heightCm: Double? {
        get { heightRaw > 0 ? heightRaw : nil }
        set { heightRaw = newValue ?? -1 }
    }

    var draft: JournalDraft {
        JournalDraft(plantID: plant?.id, entryDate: entryDate, notes: notes, heightCm: heightCm)
    }
}
