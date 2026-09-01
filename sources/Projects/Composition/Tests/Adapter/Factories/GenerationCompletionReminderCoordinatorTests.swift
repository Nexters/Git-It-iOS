import DomainLearningProject
import Synchronization
import Testing
@testable import CompositionAdapter
@testable import InfrastructurePushMessaging

// MARK: - GenerationCompletionReminderCoordinatorTests

@Suite("GenerationCompletionReminderCoordinator")
struct GenerationCompletionReminderCoordinatorTests {

    @Test
    func `등록된 projectID의 completed 이벤트는 권한이 허용되면 로컬 알림을 정확히 1회 발송한다`() async {
        let localNotificationClient = StubLocalNotificationClient(isAuthorizedResult: true)
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let coordinator = GenerationCompletionReminderCoordinator(localNotificationClient: localNotificationClient)

        await coordinator.register(projectID: "project-1")
        await coordinator.start(observeGenerationOutcomes: observeGenerationOutcomes)
        await observeGenerationOutcomes.emit(GenerationOutcome(projectID: "project-1", status: .completed))
        await observeGenerationOutcomes.finish()
        await coordinator.waitUntilObservationFinished()

        #expect(localNotificationClient.presentedProjectIDs() == ["generation-completed-project-1"])
    }

    @Test
    func `권한이 허용되지 않으면 로컬 알림을 발송하지 않는다`() async {
        let localNotificationClient = StubLocalNotificationClient(isAuthorizedResult: false)
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let coordinator = GenerationCompletionReminderCoordinator(localNotificationClient: localNotificationClient)

        await coordinator.register(projectID: "project-1")
        await coordinator.start(observeGenerationOutcomes: observeGenerationOutcomes)
        await observeGenerationOutcomes.emit(GenerationOutcome(projectID: "project-1", status: .completed))
        await observeGenerationOutcomes.finish()
        await coordinator.waitUntilObservationFinished()

        #expect(localNotificationClient.presentedProjectIDs().isEmpty)
    }

    @Test
    func `등록하지 않은 projectID의 completed 이벤트는 무시된다`() async {
        let localNotificationClient = StubLocalNotificationClient(isAuthorizedResult: true)
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let coordinator = GenerationCompletionReminderCoordinator(localNotificationClient: localNotificationClient)

        await coordinator.start(observeGenerationOutcomes: observeGenerationOutcomes)
        await observeGenerationOutcomes.emit(GenerationOutcome(projectID: "unregistered", status: .completed))
        await observeGenerationOutcomes.finish()
        await coordinator.waitUntilObservationFinished()

        #expect(localNotificationClient.presentedProjectIDs().isEmpty)
    }

    @Test
    func `등록된 projectID의 failed 이벤트는 발송 없이 등록 집합에서 제거만 한다`() async {
        let localNotificationClient = StubLocalNotificationClient(isAuthorizedResult: true)
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let coordinator = GenerationCompletionReminderCoordinator(localNotificationClient: localNotificationClient)

        await coordinator.register(projectID: "project-1")
        await coordinator.start(observeGenerationOutcomes: observeGenerationOutcomes)
        await observeGenerationOutcomes.emit(GenerationOutcome(projectID: "project-1", status: .failed))
        await observeGenerationOutcomes.finish()
        await coordinator.waitUntilObservationFinished()

        #expect(localNotificationClient.presentedProjectIDs().isEmpty)
    }

    @Test
    func `start가 반환한 시점에 생성 결과 구독이 이미 확립돼 있다`() async {
        let localNotificationClient = StubLocalNotificationClient(isAuthorizedResult: true)
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let coordinator = GenerationCompletionReminderCoordinator(localNotificationClient: localNotificationClient)

        await coordinator.register(projectID: "project-1")
        await coordinator.start(observeGenerationOutcomes: observeGenerationOutcomes)

        #expect(await observeGenerationOutcomes.hasEstablishedSubscription())

        // 확립 직후 도착한 결과도 유실되지 않는다.
        await observeGenerationOutcomes.emit(GenerationOutcome(projectID: "project-1", status: .completed))
        await observeGenerationOutcomes.finish()
        await coordinator.waitUntilObservationFinished()

        #expect(localNotificationClient.presentedProjectIDs() == ["generation-completed-project-1"])
    }

    @Test
    func `같은 projectID에 completed 이벤트가 두 번 도착해도 발송은 1회뿐이다`() async {
        let localNotificationClient = StubLocalNotificationClient(isAuthorizedResult: true)
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let coordinator = GenerationCompletionReminderCoordinator(localNotificationClient: localNotificationClient)

        await coordinator.register(projectID: "project-1")
        await coordinator.start(observeGenerationOutcomes: observeGenerationOutcomes)
        await observeGenerationOutcomes.emit(GenerationOutcome(projectID: "project-1", status: .completed))
        await observeGenerationOutcomes.emit(GenerationOutcome(projectID: "project-1", status: .completed))
        await observeGenerationOutcomes.finish()
        await coordinator.waitUntilObservationFinished()

        #expect(localNotificationClient.presentedProjectIDs() == ["generation-completed-project-1"])
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

// MARK: - StubLocalNotificationClient

private final class StubLocalNotificationClient: LocalNotificationClient, Sendable {

    // MARK: Lifecycle

    init(isAuthorizedResult: Bool) {
        self.isAuthorizedResult = isAuthorizedResult
        state = Mutex(State())
    }

    // MARK: Internal

    func requestAuthorization() async -> LocalNotificationAuthorizationOutcome {
        .authorized
    }

    func isAuthorized() async -> Bool {
        isAuthorizedResult
    }

    func present(_ request: LocalNotificationRequest) {
        state.withLock { $0.presented.append(request.identifier) }
    }

    func presentedProjectIDs() -> [String] {
        state.withLock(\.presented)
    }

    // MARK: Private

    private struct State {
        var presented = [String]()
    }

    private let isAuthorizedResult: Bool
    private let state: Mutex<State>

}
