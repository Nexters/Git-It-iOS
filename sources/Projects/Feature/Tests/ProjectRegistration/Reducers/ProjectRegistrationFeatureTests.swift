import ComposableArchitecture
import DomainLearningProject
import Foundation
import Testing

@testable import Feature

// MARK: - ProjectRegistrationFeatureTests

@Suite("ProjectRegistrationFeature")
struct ProjectRegistrationFeatureTests {

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
    func `submitting 중 중복 submitTapped는 차단된다`() async {
        let createLearningProject = StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)])
        var state = ProjectRegistrationFeature.State()
        state.validation = .validated(sampleRepository)
        state.progress = .submitting
        let store = makeProjectRegistrationStore(createLearningProject: createLearningProject, state: state)

        await store.send(.view(.submitTapped))

        #expect(await createLearningProject.recordedCalls().isEmpty)
    }

    @Test
    func `submitTapped 성공 시 createLearningProject가 검증된 canonicalURL과 선택된 QuizLevel로 정확히 한 번 호출된다`() async {
        let createLearningProject = StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)])
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        var state = ProjectRegistrationFeature.State()
        state.validation = .validated(sampleRepository)
        state.quizLevel = .l2
        let store = makeProjectRegistrationStore(
            createLearningProject: createLearningProject,
            observeGenerationOutcomes: observeGenerationOutcomes,
            state: state,
        )

        await store.send(.view(.submitTapped)) {
            $0.progress = .submitting
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
    func `waitAtHomeTapped는 알림 옵션이 꺼져 있으면 시트를 거친 뒤 projectRegistered를 정확히 한 번 출력한다`() async {
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        var state = ProjectRegistrationFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        let store = makeProjectRegistrationStore(
            observeGenerationOutcomes: observeGenerationOutcomes,
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
        var state = ProjectRegistrationFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        let store = makeProjectRegistrationStore(
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
    func `awaitingOutcome 중 일치하는 projectID의 completed 수신은 projectRegistered를 출력한다`() async {
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let createLearningProject = StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)])
        var state = ProjectRegistrationFeature.State()
        state.validation = .validated(sampleRepository)
        let store = makeProjectRegistrationStore(
            createLearningProject: createLearningProject,
            observeGenerationOutcomes: observeGenerationOutcomes,
            state: state,
        )

        await store.send(.view(.submitTapped)) {
            $0.progress = .submitting
        }
        await store.receive(.effect(.submissionFinished(.success(sampleReceipt)))) {
            $0.progress = .awaitingOutcome(sampleReceipt)
        }

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
    func `준비 완료 시각 전에 도착한 완료 결과는 보류되었다가 대기가 끝나면 전이한다`() async {
        let requestedAt = Date(timeIntervalSince1970: 1_000)
        let outcome = GenerationOutcome(projectID: sampleReceipt.projectID, status: .completed)
        var state = ProjectRegistrationFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        state.requestedAt = requestedAt
        let store = makeProjectRegistrationStore(
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
        var state = ProjectRegistrationFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        state.requestedAt = requestedAt
        let store = makeProjectRegistrationStore(
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
        var state = ProjectRegistrationFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        state.requestedAt = requestedAt
        let store = makeProjectRegistrationStore(
            waitPolicy: GenerationWaitPolicy(minimumWait: 300, retentionLimit: 3_600),
            now: { requestedAt.addingTimeInterval(301) },
            state: state,
        )

        await store.send(.effect(.generationOutcomeReceived(outcome)))
        await store.receive(.delegate(.projectRegistered(sampleReceipt)))
        await store.finish()
    }

    @Test
    func `submitTapped는 요청 시각을 기록해 최소 대기 계산의 기준으로 남긴다`() async {
        let requestedAt = Date(timeIntervalSince1970: 1_000)
        let createLearningProject = StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)])
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        var state = ProjectRegistrationFeature.State()
        state.validation = .validated(sampleRepository)
        let store = makeProjectRegistrationStore(
            createLearningProject: createLearningProject,
            observeGenerationOutcomes: observeGenerationOutcomes,
            now: { requestedAt },
            state: state,
        )

        await store.send(.view(.submitTapped)) {
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
    func `일치하지 않는 projectID의 이벤트는 무시된다`() async {
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        var state = ProjectRegistrationFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        let store = makeProjectRegistrationStore(
            observeGenerationOutcomes: observeGenerationOutcomes,
            state: state,
        )

        await observeGenerationOutcomes.emit(
            GenerationOutcome(projectID: "other-project", status: .completed)
        )
        await store.receive(
            .effect(.generationOutcomeReceived(
                GenerationOutcome(projectID: "other-project", status: .completed)
            ))
        )

        #expect(store.state.progress == .awaitingOutcome(sampleReceipt))

        await observeGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `failed 이벤트 수신 시 submission이 failed로 전이한다`() async {
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        var state = ProjectRegistrationFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        let store = makeProjectRegistrationStore(
            observeGenerationOutcomes: observeGenerationOutcomes,
            state: state,
        )

        await observeGenerationOutcomes.emit(
            GenerationOutcome(projectID: sampleReceipt.projectID, status: .failed)
        )
        await store.receive(
            .effect(.generationOutcomeReceived(
                GenerationOutcome(projectID: sampleReceipt.projectID, status: .failed)
            ))
        ) {
            $0.progress = .failed(.unexpected)
        }

        await observeGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `제출 자체 실패와 FCM 실패는 동일한 failed 표현을 쓴다`() async {
        let createLearningProject = StubCreateLearningProjectUseCase(results: [.failure(.temporarilyUnavailable)])
        var state = ProjectRegistrationFeature.State()
        state.validation = .validated(sampleRepository)
        let store = makeProjectRegistrationStore(createLearningProject: createLearningProject, state: state)

        await store.send(.view(.submitTapped)) {
            $0.progress = .submitting
        }
        await store.receive(.effect(.submissionFinished(.failure(.temporarilyUnavailable)))) {
            $0.progress = .failed(.temporarilyUnavailable)
        }
    }

    @Test
    func `retryTapped는 동일 입력으로 재제출한다`() async {
        let createLearningProject = StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)])
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        var state = ProjectRegistrationFeature.State()
        state.validation = .validated(sampleRepository)
        state.quizLevel = .l3
        state.progress = .failed(.unexpected)
        let store = makeProjectRegistrationStore(
            createLearningProject: createLearningProject,
            observeGenerationOutcomes: observeGenerationOutcomes,
            state: state,
        )

        await store.send(.view(.retryTapped)) {
            $0.progress = .submitting
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
    func `알림 수락은 generationReminderPreferenceSelected accepted true를 출력한 뒤 waitAtHomeTapped 동작을 이어간다`() async {
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        var state = ProjectRegistrationFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        state.isGenerationReminderSheetPresented = true
        let store = makeProjectRegistrationStore(
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
        var state = ProjectRegistrationFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        state.isGenerationReminderSheetPresented = true
        let store = makeProjectRegistrationStore(
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
        var state = ProjectRegistrationFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        state.isGenerationReminderSheetPresented = true
        let store = makeProjectRegistrationStore(
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
        var state = ProjectRegistrationFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        state.isGenerationReminderSheetPresented = true
        let store = makeProjectRegistrationStore(
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
    func `알림 옵션 선택은 상태 전이 자체에 영향을 주지 않는다`() async {
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        var state = ProjectRegistrationFeature.State()
        state.progress = .awaitingOutcome(sampleReceipt)
        state.isGenerationReminderSheetPresented = true
        let store = makeProjectRegistrationStore(
            observeGenerationOutcomes: observeGenerationOutcomes,
            state: state,
        )
        store.exhaustivity = .off

        await store.send(.view(.generationReminderDeclined))

        #expect(store.state.repositoryURLInput.isEmpty)
        #expect(store.state.quizLevel == .l1)

        await observeGenerationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `State가 폐기되면 진행 중이던 검증 Effect가 취소되고 이후 이벤트를 받지 않는다`() async {
        let fetchExternalRepository = StubFetchExternalRepositoryUseCase(suspendsRequests: true)
        var childState = ProjectRegistrationFeature.State()
        childState.repositoryURLInput = "https://github.com/owner/repo"
        let store = TestStore(initialState: ProjectRegistrationHostFeature.State(child: childState)) {
            ProjectRegistrationHostFeature(
                fetchExternalRepository: fetchExternalRepository,
                createLearningProject: StubCreateLearningProjectUseCase(),
                observeGenerationOutcomes: StubObserveGenerationOutcomesUseCase(),
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
                observeGenerationOutcomes: StubObserveGenerationOutcomesUseCase(),
            )
        }

        await store.send(.child(.presented(.view(.submitTapped)))) {
            $0.child?.progress = .submitting
        }
        await store.send(.child(.dismiss)) {
            $0.child = nil
        }
        await createLearningProject.resumeOldest()

        await store.finish()
    }

    @Test
    func `생성 요청이 전송되는 시점에 생성 결과 구독이 이미 확립돼 있다`() async {
        let observeGenerationOutcomes = StubObserveGenerationOutcomesUseCase()
        let createLearningProject = StubCreateLearningProjectUseCase(
            results: [.success(sampleReceipt)],
            suspendsRequests: true,
        )
        let store = makeProjectRegistrationStore(
            createLearningProject: createLearningProject,
            observeGenerationOutcomes: observeGenerationOutcomes,
            state: validatedState(),
        )
        store.exhaustivity = .off

        await store.send(.view(.submitTapped))
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
        let store = makeProjectRegistrationStore(
            createLearningProject: createLearningProject,
            observeGenerationOutcomes: observeGenerationOutcomes,
            state: validatedState(),
        )
        store.exhaustivity = .off

        await store.send(.view(.submitTapped))
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
        let store = makeProjectRegistrationStore(
            createLearningProject: StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)]),
            observeGenerationOutcomes: observeGenerationOutcomes,
            state: validatedState(),
        )
        store.exhaustivity = .off

        await store.send(.view(.submitTapped))
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
        let store = makeProjectRegistrationStore(
            createLearningProject: StubCreateLearningProjectUseCase(results: [.success(sampleReceipt)]),
            state: {
                var state = validatedState()
                state.progress = .awaitingOutcome(sampleReceipt)
                state.isGenerationReminderSheetPresented = true
                return state
            }(),
        )
        store.exhaustivity = .off

        await store.send(.effect(.generationOutcomeReceived(GenerationOutcome(projectID: "project-1", status: .failed)))) {
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
    func `저장소 확인과 이해도 선택 단계는 Feature 상태로 유지되고 역방향 전이도 가능하다`() async {
        let store = makeProjectRegistrationStore(state: validatedState())

        await store.send(.view(.repositoryConfirmed)) {
            $0.step = .quizLevelSelection
        }
        await store.send(.view(.quizLevelConfirmed)) {
            $0.step = .generationConfirmation
        }
        await store.send(.view(.stepBackTapped)) {
            $0.step = .quizLevelSelection
        }
        await store.send(.view(.stepBackTapped)) {
            $0.step = .repositoryConfirmation
        }
        await store.send(.view(.stepBackTapped))
    }

    @Test
    func `공유 초기값이 있으면 task가 검증을 1회 자동 시작한다`() async {
        let fetchExternalRepository = StubFetchExternalRepositoryUseCase(results: [.success(sampleRepository)])
        let store = makeProjectRegistrationStore(
            fetchExternalRepository: fetchExternalRepository,
            state: ProjectRegistrationFeature.State(initialRepositoryURL: "https://github.com/owner/repo"),
        )

        await store.send(.view(.task)) {
            $0.pendingAutomaticValidation = false
            $0.validation = .validating
            $0.validationRequestID = 1
        }
        await store.receive(.effect(.validationFinished(requestID: 1, result: .success(sampleRepository)))) {
            $0.validation = .validated(sampleRepository)
        }

        #expect(await fetchExternalRepository.snapshot().callCount == 1)
    }

    @Test
    func `공유 초기값이 없으면 task가 검증을 시작하지 않는다`() async {
        let fetchExternalRepository = StubFetchExternalRepositoryUseCase(results: [.success(sampleRepository)])
        let store = makeProjectRegistrationStore(fetchExternalRepository: fetchExternalRepository)

        await store.send(.view(.task))

        #expect(await fetchExternalRepository.snapshot().callCount == 0)
    }

    @Test
    func `task를 두 번 보내도 자동 검증은 1회만 시작한다`() async {
        let fetchExternalRepository = StubFetchExternalRepositoryUseCase(results: [.success(sampleRepository)])
        let store = makeProjectRegistrationStore(
            fetchExternalRepository: fetchExternalRepository,
            state: ProjectRegistrationFeature.State(initialRepositoryURL: "https://github.com/owner/repo"),
        )

        await store.send(.view(.task)) {
            $0.pendingAutomaticValidation = false
            $0.validation = .validating
            $0.validationRequestID = 1
        }
        await store.receive(.effect(.validationFinished(requestID: 1, result: .success(sampleRepository)))) {
            $0.validation = .validated(sampleRepository)
        }
        await store.send(.view(.task))

        #expect(await fetchExternalRepository.snapshot().callCount == 1)
    }

    @Test
    func `자동 검증 실패도 직접 누른 경우와 같은 failed 상태로 전이한다`() async {
        let fetchExternalRepository = StubFetchExternalRepositoryUseCase(results: [.failure(.invalidURLFormat)])
        let store = makeProjectRegistrationStore(
            fetchExternalRepository: fetchExternalRepository,
            state: ProjectRegistrationFeature.State(initialRepositoryURL: "https://example.com/article"),
        )

        await store.send(.view(.task)) {
            $0.pendingAutomaticValidation = false
            $0.validation = .validating
            $0.validationRequestID = 1
        }
        await store.receive(.effect(.validationFinished(requestID: 1, result: .failure(.invalidURLFormat)))) {
            $0.validation = .failed
        }
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

private func validatedState() -> ProjectRegistrationFeature.State {
    var state = ProjectRegistrationFeature.State()
    state.validation = .validated(sampleRepository)
    return state
}

private func waitUntil(
    timeout: Duration = .seconds(2),
    _ condition: @Sendable () async -> Bool,
) async {
    let deadline = ContinuousClock.now.advanced(by: timeout)
    while ContinuousClock.now < deadline {
        if await condition() {
            return
        }
        try? await Task.sleep(for: .milliseconds(1))
    }
}

private func makeProjectRegistrationStore(
    fetchExternalRepository: StubFetchExternalRepositoryUseCase = StubFetchExternalRepositoryUseCase(),
    createLearningProject: StubCreateLearningProjectUseCase = StubCreateLearningProjectUseCase(),
    observeGenerationOutcomes: StubObserveGenerationOutcomesUseCase = StubObserveGenerationOutcomesUseCase(),
    requestGenerationReminder: StubRequestGenerationReminderUseCase =
        StubRequestGenerationReminderUseCase(results: [.authorized]),
    openNotificationSettings: OpenNotificationSettingsSpy = OpenNotificationSettingsSpy(),
    waitPolicy: GenerationWaitPolicy = .standard,
    now: @escaping @Sendable () -> Date = { Date() },
    state: ProjectRegistrationFeature.State = ProjectRegistrationFeature.State(),
) -> TestStoreOf<ProjectRegistrationFeature> {
    TestStore(initialState: state) {
        ProjectRegistrationFeature(
            fetchExternalRepository: fetchExternalRepository,
            createLearningProject: createLearningProject,
            observeGenerationOutcomes: observeGenerationOutcomes,
            requestGenerationReminder: requestGenerationReminder,
            openNotificationSettings: { await openNotificationSettings() },
            waitPolicy: waitPolicy,
            now: now,
        )
    }
}

// MARK: - OpenNotificationSettingsSpy

private actor OpenNotificationSettingsSpy {
    private(set) var callCount = 0

    func callAsFunction() {
        callCount += 1
    }
}

// MARK: - ProjectRegistrationHostFeature

@Reducer
private struct ProjectRegistrationHostFeature {

    @ObservableState
    struct State: Equatable {
        @Presents var child: ProjectRegistrationFeature.State?
    }

    enum Action {
        case child(PresentationAction<ProjectRegistrationFeature.Action>)
    }

    let fetchExternalRepository: any FetchExternalRepositoryUseCase
    let createLearningProject: any CreateLearningProjectUseCase
    let observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase

    var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
            .ifLet(\.$child, action: \.child) {
                ProjectRegistrationFeature(
                    fetchExternalRepository: fetchExternalRepository,
                    createLearningProject: createLearningProject,
                    observeGenerationOutcomes: observeGenerationOutcomes,
                    requestGenerationReminder: StubRequestGenerationReminderUseCase(results: [.authorized]),
                )
            }
    }

}
