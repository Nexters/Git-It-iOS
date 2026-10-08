import ComposableArchitecture
import DomainAccount
import DomainExternalRepository
import DomainProjectGeneration
import Foundation
import Synchronization
import Testing

@testable import Feature

// MARK: - SharedRepositoryRegistrationFeatureTests

@MainActor
@Suite("SharedRepositoryRegistrationFeature 검증과 등록")
struct SharedRepositoryRegistrationFeatureTests {

    // MARK: Internal

    @Test
    func `공유 항목에 URL이 없으면 네트워크 호출 없이 오류 상태가 되고 진단 이벤트를 남긴다`() async {
        let recorder = Recorder()
        let store = Self.makeStore(
            sharedURL: nil,
            recorder: recorder,
        )

        await store.send(.input(.validate(sharedURL: nil))) {
            $0.phase = .invalidURL(reason: "공유한 항목에서 링크를 찾지 못했어요.")
        }

        #expect(recorder.events == [.sharedItemUnavailable])
    }

    @Test
    func `GitHub 저장소 경로가 아니면 조회하지 않고 오류 상태가 되고 진단 이벤트를 남긴다`() async {
        let recorder = Recorder()
        let store = Self.makeStore(
            location: nil,
            recorder: recorder,
        )

        await store.send(.input(.validate(sharedURL: ShareRegistrationTestSupport.sharedURL))) {
            $0.phase = .invalidURL(reason: "GitHub 저장소 주소가 아니에요.")
        }

        #expect(recorder.events == [.repositoryLinkRejected])
    }

    @Test
    func `세션 마커가 없으면 앱 실행 필요 상태가 되고 세션 판정 결과를 토큰 없이 남긴다`() async {
        let recorder = Recorder()
        let store = Self.makeStore(
            availability: .appLaunchRequired,
            recorder: recorder,
        )

        await store.send(.input(.validate(sharedURL: ShareRegistrationTestSupport.sharedURL)))
        await store.receive(\.effect.validationFinished) {
            $0.phase = .appLaunchRequired
        }

        #expect(recorder.events == [.signInAvailabilityResolved(.appLaunchRequired)])
    }

    @Test
    func `세션이 없으면 갱신 없이 로그인 필요 상태가 된다`() async {
        let store = Self.makeStore(availability: .signInRequired)

        await store.send(.input(.validate(sharedURL: ShareRegistrationTestSupport.sharedURL)))
        await store.receive(\.effect.validationFinished) {
            $0.phase = .signInRequired
        }
    }

    @Test
    func `조회가 네트워크 오류로 실패하면 재시도 가능한 실패 상태가 된다`() async {
        let store = Self.makeStore(lookupResult: .failure(ExternalRepositoryError.offline))

        await store.send(.input(.validate(sharedURL: ShareRegistrationTestSupport.sharedURL)))
        await store.receive(\.effect.validationFinished) {
            $0.phase = .failed(
                reason: "네트워크에 연결할 수 없어요.",
                retry: .lookup,
            )
        }
    }

    @Test
    func `조회에 성공하면 등록 가능 상태가 되고 repositoryResolved를 위임한다`() async {
        let store = Self.makeStore()

        await store.send(.input(.validate(sharedURL: ShareRegistrationTestSupport.sharedURL)))
        await store.receive(\.effect.repositoryResolved) {
            $0.phase = .ready(ShareRegistrationTestSupport.repository)
        }
        await store.receive(.delegate(.repositoryResolved(ShareRegistrationTestSupport.repository)))
    }

    @Test
    func `저장소 조회 실패와 등록 실패를 서로 다른 이벤트로 구분한다`() async {
        let recorder = Recorder()
        let store = Self.makeStore(
            lookupResult: .failure(ExternalRepositoryError.offline),
            recorder: recorder,
        )
        store.exhaustivity = .off

        await store.send(.input(.validate(sharedURL: ShareRegistrationTestSupport.sharedURL)))
        await store.skipReceivedActions()

        #expect(recorder.events.contains(.signInAvailabilityResolved(.signedIn)))
        #expect(recorder.events.contains { event in
            if case .repositoryLookupFailed = event {
                return true
            }
            return false
        })
        #expect(recorder.events.contains { event in
            if case .registrationFailed = event {
                return true
            }
            return false
        } == false)
    }

    @Test
    func `진단 이벤트 값에 토큰이나 원본 URL 전체를 담지 않는다`() async {
        let recorder = Recorder()
        let store = Self.makeStore(recorder: recorder)
        store.exhaustivity = .off

        await store.send(.input(.validate(sharedURL: ShareRegistrationTestSupport.sharedURL)))
        await store.skipReceivedActions()

        let described = recorder.events.map { String(describing: $0) }.joined()
        #expect(described.contains(ShareRegistrationTestSupport.sharedURL) == false)
        #expect(described.contains("token") == false)
    }

    @Test
    func `제출한 난이도로 등록을 요청하고 성공하면 완료 상태가 된다`() async {
        let projectGeneration = ProjectGenerationUseCaseSpy()
        let store = Self.makeStore(
            projectGeneration: projectGeneration,
            state: Self.readyState(),
        )

        await store.send(.input(.submit(
            repository: ShareRegistrationTestSupport.repository,
            quizLevel: .l3,
        ))) {
            $0.submission = Self.submission(quizLevel: .l3)
            $0.phase = .submitting
        }
        await store.receive(\.effect.registrationFinished) {
            $0.phase = .succeeded
        }

        #expect(projectGeneration.lastQuizLevel == .l3)
        #expect(projectGeneration.callCount == 1)
    }

    @Test
    func `요청 중에는 추가 등록 실행을 받지 않는다`() async {
        let projectGeneration = ProjectGenerationUseCaseSpy(suspendsUntilResumed: true)
        let store = Self.makeStore(
            projectGeneration: projectGeneration,
            state: Self.readyState(),
        )

        await store.send(.input(.submit(
            repository: ShareRegistrationTestSupport.repository,
            quizLevel: .l1,
        ))) {
            $0.submission = Self.submission(quizLevel: .l1)
            $0.phase = .submitting
        }
        await store.send(.input(.submit(
            repository: ShareRegistrationTestSupport.repository,
            quizLevel: .l1,
        )))

        #expect(projectGeneration.callCount == 1)

        projectGeneration.resume()
        await store.receive(\.effect.registrationFinished) {
            $0.phase = .succeeded
        }
    }

    @Test
    func `등록 응답이 인증 오류면 갱신 없이 로그인 필요 상태가 된다`() async {
        let store = Self.makeStore(
            projectGeneration: ProjectGenerationUseCaseSpy(error: .unauthorized),
            state: Self.readyState(),
        )

        await store.send(.input(.submit(
            repository: ShareRegistrationTestSupport.repository,
            quizLevel: .l1,
        ))) {
            $0.submission = Self.submission(quizLevel: .l1)
            $0.phase = .submitting
        }
        await store.receive(\.effect.registrationFinished) {
            $0.phase = .signInRequired
        }
    }

    @Test(arguments: [
        (ProjectGenerationError.duplicateRequest, "이미 등록 중인 저장소예요."),
        (.temporarilyUnavailable, "지금은 연결할 수 없어요. 잠시 후 다시 시도해 주세요."),
    ])
    func `등록 실패는 사유와 등록 단계 재시도를 남긴다`(
        error: ProjectGenerationError,
        reason: String,
    ) async {
        let store = Self.makeStore(
            projectGeneration: ProjectGenerationUseCaseSpy(error: error),
            state: Self.readyState(),
        )

        await store.send(.input(.submit(
            repository: ShareRegistrationTestSupport.repository,
            quizLevel: .l1,
        ))) {
            $0.submission = Self.submission(quizLevel: .l1)
            $0.phase = .submitting
        }
        await store.receive(\.effect.registrationFinished) {
            $0.phase = .failed(
                reason: reason,
                retry: .registration,
            )
        }
    }

    @Test(arguments: [
        (SignInAvailability.signInRequired, SharedRepositoryRegistrationFeature.State.Phase.signInRequired),
        (.appLaunchRequired, .appLaunchRequired),
    ])
    func `제출 시점에 로그인이나 앱 실행이 필요하면 등록을 요청하지 않는다`(
        availability: SignInAvailability,
        expected: SharedRepositoryRegistrationFeature.State.Phase,
    ) async {
        let projectGeneration = ProjectGenerationUseCaseSpy()
        let store = Self.makeStore(
            availability: availability,
            projectGeneration: projectGeneration,
            state: Self.readyState(),
        )

        await store.send(.input(.submit(
            repository: ShareRegistrationTestSupport.repository,
            quizLevel: .l1,
        ))) {
            $0.submission = Self.submission(quizLevel: .l1)
            $0.phase = .submitting
        }
        await store.receive(\.effect.validationFinished) {
            $0.phase = expected
        }

        #expect(projectGeneration.callCount == 0)
    }

    @Test
    func `재시도는 실패한 등록을 같은 저장소와 난이도로 다시 수행한다`() async {
        let projectGeneration = ProjectGenerationUseCaseSpy(error: .temporarilyUnavailable)
        let store = Self.makeStore(
            projectGeneration: projectGeneration,
            state: Self.readyState(),
        )
        store.exhaustivity = .off

        await store.send(.input(.submit(
            repository: ShareRegistrationTestSupport.repository,
            quizLevel: .l2,
        )))
        await store.skipReceivedActions()
        await store.send(.input(.retry))
        await store.skipReceivedActions()

        #expect(projectGeneration.callCount == 2)
        #expect(projectGeneration.lastQuizLevel == .l2)
    }

    @Test
    func `조회 실패의 재시도는 저장소 조회를 다시 수행한다`() async {
        var state = SharedRepositoryRegistrationFeature.State(sharedURL: ShareRegistrationTestSupport.sharedURL)
        state.phase = .failed(
            reason: "네트워크에 연결할 수 없어요.",
            retry: .lookup,
        )
        let store = Self.makeStore(state: state)

        await store.send(.input(.retry)) {
            $0.phase = .validating
        }
        await store.receive(\.effect.repositoryResolved) {
            $0.phase = .ready(ShareRegistrationTestSupport.repository)
        }
        await store.receive(.delegate(.repositoryResolved(ShareRegistrationTestSupport.repository)))
    }

    @Test
    func `실패 상태가 아니면 재시도를 무시한다`() async {
        let projectGeneration = ProjectGenerationUseCaseSpy()
        let store = Self.makeStore(
            projectGeneration: projectGeneration,
            state: Self.readyState(),
        )

        await store.send(.input(.retry))

        #expect(projectGeneration.callCount == 0)
    }

    @Test
    func `생성 상태에 진행 중 요청이 있으면 저장소를 조회하지 않고 생성 중 안내 상태가 된다`() async {
        let recorder = Recorder()
        let lookups = Counter()
        let store = Self.makeStore(
            lookups: lookups,
            projectGeneration: ProjectGenerationUseCaseSpy(currentStates: [.success(Self.generationState([
                .ready,
                .inProgress,
            ]))]),
            recorder: recorder,
        )

        await store.send(.input(.validate(sharedURL: ShareRegistrationTestSupport.sharedURL)))
        await store.receive(\.effect.validationFinished) {
            $0.phase = .generationInProgress
        }

        #expect(lookups.callCount == 0)
        #expect(recorder.events == [.signInAvailabilityResolved(.signedIn), .generationInProgressBlocked])
    }

    @Test(arguments: [
        [ProjectGenerationPhase.ready],
        [.failed],
        [],
    ])
    func `생성 상태에 진행 중 요청이 없으면 기존처럼 저장소를 조회한다`(phases: [ProjectGenerationPhase]) async {
        let lookups = Counter()
        let store = Self.makeStore(
            lookups: lookups,
            projectGeneration: ProjectGenerationUseCaseSpy(currentStates: [.success(Self.generationState(phases))]),
        )

        await store.send(.input(.validate(sharedURL: ShareRegistrationTestSupport.sharedURL)))
        await store.receive(\.effect.repositoryResolved) {
            $0.phase = .ready(ShareRegistrationTestSupport.repository)
        }
        await store.receive(.delegate(.repositoryResolved(ShareRegistrationTestSupport.repository)))

        #expect(lookups.callCount == 1)
    }

    @Test
    func `생성 상태를 확인하지 못하면 저장소를 조회하지 않고 조회 단계 재시도가 있는 확인 실패 상태가 된다`() async {
        let recorder = Recorder()
        let lookups = Counter()
        let store = Self.makeStore(
            lookups: lookups,
            projectGeneration: ProjectGenerationUseCaseSpy(currentStates: [.failure(.stateUnavailable)]),
            recorder: recorder,
        )

        await store.send(.input(.validate(sharedURL: ShareRegistrationTestSupport.sharedURL)))
        await store.receive(\.effect.validationFinished) {
            $0.phase = .generationUnverified(retry: .lookup)
        }

        #expect(lookups.callCount == 0)
        #expect(recorder.events == [.signInAvailabilityResolved(.signedIn), .generationStateUnverified])
    }

    @Test
    func `공유한 저장소와 같은 저장소의 진행 중 요청도 생성 중 안내 상태가 된다`() async {
        let store = Self.makeStore(projectGeneration: ProjectGenerationUseCaseSpy(currentStates: [.success(
            ProjectGenerationState(requests: [ProjectGenerationRequestState(
                repositoryURL: ShareRegistrationTestSupport.sharedURL,
                projectID: nil,
                requestedAt: Self.requestedAt,
                phase: .inProgress,
            )])
        )]))

        await store.send(.input(.validate(sharedURL: ShareRegistrationTestSupport.sharedURL)))
        await store.receive(\.effect.validationFinished) {
            $0.phase = .generationInProgress
        }
    }

    @Test
    func `등록 직전 생성 상태에 진행 중 요청이 있으면 등록을 요청하지 않고 생성 중 안내 상태가 된다`() async {
        let recorder = Recorder()
        let projectGeneration = ProjectGenerationUseCaseSpy(currentStates: [.success(Self.generationState([.inProgress]))])
        let store = Self.makeStore(
            projectGeneration: projectGeneration,
            recorder: recorder,
            state: Self.readyState(),
        )

        await store.send(.input(.submit(
            repository: ShareRegistrationTestSupport.repository,
            quizLevel: .l1,
        ))) {
            $0.submission = Self.submission(quizLevel: .l1)
            $0.phase = .submitting
        }
        await store.receive(\.effect.validationFinished) {
            $0.phase = .generationInProgress
        }

        #expect(projectGeneration.callCount == 0)
        #expect(recorder.events == [.generationInProgressBlocked])
    }

    @Test
    func `등록 직전 생성 상태를 확인하지 못하면 등록을 요청하지 않고 등록 단계 재시도가 있는 확인 실패 상태가 된다`() async {
        let recorder = Recorder()
        let projectGeneration = ProjectGenerationUseCaseSpy(currentStates: [.failure(.stateUnavailable)])
        let store = Self.makeStore(
            projectGeneration: projectGeneration,
            recorder: recorder,
            state: Self.readyState(),
        )

        await store.send(.input(.submit(
            repository: ShareRegistrationTestSupport.repository,
            quizLevel: .l1,
        ))) {
            $0.submission = Self.submission(quizLevel: .l1)
            $0.phase = .submitting
        }
        await store.receive(\.effect.validationFinished) {
            $0.phase = .generationUnverified(retry: .registration)
        }

        #expect(projectGeneration.callCount == 0)
        #expect(recorder.events == [.generationStateUnverified])
    }

    @Test(arguments: [SignInAvailability.signInRequired, .appLaunchRequired])
    func `로그인이나 앱 실행이 필요하면 생성 상태를 조회하지 않는다`(availability: SignInAvailability) async {
        let projectGeneration = ProjectGenerationUseCaseSpy()
        let store = Self.makeStore(
            availability: availability,
            projectGeneration: projectGeneration,
        )
        store.exhaustivity = .off

        await store.send(.input(.validate(sharedURL: ShareRegistrationTestSupport.sharedURL)))
        await store.skipReceivedActions()

        #expect(projectGeneration.currentStateCallCount == 0)
    }

    @Test
    func `저장소 주소가 아니면 생성 상태를 조회하지 않는다`() async {
        let projectGeneration = ProjectGenerationUseCaseSpy()
        let store = Self.makeStore(
            location: nil,
            projectGeneration: projectGeneration,
        )

        await store.send(.input(.validate(sharedURL: ShareRegistrationTestSupport.sharedURL))) {
            $0.phase = .invalidURL(reason: "GitHub 저장소 주소가 아니에요.")
        }

        #expect(projectGeneration.currentStateCallCount == 0)
    }

    @Test
    func `조회 실패의 재시도는 생성 상태 확인부터 다시 한다`() async {
        var state = SharedRepositoryRegistrationFeature.State(sharedURL: ShareRegistrationTestSupport.sharedURL)
        state.phase = .failed(
            reason: "네트워크에 연결할 수 없어요.",
            retry: .lookup,
        )
        let lookups = Counter()
        let projectGeneration = ProjectGenerationUseCaseSpy(currentStates: [.success(Self.generationState([.inProgress]))])
        let store = Self.makeStore(
            lookups: lookups,
            projectGeneration: projectGeneration,
            state: state,
        )

        await store.send(.input(.retry)) {
            $0.phase = .validating
        }
        await store.receive(\.effect.validationFinished) {
            $0.phase = .generationInProgress
        }

        #expect(projectGeneration.currentStateCallCount == 1)
        #expect(lookups.callCount == 0)
    }

    @Test
    func `확인 실패의 조회 단계 재시도는 생성 상태 확인부터 다시 해 저장소를 조회한다`() async {
        let projectGeneration = ProjectGenerationUseCaseSpy(currentStates: [
            .failure(.stateUnavailable),
            .success(Self.generationState([])),
        ])
        let store = Self.makeStore(projectGeneration: projectGeneration)

        await store.send(.input(.validate(sharedURL: ShareRegistrationTestSupport.sharedURL)))
        await store.receive(\.effect.validationFinished) {
            $0.phase = .generationUnverified(retry: .lookup)
        }
        await store.send(.input(.retry)) {
            $0.phase = .validating
        }
        await store.receive(\.effect.repositoryResolved) {
            $0.phase = .ready(ShareRegistrationTestSupport.repository)
        }
        await store.receive(.delegate(.repositoryResolved(ShareRegistrationTestSupport.repository)))

        #expect(projectGeneration.currentStateCallCount == 2)
    }

    @Test
    func `확인 실패의 등록 단계 재시도는 생성 상태 확인부터 다시 해 같은 난이도로 등록한다`() async {
        let projectGeneration = ProjectGenerationUseCaseSpy(currentStates: [
            .failure(.stateUnavailable),
            .success(Self.generationState([])),
        ])
        var state = Self.readyState()
        state.submission = Self.submission(quizLevel: .l2)
        state.phase = .generationUnverified(retry: .registration)
        let store = Self.makeStore(
            projectGeneration: projectGeneration,
            state: state,
        )

        await store.send(.input(.retry)) {
            $0.phase = .submitting
        }
        await store.receive(\.effect.validationFinished) {
            $0.phase = .generationUnverified(retry: .registration)
        }
        await store.send(.input(.retry)) {
            $0.phase = .submitting
        }
        await store.receive(\.effect.registrationFinished) {
            $0.phase = .succeeded
        }

        #expect(projectGeneration.currentStateCallCount == 2)
        #expect(projectGeneration.callCount == 1)
        #expect(projectGeneration.lastQuizLevel == .l2)
    }

    @Test
    func `생성 중 안내 상태에서는 재시도를 무시한다`() async {
        var state = Self.readyState()
        state.phase = .generationInProgress
        let projectGeneration = ProjectGenerationUseCaseSpy()
        let store = Self.makeStore(
            projectGeneration: projectGeneration,
            state: state,
        )

        await store.send(.input(.retry))

        #expect(projectGeneration.currentStateCallCount == 0)
        #expect(projectGeneration.callCount == 0)
    }

    // MARK: Private

    private final class Recorder: Sendable {

        // MARK: Internal

        var events: [ShareRegistrationDiagnosticEvent] {
            storage.withLock { $0 }
        }

        func record(_ event: ShareRegistrationDiagnosticEvent) {
            storage.withLock { $0.append(event) }
        }

        // MARK: Private

        private let storage = Mutex([ShareRegistrationDiagnosticEvent]())

    }

    private final class Counter: Sendable {

        // MARK: Internal

        var callCount: Int {
            storage.withLock { $0 }
        }

        func increment() {
            storage.withLock { $0 += 1 }
        }

        // MARK: Private

        private let storage = Mutex(0)

    }

    private static let requestedAt = Date(timeIntervalSince1970: 10_000)

    private static func generationState(_ phases: [ProjectGenerationPhase]) -> ProjectGenerationState {
        ProjectGenerationState(requests: phases.enumerated().map { index, phase in
            ProjectGenerationRequestState(
                repositoryURL: "https://github.com/owner/repo\(index)",
                projectID: "project-\(index)",
                requestedAt: requestedAt,
                phase: phase,
            )
        })
    }

    private static func readyState() -> SharedRepositoryRegistrationFeature.State {
        var state = SharedRepositoryRegistrationFeature.State(sharedURL: ShareRegistrationTestSupport.sharedURL)
        state.phase = .ready(ShareRegistrationTestSupport.repository)
        return state
    }

    private static func submission(quizLevel: QuizLevel) -> SharedRepositoryRegistrationFeature.Submission {
        SharedRepositoryRegistrationFeature.Submission(
            repository: ShareRegistrationTestSupport.repository,
            quizLevel: quizLevel,
        )
    }

    private static func makeStore(
        sharedURL: String? = ShareRegistrationTestSupport.sharedURL,
        location: ExternalRepositoryLocation? = ShareRegistrationTestSupport.location,
        availability: SignInAvailability = .signedIn,
        lookupResult: Result<ExternalRepository, any Error> = .success(ShareRegistrationTestSupport.repository),
        lookups: Counter = Counter(),
        projectGeneration: ProjectGenerationUseCaseSpy = ProjectGenerationUseCaseSpy(),
        recorder: Recorder = Recorder(),
        state: SharedRepositoryRegistrationFeature.State? = nil,
    ) -> TestStoreOf<SharedRepositoryRegistrationFeature> {
        let externalRepository = ExternalRepositoryUseCaseFixedResultStub(result: lookupResult)
        return TestStore(initialState: state ?? SharedRepositoryRegistrationFeature.State(sharedURL: sharedURL)) {
            SharedRepositoryRegistrationFeature(
                parseRepositoryLink: StubRepositoryURLParser(location: location),
                lookUpRepository: { url in
                    lookups.increment()
                    return try await externalRepository.repository(at: url)
                },
                requestGeneration: { try await projectGeneration.request($0) },
                currentGenerationState: { try await projectGeneration.currentState() },
                signInAvailability: { availability },
                recordDiagnostic: { recorder.record($0) },
            )
        }
    }

}
