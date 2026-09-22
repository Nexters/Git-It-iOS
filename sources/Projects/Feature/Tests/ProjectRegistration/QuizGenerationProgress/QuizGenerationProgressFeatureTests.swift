import ComposableArchitecture
import DomainProjectGeneration
import Foundation
import Testing

@testable import Feature

@MainActor
@Suite("QuizGenerationProgressFeature 생성 요청과 대기")
struct QuizGenerationProgressFeatureTests {

    // MARK: Internal

    @Test
    func `submit은 canonicalURL과 선택한 난이도로 정확히 한 번 생성을 요청한다`() async {
        let generationStates = ProjectGenerationStateStreamStub()
        let projectGeneration = ProjectGenerationUseCaseStub(
            results: [.success(sampleReceipt)],
            generationStates: generationStates,
        )
        let store = makeQuizGenerationProgressStore(projectGeneration: projectGeneration)
        store.exhaustivity = .off

        await store.send(.submit(
            repository: sampleRepository,
            quizLevel: .l2,
        ))
        await store.receive(\.effect.submissionFinished)

        #expect(store.state.progress == .awaitingOutcome(sampleReceipt))
        #expect(await projectGeneration.recordedRequests() == [
            ProjectGenerationRequest(
                repositoryURL: sampleRepository.canonicalURL,
                quizLevel: .l2,
            )
        ])

        await generationStates.finish()
        await store.finish()
    }

    @Test
    func `제출에 실패하면 failed로 전이한다`() async {
        let projectGeneration = ProjectGenerationUseCaseStub(results: [.failure(.temporarilyUnavailable)])
        let store = makeQuizGenerationProgressStore(projectGeneration: projectGeneration)
        store.exhaustivity = .off

        await store.send(.submit(
            repository: sampleRepository,
            quizLevel: .l1,
        ))
        await store.receive(\.effect.submissionFinished)

        #expect(store.state.progress == .failed(.temporarilyUnavailable))
    }

    @Test
    func `retryTapped는 동일 입력으로 재제출한다`() async {
        let generationStates = ProjectGenerationStateStreamStub()
        let projectGeneration = ProjectGenerationUseCaseStub(
            results: [.failure(.temporarilyUnavailable), .success(sampleReceipt)],
            generationStates: generationStates,
        )
        let store = makeQuizGenerationProgressStore(projectGeneration: projectGeneration)
        store.exhaustivity = .off

        await store.send(.submit(
            repository: sampleRepository,
            quizLevel: .l3,
        ))
        await store.receive(\.effect.submissionFinished)
        #expect(store.state.progress == .failed(.temporarilyUnavailable))

        await store.send(.view(.retryTapped))
        await store.receive(\.effect.submissionFinished)

        #expect(store.state.progress == .awaitingOutcome(sampleReceipt))
        #expect(await projectGeneration.recordedRequests().count == 2)
        #expect(await projectGeneration.recordedRequests().allSatisfy { $0.quizLevel == .l3 })

        await generationStates.finish()
        await store.finish()
    }

    @Test
    func `failed가 아닌 상태의 retryTapped는 재제출하지 않는다`() async {
        let projectGeneration = ProjectGenerationUseCaseStub(results: [.success(sampleReceipt)])
        let store = makeQuizGenerationProgressStore(
            projectGeneration: projectGeneration,
            state: awaitingState(),
        )

        await store.send(.view(.retryTapped))

        #expect(await projectGeneration.recordedRequests().isEmpty)
    }

    @Test
    func `알림 권한이 이미 허용되어 있으면 시트 없이 바로 등록을 알린다`() async {
        let appSetting = AppSettingUseCaseStub(statuses: [.authorized])
        let store = makeQuizGenerationProgressStore(
            appSetting: appSetting,
            state: awaitingState(),
        )
        store.exhaustivity = .off

        await store.send(.view(.waitAtHomeTapped))
        await store.receive(.effect(.waitAtHomeAuthorizationChecked(.authorized)))
        await store.receive(.delegate(.generationReminderPreferenceSelected(isEnabled: true)))
        await store.receive(.delegate(.projectRegistered(sampleReceipt)))

        #expect(!store.state.isGenerationReminderSheetPresented)
    }

    @Test
    func `알림 권한이 없으면 리마인드 시트를 연다`() async {
        let appSetting = AppSettingUseCaseStub(statuses: [.notDetermined])
        let store = makeQuizGenerationProgressStore(
            appSetting: appSetting,
            state: awaitingState(),
        )
        store.exhaustivity = .off

        await store.send(.view(.waitAtHomeTapped))
        await store.receive(.effect(.waitAtHomeAuthorizationChecked(.notDetermined))) {
            $0.isGenerationReminderSheetPresented = true
        }
    }

    @Test
    func `알림 수락은 권한을 요청하고 리마인드 사용을 알린 뒤 등록을 알린다`() async {
        let appSetting = AppSettingUseCaseStub(
            statuses: [.notDetermined],
            requestedStatuses: [.authorized],
        )
        let openNotificationSettings = OpenNotificationSettingsSpy()
        var state = awaitingState()
        state.isGenerationReminderSheetPresented = true
        let store = makeQuizGenerationProgressStore(
            appSetting: appSetting,
            openNotificationSettings: openNotificationSettings,
            state: state,
        )
        store.exhaustivity = .off

        await store.send(.view(.generationReminderAccepted)) {
            $0.isGenerationReminderSheetPresented = false
        }
        await store.receive(.delegate(.generationReminderPreferenceSelected(isEnabled: true)))
        await store.receive(.delegate(.projectRegistered(sampleReceipt)))
        await store.finish()

        #expect(await appSetting.snapshot().authorizationRequestCount == 1)
        #expect(await openNotificationSettings.callCount == 0)
    }

    @Test
    func `권한 요청이 거부되면 설정 화면을 정확히 한 번 안내한다`() async {
        let appSetting = AppSettingUseCaseStub(
            statuses: [.denied],
            requestedStatuses: [.denied],
        )
        let openNotificationSettings = OpenNotificationSettingsSpy()
        var state = awaitingState()
        state.isGenerationReminderSheetPresented = true
        let store = makeQuizGenerationProgressStore(
            appSetting: appSetting,
            openNotificationSettings: openNotificationSettings,
            state: state,
        )
        store.exhaustivity = .off

        await store.send(.view(.generationReminderAccepted))
        await store.receive(.delegate(.generationReminderPreferenceSelected(isEnabled: true)))
        await store.receive(.delegate(.projectRegistered(sampleReceipt)))
        await store.finish()
        await waitUntil { await openNotificationSettings.callCount == 1 }

        #expect(await openNotificationSettings.callCount == 1)
    }

    @Test
    func `알림 거절은 리마인드 미사용을 알리고 등록을 알린다`() async {
        var state = awaitingState()
        state.isGenerationReminderSheetPresented = true
        let store = makeQuizGenerationProgressStore(state: state)
        store.exhaustivity = .off

        await store.send(.view(.generationReminderDeclined)) {
            $0.isGenerationReminderSheetPresented = false
        }
        await store.receive(.delegate(.generationReminderPreferenceSelected(isEnabled: false)))
        await store.receive(.delegate(.projectRegistered(sampleReceipt)))
    }

    @Test
    func `ready 단계를 받으면 리마인드 선택 없이 등록을 알린다`() async {
        let store = makeQuizGenerationProgressStore(state: awaitingState())
        store.exhaustivity = .off

        await store.send(.effect(.generationPhaseReceived(.ready)))
        await store.receive(.delegate(.projectRegistered(sampleReceipt)))
    }

    @Test
    func `진행 중 단계는 상태를 바꾸지 않는다`() async {
        let store = makeQuizGenerationProgressStore(state: awaitingState())

        await store.send(.effect(.generationPhaseReceived(.inProgress(readyAt: .distantFuture))))
        await store.send(.effect(.generationPhaseReceived(.preparing(readyAt: .distantFuture))))

        #expect(store.state.progress == .awaitingOutcome(sampleReceipt))
    }

    @Test
    func `failed 단계를 받으면 시트를 닫고 failed로 전이한다`() async {
        var state = awaitingState()
        state.isGenerationReminderSheetPresented = true
        let store = makeQuizGenerationProgressStore(state: state)

        await store.send(.effect(.generationPhaseReceived(.failed))) {
            $0.progress = .failed(.unexpected)
            $0.isGenerationReminderSheetPresented = false
        }
    }

    @Test
    func `대기 중이 아니면 단계 수신을 무시한다`() async {
        let store = makeQuizGenerationProgressStore()

        await store.send(.effect(.generationPhaseReceived(.ready)))

        #expect(store.state.progress == .idle)
    }

    @Test
    func `dismissTapped는 dismissRequested를 위임한다`() async {
        let store = makeQuizGenerationProgressStore()

        await store.send(.view(.dismissTapped))
        await store.receive(.delegate(.dismissRequested))
    }

    // MARK: Private

    private func awaitingState() -> QuizGenerationProgressFeature.State {
        var state = QuizGenerationProgressFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        return state
    }

}
