import CoreData
import Foundation

@objc(IdentificationRecord)
final class IdentificationRecord: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var dateCreated: Date
    @NSManaged var imageFilename: String?
    @NSManaged var predictedLabel: String
    @NSManaged var confidenceRaw: Double
    @NSManaged var modelIdentifier: String
    @NSManaged var isDemoResult: Bool
    @NSManaged var plant: Plant?

    @nonobjc class func fetchRequest() -> NSFetchRequest<IdentificationRecord> {
        NSFetchRequest<IdentificationRecord>(entityName: "IdentificationRecord")
    }
}

extension IdentificationRecord {
    /// -1 in the store means "not supplied". Demo results never have a confidence.
    var confidence: Double? {
        get { confidenceRaw >= 0 ? confidenceRaw : nil }
        set { confidenceRaw = newValue ?? -1 }
    }
}
