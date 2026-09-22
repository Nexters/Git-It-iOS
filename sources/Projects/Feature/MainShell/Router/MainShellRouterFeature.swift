import ComposableArchitecture
import DomainAccount
import DomainAppSetting
import DomainIdentifier
import DomainProject
import DomainQuizDetail
import DomainUserInfo
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
        public var signIn = SignInFeature.State()
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
        case signIn(SignInFeature.Action)

        // MARK: Public

        @CasePathable
        public enum Input: Sendable, Equatable {
            case learningProjectsReloadRequested
            case memberAccessGranted
        }

        @CasePathable
        public enum View: Sendable, Equatable {
            case tabSelected(MainShellTab)
            case signInTapped
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case projectRegistrationRequested
            case projectDetailRequested(projectID: ProjectID)
            case learningRequested(projectID: ProjectID, nextSetID: QuizSetID)
            case externalURLRequested(URL)
            case loggedOut
            case signInSucceeded(needsCuration: Bool)
        }
    }

    public static let singleQuestionAdvanceActionTitle = "완료"

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
        Scope(
            state: \.signIn,
            action: \.signIn,
        ) {
            SignInFeature(
                signIn: { [account] in await account.signIn(with: $0) },
                policyConsentStatus: { [account] in try await account.policyConsentStatus() },
                consent: { [account] in try await account.consent(to: $0) },
            )
        }
        Reduce { state, action in
            switch action {
            case .input(.learningProjectsReloadRequested):
                guard state.access == .member else { return .none }
                return reloadLearningProjects()

            case .input(.memberAccessGranted):
                guard state.access == .guest else { return .none }
                state.access = .member
                return .merge(
                    .send(.home(.input(.accessChanged(.member)))),
                    .send(.projectList(.input(.learningProjectsReloadRequested))),
                )

            case .view(.tabSelected(let tab)):
                guard state.access == .member else {
                    guard tab == .home || tab == .settings else { return .none }
                    state.selectedTab = tab
                    return .none
                }
                state.selectedTab = tab
                return reloadLearningProjects()

            case .view(.signInTapped),
                 .home(.delegate(.signInRequested)):
                guard state.access == .guest else { return .none }
                return .send(.signIn(.input(.start)))

            case .signIn(.delegate(.signedIn(let needsCuration))):
                return .send(.delegate(.signInSucceeded(needsCuration: needsCuration)))

            case .home(.delegate(.allProjectsRequested)):
                state.selectedTab = .projects
                return reloadLearningProjects()

            case .home(.delegate(.projectRegistrationRequested)):
                return .send(.delegate(.projectRegistrationRequested))

            case .home(.delegate(.projectDetailRequested(let projectID))):
                return .send(.delegate(.projectDetailRequested(projectID: projectID)))

            case .home(.delegate(.learningRequested(let projectID, let nextSetID))):
                return .send(.delegate(.learningRequested(
                    projectID: projectID,
                    nextSetID: nextSetID,
                )))

            case .projectList(.delegate(.projectDeleted)):
                return .send(.home(.input(.learningProjectsReloadRequested)))

            case .projectList(.delegate(.projectSelected(let projectID))):
                return .send(.delegate(.projectDetailRequested(projectID: projectID)))

            case .projectList(.delegate(.learningRequested(let projectID, let nextSetID))):
                return .send(.delegate(.learningRequested(
                    projectID: projectID,
                    nextSetID: nextSetID,
                )))

            case .saved(.delegate(.questionSelected(let question))):
                state.singleQuestionEntry = SingleQuestionEntryFeature.State(projectID: question.projectID)
                return .send(.singleQuestionEntry(.input(.questionRequested(
                    setID: question.setID,
                    questionID: question.quizID,
                ))))

            case .singleQuestionEntry(.delegate(.questionPrepared(let question, let projectID))):
                state.singleQuestion = QuestionSolvingFeature.State(
                    projectID: projectID,
                    question: question,
                    advanceActionTitle: Self.singleQuestionAdvanceActionTitle,
                    isBookmarked: true,
                )
                return .none

            case .singleQuestionEntry(.delegate(.preparationFailed)):
                return .none

            case .singleQuestion(.presented(.delegate(.advanceRequested))),
                 .singleQuestion(.presented(.delegate(.backRequested))):
                state.singleQuestion = nil
                return .none

            case .singleQuestion(.presented(.delegate(.externalURLRequested(let url)))):
                return .send(.delegate(.externalURLRequested(url)))

            case .settings(.delegate(.externalURLRequested(let url))):
                return .send(.delegate(.externalURLRequested(url)))

            case .settings(.delegate(.signedOut)),
                 .settings(.delegate(.accountDeleted)):
                state = MainShellRouterFeature.State()
                return .send(.delegate(.loggedOut))

            case .home,
                 .projectList,
                 .saved,
                 .settings,
                 .singleQuestionEntry,
                 .singleQuestion,
                 .signIn,
                 .delegate:
                return .none
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

    private func reloadLearningProjects() -> ComposableArchitecture.Effect<Action> {
        .merge(
            .send(.home(.input(.learningProjectsReloadRequested))),
            .send(.projectList(.input(.learningProjectsReloadRequested))),
        )
    }

}
