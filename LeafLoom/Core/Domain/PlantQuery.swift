import Foundation

/// The minimal view of a plant used by search, filtering, sorting and insights.
protocol PlantRepresentable {
    var plantID: UUID { get }
    var plantName: String { get }
    var plantCommonName: String? { get }
    var plantScientificName: String? { get }
    var plantCategory: PlantCategory { get }
    var plantLocation: String? { get }
    var plantTags: [String] { get }
    var plantIsFavorite: Bool { get }
    var plantDateAdded: Date { get }
}

struct PlantSnapshot: PlantRepresentable, Hashable, Sendable {
    var plantID = UUID()
    var plantName: String
    var plantCommonName: String?
    var plantScientificName: String?
    var plantCategory: PlantCategory = .foliage
    var plantLocation: String?
    var plantTags: [String] = []
    var plantIsFavorite = false
    var plantDateAdded: Date = .now
}

enum PlantSort: String, CaseIterable, Identifiable {
    case recent, alphabetical, nextCare

    var id: String { rawValue }

    var label: String {
        switch self {
        case .recent: "Recently added"
        case .alphabetical: "A–Z"
        case .nextCare: "Next care"
        }
    }
}

struct PlantQuery: Equatable {
    var search = ""
    var categories: Set<PlantCategory> = []
    var location: String? = nil
    var favoritesOnly = false
    var sort: PlantSort = .recent

    var isFiltering: Bool {
        !search.trimmingCharacters(in: .whitespaces).isEmpty || !categories.isEmpty || location != nil || favoritesOnly
    }

    /// Case- and diacritic-insensitive match on name, common name, scientific name and tags.
    static func matches(_ plant: some PlantRepresentable, search: String) -> Bool {
        let needle = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return true }
        let fields = [plant.plantName, plant.plantCommonName ?? "", plant.plantScientificName ?? ""] + plant.plantTags
        return fields.contains { $0.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }

    /// Earliest incomplete due date per plant.
    static func nextCareIndex(_ tasks: [some CareTaskRepresentable]) -> [UUID: Date] {
        var index: [UUID: Date] = [:]
        for t in tasks where !t.taskIsCompleted {
            guard let id = t.taskPlantID else { continue }
            if let current = index[id], current <= t.taskDueDate { continue }
            index[id] = t.taskDueDate
        }
        return index
    }

    func apply<P: PlantRepresentable>(to plants: [P], nextCare: [UUID: Date] = [:]) -> [P] {
        let filtered = plants.filter { p in
            Self.matches(p, search: search)
                && (categories.isEmpty || categories.contains(p.plantCategory))
                && (location == nil || p.plantLocation == location)
                && (!favoritesOnly || p.plantIsFavorite)
        }
        let byName: (P, P) -> Bool = { $0.plantName.localizedCaseInsensitiveCompare($1.plantName) == .orderedAscending }
        switch sort {
        case .alphabetical:
            return filtered.sorted(by: byName)
        case .nextCare:
            return filtered.sorted { a, b in
                let da = nextCare[a.plantID] ?? .distantFuture
                let db = nextCare[b.plantID] ?? .distantFuture
                return da == db ? byName(a, b) : da < db
            }
        case .recent:
            return filtered.sorted { $0.plantDateAdded > $1.plantDateAdded }
        }
    }

    static func distinctLocations(_ plants: [some PlantRepresentable]) -> [String] {
        let locations = plants.compactMap { $0.plantLocation?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return Array(Set(locations)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}
