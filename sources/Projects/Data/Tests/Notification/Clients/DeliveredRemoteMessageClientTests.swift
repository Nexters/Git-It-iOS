import Foundation
import InfrastructurePushMessaging
import Testing

@testable import DataNotification

// MARK: - DeliveredRemoteMessageClientTests

@Suite("DeliveredRemoteMessageClient")
struct DeliveredRemoteMessageClientTests {

    @Test
    func `알림 센터의 원격 알림을 payload와 전달 시각 그대로 전달된 메시지로 바꾼다`() async {
        let deliveredAt = Date(timeIntervalSince1970: 1_000)
        let client = DeliveredRemoteMessageClient(
            notificationClient: StubDeliveredNotificationClient(notifications: [
                DeliveredRemoteNotification(
                    payload: ["projectId": "project-1", "status": "completed"],
                    deliveredAt: deliveredAt,
                )
            ])
        )

        let messages = await client.deliveredMessages()

        #expect(messages == [
            DeliveredRemoteMessage(
                payload: ["projectId": "project-1", "status": "completed"],
                deliveredAt: deliveredAt,
            )
        ])
    }

    @Test
    func `알림 센터가 비어 있으면 빈 목록을 반환한다`() async {
        let client = DeliveredRemoteMessageClient(
            notificationClient: StubDeliveredNotificationClient(notifications: [])
        )

        let messages = await client.deliveredMessages()

        #expect(messages.isEmpty)
    }

}
