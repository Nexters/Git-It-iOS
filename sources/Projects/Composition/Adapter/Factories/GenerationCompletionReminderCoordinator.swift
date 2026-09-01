import DomainLearningProject
import Foundation
import InfrastructurePushMessaging
import os

// MARK: - GenerationCompletionReminderCoordinator

actor GenerationCompletionReminderCoordinator {

    // MARK: Lifecycle

    init(
        localNotificationClient: any LocalNotificationClient,
        progressRepository: any GenerationProgressRepository,
        waitPolicy: GenerationWaitPolicy = .standard,
    ) {
        self.localNotificationClient = localNotificationClient
        self.progressRepository = progressRepository
        self.waitPolicy = waitPolicy
    }

    // MARK: Internal

    func register(projectID: String) {
        registeredProjectIDs.insert(projectID)
        Self.logger.debug("리마인드 대상 등록: projectID=\(projectID, privacy: .public)")
    }

    /// 스트림 확보를 마친 뒤 관찰 Task를 만든다. 따라서 이 함수가 반환한 시점에는 구독이
    /// 이미 확립돼 있고, 이후 도착하는 생성 결과를 놓치지 않는다.
    func start(observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase) async {
        let outcomes = await observeGenerationOutcomes()
        observationTask = Task {
            for await outcome in outcomes {
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
    private let progressRepository: any GenerationProgressRepository
    private let waitPolicy: GenerationWaitPolicy
    private var registeredProjectIDs = Set<String>()
    private var observationTask: Task<Void, Never>?

    private static func notificationIdentifier(projectID: String) -> String {
        "generation-completed-\(projectID)"
    }

    private func handle(_ outcome: GenerationOutcome) async {
        Self.logger
            .debug(
                "생성 결과 수신: projectID=\(outcome.projectID, privacy: .public) status=\(String(describing: outcome.status), privacy: .public)"
            )

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
        // 보존된 진행 상태의 요청 시각으로 준비 완료 시각을 계산해 예약한다. 이미 지난
        // 시각이면 예약 API가 추가 지연 없이 즉시 발송한다.
        let readyDate = await readyDate(for: outcome.projectID)
        Self.logger.debug(
            "로컬 알림 예약: projectID=\(outcome.projectID, privacy: .public) readyDate=\(String(describing: readyDate), privacy: .public)"
        )
        localNotificationClient.schedule(
            LocalNotificationRequest(
                identifier: Self.notificationIdentifier(projectID: outcome.projectID),
                title: "세트 생성 완료",
                body: "학습 세트 생성이 완료됐어요. 지금 확인해보세요.",
            ),
            at: readyDate,
        )
    }

    /// 보존된 진행 상태가 같은 프로젝트를 가리킬 때만 최소 대기 시간을 적용한다. 상태가
    /// 없거나 다른 프로젝트면 지금 시각을 반환해 즉시 발송으로 떨어진다.
    private func readyDate(for projectID: String) async -> Date {
        guard
            let progress = await progressRepository.load(),
            progress.projectID == projectID
        else { return Date() }
        return waitPolicy.readyDate(for: progress)
    }

}
