import SwiftUI
import UIKit

/// Reminder preferences and the real notification permission state.
struct ReminderSettingsView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppPreferences.self) private var preferences
    @Environment(\.scenePhase) private var scenePhase
    @State private var authorization: ReminderAuthorization?

    var body: some View {
        @Bindable var preferences = preferences
        Form {
            Section {
                permissionRow
            } header: {
                Text("Permission")
            }

            Section {
                Toggle("Care reminders", isOn: $preferences.remindersEnabled)
                    .accessibilityIdentifier("reminders.toggle")
                if preferences.remindersEnabled {
                    Picker("Remind me at", selection: $preferences.reminderHour) {
                        ForEach(6...22, id: \.self) { Text(SettingsView.hourLabel($0)).tag($0) }
                    }
                }
            } header: {
                Text("Schedule")
            } footer: {
                Text("You get one notification per task on the day it’s due. If that time has already passed today, it arrives a minute later. Overdue tasks don’t notify again.")
            }
        }
        .scrollContentBackground(.hidden)
        .leafScreenBackground()
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refresh() } }
        }
        .onChange(of: preferences.remindersEnabled) { env.tasks.rescheduleAll() }
        .onChange(of: preferences.reminderHour) { env.tasks.rescheduleAll() }
    }

    @ViewBuilder
    private var permissionRow: some View {
        switch authorization {
        case nil:
            ProgressView()
        case .authorized?:
            Label("Notifications are allowed", systemImage: "checkmark.circle.fill")
                .foregroundStyle(LeafColor.success)
        case .notDetermined?:
            VStack(alignment: .leading, spacing: LeafSpacing.xs) {
                Text("LeafLoom hasn’t asked for permission yet. Reminders need it.")
                    .font(LeafFont.subheadline)
                    .foregroundStyle(LeafColor.textSecondary)
                Button("Allow notifications") {
                    Task {
                        if await env.scheduler.requestAuthorization() { env.tasks.rescheduleAll() }
                        await refresh()
                    }
                }
                .accessibilityIdentifier("reminders.allow")
            }
        case .denied?:
            VStack(alignment: .leading, spacing: LeafSpacing.xs) {
                Label("Notifications are turned off for LeafLoom", systemImage: "bell.slash.fill")
                    .foregroundStyle(LeafColor.danger)
                Text("Your tasks still appear in the app. To get reminders, allow notifications in the Settings app.")
                    .font(LeafFont.subheadline)
                    .foregroundStyle(LeafColor.textSecondary)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }

    private func refresh() async {
        let status = await env.scheduler.authorizationStatus()
        if status == .authorized, authorization != .authorized { env.tasks.rescheduleAll() }
        authorization = status
    }
}
