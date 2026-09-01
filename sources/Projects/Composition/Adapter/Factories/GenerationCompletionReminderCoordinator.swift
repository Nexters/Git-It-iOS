import DomainLearningProject
import InfrastructurePushMessaging
import os

// MARK: - GenerationCompletionReminderCoordinator

actor GenerationCompletionReminderCoordinator {

    // MARK: Lifecycle

    init(localNotificationClient: any LocalNotificationClient) {
        self.localNotificationClient = localNotificationClient
    }

    // MARK: Internal

    func register(projectID: String) {
        registeredProjectIDs.insert(projectID)
        Self.logger.debug("리마인드 대상 등록: projectID=\(projectID, privacy: .public)")
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

    private static let logger = Logger(subsystem: "com.nexters.hytime.gitit", category: "GenerationCompletionReminderCoordinator")

    private let localNotificationClient: any LocalNotificationClient
    private var registeredProjectIDs: Set<String> = []
    private var observationTask: Task<Void, Never>?

    private func handle(_ outcome: LearningProjectGenerationOutcome) async {
        Self.logger.debug("생성 결과 수신: projectID=\(outcome.projectID, privacy: .public) status=\(String(describing: outcome.status), privacy: .public)")

        guard registeredProjectIDs.remove(outcome.projectID) != nil else {
            Self.logger.debug("리마인드 미등록 프로젝트라 무시: projectID=\(outcome.projectID, privacy: .public)")
            return
        }
        guard outcome.status == .completed else {
            Self.logger.debug("완료가 아니므로 로컬 알림 미발송: projectID=\(outcome.projectID, privacy: .public)")
            return
        }
        guard await localNotificationClient.isAuthorized() else {
            Self.logger.debug("알림 권한 없어 로컬 알림 미발송: projectID=\(outcome.projectID, privacy: .public)")
            return
        }
        Self.logger.debug("로컬 알림 발송: projectID=\(outcome.projectID, privacy: .public)")
        localNotificationClient.present(
            LocalNotificationRequest(
                identifier: "generation-completed-\(outcome.projectID)",
                title: "세트 생성 완료",
                body: "학습 세트 생성이 완료됐어요. 지금 확인해보세요.",
            )
        )
    }

}
