import ComposableArchitecture
import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation

@Reducer
public struct MainShellRouterFeature: Sendable {

    // MARK: Lifecycle

    public init(
        fetchLearningProjects: any FetchLearningProjectsUseCase,
        learningLibrary: any LearningLibraryUseCase,
        submitChoiceAnswer: any SubmitChoiceAnswerUseCase,
        submitEssayAnswer: any SubmitEssayAnswerUseCase,
        setQuestionBookmark: any SetQuestionBookmarkUseCase,
        signOut: any SignOutUseCase,
        memberAccount: any MemberAccountUseCase,
        deleteMemberAccount: any DeleteMemberAccountUseCase,
        trackGeneration: any TrackGenerationUseCase,
        requestGenerationReminder: any RequestGenerationReminderUseCase,
        openNotificationSettings: @escaping @MainActor @Sendable () async -> Void = { },
    ) {
        self.fetchLearningProjects = fetchLearningProjects
        self.learningLibrary = learningLibrary
        self.submitChoiceAnswer = submitChoiceAnswer
        self.submitEssayAnswer = submitEssayAnswer
        self.setQuestionBookmark = setQuestionBookmark
        self.signOut = signOut
        self.memberAccount = memberAccount
        self.deleteMemberAccount = deleteMemberAccount
        self.trackGeneration = trackGeneration
        self.requestGenerationReminder = requestGenerationReminder
        self.openNotificationSettings = openNotificationSettings
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {
        public init() { }

        public var selectedTab = MainShellTab.home
        public var home = HomeFeature.State()
        public var projectList = ProjectListFeature.State()
        public var saved = SavedFeature.State()
        public var settings = SettingsRouterFeature.State()
        public var singleQuestionEntry: SingleQuestionEntryFeature.State?
        @Presents public var singleQuestion: QuestionSolvingFeature.State?
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
        }

        @CasePathable
        public enum View: Sendable, Equatable {
            case tabSelected(MainShellTab)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case projectRegistrationRequested
            case projectDetailRequested(projectID: String)
            case learningRequested(projectID: String, nextSetID: String)
            case externalURLRequested(URL)
            case loggedOut
        }
    }

    public static let singleQuestionAdvanceActionTitle = "완료"

    public var body: some ReducerOf<Self> {
        Scope(state: \.home, action: \.home) {
            HomeFeature(
                fetchLearningProjects: fetchLearningProjects,
                fetchMemberProfile: { [memberAccount] in try await memberAccount.profile() },
                trackGeneration: trackGeneration,
            )
        }
        Scope(state: \.projectList, action: \.projectList) {
            ProjectListFeature(
                fetchLearningProjects: fetchLearningProjects,
                deleteLearningProject: { [learningLibrary] in try await learningLibrary.deleteProject(id: $0) },
            )
        }
        Scope(state: \.saved, action: \.saved) {
            SavedFeature(
                fetchBookmarkedQuestions: { [learningLibrary] in try await learningLibrary.bookmarkedQuestions(projectID: $0) },
                setQuestionBookmark: setQuestionBookmark,
            )
        }
        Scope(state: \.settings, action: \.settings) {
            SettingsRouterFeature(
                signOut: signOut,
                memberAccount: memberAccount,
                deleteMemberAccount: deleteMemberAccount,
                requestGenerationReminder: requestGenerationReminder,
                openNotificationSettings: openNotificationSettings,
            )
        }
        Reduce { state, action in
            switch action {
            case .input(.learningProjectsReloadRequested):
                return reloadLearningProjects()

            case .view(.tabSelected(let tab)):
                state.selectedTab = tab
                return reloadLearningProjects()

            case .home(.view(.showAllProjectsTapped)):
                state.selectedTab = .projects
                return reloadLearningProjects()

            case .home(.delegate(.projectRegistrationRequested)):
                return .send(.delegate(.projectRegistrationRequested))

            case .home(.delegate(.projectDetailRequested(let projectID))):
                return .send(.delegate(.projectDetailRequested(projectID: projectID)))

            case .home(.delegate(.learningRequested(let projectID, let nextSetID))):
                return .send(.delegate(.learningRequested(projectID: projectID, nextSetID: nextSetID)))

            case .projectList(.delegate(.projectDeleted)):
                return .send(.home(.input(.learningProjectsReloadRequested)))

            case .projectList(.delegate(.projectSelected(let projectID))):
                return .send(.delegate(.projectDetailRequested(projectID: projectID)))

            case .projectList(.delegate(.learningRequested(let projectID, let nextSetID))):
                return .send(.delegate(.learningRequested(projectID: projectID, nextSetID: nextSetID)))

            case .saved(.delegate(.questionSelected(let question))):
                state.singleQuestionEntry = SingleQuestionEntryFeature.State(projectID: question.projectID)
                return .send(.singleQuestionEntry(.input(.questionRequested(
                    setID: question.setID,
                    questionID: question.questionID,
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
                 .delegate:
                return .none
            }
        }
        .ifLet(\.singleQuestionEntry, action: \.singleQuestionEntry) {
            SingleQuestionEntryFeature(fetchLearningSet: { [learningLibrary] in try await learningLibrary.learningSet(projectID: $0, setID: $1) })
        }
        .ifLet(\.$singleQuestion, action: \.singleQuestion) {
            QuestionSolvingFeature(
                submitChoiceAnswer: submitChoiceAnswer,
                submitEssayAnswer: submitEssayAnswer,
                setQuestionBookmark: setQuestionBookmark,
            )
        }
    }

    // MARK: Private

    private let fetchLearningProjects: any FetchLearningProjectsUseCase
    private let learningLibrary: any LearningLibraryUseCase
    private let submitChoiceAnswer: any SubmitChoiceAnswerUseCase
    private let submitEssayAnswer: any SubmitEssayAnswerUseCase
    private let setQuestionBookmark: any SetQuestionBookmarkUseCase
    private let signOut: any SignOutUseCase
    private let memberAccount: any MemberAccountUseCase
    private let deleteMemberAccount: any DeleteMemberAccountUseCase
    private let trackGeneration: any TrackGenerationUseCase
    private let requestGenerationReminder: any RequestGenerationReminderUseCase
    private let openNotificationSettings: @MainActor @Sendable () async -> Void

    private func reloadLearningProjects() -> ComposableArchitecture.Effect<Action> {
        .merge(
            .send(.home(.input(.learningProjectsReloadRequested))),
            .send(.projectList(.input(.learningProjectsReloadRequested))),
        )
    }

}
