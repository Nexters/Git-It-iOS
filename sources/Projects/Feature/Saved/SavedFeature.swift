import ComposableArchitecture
import DomainUseCaseInterface
import Foundation

// MARK: - SavedFeature

@Reducer
public struct SavedFeature: Sendable {

    // MARK: Lifecycle

    public init(
        fetchBookmarks: @escaping @Sendable (QuizBookmarkFilter) async throws -> QuizBookmarkList,
        setBookmark: @escaping @Sendable (QuizID, ProjectID, Bool) async throws -> QuizBookmarkState,
    ) {
        self.fetchBookmarks = fetchBookmarks
        self.setBookmark = setBookmark
    }

    // MARK: Public

    public enum LoadStatus: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failed(QuizDetailError)
    }

    public enum BookmarkMutation: Equatable, Sendable {
        case idle
        case committing
        case failed(QuizDetailError)
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(
            initialProjectFilter: ProjectID? = nil,
            isBackControlPresented: Bool = false,
        ) {
            self.isBackControlPresented = isBackControlPresented
            selectedProjectID = initialProjectFilter
        }

        // MARK: Public

        public let isBackControlPresented: Bool

        public var selectedProjectID: ProjectID?
        public var collection: QuizBookmarkList?
        public var loadStatus = LoadStatus.idle
        public var requestID = 0
        public var bookmarkOverrides = [QuizID: Bool]()
        public var bookmarkMutations = [QuizID: BookmarkMutation]()

        public var isEmpty: Bool {
            collection?.bookmarks.isEmpty ?? false
        }

        public func isBookmarked(questionID: QuizID) -> Bool {
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
            case filterSelected(projectID: ProjectID?)
            case solveTapped(QuizBookmark)
            case bookmarkToggleTapped(QuizBookmark)
            case backTapped
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case bookmarksLoadFinished(
                requestID: Int,
                result: Result<QuizBookmarkList, QuizDetailError>,
            )
            case bookmarkToggleFinished(
                questionID: QuizID,
                result: Result<QuizBookmarkState, QuizDetailError>,
            )
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case questionSelected(QuizBookmark)
            case backRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(let action):
                reduce(
                    into: &state,
                    view: action,
                )

            case .effect(let event):
                reduce(
                    into: &state,
                    effect: event,
                )

            case .delegate:
                .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case load
        case bookmarkToggle(QuizID)
    }

    private let fetchBookmarks: @Sendable (QuizBookmarkFilter) async throws -> QuizBookmarkList
    private let setBookmark: @Sendable (QuizID, ProjectID, Bool) async throws -> QuizBookmarkState

    private func reduce(
        into state: inout State,
        view action: Action.View,
    ) -> Effect<Action> {
        switch action {
        case .task,
             .retryTapped:
            return load(&state)

        case .filterSelected(let projectID):
            guard state.selectedProjectID != projectID else { return .none }
            state.selectedProjectID = projectID
            return load(&state)

        case .solveTapped(let bookmark):
            return .send(.delegate(.questionSelected(bookmark)))

        case .bookmarkToggleTapped(let bookmark):
            return toggleBookmark(
                &state,
                bookmark: bookmark,
            )

        case .backTapped:
            guard state.isBackControlPresented else { return .none }
            return .send(.delegate(.backRequested))
        }
    }

    private func reduce(
        into state: inout State,
        effect event: Action.EffectEvent,
    ) -> Effect<Action> {
        switch event {
        case .bookmarksLoadFinished(let requestID, let result):
            guard requestID == state.requestID else { return .none }
            switch result {
            case .success(let list):
                state.collection = list
                state.loadStatus = .loaded
                state.bookmarkOverrides = [:]

            case .failure(let error):
                state.loadStatus = .failed(error)
            }
            return .none

        case .bookmarkToggleFinished(let questionID, let result):
            switch result {
            case .success(let bookmarkState):
                state.bookmarkOverrides[questionID] = bookmarkState.isBookmarked
                state.bookmarkMutations[questionID] = .idle

            case .failure(let error):
                state.bookmarkMutations[questionID] = .failed(error)
            }
            return .none
        }
    }

    private func load(_ state: inout State) -> Effect<Action> {
        state.requestID += 1
        let currentRequestID = state.requestID
        let filter = state.selectedProjectID.map(QuizBookmarkFilter.project) ?? .all
        state.loadStatus = .loading
        return .run { send in
            do {
                let list = try await fetchBookmarks(filter)
                await send(.effect(.bookmarksLoadFinished(
                    requestID: currentRequestID,
                    result: .success(list),
                )))
            } catch {
                let mapped = error as? QuizDetailError ?? .unexpected
                await send(.effect(.bookmarksLoadFinished(
                    requestID: currentRequestID,
                    result: .failure(mapped),
                )))
            }
        }
        .cancellable(
            id: CancelID.load,
            cancelInFlight: true,
        )
    }

    private func toggleBookmark(
        _ state: inout State,
        bookmark: QuizBookmark,
    ) -> Effect<Action> {
        let questionID = bookmark.quizID
        guard state.bookmarkMutations[questionID] != .committing else { return .none }
        state.bookmarkMutations[questionID] = .committing
        let projectID = bookmark.projectID
        let bookmarked = !state.isBookmarked(questionID: questionID)
        return .run { send in
            do {
                let bookmarkState = try await setBookmark(questionID, projectID, bookmarked)
                await send(.effect(.bookmarkToggleFinished(
                    questionID: questionID,
                    result: .success(bookmarkState),
                )))
            } catch {
                let mapped = error as? QuizDetailError ?? .unexpected
                await send(.effect(.bookmarkToggleFinished(
                    questionID: questionID,
                    result: .failure(mapped),
                )))
            }
        }
        .cancellable(
            id: CancelID.bookmarkToggle(questionID),
            cancelInFlight: true,
        )
    }

}
