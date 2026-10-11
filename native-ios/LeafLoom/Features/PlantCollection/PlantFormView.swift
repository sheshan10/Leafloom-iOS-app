import CoreData
import SwiftUI

struct PlantFormView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var model: PlantFormViewModel
    @State private var confirmDiscard = false
    @FocusState private var focused: PlantField?

    init(mode: PlantFormViewModel.Mode, existing: Plant? = nil) {
        _model = State(initialValue: PlantFormViewModel(mode: mode, existing: existing))
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

                Section("Basics") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Plant name (required)", text: $model.draft.name)
                            .font(LeafFont.headline)
                            .focused($focused, equals: .name)
                            .submitLabel(.next)
                            .textInputAutocapitalization(.words)
                            .accessibilityIdentifier("plantForm.name")
                        FieldError(message: model.errors[.name])
                    }
                    TextField("Common name", text: $model.draft.commonName)
                    TextField("Scientific name", text: $model.draft.scientificName)
                        .textInputAutocapitalization(.never)
                        .italic()
                    VStack(alignment: .leading, spacing: 4) {
                        Picker("Category", selection: $model.draft.category) {
                            Text("Choose…").tag(PlantCategory?.none)
                            ForEach(PlantCategory.allCases) { Text($0.label).tag(PlantCategory?.some($0)) }
                        }
                        .focused($focused, equals: .category)
                        .accessibilityIdentifier("plantForm.category")
                        FieldError(message: model.errors[.category])
                    }
                    Picker("Identification", selection: $model.draft.identificationStatus) {
                        ForEach(IdentificationStatus.allCases) { Text($0.label).tag($0) }
                    }
                }

                Section("Where & when") {
                    TextField("Location (e.g. Living room)", text: $model.draft.location)
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Acquisition date", isOn: Binding(
                            get: { model.draft.acquisitionDate != nil },
                            set: { model.draft.acquisitionDate = $0 ? (model.draft.acquisitionDate ?? .now) : nil }
                        ))
                        if let date = model.draft.acquisitionDate {
                            DatePicker("Acquired", selection: Binding(get: { date }, set: { model.draft.acquisitionDate = $0 }), in: ...Date.now, displayedComponents: .date)
                        }
                        FieldError(message: model.errors[.acquisitionDate])
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        DayIntervalField(title: "Water every", value: $model.draft.wateringIntervalDays)
                            .focused($focused, equals: .wateringInterval)
                        FieldError(message: model.errors[.wateringInterval])
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        DayIntervalField(title: "Fertilise every", value: $model.draft.fertilizingIntervalDays, placeholder: "e.g. 30")
                            .focused($focused, equals: .fertilizingInterval)
                        FieldError(message: model.errors[.fertilizingInterval])
                    }
                    Picker("Sunlight", selection: $model.draft.sunlightPreference) {
                        Text("Not set").tag(SunlightPreference?.none)
                        ForEach(SunlightPreference.allCases) { Text($0.label).tag(SunlightPreference?.some($0)) }
                    }
                    Picker("Humidity", selection: $model.draft.humidityPreference) {
                        Text("Not set").tag(HumidityPreference?.none)
                        ForEach(HumidityPreference.allCases) { Text($0.label).tag(HumidityPreference?.some($0)) }
                    }
                    TextField("Soil (e.g. Chunky aroid mix)", text: $model.draft.soilPreference)
                    if !model.isEditing {
                        Toggle("Create care schedule", isOn: $model.createCareSchedule)
                    }
                } header: {
                    Text("Care profile")
                } footer: {
                    Text(model.isEditing
                         ? "Intervals are between 1 and 365 days."
                         : "Intervals are between 1 and 365 days. With a schedule, LeafLoom creates recurring watering and fertilising tasks.")
                }

                Section("Notes & tags") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Notes", text: $model.draft.notes, axis: .vertical)
                            .lineLimit(3...8)
                            .focused($focused, equals: .notes)
                        HStack {
                            FieldError(message: model.errors[.notes])
                            Spacer()
                            Text("\(model.draft.notes.count)/\(PlantValidator.notesMax)")
                                .font(LeafFont.caption)
                                .foregroundStyle(model.draft.notes.count > PlantValidator.notesMax ? LeafColor.danger : LeafColor.textTertiary)
                        }
                    }
                    TextField("Tags, separated by commas", text: $model.tagsText)
                        .textInputAutocapitalization(.never)
                    Toggle("Favourite", isOn: $model.draft.isFavorite)
                }

                if let error = model.saveError {
                    Section { FieldError(message: error) }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(model.isEditing ? "Edit plant" : "Add plant")
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
                        .disabled(model.isSaving)
                        .accessibilityIdentifier("plantForm.save")
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
        guard !model.removeExistingImage, case let .edit(id) = model.mode, let plant = env.plants.plant(id: id) else { return nil }
        if let file = plant.imageFilename { return env.images.image(named: file) }
        if let asset = plant.sampleAssetName { return UIImage(named: asset) }
        return nil
    }

    private func save() {
        guard let id = model.save(env: env) else {
            focused = [PlantField.name, .category, .acquisitionDate, .wateringInterval, .fertilizingInterval, .notes].first { model.errors[$0] != nil }
            return
        }
        let wasEditing = model.isEditing
        dismiss()
        if wasEditing {
            env.toasts.show("Changes saved")
        } else {
            env.toasts.show("\(model.draft.name) added to your collection")
            router.showNewPlant(id)
        }
    }
}
