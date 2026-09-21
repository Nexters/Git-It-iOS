import ComposableArchitecture
import DomainIdentifier
import DomainProject
import DomainUserInfo

@Reducer
public struct HomeFeature: Sendable {

    // MARK: Lifecycle

    public init(
        projects: @escaping @Sendable () async -> AsyncStream<ProjectList>,
        refreshProjects: @escaping @Sendable () async throws -> Void,
        profile: @escaping @Sendable () async throws -> UserProfile,
    ) {
        self.projects = projects
        self.refreshProjects = refreshProjects
        self.profile = profile
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init() { }

        // MARK: Public

        public var profile = UserProfileLoadFeature.State()
        public var projectSummaries = ProjectSummaryListFeature.State()

        public var isGenerationInProgress = false

        public var access = MainShellAccess.member
        public var isSignInRequiredAlertPresented = false

    }

    public enum Action: ViewAction, Equatable, Sendable {
        case view(View)
        case input(Input)
        case delegate(Delegate)
        case profile(UserProfileLoadFeature.Action)
        case projectSummaries(ProjectSummaryListFeature.Action)

        // MARK: Public

        @CasePathable
        public enum View: Equatable, Sendable {
            case task
            case profileRetryTapped
            case projectRetryTapped
            case projectRegistrationTapped
            case showAllProjectsTapped
            case projectCardTapped(projectID: ProjectID)
            case learningTapped(projectID: ProjectID)
            case signInTapped
            case signInRequiredAlertSignInTapped
            case signInRequiredAlertDismissed
        }

        @CasePathable
        public enum Input: Equatable, Sendable {
            case learningProjectsReloadRequested
            case generationProgressChanged(isInProgress: Bool)
            case accessChanged(MainShellAccess)
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            case projectRegistrationRequested
            case projectDetailRequested(projectID: ProjectID)
            case learningRequested(projectID: ProjectID, nextSetID: QuizSetID)
            case signInRequested
            case allProjectsRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Scope(state: \.profile, action: \.profile) {
            UserProfileLoadFeature(profile: profile)
        }
        Scope(state: \.projectSummaries, action: \.projectSummaries) {
            ProjectSummaryListFeature(projects: projects, refreshProjects: refreshProjects)
        }
        Reduce { state, action in
            switch action {
            case .view(.task):
                guard state.access == .member else { return .none }
                return startAccountLoad(state: &state)

            case .input(.learningProjectsReloadRequested):
                guard state.access == .member else { return .none }
                return .send(.projectSummaries(.input(.refresh)))

            case .input(.accessChanged(let access)):
                let previousAccess = state.access
                state.access = access
                guard previousAccess == .guest, access == .member else { return .none }
                return startAccountLoad(state: &state)

            case .view(.profileRetryTapped):
                guard state.access == .member, case .failed = state.profile.load else { return .none }
                return .send(.profile(.input(.load)))

            case .view(.projectRetryTapped):
                guard state.access == .member, case .failed = state.projectSummaries.load else { return .none }
                return .send(.projectSummaries(.input(.refresh)))

            case .input(.generationProgressChanged(let isInProgress)):
                state.isGenerationInProgress = isInProgress
                return .none

            case .view(.projectRegistrationTapped):
                guard state.access == .member else {
                    state.isSignInRequiredAlertPresented = true
                    return .none
                }
                guard !state.isGenerationInProgress else { return .none }
                return .send(.delegate(.projectRegistrationRequested))

            case .view(.showAllProjectsTapped):
                guard state.access == .member else { return .none }
                return .send(.delegate(.allProjectsRequested))

            case .view(.signInTapped):
                guard state.access == .guest else { return .none }
                return .send(.delegate(.signInRequested))

            case .view(.signInRequiredAlertSignInTapped):
                state.isSignInRequiredAlertPresented = false
                return .send(.delegate(.signInRequested))

            case .view(.signInRequiredAlertDismissed):
                state.isSignInRequiredAlertPresented = false
                return .none

            case .view(.projectCardTapped(let projectID)):
                return .send(.delegate(.projectDetailRequested(projectID: projectID)))

            case .view(.learningTapped(let projectID)):
                guard
                    case .loaded(let list) = state.projectSummaries.load,
                    let summary = list.summaries.first(where: { $0.id == projectID }),
                    let next = summary.next,
                    next.quizID != nil
                else { return .none }
                return .send(
                    .delegate(.learningRequested(projectID: projectID, nextSetID: next.setID))
                )

            case .profile,
                 .projectSummaries,
                 .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private let projects: @Sendable () async -> AsyncStream<ProjectList>
    private let refreshProjects: @Sendable () async throws -> Void
    private let profile: @Sendable () async throws -> UserProfile

    private func startAccountLoad(state: inout State) -> ComposableArchitecture.Effect<Action> {
        var effects = [ComposableArchitecture.Effect<Action>]()
        if state.profile.load == .idle {
            effects.append(.send(.profile(.input(.load))))
        }
        effects.append(.send(.projectSummaries(.input(.start))))
        return .merge(effects)
    }

}
