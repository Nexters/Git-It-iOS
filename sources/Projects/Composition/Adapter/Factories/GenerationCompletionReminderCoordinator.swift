import DomainLearningProject
import InfrastructurePushMessaging

// MARK: - GenerationCompletionReminderCoordinator

actor GenerationCompletionReminderCoordinator {

    // MARK: Lifecycle

    init(localNotificationClient: any LocalNotificationClient) {
        self.localNotificationClient = localNotificationClient
    }

    // MARK: Internal

    func register(projectID: String) {
        registeredProjectIDs.insert(projectID)
    }

    func start(learningProjectOutcomes: any LearningProjectOutcomesUseCase) {
        observationTask = Task {
            for await outcome in await learningProjectOutcomes() {
                await self.handle(outcome)
            }
        }
    }

    /// 테스트에서 스트림 종료 후 관찰 Task가 모든 이벤트를 처리했는지 대기하기 위한 지원 함수다.
    func waitUntilObservationFinished() async {
        await observationTask?.value
    }

    // MARK: Private

    private let localNotificationClient: any LocalNotificationClient
    private var registeredProjectIDs: Set<String> = []
    private var observationTask: Task<Void, Never>?

    private func handle(_ outcome: LearningProjectGenerationOutcome) async {
        guard registeredProjectIDs.remove(outcome.projectID) != nil else { return }
        guard outcome.status == .completed else { return }
        guard await localNotificationClient.isAuthorized() else { return }
        localNotificationClient.presentGenerationCompletedNotification(projectID: outcome.projectID)
    }

}
