import Foundation
import InfrastructurePushMessaging
import os

// MARK: - DeliveredRemoteMessageClient

struct DeliveredRemoteMessageClient: DeliveredRemoteMessageReader {

    // MARK: Lifecycle

    init(notificationClient: any DeliveredNotificationClient) {
        self.notificationClient = notificationClient
    }

    // MARK: Internal

    func deliveredMessages() async -> [DeliveredRemoteMessage] {
        let messages = await notificationClient.deliveredRemoteNotifications().map { notification in
            DeliveredRemoteMessage(
                payload: notification.payload,
                deliveredAt: notification.deliveredAt,
            )
        }
        Self.logger.debug("알림 센터의 원격 알림 \(messages.count, privacy: .public)개를 읽었습니다.")
        return messages
    }

    // MARK: Private

    private static let logger = Logger(
        subsystem: "com.nexters.hytime.gitit",
        category: "DeliveredRemoteMessageClient",
    )

    private let notificationClient: any DeliveredNotificationClient

}
