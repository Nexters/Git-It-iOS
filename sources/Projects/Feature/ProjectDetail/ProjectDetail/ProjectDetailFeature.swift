import ComposableArchitecture
import DomainLearningProject
import Foundation

// MARK: - ProjectDetailFeature

@Reducer
public struct ProjectDetailFeature: Sendable {

    // MARK: Lifecycle

    public init(
        fetchLearningProjectDetail: any FetchLearningProjectDetailUseCase,
        deleteLearningProject: any DeleteLearningProjectUseCase,
    ) {
        self.fetchLearningProjectDetail = fetchLearningProjectDetail
        self.deleteLearningProject = deleteLearningProject
    }

    // MARK: Public

    public enum LoadStatus: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failed(LearningProjectError)
    }

    public enum Deletion: Equatable, Sendable {
        case idle
        case confirming
        case committing
        case failed(LearningProjectError)
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(projectID: String) {
            self.projectID = projectID
        }

        // MARK: Public

        public let projectID: String
        public var detail: LearningProjectDetail?
        public var loadStatus = LoadStatus.idle
        public var requestID = 0
        public var isMenuPresented = false
        public var deletion = Deletion.idle

        public var isEmpty: Bool {
            detail?.sets.isEmpty ?? false
        }

        /// 아직 모두 풀지 않은 첫 세트입니다. 없으면 시작 컨트롤을 비활성으로 둡니다.
        public var firstIncompleteSet: LearningProjectSetProgress? {
            detail?.sets.first { $0.completedCount < $0.problemCount }
        }

        public var isResumeEnabled: Bool {
            firstIncompleteSet != nil
        }

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case input(Input)
        case effect(EffectEvent)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case task
            case retryTapped
            case setStartTapped(setID: String)
            case resumeTapped
            case menuTapped
            case menuDismissed
            case savedQuestionsTapped
            case repositoryLinkTapped
            case deleteTapped
            case deletionCancelled
            case deletionConfirmed
            case backTapped
        }

        @CasePathable
        public enum Input: Sendable, Equatable {
            case refreshRequested
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case detailLoadFinished(requestID: Int, result: Result<LearningProjectDetail, LearningProjectError>)
            case deletionFinished(projectID: String, error: LearningProjectError?)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case setStartRequested(projectID: String, setID: String, label: String)
            case savedQuestionsRequested(projectID: String)
            case externalURLRequested(URL)
            case projectDeleted(projectID: String)
            case dismissRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.task),
                 .view(.retryTapped),
                 .input(.refreshRequested):
                return load(&state)

            case .view(.setStartTapped(let setID)):
                guard let progress = state.detail?.sets.first(where: { $0.setID == setID }) else { return .none }
                return .send(.delegate(.setStartRequested(
                    projectID: state.projectID,
                    setID: progress.setID,
                    label: progress.label,
                )))

            case .view(.resumeTapped):
                guard let progress = state.firstIncompleteSet else { return .none }
                return .send(.delegate(.setStartRequested(
                    projectID: state.projectID,
                    setID: progress.setID,
                    label: progress.label,
                )))

            case .view(.menuTapped):
                state.isMenuPresented = true
                return .none

            case .view(.menuDismissed):
                state.isMenuPresented = false
                return .none

            case .view(.savedQuestionsTapped):
                state.isMenuPresented = false
                return .send(.delegate(.savedQuestionsRequested(projectID: state.projectID)))

            case .view(.repositoryLinkTapped):
                guard
                    let repositoryURL = state.detail?.repositoryURL,
                    let url = URL(string: repositoryURL)
                else { return .none }
                state.isMenuPresented = false
                return .send(.delegate(.externalURLRequested(url)))

            case .view(.deleteTapped):
                guard state.deletion != .committing else { return .none }
                state.isMenuPresented = false
                state.deletion = .confirming
                return .none

            case .view(.deletionCancelled):
                guard state.deletion != .committing else { return .none }
                state.deletion = .idle
                return .none

            case .view(.deletionConfirmed):
                guard state.deletion == .confirming else { return .none }
                state.deletion = .committing
                let projectID = state.projectID
                return .run { send in
                    do {
                        try await deleteLearningProject(projectID: projectID)
                        await send(.effect(.deletionFinished(projectID: projectID, error: nil)))
                    } catch {
                        let mapped = error as? LearningProjectError ?? .unexpected
                        await send(.effect(.deletionFinished(projectID: projectID, error: mapped)))
                    }
                }
                .cancellable(id: CancelID.delete, cancelInFlight: false)

            case .view(.backTapped):
                return .send(.delegate(.dismissRequested))

            case .effect(.detailLoadFinished(let requestID, let result)):
                guard requestID == state.requestID else { return .none }
                switch result {
                case .success(let detail):
                    state.detail = detail
                    state.loadStatus = .loaded

                case .failure(let error):
                    state.loadStatus = .failed(error)
                }
                return .none

            case .effect(.deletionFinished(let projectID, let error)):
                guard let error else {
                    state.deletion = .idle
                    return .send(.delegate(.projectDeleted(projectID: projectID)))
                }
                state.deletion = .failed(error)
                return .none

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case load
        case delete
    }

    private let fetchLearningProjectDetail: any FetchLearningProjectDetailUseCase
    private let deleteLearningProject: any DeleteLearningProjectUseCase

    private func load(_ state: inout State) -> Effect<Action> {
        state.requestID += 1
        let currentRequestID = state.requestID
        state.loadStatus = .loading
        let projectID = state.projectID
        return .run { send in
            do {
                let detail = try await fetchLearningProjectDetail(projectID: projectID)
                await send(.effect(.detailLoadFinished(requestID: currentRequestID, result: .success(detail))))
            } catch {
                let mapped = error as? LearningProjectError ?? .unexpected
                await send(.effect(.detailLoadFinished(requestID: currentRequestID, result: .failure(mapped))))
            }
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
    }

}
