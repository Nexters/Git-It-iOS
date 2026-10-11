import ComposableArchitecture
import DomainUseCaseInterface
import Foundation

@Reducer
public struct MainShellRouterFeature: Sendable {

    // MARK: Lifecycle

    public init(
        project: any ProjectUseCase,
        quizDetail: any QuizDetailUseCase,
        account: any AccountUseCase,
        userInfo: any UserInfoUseCase,
        appSetting: any AppSettingUseCase,
        openNotificationSettings: @escaping @MainActor @Sendable () async -> Void = { },
    ) {
        self.project = project
        self.quizDetail = quizDetail
        self.account = account
        self.userInfo = userInfo
        self.appSetting = appSetting
        self.openNotificationSettings = openNotificationSettings
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {
        public init(access: MainShellAccess = .member) {
            self.access = access
            home.access = access
        }

        public var access: MainShellAccess
        public var selectedTab = MainShellTab.home
        public var home = HomeFeature.State()
        public var projectList = ProjectListFeature.State()
        public var saved = SavedFeature.State()
        public var settings = SettingsRouterFeature.State()
        public var singleQuestionEntry: SingleQuestionEntryFeature.State?
        @Presents public var singleQuestion: QuestionSolvingFeature.State?
        public var isSignInRequiredAlertPresented = false
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case input(Input)
        case delegate(Delegate)
        case home(HomeFeature.Action)
        case projectList(ProjectListFeature.Action)
        case saved(SavedFeature.Action)
        case settings(SettingsRouterFeature.Action)
        case singleQuestionEntry(SingleQuestionEntryFeature.Action)
        case singleQuestion(PresentationAction<QuestionSolvingFeature.Action>)

        // MARK: Public

        @CasePathable
        public enum Input: Sendable, Equatable {
            case learningProjectsReloadRequested
            case memberAccessGranted
        }

        @CasePathable
        public enum View: Sendable, Equatable {
            case tabSelected(MainShellTab)
            case signInRequiredAlertSignInTapped
            case signInRequiredAlertDismissed
            case singleQuestionFailureDismissed
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case projectRegistrationRequested
            case projectDetailRequested(projectID: ProjectID)
            case learningRequested(projectID: ProjectID, nextSetID: QuizSetID)
            case externalURLRequested(URL)
            case loggedOut
            case onboardingRequested
        }
    }

    public static let singleQuestionAdvanceActionTitle = LocalizedText.MainShell.SingleQuestion.Advance.buttonTitle

    public var body: some ReducerOf<Self> {
        Scope(
            state: \.home,
            action: \.home,
        ) {
            HomeFeature(
                projects: { [project] in await project.projects() },
                refreshProjects: { [project] in try await project.refresh() },
                profile: { [userInfo] in try await Self.profile(from: userInfo) },
            )
        }
        Scope(
            state: \.projectList,
            action: \.projectList,
        ) {
            ProjectListFeature(
                projects: { [project] in await project.projects() },
                refreshProjects: { [project] in try await project.refresh() },
                requestNextPage: { [project] in try await project.requestNextPage() },
                deleteProject: { [project] in try await project.delete($0) },
            )
        }
        Scope(
            state: \.saved,
            action: \.saved,
        ) {
            SavedFeature(
                fetchBookmarks: { [quizDetail] in try await quizDetail.bookmarks($0) },
                setBookmark: { [quizDetail] quizID, projectID, isBookmarked in
                    isBookmarked
                        ? try await quizDetail.bookmark(
                            quizID,
                            in: projectID,
                        )
                        : try await quizDetail.unbookmark(
                            quizID,
                            in: projectID,
                        )
                },
            )
        }
        Scope(
            state: \.settings,
            action: \.settings,
        ) {
            SettingsRouterFeature(
                account: account,
                userInfo: userInfo,
                appSetting: appSetting,
                openNotificationSettings: openNotificationSettings,
            )
        }
        Reduce { state, action in
            switch action {
            case .input(let action):
                reduce(
                    into: &state,
                    input: action,
                )

            case .view(let action):
                reduce(
                    into: &state,
                    view: action,
                )

            case .home(let action):
                reduce(
                    into: &state,
                    home: action,
                )

            case .projectList(let action):
                reduce(
                    into: &state,
                    projectList: action,
                )

            case .saved(let action):
                reduce(
                    into: &state,
                    saved: action,
                )

            case .settings(let action):
                reduce(
                    into: &state,
                    settings: action,
                )

            case .singleQuestionEntry(let action):
                reduce(
                    into: &state,
                    singleQuestionEntry: action,
                )

            case .singleQuestion(let action):
                reduce(
                    into: &state,
                    singleQuestion: action,
                )

            case .delegate:
                .none
            }
        }
        .ifLet(
            \.singleQuestionEntry,
            action: \.singleQuestionEntry,
        ) {
            SingleQuestionEntryFeature(fetchQuizSet: { [quizDetail] in try await quizDetail.quizSet(
                $0,
                in: $1,
            ) })
        }
        .ifLet(
            \.$singleQuestion,
            action: \.singleQuestion,
        ) {
            QuestionSolvingFeature(
                gradeChoiceAnswer: { [quizDetail] in try await quizDetail.grade($0) },
                gradeEssayAnswer: { [quizDetail] in try await quizDetail.grade($0) },
                setBookmark: { [quizDetail] quizID, projectID, isBookmarked in
                    isBookmarked
                        ? try await quizDetail.bookmark(
                            quizID,
                            in: projectID,
                        )
                        : try await quizDetail.unbookmark(
                            quizID,
                            in: projectID,
                        )
                },
            )
        }
    }

    // MARK: Private

    private let project: any ProjectUseCase
    private let quizDetail: any QuizDetailUseCase
    private let account: any AccountUseCase
    private let userInfo: any UserInfoUseCase
    private let appSetting: any AppSettingUseCase
    private let openNotificationSettings: @MainActor @Sendable () async -> Void

    private static func profile(from userInfo: any UserInfoUseCase) async throws -> UserProfile {
        async let detail = userInfo.detail()
        async let curation = userInfo.curation()
        return try await UserProfile(
            detail: detail,
            curation: curation,
        )
    }

    private func reduce(
        into state: inout State,
        input action: Action.Input,
    ) -> ComposableArchitecture.Effect<Action> {
        switch action {
        case .learningProjectsReloadRequested:
            guard state.access == .member else { return .none }
            return reloadLearningProjects()

        case .memberAccessGranted:
            guard state.access == .guest else { return .none }
            state.access = .member
            return .merge(
                .send(.home(.input(.accessChanged(.member)))),
                .send(.projectList(.input(.learningProjectsReloadRequested))),
            )
        }
    }

    private func reduce(
        into state: inout State,
        view action: Action.View,
    ) -> ComposableArchitecture.Effect<Action> {
        switch action {
        case .tabSelected(let tab):
            guard state.access == .member else {
                guard tab == .home else {
                    state.isSignInRequiredAlertPresented = true
                    return .none
                }
                state.selectedTab = tab
                return .none
            }
            state.selectedTab = tab
            return reloadLearningProjects()

        case .signInRequiredAlertSignInTapped:
            state.isSignInRequiredAlertPresented = false
            return .send(.delegate(.onboardingRequested))

        case .signInRequiredAlertDismissed:
            state.isSignInRequiredAlertPresented = false
            return .none

        case .singleQuestionFailureDismissed:
            return .send(.singleQuestionEntry(.input(.failureDismissed)))
        }
    }

    private func reduce(
        into state: inout State,
        home action: HomeFeature.Action,
    ) -> ComposableArchitecture.Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .signInRequired:
            guard state.access == .guest else { return .none }
            state.isSignInRequiredAlertPresented = true
            return .none

        case .allProjectsRequested:
            state.selectedTab = .projects
            return reloadLearningProjects()

        case .projectRegistrationRequested:
            return .send(.delegate(.projectRegistrationRequested))

        case .projectDetailRequested(let projectID):
            return .send(.delegate(.projectDetailRequested(projectID: projectID)))

        case .learningRequested(let projectID, let nextSetID):
            return .send(.delegate(.learningRequested(
                projectID: projectID,
                nextSetID: nextSetID,
            )))
        }
    }

    private func reduce(
        into _: inout State,
        projectList action: ProjectListFeature.Action,
    ) -> ComposableArchitecture.Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .projectDeleted:
            return .send(.home(.input(.learningProjectsReloadRequested)))

        case .projectSelected(let projectID):
            return .send(.delegate(.projectDetailRequested(projectID: projectID)))

        case .learningRequested(let projectID, let nextSetID):
            return .send(.delegate(.learningRequested(
                projectID: projectID,
                nextSetID: nextSetID,
            )))
        }
    }

    private func reduce(
        into state: inout State,
        saved action: SavedFeature.Action,
    ) -> ComposableArchitecture.Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .questionSelected(let question):
            state.singleQuestionEntry = SingleQuestionEntryFeature.State(projectID: question.projectID)
            return .send(.singleQuestionEntry(.input(.questionRequested(
                setID: question.setID,
                questionID: question.quizID,
            ))))

        case .backRequested:
            return .none
        }
    }

    private func reduce(
        into state: inout State,
        settings action: SettingsRouterFeature.Action,
    ) -> ComposableArchitecture.Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .externalURLRequested(let url):
            return .send(.delegate(.externalURLRequested(url)))

        case .signedOut,
             .accountDeleted:
            state = MainShellRouterFeature.State()
            return .send(.delegate(.loggedOut))
        }
    }

    private func reduce(
        into state: inout State,
        singleQuestionEntry action: SingleQuestionEntryFeature.Action,
    ) -> ComposableArchitecture.Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .questionPrepared(let question, let projectID):
            state.singleQuestion = QuestionSolvingFeature.State(
                projectID: projectID,
                question: question,
                advanceActionTitle: Self.singleQuestionAdvanceActionTitle,
                isBookmarked: true,
            )
            return .none

        case .preparationFailed:
            return .none
        }
    }

    private func reduce(
        into state: inout State,
        singleQuestion action: PresentationAction<QuestionSolvingFeature.Action>,
    ) -> ComposableArchitecture.Effect<Action> {
        guard
            case .presented(let action) = action,
            case .delegate(let action) = action
        else {
            return .none
        }
        switch action {
        case .advanceRequested,
             .backRequested:
            state.singleQuestion = nil
            return .none

        case .externalURLRequested(let url):
            return .send(.delegate(.externalURLRequested(url)))

        case .answerSubmitted:
            return .none
        }
    }

    private func reloadLearningProjects() -> ComposableArchitecture.Effect<Action> {
        .merge(
            .send(.home(.input(.learningProjectsReloadRequested))),
            .send(.projectList(.input(.learningProjectsReloadRequested))),
        )
    }

}
