import CoreData
import SwiftUI

struct CareTaskFormView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(sortDescriptors: [SortDescriptor(\Plant.name)])
    private var plants: FetchedResults<Plant>
    @State private var model: CareTaskFormViewModel
    @State private var confirmDiscard = false
    @FocusState private var focused: TaskField?

    init(mode: CareTaskFormViewModel.Mode, existing: CareTask? = nil, defaultHour: Int = 9) {
        _model = State(initialValue: CareTaskFormViewModel(mode: mode, existing: existing, defaultHour: defaultHour))
    }

    private var selectedPlantName: String? {
        guard let id = model.draft.plantID else { return nil }
        return plants.first { $0.id == id }?.name
    }

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            Form {
                Section {
                    Picker("Plant", selection: $model.draft.plantID) {
                        Text("No specific plant").tag(UUID?.none)
                        ForEach(plants) { Text($0.name).tag(UUID?.some($0.id)) }
                    }
                    .accessibilityIdentifier("taskForm.plant")
                    Picker("Type", selection: $model.draft.category) {
                        ForEach(CareCategory.allCases) { c in
                            Label(c.label, systemImage: c.symbol).tag(c)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Title (required)", text: $model.draft.title)
                            .font(LeafFont.headline)
                            .focused($focused, equals: .title)
                            .accessibilityIdentifier("taskForm.title")
                        FieldError(message: model.errors[.title])
                    }
                }

                Section {
                    DatePicker("Due", selection: $model.draft.dueDate)
                    Toggle("Repeat", isOn: $model.repeats.animation())
                        .accessibilityIdentifier("taskForm.repeat")
                    if model.repeats {
                        VStack(alignment: .leading, spacing: 4) {
                            DayIntervalField(title: "Every", value: $model.draft.recurrenceIntervalDays)
                                .focused($focused, equals: .recurrence)
                            FieldError(message: model.errors[.recurrence])
                        }
                    }
                } header: {
                    Text("Schedule")
                } footer: {
                    Text(model.repeats
                         ? "When you complete it, the next one is scheduled from the day you actually did it."
                         : "A one-off task. Reminders follow your notification settings.")
                }

                Section("Details") {
                    TextField("Description", text: $model.draft.descriptionText, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Notes", text: $model.draft.notes, axis: .vertical)
                        .lineLimit(2...6)
                }

                if let error = model.saveError {
                    Section { FieldError(message: error) }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(model.isEditing ? "Edit task" : "New care task")
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
                        .accessibilityIdentifier("taskForm.save")
                }
            }
            .interactiveDismissDisabled(model.hasChanges)
            .confirmationDialog("Discard your changes?", isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button("Discard changes", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) {}
            }
            .onAppear { if !model.isEditing { model.refreshSuggestedTitle(plantName: selectedPlantName) } }
            .onChange(of: model.draft.category) { model.refreshSuggestedTitle(plantName: selectedPlantName) }
            .onChange(of: model.draft.plantID) { model.refreshSuggestedTitle(plantName: selectedPlantName) }
        }
    }

    private func save() {
        guard model.save(env: env) else {
            focused = [TaskField.title, .recurrence].first { model.errors[$0] != nil }
            return
        }
        env.toasts.show(model.isEditing ? "Task updated" : "Task added")
        dismiss()
    }
}
