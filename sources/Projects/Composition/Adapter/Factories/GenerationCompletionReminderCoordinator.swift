import DomainLearningProject
import Foundation
import InfrastructureLocalNotification
import os

// MARK: - GenerationCompletionReminderCoordinator

actor GenerationCompletionReminderCoordinator {

    // MARK: Lifecycle

    init(
        localNotificationClient: any NotificationAuthorizationClient,
        progressRepository: any GenerationProgressRepository,
        pendingReminderCoding: PendingGenerationReminderCoding? = nil,
        waitPolicy: GenerationWaitPolicy = .standard,
    ) {
        self.localNotificationClient = localNotificationClient
        self.progressRepository = progressRepository
        self.pendingReminderCoding = pendingReminderCoding
        self.waitPolicy = waitPolicy
    }

    // MARK: Internal

    func register(projectID: String) {
        registeredProjectIDs.insert(projectID)
        Self.logger.debug("리마인드 대상 등록: projectID=\(projectID, privacy: .public)")
    }

    func absorbPendingReminders() async {
        guard let pendingReminderCoding else { return }
        for projectID in await pendingReminderCoding.drainProjectIDs() {
            register(projectID: projectID)
        }
    }

    func start(observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase) async {
        await absorbPendingReminders()
        let outcomes = await observeGenerationOutcomes()
        observationTask = Task {
            for await outcome in outcomes {
                await self.handle(outcome)
            }
        }
    }

    func waitUntilObservationFinished() async {
        await observationTask?.value
    }

    // MARK: Private

    private static let logger = Logger(subsystem: "com.nexters.hytime.gitit", category: "GenerationCompletionReminderCoordinator")

    private let localNotificationClient: any NotificationAuthorizationClient
    private let progressRepository: any GenerationProgressRepository
    private let pendingReminderCoding: PendingGenerationReminderCoding?
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

    private func readyDate(for projectID: String) async -> Date {
        guard
            let progress = await progressRepository.load(),
            progress.projectID == projectID
        else { return Date() }
        return waitPolicy.readyDate(for: progress)
    }

}
