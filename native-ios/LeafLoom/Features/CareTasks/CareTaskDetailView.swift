import CoreData
import SwiftUI

struct CareTaskDetailView: View {
    let taskID: UUID
    @FetchRequest private var results: FetchedResults<CareTask>

    init(taskID: UUID) {
        self.taskID = taskID
        _results = FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "id == %@", taskID as CVarArg))
    }

    var body: some View {
        if let task = results.first {
            CareTaskDetailContent(task: task)
        } else {
            ErrorStateView(title: "Task not found", message: "This task may have been deleted.")
                .leafScreenBackground()
        }
    }
}

private struct CareTaskDetailContent: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router
    @ObservedObject var task: CareTask
    @State private var confirmDelete = false

    var body: some View {
        let status = task.status
        ScrollView {
            VStack(alignment: .leading, spacing: LeafSpacing.lg) {
                VStack(alignment: .leading, spacing: LeafSpacing.sm) {
                    HStack(alignment: .top) {
                        CareCategoryIcon(category: task.category, size: 52)
                        Spacer()
                        StatusBadge(status: status)
                    }
                    Text(task.title)
                        .font(LeafFont.title)
                        .foregroundStyle(LeafColor.text)
                        .accessibilityAddTraits(.isHeader)
                    Text(task.category.label).eyebrowStyle()
                }
                .padding(.top, LeafSpacing.sm)

                VStack(alignment: .leading, spacing: LeafSpacing.sm) {
                    infoRow("calendar", "Due", task.dueDate.formatted(date: .complete, time: .shortened))
                    if let done = task.completedAt {
                        infoRow("checkmark.circle", "Completed", done.formatted(date: .abbreviated, time: .shortened))
                    }
                    infoRow("repeat", "Repeats", task.recurrenceDescription ?? "Does not repeat")
                    if let plant = task.plant {
                        Button { router.push(.plantDetails(plant.id)) } label: {
                            HStack {
                                infoRow("leaf", "Plant", plant.name)
                                Spacer()
                                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(LeafColor.textTertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens the plant")
                    }
                }
                .leafCard()

                if let description = task.descriptionText {
                    textCard("Description", description)
                }
                if let notes = task.notes {
                    textCard("Notes", notes)
                }

                VStack(spacing: LeafSpacing.xs) {
                    Button { env.toggleCompletion(task) } label: {
                        Label(task.isCompleted ? "Mark as not done" : "Mark as done", systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark.circle.fill")
                    }
                    .buttonStyle(.leafPrimary)
                    .accessibilityIdentifier("taskDetail.toggle")
                    Button { router.present(.editTask(task.id)) } label: { Label("Edit task", systemImage: "pencil") }
                        .buttonStyle(.leafSecondary)
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete task", systemImage: "trash") }
                        .buttonStyle(.leafDestructive)
                }

                if task.recurrenceIntervalDays != nil {
                    SeriesHistory(seriesID: task.seriesID, currentID: task.id)
                }
            }
            .padding(.horizontal, LeafSpacing.screen)
            .padding(.bottom, LeafSpacing.xl)
        }
        .leafScreenBackground()
        .navigationTitle("Care task")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete “\(task.title)”?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete task", role: .destructive, action: delete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can’t be undone. Other occurrences in the series are kept.")
        }
        .accessibilityIdentifier("screen.taskDetails")
    }

    private func infoRow(_ symbol: String, _ title: String, _ value: String) -> some View {
        HStack(spacing: LeafSpacing.sm) {
            Image(systemName: symbol).foregroundStyle(LeafColor.primary).frame(width: 24).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(LeafFont.caption).foregroundStyle(LeafColor.textSecondary)
                Text(value).font(LeafFont.subheadline.weight(.medium)).foregroundStyle(LeafColor.text)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func textCard(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: LeafSpacing.xs) {
            Text(title).eyebrowStyle()
            Text(text).font(LeafFont.body).foregroundStyle(LeafColor.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .leafCard()
    }

    private func delete() {
        let target = task
        router.pop()
        do {
            try env.tasks.delete(target)
            env.toasts.show("Task deleted", kind: .info)
        } catch {
            env.toasts.showError(error)
        }
    }
}

/// Every occurrence of a recurring task, newest first.
private struct SeriesHistory: View {
    let currentID: UUID
    @FetchRequest private var occurrences: FetchedResults<CareTask>

    init(seriesID: UUID, currentID: UUID) {
        self.currentID = currentID
        _occurrences = FetchRequest(sortDescriptors: [SortDescriptor(\CareTask.dueDate, order: .reverse)], predicate: NSPredicate(format: "seriesID == %@", seriesID as CVarArg))
    }

    var body: some View {
        let done = occurrences.filter(\.isCompleted)
        VStack(alignment: .leading, spacing: LeafSpacing.sm) {
            SectionHeader("History", subtitle: done.isEmpty ? "Not completed yet" : "Completed \(done.count) \(done.count == 1 ? "time" : "times")")
            VStack(spacing: 0) {
                ForEach(Array(occurrences.prefix(12))) { o in
                    HStack {
                        Image(systemName: o.isCompleted ? "checkmark.circle.fill" : "circle.dashed")
                            .foregroundStyle(o.isCompleted ? LeafColor.success : LeafColor.textTertiary)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(o.isCompleted ? "Done \((o.completedAt ?? o.dueDate).formatted(date: .abbreviated, time: .omitted))" : "Due \(o.dueDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(LeafFont.subheadline)
                                .foregroundStyle(LeafColor.text)
                            if o.id == currentID {
                                Text("This occurrence").font(LeafFont.caption).foregroundStyle(LeafColor.primary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, LeafSpacing.xs)
                    .accessibilityElement(children: .combine)
                    if o.id != occurrences.prefix(12).last?.id { Divider() }
                }
            }
            .leafCard(padding: LeafSpacing.sm)
        }
    }
}
