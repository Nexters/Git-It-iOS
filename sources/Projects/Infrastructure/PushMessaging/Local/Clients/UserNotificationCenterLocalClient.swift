import Foundation
import os
import UserNotifications

// MARK: - UserNotificationCenterLocalClient

public final class UserNotificationCenterLocalClient: LocalNotificationClient, Sendable {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func requestAuthorization() async -> LocalNotificationAuthorizationOutcome {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let outcome: LocalNotificationAuthorizationOutcome
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

    public func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized,
             .provisional,
             .ephemeral:
            return true

        case .notDetermined,
             .denied:
            return false

        @unknown default:
            return false
        }
    }

    public func present(_ request: LocalNotificationRequest) {
        Self.logger.debug("로컬 알림 발송: identifier=\(request.identifier, privacy: .public)")
        add(request, trigger: nil)
    }

    public func schedule(
        _ request: LocalNotificationRequest,
        at date: Date,
    ) {
        let delay = date.timeIntervalSinceNow
        Self.logger.debug(
            "로컬 알림 예약: identifier=\(request.identifier, privacy: .public) delay=\(delay, privacy: .public)"
        )
        // 같은 식별자의 이전 예약을 먼저 제거해 예약이 1건만 남게 한다.
        cancel(identifier: request.identifier)
        guard delay > 0 else {
            // 이미 지난 시각이면 추가 지연 없이 즉시 발송한다.
            add(request, trigger: nil)
            return
        }
        add(request, trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false))
    }

    public func cancel(identifier: String) {
        Self.logger.debug("로컬 알림 예약 취소: identifier=\(identifier, privacy: .public)")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: Private

    private static let logger = Logger(subsystem: "com.nexters.hytime.gitit", category: "UserNotificationCenterLocalClient")

    private func add(
        _ request: LocalNotificationRequest,
        trigger: UNNotificationTrigger?,
    ) {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default
        let notificationRequest = UNNotificationRequest(
            identifier: request.identifier,
            content: content,
            trigger: trigger,
        )
        UNUserNotificationCenter.current().add(notificationRequest)
    }

}
