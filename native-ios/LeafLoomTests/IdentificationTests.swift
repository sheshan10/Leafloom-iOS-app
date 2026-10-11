import XCTest
@testable import LeafLoom

final class LabelMapperTests: XCTestCase {
    private let mapper = LabelMapper(knowledgeBase: .shared)

    func testKnowledgeBaseIsBundled() {
        XCTAssertFalse(PlantKnowledgeBase.shared.entries.isEmpty, "plantKnowledge.json must be in the app bundle")
        XCTAssertNotNil(PlantKnowledgeBase.shared.entry(forKey: "monstera_deliciosa"))
    }

    func testNormalise() {
        XCTAssertEqual(LabelMapper.normalise("  MONSTERA-deliciosa__x "), "monstera deliciosa x")
        XCTAssertEqual(LabelMapper.humanReadable("snake_plant"), "Snake Plant")
    }

    func testMatchesKeyCommonScientificAndAlias() {
        XCTAssertEqual(mapper.knowledge(for: "monstera_deliciosa")?.key, "monstera_deliciosa")
        XCTAssertEqual(mapper.knowledge(for: "Swiss Cheese Plant")?.key, "monstera_deliciosa")
        XCTAssertEqual(mapper.knowledge(for: "MONSTERA-DELICIOSA")?.key, "monstera_deliciosa")
        XCTAssertEqual(mapper.knowledge(for: "split-leaf philodendron")?.key, "monstera_deliciosa")
    }

    func testUnknownLabelKeepsReadableName() {
        let s = mapper.suggestion(label: "mystery_vine", confidence: 0.31)
        XCTAssertNil(s.knowledge)
        XCTAssertEqual(s.displayName, "Mystery Vine")
        XCTAssertEqual(s.confidence, 0.31)
        XCTAssertNil(mapper.knowledge(for: "   "))
    }

    func testKnowledgeProducesReviewablePlantDraft() throws {
        let k = try XCTUnwrap(PlantKnowledgeBase.shared.entry(forKey: "ocimum_basilicum"))
        let draft = k.plantDraft(status: .suggested)
        XCTAssertEqual(draft.scientificName, "Ocimum basilicum")
        XCTAssertEqual(draft.identificationStatus, .suggested)
        XCTAssertNotNil(draft.category)
        XCTAssertTrue(PlantValidator.validate(draft).isEmpty, "Prefill should be immediately saveable")
        XCTAssertEqual(k.sampleAssetName, "SampleBasil")
    }
}

final class DemoIdentificationServiceTests: XCTestCase {
    private let service = DemoPlantIdentificationService(knowledgeBase: .shared, simulatedDelay: .zero)

    func testDemoModeNeverReportsConfidence() async throws {
        let result = try await service.identify(Fixtures.cgImage())
        XCTAssertTrue(result.isDemo)
        XCTAssertEqual(service.mode, .demo)
        XCTAssertEqual(result.modelIdentifier, DemoPlantIdentificationService.modelIdentifier)
        XCTAssertFalse(result.suggestions.isEmpty)
        XCTAssertTrue(result.suggestions.allSatisfy { $0.confidence == nil })
        XCTAssertEqual(Set(result.suggestions.map(\.label)).count, result.suggestions.count, "No duplicate suggestions")
    }

    func testSameImageGivesSameResult() async throws {
        let image = Fixtures.cgImage(fill: 42)
        let a = try await service.identify(image)
        let b = try await service.identify(image)
        XCTAssertEqual(a.suggestions.map(\.label), b.suggestions.map(\.label))
    }

    func testEmptyKnowledgeBaseThrowsNoResults() async {
        let empty = DemoPlantIdentificationService(knowledgeBase: PlantKnowledgeBase(disclaimer: "", entries: []), simulatedDelay: .zero)
        do {
            _ = try await empty.identify(Fixtures.cgImage())
            XCTFail("Expected noResults")
        } catch {
            XCTAssertEqual(error as? IdentificationError, .noResults)
        }
    }

    @MainActor
    func testSamplePhotoIsListedFirstInDemoMode() throws {
        let kb = PlantKnowledgeBase.shared
        let other = try XCTUnwrap(kb.entries.first { $0.key != "aloe_vera" })
        let original = IdentificationResult(
            suggestions: [IdentificationSuggestion(label: other.key, knowledge: other, confidence: nil)],
            modelIdentifier: DemoPlantIdentificationService.modelIdentifier,
            isDemo: true
        )
        let reordered = IdentificationViewModel.preferringSample(original, key: "aloe_vera", knowledgeBase: kb)
        XCTAssertEqual(reordered.top?.label, "aloe_vera")
        XCTAssertNil(reordered.top?.confidence)
        XCTAssertTrue(reordered.isDemo)
        XCTAssertEqual(reordered.suggestions.count, 2)
    }

    func testErrorMessagesAreUserFriendly() {
        let cases: [IdentificationError] = [.modelUnavailable, .modelLoadFailed, .invalidImage, .noResults, .inferenceFailed]
        for c in cases {
            let message = c.errorDescription ?? ""
            XCTAssertFalse(message.isEmpty)
            XCTAssertFalse(message.localizedCaseInsensitiveContains("error code"))
        }
    }

    @MainActor
    func testIdentifierModeMatchesBundledModel() {
        let mode = AppEnvironment.makeIdentifier(knowledgeBase: .shared, instant: true).mode
        if CoreMLPlantIdentificationService.bundledModelURL() == nil {
            XCTAssertEqual(mode, .demo, "Without a bundled model the app must fall back to labelled demo mode")
        } else {
            XCTAssertEqual(mode, .model(name: CoreMLPlantIdentificationService.defaultModelName))
        }
    }
}
