import ComposableArchitecture
import DomainUseCaseInterface

@Reducer
public struct LearningSessionFeature: Sendable {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init() { }

        // MARK: Public

        public fileprivate(set) var learningSet: QuizSet?
        public fileprivate(set) var currentQuestionIndex = 0
        public fileprivate(set) var resumption: LearningSetResumption?
        public fileprivate(set) var sessionCorrectChoiceCount = 0
        public fileprivate(set) var bookmarkedQuestionIDs = Set<QuizID>()
        public fileprivate(set) var isInProgress = false

    }

    public enum Action: Equatable, Sendable {
        case input(Input)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum Input: Equatable, Sendable {
            case started(set: QuizSet, resumption: LearningSetResumption, bookmarkedQuestionIDs: Set<QuizID>)
            case answerRecorded(choiceCorrect: Bool?)
            case advanced
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            case questionReady(question: Quiz, number: Int, isBookmarked: Bool, isLast: Bool)
            case emptySetDetected
            case completed(correctChoiceCount: Int, choiceQuestionCount: Int)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .input(let action):
                reduce(
                    into: &state,
                    input: action,
                )

            case .delegate:
                .none
            }
        }
    }

    // MARK: Private

    private func reduce(
        into state: inout State,
        input action: Action.Input,
    ) -> Effect<Action> {
        switch action {
        case .started(let set, let resumption, let bookmarkedQuestionIDs):
            state.learningSet = set
            state.resumption = resumption
            state.bookmarkedQuestionIDs = bookmarkedQuestionIDs
            guard !state.isInProgress else { return .none }
            guard set.quizzes.indices.contains(resumption.startIndex) else {
                return .send(.delegate(.emptySetDetected))
            }
            state.currentQuestionIndex = resumption.startIndex
            state.sessionCorrectChoiceCount = 0
            state.isInProgress = true
            return questionReady(state: state)

        case .answerRecorded(let choiceCorrect):
            if choiceCorrect == true {
                state.sessionCorrectChoiceCount += 1
            }
            return .none

        case .advanced:
            let nextIndex = state.currentQuestionIndex + 1
            guard let set = state.learningSet, set.quizzes.indices.contains(nextIndex) else {
                let resumption = state.resumption
                return .send(.delegate(.completed(
                    correctChoiceCount: (resumption?.skippedCorrectChoiceCount ?? 0) + state.sessionCorrectChoiceCount,
                    choiceQuestionCount: resumption?.choiceQuestionCount ?? 0,
                )))
            }
            state.currentQuestionIndex = nextIndex
            return questionReady(state: state)
        }
    }

    private func questionReady(state: State) -> Effect<Action> {
        guard
            let set = state.learningSet,
            set.quizzes.indices.contains(state.currentQuestionIndex)
        else { return .none }
        let quiz = set.quizzes[state.currentQuestionIndex]
        return .send(.delegate(.questionReady(
            question: quiz,
            number: state.currentQuestionIndex + 1,
            isBookmarked: state.bookmarkedQuestionIDs.contains(quiz.id),
            isLast: state.currentQuestionIndex == set.quizzes.count - 1,
        )))
    }

}
