import DataNotification
import DomainLearningProject
import os

// MARK: - NotificationAuthorizationAdapter

struct NotificationAuthorizationAdapter: NotificationAuthorization {

    // MARK: Internal

    let reminderNotifier: any LocalReminderNotifier

    func requestAuthorization() async -> NotificationAuthorizationOutcome {
        let outcome: NotificationAuthorizationOutcome =
            switch await reminderNotifier.requestAuthorization() {
            case .authorized: .authorized
            case .declined: .declined
            case .previouslyDenied: .previouslyDenied
            }
        Self.logger.debug("알림 권한 요청 결과: \(String(describing: outcome), privacy: .public)")
        return outcome
    }

    func isAuthorized() async -> Bool {
        await reminderNotifier.isAuthorized()
    }

    // MARK: Private

    private static let logger = Logger(subsystem: "com.nexters.hytime.gitit", category: "NotificationAuthorizationAdapter")

}
