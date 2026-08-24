import ComposableArchitecture
import DomainLearningProject
import Foundation

// MARK: - QuizFeature

/// U08 — 학습 세트(UC06) 조회, 객관식(UC07)·서술형(UC08) 제출, 북마크(UC09) 토글과 저장한
/// 문제 목록(UC10) 조회를 소유한다. 정답·해설·rubric은 제출 전 노출하지 않고
/// (`answerResults`에만 저장), 같은 문제의 답안 제출과 북마크 mutation은 각각 직렬화한다.
@Reducer
public struct QuizFeature: Sendable {

    // MARK: Lifecycle

    public init(
        projectID: String,
        setID: String,
        fetchLearningSet: any FetchLearningSetUseCase,
        submitChoiceAnswer: any SubmitChoiceAnswerUseCase,
        submitEssayAnswer: any SubmitEssayAnswerUseCase,
        setQuestionBookmark: any SetQuestionBookmarkUseCase,
        fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase,
    ) {
        self.fetchLearningSet = fetchLearningSet
        self.submitChoiceAnswer = submitChoiceAnswer
        self.submitEssayAnswer = submitEssayAnswer
        self.setQuestionBookmark = setQuestionBookmark
        self.fetchBookmarkedQuestions = fetchBookmarkedQuestions
        self.projectID = projectID
        self.setID = setID
    }

    // MARK: Public

    public enum AnswerOutcome: Equatable, Sendable {
        case choice(ChoiceAnswerResult)
        case essay(EssayAnswerResult)
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        public init(projectID: String, setID: String) {
            self.projectID = projectID
            self.setID = setID
        }

        public let projectID: String
        public let setID: String

        public var learningSet: LearningSet?
        public var setLoadStatus: LoadStatus = .idle
        public var bookmarkedQuestionIDs: Set<String> = []
        public var bookmarkLoadStatus: LoadStatus = .idle

        public var currentQuestionIndex = 0
        public var draftChoiceIndex: Int?
        public var draftEssayText = ""
        public var answerResults: [String: AnswerOutcome] = [:]
        public var answerMutation: MutationStatus = .idle
        public var bookmarkMutation: MutationStatus = .idle

        public var currentQuestion: Question? {
            guard let questions = learningSet?.questions, learningSet != nil else { return nil }
            guard questions.indices.contains(currentQuestionIndex) else { return nil }
            return questions[currentQuestionIndex]
        }

        public func isAnswered(_ questionID: String) -> Bool {
            answerResults[questionID] != nil
        }
    }

    public enum LoadStatus: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failed(LearningProjectError)
    }

    public enum MutationStatus: Equatable, Sendable {
        case idle
        case committing
        case failed(LearningProjectError)
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case delegate(Delegate)

        @CasePathable
        public enum View: Sendable, Equatable {
            case task
            case choiceSelected(Int)
            case essayTextChanged(String)
            case submitAnswerTapped
            case bookmarkToggleTapped
            case nextQuestionTapped
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case setLoadFinished(Result<LearningSet, LearningProjectError>)
            case bookmarksLoadFinished(Result<BookmarkedQuestionCollection, LearningProjectError>)
            case choiceAnswerFinished(questionID: String, result: Result<ChoiceAnswerResult, LearningProjectError>)
            case essayAnswerFinished(questionID: String, result: Result<EssayAnswerResult, LearningProjectError>)
            case bookmarkFinished(questionID: String, result: Result<BookmarkState, LearningProjectError>)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case progressInvalidated(projectID: String)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.task):
                let projectID = state.projectID
                let setID = state.setID
                state.setLoadStatus = .loading
                state.bookmarkLoadStatus = .loading
                return .merge(
                    .run { send in
                        do {
                            let set = try await fetchLearningSet(projectID: projectID, setID: setID)
                            await send(.effect(.setLoadFinished(.success(set))))
                        } catch {
                            let mapped = error as? LearningProjectError ?? .unexpected
                            await send(.effect(.setLoadFinished(.failure(mapped))))
                        }
                    }
                    .cancellable(id: CancelID.setLoad),
                    .run { send in
                        do {
                            let bookmarks = try await fetchBookmarkedQuestions(projectID: projectID)
                            await send(.effect(.bookmarksLoadFinished(.success(bookmarks))))
                        } catch {
                            let mapped = error as? LearningProjectError ?? .unexpected
                            await send(.effect(.bookmarksLoadFinished(.failure(mapped))))
                        }
                    }
                    .cancellable(id: CancelID.bookmarkLoad),
                )

            case .view(.choiceSelected(let index)):
                guard let question = state.currentQuestion, !state.isAnswered(question.questionID) else { return .none }
                state.draftChoiceIndex = index
                return .none

            case .view(.essayTextChanged(let text)):
                guard let question = state.currentQuestion, !state.isAnswered(question.questionID) else { return .none }
                state.draftEssayText = text
                return .none

            case .view(.submitAnswerTapped):
                guard
                    let question = state.currentQuestion,
                    !state.isAnswered(question.questionID),
                    state.answerMutation != .committing
                else { return .none }

                let projectID = state.projectID
                let questionID = question.questionID

                switch question.format {
                case .multipleChoice:
                    guard let selectedIndex = state.draftChoiceIndex else { return .none }
                    state.answerMutation = .committing
                    return .run { send in
                        do {
                            let result = try await submitChoiceAnswer(
                                projectID: projectID,
                                questionID: questionID,
                                selectedIndex: selectedIndex,
                            )
                            await send(.effect(.choiceAnswerFinished(questionID: questionID, result: .success(result))))
                        } catch {
                            let mapped = error as? LearningProjectError ?? .unexpected
                            await send(.effect(.choiceAnswerFinished(questionID: questionID, result: .failure(mapped))))
                        }
                    }
                    .cancellable(id: CancelID.answerMutation)

                case .essay:
                    let text = state.draftEssayText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return .none }
                    state.answerMutation = .committing
                    return .run { send in
                        do {
                            let result = try await submitEssayAnswer(
                                projectID: projectID,
                                questionID: questionID,
                                text: text,
                            )
                            await send(.effect(.essayAnswerFinished(questionID: questionID, result: .success(result))))
                        } catch {
                            let mapped = error as? LearningProjectError ?? .unexpected
                            await send(.effect(.essayAnswerFinished(questionID: questionID, result: .failure(mapped))))
                        }
                    }
                    .cancellable(id: CancelID.answerMutation)
                }

            case .view(.bookmarkToggleTapped):
                guard let question = state.currentQuestion, state.bookmarkMutation != .committing else { return .none }
                let projectID = state.projectID
                let questionID = question.questionID
                let desired = !state.bookmarkedQuestionIDs.contains(questionID)
                state.bookmarkMutation = .committing
                return .run { send in
                    do {
                        let result = try await setQuestionBookmark(
                            projectID: projectID,
                            questionID: questionID,
                            bookmarked: desired,
                        )
                        await send(.effect(.bookmarkFinished(questionID: questionID, result: .success(result))))
                    } catch {
                        let mapped = error as? LearningProjectError ?? .unexpected
                        await send(.effect(.bookmarkFinished(questionID: questionID, result: .failure(mapped))))
                    }
                }
                .cancellable(id: CancelID.bookmarkMutation)

            case .view(.nextQuestionTapped):
                guard
                    let question = state.currentQuestion,
                    state.isAnswered(question.questionID),
                    let questions = state.learningSet?.questions,
                    state.currentQuestionIndex < questions.count - 1
                else { return .none }
                state.currentQuestionIndex += 1
                state.draftChoiceIndex = nil
                state.draftEssayText = ""
                return .none

            case .effect(.setLoadFinished(let result)):
                switch result {
                case .success(let set):
                    state.learningSet = set
                    state.setLoadStatus = .loaded
                    state.currentQuestionIndex = resumeIndex(for: set.questions)

                case .failure(let error):
                    state.setLoadStatus = .failed(error)
                }
                return .none

            case .effect(.bookmarksLoadFinished(let result)):
                switch result {
                case .success(let collection):
                    state.bookmarkedQuestionIDs = Set(collection.bookmarks.map(\.questionID))
                    state.bookmarkLoadStatus = .loaded

                case .failure(let error):
                    state.bookmarkLoadStatus = .failed(error)
                }
                return .none

            case .effect(.choiceAnswerFinished(let questionID, .success(let result))):
                state.answerMutation = .idle
                state.answerResults[questionID] = .choice(result)
                return .send(.delegate(.progressInvalidated(projectID: state.projectID)))

            case .effect(.choiceAnswerFinished(_, .failure(let error))):
                state.answerMutation = .failed(error)
                return .none

            case .effect(.essayAnswerFinished(let questionID, .success(let result))):
                state.answerMutation = .idle
                state.answerResults[questionID] = .essay(result)
                return .send(.delegate(.progressInvalidated(projectID: state.projectID)))

            case .effect(.essayAnswerFinished(_, .failure(let error))):
                state.answerMutation = .failed(error)
                return .none

            case .effect(.bookmarkFinished(let questionID, .success(let bookmarkState))):
                state.bookmarkMutation = .idle
                if bookmarkState.bookmarked {
                    state.bookmarkedQuestionIDs.insert(questionID)
                } else {
                    state.bookmarkedQuestionIDs.remove(questionID)
                }
                return .none

            case .effect(.bookmarkFinished(_, .failure(let error))):
                state.bookmarkMutation = .failed(error)
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
        case answerMutation
        case bookmarkMutation
    }

    private let projectID: String
    private let setID: String
    private let fetchLearningSet: any FetchLearningSetUseCase
    private let submitChoiceAnswer: any SubmitChoiceAnswerUseCase
    private let submitEssayAnswer: any SubmitEssayAnswerUseCase
    private let setQuestionBookmark: any SetQuestionBookmarkUseCase
    private let fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase

    /// resume 3단계: 미시작(0), 일부 응답 후 재진입(첫 미응답 index), 전부 응답 완료(마지막 index).
    private func resumeIndex(for questions: [Question]) -> Int {
        guard !questions.isEmpty else { return 0 }
        if let firstUnanswered = questions.firstIndex(where: { $0.myAnswer == nil }) {
            return firstUnanswered
        }
        return questions.count - 1
    }

}
