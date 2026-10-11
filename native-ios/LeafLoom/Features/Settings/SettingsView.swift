import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppPreferences.self) private var preferences
    @Environment(AppRouter.self) private var router
    @State private var confirm: DataAction?

    private enum DataAction: Identifiable {
        case reset, erase
        var id: Self { self }
    }

    var body: some View {
        @Bindable var preferences = preferences
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $preferences.theme) {
                    ForEach(ThemePreference.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("settings.theme")
                Picker("Collection layout", selection: $preferences.collectionLayout) {
                    Label("Grid", systemImage: "square.grid.2x2").tag(CollectionLayout.grid)
                    Label("List", systemImage: "list.bullet").tag(CollectionLayout.list)
                }
            }

            Section {
                NavigationLink(value: Route.reminderSettings) {
                    LabeledContent {
                        Text(preferences.remindersEnabled ? "\(Self.hourLabel(preferences.reminderHour))" : "Off")
                    } label: {
                        Label("Reminders", systemImage: "bell.badge")
                    }
                }
                .accessibilityIdentifier("settings.reminders")
            } header: {
                Text("Care")
            }

            Section {
                Button { preferences.onboardingComplete = false; router.reset() } label: {
                    Label("Replay onboarding", systemImage: "sparkles")
                }
                Button { confirm = .reset } label: {
                    Label("Reset to sample data", systemImage: "arrow.counterclockwise")
                }
                .accessibilityIdentifier("settings.reset")
                Button(role: .destructive) { confirm = .erase } label: {
                    Label("Erase all data", systemImage: "trash")
                }
                .accessibilityIdentifier("settings.erase")
            } header: {
                Text("Data")
            } footer: {
                Text("Your plants, photos and journal are stored only on this iPhone. LeafLoom has no account and sends nothing to a server.")
            }

            Section {
                NavigationLink(value: Route.about) {
                    Label("About LeafLoom", systemImage: "info.circle")
                }
                LabeledContent("Version", value: Self.versionString)
                LabeledContent("Plant identification", value: env.identifier.mode == .demo ? "Demo mode" : "On-device model")
            }
        }
        .scrollContentBackground(.hidden)
        .leafScreenBackground()
        .navigationTitle("Settings")
        .confirmationDialog(confirmTitle, isPresented: Binding(get: { confirm != nil }, set: { if !$0 { confirm = nil } }), titleVisibility: .visible, presenting: confirm) { action in
            switch action {
            case .reset:
                Button("Reset to sample data", role: .destructive) { perform(.reset) }
            case .erase:
                Button("Erase everything", role: .destructive) { perform(.erase) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { action in
            switch action {
            case .reset: Text("All plants, tasks, journal entries and photos are replaced with the eight sample plants.")
            case .erase: Text("All plants, tasks, journal entries, identifications and photos are permanently deleted.")
            }
        }
        .accessibilityIdentifier("screen.settings")
    }

    private var confirmTitle: String {
        switch confirm {
        case .reset: "Reset to sample data?"
        case .erase: "Erase all data?"
        case nil: ""
        }
    }

    private func perform(_ action: DataAction) {
        do {
            switch action {
            case .reset: try env.maintenance.resetToSampleData()
            case .erase: try env.maintenance.eraseAll()
            }
            env.tasks.rescheduleAll()
            router.reset()
            env.toasts.show(action == .reset ? "Sample data restored" : "All data erased", kind: .info)
        } catch {
            env.toasts.showError(error)
        }
    }

    static func hourLabel(_ hour: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }

    static var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
