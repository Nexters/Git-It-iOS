import ComposableArchitecture
import DomainProject
import Feature
import Testing

@testable import GitIt

@MainActor
@Suite("AppRootFeature 프로젝트 목록 자동 갱신")
struct AppRootFeatureLearningProjectsRefreshTests {

    // MARK: Internal

    @Test
    func `mainShell 표시 중 백그라운드에서 돌아오면 목록을 대체 새로고침한다`() async {
        let project = ProjectUseCaseMock()
        let store = makeAppRootStore(
            project: project,
            state: AppRootTestFixture.mainShellState(),
        )
        store.exhaustivity = .off

        await store.send(.view(.applicationEnteredBackground)) {
            $0.isInBackground = true
        }
        await store.send(.view(.applicationBecameActive)) {
            $0.isInBackground = false
        }
        await store.receive(\.effect.learningProjectsRefreshFinished)
        await store.skipReceivedActions(strict: false)
        await store.finish()

        #expect(await project.replacingRefreshCallCount == 1)
        #expect(await project.refreshCallCount == 0)
    }

    @Test
    func `백그라운드를 거치지 않고 활성화되면 목록을 새로고침하지 않는다`() async {
        let project = ProjectUseCaseMock()
        let store = makeAppRootStore(
            project: project,
            state: AppRootTestFixture.mainShellState(),
        )
        store.exhaustivity = .off

        await store.send(.view(.applicationBecameActive))
        await store.skipReceivedActions(strict: false)
        await store.finish()

        #expect(await project.replacingRefreshCallCount == 0)
        #expect(await project.refreshCallCount == 0)
    }

    @Test
    func `onboarding 표시 중 백그라운드에서 돌아와도 목록을 새로고침하지 않는다`() async {
        let project = ProjectUseCaseMock()
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .onboarding
        let store = makeAppRootStore(
            project: project,
            state: state,
        )
        store.exhaustivity = .off

        await store.send(.view(.applicationEnteredBackground))
        await store.send(.view(.applicationBecameActive)) {
            $0.isInBackground = false
        }
        await store.skipReceivedActions(strict: false)
        await store.finish()

        #expect(await project.replacingRefreshCallCount == 0)
    }

    @Test
    func `게스트 상태에서 백그라운드에서 돌아와도 목록을 새로고침하지 않고 백그라운드 표시를 해제한다`() async {
        let project = ProjectUseCaseMock()
        let store = makeAppRootStore(
            project: project,
            state: guestMainShellState(),
        )

        await store.send(.view(.applicationEnteredBackground)) {
            $0.isInBackground = true
        }
        await store.send(.view(.applicationBecameActive)) {
            $0.isInBackground = false
        }
        await store.finish()

        #expect(await project.replacingRefreshCallCount == 0)
    }

    @Test
    func `대체 새로고침이 실패해도 mainShell 화면과 상태를 유지한다`() async {
        let project = ProjectUseCaseMock(replacingRefreshError: .temporarilyUnavailable)
        let store = makeAppRootStore(
            project: project,
            state: AppRootTestFixture.mainShellState(),
        )
        store.exhaustivity = .off

        await store.send(.view(.applicationEnteredBackground))
        await store.send(.view(.applicationBecameActive))
        let stateBeforeFinished = store.state
        await store.receive(.effect(.learningProjectsRefreshFinished(error: .temporarilyUnavailable)))

        #expect(store.state == stateBeforeFinished)
        #expect(store.state.route == .mainShell)

        await store.skipReceivedActions(strict: false)
        await store.finish()
    }

    @Test
    func `포그라운드에서 생성 결과가 도착하면 목록을 대체 새로고침한다`() async {
        let account = AccountUseCaseMock(restorations: [.signedIn(AppRootTestFixture.signedInAccount)])
        let userInfo = UserInfoUseCaseMock(curations: [.success(AppRootTestFixture.curation)])
        let project = ProjectUseCaseMock()
        let projectGeneration = ProjectGenerationUseCaseMock(keepsObservationOpen: true)
        let deviceTokenRefreshes = DeviceTokenRefreshStream()
        let store = makeAppRootStore(
            account: account,
            userInfo: userInfo,
            project: project,
            projectGeneration: projectGeneration,
            deviceTokenRefreshes: deviceTokenRefreshes,
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.send(.appEntry(.view(.splashAnimationFinished)))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .mainShell
        }

        await projectGeneration.emitArrival(AppRootTestFixture.projectID)
        await store.receive(
            .effect(.generationOutcomeArrived(AppRootTestFixture.projectID)),
            timeout: .seconds(5),
        )
        await store.receive(
            .effect(.learningProjectsRefreshFinished(error: nil)),
            timeout: .seconds(5),
        )

        #expect(await project.replacingRefreshCallCount == 1)

        await projectGeneration.finish()
        deviceTokenRefreshes.finish()
        await store.skipReceivedActions(strict: false)
        await store.finish()
    }

    @Test
    func `백그라운드에서 생성 결과가 도착하면 목록을 새로고침하지 않는다`() async {
        let project = ProjectUseCaseMock()
        let store = makeAppRootStore(
            project: project,
            state: AppRootTestFixture.mainShellState(),
        )

        await store.send(.view(.applicationEnteredBackground)) {
            $0.isInBackground = true
        }
        await store.send(.effect(.generationOutcomeArrived(AppRootTestFixture.projectID)))
        await store.finish()

        #expect(await project.replacingRefreshCallCount == 0)
    }

    @Test
    func `게스트 상태에서 생성 결과가 도착하면 목록을 새로고침하지 않는다`() async {
        let project = ProjectUseCaseMock()
        let store = makeAppRootStore(
            project: project,
            state: guestMainShellState(),
        )

        await store.send(.effect(.generationOutcomeArrived(AppRootTestFixture.projectID)))
        await store.finish()

        #expect(await project.replacingRefreshCallCount == 0)
    }

    @Test
    func `연달아 온 계기는 앞선 새로고침 Effect를 대체해 완료 이벤트를 한 번만 받는다`() async {
        let project = ProjectUseCaseMock(holdsFirstReplacingRefresh: true)
        let store = makeAppRootStore(
            project: project,
            state: AppRootTestFixture.mainShellState(),
        )

        await store.send(.effect(.generationOutcomeArrived(AppRootTestFixture.projectID)))
        await settle { await project.replacingRefreshCallCount == 1 }
        await store.send(.effect(.generationOutcomeArrived(AppRootTestFixture.projectID)))
        await store.receive(.effect(.learningProjectsRefreshFinished(error: nil)))
        await store.finish()

        #expect(await project.replacingRefreshCallCount == 2)
        #expect(await project.isHeldReplacingRefreshCancelled)
    }

    @Test
    func `상세 화면이 열린 채 백그라운드에서 돌아오면 상세 표시를 유지하고 목록을 새로고침한다`() async {
        let project = ProjectUseCaseMock()
        var state = AppRootTestFixture.mainShellState()
        state.projectDetail = ProjectDetailRouterFeature.State(projectID: AppRootTestFixture.projectID)
        let store = makeAppRootStore(
            project: project,
            state: state,
        )
        store.exhaustivity = .off

        await store.send(.view(.applicationEnteredBackground))
        await store.send(.view(.applicationBecameActive))
        await store.receive(\.effect.learningProjectsRefreshFinished)

        #expect(store.state.projectDetail?.projectID == AppRootTestFixture.projectID)
        #expect(await project.replacingRefreshCallCount == 1)

        await store.skipReceivedActions(strict: false)
        await store.finish()
    }

    @Test
    func `백그라운드에서 돌아오면 생성 상태 동기화도 함께 실행한다`() async {
        let project = ProjectUseCaseMock()
        let projectGeneration = ProjectGenerationUseCaseMock()
        let store = makeAppRootStore(
            project: project,
            projectGeneration: projectGeneration,
            state: AppRootTestFixture.mainShellState(),
        )
        store.exhaustivity = .off

        await store.send(.view(.applicationEnteredBackground))
        await store.send(.view(.applicationBecameActive))
        await store.skipReceivedActions(strict: false)
        await store.finish()

        #expect(await projectGeneration.synchronizeCount == 1)
        #expect(await project.replacingRefreshCallCount == 1)
    }

    @Test
    func `onboarding 표시 중 생성 결과가 도착하면 목록을 새로고침하지 않는다`() async {
        let project = ProjectUseCaseMock()
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .onboarding
        let store = makeAppRootStore(
            project: project,
            state: state,
        )

        await store.send(.effect(.generationOutcomeArrived(AppRootTestFixture.projectID)))
        await store.finish()

        #expect(await project.replacingRefreshCallCount == 0)
    }

    // MARK: Private

    private func guestMainShellState() -> AppRootFeature.State {
        var state = AppRootTestFixture.mainShellState()
        state.mainShell = MainShellRouterFeature.State(access: .guest)
        return state
    }

    private func settle(until condition: () async -> Bool) async {
        for _ in 0 ..< 1_000 {
            guard await !condition() else { return }
            await Task.yield()
        }
    }

}
