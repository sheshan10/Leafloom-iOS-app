import Charts
import CoreData
import SwiftUI

/// Charts and statistics computed from stored records only (see `InsightsCalculator`).
struct InsightsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FetchRequest(sortDescriptors: [SortDescriptor(\Plant.dateAdded)])
    private var plants: FetchedResults<Plant>
    @FetchRequest(sortDescriptors: [SortDescriptor(\CareTask.dueDate)])
    private var tasks: FetchedResults<CareTask>

    var body: some View {
        let now = Date.now
        let plantList = Array(plants)
        let taskList = Array(tasks)
        let summary = InsightsCalculator.summary(plants: plantList, tasks: taskList, now: now)
        let trend = InsightsCalculator.completionTrend(taskList, now: now)
        let mix = InsightsCalculator.careByCategory(taskList)
        let categories = InsightsCalculator.plantsByCategory(plantList)
        let additions = InsightsCalculator.additionsByMonth(plantList, now: now)

        ScrollView {
            VStack(alignment: .leading, spacing: LeafSpacing.lg) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calculated from your records").eyebrowStyle()
                    Text("Insights").font(LeafFont.largeTitle).foregroundStyle(LeafColor.text).accessibilityAddTraits(.isHeader)
                }
                .padding(.top, LeafSpacing.md)

                if plantList.isEmpty && taskList.isEmpty {
                    EmptyStateView(illustration: "EmptyInsights", title: "No insights yet", message: "Add plants and complete care tasks to see trends here.")
                        .leafCard()
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: LeafSpacing.sm)], spacing: LeafSpacing.sm) {
                        StatisticCard(title: "Total plants", value: "\(summary.totalPlants)", systemImage: "leaf.fill")
                        StatisticCard(title: "Favourites", value: "\(summary.favorites)", systemImage: "heart.fill", tint: LeafColor.terracotta)
                        StatisticCard(title: "Done this week", value: "\(summary.completedThisWeek)", systemImage: "checkmark.circle.fill", tint: LeafColor.success)
                        StatisticCard(title: "Due next 7 days", value: "\(summary.upcomingWeekCount)", systemImage: "calendar", tint: LeafColor.info)
                    }

                    SectionHeader("Care consistency")
                    chartCard(title: "Tasks completed per week", subtitle: "Last 8 weeks", summary: trendSummary(trend)) {
                        Chart(trend) { point in
                            AreaMark(x: .value("Week", point.start, unit: .weekOfYear), y: .value("Completed", point.count))
                                .foregroundStyle(LinearGradient(colors: [LeafColor.accent.opacity(0.35), LeafColor.accent.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                                .interpolationMethod(.monotone)
                            LineMark(x: .value("Week", point.start, unit: .weekOfYear), y: .value("Completed", point.count))
                                .foregroundStyle(LeafColor.accent)
                                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                                .interpolationMethod(.monotone)
                            PointMark(x: .value("Week", point.start, unit: .weekOfYear), y: .value("Completed", point.count))
                                .foregroundStyle(LeafColor.primary)
                                .symbolSize(30)
                        }
                        .chartYAxis { AxisMarks(position: .leading) }
                        .chartXAxis { AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { _ in AxisValueLabel(format: .dateTime.day().month(.abbreviated)) } }
                    }

                    if !mix.isEmpty {
                        chartCard(title: "Completed care by type", subtitle: "All time", summary: mixSummary(mix)) {
                            HStack(spacing: LeafSpacing.md) {
                                Chart(mix) { item in
                                    SectorMark(angle: .value("Tasks", item.count), innerRadius: .ratio(0.6), angularInset: 2)
                                        .foregroundStyle(by: .value("Type", item.category.label))
                                        .cornerRadius(4)
                                }
                                .chartForegroundStyleScale(
                                    domain: mix.map(\.category.label),
                                    range: mix.indices.map { LeafColor.chartPalette[$0 % LeafColor.chartPalette.count] }
                                )
                                .chartLegend(.hidden)
                                .frame(width: 140, height: 140)
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(Array(mix.enumerated()), id: \.element.id) { index, item in
                                        HStack(spacing: 6) {
                                            Circle().fill(LeafColor.chartPalette[index % LeafColor.chartPalette.count]).frame(width: 10, height: 10)
                                            Text(item.category.label).font(LeafFont.caption).foregroundStyle(LeafColor.text)
                                            Spacer(minLength: 4)
                                            Text("\(item.count)").font(LeafFont.caption).foregroundStyle(LeafColor.textSecondary)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if !categories.isEmpty {
                        SectionHeader("Your collection")
                        chartCard(title: "Plants by category", subtitle: "\(summary.totalPlants) plants", summary: categorySummary(categories)) {
                            Chart(categories) { item in
                                BarMark(x: .value("Plants", item.count), y: .value("Category", item.category.label))
                                    .foregroundStyle(LeafColor.primary.gradient)
                                    .cornerRadius(6)
                                    .annotation(position: .trailing) {
                                        Text("\(item.count)").font(LeafFont.caption).foregroundStyle(LeafColor.textSecondary)
                                    }
                            }
                            .chartXAxis(.hidden)
                            .frame(height: CGFloat(max(categories.count, 2)) * 36)
                        }

                        chartCard(title: "Plants added", subtitle: "Last 6 months", summary: additionsSummary(additions)) {
                            Chart(additions) { point in
                                BarMark(x: .value("Month", point.start, unit: .month), y: .value("Added", point.count))
                                    .foregroundStyle(LeafColor.accent.gradient)
                                    .cornerRadius(6)
                            }
                            .chartXAxis { AxisMarks(values: .stride(by: .month)) { _ in AxisValueLabel(format: .dateTime.month(.abbreviated)) } }
                            .chartYAxis { AxisMarks(position: .leading) }
                        }
                    }
                }
            }
            .padding(.horizontal, LeafSpacing.screen)
            .padding(.bottom, LeafSpacing.xl)
        }
        .leafScreenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .transaction { if reduceMotion { $0.animation = nil } }
        .accessibilityIdentifier("screen.insights")
    }

    private func chartCard<Content: View>(title: String, subtitle: String, summary: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: LeafSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(LeafFont.headline).foregroundStyle(LeafColor.text)
                Text(subtitle).font(LeafFont.footnote).foregroundStyle(LeafColor.textSecondary)
            }
            content()
                .frame(minHeight: 160)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(title)
                .accessibilityValue(summary)
        }
        .leafCard()
    }

    // MARK: Spoken summaries (the charts themselves are hidden from VoiceOver in favour of these)

    private func trendSummary(_ t: [CountPoint]) -> String {
        let total = t.reduce(0) { $0 + $1.count }
        guard let best = t.max(by: { $0.count < $1.count }), total > 0 else { return "No tasks completed in the last 8 weeks." }
        return "\(total) tasks completed in 8 weeks. Busiest week started \(best.start.formatted(date: .abbreviated, time: .omitted)) with \(best.count). This week: \(t.last?.count ?? 0)."
    }

    private func mixSummary(_ m: [CategoryCount<CareCategory>]) -> String {
        m.map { "\($0.category.label) \($0.count)" }.joined(separator: ", ")
    }

    private func categorySummary(_ c: [CategoryCount<PlantCategory>]) -> String {
        c.map { "\($0.category.label) \($0.count)" }.joined(separator: ", ")
    }

    private func additionsSummary(_ a: [CountPoint]) -> String {
        a.map { "\($0.start.formatted(.dateTime.month(.wide))) \($0.count)" }.joined(separator: ", ")
    }
}
