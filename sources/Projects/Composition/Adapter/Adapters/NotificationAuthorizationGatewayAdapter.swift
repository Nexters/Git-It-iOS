import DomainLearningProject
import InfrastructurePushMessaging
import os

// MARK: - NotificationAuthorizationGatewayAdapter

struct NotificationAuthorizationGatewayAdapter: NotificationAuthorizationGateway {

    let localNotificationClient: any LocalNotificationClient

    func requestAuthorization() async -> NotificationAuthorizationOutcome {
        let outcome: NotificationAuthorizationOutcome = switch await localNotificationClient.requestAuthorization() {
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
