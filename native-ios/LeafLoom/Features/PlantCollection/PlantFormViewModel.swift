import Observation
import PhotosUI
import SwiftUI

@MainActor
@Observable
final class PlantFormViewModel {
    enum Mode: Equatable {
        case create(prefill: PlantDraft?, identificationID: UUID?)
        case edit(UUID)
    }

    let mode: Mode
    var draft: PlantDraft
    var tagsText: String
    var createCareSchedule = true
    var errors: [PlantField: String] = [:]
    var isSaving = false
    var saveError: String?
    /// New photo picked in this session (JPEG/HEIC data), not yet saved.
    var newImageData: Data?
    var removeExistingImage = false
    var photoError: String?
    private let original: PlantDraft

    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }
    var hasChanges: Bool { draft != original || newImageData != nil || removeExistingImage || tagsText != original.tags.joined(separator: ", ") }

    init(mode: Mode, existing: Plant?) {
        self.mode = mode
        let initial: PlantDraft
        switch mode {
        case let .create(prefill, _): initial = prefill ?? PlantDraft()
        case .edit: initial = existing?.draft ?? PlantDraft()
        }
        draft = initial
        original = initial
        tagsText = initial.tags.joined(separator: ", ")
    }

    func validate() -> Bool {
        draft.tags = PlantValidator.parseTags(tagsText)
        errors = PlantValidator.validate(draft)
        return errors.isEmpty
    }

    func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        photoError = nil
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { throw ImageStoreError.invalidImage }
            guard data.count <= ImageStore.maxInputBytes else { throw ImageStoreError.tooLarge }
            guard UIImage(data: data) != nil else { throw ImageStoreError.invalidImage }
            newImageData = data
            removeExistingImage = false
        } catch {
            photoError = (error as? LocalizedError)?.errorDescription ?? "That photo couldn’t be loaded."
        }
    }

    func setCameraImage(_ image: UIImage) {
        newImageData = image.jpegData(compressionQuality: 0.9)
        removeExistingImage = false
    }

    /// Returns the saved plant's id, or nil when validation or saving failed.
    func save(env: AppEnvironment) -> UUID? {
        guard validate() else { return nil }
        isSaving = true
        defer { isSaving = false }
        do {
            switch mode {
            case let .create(_, identificationID):
                let record = identificationID.flatMap { id in (try? env.identifications.history())?.first { $0.id == id } }
                let plant = try env.plants.create(draft, imageData: newImageData, createCareSchedule: createCareSchedule && (draft.wateringIntervalDays != nil || draft.fertilizingIntervalDays != nil), identification: record)
                return plant.id
            case let .edit(id):
                guard let plant = env.plants.plant(id: id) else { throw PersistenceError.notFound }
                try env.plants.update(plant, with: draft, newImageData: newImageData, removeImage: removeExistingImage)
                return id
            }
        } catch {
            saveError = error.localizedDescription
            return nil
        }
    }
}
