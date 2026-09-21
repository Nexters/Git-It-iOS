import ComposableArchitecture
import DomainIdentifier
import DomainProject
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
        public var pagination = Pagination.idle
        public var mode = Mode.browsing
        public var deletion = ProjectDeletionFeature.State()

        public var projects: [ProjectSummary] {
            projectSummaries.list?.summaries ?? []
        }

        public var hasNextPage: Bool {
            projectSummaries.list?.hasNextPage ?? false
        }
    }

    public enum Pagination: Equatable, Sendable {
        case idle
        case loading
        case failed(ProjectError)
        case exhausted
    }

    public enum Mode: Equatable, Sendable {
        case browsing
        case menuPresented
        case deleting
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case input(Input)
        case effect(EffectEvent)
        case delegate(Delegate)
        case projectSummaries(ProjectSummaryListFeature.Action)
        case deletion(ProjectDeletionFeature.Action)

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
        public enum EffectEvent: Sendable, Equatable {
            case nextPageFinished(error: ProjectError?)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case projectSelected(projectID: ProjectID)
            case learningRequested(projectID: ProjectID, nextSetID: QuizSetID)
            case projectDeleted
        }
    }

    public var body: some ReducerOf<Self> {
        Scope(state: \.projectSummaries, action: \.projectSummaries) {
            ProjectSummaryListFeature(projects: projects, refreshProjects: refreshProjects)
        }
        Scope(state: \.deletion, action: \.deletion) {
            ProjectDeletionFeature(deleteProject: deleteProject)
        }
        Reduce { state, action in
            switch action {
            case .view(.task):
                return .merge(
                    .cancel(id: CancelID.nextPage),
                    .send(.projectSummaries(.input(.start))),
                )

            case .view(.refreshRequested),
                 .input(.learningProjectsReloadRequested):
                return .merge(
                    .cancel(id: CancelID.nextPage),
                    .send(.projectSummaries(.input(.refresh))),
                )

            case .view(.listBottomReached):
                guard
                    state.projectSummaries.load.isLoaded,
                    state.hasNextPage,
                    state.pagination == .idle
                else { return .none }
                return startNextPageLoad(state: &state)

            case .view(.nextPageRetryTapped):
                guard case .failed = state.pagination else { return .none }
                return startNextPageLoad(state: &state)

            case .view(.projectRowTapped(let projectID)):
                guard state.mode != .deleting else { return .none }
                return .send(.delegate(.projectSelected(projectID: projectID)))

            case .view(.learningTapped(let projectID)):
                guard state.mode != .deleting else { return .none }
                guard
                    let summary = state.projects.first(where: { $0.id == projectID }),
                    let next = summary.next,
                    next.quizID != nil
                else { return .none }
                return .send(.delegate(.learningRequested(projectID: projectID, nextSetID: next.setID)))

            case .view(.menuTapped):
                guard state.mode == .browsing else { return .none }
                state.mode = .menuPresented
                return .none

            case .view(.menuDismissed):
                guard state.mode == .menuPresented else { return .none }
                state.mode = .browsing
                return .none

            case .view(.deletionMenuItemTapped):
                guard state.mode == .menuPresented else { return .none }
                state.mode = .deleting
                return .none

            case .view(.backTapped):
                guard state.mode == .deleting else { return .none }
                state.mode = .browsing
                return .send(.deletion(.input(.cancel)))

            case .view(.deleteButtonTapped(let projectID)):
                guard state.mode == .deleting else { return .none }
                return .send(.deletion(.input(.request(projectID))))

            case .view(.deletionCancelled):
                return .send(.deletion(.input(.cancel)))

            case .view(.deletionConfirmed):
                return .send(.deletion(.input(.confirm)))

            case .deletion(.delegate(.deleted(let projectID))):
                return .merge(
                    .send(.projectSummaries(.input(.projectRemoved(projectID)))),
                    .send(.delegate(.projectDeleted)),
                )

            case .projectSummaries(.delegate(.listUpdated(let list))):
                state.pagination = list.hasNextPage ? .idle : .exhausted
                if list.summaries.isEmpty, state.mode == .deleting {
                    state.mode = .browsing
                }
                return .none

            case .effect(.nextPageFinished(let error)):
                guard case .loading = state.pagination else { return .none }
                if let error {
                    state.pagination = .failed(error)
                } else {
                    state.pagination = state.hasNextPage ? .idle : .exhausted
                }
                return .none

            case .projectSummaries,
                 .deletion,
                 .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case nextPage
    }

    private let projects: @Sendable () async -> AsyncStream<ProjectList>
    private let refreshProjects: @Sendable () async throws -> Void
    private let requestNextPage: @Sendable () async throws -> Void
    private let deleteProject: @Sendable (ProjectID) async throws -> Void

    private func startNextPageLoad(state: inout State) -> ComposableArchitecture.Effect<Action> {
        state.pagination = .loading
        let requestNextPage = requestNextPage

        return .run { send in
            do {
                try await requestNextPage()
                await send(.effect(.nextPageFinished(error: nil)))
            } catch {
                let mapped = error as? ProjectError ?? .unexpected
                await send(.effect(.nextPageFinished(error: mapped)))
            }
        }
        .cancellable(id: CancelID.nextPage, cancelInFlight: true)
    }

}
