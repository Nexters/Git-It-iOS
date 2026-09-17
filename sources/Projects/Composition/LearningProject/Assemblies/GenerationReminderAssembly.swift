import DataNotification
import DomainLearningProject
import Foundation

// MARK: - GenerationReminderAssembly

public struct GenerationReminderAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        reminderTitle: String,
        reminderBody: String,
        reminderNotifier: (any LocalReminderNotifier)? = nil,
        pendingGenerations: (any PendingGenerationRepository)? = nil,
    ) {
        let reminderNotifier = reminderNotifier ?? NotificationFactory.localReminderNotifier()
        let scheduleGenerationReminder = ScheduleGenerationReminder(
            scheduler: GenerationReminderSchedulerAdapter(
                reminderNotifier: reminderNotifier,
                title: reminderTitle,
                body: reminderBody,
            ),
            pendingGenerations: pendingGenerations,
        )
        self.scheduleGenerationReminder = scheduleGenerationReminder
        requestGenerationReminder = RequestGenerationReminder(
            notificationAuthorization: NotificationAuthorizationAdapter(reminderNotifier: reminderNotifier),
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
