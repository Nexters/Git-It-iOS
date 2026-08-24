import ComposableArchitecture
import DomainLearningProject
import Foundation

// MARK: - ProjectDetailFeature

/// U07 — 프로젝트 상세(UC04)를 조회하고, 첫 미완료 세트를 기본 선택한다. 모든 세트를
/// 완료했으면 replay를 위해 첫 번째 세트로 fallback하고, 세트가 비어 있으면 empty copy를
/// 표시한다(GAP-014-006).
@Reducer
public struct ProjectDetailFeature: Sendable {

    // MARK: Lifecycle

    public init(fetchLearningProjectDetail: any FetchLearningProjectDetailUseCase) {
        self.fetchLearningProjectDetail = fetchLearningProjectDetail
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {
        public init(projectID: String) {
            self.projectID = projectID
        }

        public let projectID: String
        public var detail: LearningProjectDetail?
        public var loadStatus: LoadStatus = .idle
        public var requestID = 0

        public var isEmpty: Bool {
            detail?.sets.isEmpty ?? false
        }
    }

    public enum LoadStatus: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failed(LearningProjectError)
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case delegate(Delegate)

        @CasePathable
        public enum View: Sendable, Equatable {
            case task
            case retryTapped
            case setRowTapped(setID: String)
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case detailLoadFinished(requestID: Int, result: Result<LearningProjectDetail, LearningProjectError>)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case setSelected(projectID: String, setID: String)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.task), .view(.retryTapped):
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

            case .view(.setRowTapped(let setID)):
                return .send(.delegate(.setSelected(projectID: state.projectID, setID: setID)))

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

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case load
    }

    private let fetchLearningProjectDetail: any FetchLearningProjectDetailUseCase

}
