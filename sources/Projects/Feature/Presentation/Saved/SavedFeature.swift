import ComposableArchitecture
import DomainLearningProject
import Foundation

// MARK: - SavedFeature

/// U05 — 저장한(bookmark) 문제 목록(UC10)을 프로젝트 필터와 함께 조회한다. `availableProjects`는
/// 필터 결과와 무관하게 서버가 내려준 값을 그대로 보존한다.
@Reducer
public struct SavedFeature: Sendable {

    // MARK: Lifecycle

    public init(fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase) {
        self.fetchBookmarkedQuestions = fetchBookmarkedQuestions
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {
        public init() { }

        public var selectedProjectID: String?
        public var collection: BookmarkedQuestionCollection?
        public var loadStatus: LoadStatus = .idle
        public var requestID = 0
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
            case filterSelected(projectID: String?)
            case bookmarkRowTapped(BookmarkedQuestion)
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case bookmarksLoadFinished(
                requestID: Int,
                result: Result<BookmarkedQuestionCollection, LearningProjectError>
            )
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case questionSelected(BookmarkedQuestion)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.task):
                return load(&state)

            case .view(.filterSelected(let projectID)):
                state.selectedProjectID = projectID
                return load(&state)

            case .view(.bookmarkRowTapped(let question)):
                return .send(.delegate(.questionSelected(question)))

            case .effect(.bookmarksLoadFinished(let requestID, let result)):
                guard requestID == state.requestID else { return .none }
                switch result {
                case .success(let collection):
                    state.collection = collection
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

    private let fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase

    private func load(_ state: inout State) -> Effect<Action> {
        state.requestID += 1
        let currentRequestID = state.requestID
        let projectID = state.selectedProjectID
        state.loadStatus = .loading
        return .run { send in
            do {
                let collection = try await fetchBookmarkedQuestions(projectID: projectID)
                await send(.effect(.bookmarksLoadFinished(requestID: currentRequestID, result: .success(collection))))
            } catch {
                let mapped = error as? LearningProjectError ?? .unexpected
                await send(.effect(.bookmarksLoadFinished(requestID: currentRequestID, result: .failure(mapped))))
            }
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
    }

}
