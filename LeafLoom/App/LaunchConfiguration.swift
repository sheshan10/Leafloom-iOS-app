import Foundation

/// Launch arguments used by UI tests (and handy for demos) to get deterministic state.
///
/// - `-uiTesting`: in-memory store, isolated preferences, no notification prompts, instant demo identification.
/// - `-resetData`: replace everything with the sample collection on launch.
/// - `-emptyState`: start with no plants, tasks or journal entries.
/// - `-skipOnboarding`: go straight to the main tabs.
struct LaunchConfiguration: Sendable {
    var isUITesting = false
    var resetData = false
    var emptyState = false
    var skipOnboarding = false

    static let current = LaunchConfiguration(arguments: ProcessInfo.processInfo.arguments)

    init(arguments: [String]) {
        isUITesting = arguments.contains("-uiTesting")
        resetData = arguments.contains("-resetData")
        emptyState = arguments.contains("-emptyState")
        skipOnboarding = arguments.contains("-skipOnboarding")
    }

    init() {}

    /// Unit tests host the app; never seed or touch the real store while XCTest is running.
    static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            && !ProcessInfo.processInfo.arguments.contains("-uiTesting")
    }
}
