import Foundation

/// Maps raw classifier labels ("snake_plant", "Sansevieria trifasciata", "MONSTERA-DELICIOSA") to
/// knowledge-base entries. Mirrors `lookupLabel` in the browser preview.
struct LabelMapper: Sendable {
    let knowledgeBase: PlantKnowledgeBase

    init(knowledgeBase: PlantKnowledgeBase = .shared) {
        self.knowledgeBase = knowledgeBase
    }

    static func normalise(_ label: String) -> String {
        label
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    /// "snake_plant" → "Snake Plant" for labels that have no knowledge entry.
    static func humanReadable(_ label: String) -> String {
        normalise(label).split(separator: " ").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }

    func knowledge(for label: String) -> PlantKnowledge? {
        let n = Self.normalise(label)
        guard !n.isEmpty else { return nil }
        return knowledgeBase.entries.first { e in
            Self.normalise(e.key) == n
                || Self.normalise(e.commonName) == n
                || Self.normalise(e.scientificName) == n
                || e.aliases.contains { Self.normalise($0) == n }
        }
    }

    func suggestion(label: String, confidence: Double?) -> IdentificationSuggestion {
        IdentificationSuggestion(label: label, knowledge: knowledge(for: label), confidence: confidence)
    }
}
