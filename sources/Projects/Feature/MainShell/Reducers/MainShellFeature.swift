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
        observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase,
    ) {
        self.fetchLearningProjects = fetchLearningProjects
        self.deleteLearningProject = deleteLearningProject
        self.fetchBookmarkedQuestions = fetchBookmarkedQuestions
        self.signOut = signOut
        self.fetchMemberProfile = fetchMemberProfile
        self.updateMemberPosition = updateMemberPosition
        self.updateMemberCareerLevel = updateMemberCareerLevel
        self.deleteMemberAccount = deleteMemberAccount
        self.observeGenerationOutcomes = observeGenerationOutcomes
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {
        public init() { }

        public var selectedTab = MainShellTab.home
        public var home = HomeFeature.State()
        public var projectList = ProjectListFeature.State()
        public var saved = SavedFeature.State()
        public var settings = SettingsFeature.State()
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case delegate(Delegate)
        case home(HomeFeature.Action)
        case projectList(ProjectListFeature.Action)
        case saved(SavedFeature.Action)
        case settings(SettingsFeature.Action)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case tabSelected(MainShellTab)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case projectRegistrationRequested
            case projectDetailRequested(projectID: String)
            case learningRequested(projectID: String, nextSetID: String, nextQuestionID: String)
            case questionSelected(BookmarkedQuestion)
            case loggedOut
        }
    }

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

            case .home(.view(.showAllProjectsTapped)):
                state.selectedTab = .projects
                return .none

            case .home(.delegate(.projectRegistrationRequested)):
                return .send(.delegate(.projectRegistrationRequested))

            case .home(.delegate(.projectDetailRequested(let projectID))):
                return .send(.delegate(.projectDetailRequested(projectID: projectID)))

            case .home(.delegate(.learningRequested(let projectID, let nextSetID, let nextQuestionID))):
                return .send(
                    .delegate(
                        .learningRequested(
                            projectID: projectID,
                            nextSetID: nextSetID,
                            nextQuestionID: nextQuestionID,
                        )
                    )
                )

            case .projectList(.delegate(.projectSelected(let projectID))):
                return .send(.delegate(.projectDetailRequested(projectID: projectID)))

            case .saved(.delegate(.questionSelected(let question))):
                return .send(.delegate(.questionSelected(question)))

            case .settings(.delegate(.signedOut)),
                 .settings(.delegate(.accountDeleted)):
                state = MainShellFeature.State()
                return .send(.delegate(.loggedOut))

            case .home,
                 .projectList,
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
    private let observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase

}
