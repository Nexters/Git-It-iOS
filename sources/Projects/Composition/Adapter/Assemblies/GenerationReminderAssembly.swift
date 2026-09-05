import DomainLearningProject
import Foundation
import InfrastructureLocalNotification

// MARK: - GenerationReminderAssembly

/// 퀴즈 생성 완료 리마인더 조립을 소유한다. 리마인더 등록과 생성 결과 관찰 시작만
/// 공개하고, 조정자와 게이트웨이 구현은 이 패키지 내부에 둔다.
public struct GenerationReminderAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        learningProject: LearningProjectAssembly,
        localNotificationClient: any LocalNotificationClient = UserNotificationCenterLocalClient(),
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
