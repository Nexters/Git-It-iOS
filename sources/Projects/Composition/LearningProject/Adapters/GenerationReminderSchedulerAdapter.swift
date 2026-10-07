import DomainLearningProject
import Foundation
import InfrastructureLocalNotification

// MARK: - GenerationReminderSchedulerAdapter

struct GenerationReminderSchedulerAdapter: GenerationReminderScheduler {

    // MARK: Lifecycle

    init(
        localNotificationClient: any NotificationAuthorizationClient,
        title: String,
        body: String,
    ) {
        self.localNotificationClient = localNotificationClient
        self.title = title
        self.body = body
    }

    // MARK: Internal

    func isAuthorized() async -> Bool {
        await localNotificationClient.isAuthorized()
    }

    func schedule(
        identifier: String,
        at date: Date,
    ) async {
        localNotificationClient.schedule(
            LocalNotificationRequest(
                identifier: identifier,
                title: title,
                body: body,
            ),
            at: date,
        )
    }

    // MARK: Private

    private let localNotificationClient: any NotificationAuthorizationClient
    private let title: String
    private let body: String

}
