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
            pendingReminders: pendingReminderCoding.map(PendingGenerationRemindersAdapter.init(coding:)),
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

    public static func makePendingReminderEnqueue(sharedDefaults: UserDefaults?) -> @Sendable (String) async -> Void {
        let pendingReminderCoding = sharedDefaults.map(PendingGenerationReminderCoding.init(userDefaults:))
        return { projectID in
            await pendingReminderCoding?.append(projectID: projectID)
        }
    }

    // MARK: Internal

    let scheduleGenerationReminder: ScheduleGenerationReminder

}
