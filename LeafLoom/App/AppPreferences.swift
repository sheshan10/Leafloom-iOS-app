import Observation
import SwiftUI

enum ThemePreference: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum CollectionLayout: String, CaseIterable, Identifiable {
    case grid, list
    var id: String { rawValue }
}

/// User preferences persisted in UserDefaults. Observable so every screen updates immediately.
@Observable
final class AppPreferences {
    private let defaults: UserDefaults

    var theme: ThemePreference { didSet { defaults.set(theme.rawValue, forKey: Keys.theme) } }
    var collectionLayout: CollectionLayout { didSet { defaults.set(collectionLayout.rawValue, forKey: Keys.layout) } }
    var remindersEnabled: Bool { didSet { defaults.set(remindersEnabled, forKey: Keys.reminders) } }
    var reminderHour: Int { didSet { defaults.set(reminderHour, forKey: Keys.hour) } }
    var onboardingComplete: Bool { didSet { defaults.set(onboardingComplete, forKey: Keys.onboarding) } }

    private enum Keys {
        static let theme = "theme"
        static let layout = "collectionLayout"
        static let reminders = "remindersEnabled"
        static let hour = "reminderHour"
        static let onboarding = "onboardingComplete"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        theme = ThemePreference(rawValue: defaults.string(forKey: Keys.theme) ?? "") ?? .system
        collectionLayout = CollectionLayout(rawValue: defaults.string(forKey: Keys.layout) ?? "") ?? .grid
        remindersEnabled = defaults.object(forKey: Keys.reminders) as? Bool ?? true
        reminderHour = defaults.object(forKey: Keys.hour) as? Int ?? 9
        onboardingComplete = defaults.bool(forKey: Keys.onboarding)
    }

    /// The hour to schedule reminders at, or nil when the user switched reminders off.
    var effectiveReminderHour: Int? { remindersEnabled ? reminderHour : nil }
}
