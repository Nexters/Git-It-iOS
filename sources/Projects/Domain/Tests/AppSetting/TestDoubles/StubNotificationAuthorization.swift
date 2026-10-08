import DomainUseCaseDependency
@testable import DomainUseCaseInterface

struct StubNotificationAuthorization: NotificationAuthorization {

    // MARK: Internal

    let currentStatus: NotificationAuthorizationStatus
    let requestedStatus: NotificationAuthorizationStatus

    func status() async -> NotificationAuthorizationStatus {
        currentStatus
    }

    func requestAuthorization() async -> NotificationAuthorizationStatus {
        requestedStatus
    }

}
