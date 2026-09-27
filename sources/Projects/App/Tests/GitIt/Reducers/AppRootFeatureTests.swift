import ComposableArchitecture
import DomainProject
import DomainProjectGeneration
import Feature
import Foundation
import Testing

@testable import GitIt

// MARK: - AppRootFeatureTests

@MainActor
@Suite("AppRootFeature root 전환")
struct AppRootFeatureTests {

    @Test
    func `launch task는 route를 즉시 바꾸지 않고 appEntry task를 전달한다`() async {
        let account = AccountUseCaseMock(restorations: [.temporarilyUnavailable])
        let deviceTokenRefreshes = DeviceTokenRefreshStream()
        let store = makeAppRootStore(
            account: account,
            deviceTokenRefreshes: deviceTokenRefreshes,
        )
        store.exhaustivity = .off

        #expect(store.state.route == .restoring)

        await store.send(.view(.task))
        await store.receive(\.appEntry.effect.restoreSignInFinished)
        await store.receive(\.appEntry.effect.restoreSignInFinished)

        #expect(store.state.route == .restoring)
        #expect(store.state.appEntry.authentication == .retryableFailure)

        deviceTokenRefreshes.finish()
        await store.finish()
    }

    @Test
    func `미인증 세션은 route를 onboarding으로 전환하고 온보딩 안내부터 시작한다`() async {
        let account = AccountUseCaseMock(restorations: [.signedOut])
        let deviceTokenRefreshes = DeviceTokenRefreshStream()
        let store = makeAppRootStore(
            account: account,
            deviceTokenRefreshes: deviceTokenRefreshes,
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.send(.appEntry(.view(.splashAnimationFinished)))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(
                startingAt: .guide,
                bundleVersion: "1.0.0",
            )
        }

        deviceTokenRefreshes.finish()
        await store.finish()
    }

    @Test
    func `인증됐지만 큐레이션이 미완료면 route를 onboarding으로 전환하고 큐레이션부터 시작한다`() async {
        let account = AccountUseCaseMock(restorations: [.signedIn(AppRootTestFixture.signedInAccount)])
        let userInfo = UserInfoUseCaseMock(curations: [.success(nil)])
        let deviceTokenRefreshes = DeviceTokenRefreshStream()
        let store = makeAppRootStore(
            account: account,
            userInfo: userInfo,
            deviceTokenRefreshes: deviceTokenRefreshes,
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.send(.appEntry(.view(.splashAnimationFinished)))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(
                startingAt: .curation,
                bundleVersion: "1.0.0",
            )
        }

        deviceTokenRefreshes.finish()
        await store.finish()
    }

    @Test
    func `인증됐고 큐레이션이 완료면 route를 mainShell로 전환한다`() async {
        let account = AccountUseCaseMock(restorations: [.signedIn(AppRootTestFixture.signedInAccount)])
        let userInfo = UserInfoUseCaseMock(curations: [.success(AppRootTestFixture.curation)])
        let deviceTokenRefreshes = DeviceTokenRefreshStream()
        let store = makeAppRootStore(
            account: account,
            userInfo: userInfo,
            deviceTokenRefreshes: deviceTokenRefreshes,
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.send(.appEntry(.view(.splashAnimationFinished)))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .mainShell
        }

        deviceTokenRefreshes.finish()
        await store.skipReceivedActions()
        await store.finish()
    }

    @Test
    func `복원 가능한 실패는 route를 바꾸지 않고 재시도하면 목적지를 결정한다`() async {
        let account = AccountUseCaseMock(restorations: [
            .temporarilyUnavailable,
            .temporarilyUnavailable,
            .signedOut,
        ])
        let deviceTokenRefreshes = DeviceTokenRefreshStream()
        let store = makeAppRootStore(
            account: account,
            deviceTokenRefreshes: deviceTokenRefreshes,
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.appEntry.effect.restoreSignInFinished)
        await store.receive(\.appEntry.effect.restoreSignInFinished)
        await store.send(.appEntry(.view(.splashAnimationFinished)))

        #expect(store.state.route == .restoring)
        #expect(store.state.appEntry.isShowingRecoverableError)

        await store.send(.appEntry(.view(.retryTapped)))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(
                startingAt: .guide,
                bundleVersion: "1.0.0",
            )
        }

        deviceTokenRefreshes.finish()
        await store.finish()
    }

    @Test
    func `restoring을 벗어난 뒤 반복 task는 appEntry task를 다시 전달하지 않는다`() async {
        let account = AccountUseCaseMock(restorations: [.signedOut])
        let deviceTokenRefreshes = DeviceTokenRefreshStream()
        let store = makeAppRootStore(
            account: account,
            deviceTokenRefreshes: deviceTokenRefreshes,
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.send(.appEntry(.view(.splashAnimationFinished)))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(
                startingAt: .guide,
                bundleVersion: "1.0.0",
            )
        }
        await store.send(.view(.task))

        #expect(await account.restoreCallCount == 1)

        deviceTokenRefreshes.finish()
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

        await store.skipReceivedActions()
        await store.finish()
    }

    @Test
    func `mainShell logout delegate는 onboarding 안내부터 다시 시작한다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(.mainShell(.delegate(.loggedOut))) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(
                startingAt: .guide,
                bundleVersion: "1.0.0",
            )
        }
    }

    @Test
    func `로그아웃·로그인 무효화·초기화 뒤 재생성된 MainShell은 다음 진입에서 Home 기본으로 시작한다`() async {
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

        await loggedOutStore.skipReceivedActions()
        await loggedOutStore.finish()

        var signInState = AppRootFeature.State(bundleVersion: "1.0.0")
        signInState.route = .mainShell
        signInState.mainShell.selectedTab = .projects
        let signInStore = makeAppRootStore(
            account: AccountUseCaseMock(verification: .reauthenticationRequired),
            state: signInState,
        )
        signInStore.exhaustivity = .off

        await signInStore.send(.view(.applicationBecameActive))
        await signInStore.receive(.effect(.signInVerified(.reauthenticationRequired))) {
            $0.route = .onboarding
            $0.mainShell = MainShellRouterFeature.State()
        }
        await signInStore.send(.onboarding(.delegate(.mainShellRequested))) {
            $0.route = .mainShell
        }
        #expect(signInStore.state.mainShell.selectedTab == .home)
        #expect(signInStore.state.mainShell.home == HomeFeature.State())

        await signInStore.skipReceivedActions()
        await signInStore.finish()
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

        await store.send(.mainShell(.delegate(.projectDetailRequested(projectID: AppRootTestFixture.projectID))))
        #expect(store.state.route == .mainShell)
        #expect(store.state.mainShell == MainShellRouterFeature.State())

        await store.skipReceivedActions(strict: false)
        await store.finish()
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
                    .learningRequested(
                        projectID: AppRootTestFixture.projectID,
                        nextSetID: AppRootTestFixture.setID,
                    )
                )
            )
        )
        #expect(store.state.quiz == nil)
    }

    @Test
    func `프로젝트 목록의 학습 요청은 상세 위에 그 세트의 풀이 흐름을 연다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        state.mainShell.projectList.projectSummaries.load = .loaded(
            AppRootTestFixture.projectList(summaries: [AppRootTestFixture.projectSummary()])
        )
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(
            .mainShell(
                .delegate(
                    .learningRequested(
                        projectID: AppRootTestFixture.projectID,
                        nextSetID: AppRootTestFixture.setID,
                    )
                )
            )
        )

        #expect(store.state.quiz?.projectID == AppRootTestFixture.projectID)
        #expect(store.state.quiz?.setID == AppRootTestFixture.setID)
        #expect(store.state.quiz?.setLabel == AppRootTestFixture.setLabel)
        #expect(store.state.projectDetail?.projectID == AppRootTestFixture.projectID)

        await store.skipReceivedActions(strict: false)
        await store.finish()
    }

    @Test
    func `Home 학습 요청은 일치하는 프로젝트가 있으면 그 세트의 풀이 흐름을 연다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        state.mainShell.home.projectSummaries.load = .loaded(
            AppRootTestFixture.projectList(summaries: [AppRootTestFixture.projectSummary()])
        )
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(
            .mainShell(
                .delegate(
                    .learningRequested(
                        projectID: AppRootTestFixture.projectID,
                        nextSetID: AppRootTestFixture.setID,
                    )
                )
            )
        ) {
            $0.quiz = QuizRouterFeature.State(
                projectID: AppRootTestFixture.projectID,
                setID: AppRootTestFixture.setID,
                setLabel: AppRootTestFixture.setLabel,
                autoStartsLearning: true,
            )
        }

        await store.skipReceivedActions(strict: false)
        await store.finish()
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
    func `등록 완료 delegate는 등록 흐름을 닫고 목록을 정확히 한 번 재조회한다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        state.projectRegistration = ProjectRegistrationRouterFeature.State()
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        let receipt = ProjectGenerationReceipt(
            projectID: AppRootTestFixture.projectID,
            quizLevel: .l1,
        )
        await store.send(.projectRegistration(.presented(.delegate(.projectRegistered(receipt))))) {
            $0.projectRegistration = nil
        }
        await store.receive(.mainShell(.input(.learningProjectsReloadRequested)))

        await store.skipReceivedActions()
        await store.finish()
    }

    @Test
    func `mainShell 표시 중 로그인 무효화는 onboarding 안내부터 다시 시작한다`() async {
        let account = AccountUseCaseMock(
            restorations: [.signedOut],
            verification: .reauthenticationRequired,
        )
        let deviceTokenRefreshes = DeviceTokenRefreshStream()
        let store = makeAppRootStore(
            account: account,
            deviceTokenRefreshes: deviceTokenRefreshes,
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.send(.appEntry(.view(.splashAnimationFinished)))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(
                startingAt: .guide,
                bundleVersion: "1.0.0",
            )
        }
        await store.send(.onboarding(.delegate(.mainShellRequested))) {
            $0.route = .mainShell
        }

        await store.send(.view(.applicationBecameActive))
        await store.receive(.effect(.signInVerified(.reauthenticationRequired))) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(
                startingAt: .guide,
                bundleVersion: "1.0.0",
            )
        }

        deviceTokenRefreshes.finish()
        await store.finish()
    }

    @Test
    func `onboarding 표시 중 로그인 무효화는 route를 바꾸지 않는다`() async {
        let account = AccountUseCaseMock(
            restorations: [.signedOut],
            verification: .reauthenticationRequired,
        )
        let deviceTokenRefreshes = DeviceTokenRefreshStream()
        let store = makeAppRootStore(
            account: account,
            deviceTokenRefreshes: deviceTokenRefreshes,
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.send(.appEntry(.view(.splashAnimationFinished)))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(
                startingAt: .guide,
                bundleVersion: "1.0.0",
            )
        }

        await store.send(.view(.applicationBecameActive))
        await store.receive(.effect(.signInVerified(.reauthenticationRequired)))

        #expect(store.state.route == .onboarding)

        deviceTokenRefreshes.finish()
        await store.finish()
    }

    @Test
    func `로그인 세션이 확립되면 기기 등록을 1회 수행한다`() async {
        let appSetting = AppSettingUseCaseMock()
        let store = makeAppRootStore(appSetting: appSetting)
        store.exhaustivity = .off

        await store.send(.appEntry(.delegate(.destinationDecided(.mainShell)))) {
            $0.route = .mainShell
            $0.deviceRegistration = .registering
        }
        await store.receive(.effect(.deviceRegistrationSucceeded)) {
            $0.deviceRegistration = .registered
        }

        #expect(await appSetting.registerDeviceCallCount == 1)
        await store.finish()
    }

    @Test
    func `기기 등록 실패는 상태로 남고 앱 활성화 시 재시도한다`() async {
        let appSetting = AppSettingUseCaseMock(registrationResults: [
            .failure(DeviceRegistrationTestError.failed),
            .success(()),
        ])
        let store = makeAppRootStore(appSetting: appSetting)
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

        #expect(await appSetting.registerDeviceCallCount == 2)
        await store.finish()
    }

    @Test
    func `기기 등록 실패 후 token이 갱신되면 갱신 token을 저장하고 재시도한다`() async {
        let appSetting = AppSettingUseCaseMock(registrationResults: [
            .failure(DeviceRegistrationTestError.failed),
            .success(()),
        ])
        let store = makeAppRootStore(appSetting: appSetting)
        store.exhaustivity = .off

        await store.send(.appEntry(.delegate(.destinationDecided(.mainShell))))
        await store.receive(.effect(.deviceRegistrationFailed)) {
            $0.deviceRegistration = .failed
        }

        await store.send(.effect(.deviceTokenRefreshed("device-token"))) {
            $0.deviceRegistration = .registering
        }
        await store.receive(.effect(.deviceRegistrationSucceeded)) {
            $0.deviceRegistration = .registered
        }

        await store.finish()

        #expect(await appSetting.registerDeviceCallCount == 2)
        #expect(await appSetting.updatedDeviceTokens == ["device-token"])
    }

    @Test
    func `앱 활성화와 token 갱신이 동시에 발생해도 서버 등록 요청은 1회다`() async {
        let appSetting = AppSettingUseCaseMock()
        await appSetting.setSuspends(true)
        let store = makeAppRootStore(appSetting: appSetting)
        store.exhaustivity = .off

        await store.send(.appEntry(.delegate(.destinationDecided(.mainShell)))) {
            $0.route = .mainShell
            $0.deviceRegistration = .registering
        }

        await store.send(.view(.applicationBecameActive))
        await store.send(.effect(.deviceTokenRefreshed("device-token")))

        #expect(await appSetting.registerDeviceCallCount == 1)

        await appSetting.resumeOldest()
        await store.receive(.effect(.deviceRegistrationSucceeded)) {
            $0.deviceRegistration = .registered
        }

        await store.skipReceivedActions(strict: false)
        await store.finish()
    }

    @Test
    func `로그인 종료 시 등록 흐름 child와 기기 등록 상태를 함께 제거한다`() async {
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
    func `진행 중 생성 요청이 관측되면 홈에 진행 중을 전달한다`() async {
        let projectGeneration = ProjectGenerationUseCaseMock(keepsObservationOpen: true)
        let deviceTokenRefreshes = DeviceTokenRefreshStream()
        let store = makeAppRootStore(
            projectGeneration: projectGeneration,
            deviceTokenRefreshes: deviceTokenRefreshes,
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(
            \.effect.generationStateChanged,
            timeout: .seconds(5),
        )

        await projectGeneration.emit(
            AppRootTestFixture.generationState(phase: .inProgress)
        )
        await store.receive(
            \.effect.generationStateChanged,
            timeout: .seconds(5),
        )
        await store.receive(.mainShell(.home(.input(.generationProgressChanged(isInProgress: true)))))

        #expect(store.state.mainShell.home.isGenerationInProgress)

        await projectGeneration.finish()
        deviceTokenRefreshes.finish()
        await store.skipReceivedActions(strict: false)
        await store.finish()
    }

    @Test
    func `생성이 끝난 요청만 남으면 홈의 진행 중 표시를 해제한다`() async {
        let projectGeneration = ProjectGenerationUseCaseMock(
            stored: AppRootTestFixture.generationState(
                phase: .inProgress
            ),
            keepsObservationOpen: true,
        )
        let deviceTokenRefreshes = DeviceTokenRefreshStream()
        let store = makeAppRootStore(
            projectGeneration: projectGeneration,
            deviceTokenRefreshes: deviceTokenRefreshes,
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(
            \.effect.generationStateChanged,
            timeout: .seconds(5),
        )
        await store.receive(.mainShell(.home(.input(.generationProgressChanged(isInProgress: true)))))

        #expect(store.state.mainShell.home.isGenerationInProgress)

        await projectGeneration.emit(AppRootTestFixture.generationState(phase: .ready))
        await store.receive(
            \.effect.generationStateChanged,
            timeout: .seconds(5),
        )
        await store.receive(.mainShell(.home(.input(.generationProgressChanged(isInProgress: false)))))

        #expect(store.state.mainShell.home.isGenerationInProgress == false)

        await projectGeneration.finish()
        deviceTokenRefreshes.finish()
        await store.skipReceivedActions(strict: false)
        await store.finish()
    }

}

// MARK: - AppRootLearningFlowTests

@Suite("AppRootFeature 학습 흐름 표시")
struct AppRootLearningFlowTests {

    // MARK: Internal

    @Test
    func `프로젝트 상세 요청은 상세 흐름을 표시한다`() async {
        let store = makeAppRootStore(state: AppRootTestFixture.mainShellState())
        store.exhaustivity = .off

        await store.send(.mainShell(.delegate(.projectDetailRequested(projectID: AppRootTestFixture.projectID))))

        #expect(store.state.projectDetail?.projectID == AppRootTestFixture.projectID)

        await store.skipReceivedActions(strict: false)
        await store.finish()
    }

    @Test
    func `세트 선택은 상세 흐름 위에 풀이 흐름을 표시한다`() async {
        let store = makeAppRootStore(state: presentedDetailState())
        store.exhaustivity = .off

        await store.send(.projectDetail(.presented(.delegate(.learningSetRequested(
            projectID: AppRootTestFixture.projectID,
            setID: AppRootTestFixture.setID,
            label: AppRootTestFixture.setLabel,
        )))))

        #expect(store.state.quiz?.projectID == AppRootTestFixture.projectID)
        #expect(store.state.quiz?.setID == AppRootTestFixture.setID)
        #expect(store.state.quiz?.setLabel == AppRootTestFixture.setLabel)
        #expect(store.state.projectDetail != nil)

        await store.skipReceivedActions(strict: false)
        await store.finish()
    }

    @Test
    func `풀이 흐름을 닫으면 프로젝트 목록을 한 번 갱신하고 열린 상세에 갱신을 요청한다`() async {
        let project = ProjectUseCaseMock()
        var state = presentedDetailState()
        state.quiz = QuizRouterFeature.State(
            projectID: AppRootTestFixture.projectID,
            setID: AppRootTestFixture.setID,
            setLabel: AppRootTestFixture.setLabel,
        )
        let store = makeAppRootStore(
            project: project,
            state: state,
        )
        store.exhaustivity = .off

        await store.send(.quiz(.presented(.delegate(.dismissRequested(projectID: AppRootTestFixture.projectID)))))
        await store.receive(.projectDetail(.presented(.projectDetail(.input(.refreshRequested)))))

        #expect(store.state.quiz == nil)
        #expect(store.state.projectDetail?.projectID == AppRootTestFixture.projectID)
        #expect(await project.refreshCallCount == 1)

        await store.skipReceivedActions()
        await store.finish()
    }

    @Test
    func `풀이 중 답안을 제출하면 프로젝트 목록도 상세도 갱신하지 않는다`() async {
        let project = ProjectUseCaseMock()
        var state = presentedDetailState()
        var quizState = QuizRouterFeature.State(
            projectID: AppRootTestFixture.projectID,
            setID: AppRootTestFixture.setID,
            setLabel: AppRootTestFixture.setLabel,
        )
        quizState.questionSolving = QuestionSolvingFeature.State(
            projectID: AppRootTestFixture.projectID,
            question: AppRootTestFixture.quiz(),
            advanceActionTitle: QuizRouterFeature.nextQuestionActionTitle,
        )
        state.quiz = quizState
        let store = makeAppRootStore(
            project: project,
            state: state,
        )
        store.exhaustivity = .off

        await store.send(.quiz(.presented(.questionSolving(.delegate(.answerSubmitted(
            questionID: AppRootTestFixture.quizID,
            choiceCorrect: true,
        ))))))

        #expect(store.state.quiz != nil)
        #expect(store.state.projectDetail?.projectDetail.detailLoad.requestID == 0)
        #expect(store.state.projectDetail?.projectDetail.detailLoad.loadStatus == .idle)
        #expect(await project.refreshCallCount == 0)

        await store.skipReceivedActions(strict: false)
        await store.finish()
    }

    @Test
    func `외부 URL 요청은 주입된 경로를 정확히 한 번 사용한다`() async throws {
        let openExternalURL = OpenExternalURLSpy()
        let store = makeAppRootStore(
            openExternalURL: openExternalURL,
            state: presentedDetailState(),
        )
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

        await store.send(
            .projectDetail(.presented(.delegate(.projectDeleted(projectID: AppRootTestFixture.projectID))))
        )
        await store.receive(.mainShell(.input(.learningProjectsReloadRequested)))

        #expect(store.state.projectDetail == nil)

        await store.skipReceivedActions()
        await store.finish()
    }

    @Test
    func `회원 상태에서 앱이 활성화되면 생성 상태를 동기화한다`() async {
        let projectGeneration = ProjectGenerationUseCaseMock()
        let store = makeAppRootStore(projectGeneration: projectGeneration)
        store.exhaustivity = .off

        await store.send(.view(.applicationBecameActive))
        await store.skipReceivedActions()
        await store.finish()

        #expect(await projectGeneration.synchronizeCount == 1)
    }

    @Test
    func `게스트 상태에서 앱이 활성화되면 생성 상태를 동기화하지 않는다`() async {
        let projectGeneration = ProjectGenerationUseCaseMock()
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.mainShell = MainShellRouterFeature.State(access: .guest)
        let store = makeAppRootStore(
            projectGeneration: projectGeneration,
            state: state,
        )

        await store.send(.view(.applicationBecameActive))
        await store.finish()

        #expect(await projectGeneration.synchronizeCount == 0)
    }

    // MARK: Private

    private func presentedDetailState() -> AppRootFeature.State {
        var state = AppRootTestFixture.mainShellState()
        state.projectDetail = ProjectDetailRouterFeature.State(projectID: AppRootTestFixture.projectID)
        return state
    }

}
