import CoreData
import UIKit

/// Creates the demonstration collection shown on first launch (mirrors `sampleData.ts` in the preview).
/// Every record is flagged `isSample` so it can be labelled in the UI and removed with Reset / Erase.
/// Dates are relative to `now`, so there is always something due today, something overdue and history.
struct SampleDataSeeder {
    struct Spec {
        let key: String
        let name: String
        let commonName: String
        let scientificName: String
        let category: PlantCategory
        let location: String
        let asset: String
        let addedDaysAgo: Int
        let water: Int
        var fertilise: Int? = nil
        let nextWaterOffset: Int
        let sunlight: SunlightPreference
        let humidity: HumidityPreference
        let soil: String
        var favorite = false
        let tags: [String]
        var notes: String? = nil
    }

    static let specs: [Spec] = [
        Spec(key: "monstera", name: "Monty", commonName: "Swiss cheese plant", scientificName: "Monstera deliciosa", category: .foliage, location: "Living room", asset: "SampleMonstera", addedDaysAgo: 150, water: 7, fertilise: 30, nextWaterOffset: 0, sunlight: .brightIndirect, humidity: .average, soil: "Chunky aroid mix", favorite: true, tags: ["statement", "fast-growing"], notes: "New leaf unfurling near the moss pole."),
        Spec(key: "snake", name: "Sunny", commonName: "Snake plant", scientificName: "Dracaena trifasciata", category: .succulent, location: "Bedroom", asset: "SampleSnakePlant", addedDaysAgo: 120, water: 14, nextWaterOffset: 3, sunlight: .low, humidity: .low, soil: "Cactus mix", tags: ["low-maintenance"]),
        Spec(key: "pothos", name: "Goldie", commonName: "Golden pothos", scientificName: "Epipremnum aureum", category: .trailing, location: "Office", asset: "SamplePothos", addedDaysAgo: 95, water: 7, fertilise: 30, nextWaterOffset: -2, sunlight: .medium, humidity: .average, soil: "Potting mix + perlite", favorite: true, tags: ["trailing", "propagated"]),
        Spec(key: "fiddle", name: "Figgy", commonName: "Fiddle leaf fig", scientificName: "Ficus lyrata", category: .tree, location: "Living room", asset: "SampleFiddleLeafFig", addedDaysAgo: 70, water: 8, fertilise: 30, nextWaterOffset: 1, sunlight: .brightIndirect, humidity: .average, soil: "Indoor plant mix", tags: ["tall"]),
        Spec(key: "lily", name: "Lily", commonName: "Peace lily", scientificName: "Spathiphyllum wallisii", category: .flowering, location: "Bathroom", asset: "SamplePeaceLily", addedDaysAgo: 48, water: 5, nextWaterOffset: -1, sunlight: .medium, humidity: .high, soil: "Moisture-retentive mix", tags: ["flowering"]),
        Spec(key: "aloe", name: "Aloe", commonName: "Aloe vera", scientificName: "Aloe vera", category: .succulent, location: "Kitchen window", asset: "SampleAloeVera", addedDaysAgo: 30, water: 14, nextWaterOffset: 6, sunlight: .fullSun, humidity: .low, soil: "Gritty succulent mix", tags: ["sun-lover"]),
        Spec(key: "basil", name: "Basil", commonName: "Sweet basil", scientificName: "Ocimum basilicum", category: .herb, location: "Kitchen window", asset: "SampleBasil", addedDaysAgo: 12, water: 2, fertilise: 21, nextWaterOffset: 0, sunlight: .fullSun, humidity: .average, soil: "Rich herb compost", favorite: true, tags: ["edible", "kitchen"]),
        Spec(key: "calathea", name: "Orbi", commonName: "Calathea orbifolia", scientificName: "Goeppertia orbifolia", category: .foliage, location: "Office", asset: "SampleCalathea", addedDaysAgo: 4, water: 5, nextWaterOffset: 2, sunlight: .medium, humidity: .high, soil: "Airy moisture-retentive mix", tags: ["humidity-lover"]),
    ]

    let calendar: CareCalendar
    let images: ImageStore?

    init(calendar: CareCalendar = CareCalendar(), images: ImageStore? = nil) {
        self.calendar = calendar
        self.images = images
    }

    private func at(_ now: Date, _ days: Int, hour: Int = 9) -> Date {
        calendar.at(hour: hour, on: calendar.addingDays(days, to: calendar.startOfDay(now)))
    }

    /// Inserts the sample collection into `context` (does not save).
    func insertSamples(into context: NSManagedObjectContext, now: Date) {
        var plantsByKey: [String: Plant] = [:]
        for s in Self.specs {
            let added = at(now, -s.addedDaysAgo, hour: 11)
            let p = Plant(context: context)
            p.id = UUID()
            p.name = s.name
            p.commonName = s.commonName
            p.scientificName = s.scientificName
            p.category = s.category
            p.identificationStatus = .identified
            p.sampleAssetName = s.asset
            p.location = s.location
            p.acquisitionDate = at(now, -s.addedDaysAgo - 7)
            p.dateAdded = added
            p.wateringIntervalDays = s.water
            p.fertilizingIntervalDays = s.fertilise
            p.sunlightPreference = s.sunlight
            p.humidityPreference = s.humidity
            p.soilPreference = s.soil
            p.notes = s.notes
            p.tags = s.tags
            p.isFavorite = s.favorite
            p.isSample = true
            p.createdAt = added
            p.updatedAt = added
            plantsByKey[s.key] = p

            let history = min(56, s.addedDaysAgo)
            insertSeries(plant: p, category: .watering, interval: s.water, nextOffset: s.nextWaterOffset, history: history, now: now, context: context)
            if let f = s.fertilise {
                insertSeries(plant: p, category: .fertilizing, interval: f, nextOffset: s.nextWaterOffset + 4, history: history, now: now, context: context)
            }
        }

        let inspection = CareTask(context: context)
        fill(inspection, title: "Check all plants for pests", description: "Look under leaves and along stems for webbing, sticky residue or spots.", category: .inspection, due: at(now, 4), interval: 14, plant: nil, now: now)

        let repot = CareTask(context: context)
        fill(repot, title: "Repot Figgy into a larger pot", description: "Roots are circling the base. Move up one pot size in spring.", category: .repotting, due: at(now, 12), interval: nil, plant: plantsByKey["fiddle"], now: now)

        let journal: [(String, Int, String, Double?, String?)] = [
            ("monstera", -140, "Brought Monty home. Four leaves, one with first splits.", 48, nil),
            ("monstera", -60, "Added a moss pole. Two new leaves this month.", 61, nil),
            ("monstera", -3, "Biggest leaf so far, with seven splits.", 74, "SampleMonstera"),
            ("pothos", -20, "Took three cuttings to propagate in water.", nil, "SamplePothos"),
        ]
        for (key, offset, notes, height, asset) in journal {
            let e = JournalEntry(context: context)
            e.id = UUID()
            e.plant = plantsByKey[key]
            e.entryDate = at(now, offset)
            e.notes = notes
            e.heightCm = height
            e.createdAt = now
            e.updatedAt = now
            if let asset, let images, let image = UIImage(named: asset) {
                e.imageFilename = try? images.save(image)
            }
        }
    }

    private func fill(_ t: CareTask, title: String, description: String, category: CareCategory, due: Date, interval: Int?, plant: Plant?, now: Date) {
        t.id = UUID()
        t.seriesID = UUID()
        t.title = title
        t.descriptionText = description
        t.category = category
        t.dueDate = due
        t.recurrenceIntervalDays = interval
        t.isCompleted = false
        t.isSample = true
        t.plant = plant
        t.createdAt = now
        t.updatedAt = now
    }

    /// A recurring series: past completed occurrences (history) plus one open occurrence.
    private func insertSeries(plant: Plant, category: CareCategory, interval: Int, nextOffset: Int, history: Int, now: Date, context: NSManagedObjectContext) {
        let seriesID = UUID()
        var newer: CareTask?
        var k = 0
        var offset = nextOffset
        while offset >= -history {
            let due = at(now, offset)
            let isOpen = k == 0
            // Occasionally completed a day late so the history looks realistic.
            let completed: Date? = isOpen ? nil : calendar.addingDays(k % 3 == 0 ? 1 : 0, to: due)
            let t = CareTask(context: context)
            t.id = UUID()
            t.seriesID = seriesID
            t.plant = plant
            t.title = "\(category.verb) \(plant.name)"
            t.descriptionText = category == .watering
                ? "Water until it drains from the pot, then empty the saucer."
                : "Use a balanced liquid fertiliser at half strength."
            t.category = category
            t.dueDate = due
            t.isCompleted = !isOpen
            t.completedAt = completed
            t.recurrenceIntervalDays = interval
            t.isSample = true
            t.createdAt = completed ?? now
            t.updatedAt = completed ?? now
            t.spawnedTaskID = newer?.id
            newer = t
            offset -= interval
            k += 1
        }
    }
}

/// First-launch seeding, reset and erase. Runs on a background context; the view context merges.
@MainActor
final class DataMaintenance {
    private let persistence: PersistenceController
    private let images: ImageStore
    private let scheduler: ReminderScheduling
    private let defaults: UserDefaults
    static let seededKey = "sampleDataSeeded"

    init(persistence: PersistenceController, images: ImageStore, scheduler: ReminderScheduling, defaults: UserDefaults = .standard) {
        self.persistence = persistence
        self.images = images
        self.scheduler = scheduler
        self.defaults = defaults
    }

    /// Seeds once per install. The flag prevents duplicates on every launch.
    func seedIfNeeded(now: Date = .now) throws {
        guard !defaults.bool(forKey: Self.seededKey) else { return }
        try replaceAll(withSamples: true, now: now)
    }

    func resetToSampleData(now: Date = .now) throws {
        try replaceAll(withSamples: true, now: now)
    }

    func eraseAll() throws {
        try replaceAll(withSamples: false, now: .now)
    }

    private func replaceAll(withSamples: Bool, now: Date) throws {
        let context = persistence.newBackgroundContext()
        let seeder = SampleDataSeeder(images: images)
        var thrown: Error?
        scheduler.cancelAll()
        images.deleteAll()
        context.performAndWait {
            do {
                for entity in ["CareTask", "JournalEntry", "IdentificationRecord", "Plant"] {
                    let request = NSFetchRequest<NSManagedObject>(entityName: entity)
                    request.includesPropertyValues = false
                    for object in try context.fetch(request) { context.delete(object) }
                }
                if withSamples { seeder.insertSamples(into: context, now: now) }
                try PersistenceController.save(context)
            } catch {
                thrown = error
            }
        }
        if let thrown { throw thrown }
        defaults.set(true, forKey: Self.seededKey)
        persistence.viewContext.refreshAllObjects()
    }
}
