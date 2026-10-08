import DataNotification
import DomainUseCaseDependency
import DomainUseCaseInterface

// MARK: - NotificationAuthorizationAdapter

public struct NotificationAuthorizationAdapter: NotificationAuthorization {

    // MARK: Lifecycle

    public init(permissionRequester: any NotificationPermissionRequester) {
        self.permissionRequester = permissionRequester
    }

    // MARK: Public

    public func status() async -> NotificationAuthorizationStatus {
        switch await permissionRequester.authorizationSetting() {
        case .notDetermined: .notDetermined
        case .authorized: .authorized
        case .denied: .denied
        }
    }

    public func requestAuthorization() async -> NotificationAuthorizationStatus {
        switch await permissionRequester.requestAuthorization() {
        case .authorized: .authorized
        case .declined,
             .previouslyDenied: .denied
        }
    }

    // MARK: Private

    private let permissionRequester: any NotificationPermissionRequester

}
