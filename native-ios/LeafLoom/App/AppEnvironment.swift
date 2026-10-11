import CoreData
import OSLog
import SwiftUI

/// Dependency container created once at launch and shared through the SwiftUI environment.
@MainActor
@Observable
final class AppEnvironment {
    let persistence: PersistenceController
    let images: ImageStore
    let preferences: AppPreferences
    let router = AppRouter()
    let toasts = ToastCenter()
    let scheduler: ReminderScheduling
    let identifier: PlantIdentifying
    let knowledgeBase: PlantKnowledgeBase
    let plants: PlantRepository
    let tasks: CareTaskRepository
    let journal: JournalRepository
    let identifications: IdentificationRepository
    let maintenance: DataMaintenance
    let launch: LaunchConfiguration
    private(set) var startupError: String?

    var viewContext: NSManagedObjectContext { persistence.viewContext }

    init(launch: LaunchConfiguration = .current, identifier: PlantIdentifying? = nil, scheduler: ReminderScheduling? = nil) {
        self.launch = launch
        let isTest = launch.isUITesting || LaunchConfiguration.isRunningUnitTests
        let defaults: UserDefaults
        if isTest, let suite = UserDefaults(suiteName: "LeafLoomUITests") {
            suite.removePersistentDomain(forName: "LeafLoomUITests")
            defaults = suite
        } else {
            defaults = .standard
        }

        persistence = PersistenceController(inMemory: isTest)
        images = isTest
            ? ImageStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent("LeafLoomTestImages", isDirectory: true))
            : ImageStore()
        preferences = AppPreferences(defaults: defaults)
        knowledgeBase = .shared
        self.scheduler = scheduler ?? (isTest ? NoopReminderScheduler() : ReminderScheduler())
        self.identifier = identifier ?? Self.makeIdentifier(knowledgeBase: knowledgeBase, instant: isTest)

        let context = persistence.viewContext
        let prefs = preferences
        tasks = CareTaskRepository(context: context, scheduler: self.scheduler, reminderHour: { prefs.effectiveReminderHour })
        plants = PlantRepository(context: context, images: images, tasks: tasks)
        journal = JournalRepository(context: context, images: images)
        identifications = IdentificationRepository(context: context, images: images)
        maintenance = DataMaintenance(persistence: persistence, images: images, scheduler: self.scheduler, defaults: defaults)

        if let error = persistence.loadError {
            startupError = error.localizedDescription
            return
        }
        guard !LaunchConfiguration.isRunningUnitTests else { return }
        do {
            if launch.emptyState {
                try maintenance.eraseAll()
            } else if launch.resetData || launch.isUITesting {
                try maintenance.resetToSampleData()
            } else {
                try maintenance.seedIfNeeded()
            }
        } catch {
            Logger(subsystem: "com.leafloom.LeafLoom", category: "Startup").error("Seeding failed: \(error.localizedDescription, privacy: .public)")
        }
        if launch.skipOnboarding { preferences.onboardingComplete = true }
    }

    /// Core ML if `LeafLoomPlantClassifier.mlmodelc` is bundled and loads, otherwise the labelled demo service.
    static func makeIdentifier(knowledgeBase: PlantKnowledgeBase, instant: Bool) -> PlantIdentifying {
        if let url = CoreMLPlantIdentificationService.bundledModelURL(),
           let service = try? CoreMLPlantIdentificationService(modelURL: url, mapper: LabelMapper(knowledgeBase: knowledgeBase)) {
            return service
        }
        return DemoPlantIdentificationService(knowledgeBase: knowledgeBase, simulatedDelay: instant ? .zero : .milliseconds(900))
    }
}
