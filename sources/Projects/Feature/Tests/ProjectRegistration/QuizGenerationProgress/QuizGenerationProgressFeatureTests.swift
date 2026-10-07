import ComposableArchitecture
import DomainLearningProject
import Foundation
import Testing

@testable import Feature

@Suite("QuizGenerationProgressFeature")
struct QuizGenerationProgressFeatureTests {

    @Test
    func `submit 성공 시 createLearningProject가 검증된 canonicalURL과 선택된 QuizLevel로 정확히 한 번 호출된다`() async {
        let createLearningProject = StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)])
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let requestedAt = Date(timeIntervalSince1970: 1_000)
        let store = makeQuizGenerationProgressStore(
            createLearningProject: createLearningProject,
            observeGenerationOutcomes: observeGenerationOutcomes,
            now: { requestedAt },
        )

        await store.send(.submit(repository: sampleRepository, quizLevel: .l2)) {
            $0.repository = sampleRepository
            $0.quizLevel = .l2
            $0.progress = .submitting
            $0.requestedAt = requestedAt
        }
        await store.receive(.effect(.submissionFinished(.success(sampleReceipt)))) {
            $0.progress = .awaitingOutcome(sampleReceipt)
        }

        #expect(
            await createLearningProject.recordedCalls() == [
                StubCreateLearningProjectUseCase.Call(githubRepoURL: sampleRepository.canonicalURL, quizLevel: .l2)
            ]
        )

        await observeGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `submit은 요청 시각을 기록해 최소 대기 계산의 기준으로 남긴다`() async {
        let requestedAt = Date(timeIntervalSince1970: 1_000)
        let createLearningProject = StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)])
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let store = makeQuizGenerationProgressStore(
            createLearningProject: createLearningProject,
            observeGenerationOutcomes: observeGenerationOutcomes,
            now: { requestedAt },
        )

        await store.send(.submit(repository: sampleRepository, quizLevel: .l1)) {
            $0.repository = sampleRepository
            $0.progress = .submitting
            $0.requestedAt = requestedAt
        }
        await store.receive(.effect(.submissionFinished(.success(sampleReceipt)))) {
            $0.progress = .awaitingOutcome(sampleReceipt)
        }

        await observeGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `제출 자체 실패와 FCM 실패는 동일한 failed 표현을 쓴다`() async {
        let createLearningProject = StubCreateLearningProjectUseCase(results: [.failure(.temporarilyUnavailable)])
        let requestedAt = Date(timeIntervalSince1970: 1_000)
        let store = makeQuizGenerationProgressStore(
            createLearningProject: createLearningProject,
            now: { requestedAt },
        )

        await store.send(.submit(repository: sampleRepository, quizLevel: .l1)) {
            $0.repository = sampleRepository
            $0.progress = .submitting
            $0.requestedAt = requestedAt
        }
        await store.receive(.effect(.submissionFinished(.failure(.temporarilyUnavailable)))) {
            $0.progress = .failed(.temporarilyUnavailable)
        }
    }

    @Test
    func `retryTapped는 동일 입력으로 재제출한다`() async {
        let requestedAt = Date(timeIntervalSince1970: 1_000)
        let createLearningProject = StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)])
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        var state = QuizGenerationProgressFeature.State()
        state.repository = sampleRepository
        state.quizLevel = .l3
        state.progress = .failed(.unexpected)
        let store = makeQuizGenerationProgressStore(
            createLearningProject: createLearningProject,
            observeGenerationOutcomes: observeGenerationOutcomes,
            now: { requestedAt },
            state: state,
        )

        await store.send(.view(.retryTapped)) {
            $0.progress = .submitting
            $0.requestedAt = requestedAt
        }
        await store.receive(.effect(.submissionFinished(.success(sampleReceipt)))) {
            $0.progress = .awaitingOutcome(sampleReceipt)
        }

        #expect(
            await createLearningProject.recordedCalls() == [
                StubCreateLearningProjectUseCase.Call(githubRepoURL: sampleRepository.canonicalURL, quizLevel: .l3)
            ]
        )

        await observeGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `failed가 아닌 상태의 retryTapped는 재제출하지 않는다`() async {
        let createLearningProject = StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)])
        var state = QuizGenerationProgressFeature.State()
        state.repository = sampleRepository
        state.progress = .awaitingOutcome(sampleReceipt)
        let store = makeQuizGenerationProgressStore(createLearningProject: createLearningProject, state: state)

        await store.send(.view(.retryTapped))

        #expect(await createLearningProject.recordedCalls().isEmpty)
    }

    @Test
    func `waitAtHomeTapped는 알림 옵션이 꺼져 있으면 시트를 거친 뒤 projectRegistered를 정확히 한 번 출력한다`() async {
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let requestGenerationReminder = StubRequestGenerationReminderUseCase(
            results: [.authorized],
            isAuthorizedResult: false,
        )
        var state = QuizGenerationProgressFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        let store = makeQuizGenerationProgressStore(
            observeGenerationOutcomes: observeGenerationOutcomes,
            requestGenerationReminder: requestGenerationReminder,
            state: state,
        )

        await store.send(.view(.waitAtHomeTapped))
        await store.receive(.effect(.waitAtHomeAuthorizationChecked(isAuthorized: false))) {
            $0.isGenerationReminderSheetPresented = true
        }
        await store.send(.view(.generationReminderDeclined)) {
            $0.isGenerationReminderSheetPresented = false
        }
        await store.receive(.delegate(.generationReminderPreferenceSelected(isEnabled: false)))
        await store.receive(.delegate(.projectRegistered(sampleReceipt)))

        await observeGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `waitAtHomeTapped는 알림 권한이 이미 허용되어 있으면 시트 없이 바로 등록하고 projectRegistered를 출력한다`() async {
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let requestGenerationReminder = StubRequestGenerationReminderUseCase(
            results: [.authorized],
            isAuthorizedResult: true,
        )
        var state = QuizGenerationProgressFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        let store = makeQuizGenerationProgressStore(
            observeGenerationOutcomes: observeGenerationOutcomes,
            requestGenerationReminder: requestGenerationReminder,
            state: state,
        )

        await store.send(.view(.waitAtHomeTapped))
        await store.receive(.effect(.waitAtHomeAuthorizationChecked(isAuthorized: true)))
        await store.receive(.delegate(.generationReminderPreferenceSelected(isEnabled: true)))
        await store.receive(.delegate(.projectRegistered(sampleReceipt)))

        #expect(store.state.isGenerationReminderSheetPresented == false)
        #expect(await requestGenerationReminder.snapshot() == (1, sampleReceipt.projectID))

        await observeGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `알림 수락은 generationReminderPreferenceSelected true를 출력한 뒤 waitAtHome 동작을 이어간다`() async {
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        var state = QuizGenerationProgressFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        state.isGenerationReminderSheetPresented = true
        let store = makeQuizGenerationProgressStore(
            observeGenerationOutcomes: observeGenerationOutcomes,
            state: state,
        )

        await store.send(.view(.generationReminderAccepted)) {
            $0.isGenerationReminderSheetPresented = false
        }
        await store.receive(.delegate(.generationReminderPreferenceSelected(isEnabled: true)))
        await store.receive(.delegate(.projectRegistered(sampleReceipt)))

        await observeGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `권한이 허용되면 설정 화면 안내 없이 기존 waitAtHome 동작이 유지된다`() async {
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let requestGenerationReminder = StubRequestGenerationReminderUseCase(results: [.authorized])
        let openNotificationSettings = OpenNotificationSettingsSpy()
        var state = QuizGenerationProgressFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        state.isGenerationReminderSheetPresented = true
        let store = makeQuizGenerationProgressStore(
            observeGenerationOutcomes: observeGenerationOutcomes,
            requestGenerationReminder: requestGenerationReminder,
            openNotificationSettings: openNotificationSettings,
            state: state,
        )

        await store.send(.view(.generationReminderAccepted)) {
            $0.isGenerationReminderSheetPresented = false
        }
        await store.receive(.delegate(.generationReminderPreferenceSelected(isEnabled: true)))
        await store.receive(.delegate(.projectRegistered(sampleReceipt)))

        #expect(await requestGenerationReminder.snapshot() == (1, sampleReceipt.projectID))
        #expect(await openNotificationSettings.callCount == 0)

        await observeGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `권한을 방금 거부해도 설정 화면을 안내하지 않는다`() async {
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let requestGenerationReminder = StubRequestGenerationReminderUseCase(results: [.declined])
        let openNotificationSettings = OpenNotificationSettingsSpy()
        var state = QuizGenerationProgressFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        state.isGenerationReminderSheetPresented = true
        let store = makeQuizGenerationProgressStore(
            observeGenerationOutcomes: observeGenerationOutcomes,
            requestGenerationReminder: requestGenerationReminder,
            openNotificationSettings: openNotificationSettings,
            state: state,
        )

        await store.send(.view(.generationReminderAccepted)) {
            $0.isGenerationReminderSheetPresented = false
        }
        await store.receive(.delegate(.generationReminderPreferenceSelected(isEnabled: true)))
        await store.receive(.delegate(.projectRegistered(sampleReceipt)))

        #expect(await requestGenerationReminder.snapshot() == (1, sampleReceipt.projectID))
        #expect(await openNotificationSettings.callCount == 0)

        await observeGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `권한이 이미 거부된 상태면 설정 화면을 정확히 한 번 안내한다`() async {
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let requestGenerationReminder = StubRequestGenerationReminderUseCase(results: [.previouslyDenied])
        let openNotificationSettings = OpenNotificationSettingsSpy()
        var state = QuizGenerationProgressFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        state.isGenerationReminderSheetPresented = true
        let store = makeQuizGenerationProgressStore(
            observeGenerationOutcomes: observeGenerationOutcomes,
            requestGenerationReminder: requestGenerationReminder,
            openNotificationSettings: openNotificationSettings,
            state: state,
        )

        await store.send(.view(.generationReminderAccepted)) {
            $0.isGenerationReminderSheetPresented = false
        }
        await store.receive(.delegate(.generationReminderPreferenceSelected(isEnabled: true)))
        await store.receive(.delegate(.projectRegistered(sampleReceipt)))

        #expect(await requestGenerationReminder.snapshot() == (1, sampleReceipt.projectID))
        #expect(await openNotificationSettings.callCount == 1)

        await observeGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `awaitingOutcome 중 일치하는 projectID의 completed 수신은 projectRegistered를 출력한다`() async {
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let createLearningProject = StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)])
        let store = makeQuizGenerationProgressStore(
            createLearningProject: createLearningProject,
            observeGenerationOutcomes: observeGenerationOutcomes,
        )
        store.exhaustivity = .off

        await store.send(.submit(repository: sampleRepository, quizLevel: .l1))
        await store.receive(.effect(.submissionFinished(.success(sampleReceipt))))

        await observeGenerationOutcomes.emit(
            GenerationOutcome(projectID: sampleReceipt.projectID, status: .completed)
        )
        await store.receive(
            .effect(.generationOutcomeReceived(
                GenerationOutcome(projectID: sampleReceipt.projectID, status: .completed)
            ))
        )
        await store.receive(.delegate(.projectRegistered(sampleReceipt)))

        await observeGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `일치하지 않는 projectID의 이벤트는 무시된다`() async {
        var state = QuizGenerationProgressFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        let store = makeQuizGenerationProgressStore(state: state)

        await store.send(
            .effect(.generationOutcomeReceived(GenerationOutcome(projectID: "other-project", status: .completed)))
        )

        #expect(store.state.progress == .awaitingOutcome(sampleReceipt))
    }

    @Test
    func `failed 이벤트 수신 시 submission이 failed로 전이한다`() async {
        var state = QuizGenerationProgressFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        let store = makeQuizGenerationProgressStore(state: state)

        await store.send(
            .effect(.generationOutcomeReceived(
                GenerationOutcome(projectID: sampleReceipt.projectID, status: .failed)
            ))
        ) {
            $0.progress = .failed(.unexpected)
        }
    }

    @Test
    func `준비 완료 시각 전에 도착한 완료 결과는 보류되었다가 대기가 끝나면 전이한다`() async {
        let requestedAt = Date(timeIntervalSince1970: 1_000)
        let outcome = GenerationOutcome(projectID: sampleReceipt.projectID, status: .completed)
        var state = QuizGenerationProgressFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        state.requestedAt = requestedAt
        let store = makeQuizGenerationProgressStore(
            waitPolicy: GenerationWaitPolicy(minimumWait: 0.05, retentionLimit: 60),
            now: { requestedAt },
            state: state,
        )

        await store.send(.effect(.generationOutcomeReceived(outcome))) {
            $0.pendingOutcome = outcome
        }
        #expect(store.state.progress == .awaitingOutcome(sampleReceipt))

        await store.receive(\.effect.minimumWaitElapsed, timeout: .seconds(5)) {
            $0.pendingOutcome = nil
        }
        await store.receive(.delegate(.projectRegistered(sampleReceipt)))
        await store.finish()
    }

    @Test
    func `준비 완료 시각 전에 도착한 실패 결과도 같은 게이트를 따른다`() async {
        let requestedAt = Date(timeIntervalSince1970: 1_000)
        let outcome = GenerationOutcome(projectID: sampleReceipt.projectID, status: .failed)
        var state = QuizGenerationProgressFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        state.requestedAt = requestedAt
        let store = makeQuizGenerationProgressStore(
            waitPolicy: GenerationWaitPolicy(minimumWait: 0.05, retentionLimit: 60),
            now: { requestedAt },
            state: state,
        )

        await store.send(.effect(.generationOutcomeReceived(outcome))) {
            $0.pendingOutcome = outcome
        }
        #expect(store.state.progress == .awaitingOutcome(sampleReceipt))

        await store.receive(\.effect.minimumWaitElapsed, timeout: .seconds(5)) {
            $0.pendingOutcome = nil
            $0.progress = .failed(.unexpected)
        }
        await store.finish()
    }

    @Test
    func `준비 완료 시각이 이미 지난 뒤 도착한 결과는 추가 지연 없이 전이한다`() async {
        let requestedAt = Date(timeIntervalSince1970: 1_000)
        let outcome = GenerationOutcome(projectID: sampleReceipt.projectID, status: .completed)
        var state = QuizGenerationProgressFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        state.requestedAt = requestedAt
        let store = makeQuizGenerationProgressStore(
            waitPolicy: GenerationWaitPolicy(minimumWait: 300, retentionLimit: 3_600),
            now: { requestedAt.addingTimeInterval(301) },
            state: state,
        )

        await store.send(.effect(.generationOutcomeReceived(outcome)))
        await store.receive(.delegate(.projectRegistered(sampleReceipt)))
        await store.finish()
    }

    @Test
    func `생성 요청이 전송되는 시점에 생성 결과 구독이 이미 확립돼 있다`() async {
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let createLearningProject = StubCreateLearningProjectUseCase(
            results: [.success(sampleReceipt)],
            suspendsRequests: true,
        )
        let store = makeQuizGenerationProgressStore(
            createLearningProject: createLearningProject,
            observeGenerationOutcomes: observeGenerationOutcomes,
        )
        store.exhaustivity = .off

        await store.send(.submit(repository: sampleRepository, quizLevel: .l1))
        await waitUntil { await createLearningProject.recordedCalls().count == 1 }

        #expect(await observeGenerationOutcomes.hasEstablishedSubscription())

        await createLearningProject.resumeOldest()
        await observeGenerationOutcomes.finish()
        await store.skipReceivedActions()
    }

    @Test
    func `생성 요청 응답보다 먼저 도착한 완료 결과가 진행 화면에 반영된다`() async {
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let createLearningProject = StubCreateLearningProjectUseCase(
            results: [.success(sampleReceipt)],
            suspendsRequests: true,
        )
        let store = makeQuizGenerationProgressStore(
            createLearningProject: createLearningProject,
            observeGenerationOutcomes: observeGenerationOutcomes,
        )
        store.exhaustivity = .off

        await store.send(.submit(repository: sampleRepository, quizLevel: .l1))
        await waitUntil { await createLearningProject.recordedCalls().count == 1 }

        await observeGenerationOutcomes.emit(GenerationOutcome(projectID: "project-1", status: .completed))
        await createLearningProject.resumeOldest()

        await store.receive(.delegate(.projectRegistered(sampleReceipt)))
        await observeGenerationOutcomes.finish()
        await store.skipReceivedActions()
    }

    @Test
    func `같은 프로젝트의 완료 결과를 2회 수신해도 상태와 delegate 전달이 1회 수신과 같다`() async {
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let store = makeQuizGenerationProgressStore(
            createLearningProject: StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)]),
            observeGenerationOutcomes: observeGenerationOutcomes,
        )
        store.exhaustivity = .off

        await store.send(.submit(repository: sampleRepository, quizLevel: .l1))
        await waitUntil { await observeGenerationOutcomes.hasEstablishedSubscription() }

        await observeGenerationOutcomes.emit(GenerationOutcome(projectID: "project-1", status: .completed))
        await observeGenerationOutcomes.emit(GenerationOutcome(projectID: "project-1", status: .completed))
        await observeGenerationOutcomes.finish()

        await store.receive(.delegate(.projectRegistered(sampleReceipt)))

        await store.finish()

        #expect(await observeGenerationOutcomes.establishedSubscriptionCount() == 1)
    }

    @Test
    func `리마인드 시트 표시 중 생성 실패가 도착하면 시트가 닫히고 재시도가 가능해진다`() async {
        var state = QuizGenerationProgressFeature.State()
        state.repository = sampleRepository
        state.progress = .awaitingOutcome(sampleReceipt)
        state.isGenerationReminderSheetPresented = true
        let store = makeQuizGenerationProgressStore(
            createLearningProject: StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)]),
            state: state,
        )
        store.exhaustivity = .off

        await store.send(
            .effect(.generationOutcomeReceived(GenerationOutcome(projectID: "project-1", status: .failed)))
        ) {
            $0.progress = .failed(.unexpected)
            $0.isGenerationReminderSheetPresented = false
        }

        await store.send(.view(.retryTapped)) {
            $0.progress = .submitting
        }
        await store.skipReceivedActions()
        await store.finish()
    }

    @Test
    func `dismissTapped는 dismissRequested를 위임한다`() async {
        let store = makeQuizGenerationProgressStore()

        await store.send(.view(.dismissTapped))
        await store.receive(.delegate(.dismissRequested))
    }

    @Test
    func `State가 폐기되면 진행 중이던 제출 Effect가 취소되고 이후 이벤트를 받지 않는다`() async {
        let createLearningProject = StubCreateLearningProjectUseCase(suspendsRequests: true)
        let store = TestStore(
            initialState: QuizGenerationProgressHostFeature.State(child: QuizGenerationProgressFeature.State())
        ) {
            QuizGenerationProgressHostFeature(
                createLearningProject: createLearningProject,
                observeGenerationOutcomes: StubObserveGenerationOutcomesUseCase(),
            )
        }
        store.exhaustivity = .off

        await store.send(.child(.presented(.submit(repository: sampleRepository, quizLevel: .l1)))) {
            $0.child?.progress = .submitting
        }
        await store.send(.child(.dismiss)) {
            $0.child = nil
        }
        await createLearningProject.resumeOldest()

        await store.finish()
    }

}

@Reducer
private struct QuizGenerationProgressHostFeature {

    @ObservableState
    struct State: Equatable {
        @Presents var child: QuizGenerationProgressFeature.State?
    }

    enum Action {
        case child(PresentationAction<QuizGenerationProgressFeature.Action>)
    }

    let createLearningProject: any CreateLearningProjectUseCase
    let observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase

    var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
            .ifLet(\.$child, action: \.child) {
                QuizGenerationProgressFeature(
                    createLearningProject: createLearningProject,
                    observeGenerationOutcomes: observeGenerationOutcomes,
                    requestGenerationReminder: StubRequestGenerationReminderUseCase(results: [.authorized]),
                )
            }
    }

}
