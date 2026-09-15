import DomainLearningProject
import Foundation
import InfrastructureLocalNotification

// MARK: - GenerationReminderAssembly

public struct GenerationReminderAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        localNotificationClient: any NotificationAuthorizationClient = LocalNotificationAuthorizationClient(),
        pendingReminderCoding: PendingGenerationReminderCoding? = SharedSessionLayout.makeSharedDefaults()
            .map(PendingGenerationReminderCoding.init(userDefaults:)),
    ) {
        let coordinator = GenerationCompletionReminderCoordinator(
            localNotificationClient: localNotificationClient,
            pendingReminderCoding: pendingReminderCoding,
        )
        self.coordinator = coordinator
        requestGenerationReminder = RequestGenerationReminder(
            authorizationGateway: NotificationAuthorizationGatewayAdapter(localNotificationClient: localNotificationClient),
            reminderRegistry: GenerationReminderRegistryAdapter(coordinator: coordinator),
        )
        startObservingGenerationState = { trackGeneration in
            await coordinator.start(trackGeneration: trackGeneration)
        }
    }

    // MARK: Public

    public let requestGenerationReminder: any RequestGenerationReminderUseCase
    public let startObservingGenerationState: @Sendable (any TrackGenerationUseCase) async -> Void

    // MARK: Internal

    let coordinator: GenerationCompletionReminderCoordinator

}
