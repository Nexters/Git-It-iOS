import DataLearningProject
import DomainLearningProject
import Foundation
import InfrastructureLocalNotification
import InfrastructureStorage

// MARK: - GenerationReminderAssembly

public struct GenerationReminderAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        reminderTitle: String,
        reminderBody: String,
        localNotificationClient: any NotificationAuthorizationClient = LocalNotificationAuthorizationClient(),
        pendingReminderCoding: PendingGenerationReminderCoding? = AppGroupUserDefaults.makeShared()
            .map(PendingGenerationReminderCoding.init(userDefaults:)),
    ) {
        let scheduleGenerationReminder = ScheduleGenerationReminder(
            scheduler: GenerationReminderSchedulerAdapter(
                localNotificationClient: localNotificationClient,
                title: reminderTitle,
                body: reminderBody,
            ),
            pendingReminderStore: pendingReminderCoding.map(PendingGenerationReminderStoreAdapter.init(coding:)),
        )
        self.scheduleGenerationReminder = scheduleGenerationReminder
        requestGenerationReminder = RequestGenerationReminder(
            authorizationGateway: NotificationAuthorizationGatewayAdapter(localNotificationClient: localNotificationClient),
            reminderRegistry: scheduleGenerationReminder,
        )
        startObservingGenerationState = { trackGeneration in
            await scheduleGenerationReminder.start(trackGeneration: trackGeneration)
        }
    }

    // MARK: Public

    public let requestGenerationReminder: any RequestGenerationReminderUseCase
    public let startObservingGenerationState: @Sendable (any TrackGenerationUseCase) async -> Void

    // MARK: Internal

    let scheduleGenerationReminder: ScheduleGenerationReminder

}
