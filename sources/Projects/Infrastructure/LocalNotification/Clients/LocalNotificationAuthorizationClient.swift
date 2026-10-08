import Foundation
import os
import UserNotifications

// MARK: - LocalNotificationAuthorizationClient

public final class LocalNotificationAuthorizationClient: NotificationAuthorizationClient, Sendable {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func requestAuthorization() async -> NotificationAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let outcome: NotificationAuthorizationStatus
        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .badge, .sound]
                )
                outcome = granted ? .authorized : .declined
            } catch {
                Self.logger.debug("requestAuthorization 호출 실패: \(String(describing: error), privacy: .public)")
                outcome = .declined
            }

        case .denied:
            outcome = .previouslyDenied

        case .authorized,
             .provisional,
             .ephemeral:
            outcome = .authorized

        @unknown default:
            outcome = .declined
        }
        Self.logger.debug("requestAuthorization 결과: \(String(describing: outcome), privacy: .public)")
        return outcome
    }

    public func authorizationSetting() async -> NotificationAuthorizationSetting {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined

        case .denied:
            return .denied

        case .authorized,
             .provisional,
             .ephemeral:
            return .authorized

        @unknown default:
            return .denied
        }
    }

    // MARK: Private

    private static let logger = Logger(
        subsystem: "com.nexters.hytime.gitit",
        category: "LocalNotificationAuthorizationClient",
    )

}
