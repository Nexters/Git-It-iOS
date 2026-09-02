public protocol RequestGenerationReminderUseCase: Sendable {
    func callAsFunction(projectID: String) async -> NotificationAuthorizationOutcome

    func isAuthorized() async -> Bool
}
