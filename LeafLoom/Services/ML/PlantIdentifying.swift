import CoreGraphics
import Foundation

enum IdentificationMode: Equatable, Sendable {
    /// A Core ML model is bundled and loaded.
    case model(name: String)
    /// No model is bundled; results are deterministic demonstrations, clearly labelled in the UI.
    case demo
}

struct IdentificationSuggestion: Identifiable, Equatable, Sendable {
    var id: String { label }
    /// Raw classifier label (e.g. "snake_plant").
    var label: String
    /// Knowledge-base entry the label maps to, if any.
    var knowledge: PlantKnowledge?
    /// 0...1, only when supplied by a real model. Never set for demo results.
    var confidence: Double?

    var displayName: String { knowledge?.commonName ?? LabelMapper.humanReadable(label) }
}

struct IdentificationResult: Equatable, Sendable {
    var suggestions: [IdentificationSuggestion]
    var modelIdentifier: String
    var isDemo: Bool
    var date: Date = .now

    var top: IdentificationSuggestion? { suggestions.first }
    var alternatives: ArraySlice<IdentificationSuggestion> { suggestions.dropFirst().prefix(4) }
}

enum IdentificationError: LocalizedError, Equatable {
    case modelUnavailable
    case modelLoadFailed
    case invalidImage
    case noResults
    case inferenceFailed

    var errorDescription: String? {
        switch self {
        case .modelUnavailable: "No identification model is installed. LeafLoom is running in demo mode."
        case .modelLoadFailed: "The identification model couldn’t be loaded. Try restarting the app."
        case .invalidImage: "That photo couldn’t be read. Try a different image."
        case .noResults: "LeafLoom couldn’t recognise a plant in this photo. Try a closer, well-lit shot of a single plant."
        case .inferenceFailed: "Identification failed. Please try again."
        }
    }
}

/// Model-agnostic identification. Swap implementations without touching the UI.
protocol PlantIdentifying: Sendable {
    var mode: IdentificationMode { get }
    func identify(_ image: CGImage) async throws -> IdentificationResult
}
