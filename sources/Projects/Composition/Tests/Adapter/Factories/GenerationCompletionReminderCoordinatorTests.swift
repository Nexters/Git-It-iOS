import DomainLearningProject
import Foundation
import Synchronization
import Testing
@testable import CompositionAdapter
@testable import InfrastructureLocalNotification

// MARK: - GenerationCompletionReminderCoordinatorTests

@Suite("GenerationCompletionReminderCoordinator")
struct GenerationCompletionReminderCoordinatorTests {

    // MARK: Internal

    @Test
    func `완료 기록은 즉시 발송이 아니라 준비 완료 시각으로 예약된다`() async {
        let requestedAt = Date(timeIntervalSince1970: 1_000)
        let localNotificationClient = StubNotificationAuthorizationClient(isAuthorizedResult: true)
        let trackGeneration = StubTrackGenerationUseCase()
        let coordinator = makeCoordinator(localNotificationClient: localNotificationClient)

        await emitFinished(
            projectID: "project-1",
            status: .completed,
            requestedAt: requestedAt,
            coordinator: coordinator,
            trackGeneration: trackGeneration,
        )

        #expect(localNotificationClient.presentedIdentifiers().isEmpty)
        #expect(
            localNotificationClient.scheduled() == [
                StubNotificationAuthorizationClient.Scheduled(
                    identifier: "generation-completed-project-1",
                    date: requestedAt.addingTimeInterval(300),
                )
            ]
        )
    }

    @Test
    func `준비 완료 시각이 이미 지났으면 지난 시각으로 예약해 즉시 발송된다`() async {
        let localNotificationClient = StubNotificationAuthorizationClient(isAuthorizedResult: true)
        let trackGeneration = StubTrackGenerationUseCase()
        let coordinator = makeCoordinator(localNotificationClient: localNotificationClient)

        await emitFinished(
            projectID: "project-1",
            status: .completed,
            requestedAt: Date(timeIntervalSince1970: 0),
            coordinator: coordinator,
            trackGeneration: trackGeneration,
        )

        let scheduled = localNotificationClient.scheduled()
        #expect(scheduled.count == 1)
        #expect(scheduled.first?.date ?? Date.distantFuture < Date())
    }

    @Test
    func `권한이 허용되지 않으면 예약도 발송도 하지 않는다`() async {
        let localNotificationClient = StubNotificationAuthorizationClient(isAuthorizedResult: false)
        let trackGeneration = StubTrackGenerationUseCase()
        let coordinator = makeCoordinator(localNotificationClient: localNotificationClient)

        await emitFinished(
            projectID: "project-1",
            status: .completed,
            requestedAt: Date(timeIntervalSince1970: 1_000),
            coordinator: coordinator,
            trackGeneration: trackGeneration,
        )

        #expect(localNotificationClient.scheduled().isEmpty)
        #expect(localNotificationClient.presentedIdentifiers().isEmpty)
    }

    @Test
    func `등록하지 않은 projectID의 완료 기록은 무시된다`() async {
        let localNotificationClient = StubNotificationAuthorizationClient(isAuthorizedResult: true)
        let trackGeneration = StubTrackGenerationUseCase()
        let coordinator = makeCoordinator(localNotificationClient: localNotificationClient)

        await coordinator.start(trackGeneration: trackGeneration)
        await trackGeneration.emit(
            Self.state(projectID: "unregistered", status: .completed, requestedAt: Date(timeIntervalSince1970: 1_000))
        )
        await trackGeneration.finish()
        await coordinator.waitUntilObservationFinished()

        #expect(localNotificationClient.scheduled().isEmpty)
    }

    @Test
    func `등록된 projectID의 실패 기록은 예약 없이 등록 집합에서 제거만 한다`() async {
        let localNotificationClient = StubNotificationAuthorizationClient(isAuthorizedResult: true)
        let trackGeneration = StubTrackGenerationUseCase()
        let coordinator = makeCoordinator(localNotificationClient: localNotificationClient)

        await emitFinished(
            projectID: "project-1",
            status: .failed,
            requestedAt: Date(timeIntervalSince1970: 1_000),
            coordinator: coordinator,
            trackGeneration: trackGeneration,
        )

        #expect(localNotificationClient.scheduled().isEmpty)
        #expect(localNotificationClient.presentedIdentifiers().isEmpty)
    }

    @Test
    func `start가 반환한 시점에 생성 상태 구독이 이미 확립돼 있다`() async {
        let localNotificationClient = StubNotificationAuthorizationClient(isAuthorizedResult: true)
        let trackGeneration = StubTrackGenerationUseCase()
        let coordinator = makeCoordinator(localNotificationClient: localNotificationClient)

        await coordinator.register(projectID: "project-1")
        await coordinator.start(trackGeneration: trackGeneration)

        #expect(await trackGeneration.hasEstablishedSubscription())

        await trackGeneration.emit(
            Self.state(projectID: "project-1", status: .completed, requestedAt: Date(timeIntervalSince1970: 1_000))
        )
        await trackGeneration.finish()
        await coordinator.waitUntilObservationFinished()

        #expect(localNotificationClient.scheduled().count == 1)
    }

    @Test
    func `같은 완료 기록이 두 스냅샷에 연속으로 담겨도 예약은 1회뿐이다`() async {
        let localNotificationClient = StubNotificationAuthorizationClient(isAuthorizedResult: true)
        let trackGeneration = StubTrackGenerationUseCase()
        let coordinator = makeCoordinator(localNotificationClient: localNotificationClient)
        let finished = Self.state(
            projectID: "project-1",
            status: .completed,
            requestedAt: Date(timeIntervalSince1970: 1_000),
        )

        await coordinator.register(projectID: "project-1")
        await coordinator.start(trackGeneration: trackGeneration)
        await trackGeneration.emit(finished)
        await trackGeneration.emit(finished)
        await trackGeneration.finish()
        await coordinator.waitUntilObservationFinished()

        #expect(localNotificationClient.scheduled().map(\.identifier) == ["generation-completed-project-1"])
    }

    // MARK: Private

    private static func state(
        projectID: String,
        status: GenerationRecord.Status,
        requestedAt: Date,
    ) -> GenerationState {
        GenerationState(records: [
            GenerationRecord(
                githubRepoURL: "https://github.com/owner/\(projectID)",
                projectID: projectID,
                requestedAt: requestedAt,
                status: status,
                finishedAt: requestedAt,
            ),
        ])
    }

    private func makeCoordinator(
        localNotificationClient: StubNotificationAuthorizationClient
    ) -> GenerationCompletionReminderCoordinator {
        GenerationCompletionReminderCoordinator(
            localNotificationClient: localNotificationClient,
            waitPolicy: GenerationWaitPolicy(minimumWait: 300, retentionLimit: 3_600),
        )
    }

    private func emitFinished(
        projectID: String,
        status: GenerationRecord.Status,
        requestedAt: Date,
        coordinator: GenerationCompletionReminderCoordinator,
        trackGeneration: StubTrackGenerationUseCase,
    ) async {
        await coordinator.register(projectID: projectID)
        await coordinator.start(trackGeneration: trackGeneration)
        await trackGeneration.emit(Self.state(projectID: projectID, status: status, requestedAt: requestedAt))
        await trackGeneration.finish()
        await coordinator.waitUntilObservationFinished()
    }

}

// MARK: - StubTrackGenerationUseCase

private actor StubTrackGenerationUseCase: TrackGenerationUseCase {

    // MARK: Internal

    func begin(
        githubRepoURL _: String,
        requestedAt _: Date,
    ) async -> Bool {
        true
    }

    func attachProjectID(
        _: String,
        toGithubRepoURL _: String,
    ) async { }

    func end(githubRepoURL _: String) async { }
    func end(projectID _: String) async { }
    func current() async -> GenerationState {
        GenerationState()
    }

    func states() async -> AsyncStream<GenerationState> {
        let (stream, continuation) = AsyncStream<GenerationState>.makeStream()
        self.continuation = continuation
        return stream
    }

    func emit(_ state: GenerationState) {
        continuation?.yield(state)
    }

    func finish() {
        continuation?.finish()
    }

    func hasEstablishedSubscription() -> Bool {
        continuation != nil
    }

    // MARK: Private

    private var continuation: AsyncStream<GenerationState>.Continuation?

}

// MARK: - StubNotificationAuthorizationClient

private final class StubNotificationAuthorizationClient: NotificationAuthorizationClient, Sendable {

    // MARK: Lifecycle

    init(isAuthorizedResult: Bool) {
        self.isAuthorizedResult = isAuthorizedResult
        state = Mutex(State())
    }

    // MARK: Internal

    struct Scheduled: Equatable, Sendable {
        let identifier: String
        let date: Date
    }

    func requestAuthorization() async -> NotificationAuthorizationStatus {
        .authorized
    }

    func isAuthorized() async -> Bool {
        isAuthorizedResult
    }

    func present(_ request: LocalNotificationRequest) {
        state.withLock { $0.presented.append(request.identifier) }
    }

    func schedule(
        _ request: LocalNotificationRequest,
        at date: Date,
    ) {
        state.withLock { $0.scheduled.append(Scheduled(identifier: request.identifier, date: date)) }
    }

    func cancel(identifier: String) {
        state.withLock { $0.scheduled.removeAll { $0.identifier == identifier } }
    }

    func presentedIdentifiers() -> [String] {
        state.withLock(\.presented)
    }

    func scheduled() -> [Scheduled] {
        state.withLock(\.scheduled)
    }

    // MARK: Private

    private struct State {
        var presented = [String]()
        var scheduled = [Scheduled]()
    }

    private let isAuthorizedResult: Bool
    private let state: Mutex<State>

}
