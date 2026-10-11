import Observation
import SwiftUI
import UIKit

struct Toast: Identifiable, Equatable {
    enum Kind { case success, info, error }

    let id = UUID()
    var message: String
    var kind: Kind = .success
    var actionTitle: String?
    var action: (() -> Void)?

    static func == (lhs: Toast, rhs: Toast) -> Bool { lhs.id == rhs.id }
}

/// App-wide transient messages (with optional Undo). One toast at a time.
@MainActor
@Observable
final class ToastCenter {
    private(set) var current: Toast?
    private var dismissTask: Task<Void, Never>?

    func show(_ message: String, kind: Toast.Kind = .success, actionTitle: String? = nil, duration: Duration = .seconds(4), action: (() -> Void)? = nil) {
        dismissTask?.cancel()
        let toast = Toast(message: message, kind: kind, actionTitle: actionTitle, action: action)
        current = toast
        UIAccessibility.post(notification: .announcement, argument: message)
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: actionTitle == nil ? duration : duration + .seconds(2))
            guard !Task.isCancelled else { return }
            self?.dismiss(toast.id)
        }
    }

    func showError(_ error: Error) {
        show(error.localizedDescription, kind: .error)
    }

    func dismiss(_ id: UUID? = nil) {
        guard id == nil || current?.id == id else { return }
        current = nil
    }

    func performAction() {
        let action = current?.action
        dismiss()
        action?()
    }
}

struct ToastOverlay: View {
    @Environment(ToastCenter.self) private var center
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack {
            Spacer()
            if let toast = center.current {
                HStack(spacing: LeafSpacing.sm) {
                    Image(systemName: icon(for: toast.kind))
                        .foregroundStyle(color(for: toast.kind))
                        .accessibilityHidden(true)
                    Text(toast.message)
                        .font(LeafFont.subheadline)
                        .foregroundStyle(LeafColor.onPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let title = toast.actionTitle {
                        Button(title) { center.performAction() }
                            .font(LeafFont.headline)
                            .foregroundStyle(LeafColor.sage)
                            .frame(minHeight: LeafSpacing.touchTarget)
                            .accessibilityIdentifier("toast.action")
                    }
                }
                .padding(.horizontal, LeafSpacing.md)
                .padding(.vertical, LeafSpacing.xs)
                .background(LeafColor.deep.opacity(0.96), in: RoundedRectangle(cornerRadius: LeafRadius.lg, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 16, y: 6)
                .padding(.horizontal, LeafSpacing.md)
                .padding(.bottom, 96)
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("toast")
            }
        }
        .animation(LeafMotion.animation(LeafMotion.spring, reduceMotion: reduceMotion), value: center.current)
    }

    private func icon(for kind: Toast.Kind) -> String {
        switch kind {
        case .success: "checkmark.circle.fill"
        case .info: "bell.fill"
        case .error: "exclamationmark.triangle.fill"
        }
    }

    private func color(for kind: Toast.Kind) -> Color {
        switch kind {
        case .success: LeafColor.sage
        case .info: LeafColor.amber
        case .error: Color(red: 0.95, green: 0.45, blue: 0.42)
        }
    }
}
