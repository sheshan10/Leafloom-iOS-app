import CoreData
import SwiftUI

/// Small cross-screen actions that combine a repository call with user feedback.
extension AppEnvironment {
    /// Completes (with an Undo toast) or un-completes a task.
    func toggleCompletion(_ task: CareTask) {
        do {
            if task.isCompleted {
                try tasks.undoCompletion(task)
                toasts.show("Marked “\(task.title)” as not done", kind: .info)
            } else {
                let spawned = try tasks.complete(task)
                let message = spawned.map { "Done! Next time: \(RelativeDayFormatter.string(for: $0.dueDate).lowercased())" } ?? "Nice work — task completed"
                toasts.show(message, actionTitle: "Undo") { [weak self] in
                    guard let self, !task.isDeleted, task.managedObjectContext != nil else { return }
                    do { try self.tasks.undoCompletion(task) } catch { self.toasts.showError(error) }
                }
            }
        } catch {
            toasts.showError(error)
        }
    }

    func toggleFavorite(_ plant: Plant) {
        do {
            try plants.toggleFavorite(plant)
        } catch {
            toasts.showError(error)
        }
    }
}
