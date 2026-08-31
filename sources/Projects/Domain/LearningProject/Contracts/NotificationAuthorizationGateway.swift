public protocol NotificationAuthorizationGateway: Sendable {
    func requestAuthorization() async -> NotificationAuthorizationOutcome
}
