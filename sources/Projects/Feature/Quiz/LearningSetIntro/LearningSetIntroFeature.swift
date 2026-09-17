import ComposableArchitecture
import DomainIdentifier
import DomainQuizDetail
import Foundation

// MARK: - LearningSetIntroFeature

@Reducer
public struct LearningSetIntroFeature: Sendable {

    // MARK: Lifecycle

    public init(
        fetchQuizSet: @escaping @Sendable (QuizSetID, ProjectID) async throws -> QuizSet,
        fetchBookmarks: @escaping @Sendable (QuizBookmarkFilter) async throws -> QuizBookmarkList,
    ) {
        self.fetchQuizSet = fetchQuizSet
        self.fetchBookmarks = fetchBookmarks
    }

    // MARK: Public

    public enum SetLoad: Equatable, Sendable {
        case idle
        case loading(requestID: Int)
        case loaded(QuizSet)
        case failed(QuizDetailError)
    }

    public enum BookmarkLoad: Equatable, Sendable {
        case idle
        case loading
        case loaded(Set<QuizID>)
        case failed(QuizDetailError)
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(
            projectID: ProjectID,
            setID: QuizSetID,
            label: String,
            autoStartsOnLoad: Bool = false,
        ) {
            self.projectID = projectID
            self.setID = setID
            self.label = label
            self.autoStartsOnLoad = autoStartsOnLoad
        }

        // MARK: Public

        public let projectID: ProjectID
        public let setID: QuizSetID
        public let label: String
        public var autoStartsOnLoad: Bool

        public var setLoad = SetLoad.idle
        public var bookmarkLoad = BookmarkLoad.idle
        public var isEmptySetReported = false
        public var loadRequestID = 0

        public var learningSet: QuizSet? {
            guard case .loaded(let set) = setLoad else { return nil }
            return set
        }

        public var bookmarkedQuestionIDs: Set<QuizID> {
            guard case .loaded(let identifiers) = bookmarkLoad else { return [] }
            return identifiers
        }

        public var isStartEnabled: Bool {
            learningSet != nil && !isEmptySetReported
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
            case startTapped
            case backTapped
        }

        @CasePathable
        public enum Input: Sendable, Equatable {
            case emptySetReported
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case setLoadFinished(requestID: Int, result: Result<QuizSet, QuizDetailError>)
            case bookmarksLoadFinished(Result<QuizBookmarkList, QuizDetailError>)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case startRequested(
                set: QuizSet,
                resumption: LearningSetResumption,
                bookmarkedQuestionIDs: Set<QuizID>,
            )
            case backRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.task):
                return .merge(loadSet(&state), loadBookmarks(&state))

            case .view(.retryTapped):
                return loadSet(&state)

            case .view(.startTapped):
                guard
                    let set = state.learningSet,
                    !state.isEmptySetReported,
                    !state.autoStartsOnLoad
                else { return .none }
                state.autoStartsOnLoad = true
                return startEffect(set: set, state: state)

            case .view(.backTapped):
                return .send(.delegate(.backRequested))

            case .input(.emptySetReported):
                state.isEmptySetReported = true
                return .none

            case .effect(.setLoadFinished(let requestID, let result)):
                guard requestID == state.loadRequestID else { return .none }
                switch result {
                case .success(let set):
                    state.setLoad = .loaded(set)
                    guard state.autoStartsOnLoad else { return .none }
                    state.autoStartsOnLoad = false
                    return startEffect(set: set, state: state)

                case .failure(let error):
                    state.setLoad = .failed(error)
                    return .none
                }

            case .effect(.bookmarksLoadFinished(let result)):
                switch result {
                case .success(let list):
                    state.bookmarkLoad = .loaded(Set(list.bookmarks.map(\.quizID)))

                case .failure(let error):
                    state.bookmarkLoad = .failed(error)
                }
                return .none

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case setLoad
        case bookmarkLoad
    }

    private let fetchQuizSet: @Sendable (QuizSetID, ProjectID) async throws -> QuizSet
    private let fetchBookmarks: @Sendable (QuizBookmarkFilter) async throws -> QuizBookmarkList

    private func startEffect(
        set: QuizSet,
        state: State,
    ) -> Effect<Action> {
        .send(.delegate(.startRequested(
            set: set,
            resumption: LearningSetResumption(set: set),
            bookmarkedQuestionIDs: state.bookmarkedQuestionIDs,
        )))
    }

    private func loadSet(_ state: inout State) -> Effect<Action> {
        state.loadRequestID += 1
        let requestID = state.loadRequestID
        state.setLoad = .loading(requestID: requestID)
        state.isEmptySetReported = false
        let projectID = state.projectID
        let setID = state.setID
        return .run { send in
            do {
                let set = try await fetchQuizSet(setID, projectID)
                await send(.effect(.setLoadFinished(requestID: requestID, result: .success(set))))
            } catch {
                let mapped = error as? QuizDetailError ?? .unexpected
                await send(.effect(.setLoadFinished(requestID: requestID, result: .failure(mapped))))
            }
        }
        .cancellable(id: CancelID.setLoad, cancelInFlight: true)
    }

    private func loadBookmarks(_ state: inout State) -> Effect<Action> {
        state.bookmarkLoad = .loading
        let filter = QuizBookmarkFilter.project(state.projectID)
        return .run { send in
            do {
                let list = try await fetchBookmarks(filter)
                await send(.effect(.bookmarksLoadFinished(.success(list))))
            } catch {
                let mapped = error as? QuizDetailError ?? .unexpected
                await send(.effect(.bookmarksLoadFinished(.failure(mapped))))
            }
        }
        .cancellable(id: CancelID.bookmarkLoad, cancelInFlight: true)
    }

}
