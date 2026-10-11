import CoreML
import OSLog
import Vision

/// Runs an image-classification Core ML model through Vision.
///
/// The model is loaded by name (`LeafLoomPlantClassifier`) so the app compiles and runs without it.
/// Add `LeafLoomPlantClassifier.mlmodel` to `native-ios/LeafLoom/Resources/` and Xcode compiles it
/// into `LeafLoomPlantClassifier.mlmodelc` automatically. See docs/CORE_ML_GUIDE.md.
final class CoreMLPlantIdentificationService: PlantIdentifying, @unchecked Sendable {
    static let defaultModelName = "LeafLoomPlantClassifier"

    let mode: IdentificationMode
    private let vnModel: VNCoreMLModel
    private let mapper: LabelMapper
    private let maxResults: Int
    private let logger = Logger(subsystem: "com.leafloom.LeafLoom", category: "CoreML")

    /// Returns nil when no compiled model is bundled.
    static func bundledModelURL(named name: String = defaultModelName, in bundle: Bundle = .main) -> URL? {
        bundle.url(forResource: name, withExtension: "mlmodelc")
    }

    init(modelURL: URL, mapper: LabelMapper = LabelMapper(), maxResults: Int = 5) throws {
        do {
            let configuration = MLModelConfiguration()
            configuration.computeUnits = .all
            let mlModel = try MLModel(contentsOf: modelURL, configuration: configuration)
            vnModel = try VNCoreMLModel(for: mlModel)
        } catch {
            throw IdentificationError.modelLoadFailed
        }
        self.mapper = mapper
        self.maxResults = maxResults
        mode = .model(name: modelURL.deletingPathExtension().lastPathComponent)
    }

    func identify(_ image: CGImage) async throws -> IdentificationResult {
        let model = vnModel
        let maxResults = maxResults
        // Vision work runs off the main actor so the UI stays responsive.
        let observations: [VNClassificationObservation] = try await Task.detached(priority: .userInitiated) {
            let request = VNCoreMLRequest(model: model)
            request.imageCropAndScaleOption = .centerCrop
            let handler = VNImageRequestHandler(cgImage: image, orientation: .up)
            do {
                try handler.perform([request])
            } catch {
                throw IdentificationError.inferenceFailed
            }
            guard let results = request.results as? [VNClassificationObservation] else {
                throw IdentificationError.inferenceFailed
            }
            return Array(results.sorted { $0.confidence > $1.confidence }.prefix(maxResults))
        }.value

        let meaningful = observations.filter { $0.confidence > 0.01 }
        guard !meaningful.isEmpty else { throw IdentificationError.noResults }
        logger.debug("Top label: \(meaningful[0].identifier, privacy: .public)")

        let name: String
        if case let .model(n) = mode { name = n } else { name = Self.defaultModelName }
        return IdentificationResult(
            suggestions: meaningful.map { mapper.suggestion(label: $0.identifier, confidence: Double($0.confidence)) },
            modelIdentifier: name,
            isDemo: false
        )
    }
}
