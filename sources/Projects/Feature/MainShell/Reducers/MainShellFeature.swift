import ComposableArchitecture
import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation

@Reducer
public struct MainShellFeature: Sendable {

    // MARK: Lifecycle

    public init(
        fetchLearningProjects: any FetchLearningProjectsUseCase,
        deleteLearningProject: any DeleteLearningProjectUseCase,
        fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase,
        signOut: any SignOutUseCase,
        fetchMemberProfile: any FetchMemberProfileUseCase,
        updateMemberPosition: any UpdateMemberPositionUseCase,
        updateMemberCareerLevel: any UpdateMemberCareerLevelUseCase,
        deleteMemberAccount: any DeleteMemberAccountUseCase,
    ) {
        self.fetchLearningProjects = fetchLearningProjects
        self.deleteLearningProject = deleteLearningProject
        self.fetchBookmarkedQuestions = fetchBookmarkedQuestions
        self.signOut = signOut
        self.fetchMemberProfile = fetchMemberProfile
        self.updateMemberPosition = updateMemberPosition
        self.updateMemberCareerLevel = updateMemberCareerLevel
        self.deleteMemberAccount = deleteMemberAccount
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {
        public init() { }

        public var selectedTab = MainShellTab.projects
        public var projectList = ProjectListFeature.State()
        public var saved = SavedFeature.State()
        public var settings = SettingsFeature.State()
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case delegate(Delegate)
        case projectList(ProjectListFeature.Action)
        case saved(SavedFeature.Action)
        case settings(SettingsFeature.Action)

        @CasePathable
        public enum View: Sendable, Equatable {
            case tabSelected(MainShellTab)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case projectSelected(projectID: String)
            case questionSelected(BookmarkedQuestion)
            case loggedOut
        }
    }

    public var body: some ReducerOf<Self> {
        Scope(state: \.projectList, action: \.projectList) {
            ProjectListFeature(
                fetchLearningProjects: fetchLearningProjects,
                deleteLearningProject: deleteLearningProject,
            )
        }
        Scope(state: \.saved, action: \.saved) {
            SavedFeature(fetchBookmarkedQuestions: fetchBookmarkedQuestions)
        }
        Scope(state: \.settings, action: \.settings) {
            SettingsFeature(
                signOut: signOut,
                fetchMemberProfile: fetchMemberProfile,
                updateMemberPosition: updateMemberPosition,
                updateMemberCareerLevel: updateMemberCareerLevel,
                deleteMemberAccount: deleteMemberAccount,
            )
        }
        Reduce { state, action in
            switch action {
            case .view(.tabSelected(let tab)):
                state.selectedTab = tab
                return .none

            case .projectList(.delegate(.projectSelected(let projectID))):
                return .send(.delegate(.projectSelected(projectID: projectID)))

            case .saved(.delegate(.questionSelected(let question))):
                return .send(.delegate(.questionSelected(question)))

            case .settings(.delegate(.signedOut)),
                 .settings(.delegate(.accountDeleted)):
                state.projectList = ProjectListFeature.State()
                state.saved = SavedFeature.State()
                state.settings = SettingsFeature.State()
                return .send(.delegate(.loggedOut))

            case .projectList,
                 .saved,
                 .settings,
                 .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private let fetchLearningProjects: any FetchLearningProjectsUseCase
    private let deleteLearningProject: any DeleteLearningProjectUseCase
    private let fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase
    private let signOut: any SignOutUseCase
    private let fetchMemberProfile: any FetchMemberProfileUseCase
    private let updateMemberPosition: any UpdateMemberPositionUseCase
    private let updateMemberCareerLevel: any UpdateMemberCareerLevelUseCase
    private let deleteMemberAccount: any DeleteMemberAccountUseCase

}
