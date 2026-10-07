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

        public var projects = [ProjectSummary]()
        public var hasNextPage = false
        public var initialLoad = InitialLoad.idle
        public var pagination = Pagination.idle
        public var mode = Mode.browsing
        public var deletion = Deletion.idle
        public var requestID = 0
    }

    public enum InitialLoad: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failed(ProjectError)
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

    public enum Deletion: Equatable, Sendable {
        case idle
        case confirming(projectID: ProjectID)
        case committing(projectID: ProjectID)
        case failed(projectID: ProjectID, error: ProjectError)
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case input(Input)
        case effect(EffectEvent)
        case delegate(Delegate)

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
            case projectsReceived(ProjectList)
            case refreshFinished(requestID: Int, error: ProjectError?)
            case nextPageFinished(error: ProjectError?)
            case deletionFinished(projectID: ProjectID, error: ProjectError?)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case projectSelected(projectID: ProjectID)
            case learningRequested(projectID: ProjectID, nextSetID: QuizSetID)
            case projectDeleted
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.task):
                return .merge(
                    observeProjects(),
                    startRefresh(state: &state),
                )

            case .view(.refreshRequested),
                 .input(.learningProjectsReloadRequested):
                return startRefresh(state: &state)

            case .view(.listBottomReached):
                guard
                    state.initialLoad == .loaded,
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
                state.deletion = .idle
                return .none

            case .view(.deleteButtonTapped(let projectID)):
                guard state.mode == .deleting, case .idle = state.deletion else { return .none }
                state.deletion = .confirming(projectID: projectID)
                return .none

            case .view(.deletionCancelled):
                if case .confirming = state.deletion {
                    state.deletion = .idle
                }
                return .none

            case .view(.deletionConfirmed):
                guard case .confirming(let projectID) = state.deletion else { return .none }
                state.deletion = .committing(projectID: projectID)
                return .run { send in
                    do {
                        try await deleteProject(projectID)
                        await send(.effect(.deletionFinished(projectID: projectID, error: nil)))
                    } catch {
                        let mapped = error as? ProjectError ?? .unexpected
                        await send(.effect(.deletionFinished(projectID: projectID, error: mapped)))
                    }
                }
                .cancellable(id: CancelID.deletion)

            case .effect(.projectsReceived(let list)):
                guard list.isLoaded else { return .none }
                state.projects = list.summaries
                state.hasNextPage = list.hasNextPage
                state.initialLoad = .loaded
                state.pagination = list.hasNextPage ? .idle : .exhausted
                if state.projects.isEmpty, state.mode == .deleting {
                    state.mode = .browsing
                }
                return .none

            case .effect(.refreshFinished(let requestID, let error)):
                guard requestID == state.requestID else { return .none }
                guard let error, state.initialLoad != .loaded else { return .none }
                state.initialLoad = .failed(error)
                return .none

            case .effect(.nextPageFinished(let error)):
                guard case .loading = state.pagination else { return .none }
                if let error {
                    state.pagination = .failed(error)
                } else {
                    state.pagination = state.hasNextPage ? .idle : .exhausted
                }
                return .none

            case .effect(.deletionFinished(let projectID, nil)),
                 .effect(.deletionFinished(let projectID, .some(.notFound))):
                state.projects.removeAll { $0.id == projectID }
                state.deletion = .idle
                if state.projects.isEmpty {
                    state.mode = .browsing
                }
                return .send(.delegate(.projectDeleted))

            case .effect(.deletionFinished(let projectID, .some(let error))):
                state.deletion = .failed(projectID: projectID, error: error)
                return .none

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case projects
        case refresh
        case nextPage
        case deletion
    }

    private let projects: @Sendable () async -> AsyncStream<ProjectList>
    private let refreshProjects: @Sendable () async throws -> Void
    private let requestNextPage: @Sendable () async throws -> Void
    private let deleteProject: @Sendable (ProjectID) async throws -> Void

    private func observeProjects() -> ComposableArchitecture.Effect<Action> {
        let projects = projects
        return .run { send in
            for await list in await projects() {
                await send(.effect(.projectsReceived(list)))
            }
        }
        .cancellable(id: CancelID.projects, cancelInFlight: true)
    }

    private func startRefresh(state: inout State) -> ComposableArchitecture.Effect<Action> {
        state.requestID += 1
        if state.projects.isEmpty {
            state.initialLoad = .loading
        }
        let requestID = state.requestID
        let refreshProjects = refreshProjects

        return .merge(
            .cancel(id: CancelID.nextPage),
            .run { send in
                do {
                    try await refreshProjects()
                    await send(.effect(.refreshFinished(requestID: requestID, error: nil)))
                } catch {
                    let mapped = error as? ProjectError ?? .unexpected
                    await send(.effect(.refreshFinished(requestID: requestID, error: mapped)))
                }
            }
            .cancellable(id: CancelID.refresh, cancelInFlight: true),
        )
    }

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
