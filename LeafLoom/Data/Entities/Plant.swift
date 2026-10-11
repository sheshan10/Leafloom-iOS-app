import CoreData
import Foundation

@objc(Plant)
final class Plant: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var commonName: String?
    @NSManaged var scientificName: String?
    @NSManaged var categoryRaw: String
    @NSManaged var identificationStatusRaw: String
    @NSManaged var imageFilename: String?
    /// Asset-catalog image for bundled sample plants (sample photos are not copied to disk).
    @NSManaged var sampleAssetName: String?
    @NSManaged var location: String?
    @NSManaged var acquisitionDate: Date?
    @NSManaged var dateAdded: Date
    @NSManaged var wateringIntervalRaw: Int16
    @NSManaged var fertilizingIntervalRaw: Int16
    @NSManaged var sunlightRaw: String?
    @NSManaged var humidityRaw: String?
    @NSManaged var soilPreference: String?
    @NSManaged var notes: String?
    @NSManaged var tagsRaw: String?
    @NSManaged var isFavorite: Bool
    @NSManaged var isSample: Bool
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var careTasks: Set<CareTask>?
    @NSManaged var journalEntries: Set<JournalEntry>?
    @NSManaged var identifications: Set<IdentificationRecord>?

    @nonobjc class func fetchRequest() -> NSFetchRequest<Plant> {
        NSFetchRequest<Plant>(entityName: "Plant")
    }
}

extension Plant {
    var category: PlantCategory {
        get { PlantCategory(rawValue: categoryRaw) ?? .foliage }
        set { categoryRaw = newValue.rawValue }
    }

    var identificationStatus: IdentificationStatus {
        get { IdentificationStatus(rawValue: identificationStatusRaw) ?? .unknown }
        set { identificationStatusRaw = newValue.rawValue }
    }

    /// 0 in the store means "not set".
    var wateringIntervalDays: Int? {
        get { wateringIntervalRaw > 0 ? Int(wateringIntervalRaw) : nil }
        set { wateringIntervalRaw = Int16(clamping: newValue ?? 0) }
    }

    var fertilizingIntervalDays: Int? {
        get { fertilizingIntervalRaw > 0 ? Int(fertilizingIntervalRaw) : nil }
        set { fertilizingIntervalRaw = Int16(clamping: newValue ?? 0) }
    }

    var sunlightPreference: SunlightPreference? {
        get { sunlightRaw.flatMap(SunlightPreference.init(rawValue:)) }
        set { sunlightRaw = newValue?.rawValue }
    }

    var humidityPreference: HumidityPreference? {
        get { humidityRaw.flatMap(HumidityPreference.init(rawValue:)) }
        set { humidityRaw = newValue?.rawValue }
    }

    var tags: [String] {
        get { (tagsRaw ?? "").split(separator: ",").map(String.init).filter { !$0.isEmpty } }
        set { tagsRaw = newValue.isEmpty ? nil : newValue.joined(separator: ",") }
    }

    var tasksArray: [CareTask] { Array(careTasks ?? []) }
    var journalArray: [JournalEntry] { (journalEntries ?? []).sorted { $0.entryDate > $1.entryDate } }

    var nextOpenTask: CareTask? {
        tasksArray.filter { !$0.isCompleted }.min { $0.dueDate < $1.dueDate }
    }

    var draft: PlantDraft {
        PlantDraft(
            name: name,
            commonName: commonName ?? "",
            scientificName: scientificName ?? "",
            category: category,
            identificationStatus: identificationStatus,
            location: location ?? "",
            acquisitionDate: acquisitionDate,
            wateringIntervalDays: wateringIntervalDays,
            fertilizingIntervalDays: fertilizingIntervalDays,
            sunlightPreference: sunlightPreference,
            humidityPreference: humidityPreference,
            soilPreference: soilPreference ?? "",
            notes: notes ?? "",
            tags: tags,
            isFavorite: isFavorite
        )
    }

    /// Writes a validated, normalised draft. Does not touch id, dateAdded or images.
    func apply(_ d: PlantDraft, now: Date) {
        let n = PlantValidator.normalised(d)
        name = n.name
        commonName = n.commonName.nilIfEmpty
        scientificName = n.scientificName.nilIfEmpty
        category = n.category ?? .foliage
        identificationStatus = n.identificationStatus
        location = n.location.nilIfEmpty
        acquisitionDate = n.acquisitionDate
        wateringIntervalDays = n.wateringIntervalDays
        fertilizingIntervalDays = n.fertilizingIntervalDays
        sunlightPreference = n.sunlightPreference
        humidityPreference = n.humidityPreference
        soilPreference = n.soilPreference.nilIfEmpty
        notes = n.notes.nilIfEmpty
        tags = n.tags
        isFavorite = n.isFavorite
        updatedAt = now
    }
}

extension Plant: PlantRepresentable {
    var plantID: UUID { id }
    var plantName: String { name }
    var plantCommonName: String? { commonName }
    var plantScientificName: String? { scientificName }
    var plantCategory: PlantCategory { category }
    var plantLocation: String? { location }
    var plantTags: [String] { tags }
    var plantIsFavorite: Bool { isFavorite }
    var plantDateAdded: Date { dateAdded }
}

extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
