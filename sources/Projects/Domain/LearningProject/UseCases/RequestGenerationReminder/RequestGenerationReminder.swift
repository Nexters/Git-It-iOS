public struct RequestGenerationReminder: RequestGenerationReminderUseCase, Sendable {

    // MARK: Lifecycle

    public init(
        notificationAuthorization: any NotificationAuthorization,
        reminderRegistration: any GenerationReminderRegistration,
    ) {
        self.notificationAuthorization = notificationAuthorization
        self.reminderRegistration = reminderRegistration
    }

    // MARK: Public

    public func callAsFunction(projectID: String) async -> NotificationAuthorizationOutcome {
        let outcome = await notificationAuthorization.requestAuthorization()
        if outcome == .authorized {
            await reminderRegistration.register(projectID: projectID)
        }
        return outcome
    }

    public func requestAuthorization() async -> NotificationAuthorizationOutcome {
        await notificationAuthorization.requestAuthorization()
    }

    public func isAuthorized() async -> Bool {
        await notificationAuthorization.isAuthorized()
    }

    // MARK: Private

    private let notificationAuthorization: any NotificationAuthorization
    private let reminderRegistration: any GenerationReminderRegistration

}
