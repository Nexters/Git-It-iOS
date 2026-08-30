import ComposableArchitecture
import DomainLearningProject
import Testing

@testable import Feature

@Suite("ProjectRegistrationFeature")
struct ProjectRegistrationFeatureTests {

    // MARK: - S1: 레포지토리 검증

    @Test
    func `repositoryURLChanged는 validation을 idle로 되돌린다`() async {
        let store = makeProjectRegistrationStore(
            state: {
                var state = ProjectRegistrationFeature.State()
                state.validation = .validated(sampleRepository)
                return state
            }()
        )

        await store.send(.view(.repositoryURLChanged("https://github.com/owner/repo"))) {
            $0.repositoryURLInput = "https://github.com/owner/repo"
            $0.validation = .idle
        }
    }

    @Test
    func `validateTapped 성공은 validation을 validated로 전이한다`() async {
        let fetchExternalRepository = StubFetchExternalRepositoryUseCase(results: [.success(sampleRepository)])
        let store = makeProjectRegistrationStore(fetchExternalRepository: fetchExternalRepository)

        await store.send(.view(.repositoryURLChanged("https://github.com/owner/repo"))) {
            $0.repositoryURLInput = "https://github.com/owner/repo"
        }
        await store.send(.view(.validateTapped)) {
            $0.validation = .validating
            $0.validationRequestID = 1
        }
        await store.receive(.effect(.validationFinished(requestID: 1, result: .success(sampleRepository)))) {
            $0.validation = .validated(sampleRepository)
        }

        #expect(await fetchExternalRepository.snapshot().callCount == 1)
    }

    @Test
    func `validateTapped 실패는 validation을 failed로 전이한다`() async {
        let fetchExternalRepository = StubFetchExternalRepositoryUseCase(results: [.failure(.invalidURLFormat)])
        let store = makeProjectRegistrationStore(fetchExternalRepository: fetchExternalRepository)

        await store.send(.view(.repositoryURLChanged("https://github.com/owner/repo"))) {
            $0.repositoryURLInput = "https://github.com/owner/repo"
        }
        await store.send(.view(.validateTapped)) {
            $0.validation = .validating
            $0.validationRequestID = 1
        }
        await store.receive(.effect(.validationFinished(requestID: 1, result: .failure(.invalidURLFormat)))) {
            $0.validation = .failed
        }
    }

    @Test
    func `빈 URL에서 validateTapped는 아무 효과도 내지 않는다`() async {
        let fetchExternalRepository = StubFetchExternalRepositoryUseCase()
        let store = makeProjectRegistrationStore(fetchExternalRepository: fetchExternalRepository)

        await store.send(.view(.validateTapped))

        #expect(await fetchExternalRepository.snapshot().callCount == 0)
    }

    @Test
    func `늦게 도착한 validationRequestID 불일치 응답은 최신 상태를 덮어쓰지 않는다`() async {
        let store = makeProjectRegistrationStore()

        await store.send(.view(.repositoryURLChanged("https://github.com/owner/repo"))) {
            $0.repositoryURLInput = "https://github.com/owner/repo"
        }
        await store.send(.view(.validateTapped)) {
            $0.validation = .validating
            $0.validationRequestID = 1
        }
        await store.send(.view(.validateTapped)) {
            $0.validationRequestID = 2
        }
        await store.send(.effect(.validationFinished(requestID: 1, result: .success(sampleRepository))))

        #expect(store.state.validation == .validating)
    }

    // MARK: - S2: 이해도 선택과 제출

    @Test
    func `quizLevelSelected는 선택한 값을 반영한다`() async {
        let store = makeProjectRegistrationStore()

        for level in QuizLevel.allCases {
            await store.send(.view(.quizLevelSelected(level))) {
                $0.quizLevel = level
            }
        }
    }

    @Test
    func `미검증 상태에서 submitTapped는 아무 효과도 내지 않는다`() async {
        let createLearningProject = StubCreateLearningProjectUseCase()
        let store = makeProjectRegistrationStore(createLearningProject: createLearningProject)

        await store.send(.view(.submitTapped))

        #expect(await createLearningProject.recordedCalls().isEmpty)
    }

    @Test
    func `committing 중 중복 submitTapped는 차단된다`() async {
        let createLearningProject = StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)])
        var state = ProjectRegistrationFeature.State()
        state.validation = .validated(sampleRepository)
        state.submission = .committing
        let store = makeProjectRegistrationStore(createLearningProject: createLearningProject, state: state)

        await store.send(.view(.submitTapped))

        #expect(await createLearningProject.recordedCalls().isEmpty)
    }

    @Test
    func `submitTapped 성공 시 createLearningProject가 검증된 canonicalURL과 선택된 QuizLevel로 정확히 한 번 호출된다`() async {
        let createLearningProject = StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)])
        let observeLearningProjectGenerationOutcomes = StubObserveLearningProjectGenerationOutcomesUseCase()
        var state = ProjectRegistrationFeature.State()
        state.validation = .validated(sampleRepository)
        state.quizLevel = .l2
        let store = makeProjectRegistrationStore(
            createLearningProject: createLearningProject,
            observeLearningProjectGenerationOutcomes: observeLearningProjectGenerationOutcomes,
            state: state,
        )

        await store.send(.view(.submitTapped)) {
            $0.submission = .committing
        }
        await store.receive(.effect(.submissionFinished(.success(sampleReceipt)))) {
            $0.submission = .awaitingGeneration(sampleReceipt)
        }

        #expect(
            await createLearningProject.recordedCalls() == [
                StubCreateLearningProjectUseCase.Call(githubRepoURL: sampleRepository.canonicalURL, quizLevel: .l2)
            ]
        )

        await observeLearningProjectGenerationOutcomes.finish()
        await store.finish()
    }

    // MARK: - S3: 생성 진행과 FCM 판정

    @Test
    func `waitAtHomeTapped는 알림 옵션이 꺼져 있으면 시트를 거친 뒤 projectRegistered를 정확히 한 번 출력한다`() async {
        let observeLearningProjectGenerationOutcomes = StubObserveLearningProjectGenerationOutcomesUseCase()
        var state = ProjectRegistrationFeature.State()
        state.submission = .awaitingGeneration(sampleReceipt)
        let store = makeProjectRegistrationStore(
            observeLearningProjectGenerationOutcomes: observeLearningProjectGenerationOutcomes,
            state: state,
        )

        await store.send(.view(.waitAtHomeTapped)) {
            $0.isNotificationOptionSheetPresented = true
        }
        await store.send(.view(.notificationOptionDeclined)) {
            $0.isNotificationOptionSheetPresented = false
        }
        await store.receive(.delegate(.notificationOptionSelected(accepted: false)))
        await store.receive(.delegate(.projectRegistered(sampleReceipt)))

        await observeLearningProjectGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `awaitingGeneration 중 일치하는 projectID의 completed 수신은 projectRegistered를 출력한다`() async {
        let observeLearningProjectGenerationOutcomes = StubObserveLearningProjectGenerationOutcomesUseCase()
        let createLearningProject = StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)])
        var state = ProjectRegistrationFeature.State()
        state.validation = .validated(sampleRepository)
        let store = makeProjectRegistrationStore(
            createLearningProject: createLearningProject,
            observeLearningProjectGenerationOutcomes: observeLearningProjectGenerationOutcomes,
            state: state,
        )

        await store.send(.view(.submitTapped)) {
            $0.submission = .committing
        }
        await store.receive(.effect(.submissionFinished(.success(sampleReceipt)))) {
            $0.submission = .awaitingGeneration(sampleReceipt)
        }

        await observeLearningProjectGenerationOutcomes.emit(
            LearningProjectGenerationOutcome(projectID: sampleReceipt.projectID, status: .completed)
        )
        await store.receive(
            .effect(.generationOutcomeReceived(
                LearningProjectGenerationOutcome(projectID: sampleReceipt.projectID, status: .completed)
            ))
        )
        await store.receive(.delegate(.projectRegistered(sampleReceipt)))

        await observeLearningProjectGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `일치하지 않는 projectID의 이벤트는 무시된다`() async {
        let observeLearningProjectGenerationOutcomes = StubObserveLearningProjectGenerationOutcomesUseCase()
        var state = ProjectRegistrationFeature.State()
        state.submission = .awaitingGeneration(sampleReceipt)
        let store = makeProjectRegistrationStore(
            observeLearningProjectGenerationOutcomes: observeLearningProjectGenerationOutcomes,
            state: state,
        )

        await observeLearningProjectGenerationOutcomes.emit(
            LearningProjectGenerationOutcome(projectID: "other-project", status: .completed)
        )
        await store.receive(
            .effect(.generationOutcomeReceived(
                LearningProjectGenerationOutcome(projectID: "other-project", status: .completed)
            ))
        )

        #expect(store.state.submission == .awaitingGeneration(sampleReceipt))

        await observeLearningProjectGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `failed 이벤트 수신 시 submission이 failed로 전이한다`() async {
        let observeLearningProjectGenerationOutcomes = StubObserveLearningProjectGenerationOutcomesUseCase()
        var state = ProjectRegistrationFeature.State()
        state.submission = .awaitingGeneration(sampleReceipt)
        let store = makeProjectRegistrationStore(
            observeLearningProjectGenerationOutcomes: observeLearningProjectGenerationOutcomes,
            state: state,
        )

        await observeLearningProjectGenerationOutcomes.emit(
            LearningProjectGenerationOutcome(projectID: sampleReceipt.projectID, status: .failed)
        )
        await store.receive(
            .effect(.generationOutcomeReceived(
                LearningProjectGenerationOutcome(projectID: sampleReceipt.projectID, status: .failed)
            ))
        ) {
            $0.submission = .failed(.unexpected)
        }

        await observeLearningProjectGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `제출 자체 실패와 FCM 실패는 동일한 failed 표현을 쓴다`() async {
        let createLearningProject = StubCreateLearningProjectUseCase(results: [.failure(.temporarilyUnavailable)])
        var state = ProjectRegistrationFeature.State()
        state.validation = .validated(sampleRepository)
        let store = makeProjectRegistrationStore(createLearningProject: createLearningProject, state: state)

        await store.send(.view(.submitTapped)) {
            $0.submission = .committing
        }
        await store.receive(.effect(.submissionFinished(.failure(.temporarilyUnavailable)))) {
            $0.submission = .failed(.temporarilyUnavailable)
        }
    }

    @Test
    func `retryTapped는 동일 입력으로 재제출한다`() async {
        let createLearningProject = StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)])
        let observeLearningProjectGenerationOutcomes = StubObserveLearningProjectGenerationOutcomesUseCase()
        var state = ProjectRegistrationFeature.State()
        state.validation = .validated(sampleRepository)
        state.quizLevel = .l3
        state.submission = .failed(.unexpected)
        let store = makeProjectRegistrationStore(
            createLearningProject: createLearningProject,
            observeLearningProjectGenerationOutcomes: observeLearningProjectGenerationOutcomes,
            state: state,
        )

        await store.send(.view(.retryTapped)) {
            $0.submission = .committing
        }
        await store.receive(.effect(.submissionFinished(.success(sampleReceipt)))) {
            $0.submission = .awaitingGeneration(sampleReceipt)
        }

        #expect(
            await createLearningProject.recordedCalls() == [
                StubCreateLearningProjectUseCase.Call(githubRepoURL: sampleRepository.canonicalURL, quizLevel: .l3)
            ]
        )

        await observeLearningProjectGenerationOutcomes.finish()
        await store.finish()
    }

    // MARK: - S4: 알림 옵션

    @Test
    func `알림 수락은 notificationOptionSelected accepted true를 출력한 뒤 waitAtHomeTapped 동작을 이어간다`() async {
        let observeLearningProjectGenerationOutcomes = StubObserveLearningProjectGenerationOutcomesUseCase()
        var state = ProjectRegistrationFeature.State()
        state.submission = .awaitingGeneration(sampleReceipt)
        state.isNotificationOptionSheetPresented = true
        let store = makeProjectRegistrationStore(
            observeLearningProjectGenerationOutcomes: observeLearningProjectGenerationOutcomes,
            state: state,
        )

        await store.send(.view(.notificationOptionAccepted)) {
            $0.isNotificationOptionSheetPresented = false
        }
        await store.receive(.delegate(.notificationOptionSelected(accepted: true)))
        await store.receive(.delegate(.projectRegistered(sampleReceipt)))

        await observeLearningProjectGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `알림 옵션 선택은 상태 전이 자체에 영향을 주지 않는다`() async {
        let observeLearningProjectGenerationOutcomes = StubObserveLearningProjectGenerationOutcomesUseCase()
        var state = ProjectRegistrationFeature.State()
        state.submission = .awaitingGeneration(sampleReceipt)
        state.isNotificationOptionSheetPresented = true
        let store = makeProjectRegistrationStore(
            observeLearningProjectGenerationOutcomes: observeLearningProjectGenerationOutcomes,
            state: state,
        )
        store.exhaustivity = .off

        await store.send(.view(.notificationOptionDeclined))

        #expect(store.state.repositoryURLInput.isEmpty)
        #expect(store.state.quizLevel == .l1)

        await observeLearningProjectGenerationOutcomes.finish()
        await store.finish()
    }

    // MARK: - FR-016 / SC-014: 흐름 중간 종료 시 취소

    @Test
    func `State가 폐기되면 진행 중이던 검증 Effect가 취소되고 이후 이벤트를 받지 않는다`() async {
        let fetchExternalRepository = StubFetchExternalRepositoryUseCase(suspendsRequests: true)
        var childState = ProjectRegistrationFeature.State()
        childState.repositoryURLInput = "https://github.com/owner/repo"
        let store = TestStore(initialState: ProjectRegistrationHostFeature.State(child: childState)) {
            ProjectRegistrationHostFeature(
                fetchExternalRepository: fetchExternalRepository,
                createLearningProject: StubCreateLearningProjectUseCase(),
                observeLearningProjectGenerationOutcomes: StubObserveLearningProjectGenerationOutcomesUseCase(),
            )
        }

        await store.send(.child(.presented(.view(.validateTapped)))) {
            $0.child?.validation = .validating
            $0.child?.validationRequestID = 1
        }
        await store.send(.child(.dismiss)) {
            $0.child = nil
        }
        await fetchExternalRepository.resumeOldest()

        await store.finish()
    }

    @Test
    func `State가 폐기되면 진행 중이던 제출 Effect가 취소되고 이후 이벤트를 받지 않는다`() async {
        let createLearningProject = StubCreateLearningProjectUseCase(suspendsRequests: true)
        var childState = ProjectRegistrationFeature.State()
        childState.validation = .validated(sampleRepository)
        let store = TestStore(initialState: ProjectRegistrationHostFeature.State(child: childState)) {
            ProjectRegistrationHostFeature(
                fetchExternalRepository: StubFetchExternalRepositoryUseCase(),
                createLearningProject: createLearningProject,
                observeLearningProjectGenerationOutcomes: StubObserveLearningProjectGenerationOutcomesUseCase(),
            )
        }

        await store.send(.child(.presented(.view(.submitTapped)))) {
            $0.child?.submission = .committing
        }
        await store.send(.child(.dismiss)) {
            $0.child = nil
        }
        await createLearningProject.resumeOldest()

        await store.finish()
    }

}

// MARK: - Fixtures

private let sampleRepository = ExternalRepository(
    canonicalURL: "https://github.com/owner/repo",
    ownerName: "owner",
    repositoryName: "repo",
    imageURL: nil,
    starCount: 10,
    techStack: ["Swift"],
)

private let sampleReceipt = ProjectRegistrationReceipt(
    projectID: "project-1",
    requestStatus: "ready",
    quizLevel: .l1,
)

private func makeProjectRegistrationStore(
    fetchExternalRepository: StubFetchExternalRepositoryUseCase = StubFetchExternalRepositoryUseCase(),
    createLearningProject: StubCreateLearningProjectUseCase = StubCreateLearningProjectUseCase(),
    observeLearningProjectGenerationOutcomes: StubObserveLearningProjectGenerationOutcomesUseCase = StubObserveLearningProjectGenerationOutcomesUseCase(),
    state: ProjectRegistrationFeature.State = ProjectRegistrationFeature.State(),
) -> TestStoreOf<ProjectRegistrationFeature> {
    TestStore(initialState: state) {
        ProjectRegistrationFeature(
            fetchExternalRepository: fetchExternalRepository,
            createLearningProject: createLearningProject,
            observeLearningProjectGenerationOutcomes: observeLearningProjectGenerationOutcomes,
        )
    }
}

// MARK: - ProjectRegistrationHostFeature

@Reducer
private struct ProjectRegistrationHostFeature {

    // MARK: Internal

    @ObservableState
    struct State: Equatable {
        @Presents var child: ProjectRegistrationFeature.State?
    }

    enum Action {
        case child(PresentationAction<ProjectRegistrationFeature.Action>)
    }

    let fetchExternalRepository: any FetchExternalRepositoryUseCase
    let createLearningProject: any CreateLearningProjectUseCase
    let observeLearningProjectGenerationOutcomes: any ObserveLearningProjectGenerationOutcomesUseCase

    var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
            .ifLet(\.$child, action: \.child) {
                ProjectRegistrationFeature(
                    fetchExternalRepository: fetchExternalRepository,
                    createLearningProject: createLearningProject,
                    observeLearningProjectGenerationOutcomes: observeLearningProjectGenerationOutcomes,
                )
            }
    }

}
