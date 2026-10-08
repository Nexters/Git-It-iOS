import Foundation
import InfrastructureLocalNotification
import Testing

@testable import DataNotification

// MARK: - NotificationPermissionClientTests

@Suite("NotificationPermissionClient")
struct NotificationPermissionClientTests {

    @Test(arguments: [
        (NotificationAuthorizationStatus.authorized, NotificationPermissionRequestResult.authorized),
        (.declined, .declined),
        (.previouslyDenied, .previouslyDenied),
    ])
    func `권한 요청 결과를 알림 권한 상태로 변환한다`(
        status: NotificationAuthorizationStatus,
        expected: NotificationPermissionRequestResult,
    ) async {
        let authorizationClient = SpyNotificationAuthorizationClient(status: status)
        let client = NotificationPermissionClient(authorizationClient: authorizationClient)

        let result = await client.requestAuthorization()

        #expect(result == expected)
        #expect(authorizationClient.authorizationRequestCount == 1)
    }

    @Test(arguments: [
        (NotificationAuthorizationSetting.notDetermined, NotificationPermissionSetting.notDetermined),
        (.authorized, .authorized),
        (.denied, .denied),
    ])
    func `권한을 요청하지 않고 현재 알림 권한 설정을 변환한다`(
        setting: NotificationAuthorizationSetting,
        expected: NotificationPermissionSetting,
    ) async {
        let authorizationClient = SpyNotificationAuthorizationClient(setting: setting)
        let client = NotificationPermissionClient(authorizationClient: authorizationClient)

        let result = await client.authorizationSetting()

        #expect(result == expected)
        #expect(authorizationClient.authorizationRequestCount == 0)
    }

}
