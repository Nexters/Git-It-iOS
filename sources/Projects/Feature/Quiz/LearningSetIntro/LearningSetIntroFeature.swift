import ComposableArchitecture
import DomainLearningProject
import Foundation

// MARK: - LearningSetIntroFeature

@Reducer
public struct LearningSetIntroFeature: Sendable {

    // MARK: Lifecycle

    public init(
        fetchLearningSet: any FetchLearningSetUseCase,
        fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase,
    ) {
        self.fetchLearningSet = fetchLearningSet
        self.fetchBookmarkedQuestions = fetchBookmarkedQuestions
    }

    // MARK: Public

    public enum SetLoad: Equatable, Sendable {
        case idle
        case loading(requestID: Int)
        case loaded(LearningSet)
        case failed(LearningProjectError)
    }

    public enum BookmarkLoad: Equatable, Sendable {
        case idle
        case loading
        case loaded(Set<String>)
        case failed(LearningProjectError)
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(
            projectID: String,
            setID: String,
            label: String,
            autoStartsOnLoad: Bool = false,
        ) {
            self.projectID = projectID
            self.setID = setID
            self.label = label
            self.autoStartsOnLoad = autoStartsOnLoad
        }

        // MARK: Public

        public let projectID: String
        public let setID: String
        public let label: String
        /// 홈 화면 카드의 이어풀기처럼 사용자가 이미 세트를 선택한 진입 경로에서
        /// 세트를 불러오는 즉시 시작 확인 탭 없이 바로 문제풀이로 진행합니다.
        /// 시작이 실행되는 즉시 꺼지며, 이 상태는 두 가지 역할을 겸합니다.
        /// - 문제풀이에서 뒤로가기로 돌아왔을 때 다시 자동 시작되지 않도록 막습니다.
        /// - 시작 버튼의 중복 탭(더블 탭)으로 시작 요청이 두 번 전송되지 않도록
        ///   쓰로틀합니다. `true`인 동안에는 자동/수동 시작 요청 모두 재실행을
        ///   막고, 시작 요청을 한 번 보낸 뒤 바로 꺼집니다.
        public var autoStartsOnLoad: Bool

        public var setLoad = SetLoad.idle
        public var bookmarkLoad = BookmarkLoad.idle
        public var isEmptySetReported = false
        public var loadRequestID = 0

        public var learningSet: LearningSet? {
            guard case .loaded(let set) = setLoad else { return nil }
            return set
        }

        public var bookmarkedQuestionIDs: Set<String> {
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
            case setLoadFinished(requestID: Int, result: Result<LearningSet, LearningProjectError>)
            case bookmarksLoadFinished(Result<BookmarkedQuestionCollection, LearningProjectError>)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case startRequested(
                set: LearningSet,
                resumption: LearningSetResumption,
                bookmarkedQuestionIDs: Set<String>,
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
                case .success(let collection):
                    state.bookmarkLoad = .loaded(Set(collection.bookmarks.map(\.questionID)))

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

    private let fetchLearningSet: any FetchLearningSetUseCase
    private let fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase

    private func startEffect(set: LearningSet, state: State) -> Effect<Action> {
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
                let set = try await fetchLearningSet(projectID: projectID, setID: setID)
                await send(.effect(.setLoadFinished(requestID: requestID, result: .success(set))))
            } catch {
                let mapped = error as? LearningProjectError ?? .unexpected
                await send(.effect(.setLoadFinished(requestID: requestID, result: .failure(mapped))))
            }
        }
        .cancellable(id: CancelID.setLoad, cancelInFlight: true)
    }

    private func loadBookmarks(_ state: inout State) -> Effect<Action> {
        state.bookmarkLoad = .loading
        let projectID = state.projectID
        return .run { send in
            do {
                let collection = try await fetchBookmarkedQuestions(projectID: projectID)
                await send(.effect(.bookmarksLoadFinished(.success(collection))))
            } catch {
                let mapped = error as? LearningProjectError ?? .unexpected
                await send(.effect(.bookmarksLoadFinished(.failure(mapped))))
            }
        }
        .cancellable(id: CancelID.bookmarkLoad, cancelInFlight: true)
    }

}
