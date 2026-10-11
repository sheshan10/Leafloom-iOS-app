import Foundation

/// Light a plant prefers. Ordered from darkest to brightest so distance between cases is meaningful.
enum Sunlight: Int, Codable, CaseIterable, Comparable, Sendable {
    case low, medium, brightIndirect, fullSun

    var label: String {
        switch self {
        case .low: "Low light"
        case .medium: "Medium light"
        case .brightIndirect: "Bright indirect"
        case .fullSun: "Full sun"
        }
    }

    var symbol: String {
        switch self {
        case .low: "moon"
        case .medium: "cloud.sun"
        case .brightIndirect: "sun.haze"
        case .fullSun: "sun.max"
        }
    }

    static func < (lhs: Sunlight, rhs: Sunlight) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// The silhouette used to build a procedural plant from RealityKit primitives.
enum PlantShape: String, Codable, CaseIterable, Sendable {
    case broadLeaf, upright, trailing, tree, flowering, rosette, herb
}

struct SpatialPlant: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var commonName: String
    var shape: PlantShape
    var sunlight: Sunlight
    var wateringIntervalDays: Int
    var lastWatered: Date
    var tip: String

    func nextWatering(calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: wateringIntervalDays, to: lastWatered) ?? lastWatered
    }

    func isWateringDue(now: Date = .now, calendar: Calendar = .current) -> Bool {
        calendar.startOfDay(for: nextWatering(calendar: calendar)) <= calendar.startOfDay(for: now)
    }
}
