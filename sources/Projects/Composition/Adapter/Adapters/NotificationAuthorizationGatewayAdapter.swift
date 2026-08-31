import DomainLearningProject
import InfrastructurePushMessaging

// MARK: - NotificationAuthorizationGatewayAdapter

struct NotificationAuthorizationGatewayAdapter: NotificationAuthorizationGateway {

    let localNotificationClient: any LocalNotificationClient

    func requestAuthorization() async -> NotificationAuthorizationOutcome {
        switch await localNotificationClient.requestAuthorization() {
        case .authorized: .authorized
        case .declined: .declined
        case .previouslyDenied: .previouslyDenied
        }
    }

    func isAuthorized() async -> Bool {
        await localNotificationClient.isAuthorized()
    }

}
