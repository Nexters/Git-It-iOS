public struct RequestGenerationReminder: RequestGenerationReminderUseCase, Sendable {

    // MARK: Lifecycle

    public init(
        authorizationGateway: any NotificationAuthorizationGateway,
        reminderRegistry: any GenerationReminderRegistry,
    ) {
        self.authorizationGateway = authorizationGateway
        self.reminderRegistry = reminderRegistry
    }

    // MARK: Public

    public func callAsFunction(projectID: String) async -> NotificationAuthorizationOutcome {
        let outcome = await authorizationGateway.requestAuthorization()
        if outcome == .authorized {
            await reminderRegistry.register(projectID: projectID)
        }
        return outcome
    }

    // MARK: Private

    private let authorizationGateway: any NotificationAuthorizationGateway
    private let reminderRegistry: any GenerationReminderRegistry

}
