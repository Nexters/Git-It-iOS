import ComposableArchitecture
import DomainLearningProject
import Foundation

// MARK: - SavedFeature

@Reducer
public struct SavedFeature: Sendable {

    // MARK: Lifecycle

    public init(fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase) {
        self.fetchBookmarkedQuestions = fetchBookmarkedQuestions
    }

    // MARK: Public

    public enum LoadStatus: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failed(LearningProjectError)
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(
            projectFilter: String? = nil,
            isBackControlPresented: Bool = false,
        ) {
            self.projectFilter = projectFilter
            self.isBackControlPresented = isBackControlPresented
            selectedProjectID = projectFilter
        }

        // MARK: Public

        /// 값이 있으면 그 프로젝트의 문제만 조회합니다.
        public let projectFilter: String?
        /// 뒤로가기 컨트롤의 표시 여부만 결정하는 표시 값입니다.
        public let isBackControlPresented: Bool

        public var selectedProjectID: String?
        public var collection: BookmarkedQuestionCollection?
        public var loadStatus = LoadStatus.idle
        public var requestID = 0

        public var isEmpty: Bool {
            collection?.bookmarks.isEmpty ?? false
        }

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case task
            case retryTapped
            case filterSelected(projectID: String?)
            case solveTapped(BookmarkedQuestion)
            case backTapped
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case bookmarksLoadFinished(
                requestID: Int,
                result: Result<BookmarkedQuestionCollection, LearningProjectError>,
            )
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case questionSelected(BookmarkedQuestion)
            case backRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.task),
                 .view(.retryTapped):
                return load(&state)

            case .view(.filterSelected(let projectID)):
                guard state.projectFilter == nil else { return .none }
                state.selectedProjectID = projectID
                return load(&state)

            case .view(.solveTapped(let question)):
                return .send(.delegate(.questionSelected(question)))

            case .view(.backTapped):
                guard state.isBackControlPresented else { return .none }
                return .send(.delegate(.backRequested))

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
        let projectID = state.projectFilter ?? state.selectedProjectID
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
