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
        deleteLearningProject: any DeleteLearningProjectUseCase,
        fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase,
        fetchLearningSet: any FetchLearningSetUseCase,
        submitChoiceAnswer: any SubmitChoiceAnswerUseCase,
        submitEssayAnswer: any SubmitEssayAnswerUseCase,
        setQuestionBookmark: any SetQuestionBookmarkUseCase,
        signOut: any SignOutUseCase,
        fetchMemberProfile: any FetchMemberProfileUseCase,
        updateMemberPosition: any UpdateMemberPositionUseCase,
        updateMemberCareerLevel: any UpdateMemberCareerLevelUseCase,
        deleteMemberAccount: any DeleteMemberAccountUseCase,
        observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase,
        requestGenerationReminder: any RequestGenerationReminderUseCase,
        openNotificationSettings: @escaping @MainActor @Sendable () async -> Void = { },
    ) {
        self.fetchLearningProjects = fetchLearningProjects
        self.deleteLearningProject = deleteLearningProject
        self.fetchBookmarkedQuestions = fetchBookmarkedQuestions
        self.fetchLearningSet = fetchLearningSet
        self.submitChoiceAnswer = submitChoiceAnswer
        self.submitEssayAnswer = submitEssayAnswer
        self.setQuestionBookmark = setQuestionBookmark
        self.signOut = signOut
        self.fetchMemberProfile = fetchMemberProfile
        self.updateMemberPosition = updateMemberPosition
        self.updateMemberCareerLevel = updateMemberCareerLevel
        self.deleteMemberAccount = deleteMemberAccount
        self.observeGenerationOutcomes = observeGenerationOutcomes
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
        case delegate(Delegate)
        case home(HomeFeature.Action)
        case projectList(ProjectListFeature.Action)
        case saved(SavedFeature.Action)
        case settings(SettingsRouterFeature.Action)
        case singleQuestionEntry(SingleQuestionEntryFeature.Action)
        case singleQuestion(PresentationAction<QuestionSolvingFeature.Action>)

        // MARK: Public

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
                fetchMemberProfile: fetchMemberProfile,
                observeGenerationOutcomes: observeGenerationOutcomes,
            )
        }
        Scope(state: \.projectList, action: \.projectList) {
            ProjectListFeature(
                fetchLearningProjects: fetchLearningProjects,
                deleteLearningProject: deleteLearningProject,
            )
        }
        Scope(state: \.saved, action: \.saved) {
            SavedFeature(
                fetchBookmarkedQuestions: fetchBookmarkedQuestions,
                setQuestionBookmark: setQuestionBookmark,
            )
        }
        Scope(state: \.settings, action: \.settings) {
            SettingsRouterFeature(
                signOut: signOut,
                fetchMemberProfile: fetchMemberProfile,
                updateMemberPosition: updateMemberPosition,
                updateMemberCareerLevel: updateMemberCareerLevel,
                deleteMemberAccount: deleteMemberAccount,
                requestGenerationReminder: requestGenerationReminder,
                openNotificationSettings: openNotificationSettings,
            )
        }
        Reduce { state, action in
            switch action {
            case .view(.tabSelected(let tab)):
                state.selectedTab = tab
                return .none

            case .home(.view(.showAllProjectsTapped)):
                state.selectedTab = .projects
                return .none

            case .home(.delegate(.projectRegistrationRequested)):
                return .send(.delegate(.projectRegistrationRequested))

            case .home(.delegate(.projectDetailRequested(let projectID))):
                return .send(.delegate(.projectDetailRequested(projectID: projectID)))

            case .home(.delegate(.learningRequested(let projectID, let nextSetID))):
                return .send(.delegate(.learningRequested(projectID: projectID, nextSetID: nextSetID)))

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
            SingleQuestionEntryFeature(fetchLearningSet: fetchLearningSet)
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
    private let deleteLearningProject: any DeleteLearningProjectUseCase
    private let fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase
    private let fetchLearningSet: any FetchLearningSetUseCase
    private let submitChoiceAnswer: any SubmitChoiceAnswerUseCase
    private let submitEssayAnswer: any SubmitEssayAnswerUseCase
    private let setQuestionBookmark: any SetQuestionBookmarkUseCase
    private let signOut: any SignOutUseCase
    private let fetchMemberProfile: any FetchMemberProfileUseCase
    private let updateMemberPosition: any UpdateMemberPositionUseCase
    private let updateMemberCareerLevel: any UpdateMemberCareerLevelUseCase
    private let deleteMemberAccount: any DeleteMemberAccountUseCase
    private let observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase
    private let requestGenerationReminder: any RequestGenerationReminderUseCase
    private let openNotificationSettings: @MainActor @Sendable () async -> Void

}
