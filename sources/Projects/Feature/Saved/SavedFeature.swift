import ComposableArchitecture
import DomainLearningProject
import Foundation

// MARK: - SavedFeature

@Reducer
public struct SavedFeature: Sendable {

    // MARK: Lifecycle

    public init(
        fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase,
        setQuestionBookmark: any SetQuestionBookmarkUseCase,
    ) {
        self.fetchBookmarkedQuestions = fetchBookmarkedQuestions
        self.setQuestionBookmark = setQuestionBookmark
    }

    // MARK: Public

    public enum LoadStatus: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failed(LearningProjectError)
    }

    public enum BookmarkMutation: Equatable, Sendable {
        case idle
        case committing
        case failed(LearningProjectError)
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(
            initialProjectFilter: String? = nil,
            isBackControlPresented: Bool = false,
        ) {
            self.isBackControlPresented = isBackControlPresented
            selectedProjectID = initialProjectFilter
        }

        // MARK: Public

        public let isBackControlPresented: Bool

        public var selectedProjectID: String?
        public var collection: BookmarkedQuestionCollection?
        public var loadStatus = LoadStatus.idle
        public var requestID = 0
        public var bookmarkOverrides = [String: Bool]()
        public var bookmarkMutations = [String: BookmarkMutation]()

        public var isEmpty: Bool {
            collection?.bookmarks.isEmpty ?? false
        }

        public func isBookmarked(questionID: String) -> Bool {
            bookmarkOverrides[questionID] ?? true
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
            case bookmarkToggleTapped(BookmarkedQuestion)
            case backTapped
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case bookmarksLoadFinished(
                requestID: Int,
                result: Result<BookmarkedQuestionCollection, LearningProjectError>,
            )
            case bookmarkToggleFinished(
                questionID: String,
                result: Result<BookmarkState, LearningProjectError>,
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
                guard state.selectedProjectID != projectID else { return .none }
                state.selectedProjectID = projectID
                return load(&state)

            case .view(.solveTapped(let question)):
                return .send(.delegate(.questionSelected(question)))

            case .view(.bookmarkToggleTapped(let question)):
                return toggleBookmark(&state, question: question)

            case .view(.backTapped):
                guard state.isBackControlPresented else { return .none }
                return .send(.delegate(.backRequested))

            case .effect(.bookmarksLoadFinished(let requestID, let result)):
                guard requestID == state.requestID else { return .none }
                switch result {
                case .success(let collection):
                    state.collection = collection
                    state.loadStatus = .loaded
                    state.bookmarkOverrides = [:]

                case .failure(let error):
                    state.loadStatus = .failed(error)
                }
                return .none

            case .effect(.bookmarkToggleFinished(let questionID, let result)):
                switch result {
                case .success(let bookmarkState):
                    state.bookmarkOverrides[questionID] = bookmarkState.bookmarked
                    state.bookmarkMutations[questionID] = .idle

                case .failure(let error):
                    state.bookmarkMutations[questionID] = .failed(error)
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
        case bookmarkToggle(String)
    }

    private let fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase
    private let setQuestionBookmark: any SetQuestionBookmarkUseCase

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

    private func toggleBookmark(
        _ state: inout State,
        question: BookmarkedQuestion,
    ) -> Effect<Action> {
        let questionID = question.questionID
        guard state.bookmarkMutations[questionID] != .committing else { return .none }
        state.bookmarkMutations[questionID] = .committing
        let projectID = question.projectID
        let bookmarked = !state.isBookmarked(questionID: questionID)
        return .run { send in
            do {
                let result = try await setQuestionBookmark(
                    projectID: projectID,
                    questionID: questionID,
                    bookmarked: bookmarked,
                )
                await send(.effect(.bookmarkToggleFinished(questionID: questionID, result: .success(result))))
            } catch {
                let mapped = error as? LearningProjectError ?? .unexpected
                await send(.effect(.bookmarkToggleFinished(questionID: questionID, result: .failure(mapped))))
            }
        }
        .cancellable(id: CancelID.bookmarkToggle(questionID), cancelInFlight: true)
    }

}
