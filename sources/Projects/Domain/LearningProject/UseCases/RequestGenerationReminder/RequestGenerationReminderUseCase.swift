public protocol RequestGenerationReminderUseCase: Sendable {
    func callAsFunction(projectID: String) async -> NotificationAuthorizationOutcome

    func requestAuthorization() async -> NotificationAuthorizationOutcome

    func isAuthorized() async -> Bool
}
