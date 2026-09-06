import DomainLearningProject
import Foundation
import InfrastructureLocalNotification

// MARK: - GenerationReminderAssembly

public struct GenerationReminderAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        learningProject: LearningProjectAssembly,
        localNotificationClient: any NotificationAuthorizationClient = LocalNotificationAuthorizationClient(),
        pendingReminderCoding: PendingGenerationReminderCoding? = SharedSessionLayout.makeSharedDefaults()
            .map(PendingGenerationReminderCoding.init(userDefaults:)),
    ) {
        let coordinator = GenerationCompletionReminderCoordinator(
            localNotificationClient: localNotificationClient,
            progressRepository: learningProject.generationProgressRepository,
            pendingReminderCoding: pendingReminderCoding,
        )
        self.coordinator = coordinator
        requestGenerationReminder = RequestGenerationReminder(
            authorizationGateway: NotificationAuthorizationGatewayAdapter(localNotificationClient: localNotificationClient),
            reminderRegistry: GenerationReminderRegistryAdapter(coordinator: coordinator),
        )
        startObservingGenerationOutcomes = { observeGenerationOutcomes in
            await coordinator.start(observeGenerationOutcomes: observeGenerationOutcomes)
        }
    }

    // MARK: Public

    public let requestGenerationReminder: any RequestGenerationReminderUseCase
    public let startObservingGenerationOutcomes: @Sendable (any ObserveGenerationOutcomesUseCase) async -> Void

    // MARK: Internal

    let coordinator: GenerationCompletionReminderCoordinator

}
