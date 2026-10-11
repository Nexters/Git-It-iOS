import ComposableArchitecture
import DomainUseCaseInterface
import Foundation

// MARK: - ProjectListFeature

@Reducer
public struct ProjectListFeature: Sendable {

    // MARK: Lifecycle

    public init(
        projects: @escaping @Sendable () async -> AsyncStream<ProjectList>,
        refreshProjects: @escaping @Sendable () async throws -> Void,
        requestNextPage: @escaping @Sendable () async throws -> Void,
        deleteProject: @escaping @Sendable (ProjectID) async throws -> Void,
    ) {
        self.projects = projects
        self.refreshProjects = refreshProjects
        self.requestNextPage = requestNextPage
        self.deleteProject = deleteProject
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {
        public init() { }

        public var projectSummaries = ProjectSummaryListFeature.State()
        public var pagination = ProjectListPaginationFeature.State()
        public var mode = Mode.browsing
        public var deletion = ProjectDeletionFeature.State()

        public var projects: [ProjectSummary] {
            projectSummaries.list?.summaries ?? []
        }

        public var hasNextPage: Bool {
            projectSummaries.list?.hasNextPage ?? false
        }
    }

    public enum Mode: Equatable, Sendable {
        case browsing
        case menuPresented
        case deleting
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case input(Input)
        case delegate(Delegate)
        case projectSummaries(ProjectSummaryListFeature.Action)
        case deletion(ProjectDeletionFeature.Action)
        case pagination(ProjectListPaginationFeature.Action)

        // MARK: Public

        @CasePathable
        public enum Input: Sendable, Equatable {
            case learningProjectsReloadRequested
        }

        @CasePathable
        public enum View: Sendable, Equatable {
            case task
            case refreshRequested
            case listBottomReached
            case nextPageRetryTapped
            case projectRowTapped(projectID: ProjectID)
            case learningTapped(projectID: ProjectID)
            case menuTapped
            case menuDismissed
            case deletionMenuItemTapped
            case backTapped
            case deleteButtonTapped(projectID: ProjectID)
            case deletionCancelled
            case deletionConfirmed
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case projectSelected(projectID: ProjectID)
            case learningRequested(projectID: ProjectID, nextSetID: QuizSetID)
            case projectDeleted
        }
    }

    public var body: some ReducerOf<Self> {
        Scope(
            state: \.projectSummaries,
            action: \.projectSummaries,
        ) {
            ProjectSummaryListFeature(
                projects: projects,
                refreshProjects: refreshProjects,
            )
        }
        Scope(
            state: \.deletion,
            action: \.deletion,
        ) {
            ProjectDeletionFeature(deleteProject: deleteProject)
        }
        Scope(
            state: \.pagination,
            action: \.pagination,
        ) {
            ProjectListPaginationFeature(requestNextPage: requestNextPage)
        }
        Reduce { state, action in
            switch action {
            case .view(let action):
                reduce(
                    into: &state,
                    view: action,
                )

            case .input(let action):
                reduce(
                    into: &state,
                    input: action,
                )

            case .delegate:
                .none

            case .projectSummaries(let action):
                reduce(
                    into: &state,
                    projectSummaries: action,
                )

            case .deletion(let action):
                reduce(
                    into: &state,
                    deletion: action,
                )

            case .pagination:
                .none
            }
        }
    }

    // MARK: Private

    private let projects: @Sendable () async -> AsyncStream<ProjectList>
    private let refreshProjects: @Sendable () async throws -> Void
    private let requestNextPage: @Sendable () async throws -> Void
    private let deleteProject: @Sendable (ProjectID) async throws -> Void

    private func reduce(
        into state: inout State,
        view action: Action.View,
    ) -> Effect<Action> {
        switch action {
        case .task:
            return .merge(
                .send(.pagination(.input(.refreshStarted))),
                .send(.projectSummaries(.input(.start))),
            )

        case .refreshRequested:
            return .merge(
                .send(.pagination(.input(.refreshStarted))),
                .send(.projectSummaries(.input(.refresh))),
            )

        case .listBottomReached:
            guard
                state.projectSummaries.load.isLoaded,
                state.hasNextPage
            else { return .none }
            return .send(.pagination(.input(.nextPageRequested)))

        case .nextPageRetryTapped:
            return .send(.pagination(.input(.retry)))

        case .projectRowTapped(let projectID):
            guard state.mode != .deleting else { return .none }
            return .send(.delegate(.projectSelected(projectID: projectID)))

        case .learningTapped(let projectID):
            guard state.mode != .deleting else { return .none }
            guard
                let summary = state.projects.first(where: { $0.id == projectID }),
                let next = summary.next,
                next.quizID != nil
            else { return .none }
            return .send(.delegate(.learningRequested(
                projectID: projectID,
                nextSetID: next.setID,
            )))

        case .menuTapped:
            guard state.mode == .browsing else { return .none }
            state.mode = .menuPresented
            return .none

        case .menuDismissed:
            guard state.mode == .menuPresented else { return .none }
            state.mode = .browsing
            return .none

        case .deletionMenuItemTapped:
            guard state.mode == .menuPresented else { return .none }
            state.mode = .deleting
            return .none

        case .backTapped:
            guard state.mode == .deleting else { return .none }
            state.mode = .browsing
            return .send(.deletion(.input(.cancel)))

        case .deleteButtonTapped(let projectID):
            guard state.mode == .deleting else { return .none }
            return .send(.deletion(.input(.request(projectID))))

        case .deletionCancelled:
            return .send(.deletion(.input(.cancel)))

        case .deletionConfirmed:
            return .send(.deletion(.input(.confirm)))
        }
    }

    private func reduce(
        into _: inout State,
        input action: Action.Input,
    ) -> Effect<Action> {
        switch action {
        case .learningProjectsReloadRequested:
            .merge(
                .send(.pagination(.input(.refreshStarted))),
                .send(.projectSummaries(.input(.refresh))),
            )
        }
    }

    private func reduce(
        into state: inout State,
        projectSummaries action: ProjectSummaryListFeature.Action,
    ) -> Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .listUpdated(let list):
            if list.summaries.isEmpty, state.mode == .deleting {
                state.mode = .browsing
            }
            return .send(.pagination(.input(.listReplaced(hasNextPage: list.hasNextPage))))
        }
    }

    private func reduce(
        into _: inout State,
        deletion action: ProjectDeletionFeature.Action,
    ) -> Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .deleted(let projectID):
            return .merge(
                .send(.projectSummaries(.input(.projectRemoved(projectID)))),
                .send(.delegate(.projectDeleted)),
            )
        }
    }

}
