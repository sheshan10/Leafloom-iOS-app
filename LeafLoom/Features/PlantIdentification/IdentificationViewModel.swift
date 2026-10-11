import Observation
import PhotosUI
import SwiftUI

@MainActor
@Observable
final class IdentificationViewModel {
    enum Phase: Equatable {
        case idle
        case ready
        case analysing
        case result(IdentificationResult)
        case failed(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var imageData: Data?
    private(set) var previewImage: UIImage?
    /// Knowledge key of the bundled sample photo the user picked, if any.
    private(set) var sampleKey: String?
    /// The suggestion the user wants to save (defaults to the top one; alternatives can be chosen).
    var selectedLabel: String?
    private(set) var recordID: UUID?

    var result: IdentificationResult? {
        if case let .result(r) = phase { return r }
        return nil
    }

    var selectedSuggestion: IdentificationSuggestion? {
        guard let result else { return nil }
        return result.suggestions.first { $0.label == selectedLabel } ?? result.top
    }

    // MARK: Input

    func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { throw IdentificationError.invalidImage }
            guard data.count <= ImageStore.maxInputBytes else { throw ImageStoreError.tooLarge }
            setImage(data: data, sampleKey: nil)
        } catch {
            phase = .failed((error as? LocalizedError)?.errorDescription ?? IdentificationError.invalidImage.localizedDescription)
        }
    }

    func setCameraImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            phase = .failed(IdentificationError.invalidImage.localizedDescription)
            return
        }
        setImage(data: data, sampleKey: nil)
    }

    func selectSample(_ entry: PlantKnowledge) {
        guard let asset = entry.sampleAssetName, let image = UIImage(named: asset), let data = image.jpegData(compressionQuality: 0.9) else { return }
        setImage(data: data, sampleKey: entry.key)
    }

    private func setImage(data: Data, sampleKey: String?) {
        guard let preview = ImageStore.downsample(data: data, maxPixelSize: 1200) else {
            phase = .failed(IdentificationError.invalidImage.localizedDescription)
            return
        }
        imageData = data
        previewImage = preview
        self.sampleKey = sampleKey
        recordID = nil
        selectedLabel = nil
        phase = .ready
    }

    func clear() {
        imageData = nil
        previewImage = nil
        sampleKey = nil
        recordID = nil
        selectedLabel = nil
        phase = .idle
    }

    // MARK: Identify

    func identify(env: AppEnvironment) async {
        guard let imageData else { return }
        phase = .analysing
        do {
            // The classifier works on a downsampled image; the saved photo keeps full quality (capped by ImageStore).
            guard let cgImage = ImageStore.downsample(data: imageData, maxPixelSize: 1024)?.cgImage else {
                throw IdentificationError.invalidImage
            }
            var result = try await env.identifier.identify(cgImage)
            if result.isDemo, let sampleKey {
                result = Self.preferringSample(result, key: sampleKey, knowledgeBase: env.knowledgeBase)
            }
            guard !result.suggestions.isEmpty else { throw IdentificationError.noResults }
            let record = try env.identifications.save(result, imageData: imageData)
            recordID = record.id
            selectedLabel = result.top?.label
            phase = .result(result)
        } catch is CancellationError {
            phase = .ready
        } catch {
            phase = .failed((error as? LocalizedError)?.errorDescription ?? IdentificationError.inferenceFailed.localizedDescription)
        }
    }

    /// In demo mode a bundled sample photo is known, so its own entry is listed first (mirrors the browser preview).
    /// This is still labelled as a demo result and carries no confidence.
    static func preferringSample(_ result: IdentificationResult, key: String, knowledgeBase: PlantKnowledgeBase) -> IdentificationResult {
        guard let entry = knowledgeBase.entry(forKey: key) else { return result }
        var suggestions = result.suggestions.filter { $0.label != key }
        suggestions.insert(IdentificationSuggestion(label: key, knowledge: entry, confidence: nil), at: 0)
        var copy = result
        copy.suggestions = Array(suggestions.prefix(3))
        return copy
    }

    // MARK: Save

    /// Prefill for Add Plant. AI output is only ever a suggestion: the user reviews every field before saving.
    func plantPrefill() -> PlantDraft? {
        guard let suggestion = selectedSuggestion, let result else { return nil }
        let status: IdentificationStatus = result.isDemo ? .unknown : .suggested
        if let knowledge = suggestion.knowledge {
            return knowledge.plantDraft(status: status)
        }
        return PlantDraft(name: suggestion.displayName, commonName: suggestion.displayName, identificationStatus: status)
    }
}
