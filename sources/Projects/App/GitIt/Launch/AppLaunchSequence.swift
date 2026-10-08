// MARK: - AppLaunchSequence

struct AppLaunchSequence: Sendable {

    // MARK: Lifecycle

    init(
        recordSharedSessionState: @escaping @Sendable () async -> Void,
        activatePushClient: @escaping @Sendable () -> Void,
        configureAppDelegate: @escaping @MainActor @Sendable () -> Void,
    ) {
        self.recordSharedSessionState = recordSharedSessionState
        self.activatePushClient = activatePushClient
        self.configureAppDelegate = configureAppDelegate
    }

    // MARK: Internal

    @MainActor
    func callAsFunction() async {
        await recordSharedSessionState()
        activatePushClient()
        configureAppDelegate()
    }

    // MARK: Private

    private let recordSharedSessionState: @Sendable () async -> Void
    private let activatePushClient: @Sendable () -> Void
    private let configureAppDelegate: @MainActor @Sendable () -> Void

}
