import CoreData
import SwiftUI

/// Plant details. Fetches by id so the screen updates (or shows "not found") when data changes elsewhere.
struct PlantDetailView: View {
    let plantID: UUID
    @FetchRequest private var plants: FetchedResults<Plant>
    @FetchRequest private var tasks: FetchedResults<CareTask>
    @FetchRequest private var entries: FetchedResults<JournalEntry>

    init(plantID: UUID) {
        self.plantID = plantID
        _plants = FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "id == %@", plantID as CVarArg))
        _tasks = FetchRequest(sortDescriptors: [SortDescriptor(\CareTask.dueDate)], predicate: NSPredicate(format: "plant.id == %@", plantID as CVarArg))
        _entries = FetchRequest(sortDescriptors: [SortDescriptor(\JournalEntry.entryDate, order: .reverse)], predicate: NSPredicate(format: "plant.id == %@", plantID as CVarArg))
    }

    var body: some View {
        if let plant = plants.first {
            PlantDetailContent(plant: plant, tasks: Array(tasks), entries: Array(entries))
        } else {
            ErrorStateView(title: "Plant not found", message: "This plant may have been deleted.")
                .leafScreenBackground()
        }
    }
}

private struct PlantDetailContent: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router
    @ObservedObject var plant: Plant
    let tasks: [CareTask]
    let entries: [JournalEntry]
    @State private var confirmDelete = false

    var body: some View {
        let open = tasks.filter { !$0.isCompleted }
        let history = tasks.filter(\.isCompleted).sorted { ($0.completedAt ?? $0.dueDate) > ($1.completedAt ?? $1.dueDate) }

        ScrollView {
            VStack(alignment: .leading, spacing: LeafSpacing.lg) {
                hero
                pills

                VStack(alignment: .leading, spacing: LeafSpacing.sm) {
                    SectionHeader("Next care") {
                        Button { router.present(.addTask(plantID: plant.id)) } label: { Label("Add task", systemImage: "plus") }
                            .accessibilityIdentifier("details.addTask")
                    }
                    if open.isEmpty {
                        Label("No care scheduled. Add a task to get reminders.", systemImage: "calendar.badge.plus")
                            .font(LeafFont.subheadline)
                            .foregroundStyle(LeafColor.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .leafCard()
                    } else {
                        taskList(Array(open.prefix(4)))
                    }
                }

                careProfile

                if !history.isEmpty {
                    VStack(alignment: .leading, spacing: LeafSpacing.sm) {
                        SectionHeader("Recent care", subtitle: "\(history.count) completed")
                        taskList(Array(history.prefix(5)))
                    }
                }

                journalPreview

                if plant.notes != nil || !plant.tags.isEmpty {
                    notesSection
                }

                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("Delete plant", systemImage: "trash")
                }
                .buttonStyle(.leafDestructive)
                .accessibilityIdentifier("details.delete")
            }
            .padding(.horizontal, LeafSpacing.screen)
            .padding(.bottom, LeafSpacing.xl)
        }
        .leafScreenBackground()
        .navigationTitle(plant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { router.present(.editPlant(plant.id)) } label: { Image(systemName: "pencil") }
                    .accessibilityLabel("Edit plant")
                    .accessibilityIdentifier("details.edit")
            }
        }
        .confirmationDialog("Delete \(plant.name)?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete plant", role: .destructive, action: delete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(deleteMessage)
        }
        .accessibilityIdentifier("screen.plantDetails")
    }

    // MARK: Sections

    private var hero: some View {
        PlantThumbnail(plant: plant, cornerRadius: LeafRadius.xl, maxPixelSize: 1200)
            .frame(height: 280)
            .overlay {
                LinearGradient(colors: [.clear, LeafColor.deep.opacity(0.75)], startPoint: .center, endPoint: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: LeafRadius.xl, style: .continuous))
                    .accessibilityHidden(true)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    if plant.isSample { SampleBadge() }
                    Text(plant.name)
                        .font(LeafFont.title)
                        .foregroundStyle(.white)
                        .accessibilityAddTraits(.isHeader)
                    if let scientific = plant.scientificName {
                        Text(scientific).font(LeafFont.subheadline).italic().foregroundStyle(.white.opacity(0.9))
                    }
                }
                .padding(LeafSpacing.md)
            }
            .overlay(alignment: .bottomTrailing) {
                FavoriteButton(isFavorite: plant.isFavorite, onImage: true) { env.toggleFavorite(plant) }
                    .padding(LeafSpacing.sm)
            }
            .padding(.top, LeafSpacing.xs)
    }

    private var pills: some View {
        VStack(alignment: .leading, spacing: LeafSpacing.xs) {
            FlowLayout(spacing: LeafSpacing.xs) {
                HStack(spacing: 4) {
                    CategoryIcon(category: plant.category, size: 14)
                    Text(plant.category.label)
                }
                .font(LeafFont.caption)
                .foregroundStyle(LeafColor.primary)
                .padding(.horizontal, LeafSpacing.xs)
                .padding(.vertical, LeafSpacing.xxs)
                .background(LeafColor.primarySoft, in: Capsule())

                PillBadge(
                    text: plant.identificationStatus.label,
                    systemImage: plant.identificationStatus == .identified ? "checkmark.seal" : "questionmark.circle",
                    foreground: plant.identificationStatus == .identified ? LeafColor.success : LeafColor.textSecondary,
                    background: plant.identificationStatus == .identified ? LeafColor.successSoft : LeafColor.surfaceAlt
                )
                if let location = plant.location {
                    PillBadge(text: location, systemImage: "mappin", foreground: LeafColor.textSecondary, background: LeafColor.surfaceAlt)
                }
            }
            if let common = plant.commonName, common != plant.name {
                Text("Also known as \(common)").font(LeafFont.subheadline).foregroundStyle(LeafColor.textSecondary)
            }
        }
    }

    private func taskList(_ list: [CareTask]) -> some View {
        VStack(spacing: 0) {
            ForEach(list) { task in
                CareTaskRow(task: task, showsPlant: false) { env.toggleCompletion(task) }
                    .contentShape(Rectangle())
                    .onTapGesture { router.push(.taskDetails(task.id)) }
                    .accessibilityAction(named: "Open details") { router.push(.taskDetails(task.id)) }
                if task.id != list.last?.id { Divider().padding(.leading, 88) }
            }
        }
        .leafCard(padding: LeafSpacing.xs)
    }

    private var careProfile: some View {
        VStack(alignment: .leading, spacing: LeafSpacing.sm) {
            SectionHeader("Care profile")
            LazyVGrid(columns: [GridItem(.flexible(), alignment: .topLeading), GridItem(.flexible(), alignment: .topLeading)], spacing: LeafSpacing.md) {
                profileItem("Watering", value: plant.wateringIntervalDays.map(Self.every) ?? "Not set", symbol: "drop")
                profileItem("Fertilising", value: plant.fertilizingIntervalDays.map(Self.every) ?? "Not set", symbol: "leaf.arrow.circlepath")
                profileItem("Light", value: plant.sunlightPreference?.label ?? "Not set", symbol: "sun.max")
                profileItem("Humidity", value: plant.humidityPreference?.label ?? "Not set", symbol: "humidity")
                profileItem("Soil", value: plant.soilPreference ?? "Not set", symbol: "square.stack.3d.down.right")
                profileItem("Added", value: (plant.acquisitionDate ?? plant.dateAdded).formatted(date: .abbreviated, time: .omitted), symbol: "calendar")
            }
            .leafCard()
        }
    }

    private static func every(_ days: Int) -> String { days == 1 ? "Every day" : "Every \(days) days" }

    private func profileItem(_ title: String, value: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: LeafSpacing.xs) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(LeafColor.primary)
                .frame(width: 30, height: 30)
                .background(LeafColor.primarySoft, in: RoundedRectangle(cornerRadius: LeafRadius.sm, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(LeafFont.caption).foregroundStyle(LeafColor.textSecondary)
                Text(value).font(LeafFont.subheadline.weight(.semibold)).foregroundStyle(LeafColor.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var journalPreview: some View {
        VStack(alignment: .leading, spacing: LeafSpacing.sm) {
            SectionHeader("Growth journal", subtitle: entries.isEmpty ? nil : "\(entries.count) \(entries.count == 1 ? "entry" : "entries")") {
                Button("Open") { router.push(.journal(plant.id)) }
                    .accessibilityLabel("Open journal")
                    .accessibilityIdentifier("details.journal")
            }
            Button { router.push(.journal(plant.id)) } label: {
                HStack(spacing: LeafSpacing.sm) {
                    if let latest = entries.first {
                        if let file = latest.imageFilename {
                            PlantThumbnail(imageFilename: file, category: plant.category)
                                .frame(width: 64, height: 64)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(latest.entryDate.formatted(date: .abbreviated, time: .omitted)).font(LeafFont.caption).foregroundStyle(LeafColor.textSecondary)
                            Text(latest.notes).font(LeafFont.subheadline).foregroundStyle(LeafColor.text).lineLimit(2).multilineTextAlignment(.leading)
                        }
                    } else {
                        Image(systemName: "book.pages").font(.title2).foregroundStyle(LeafColor.primary).accessibilityHidden(true)
                        Text("Start a journal to track new leaves, repotting and growth.")
                            .font(LeafFont.subheadline)
                            .foregroundStyle(LeafColor.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(LeafColor.textTertiary).accessibilityHidden(true)
                }
                .leafCard(padding: LeafSpacing.sm)
            }
            .buttonStyle(.plain)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: LeafSpacing.sm) {
            SectionHeader("Notes")
            VStack(alignment: .leading, spacing: LeafSpacing.sm) {
                if let notes = plant.notes {
                    Text(notes).font(LeafFont.body).foregroundStyle(LeafColor.text).frame(maxWidth: .infinity, alignment: .leading)
                }
                if !plant.tags.isEmpty {
                    FlowLayout(spacing: LeafSpacing.xs) {
                        ForEach(plant.tags, id: \.self) { tag in
                            PillBadge(text: "#\(tag)", foreground: LeafColor.textSecondary, background: LeafColor.surfaceAlt)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Tags: \(plant.tags.joined(separator: ", "))")
                }
            }
            .leafCard()
        }
    }

    // MARK: Delete

    private var deleteMessage: String {
        let s = env.plants.deletionSummary(for: plant)
        var parts: [String] = []
        if s.taskCount > 0 { parts.append("\(s.taskCount) care \(s.taskCount == 1 ? "task" : "tasks")") }
        if s.journalCount > 0 { parts.append("\(s.journalCount) journal \(s.journalCount == 1 ? "entry" : "entries")") }
        let extra = parts.isEmpty ? "" : " This also deletes \(parts.joined(separator: " and "))."
        return "This can’t be undone.\(extra)"
    }

    private func delete() {
        let name = plant.name
        let target = plant
        router.pop()
        do {
            try env.plants.delete(target)
            env.toasts.show("\(name) deleted", kind: .info)
        } catch {
            env.toasts.showError(error)
        }
    }
}
