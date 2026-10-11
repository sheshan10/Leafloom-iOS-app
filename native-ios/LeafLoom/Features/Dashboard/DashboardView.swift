import CoreData
import SwiftUI

/// Personal dashboard. Every number is computed from stored records by `InsightsCalculator`.
struct DashboardView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router
    @FetchRequest(sortDescriptors: [SortDescriptor(\Plant.dateAdded, order: .reverse)])
    private var plants: FetchedResults<Plant>
    @FetchRequest(sortDescriptors: [SortDescriptor(\CareTask.dueDate)])
    private var tasks: FetchedResults<CareTask>

    var body: some View {
        let now = Date.now
        let summary = InsightsCalculator.summary(plants: Array(plants), tasks: Array(tasks), now: now)
        let open = tasks.filter { !$0.isCompleted }
        let today = open.filter { CareStatusEvaluator.needsAttention($0, now: now) }
        let upcoming = open.filter { CareStatusEvaluator.status(of: $0, now: now) == .upcoming && CareCalendar().daysBetween(now, $0.dueDate) <= 7 }
        let attention = plants.filter { summary.needsAttentionPlantIDs.contains($0.id) }

        ScrollView {
            VStack(alignment: .leading, spacing: LeafSpacing.lg) {
                header(now: now)

                if plants.isEmpty && tasks.isEmpty {
                    EmptyStateView(
                        illustration: "EmptyPlants",
                        title: "Your garden starts here",
                        message: "Add your first plant to get care reminders, a growth journal and insights.",
                        actionTitle: "Add a plant"
                    ) { router.present(.addPlant()) }
                    .leafCard()
                } else {
                    progressCard(summary)
                    statsGrid(summary)

                    if !attention.isEmpty {
                        VStack(alignment: .leading, spacing: LeafSpacing.sm) {
                            SectionHeader("Needs attention", subtitle: "Overdue or due today")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: LeafSpacing.sm) {
                                    ForEach(attention) { plant in
                                        Button { router.push(.plantDetails(plant.id)) } label: {
                                            PlantCardView(plant: plant) { env.toggleFavorite(plant) }
                                                .frame(width: 168)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .scrollClipDisabled()
                        }
                    }

                    taskSection(title: "Today’s care", subtitle: today.isEmpty ? nil : "\(today.count) to do", tasks: Array(today.prefix(6)), empty: "Nothing due today. Enjoy your plants!")
                    taskSection(title: "Coming up", subtitle: "Next 7 days", tasks: Array(upcoming.prefix(5)), empty: "No care scheduled this week.")

                    if !plants.isEmpty {
                        VStack(alignment: .leading, spacing: LeafSpacing.sm) {
                            SectionHeader("Recently added") {
                                Button("See all") { router.select(.plants) }
                            }
                            VStack(spacing: 0) {
                                ForEach(Array(plants.prefix(3))) { plant in
                                    Button { router.push(.plantDetails(plant.id)) } label: { PlantRowView(plant: plant) }
                                        .buttonStyle(.plain)
                                        .padding(.vertical, LeafSpacing.xxs)
                                    if plant.id != plants.prefix(3).last?.id { Divider() }
                                }
                            }
                            .leafCard(padding: LeafSpacing.sm)
                        }
                    }
                }
            }
            .padding(.horizontal, LeafSpacing.screen)
            .padding(.bottom, LeafSpacing.xl)
        }
        .leafScreenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen.home")
    }

    private func header(now: Date) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(now.formatted(.dateTime.weekday(.wide).day().month(.wide))).eyebrowStyle()
                Text(RelativeDayFormatter.greeting(for: now))
                    .font(LeafFont.largeTitle)
                    .foregroundStyle(LeafColor.text)
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer()
            Button { router.push(.settings, in: .home) } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.leafIcon)
            .accessibilityLabel("Settings")
            .accessibilityIdentifier("home.settings")
        }
        .padding(.top, LeafSpacing.md)
    }

    private func progressCard(_ s: DashboardSummary) -> some View {
        HStack(spacing: LeafSpacing.md) {
            ProgressRing(progress: s.weeklyProgress, lineWidth: 11, label: "Care completed this week", caption: "this week")
                .frame(width: 118, height: 118)
            VStack(alignment: .leading, spacing: LeafSpacing.xs) {
                Text("Weekly care").font(LeafFont.title3).foregroundStyle(LeafColor.text)
                Text(s.completedThisWeek == 0 && s.weeklyProgress == 0
                     ? "Complete a task to start this week’s progress."
                     : "\(s.completedThisWeek) done this week. \(s.overdueCount + s.dueTodayCount) still need attention.")
                    .font(LeafFont.subheadline)
                    .foregroundStyle(LeafColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("View care") { router.select(.care) }
                    .font(LeafFont.subheadline.weight(.semibold))
                    .foregroundStyle(LeafColor.primary)
            }
        }
        .leafCard()
    }

    private func statsGrid(_ s: DashboardSummary) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: LeafSpacing.sm)], spacing: LeafSpacing.sm) {
            StatisticCard(title: "Plants", value: "\(s.totalPlants)", systemImage: "leaf.fill", footnote: "\(s.favorites) favourites")
            StatisticCard(title: "Due today", value: "\(s.dueTodayCount)", systemImage: "clock.fill", tint: LeafColor.amberText)
            StatisticCard(title: "Overdue", value: "\(s.overdueCount)", systemImage: "exclamationmark.circle.fill", tint: LeafColor.danger)
            StatisticCard(title: "On schedule", value: "\(s.onSchedulePercent)%", systemImage: "calendar.badge.checkmark", tint: LeafColor.success, footnote: "Plants with no overdue care")
        }
    }

    @ViewBuilder
    private func taskSection(title: String, subtitle: String?, tasks: [CareTask], empty: String) -> some View {
        VStack(alignment: .leading, spacing: LeafSpacing.sm) {
            SectionHeader(title, subtitle: subtitle)
            if tasks.isEmpty {
                Label(empty, systemImage: "sun.max")
                    .font(LeafFont.subheadline)
                    .foregroundStyle(LeafColor.textSecondary)
                    .leafCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(tasks) { task in
                        CareTaskRow(task: task) { env.toggleCompletion(task) }
                            .contentShape(Rectangle())
                            .onTapGesture { router.push(.taskDetails(task.id)) }
                            .accessibilityAction(named: "Open details") { router.push(.taskDetails(task.id)) }
                        if task.id != tasks.last?.id { Divider().padding(.leading, 88) }
                    }
                }
                .leafCard(padding: LeafSpacing.xs)
            }
        }
    }
}
