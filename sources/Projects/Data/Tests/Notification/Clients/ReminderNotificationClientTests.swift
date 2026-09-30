import Foundation
import InfrastructureLocalNotification
import Testing

@testable import DataNotification

// MARK: - ReminderNotificationClientTests

@Suite("ReminderNotificationClient")
struct ReminderNotificationClientTests {

    @Test(arguments: [
        (NotificationAuthorizationStatus.authorized, ReminderAuthorizationStatus.authorized),
        (.declined, .declined),
        (.previouslyDenied, .previouslyDenied),
    ])
    func `권한 요청 결과를 알림 권한 상태로 변환한다`(
        status: NotificationAuthorizationStatus,
        expected: ReminderAuthorizationStatus,
    ) async {
        let authorizationClient = SpyNotificationAuthorizationClient(status: status)
        let client = ReminderNotificationClient(authorizationClient: authorizationClient)

        let result = await client.requestAuthorization()

        #expect(result == expected)
        #expect(authorizationClient.authorizationRequestCount == 1)
    }

    @Test(arguments: [
        (NotificationAuthorizationSetting.notDetermined, ReminderAuthorizationSetting.notDetermined),
        (.authorized, .authorized),
        (.denied, .denied),
    ])
    func `권한을 요청하지 않고 현재 알림 권한 설정을 변환한다`(
        setting: NotificationAuthorizationSetting,
        expected: ReminderAuthorizationSetting,
    ) async {
        let authorizationClient = SpyNotificationAuthorizationClient(setting: setting)
        let client = ReminderNotificationClient(authorizationClient: authorizationClient)

        let result = await client.authorizationSetting()

        #expect(result == expected)
        #expect(authorizationClient.authorizationRequestCount == 0)
    }

}
