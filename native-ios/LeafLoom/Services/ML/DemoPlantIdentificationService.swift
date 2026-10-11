import CoreGraphics
import Foundation

/// Demonstration identifier used when no Core ML model is bundled.
///
/// It performs **no image analysis**. It picks deterministically from the knowledge base using a stable
/// hash of the image's size and a small pixel sample, so the same photo always gives the same answer.
/// Results never include a confidence and the UI always labels them "Demo identification".
struct DemoPlantIdentificationService: PlantIdentifying {
    static let modelIdentifier = "demo-mode"

    let mode: IdentificationMode = .demo
    let knowledgeBase: PlantKnowledgeBase
    var simulatedDelay: Duration = .milliseconds(900)

    init(knowledgeBase: PlantKnowledgeBase = .shared, simulatedDelay: Duration = .milliseconds(900)) {
        self.knowledgeBase = knowledgeBase
        self.simulatedDelay = simulatedDelay
    }

    func identify(_ image: CGImage) async throws -> IdentificationResult {
        guard image.width > 0, image.height > 0 else { throw IdentificationError.invalidImage }
        let pool = knowledgeBase.entries
        guard !pool.isEmpty else { throw IdentificationError.noResults }
        if simulatedDelay > .zero { try await Task.sleep(for: simulatedDelay) }

        let start = Int(Self.fingerprint(image) % UInt64(pool.count))
        let picks = [0, 3, 7].map { pool[(start + $0) % pool.count] }
        var seen = Set<String>()
        let suggestions = picks.filter { seen.insert($0.key).inserted }.map {
            IdentificationSuggestion(label: $0.key, knowledge: $0, confidence: nil)
        }
        return IdentificationResult(suggestions: suggestions, modelIdentifier: Self.modelIdentifier, isDemo: true)
    }

    /// FNV-1a over the dimensions and a few raw bytes. Stable across launches.
    static func fingerprint(_ image: CGImage) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        func mix(_ value: UInt64) {
            hash ^= value
            hash = hash &* 0x0000_0100_0000_01b3
        }
        mix(UInt64(image.width))
        mix(UInt64(image.height))
        if let data = image.dataProvider?.data, let bytes = CFDataGetBytePtr(data) {
            let length = CFDataGetLength(data)
            let step = max(1, length / 64)
            var i = 0
            while i < length {
                mix(UInt64(bytes[i]))
                i += step
            }
        }
        return hash
    }
}
