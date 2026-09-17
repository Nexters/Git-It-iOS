import DomainLearningProject
import Foundation
import InfrastructureLocalNotification

// MARK: - GenerationReminderAssembly

public struct GenerationReminderAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        reminderTitle: String,
        reminderBody: String,
        localNotificationClient: any NotificationAuthorizationClient = LocalNotificationAuthorizationClient(),
        pendingGenerations: (any PendingGenerationRepository)? = nil,
    ) {
        let scheduleGenerationReminder = ScheduleGenerationReminder(
            scheduler: GenerationReminderSchedulerAdapter(
                localNotificationClient: localNotificationClient,
                title: reminderTitle,
                body: reminderBody,
            ),
            pendingGenerations: pendingGenerations,
        )
        self.scheduleGenerationReminder = scheduleGenerationReminder
        requestGenerationReminder = RequestGenerationReminder(
            notificationAuthorization: NotificationAuthorizationAdapter(localNotificationClient: localNotificationClient),
            reminderRegistration: scheduleGenerationReminder,
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
