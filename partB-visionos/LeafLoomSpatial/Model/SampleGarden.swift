import Foundation

/// The same eight sample plants the iPhone app seeds, so demos tell one story across devices.
/// Fixed UUIDs keep saved room layouts valid between launches.
enum SampleGarden {
    static func plants(now: Date = .now, calendar: Calendar = .current) -> [SpatialPlant] {
        func daysAgo(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: now)) ?? now
        }
        func id(_ suffix: Int) -> UUID {
            UUID(uuidString: String(format: "1EAF5A7E-0000-4000-8000-%012ld", suffix))!
        }
        return [
            SpatialPlant(id: id(1), name: "Monty", commonName: "Swiss cheese plant", shape: .broadLeaf,
                         sunlight: .brightIndirect, wateringIntervalDays: 7, lastWatered: daysAgo(7),
                         tip: "Wipe the big leaves so they can catch light."),
            SpatialPlant(id: id(2), name: "Sunny", commonName: "Snake plant", shape: .upright,
                         sunlight: .low, wateringIntervalDays: 14, lastWatered: daysAgo(11),
                         tip: "Let the soil dry out completely between waterings."),
            SpatialPlant(id: id(3), name: "Goldie", commonName: "Golden pothos", shape: .trailing,
                         sunlight: .medium, wateringIntervalDays: 7, lastWatered: daysAgo(9),
                         tip: "Trim long vines to keep it bushy."),
            SpatialPlant(id: id(4), name: "Figgy", commonName: "Fiddle leaf fig", shape: .tree,
                         sunlight: .brightIndirect, wateringIntervalDays: 8, lastWatered: daysAgo(7),
                         tip: "Avoid moving it often; it dislikes change."),
            SpatialPlant(id: id(5), name: "Lily", commonName: "Peace lily", shape: .flowering,
                         sunlight: .medium, wateringIntervalDays: 5, lastWatered: daysAgo(6),
                         tip: "Drooping leaves usually mean it is thirsty."),
            SpatialPlant(id: id(6), name: "Aloe", commonName: "Aloe vera", shape: .rosette,
                         sunlight: .fullSun, wateringIntervalDays: 14, lastWatered: daysAgo(8),
                         tip: "Water deeply but rarely."),
            SpatialPlant(id: id(7), name: "Basil", commonName: "Sweet basil", shape: .herb,
                         sunlight: .fullSun, wateringIntervalDays: 2, lastWatered: daysAgo(2),
                         tip: "Pinch off flower buds to keep leaves coming."),
            SpatialPlant(id: id(8), name: "Orbi", commonName: "Calathea orbifolia", shape: .broadLeaf,
                         sunlight: .medium, wateringIntervalDays: 5, lastWatered: daysAgo(3),
                         tip: "Likes humidity; keep it away from heaters."),
        ]
    }
}
