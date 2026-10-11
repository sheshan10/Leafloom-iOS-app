import CoreData
import Observation
import PhotosUI
import SwiftUI

@MainActor
@Observable
final class JournalEntryFormViewModel {
    enum Mode: Equatable {
        case create(plantID: UUID?)
        case edit(UUID)
    }

    let mode: Mode
    var draft: JournalDraft
    var heightText: String
    var errors: [JournalField: String] = [:]
    var saveError: String?
    var newImageData: Data?
    var removeExistingImage = false
    var photoError: String?
    let existingImageFilename: String?
    private let original: JournalDraft

    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var hasChanges: Bool { draft != original || newImageData != nil || removeExistingImage || heightText != Self.format(original.heightCm) }

    init(mode: Mode, existing: JournalEntry?) {
        self.mode = mode
        let initial: JournalDraft
        switch mode {
        case let .create(plantID): initial = JournalDraft(plantID: plantID)
        case .edit: initial = existing?.draft ?? JournalDraft()
        }
        draft = initial
        original = initial
        heightText = Self.format(initial.heightCm)
        existingImageFilename = existing?.imageFilename
    }

    private static func format(_ h: Double?) -> String {
        h.map { $0.formatted(.number.precision(.fractionLength(0...1)).grouping(.never)) } ?? ""
    }

    /// Parses the height field. Empty means "not measured"; anything unparseable is a validation error.
    private func parseHeight() -> Bool {
        let trimmed = heightText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        if trimmed.isEmpty {
            draft.heightCm = nil
            return true
        }
        guard let value = Double(trimmed) else { return false }
        draft.heightCm = value
        return true
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

    func save(env: AppEnvironment) -> Bool {
        let heightOK = parseHeight()
        errors = PlantValidator.validate(draft)
        if !heightOK { errors[.height] = "Enter the height as a number, e.g. 42 or 42.5." }
        guard errors.isEmpty else { return false }
        do {
            switch mode {
            case .create:
                try env.journal.create(draft, imageData: newImageData)
            case let .edit(id):
                guard let entry = env.journal.entry(id: id) else { throw PersistenceError.notFound }
                try env.journal.update(entry, with: draft, newImageData: newImageData, removeImage: removeExistingImage)
            }
            return true
        } catch {
            saveError = error.localizedDescription
            return false
        }
    }
}

struct JournalEntryFormView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(sortDescriptors: [SortDescriptor(\Plant.name)])
    private var plants: FetchedResults<Plant>
    @State private var model: JournalEntryFormViewModel
    @State private var confirmDiscard = false
    @FocusState private var focused: JournalField?

    init(mode: JournalEntryFormViewModel.Mode, existing: JournalEntry? = nil) {
        _model = State(initialValue: JournalEntryFormViewModel(mode: mode, existing: existing))
    }

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            Form {
                Section {
                    PhotoPickerSection(
                        currentImage: previewImage,
                        hasImage: previewImage != nil,
                        onPick: { await model.loadPhoto($0) },
                        onCamera: { model.setCameraImage($0) },
                        onRemove: { model.newImageData = nil; model.removeExistingImage = true },
                        error: model.photoError
                    )
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Picker("Plant", selection: $model.draft.plantID) {
                            Text("Choose…").tag(UUID?.none)
                            ForEach(plants) { Text($0.name).tag(UUID?.some($0.id)) }
                        }
                        FieldError(message: model.errors[.plant])
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        DatePicker("Date", selection: $model.draft.entryDate, in: ...Date.now, displayedComponents: .date)
                        FieldError(message: model.errors[.entryDate])
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Height")
                            Spacer()
                            TextField("Optional", text: $model.heightText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 100)
                                .focused($focused, equals: .height)
                                .accessibilityLabel("Height in centimetres")
                            Text("cm").foregroundStyle(LeafColor.textSecondary)
                        }
                        FieldError(message: model.errors[.height])
                    }
                }

                Section("What did you notice?") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("New leaf, repotted, moved to a brighter spot…", text: $model.draft.notes, axis: .vertical)
                            .lineLimit(4...10)
                            .focused($focused, equals: .notes)
                            .accessibilityIdentifier("journalForm.notes")
                        HStack {
                            FieldError(message: model.errors[.notes])
                            Spacer()
                            Text("\(model.draft.notes.count)/\(PlantValidator.notesMax)")
                                .font(LeafFont.caption)
                                .foregroundStyle(model.draft.notes.count > PlantValidator.notesMax ? LeafColor.danger : LeafColor.textTertiary)
                        }
                    }
                }

                if let error = model.saveError {
                    Section { FieldError(message: error) }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(model.isEditing ? "Edit entry" : "New journal entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if model.hasChanges { confirmDiscard = true } else { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.isEditing ? "Save" : "Add") { save() }
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("journalForm.save")
                }
            }
            .interactiveDismissDisabled(model.hasChanges)
            .confirmationDialog("Discard your changes?", isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button("Discard changes", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) {}
            }
        }
    }

    private var previewImage: UIImage? {
        if let data = model.newImageData { return ImageStore.downsample(data: data, maxPixelSize: 900) }
        guard !model.removeExistingImage, let file = model.existingImageFilename else { return nil }
        return env.images.image(named: file)
    }

    private func save() {
        guard model.save(env: env) else {
            focused = [JournalField.notes, .height].first { model.errors[$0] != nil }
            return
        }
        env.toasts.show(model.isEditing ? "Entry updated" : "Journal entry added")
        dismiss()
    }
}
