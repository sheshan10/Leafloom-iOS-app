import Foundation

/// General care information for common houseplants, loaded from `plantKnowledge.json`
/// (shared with the browser preview). Guidance only — never presented as expert advice.
struct PlantKnowledge: Codable, Equatable, Hashable, Identifiable, Sendable {
    var id: String { key }
    let key: String
    let aliases: [String]
    let commonName: String
    let scientificName: String
    let categoryRaw: String
    let sunlightRaw: String
    let humidityRaw: String
    let soil: String
    let wateringIntervalDays: Int
    let fertilizingIntervalDays: Int
    let summary: String
    let image: String?

    enum CodingKeys: String, CodingKey {
        case key, aliases, commonName, scientificName, soil, wateringIntervalDays, fertilizingIntervalDays, summary, image
        case categoryRaw = "category"
        case sunlightRaw = "sunlight"
        case humidityRaw = "humidity"
    }

    var category: PlantCategory { PlantCategory(rawValue: categoryRaw) ?? .foliage }
    var sunlight: SunlightPreference? { SunlightPreference(rawValue: sunlightRaw) }
    var humidity: HumidityPreference? { HumidityPreference(rawValue: humidityRaw) }

    /// Sample photo in the asset catalog, e.g. "monstera.jpg" → "SampleMonstera".
    var sampleAssetName: String? {
        guard let image else { return nil }
        let base = image.replacingOccurrences(of: ".jpg", with: "")
        return "Sample" + base.split(separator: "-").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
    }

    /// Prefills the Add Plant form from an identification.
    func plantDraft(status: IdentificationStatus) -> PlantDraft {
        PlantDraft(
            name: commonName,
            commonName: commonName,
            scientificName: scientificName,
            category: category,
            identificationStatus: status,
            wateringIntervalDays: wateringIntervalDays,
            fertilizingIntervalDays: fertilizingIntervalDays,
            sunlightPreference: sunlight,
            humidityPreference: humidity,
            soilPreference: soil
        )
    }
}

struct PlantKnowledgeBase: Sendable {
    let disclaimer: String
    let entries: [PlantKnowledge]

    private struct File: Decodable {
        let disclaimer: String
        let entries: [PlantKnowledge]
    }

    static let shared: PlantKnowledgeBase = {
        let bundles = [Bundle.main, Bundle(for: BundleToken.self)]
        for bundle in bundles {
            if let url = bundle.url(forResource: "plantKnowledge", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let kb = try? PlantKnowledgeBase(data: data) {
                return kb
            }
        }
        return PlantKnowledgeBase(disclaimer: "", entries: [])
    }()

    init(disclaimer: String, entries: [PlantKnowledge]) {
        self.disclaimer = disclaimer
        self.entries = entries
    }

    init(data: Data) throws {
        let file = try JSONDecoder().decode(File.self, from: data)
        self.init(disclaimer: file.disclaimer, entries: file.entries)
    }

    func entry(forKey key: String) -> PlantKnowledge? { entries.first { $0.key == key } }
}

private final class BundleToken {}
