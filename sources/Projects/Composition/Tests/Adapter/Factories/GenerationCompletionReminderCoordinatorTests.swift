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
    func `완료 결과는 즉시 발송이 아니라 준비 완료 시각으로 예약된다`() async {
        let requestedAt = Date(timeIntervalSince1970: 1_000)
        let localNotificationClient = StubLocalNotificationClient(isAuthorizedResult: true)
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let coordinator = makeCoordinator(
            localNotificationClient: localNotificationClient,
            progress: GenerationProgress(projectID: "project-1", requestedAt: requestedAt),
        )

        await emitCompleted(projectID: "project-1", coordinator: coordinator, outcomes: observeGenerationOutcomes)

        #expect(localNotificationClient.presentedIdentifiers().isEmpty)
        #expect(
            localNotificationClient.scheduled() == [
                StubLocalNotificationClient.Scheduled(
                    identifier: "generation-completed-project-1",
                    date: requestedAt.addingTimeInterval(300),
                )
            ]
        )
    }

    @Test
    func `준비 완료 시각이 이미 지났으면 지난 시각으로 예약해 즉시 발송된다`() async {
        let requestedAt = Date(timeIntervalSince1970: 0)
        let localNotificationClient = StubLocalNotificationClient(isAuthorizedResult: true)
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let coordinator = makeCoordinator(
            localNotificationClient: localNotificationClient,
            progress: GenerationProgress(projectID: "project-1", requestedAt: requestedAt),
        )

        await emitCompleted(projectID: "project-1", coordinator: coordinator, outcomes: observeGenerationOutcomes)

        let scheduled = localNotificationClient.scheduled()
        #expect(scheduled.count == 1)
        #expect(scheduled.first?.date ?? Date.distantFuture < Date())
    }

    @Test
    func `보존된 진행 상태가 없으면 최소 대기 없이 지금 시각으로 예약한다`() async {
        let localNotificationClient = StubLocalNotificationClient(isAuthorizedResult: true)
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let coordinator = makeCoordinator(localNotificationClient: localNotificationClient, progress: nil)

        let before = Date()
        await emitCompleted(projectID: "project-1", coordinator: coordinator, outcomes: observeGenerationOutcomes)

        let scheduled = localNotificationClient.scheduled()
        #expect(scheduled.count == 1)
        #expect((scheduled.first?.date ?? Date.distantPast) >= before)
    }

    @Test
    func `권한이 허용되지 않으면 예약도 발송도 하지 않는다`() async {
        let localNotificationClient = StubLocalNotificationClient(isAuthorizedResult: false)
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let coordinator = makeCoordinator(
            localNotificationClient: localNotificationClient,
            progress: GenerationProgress(projectID: "project-1", requestedAt: Date(timeIntervalSince1970: 1_000)),
        )

        await emitCompleted(projectID: "project-1", coordinator: coordinator, outcomes: observeGenerationOutcomes)

        #expect(localNotificationClient.scheduled().isEmpty)
        #expect(localNotificationClient.presentedIdentifiers().isEmpty)
    }

    @Test
    func `등록하지 않은 projectID의 completed 이벤트는 무시된다`() async {
        let localNotificationClient = StubLocalNotificationClient(isAuthorizedResult: true)
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let coordinator = makeCoordinator(
            localNotificationClient: localNotificationClient,
            progress: GenerationProgress(projectID: "unregistered", requestedAt: Date(timeIntervalSince1970: 1_000)),
        )

        await coordinator.start(observeGenerationOutcomes: observeGenerationOutcomes)
        await observeGenerationOutcomes.emit(GenerationOutcome(projectID: "unregistered", status: .completed))
        await observeGenerationOutcomes.finish()
        await coordinator.waitUntilObservationFinished()

        #expect(localNotificationClient.scheduled().isEmpty)
    }

    @Test
    func `등록된 projectID의 failed 이벤트는 예약 없이 등록 집합에서 제거만 한다`() async {
        let localNotificationClient = StubLocalNotificationClient(isAuthorizedResult: true)
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let coordinator = makeCoordinator(
            localNotificationClient: localNotificationClient,
            progress: GenerationProgress(projectID: "project-1", requestedAt: Date(timeIntervalSince1970: 1_000)),
        )

        await coordinator.register(projectID: "project-1")
        await coordinator.start(observeGenerationOutcomes: observeGenerationOutcomes)
        await observeGenerationOutcomes.emit(GenerationOutcome(projectID: "project-1", status: .failed))
        await observeGenerationOutcomes.finish()
        await coordinator.waitUntilObservationFinished()

        #expect(localNotificationClient.scheduled().isEmpty)
        #expect(localNotificationClient.presentedIdentifiers().isEmpty)
    }

    @Test
    func `start가 반환한 시점에 생성 결과 구독이 이미 확립돼 있다`() async {
        let localNotificationClient = StubLocalNotificationClient(isAuthorizedResult: true)
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let coordinator = makeCoordinator(
            localNotificationClient: localNotificationClient,
            progress: GenerationProgress(projectID: "project-1", requestedAt: Date(timeIntervalSince1970: 1_000)),
        )

        await coordinator.register(projectID: "project-1")
        await coordinator.start(observeGenerationOutcomes: observeGenerationOutcomes)

        #expect(await observeGenerationOutcomes.hasEstablishedSubscription())

        await observeGenerationOutcomes.emit(GenerationOutcome(projectID: "project-1", status: .completed))
        await observeGenerationOutcomes.finish()
        await coordinator.waitUntilObservationFinished()

        #expect(localNotificationClient.scheduled().count == 1)
    }

    @Test
    func `같은 projectID에 completed 이벤트가 두 번 도착해도 예약은 1회뿐이다`() async {
        let localNotificationClient = StubLocalNotificationClient(isAuthorizedResult: true)
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let coordinator = makeCoordinator(
            localNotificationClient: localNotificationClient,
            progress: GenerationProgress(projectID: "project-1", requestedAt: Date(timeIntervalSince1970: 1_000)),
        )

        await coordinator.register(projectID: "project-1")
        await coordinator.start(observeGenerationOutcomes: observeGenerationOutcomes)
        await observeGenerationOutcomes.emit(GenerationOutcome(projectID: "project-1", status: .completed))
        await observeGenerationOutcomes.emit(GenerationOutcome(projectID: "project-1", status: .completed))
        await observeGenerationOutcomes.finish()
        await coordinator.waitUntilObservationFinished()

        #expect(localNotificationClient.scheduled().map(\.identifier) == ["generation-completed-project-1"])
    }

    // MARK: Private

    private func makeCoordinator(
        localNotificationClient: StubLocalNotificationClient,
        progress: GenerationProgress?,
    ) -> GenerationCompletionReminderCoordinator {
        GenerationCompletionReminderCoordinator(
            localNotificationClient: localNotificationClient,
            progressRepository: StubGenerationProgressRepository(stored: progress),
            waitPolicy: GenerationWaitPolicy(minimumWait: 300, retentionLimit: 3_600),
        )
    }

    private func emitCompleted(
        projectID: String,
        coordinator: GenerationCompletionReminderCoordinator,
        outcomes: StubObserveGenerationOutcomesUseCase,
    ) async {
        await coordinator.register(projectID: projectID)
        await coordinator.start(observeGenerationOutcomes: outcomes)
        await outcomes.emit(GenerationOutcome(projectID: projectID, status: .completed))
        await outcomes.finish()
        await coordinator.waitUntilObservationFinished()
    }

}

// MARK: - StubObserveGenerationOutcomesUseCase

private actor StubObserveGenerationOutcomesUseCase: ObserveGenerationOutcomesUseCase {

    // MARK: Internal

    func callAsFunction() async -> AsyncStream<GenerationOutcome> {
        let (stream, continuation) = AsyncStream<GenerationOutcome>.makeStream()
        self.continuation = continuation
        return stream
    }

    func emit(_ outcome: GenerationOutcome) {
        continuation?.yield(outcome)
    }

    func finish() {
        continuation?.finish()
    }

    func hasEstablishedSubscription() -> Bool {
        continuation != nil
    }

    // MARK: Private

    private var continuation: AsyncStream<GenerationOutcome>.Continuation?

}

// MARK: - StubGenerationProgressRepository

private actor StubGenerationProgressRepository: GenerationProgressRepository {

    // MARK: Lifecycle

    init(stored: GenerationProgress?) {
        self.stored = stored
    }

    // MARK: Internal

    func load() async -> GenerationProgress? {
        stored
    }

    func save(_ progress: GenerationProgress) async {
        stored = progress
    }

    func clear() async {
        stored = nil
    }

    // MARK: Private

    private var stored: GenerationProgress?

}

// MARK: - StubLocalNotificationClient

private final class StubLocalNotificationClient: LocalNotificationClient, Sendable {

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

    func requestAuthorization() async -> LocalNotificationAuthorizationOutcome {
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
