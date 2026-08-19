import ComposableArchitecture
import DomainLearningProject

@Reducer
public struct LearningProjectListFeature: Sendable {

    // MARK: Lifecycle

    public init(
        fetchLearningProjects: any FetchLearningProjects,
        deleteLearningProject: any DeleteLearningProject,
    ) {
        self.fetchLearningProjects = fetchLearningProjects
        self.deleteLearningProject = deleteLearningProject
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable {

        // MARK: Lifecycle

        public init(
            projects: IdentifiedArrayOf<LearningProjectSummary> = [],
            loadState: LoadState = .idle,
            isMenuPresented: Bool = false,
            isDeleteMode: Bool = false,
            pendingDeletion: LearningProjectID? = nil,
        ) {
            self.projects = projects
            self.loadState = loadState
            self.isMenuPresented = isMenuPresented
            self.isDeleteMode = isDeleteMode
            self.pendingDeletion = pendingDeletion
        }

        // MARK: Public

        public var projects: IdentifiedArrayOf<LearningProjectSummary>
        public var loadState: LoadState
        public var isMenuPresented: Bool
        public var isDeleteMode: Bool
        public var pendingDeletion: LearningProjectID?

        public var isEmpty: Bool {
            loadState == .loaded && projects.isEmpty
        }

    }

    public enum LoadState: Sendable, Equatable {
        case idle
        case loading
        case loaded
        case failed
    }

    public enum Action: Sendable, Equatable {
        case onAppear
        case projectsResponse(Result<LearningProjectPage, LearningProjectError>)
        case retryButtonTapped
        case menuButtonTapped
        case menuDismissed
        case deleteModeEntered
        case deleteModeExited
        case deleteButtonTapped(LearningProjectID)
        case deletionConfirmed
        case deletionCancelled
        case deletionResponse(Result<LearningProjectID, LearningProjectError>)
        case learningStartButtonTapped(LearningProjectID)
        case delegate(Delegate)
    }

    public enum Delegate: Sendable, Equatable {
        case learningStarted(LearningProjectID)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.loadState == .idle else { return .none }
                state.loadState = .loading
                return fetchEffect()

            case .retryButtonTapped:
                guard state.loadState == .failed else { return .none }
                state.loadState = .loading
                return fetchEffect()

            case .projectsResponse(.success(let page)):
                guard state.loadState == .loading else { return .none }
                state.projects = .init(uniqueElements: page.projects)
                state.loadState = .loaded
                return .none

            case .projectsResponse(.failure):
                guard state.loadState == .loading else { return .none }
                state.loadState = .failed
                return .none

            case .menuButtonTapped:
                guard state.loadState == .loaded else { return .none }
                state.isMenuPresented = true
                return .none

            case .menuDismissed:
                state.isMenuPresented = false
                return .none

            case .deleteModeEntered:
                guard state.loadState == .loaded else { return .none }
                state.isMenuPresented = false
                state.isDeleteMode = true
                return .none

            case .deleteModeExited:
                state.isDeleteMode = false
                state.pendingDeletion = nil
                return .cancel(id: CancelID.delete)

            case .deleteButtonTapped(let id):
                guard state.isDeleteMode, state.projects[id: id] != nil else {
                    return .none
                }
                state.pendingDeletion = id
                return .none

            case .deletionConfirmed:
                guard let id = state.pendingDeletion else { return .none }
                return deleteEffect(id: id)

            case .deletionCancelled:
                state.pendingDeletion = nil
                return .none

            case .deletionResponse(.success(let id)):
                state.projects.remove(id: id)
                state.pendingDeletion = nil
                if state.projects.isEmpty {
                    state.isDeleteMode = false
                }
                return .none

            case .deletionResponse(.failure):
                state.pendingDeletion = nil
                return .none

            case .learningStartButtonTapped(let id):
                guard state.projects[id: id] != nil else { return .none }
                return .send(.delegate(.learningStarted(id)))

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable, Sendable {
        case fetch
        case delete
    }

    private enum Constant {
        static let initialPage = 0
        static let pageSize = 20
    }

    private let fetchLearningProjects: any FetchLearningProjects
    private let deleteLearningProject: any DeleteLearningProject

    private func fetchEffect() -> Effect<Action> {
        .run { [fetchLearningProjects] send in
            do {
                let page = try await fetchLearningProjects(
                    page: Constant.initialPage,
                    size: Constant.pageSize,
                )
                await send(.projectsResponse(.success(page)))
            } catch is CancellationError {
                return
            } catch let error as LearningProjectError {
                await send(.projectsResponse(.failure(error)))
            } catch {
                await send(.projectsResponse(.failure(.temporarilyUnavailable)))
            }
        }
        .cancellable(id: CancelID.fetch, cancelInFlight: true)
    }

    private func deleteEffect(id: LearningProjectID) -> Effect<Action> {
        .run { [deleteLearningProject] send in
            do {
                try await deleteLearningProject(id)
                await send(.deletionResponse(.success(id)))
            } catch is CancellationError {
                return
            } catch let error as LearningProjectError {
                await send(.deletionResponse(.failure(error)))
            } catch {
                await send(.deletionResponse(.failure(.temporarilyUnavailable)))
            }
        }
        .cancellable(id: CancelID.delete, cancelInFlight: true)
    }

}
