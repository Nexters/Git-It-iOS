import Foundation

// MARK: - NotificationPermissionRequester

public protocol NotificationPermissionRequester: Sendable {

    func requestAuthorization() async -> NotificationPermissionRequestResult

    func authorizationSetting() async -> NotificationPermissionSetting

}
