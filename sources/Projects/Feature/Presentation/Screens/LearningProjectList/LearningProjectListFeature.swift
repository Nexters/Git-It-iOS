import ComposableArchitecture
import DomainLearningProject

@Reducer
public struct LearningProjectListFeature: Sendable {

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
    public struct State: Equatable {

        // MARK: Lifecycle

        public init(
            projects: [LearningProjectSummary] = [],
            loadState: LoadState = .idle,
            isMenuPresented: Bool = false,
            isDeleteMode: Bool = false,
            pendingDeletion: String? = nil,
        ) {
            self.projects = projects
            self.loadState = loadState
            self.isMenuPresented = isMenuPresented
            self.isDeleteMode = isDeleteMode
            self.pendingDeletion = pendingDeletion
        }

        // MARK: Public

        public var projects: [LearningProjectSummary]
        public var loadState: LoadState
        public var isMenuPresented: Bool
        public var isDeleteMode: Bool
        public var pendingDeletion: String?

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
        case deleteButtonTapped(String)
        case deletionConfirmed
        case deletionCancelled
        case deletionResponse(Result<String, LearningProjectError>)
        case learningStartButtonTapped(String)
        case delegate(Delegate)
    }

    public enum Delegate: Sendable, Equatable {
        case learningStarted(String)
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
                state.projects = page.items
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

            case .deleteButtonTapped(let projectId):
                guard
                    state.isDeleteMode,
                    state.projects.contains(where: { $0.projectId == projectId })
                else {
                    return .none
                }
                state.pendingDeletion = projectId
                return .none

            case .deletionConfirmed:
                guard let projectId = state.pendingDeletion else { return .none }
                return deleteEffect(projectId: projectId)

            case .deletionCancelled:
                state.pendingDeletion = nil
                return .none

            case .deletionResponse(.success(let projectId)):
                state.projects.removeAll { $0.projectId == projectId }
                state.pendingDeletion = nil
                if state.projects.isEmpty {
                    state.isDeleteMode = false
                }
                return .none

            case .deletionResponse(.failure):
                state.pendingDeletion = nil
                return .none

            case .learningStartButtonTapped(let projectId):
                guard state.projects.contains(where: { $0.projectId == projectId }) else { return .none }
                return .send(.delegate(.learningStarted(projectId)))

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

    private let fetchLearningProjects: any FetchLearningProjectsUseCase
    private let deleteLearningProject: any DeleteLearningProjectUseCase

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
                await send(.projectsResponse(.failure(.unexpected)))
            }
        }
        .cancellable(id: CancelID.fetch, cancelInFlight: true)
    }

    private func deleteEffect(projectId: String) -> Effect<Action> {
        .run { [deleteLearningProject] send in
            do {
                try await deleteLearningProject(projectId: projectId)
                await send(.deletionResponse(.success(projectId)))
            } catch is CancellationError {
                return
            } catch let error as LearningProjectError {
                await send(.deletionResponse(.failure(error)))
            } catch {
                await send(.deletionResponse(.failure(.unexpected)))
            }
        }
        .cancellable(id: CancelID.delete, cancelInFlight: true)
    }

}
