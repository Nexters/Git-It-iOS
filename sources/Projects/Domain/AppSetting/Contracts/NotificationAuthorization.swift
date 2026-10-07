public protocol NotificationAuthorization: Sendable {
    func status() async -> NotificationAuthorizationStatus
    func requestAuthorization() async -> NotificationAuthorizationStatus
}
