import ComposableArchitecture
import DomainAuthentication
import DomainLearningProject
import Feature
import Foundation
import Testing

@testable import GitIt

// MARK: - AppRootFeatureTests

@Suite("AppRootFeature root 전환")
struct AppRootFeatureTests {

    // MARK: Internal

    @Test
    func `launch task는 route를 즉시 바꾸지 않고 appEntry task를 전달한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.recoverableFailure])
        let authenticationOutcomes = AuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(restoreSession: restoreSession, authenticationOutcomes: authenticationOutcomes)
        store.exhaustivity = .off

        #expect(store.state.route == .restoring)

        await store.send(.view(.task))
        #expect(store.state.route == .restoring)
        #expect(store.state.appEntry.authentication == .retryableFailure)

        await authenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `미인증 세션은 route를 onboarding으로 전환하고 온보딩 안내부터 시작한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let authenticationOutcomes = AuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(restoreSession: restoreSession, authenticationOutcomes: authenticationOutcomes)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }

        await authenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `인증됐지만 프로필이 미완료면 route를 onboarding으로 전환하고 큐레이션부터 시작한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.authenticated(AppRootTestFixture.authenticatedUser)])
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(results: [.success(AppRootTestFixture.incompleteProfile)])
        let authenticationOutcomes = AuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(
            restoreSession: restoreSession,
            fetchMemberProfile: fetchMemberProfile,
            authenticationOutcomes: authenticationOutcomes,
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .curation, bundleVersion: "1.0.0")
        }

        await authenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `인증됐고 프로필이 완료면 route를 mainShell로 전환한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.authenticated(AppRootTestFixture.authenticatedUser)])
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(results: [.success(AppRootTestFixture.completeProfile)])
        let authenticationOutcomes = AuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(
            restoreSession: restoreSession,
            fetchMemberProfile: fetchMemberProfile,
            authenticationOutcomes: authenticationOutcomes,
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .mainShell
        }

        await authenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `복원 가능한 실패는 route를 바꾸지 않고 재시도하면 목적지를 결정한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.recoverableFailure, .unauthenticated])
        let authenticationOutcomes = AuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(restoreSession: restoreSession, authenticationOutcomes: authenticationOutcomes)
        store.exhaustivity = .off

        await store.send(.view(.task))
        #expect(store.state.route == .restoring)
        #expect(store.state.appEntry.isShowingRecoverableError)

        await store.send(.appEntry(.view(.retryTapped)))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }

        await authenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `restoring을 벗어난 뒤 반복 task는 appEntry task를 다시 전달하지 않는다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let authenticationOutcomes = AuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(restoreSession: restoreSession, authenticationOutcomes: authenticationOutcomes)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }
        await store.send(.view(.task))

        #expect(await restoreSession.snapshot() == 1)

        await authenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `onboarding delegate mainShellRequested는 route를 mainShell로 전환한다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .onboarding
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(.onboarding(.delegate(.mainShellRequested))) {
            $0.route = .mainShell
        }
    }

    @Test
    func `mainShell logout delegate는 onboarding 안내부터 다시 시작한다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(.mainShell(.delegate(.loggedOut))) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }
    }

    @Test
    func `로그아웃·세션 무효화·초기화 뒤 재생성된 MainShell은 다음 진입에서 Home 기본으로 시작한다`() async {
        var loggedOutState = AppRootFeature.State(bundleVersion: "1.0.0")
        loggedOutState.route = .mainShell
        loggedOutState.mainShell.selectedTab = .settings
        let loggedOutStore = makeAppRootStore(state: loggedOutState)
        loggedOutStore.exhaustivity = .off

        await loggedOutStore.send(.mainShell(.delegate(.loggedOut))) {
            $0.route = .onboarding
            $0.mainShell = MainShellRouterFeature.State()
        }
        await loggedOutStore.send(.onboarding(.delegate(.mainShellRequested))) {
            $0.route = .mainShell
        }
        #expect(loggedOutStore.state.mainShell.selectedTab == .home)
        #expect(loggedOutStore.state.mainShell.home == HomeFeature.State())

        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let authenticationOutcomes = AuthenticationOutcomesUseCaseMock()
        var sessionState = AppRootFeature.State(bundleVersion: "1.0.0")
        sessionState.route = .mainShell
        sessionState.mainShell.selectedTab = .projects
        let sessionStore = makeAppRootStore(
            restoreSession: restoreSession,
            authenticationOutcomes: authenticationOutcomes,
            state: sessionState,
        )
        sessionStore.exhaustivity = .off

        await authenticationOutcomes.emit(.unauthenticated)
        await sessionStore.receive(.effect(.authenticationOutcomeReceived(.unauthenticated))) {
            $0.route = .onboarding
            $0.mainShell = MainShellRouterFeature.State()
        }
        await sessionStore.send(.onboarding(.delegate(.mainShellRequested))) {
            $0.route = .mainShell
        }
        #expect(sessionStore.state.mainShell.selectedTab == .home)
        #expect(sessionStore.state.mainShell.home == HomeFeature.State())

        await authenticationOutcomes.finish()
        await sessionStore.finish()
    }

    @Test
    func `MainShell의 등록·ProjectDetail delegate는 payload를 보존하며 route와 MainShell 상태를 바꾸지 않는다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(.mainShell(.delegate(.projectRegistrationRequested)))
        #expect(store.state.route == .mainShell)
        #expect(store.state.mainShell == MainShellRouterFeature.State())

        await store.send(.mainShell(.delegate(.projectDetailRequested(projectID: "project-1"))))
        #expect(store.state.route == .mainShell)
        #expect(store.state.mainShell == MainShellRouterFeature.State())
    }

    @Test
    func `Home 학습 요청은 일치하는 프로젝트가 없으면 풀이 흐름을 열지 않는다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(
            .mainShell(
                .delegate(
                    .learningRequested(projectID: "project-1", nextSetID: "set-1")
                )
            )
        )
        #expect(store.state.quiz == nil)
    }

    @Test
    func `프로젝트 목록의 학습 요청은 상세 위에 그 세트의 풀이 흐름을 연다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        state.mainShell.projectList.projects = [
            LearningProjectSummary(
                projectID: "project-1",
                repositoryName: "repo",
                repositoryImageURL: nil,
                techStack: ["Swift"],
                currentSetLabel: "Set 1",
                currentSetTitle: "Basics",
                nextSetID: "set-1",
                nextQuestionID: "question-1",
                overallProgressPercent: 0,
            )
        ]
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(
            .mainShell(
                .delegate(
                    .learningRequested(projectID: "project-1", nextSetID: "set-1")
                )
            )
        )

        #expect(store.state.quiz?.projectID == "project-1")
        #expect(store.state.quiz?.setID == "set-1")
        #expect(store.state.quiz?.setLabel == "Set 1")
        #expect(store.state.projectDetail?.projectID == "project-1")
    }

    @Test
    func `Home 학습 요청은 일치하는 프로젝트가 있으면 그 세트의 풀이 흐름을 연다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        state.mainShell.home.projectLoad = .loaded(
            LearningProjectPage(
                items: [
                    LearningProjectSummary(
                        projectID: "project-1",
                        repositoryName: "repo",
                        repositoryImageURL: nil,
                        techStack: ["Swift"],
                        currentSetLabel: "Set 1",
                        currentSetTitle: "Basics",
                        nextSetID: "set-1",
                        nextQuestionID: "question-1",
                        overallProgressPercent: 0,
                    )
                ],
                hasNext: false,
            )
        )
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(
            .mainShell(
                .delegate(
                    .learningRequested(projectID: "project-1", nextSetID: "set-1")
                )
            )
        ) {
            $0.quiz = QuizRouterFeature.State(projectID: "project-1", setID: "set-1", setLabel: "Set 1")
        }
    }

    @Test
    func `projectRegistrationRequested delegate는 등록 흐름 State를 채운다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(.mainShell(.delegate(.projectRegistrationRequested))) {
            $0.projectRegistration = ProjectRegistrationRouterFeature.State()
        }
    }

    @Test
    func `등록 완료 delegate는 등록 흐름을 닫고 Home을 정확히 한 번 재조회한다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        state.projectRegistration = ProjectRegistrationRouterFeature.State()
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        let receipt = ProjectRegistrationReceipt(projectID: "project-1", requestStatus: "accepted", quizLevel: .l1)
        await store.send(.projectRegistration(.presented(.delegate(.projectRegistered(receipt))))) {
            $0.projectRegistration = nil
        }
        await store.receive(.mainShell(.home(.input(.learningProjectsReloadRequested))))
    }

    @Test
    func `mainShell 표시 중 session invalidation은 onboarding 안내부터 다시 시작한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let authenticationOutcomes = AuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(restoreSession: restoreSession, authenticationOutcomes: authenticationOutcomes)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }
        await store.send(.onboarding(.delegate(.mainShellRequested))) {
            $0.route = .mainShell
        }

        await authenticationOutcomes.emit(.unauthenticated)
        await store.receive(.effect(.authenticationOutcomeReceived(.unauthenticated))) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }

        await authenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `onboarding 표시 중 session invalidation은 route를 바꾸지 않는다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let authenticationOutcomes = AuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(restoreSession: restoreSession, authenticationOutcomes: authenticationOutcomes)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }

        await authenticationOutcomes.emit(.unauthenticated)
        await store.receive(.effect(.authenticationOutcomeReceived(.unauthenticated)))

        #expect(store.state.route == .onboarding)

        await authenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `인증 세션이 확립되면 기기 등록을 1회 수행한다`() async {
        let registerCurrentDevice = RegisterCurrentDeviceSpy()
        let store = makeAppRootStore(registerCurrentDevice: registerCurrentDevice)
        store.exhaustivity = .off

        await store.send(.appEntry(.delegate(.destinationDecided(.mainShell)))) {
            $0.route = .mainShell
            $0.deviceRegistration = .registering
        }
        await store.receive(.effect(.deviceRegistrationSucceeded)) {
            $0.deviceRegistration = .registered
        }

        #expect(await registerCurrentDevice.callCount == 1)
        await store.finish()
    }

    @Test
    func `기기 등록 실패는 상태로 남고 앱 활성화 시 재시도한다`() async {
        let registerCurrentDevice = RegisterCurrentDeviceSpy(results: [
            .failure(DeviceRegistrationTestError.failed),
            .success(()),
        ])
        let store = makeAppRootStore(registerCurrentDevice: registerCurrentDevice)
        store.exhaustivity = .off

        await store.send(.appEntry(.delegate(.destinationDecided(.mainShell))))
        await store.receive(.effect(.deviceRegistrationFailed)) {
            $0.deviceRegistration = .failed
        }

        await store.send(.view(.applicationBecameActive)) {
            $0.deviceRegistration = .registering
        }
        await store.receive(.effect(.deviceRegistrationSucceeded)) {
            $0.deviceRegistration = .registered
        }

        #expect(await registerCurrentDevice.callCount == 2)
        await store.finish()
    }

    @Test
    func `mainShell 표시 중 앱이 활성화되면 프로젝트 목록을 다시 조회한다`() async {
        let store = makeAppRootStore(state: mainShellState())
        store.exhaustivity = .off

        await store.send(.view(.applicationBecameActive))
        await store.receive(.mainShell(.home(.input(.learningProjectsReloadRequested))))

        await store.finish()
    }

    @Test
    func `onboarding 표시 중 앱이 활성화되면 프로젝트 목록을 조회하지 않는다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .onboarding
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(.view(.applicationBecameActive))

        #expect(store.state.mainShell.home.projectLoad == .idle)
        await store.finish()
    }

    @Test
    func `포그라운드 목록 갱신이 실패해도 mainShell 화면을 유지한다`() async {
        let store = makeAppRootStore(state: mainShellState())
        store.exhaustivity = .off

        await store.send(.view(.applicationBecameActive))
        await store.receive(.mainShell(.home(.input(.learningProjectsReloadRequested))))
        await store.receive(
            .mainShell(.home(.effect(.projectsLoadFinished(requestID: 1, result: .failure(.unexpected)))))
        )

        #expect(store.state.route == .mainShell)
        #expect(store.state.mainShell.home.projectLoad == .failed(.unexpected))
        await store.finish()
    }

    @Test
    func `기기 등록 실패 후 token이 갱신되면 갱신 token으로 재시도한다`() async {
        let registerCurrentDevice = RegisterCurrentDeviceSpy(results: [
            .failure(DeviceRegistrationTestError.failed),
            .success(()),
        ])
        let store = makeAppRootStore(registerCurrentDevice: registerCurrentDevice)
        store.exhaustivity = .off

        await store.send(.appEntry(.delegate(.destinationDecided(.mainShell))))
        await store.receive(.effect(.deviceRegistrationFailed)) {
            $0.deviceRegistration = .failed
        }

        await store.send(.effect(.deviceTokenRefreshed)) {
            $0.deviceRegistration = .registering
        }
        await store.receive(.effect(.deviceRegistrationSucceeded)) {
            $0.deviceRegistration = .registered
        }

        #expect(await registerCurrentDevice.callCount == 2)
        await store.finish()
    }

    @Test
    func `앱 활성화와 token 갱신이 동시에 발생해도 서버 등록 요청은 1회다`() async {
        let registerCurrentDevice = RegisterCurrentDeviceSpy()
        await registerCurrentDevice.setSuspends(true)
        let store = makeAppRootStore(registerCurrentDevice: registerCurrentDevice)
        store.exhaustivity = .off

        await store.send(.appEntry(.delegate(.destinationDecided(.mainShell)))) {
            $0.route = .mainShell
            $0.deviceRegistration = .registering
        }

        await store.send(.view(.applicationBecameActive))
        await store.send(.effect(.deviceTokenRefreshed))

        #expect(await registerCurrentDevice.callCount == 1)

        await registerCurrentDevice.resumeOldest()
        await store.receive(.effect(.deviceRegistrationSucceeded)) {
            $0.deviceRegistration = .registered
        }
        await store.finish()
    }

    @Test
    func `인증 종료 시 등록 흐름 child와 기기 등록 상태를 함께 제거한다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        state.projectRegistration = ProjectRegistrationRouterFeature.State()
        state.deviceRegistration = .failed
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(.mainShell(.delegate(.loggedOut))) {
            $0.projectRegistration = nil
            $0.deviceRegistration = .idle
            $0.route = .onboarding
        }

        await store.finish()
    }

    @Test
    func `재로그인 시 이전 세션의 등록 흐름 화면이 다시 표시되지 않는다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        state.projectRegistration = ProjectRegistrationRouterFeature.State()
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(.mainShell(.delegate(.loggedOut))) {
            $0.projectRegistration = nil
            $0.route = .onboarding
        }
        await store.send(.onboarding(.delegate(.mainShellRequested))) {
            $0.route = .mainShell
            $0.deviceRegistration = .registering
        }

        #expect(store.state.projectRegistration == nil)

        await store.skipReceivedActions()
        await store.finish()
    }

    @Test
    func `등록 제출이 성공하면 추적을 시작하고 홈에 진행 중을 전달한다`() async {
        let requestedAt = Date(timeIntervalSince1970: 1_000)
        let trackGenerationProgress = TrackGenerationProgressSpy()
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        state.projectRegistration = ProjectRegistrationRouterFeature.State()
        let store = makeAppRootStore(
            trackGenerationProgress: trackGenerationProgress,
            waitPolicy: GenerationWaitPolicy(minimumWait: 0.05, retentionLimit: 60),
            now: { requestedAt },
            state: state,
        )
        store.exhaustivity = .off

        await store
            .send(.projectRegistration(.presented(.quizGenerationProgress(.effect(.submissionFinished(.success(Self
                    .receipt)))))))
            {
                $0.generationProgress = GenerationProgress(projectID: "project-1", requestedAt: requestedAt)
                $0.mainShell.home.isGenerationInProgress = true
            }

        #expect(await trackGenerationProgress.beganCount == 1)

        await store.skipReceivedActions()
        await store.finish()
    }

    @Test
    func `결과가 확정되어도 준비 완료 시각까지는 진행 중을 유지한다`() async {
        let requestedAt = Date(timeIntervalSince1970: 1_000)
        let observeGenerationOutcomes = ObserveGenerationOutcomesUseCaseMock()
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        state.projectRegistration = ProjectRegistrationRouterFeature.State()
        let store = makeAppRootStore(
            observeGenerationOutcomes: observeGenerationOutcomes,
            waitPolicy: GenerationWaitPolicy(minimumWait: 60, retentionLimit: 3_600),
            now: { requestedAt },
            state: state,
        )
        store.exhaustivity = .off

        await store
            .send(.projectRegistration(.presented(.quizGenerationProgress(.effect(.submissionFinished(.success(Self.receipt)))))))
        await observeGenerationOutcomes.emit(GenerationOutcome(projectID: "project-1", status: .completed))

        #expect(store.state.generationProgress?.projectID == "project-1")

        await store.send(.mainShell(.delegate(.loggedOut)))
        await observeGenerationOutcomes.finish()
        await store.skipReceivedActions()
        await store.finish()
    }

    @Test
    func `준비 완료 시각이 지난 뒤 결과가 도착하면 진행 상태를 해제한다`() async {
        let requestedAt = Date(timeIntervalSince1970: 1_000)
        let trackGenerationProgress = TrackGenerationProgressSpy()
        let observeGenerationOutcomes = ObserveGenerationOutcomesUseCaseMock()
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        state.projectRegistration = ProjectRegistrationRouterFeature.State()
        let store = makeAppRootStore(
            observeGenerationOutcomes: observeGenerationOutcomes,
            trackGenerationProgress: trackGenerationProgress,
            waitPolicy: GenerationWaitPolicy(minimumWait: 0, retentionLimit: 3_600),
            now: { requestedAt },
            state: state,
        )
        store.exhaustivity = .off

        await store
            .send(.projectRegistration(.presented(.quizGenerationProgress(.effect(.submissionFinished(.success(Self.receipt)))))))
        await observeGenerationOutcomes.emit(GenerationOutcome(projectID: "project-1", status: .completed))

        await store.receive(.effect(.generationProgressReleased(projectID: "project-1")), timeout: .seconds(5)) {
            $0.generationProgress = nil
        }
        #expect(await trackGenerationProgress.endedCount == 1)

        await observeGenerationOutcomes.finish()
        await store.skipReceivedActions()
        await store.finish()
    }

    @Test
    func `앱 시작 시 보존된 진행 상태를 복원해 홈에 진행 중을 전달한다`() async {
        let requestedAt = Date(timeIntervalSince1970: 1_000)
        let restored = GenerationProgress(projectID: "project-1", requestedAt: requestedAt)
        let store = makeAppRootStore(
            trackGenerationProgress: TrackGenerationProgressSpy(stored: restored),
            waitPolicy: GenerationWaitPolicy(minimumWait: 300, retentionLimit: 3_600),
            now: { requestedAt.addingTimeInterval(10) },
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(.effect(.generationProgressRestored(restored))) {
            $0.generationProgress = restored
            $0.isGenerationProgressRestored = true
            $0.mainShell.home.isGenerationInProgress = true
        }

        await store.send(.mainShell(.delegate(.loggedOut)))
        await store.skipReceivedActions()
        await store.finish()
    }

    @Test
    func `보존 상한을 넘긴 진행 상태는 복원하지 않고 해제한다`() async {
        let requestedAt = Date(timeIntervalSince1970: 1_000)
        let restored = GenerationProgress(projectID: "project-1", requestedAt: requestedAt)
        let trackGenerationProgress = TrackGenerationProgressSpy(stored: restored)
        let store = makeAppRootStore(
            trackGenerationProgress: trackGenerationProgress,
            waitPolicy: GenerationWaitPolicy(minimumWait: 300, retentionLimit: 3_600),
            now: { requestedAt.addingTimeInterval(3_601) },
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(.effect(.generationProgressRestored(restored)))

        #expect(store.state.generationProgress == nil)
        #expect(store.state.mainShell.home.isGenerationInProgress == false)

        await store.skipReceivedActions()
        await store.finish()
    }

    @Test
    func `복원된 projectID가 학습 프로젝트 목록에 있으면 진행 상태를 해제한다`() async {
        let requestedAt = Date(timeIntervalSince1970: 1_000)
        let restored = GenerationProgress(projectID: "project-1", requestedAt: requestedAt)
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        state.generationProgress = restored
        state.isGenerationProgressRestored = true
        let store = makeAppRootStore(
            waitPolicy: GenerationWaitPolicy(minimumWait: 300, retentionLimit: 3_600),
            now: { requestedAt.addingTimeInterval(301) },
            state: state,
        )
        store.exhaustivity = .off

        await store.send(.mainShell(.home(.effect(.projectsLoadFinished(
            requestID: 1,
            result: .success(Self.pageContainingProject),
        )))))
        await store.receive(.effect(.generationProgressReleased(projectID: "project-1"))) {
            $0.generationProgress = nil
            $0.isGenerationProgressRestored = false
        }

        await store.skipReceivedActions()
        await store.finish()
    }

    // MARK: Private

    private static let receipt = ProjectRegistrationReceipt(
        projectID: "project-1",
        requestStatus: "IN_PROGRESS",
        quizLevel: .l1,
    )

    private static let pageContainingProject = LearningProjectPage(
        items: [
            LearningProjectSummary(
                projectID: "project-1",
                repositoryName: "repo",
                repositoryImageURL: nil,
                techStack: ["Swift"],
                currentSetLabel: "Set 1",
                currentSetTitle: "제목",
                nextSetID: nil,
                nextQuestionID: nil,
                overallProgressPercent: 0,
            )
        ],
        hasNext: false,
    )

}

// MARK: - AppRootLearningFlowTests

@Suite("AppRootFeature 학습 흐름 표시")
struct AppRootLearningFlowTests {

    // MARK: Internal

    @Test
    func `프로젝트 상세 요청은 상세 흐름을 표시한다`() async {
        let store = makeAppRootStore(state: mainShellState())
        store.exhaustivity = .off

        await store.send(.mainShell(.delegate(.projectDetailRequested(projectID: "project-1"))))

        #expect(store.state.projectDetail?.projectID == "project-1")
    }

    @Test
    func `세트 선택은 상세 흐름 위에 풀이 흐름을 표시한다`() async {
        let store = makeAppRootStore(state: presentedDetailState())
        store.exhaustivity = .off

        await store.send(.projectDetail(.presented(.delegate(.learningSetRequested(
            projectID: "project-1",
            setID: "set-1",
            label: "CHAPTER 1",
        )))))

        #expect(store.state.quiz?.projectID == "project-1")
        #expect(store.state.quiz?.setID == "set-1")
        #expect(store.state.quiz?.setLabel == "CHAPTER 1")
        #expect(store.state.projectDetail != nil)
    }

    @Test
    func `풀이 흐름을 닫으면 상세로 돌아가고 갱신을 요청한다`() async {
        var state = presentedDetailState()
        state.quiz = QuizRouterFeature.State(projectID: "project-1", setID: "set-1", setLabel: "CHAPTER 1")
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(.quiz(.presented(.delegate(.dismissRequested(projectID: "project-1")))))
        await store.receive(.projectDetail(.presented(.projectDetail(.input(.refreshRequested)))))

        #expect(store.state.quiz == nil)
        #expect(store.state.projectDetail?.projectID == "project-1")
    }

    @Test
    func `풀이 중 진행이 바뀌면 표시 중인 상세에 갱신을 전달한다`() async {
        var state = presentedDetailState()
        state.quiz = QuizRouterFeature.State(projectID: "project-1", setID: "set-1", setLabel: "CHAPTER 1")
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(.quiz(.presented(.delegate(.progressInvalidated(projectID: "project-1")))))
        await store.receive(.projectDetail(.presented(.projectDetail(.input(.refreshRequested)))))
    }

    @Test
    func `외부 URL 요청은 주입된 경로를 정확히 한 번 사용한다`() async throws {
        let openExternalURL = OpenExternalURLSpy()
        let store = makeAppRootStore(openExternalURL: openExternalURL, state: presentedDetailState())
        store.exhaustivity = .off
        let url = try #require(URL(string: AppRootTestFixture.repositoryURL))

        await store.send(.projectDetail(.presented(.delegate(.externalURLRequested(url)))))
        await store.finish()

        #expect(await openExternalURL.openedURLs == [url])
    }

    @Test
    func `삭제 완료는 상세 표시를 해제하고 목록 갱신을 요청한다`() async {
        let store = makeAppRootStore(state: presentedDetailState())
        store.exhaustivity = .off

        await store.send(.projectDetail(.presented(.delegate(.projectDeleted(projectID: "project-1")))))
        await store.receive(.mainShell(.home(.input(.learningProjectsReloadRequested))))

        #expect(store.state.projectDetail == nil)
    }

    // MARK: Private

    private func mainShellState() -> AppRootFeature.State {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        return state
    }

    private func presentedDetailState() -> AppRootFeature.State {
        var state = mainShellState()
        state.projectDetail = ProjectDetailRouterFeature.State(projectID: "project-1")
        return state
    }

}
