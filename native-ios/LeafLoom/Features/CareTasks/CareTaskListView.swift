import CoreData
import SwiftUI

/// Care tab: filtered, day-grouped task list with swipe actions.
struct CareTaskListView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router
    @FetchRequest(sortDescriptors: [SortDescriptor(\CareTask.dueDate)])
    private var tasks: FetchedResults<CareTask>
    @State private var filter: TaskFilter = .upcoming
    @State private var pendingDelete: CareTask?

    var body: some View {
        taskList
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .leafScreenBackground()
            .navigationTitle("Care")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { router.present(.addTask(plantID: nil)) } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add care task")
                        .accessibilityIdentifier("care.add")
                }
            }
            .confirmationDialog(
                "Delete this task?",
                isPresented: deleteDialogPresented,
                titleVisibility: .visible,
                presenting: pendingDelete
            ) { task in
                Button("Delete task", role: .destructive) { delete(task) }
                Button("Cancel", role: .cancel) {}
            } message: { task in
                Text(task.recurrenceIntervalDays != nil
                     ? "“\(task.title)” will be removed. Earlier completed occurrences stay in the plant’s history."
                     : "“\(task.title)” will be removed.")
            }
            .leafAnimation(value: filter)
            .accessibilityIdentifier("screen.care")
    }

    private var deleteDialogPresented: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }

    private var taskList: some View {
        let now = Date.now
        let list = filter.apply(Array(tasks), now: now)
        let overdueCount = TaskFilter.overdue.apply(Array(tasks), now: now).count

        return List {
            Section {
                Picker("Show", selection: $filter) {
                    ForEach(TaskFilter.allCases) { f in
                        Text(f == .overdue && overdueCount > 0 ? "\(f.label) (\(overdueCount))" : f.label).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("care.filter")
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            if list.isEmpty {
                Section {
                    emptyState
                        .listRowBackground(Color.clear)
                }
            } else {
                ForEach(groups(list, now: now), id: \.title) { group in
                    Section {
                        ForEach(group.tasks) { task in
                            row(task)
                        }
                    } header: {
                        Text(group.title)
                            .font(LeafFont.subheadline.weight(.semibold))
                            .foregroundStyle(group.isOverdue ? LeafColor.danger : LeafColor.textSecondary)
                            .textCase(nil)
                    }
                }
            }
        }
    }

    private func delete(_ task: CareTask) {
        do {
            try env.tasks.delete(task)
            env.toasts.show("Task deleted", kind: .info)
        } catch {
            env.toasts.showError(error)
        }
    }

    private func row(_ task: CareTask) -> some View {
        CareTaskRow(task: task) { env.toggleCompletion(task) }
            .contentShape(Rectangle())
            .onTapGesture { router.push(.taskDetails(task.id)) }
            .accessibilityAction(named: "Open details") { router.push(.taskDetails(task.id)) }
            .swipeActions(edge: .leading) {
                Button { env.toggleCompletion(task) } label: {
                    Label(task.isCompleted ? "Not done" : "Done", systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                }
                .tint(task.isCompleted ? LeafColor.textSecondary : LeafColor.success)
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) { pendingDelete = task } label: { Label("Delete", systemImage: "trash") }
                Button { router.present(.editTask(task.id)) } label: { Label("Edit", systemImage: "pencil") }
                    .tint(LeafColor.info)
            }
    }

    @ViewBuilder
    private var emptyState: some View {
        switch filter {
        case .overdue:
            EmptyStateView(illustration: "EmptyTasks", title: "Nothing overdue", message: "Every plant is up to date. Nicely done.")
        case .completed:
            EmptyStateView(illustration: "EmptyTasks", title: "No completed care yet", message: "Tasks you tick off appear here, so you can see your care history.")
        default:
            EmptyStateView(
                illustration: "EmptyTasks",
                title: "No care scheduled",
                message: "Add watering, fertilising or other tasks and LeafLoom will remind you.",
                actionTitle: "Add a task"
            ) { router.present(.addTask(plantID: nil)) }
        }
    }

    // MARK: Grouping

    private struct DayGroup {
        var title: String
        var isOverdue: Bool
        var tasks: [CareTask]
    }

    private func groups(_ list: [CareTask], now: Date) -> [DayGroup] {
        let calendar = CareCalendar()
        var out: [DayGroup] = []
        for task in list {
            let status = CareStatusEvaluator.status(of: task, now: now)
            let title: String
            if status == .overdue {
                title = "Overdue"
            } else if task.isCompleted {
                let when = RelativeDayFormatter.string(for: task.completedAt ?? task.dueDate, now: now)
                title = "Completed " + (["Today", "Yesterday"].contains(when) ? when.lowercased() : when)
            } else {
                title = RelativeDayFormatter.string(for: calendar.startOfDay(task.dueDate), now: now)
            }
            if let i = out.firstIndex(where: { $0.title == title }) {
                out[i].tasks.append(task)
            } else {
                out.append(DayGroup(title: title, isOverdue: status == .overdue, tasks: [task]))
            }
        }
        return out
    }
}
