import ComposableArchitecture
import DomainAppSetting
import Testing

@testable import Feature

// MARK: - MainShellRouterFeatureTests

@MainActor
@Suite("MainShell Home 통합")
struct MainShellRouterFeatureTests {

    // MARK: Internal

    @Test
    func `Home이 기본이고 탭 순서는 Home 프로젝트 저장 마이다`() {
        #expect(MainShellRouterFeature.State().selectedTab == .home)
        #expect(MainShellTab.allCases == [.home, .projects, .saved, .settings])
    }

    @Test
    func `탭을 왕복하면 프로젝트를 다시 조회하고 실패해도 그리던 목록을 유지한다`() async {
        let userInfo = UserInfoUseCaseMock()
        let projects = ProjectUseCaseMock()
        var state = MainShellRouterFeature.State()
        state.home.profile.load = .loaded(HomeTestFixture.profileWithBoth)
        state.home.projectSummaries.load = .loaded(HomeTestFixture.oneProjectPage)
        let store = makeStore(
            state: state,
            projects: projects,
            userInfo: userInfo,
        )
        store.exhaustivity = .off

        await store.send(.view(.tabSelected(.projects))) { $0.selectedTab = .projects }
        await store.send(.view(.tabSelected(.home))) { $0.selectedTab = .home }
        await store.finish()

        #expect(await projects.snapshot().refreshCallCount > 0)
        #expect(store.state.home.projectSummaries.load == .loaded(HomeTestFixture.oneProjectPage))
    }

    @Test
    func `Home 전체 보기는 프로젝트 탭을 선택한다`() async {
        let store = makeStore()
        store.exhaustivity = .off

        await store.send(.home(.delegate(.allProjectsRequested))) {
            $0.selectedTab = .projects
        }
        await store.finish()
    }

    @Test
    func `Home delegate를 payload 손실 없이 상위로 중계한다`() async {
        let store = makeStore()

        await store.send(.home(.delegate(.projectRegistrationRequested)))
        await store.receive(.delegate(.projectRegistrationRequested))
        await store.send(.home(.delegate(.projectDetailRequested(projectID: "project-1"))))
        await store.receive(.delegate(.projectDetailRequested(projectID: "project-1")))
        await store.send(
            .home(.delegate(.learningRequested(
                projectID: "project-1",
                nextSetID: "set-1",
            )))
        )
        await store.receive(
            .delegate(.learningRequested(
                projectID: "project-1",
                nextSetID: "set-1",
            ))
        )
    }

    @Test(arguments: [SettingsRouterFeature.Action.Delegate.signedOut, .accountDeleted])
    func `로그아웃과 계정 삭제는 네 child와 Home 기본 탭을 초기화한다`(
        delegate: SettingsRouterFeature.Action.Delegate
    ) async {
        var state = MainShellRouterFeature.State()
        state.selectedTab = .settings
        state.home.profile.load = .loaded(HomeTestFixture.profileWithBoth)
        let store = makeStore(state: state)

        await store.send(.settings(.delegate(delegate))) {
            $0 = MainShellRouterFeature.State()
        }
        await store.receive(.delegate(.loggedOut))
    }

    @Test
    func `프로젝트 목록의 이어하기 요청을 payload 손실 없이 상위로 중계한다`() async {
        let store = makeStore()

        await store.send(
            .projectList(.delegate(.learningRequested(
                projectID: "project-1",
                nextSetID: "set-1",
            )))
        )
        await store.receive(
            .delegate(.learningRequested(
                projectID: "project-1",
                nextSetID: "set-1",
            ))
        )
    }

    @Test
    func `저장한 문제를 고르면 그 프로젝트 세트로 준비를 요청한다`() async {
        let store = makeStore()
        store.exhaustivity = .off
        let bookmark = ProjectDetailTestFixture.savedQuizList.bookmarks[0]

        await store.send(.saved(.delegate(.questionSelected(bookmark))))
        await store.receive(
            .singleQuestionEntry(.input(.questionRequested(
                setID: "set-0",
                questionID: "quiz-0",
            )))
        )

        #expect(store.state.singleQuestionEntry?.projectID == bookmark.projectID)
    }

    @Test
    func `준비가 끝나면 단일 문제 화면을 연다`() async {
        let store = makeStore()
        store.exhaustivity = .off
        let quiz = QuizTestFixture.unansweredSet.quizzes[0]
        let bookmark = ProjectDetailTestFixture.savedQuizList.bookmarks[0]

        await store.send(.saved(.delegate(.questionSelected(bookmark))))
        await store.send(.singleQuestionEntry(.delegate(.questionPrepared(
            question: quiz,
            projectID: ProjectDetailTestFixture.projectID,
        ))))

        #expect(store.state.singleQuestion?.question == quiz)
        #expect(
            store.state.singleQuestion?.advanceActionTitle
                == MainShellRouterFeature.singleQuestionAdvanceActionTitle
        )
    }

    @Test
    func `단일 문제 화면의 뒤로가기는 저장 탭으로 바로 돌아간다`() async {
        var state = MainShellRouterFeature.State()
        state.selectedTab = .saved
        state.singleQuestion = QuestionSolvingFeature.State(
            projectID: ProjectDetailTestFixture.projectID,
            question: QuizTestFixture.unansweredSet.quizzes[0],
            advanceActionTitle: MainShellRouterFeature.singleQuestionAdvanceActionTitle,
            isBookmarked: true,
        )
        let store = makeStore(state: state)
        store.exhaustivity = .off

        await store.send(.singleQuestion(.presented(.delegate(.backRequested))))

        #expect(store.state.singleQuestion == nil)
        #expect(store.state.selectedTab == .saved)
    }

    // MARK: Private

    private func makeStore(
        state: MainShellRouterFeature.State = .init(),
        projects: ProjectUseCaseMock = .init(),
        userInfo: UserInfoUseCaseMock = .init(),
    ) -> TestStoreOf<MainShellRouterFeature> {
        TestStore(initialState: state) {
            MainShellRouterFeature(
                project: projects,
                quizDetail: QuizDetailUseCaseMock(),
                account: MainShellAccountUseCaseStub(),
                userInfo: userInfo,
                appSetting: MainShellAppSettingUseCaseStub(),
            )
        }
    }

}

// MARK: - MainShellAppSettingUseCaseStub

private struct MainShellAppSettingUseCaseStub: AppSettingUseCase {

    func notificationAuthorization() async -> NotificationAuthorizationStatus {
        .denied
    }

    func requestNotificationAuthorization() async -> NotificationAuthorizationStatus {
        .denied
    }

    func registerDevice() async throws { }

    func updateDeviceToken(_ token: DeviceToken) async throws {
        _ = token
    }

}
