import ComposableArchitecture
import DomainLearningProject
import Foundation

// MARK: - ProjectListFeature

@Reducer
public struct ProjectListFeature: Sendable {

    // MARK: Lifecycle

    public init(
        fetchLearningProjects: any FetchLearningProjectsUseCase,
        deleteLearningProject: any DeleteLearningProjectUseCase,
    ) {
        self.fetchLearningProjects = fetchLearningProjects
        self.deleteLearningProject = deleteLearningProject
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {
        public init() { }

        public var projects = [LearningProjectSummary]()
        public var initialLoad = InitialLoad.idle
        public var pagination = Pagination.idle(nextPage: LearningProjectPage.firstIndex)
        public var mode = Mode.browsing
        public var deletion = Deletion.idle
        public var requestID = 0
    }

    public enum InitialLoad: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failed(LearningProjectError)
    }

    public enum Pagination: Equatable, Sendable {
        case idle(nextPage: Int)
        case loading(nextPage: Int)
        case failed(nextPage: Int, error: LearningProjectError)
        case exhausted
    }

    public enum Mode: Equatable, Sendable {
        case browsing
        case menuPresented
        case deleting
    }

    public enum Deletion: Equatable, Sendable {
        case idle
        case confirming(projectID: String)
        case committing(projectID: String)
        case failed(projectID: String, error: LearningProjectError)
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
            case projectRowTapped(projectID: String)
            case learningTapped(projectID: String)
            case menuTapped
            case menuDismissed
            case deletionMenuItemTapped
            case backTapped
            case deleteButtonTapped(projectID: String)
            case deletionCancelled
            case deletionConfirmed
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case projectsLoadFinished(
                requestID: Int,
                page: Int,
                result: Result<LearningProjectPage, LearningProjectError>,
            )
            case deletionFinished(projectID: String, error: LearningProjectError?)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case projectSelected(projectID: String)
            case learningRequested(projectID: String, nextSetID: String)
            case projectDeleted
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.task),
                 .view(.refreshRequested),
                 .input(.learningProjectsReloadRequested):
                state.requestID += 1
                state.initialLoad = state.projects.isEmpty ? .loading : state.initialLoad
                return .merge(
                    .cancel(id: CancelID.nextPage),
                    projectsLoadEffect(requestID: state.requestID, page: LearningProjectPage.firstIndex)
                        .cancellable(id: CancelID.load, cancelInFlight: true),
                )

            case .view(.listBottomReached):
                guard
                    state.initialLoad == .loaded,
                    case .idle(let nextPage) = state.pagination
                else { return .none }
                return startNextPageLoad(state: &state, nextPage: nextPage)

            case .view(.nextPageRetryTapped):
                guard case .failed(let nextPage, _) = state.pagination else { return .none }
                return startNextPageLoad(state: &state, nextPage: nextPage)

            case .view(.projectRowTapped(let projectID)):
                guard state.mode != .deleting else { return .none }
                return .send(.delegate(.projectSelected(projectID: projectID)))

            case .view(.learningTapped(let projectID)):
                guard state.mode != .deleting else { return .none }
                guard
                    let project = state.projects.first(where: { $0.projectID == projectID }),
                    let nextSetID = project.nextSetID,
                    project.nextQuestionID != nil
                else { return .none }
                return .send(.delegate(.learningRequested(projectID: projectID, nextSetID: nextSetID)))

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
                        try await deleteLearningProject(projectID: projectID)
                        await send(.effect(.deletionFinished(projectID: projectID, error: nil)))
                    } catch {
                        let mapped = error as? LearningProjectError ?? .unexpected
                        await send(.effect(.deletionFinished(projectID: projectID, error: mapped)))
                    }
                }
                .cancellable(id: CancelID.deletion)

            case .effect(.projectsLoadFinished(let requestID, let page, let result)):
                guard requestID == state.requestID, isCurrentLoad(state: state, page: page) else { return .none }
                switch result {
                case .success(let loaded):
                    applyLoadedPage(state: &state, loaded: loaded, page: page)

                case .failure(let error):
                    if page == LearningProjectPage.firstIndex {
                        if state.projects.isEmpty {
                            state.initialLoad = .failed(error)
                        }
                    } else {
                        state.pagination = .failed(nextPage: page, error: error)
                    }
                }
                return .none

            case .effect(.deletionFinished(let projectID, nil)),
                 .effect(.deletionFinished(let projectID, .some(.notFound))):
                state.projects.removeAll { $0.projectID == projectID }
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
        case load
        case nextPage
        case deletion
    }

    private let fetchLearningProjects: any FetchLearningProjectsUseCase
    private let deleteLearningProject: any DeleteLearningProjectUseCase

    private func startNextPageLoad(
        state: inout State,
        nextPage: Int,
    ) -> ComposableArchitecture.Effect<Action> {
        state.pagination = .loading(nextPage: nextPage)
        return projectsLoadEffect(requestID: state.requestID, page: nextPage)
            .cancellable(id: CancelID.nextPage, cancelInFlight: true)
    }

    private func projectsLoadEffect(
        requestID: Int,
        page: Int,
    ) -> ComposableArchitecture.Effect<Action> {
        let fetchLearningProjects = fetchLearningProjects

        return .run { send in
            do {
                let loaded = try await fetchLearningProjects(page: page)
                await send(.effect(.projectsLoadFinished(
                    requestID: requestID,
                    page: page,
                    result: .success(loaded),
                )))
            } catch {
                let mapped = error as? LearningProjectError ?? .unexpected
                await send(.effect(.projectsLoadFinished(
                    requestID: requestID,
                    page: page,
                    result: .failure(mapped),
                )))
            }
        }
    }

    private func isCurrentLoad(
        state: State,
        page: Int,
    ) -> Bool {
        guard page != LearningProjectPage.firstIndex else { return true }
        guard case .loading(let loadingPage) = state.pagination else { return false }
        return loadingPage == page
    }

    private func applyLoadedPage(
        state: inout State,
        loaded: LearningProjectPage,
        page: Int,
    ) {
        if page == LearningProjectPage.firstIndex {
            state.projects = loaded.items
        } else {
            let loadedProjectIDs = Set(state.projects.map(\.projectID))
            state.projects.append(contentsOf: loaded.items.filter { !loadedProjectIDs.contains($0.projectID) })
        }
        state.initialLoad = .loaded
        state.pagination = loaded.hasNext ? .idle(nextPage: page + 1) : .exhausted
    }

}
