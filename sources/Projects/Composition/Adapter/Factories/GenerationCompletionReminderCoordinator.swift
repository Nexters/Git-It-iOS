import DomainLearningProject
import Foundation
import InfrastructureLocalNotification
import os

// MARK: - GenerationCompletionReminderCoordinator

actor GenerationCompletionReminderCoordinator {

    // MARK: Lifecycle

    init(
        localNotificationClient: any NotificationAuthorizationClient,
        pendingReminderCoding: PendingGenerationReminderCoding? = nil,
        waitPolicy: GenerationWaitPolicy = .standard,
    ) {
        self.localNotificationClient = localNotificationClient
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

    func start(trackGeneration: any TrackGenerationUseCase) async {
        await absorbPendingReminders()
        let states = await trackGeneration.states()
        observationTask = Task {
            for await state in states {
                await self.handle(state)
            }
        }
    }

    func waitUntilObservationFinished() async {
        await observationTask?.value
    }

    // MARK: Private

    private static let logger = Logger(subsystem: "com.nexters.hytime.gitit", category: "GenerationCompletionReminderCoordinator")

    private let localNotificationClient: any NotificationAuthorizationClient
    private let pendingReminderCoding: PendingGenerationReminderCoding?
    private let waitPolicy: GenerationWaitPolicy
    private var registeredProjectIDs = Set<String>()
    private var observationTask: Task<Void, Never>?

    private static func notificationIdentifier(projectID: String) -> String {
        "generation-completed-\(projectID)"
    }

    private func handle(_ state: GenerationState) async {
        for record in state.records where record.status != .inProgress {
            await handle(record)
        }
    }

    private func handle(_ record: GenerationRecord) async {
        guard let projectID = record.projectID else { return }
        Self.logger
            .debug(
                "생성 결과 수신: projectID=\(projectID, privacy: .public) status=\(String(describing: record.status), privacy: .public)"
            )

        guard registeredProjectIDs.remove(projectID) != nil else {
            Self.logger.debug("리마인드 미등록 프로젝트라 무시: projectID=\(projectID, privacy: .public)")
            return
        }
        guard record.status == .completed else {
            Self.logger.debug("완료가 아니므로 로컬 알림 미발송: projectID=\(projectID, privacy: .public)")
            return
        }
        guard await localNotificationClient.isAuthorized() else {
            Self.logger.debug("알림 권한 없어 로컬 알림 미발송: projectID=\(projectID, privacy: .public)")
            return
        }

        let readyDate = waitPolicy.readyDate(for: record)
        Self.logger.debug(
            "로컬 알림 예약: projectID=\(projectID, privacy: .public) readyDate=\(String(describing: readyDate), privacy: .public)"
        )
        localNotificationClient.schedule(
            LocalNotificationRequest(
                identifier: Self.notificationIdentifier(projectID: projectID),
                title: "세트 생성 완료",
                body: "학습 세트 생성이 완료됐어요. 지금 확인해보세요.",
            ),
            at: readyDate,
        )
    }

}
