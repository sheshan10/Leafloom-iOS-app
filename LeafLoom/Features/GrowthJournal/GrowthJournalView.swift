import CoreData
import SwiftUI

/// Chronological journal for one plant, with growth summary and before/after comparison.
struct GrowthJournalView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router
    let plantID: UUID
    @FetchRequest private var plants: FetchedResults<Plant>
    @FetchRequest private var entries: FetchedResults<JournalEntry>
    @State private var pendingDelete: JournalEntry?

    init(plantID: UUID) {
        self.plantID = plantID
        _plants = FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "id == %@", plantID as CVarArg))
        _entries = FetchRequest(sortDescriptors: [SortDescriptor(\JournalEntry.entryDate, order: .reverse)], predicate: NSPredicate(format: "plant.id == %@", plantID as CVarArg))
    }

    var body: some View {
        let plant = plants.first
        let photos = entries.filter { $0.imageFilename != nil }

        ScrollView {
            VStack(alignment: .leading, spacing: LeafSpacing.lg) {
                if entries.isEmpty {
                    EmptyStateView(
                        illustration: "EmptyJournal",
                        title: "Start a growth journal",
                        message: "Record new leaves, repotting or changes in \(plant?.name ?? "your plant"). Add photos to compare growth over time.",
                        actionTitle: "Add first entry"
                    ) { router.present(.addJournal(plantID: plantID)) }
                    .padding(.top, LeafSpacing.xl)
                } else {
                    if let growth = Self.growthSummary(Array(entries)) {
                        Label {
                            Text(growth)
                        } icon: {
                            Image(systemName: "ruler")
                        }
                        .font(LeafFont.subheadline)
                        .foregroundStyle(LeafColor.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(LeafSpacing.sm)
                        .background(LeafColor.primarySoft, in: RoundedRectangle(cornerRadius: LeafRadius.md, style: .continuous))
                    }

                    if photos.count >= 2, let before = photos.last, let after = photos.first {
                        VStack(alignment: .leading, spacing: LeafSpacing.sm) {
                            SectionHeader("Before & after", subtitle: "\(before.entryDate.formatted(date: .abbreviated, time: .omitted)) → \(after.entryDate.formatted(date: .abbreviated, time: .omitted))")
                            BeforeAfterView(beforeFilename: before.imageFilename, afterFilename: after.imageFilename, category: plant?.category ?? .foliage)
                                .frame(height: 260)
                        }
                    }

                    VStack(alignment: .leading, spacing: LeafSpacing.sm) {
                        SectionHeader("Timeline")
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(entries) { entry in
                                JournalTimelineRow(entry: entry, isLast: entry.id == entries.last?.id, category: plant?.category ?? .foliage) {
                                    router.present(.editJournal(entry.id))
                                }
                                .contextMenu {
                                    Button("Edit", systemImage: "pencil") { router.present(.editJournal(entry.id)) }
                                    Button("Delete", systemImage: "trash", role: .destructive) { pendingDelete = entry }
                                }
                                .accessibilityAction(named: "Delete") { pendingDelete = entry }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, LeafSpacing.screen)
            .padding(.bottom, LeafSpacing.xl)
        }
        .leafScreenBackground()
        .navigationTitle(plant.map { "\($0.name)’s journal" } ?? "Journal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { router.present(.addJournal(plantID: plantID)) } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add journal entry")
                    .accessibilityIdentifier("journal.add")
            }
        }
        .confirmationDialog("Delete this entry?", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }), titleVisibility: .visible, presenting: pendingDelete) { entry in
            Button("Delete entry", role: .destructive) {
                do {
                    try env.journal.delete(entry)
                    env.toasts.show("Entry deleted", kind: .info)
                } catch {
                    env.toasts.showError(error)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("The note and its photo will be removed. This can’t be undone.")
        }
        .accessibilityIdentifier("screen.journal")
    }

    /// "Grew 26 cm across 3 measurements" from the earliest and latest heights.
    static func growthSummary(_ entries: [JournalEntry]) -> String? {
        let measured = entries.compactMap { e in e.heightCm.map { (e.entryDate, $0) } }.sorted { $0.0 < $1.0 }
        guard measured.count >= 2, let first = measured.first, let last = measured.last else { return nil }
        let delta = last.1 - first.1
        let amount = abs(delta).formatted(.number.precision(.fractionLength(0...1)))
        let verb = delta >= 0 ? "Grew" : "Shrank"
        return "\(verb) \(amount) cm across \(measured.count) measurements"
    }
}

private struct JournalTimelineRow: View {
    @ObservedObject var entry: JournalEntry
    let isLast: Bool
    let category: PlantCategory
    let onEdit: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: LeafSpacing.sm) {
            VStack(spacing: 0) {
                Circle()
                    .fill(LeafColor.accent)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().strokeBorder(LeafColor.background, lineWidth: 2))
                    .padding(.top, 4)
                if !isLast {
                    Rectangle().fill(LeafColor.border).frame(width: 2)
                }
            }
            .frame(width: 12)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: LeafSpacing.xs) {
                HStack {
                    Text(header)
                        .font(LeafFont.caption)
                        .foregroundStyle(LeafColor.textSecondary)
                    Spacer()
                    Button(action: onEdit) { Image(systemName: "pencil") }
                        .buttonStyle(.leafIcon)
                        .accessibilityLabel("Edit entry")
                }
                Text(entry.notes)
                    .font(LeafFont.body)
                    .foregroundStyle(LeafColor.text)
                    .fixedSize(horizontal: false, vertical: true)
                if let file = entry.imageFilename {
                    PlantThumbnail(imageFilename: file, category: category, cornerRadius: LeafRadius.lg)
                        .frame(height: 190)
                        .accessibilityLabel("Photo from this entry")
                }
            }
            .padding(.bottom, LeafSpacing.lg)
        }
        .accessibilityElement(children: .contain)
    }

    private var header: String {
        let date = entry.entryDate.formatted(date: .abbreviated, time: .omitted)
        guard let h = entry.heightCm else { return date }
        return "\(date) · \(h.formatted(.number.precision(.fractionLength(0...1)))) cm"
    }
}
