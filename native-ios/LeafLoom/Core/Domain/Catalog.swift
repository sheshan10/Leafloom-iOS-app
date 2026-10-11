import Foundation

/// Plant categories. Raw values are persisted in Core Data and shared with the browser preview.
enum PlantCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case foliage, succulent, flowering, herb, tree, fern, trailing, edible

    var id: String { rawValue }

    var label: String {
        switch self {
        case .foliage: "Foliage"
        case .succulent: "Succulent & cactus"
        case .flowering: "Flowering"
        case .herb: "Herb"
        case .tree: "Tree & shrub"
        case .fern: "Fern"
        case .trailing: "Trailing & climbing"
        case .edible: "Fruit & vegetable"
        }
    }

    /// Template image generated from `categoryIcons.json` by `scripts/generate-native-assets.mjs`.
    var assetName: String { "Category" + rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
}

enum CareCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case watering, fertilizing, pruning, repotting, cleaning, inspection, custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .watering: "Watering"
        case .fertilizing: "Fertilising"
        case .pruning: "Pruning"
        case .repotting: "Repotting"
        case .cleaning: "Cleaning leaves"
        case .inspection: "Pest inspection"
        case .custom: "Custom"
        }
    }

    var verb: String {
        switch self {
        case .watering: "Water"
        case .fertilizing: "Fertilise"
        case .pruning: "Prune"
        case .repotting: "Repot"
        case .cleaning: "Clean leaves of"
        case .inspection: "Inspect"
        case .custom: "Care for"
        }
    }

    var symbol: String {
        switch self {
        case .watering: "drop.fill"
        case .fertilizing: "leaf.arrow.circlepath"
        case .pruning: "scissors"
        case .repotting: "shippingbox.fill"
        case .cleaning: "sparkles"
        case .inspection: "magnifyingglass"
        case .custom: "checklist"
        }
    }
}

enum SunlightPreference: String, CaseIterable, Identifiable, Codable, Sendable {
    case low, medium
    case brightIndirect = "bright-indirect"
    case fullSun = "full-sun"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .low: "Low light"
        case .medium: "Medium light"
        case .brightIndirect: "Bright, indirect"
        case .fullSun: "Full sun"
        }
    }
}

enum HumidityPreference: String, CaseIterable, Identifiable, Codable, Sendable {
    case low, average, high

    var id: String { rawValue }

    var label: String {
        switch self {
        case .low: "Low"
        case .average: "Average"
        case .high: "High"
        }
    }
}

enum IdentificationStatus: String, CaseIterable, Identifiable, Codable, Sendable {
    case identified, suggested, unknown

    var id: String { rawValue }

    var label: String {
        switch self {
        case .identified: "Identified"
        case .suggested: "AI suggestion"
        case .unknown: "Not identified"
        }
    }
}
