import UserNotifications

// MARK: - UNUserNotificationCenterLocalNotificationClient

public final class UNUserNotificationCenterLocalNotificationClient: LocalNotificationClient, Sendable {

    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public func requestAuthorization() async -> LocalNotificationAuthorizationOutcome {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .badge, .sound],
                )
                return granted ? .authorized : .declined
            } catch {
                return .declined
            }

        case .denied:
            return .previouslyDenied

        case .authorized, .provisional, .ephemeral:
            return .authorized

        @unknown default:
            return .declined
        }
    }

    public func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            true

        case .notDetermined, .denied:
            false

        @unknown default:
            false
        }
    }

    public func presentGenerationCompletedNotification(projectID: String) {
        let content = UNMutableNotificationContent()
        content.title = "세트 생성 완료"
        content.body = "학습 세트 생성이 완료됐어요. 지금 확인해보세요."
        let request = UNNotificationRequest(
            identifier: "generation-completed-\(projectID)",
            content: content,
            trigger: nil,
        )
        UNUserNotificationCenter.current().add(request)
    }

}
