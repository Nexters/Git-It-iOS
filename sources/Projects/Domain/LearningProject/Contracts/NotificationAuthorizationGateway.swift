public protocol NotificationAuthorizationGateway: Sendable {
    func requestAuthorization() async -> NotificationAuthorizationOutcome
    func isAuthorized() async -> Bool
}
