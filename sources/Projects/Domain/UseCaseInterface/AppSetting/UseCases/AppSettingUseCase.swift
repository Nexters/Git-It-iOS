public protocol AppSettingUseCase: Sendable {
    func notificationAuthorization() async -> NotificationAuthorizationStatus
    func requestNotificationAuthorization() async -> NotificationAuthorizationStatus
    func registerDevice() async throws
    func updateDeviceToken(_ token: DeviceToken) async throws
}
