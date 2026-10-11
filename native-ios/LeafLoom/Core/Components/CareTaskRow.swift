import SwiftUI

/// A care task with a completion check button. The check is announced as a toggle with its state.
struct CareTaskRow: View {
    @ObservedObject var task: CareTask
    var showsPlant = true
    let onToggle: () -> Void

    var body: some View {
        let status = task.status
        HStack(spacing: LeafSpacing.sm) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .strokeBorder(task.isCompleted ? Color.clear : LeafColor.primary.opacity(0.5), lineWidth: 2)
                        .background(Circle().fill(task.isCompleted ? LeafColor.success : Color.clear))
                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(LeafColor.onPrimary)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 28, height: 28)
                .frame(width: LeafSpacing.touchTarget, height: LeafSpacing.touchTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: task.isCompleted) { _, new in new }
            .accessibilityLabel(task.isCompleted ? "Mark \(task.title) as not done" : "Mark \(task.title) as done")
            .accessibilityAddTraits(task.isCompleted ? [.isSelected] : [])
            .accessibilityIdentifier("taskCheck")

            CareCategoryIcon(category: task.category)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(LeafFont.headline)
                    .foregroundStyle(task.isCompleted ? LeafColor.textSecondary : LeafColor.text)
                    .strikethrough(task.isCompleted, color: LeafColor.textTertiary)
                    .lineLimit(2)
                HStack(spacing: 4) {
                    if showsPlant, let plant = task.plant { Text("\(plant.name) ·") }
                    Text(whenText)
                    if let interval = task.recurrenceIntervalDays {
                        Image(systemName: "repeat").accessibilityHidden(true)
                        Text("\(interval)d").accessibilityLabel("repeats every \(interval) days")
                    }
                }
                .font(LeafFont.caption)
                .foregroundStyle(LeafColor.textSecondary)
                .lineLimit(1)
            }
            Spacer(minLength: 0)
            StatusBadge(status: status)
        }
        .padding(.vertical, 2)
        .leafAnimation(value: task.isCompleted)
    }

    private var whenText: String {
        if task.isCompleted, let done = task.completedAt {
            return "Done \(RelativeDayFormatter.string(for: done).lowercased())"
        }
        return RelativeDayFormatter.string(for: task.dueDate)
    }
}
