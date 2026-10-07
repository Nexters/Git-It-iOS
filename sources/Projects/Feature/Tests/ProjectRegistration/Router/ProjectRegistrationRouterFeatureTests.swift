import ComposableArchitecture
import DomainLearningProject
import Foundation
import Testing

@testable import Feature

@Suite("ProjectRegistrationRouterFeature 화면 전환")
struct ProjectRegistrationRouterFeatureTests {

    @Test
    func `검증에 성공하면 저장소 확인 화면으로 전환하고 확인 대상 저장소를 넘긴다`() async {
        let store = makeProjectRegistrationRouterStore()

        #expect(store.state.activeScreen == .repositoryLinkInput)

        await store.send(.repositoryLinkInput(.delegate(.repositoryValidated(sampleRepository)))) {
            $0.repositoryConfirmation.repository = sampleRepository
            $0.activeScreen = .repositoryConfirmation
            $0.screenTransitions = [.init(from: .repositoryLinkInput, to: .repositoryConfirmation)]
        }
    }

    @Test
    func `저장소 확인과 이해도 선택 단계는 Feature 상태로 유지되고 역방향 전이도 가능하다`() async {
        var state = ProjectRegistrationRouterFeature.State()
        state.activeScreen = .repositoryConfirmation
        state.repositoryConfirmation.repository = sampleRepository
        let store = makeProjectRegistrationRouterStore(state: state)
        store.exhaustivity = .off

        await store.send(.repositoryConfirmation(.view(.confirmTapped)))
        await store.receive(.repositoryConfirmation(.delegate(.confirmed)))
        #expect(store.state.activeScreen == .quizLevelSelection)

        await store.send(.quizLevelSelection(.view(.nextTapped)))
        await store.receive(.quizLevelSelection(.delegate(.confirmed(.l1))))
        #expect(store.state.activeScreen == .quizGenerationConfirmation)

        await store.send(.quizGenerationConfirmation(.view(.backTapped)))
        await store.receive(.quizGenerationConfirmation(.delegate(.backRequested)))
        #expect(store.state.activeScreen == .quizLevelSelection)

        await store.send(.quizLevelSelection(.view(.backTapped)))
        await store.receive(.quizLevelSelection(.delegate(.backRequested)))
        #expect(store.state.activeScreen == .repositoryConfirmation)

        #expect(store.state.screenTransitions.map(\.to) == [
            .quizLevelSelection,
            .quizGenerationConfirmation,
            .quizLevelSelection,
            .repositoryConfirmation,
        ])
    }

    @Test
    func `저장소를 거부하면 링크 입력으로 되돌리고 검증 결과를 비운다`() async {
        var state = ProjectRegistrationRouterFeature.State()
        state.activeScreen = .repositoryConfirmation
        state.repositoryConfirmation.repository = sampleRepository
        state.repositoryLinkInput.validation = .validated(sampleRepository)
        let store = makeProjectRegistrationRouterStore(state: state)
        store.exhaustivity = .off

        await store.send(.repositoryConfirmation(.view(.rejectTapped)))
        await store.receive(.repositoryConfirmation(.delegate(.rejected)))

        #expect(store.state.activeScreen == .repositoryLinkInput)
        #expect(store.state.repositoryLinkInput.validation == .idle)
        #expect(store.state.repositoryConfirmation.repository == nil)
    }

    @Test
    func `생성 시작은 진행 화면으로 전환하고 확인된 저장소와 선택한 난이도로 제출을 요청한다`() async {
        let createLearningProject = StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)])
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        var state = ProjectRegistrationRouterFeature.State()
        state.activeScreen = .quizGenerationConfirmation
        state.repositoryConfirmation.repository = sampleRepository
        state.quizLevelSelection.quizLevel = .l2
        let store = makeProjectRegistrationRouterStore(
            createLearningProject: createLearningProject,
            observeGenerationOutcomes: observeGenerationOutcomes,
            state: state,
        )
        store.exhaustivity = .off

        await store.send(.quizGenerationConfirmation(.view(.startTapped)))
        await store.receive(.quizGenerationConfirmation(.delegate(.submitRequested)))
        await store.receive(.quizGenerationProgress(.submit(repository: sampleRepository, quizLevel: .l2)))

        #expect(store.state.activeScreen == .quizGenerationProgress)

        await store.receive(.quizGenerationProgress(.effect(.submissionFinished(.success(sampleReceipt)))))
        #expect(
            await createLearningProject.recordedCalls() == [
                StubCreateLearningProjectUseCase.Call(githubRepoURL: sampleRepository.canonicalURL, quizLevel: .l2)
            ]
        )

        await observeGenerationOutcomes.finish()
        await store.skipReceivedActions()
        await store.finish()
    }

    @Test
    func `확인된 저장소가 없으면 생성 시작이 아무 효과도 내지 않는다`() async {
        let createLearningProject = StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)])
        var state = ProjectRegistrationRouterFeature.State()
        state.activeScreen = .quizGenerationConfirmation
        let store = makeProjectRegistrationRouterStore(createLearningProject: createLearningProject, state: state)
        store.exhaustivity = .off

        await store.send(.quizGenerationConfirmation(.view(.startTapped)))
        await store.receive(.quizGenerationConfirmation(.delegate(.submitRequested)))

        #expect(store.state.activeScreen == .quizGenerationConfirmation)
        #expect(await createLearningProject.recordedCalls().isEmpty)
    }

    @Test
    func `진행 화면의 완료와 알림 선택과 닫기 위임은 그대로 상위로 전달된다`() async {
        let store = makeProjectRegistrationRouterStore()
        store.exhaustivity = .off

        await store.send(.quizGenerationProgress(.delegate(.projectRegistered(sampleReceipt))))
        await store.receive(.delegate(.projectRegistered(sampleReceipt)))

        await store.send(.quizGenerationProgress(.delegate(.generationReminderPreferenceSelected(isEnabled: true))))
        await store.receive(.delegate(.generationReminderPreferenceSelected(isEnabled: true)))

        await store.send(.quizGenerationProgress(.delegate(.dismissRequested)))
        await store.receive(.delegate(.dismissRequested))
    }

    @Test
    func `링크 입력의 닫기 위임은 그대로 상위로 전달된다`() async {
        let store = makeProjectRegistrationRouterStore()
        store.exhaustivity = .off

        await store.send(.repositoryLinkInput(.delegate(.dismissRequested)))
        await store.receive(.delegate(.dismissRequested))
    }

    @Test
    func `같은 화면으로의 전환 요청은 이동 기록을 남기지 않는다`() async {
        var state = ProjectRegistrationRouterFeature.State()
        state.activeScreen = .repositoryConfirmation
        state.repositoryConfirmation.repository = sampleRepository
        let store = makeProjectRegistrationRouterStore(state: state)
        store.exhaustivity = .off

        await store.send(.repositoryLinkInput(.delegate(.repositoryValidated(sampleRepository))))

        #expect(store.state.activeScreen == .repositoryConfirmation)
        #expect(store.state.screenTransitions.isEmpty)
    }

}
