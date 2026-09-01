import os
import UserNotifications

// MARK: - UserNotificationCenterLocalClient

public final class UserNotificationCenterLocalClient: LocalNotificationClient, Sendable {

    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public func requestAuthorization() async -> LocalNotificationAuthorizationOutcome {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let outcome: LocalNotificationAuthorizationOutcome
        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .badge, .sound],
                )
                outcome = granted ? .authorized : .declined
            } catch {
                Self.logger.debug("requestAuthorization 호출 실패: \(String(describing: error), privacy: .public)")
                outcome = .declined
            }

        case .denied:
            outcome = .previouslyDenied

        case .authorized, .provisional, .ephemeral:
            outcome = .authorized

        @unknown default:
            outcome = .declined
        }
        Self.logger.debug("requestAuthorization 결과: \(String(describing: outcome), privacy: .public)")
        return outcome
    }

    public func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true

        case .notDetermined, .denied:
            return false

        @unknown default:
            return false
        }
    }

    public func presentGenerationCompletedNotification(projectID: String) {
        Self.logger.debug("생성 완료 로컬 알림 발송: projectID=\(projectID, privacy: .public)")
        let content = UNMutableNotificationContent()
        content.title = "세트 생성 완료"
        content.body = "학습 세트 생성이 완료됐어요. 지금 확인해보세요."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "generation-completed-\(projectID)",
            content: content,
            trigger: nil,
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: Private

    private static let logger = Logger(subsystem: "com.nexters.hytime.gitit", category: "UserNotificationCenterLocalClient")

}
