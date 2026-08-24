import ComposableArchitecture
import DomainLearningProject
import Foundation

// MARK: - ProjectListFeature

/// U04 — 학습 프로젝트 목록(UC03) full snapshot 조회와 삭제(UC05)를 소유한다. pagination
/// 상태 없이 서버가 돌려주는 전체 목록을 그대로 보존한다.
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

        public var projects: [LearningProjectSummary] = []
        public var initialLoad: InitialLoad = .idle
        public var deletion: Deletion = .idle
        public var refreshRequestID = 0
    }

    public enum InitialLoad: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failed(LearningProjectError)
    }

    public enum Deletion: Equatable, Sendable {
        case idle
        case confirming(projectID: String)
        case committing(projectID: String)
        case failed(projectID: String, error: LearningProjectError)
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case delegate(Delegate)

        @CasePathable
        public enum View: Sendable, Equatable {
            case task
            case refreshRequested
            case projectRowTapped(projectID: String)
            case deleteButtonTapped(projectID: String)
            case deletionCancelled
            case deletionConfirmed
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case projectsLoadFinished(requestID: Int, result: Result<LearningProjectPage, LearningProjectError>)
            case deletionFinished(projectID: String, error: LearningProjectError?)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case projectSelected(projectID: String)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.task), .view(.refreshRequested):
                state.refreshRequestID += 1
                let currentRequestID = state.refreshRequestID
                state.initialLoad = state.projects.isEmpty ? .loading : state.initialLoad
                return .run { send in
                    do {
                        let page = try await fetchLearningProjects()
                        await send(.effect(.projectsLoadFinished(requestID: currentRequestID, result: .success(page))))
                    } catch {
                        let mapped = error as? LearningProjectError ?? .unexpected
                        await send(.effect(.projectsLoadFinished(requestID: currentRequestID, result: .failure(mapped))))
                    }
                }
                .cancellable(id: CancelID.load, cancelInFlight: true)

            case .view(.projectRowTapped(let projectID)):
                return .send(.delegate(.projectSelected(projectID: projectID)))

            case .view(.deleteButtonTapped(let projectID)):
                guard case .idle = state.deletion else { return .none }
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

            case .effect(.projectsLoadFinished(let requestID, let result)):
                guard requestID == state.refreshRequestID else { return .none }
                switch result {
                case .success(let page):
                    state.projects = page.items
                    state.initialLoad = .loaded

                case .failure(let error):
                    state.initialLoad = .failed(error)
                }
                return .none

            case .effect(.deletionFinished(let projectID, nil)):
                state.projects.removeAll { $0.projectID == projectID }
                state.deletion = .idle
                return .none

            case .effect(.deletionFinished(let projectID, .some(.notFound))):
                // 이미 서버에서 삭제된 항목이므로 로컬 목록과 재조정한다.
                state.projects.removeAll { $0.projectID == projectID }
                state.deletion = .idle
                return .none

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
        case deletion
    }

    private let fetchLearningProjects: any FetchLearningProjectsUseCase
    private let deleteLearningProject: any DeleteLearningProjectUseCase

}
