import DomainLearningProject
import InfrastructureLocalNotification
import os

// MARK: - NotificationAuthorizationGatewayAdapter

struct NotificationAuthorizationGatewayAdapter: NotificationAuthorizationGateway {

    // MARK: Internal

    let localNotificationClient: any NotificationAuthorizationClient

    func requestAuthorization() async -> NotificationAuthorizationOutcome {
        let outcome: NotificationAuthorizationOutcome =
            switch await localNotificationClient.requestAuthorization() {
            case .authorized: .authorized
            case .declined: .declined
            case .previouslyDenied: .previouslyDenied
            }
        Self.logger.debug("알림 권한 요청 결과: \(String(describing: outcome), privacy: .public)")
        return outcome
    }

    func isAuthorized() async -> Bool {
        await localNotificationClient.isAuthorized()
    }

    // MARK: Private

    private static let logger = Logger(subsystem: "com.nexters.hytime.gitit", category: "NotificationAuthorizationGatewayAdapter")

}
