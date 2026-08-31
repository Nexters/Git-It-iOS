public protocol RequestGenerationReminderUseCase: Sendable {
    func callAsFunction(projectID: String) async -> NotificationAuthorizationOutcome
}
