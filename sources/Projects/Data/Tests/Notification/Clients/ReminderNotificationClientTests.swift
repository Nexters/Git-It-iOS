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

    @Test(arguments: [true, false])
    func `권한 허용 여부를 그대로 전달한다`(isAuthorized: Bool) async {
        let client = ReminderNotificationClient(
            authorizationClient: SpyNotificationAuthorizationClient(isAuthorized: isAuthorized)
        )

        let result = await client.isAuthorized()

        #expect(result == isAuthorized)
    }

    @Test
    func `예약 요청의 식별자와 제목, 본문, 시각을 전달한다`() async {
        let authorizationClient = SpyNotificationAuthorizationClient()
        let client = ReminderNotificationClient(authorizationClient: authorizationClient)
        let date = Date(timeIntervalSince1970: 1_800_000_000)

        await client.schedule(
            ReminderNotification(identifier: "reminder-1", title: "생성 완료", body: "학습을 시작하세요"),
            at: date,
        )

        #expect(authorizationClient.scheduledRequests == [
            SpyNotificationAuthorizationClient.ScheduledRequest(
                request: LocalNotificationRequest(identifier: "reminder-1", title: "생성 완료", body: "학습을 시작하세요"),
                date: date,
            )
        ])
        #expect(authorizationClient.presentedRequests.isEmpty)
    }

    @Test
    func `취소 요청을 식별자와 함께 위임한다`() async {
        let authorizationClient = SpyNotificationAuthorizationClient()
        let client = ReminderNotificationClient(authorizationClient: authorizationClient)

        await client.cancel(identifier: "reminder-1")

        #expect(authorizationClient.cancelledIdentifiers == ["reminder-1"])
    }

}
