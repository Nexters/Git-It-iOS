import ComposableArchitecture
import DomainLearningProject
import Foundation

// MARK: - QuizRouterFeature

@Reducer
public struct QuizRouterFeature: Sendable {

    // MARK: Lifecycle

    public init(
        fetchLearningSet: any FetchLearningSetUseCase,
        fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase,
        submitChoiceAnswer: any SubmitChoiceAnswerUseCase,
        submitEssayAnswer: any SubmitEssayAnswerUseCase,
        setQuestionBookmark: any SetQuestionBookmarkUseCase,
    ) {
        self.fetchLearningSet = fetchLearningSet
        self.fetchBookmarkedQuestions = fetchBookmarkedQuestions
        self.submitChoiceAnswer = submitChoiceAnswer
        self.submitEssayAnswer = submitEssayAnswer
        self.setQuestionBookmark = setQuestionBookmark
    }

    // MARK: Public

    public enum ActiveScreen: Equatable, Sendable {
        case learningSetIntro
        case questionSolving
        case learningCompletion
    }

    public struct ScreenTransition: Equatable, Sendable {

        // MARK: Lifecycle

        public init(
            from: ActiveScreen,
            to: ActiveScreen,
            cause: Cause,
        ) {
            self.from = from
            self.to = to
            self.cause = cause
        }

        // MARK: Public

        public enum Cause: Equatable, Sendable {
            case startRequested
            case advancedToCompletion
            case backRequested
        }

        public let from: ActiveScreen
        public let to: ActiveScreen
        public let cause: Cause

    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(
            projectID: String,
            setID: String,
            setLabel: String,
            autoStartsLearning: Bool = false,
        ) {
            self.projectID = projectID
            self.setID = setID
            self.setLabel = setLabel
            learningSetIntro = LearningSetIntroFeature.State(
                projectID: projectID,
                setID: setID,
                label: setLabel,
                autoStartsOnLoad: autoStartsLearning,
            )
            learningCompletion = LearningCompletionFeature.State(projectID: projectID)
        }

        // MARK: Public

        public let projectID: String
        public let setID: String
        public let setLabel: String

        public var activeScreen = ActiveScreen.learningSetIntro
        public var screenTransitions = [ScreenTransition]()

        public var learningSetIntro: LearningSetIntroFeature.State
        public var questionSolving: QuestionSolvingFeature.State?
        public var learningCompletion: LearningCompletionFeature.State

        public internal(set) var learningSet: LearningSet?
        public internal(set) var currentQuestionIndex = 0
        public internal(set) var resumption: LearningSetResumption?
        public internal(set) var sessionCorrectChoiceCount = 0
        public internal(set) var bookmarkedQuestionIDs = Set<String>()

    }

    public enum Action: Sendable, Equatable {
        case learningSetIntro(LearningSetIntroFeature.Action)
        case questionSolving(QuestionSolvingFeature.Action)
        case learningCompletion(LearningCompletionFeature.Action)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case externalURLRequested(URL)
            case progressInvalidated(projectID: String)
            case dismissRequested(projectID: String)
        }
    }

    /// 진행 컨트롤 문구입니다. 문제 화면은 이 값만 읽고 흐름을 알지 않습니다.
    public static let nextQuestionActionTitle = "다음 문제"
    public static let completeActionTitle = "학습 완료"

    public var body: some ReducerOf<Self> {
        Scope(state: \.learningSetIntro, action: \.learningSetIntro) {
            LearningSetIntroFeature(
                fetchLearningSet: fetchLearningSet,
                fetchBookmarkedQuestions: fetchBookmarkedQuestions,
            )
        }
        Scope(state: \.learningCompletion, action: \.learningCompletion) {
            LearningCompletionFeature()
        }
        Reduce { state, action in
            switch action {
            case .learningSetIntro(.delegate(.startRequested(let set, let resumption, let bookmarkedQuestionIDs))):
                state.learningSet = set
                state.resumption = resumption
                state.bookmarkedQuestionIDs = bookmarkedQuestionIDs

                if state.questionSolving != nil {
                    return activate(.questionSolving, cause: .startRequested, state: &state)
                }

                guard set.questions.indices.contains(resumption.startIndex) else {
                    return .send(.learningSetIntro(.input(.emptySetReported)))
                }

                state.currentQuestionIndex = resumption.startIndex
                state.sessionCorrectChoiceCount = 0
                state.questionSolving = questionSolvingState(state: state)
                return activate(.questionSolving, cause: .startRequested, state: &state)

            case .learningSetIntro(.delegate(.backRequested)):
                return .send(.delegate(.dismissRequested(projectID: state.projectID)))

            case .questionSolving(.delegate(.backRequested)):
                return activate(.learningSetIntro, cause: .backRequested, state: &state)

            case .questionSolving(.delegate(.answerSubmitted(_, let choiceCorrect))):
                if choiceCorrect == true {
                    state.sessionCorrectChoiceCount += 1
                }
                return .send(.delegate(.progressInvalidated(projectID: state.projectID)))

            case .questionSolving(.delegate(.advanceRequested)):
                let nextIndex = state.currentQuestionIndex + 1
                guard let set = state.learningSet, set.questions.indices.contains(nextIndex) else {
                    let resumption = state.resumption
                    state.learningCompletion.choiceQuestionCount = resumption?.choiceQuestionCount ?? 0
                    state.learningCompletion.correctChoiceCount =
                        (resumption?.skippedCorrectChoiceCount ?? 0) + state.sessionCorrectChoiceCount
                    return activate(.learningCompletion, cause: .advancedToCompletion, state: &state)
                }

                state.currentQuestionIndex = nextIndex
                state.questionSolving = questionSolvingState(state: state)
                return .none

            case .questionSolving(.delegate(.externalURLRequested(let url))):
                return .send(.delegate(.externalURLRequested(url)))

            case .learningCompletion(.delegate(.dismissRequested)):
                return .send(.delegate(.dismissRequested(projectID: state.projectID)))

            case .learningSetIntro,
                 .questionSolving,
                 .learningCompletion,
                 .delegate:
                return .none
            }
        }
        .ifLet(\.questionSolving, action: \.questionSolving) {
            QuestionSolvingFeature(
                submitChoiceAnswer: submitChoiceAnswer,
                submitEssayAnswer: submitEssayAnswer,
                setQuestionBookmark: setQuestionBookmark,
            )
        }
    }

    // MARK: Private

    private let fetchLearningSet: any FetchLearningSetUseCase
    private let fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase
    private let submitChoiceAnswer: any SubmitChoiceAnswerUseCase
    private let submitEssayAnswer: any SubmitEssayAnswerUseCase
    private let setQuestionBookmark: any SetQuestionBookmarkUseCase

    private func questionSolvingState(state: State) -> QuestionSolvingFeature.State? {
        guard
            let set = state.learningSet,
            set.questions.indices.contains(state.currentQuestionIndex)
        else { return nil }

        let question = set.questions[state.currentQuestionIndex]
        let isLastQuestion = state.currentQuestionIndex == set.questions.count - 1
        return QuestionSolvingFeature.State(
            projectID: state.projectID,
            question: question,
            questionNumber: state.currentQuestionIndex + 1,
            questionCount: set.questions.count,
            advanceActionTitle: isLastQuestion ? Self.completeActionTitle : Self.nextQuestionActionTitle,
            isBookmarked: state.bookmarkedQuestionIDs.contains(question.questionID),
        )
    }

    private func activate(
        _ screen: ActiveScreen,
        cause: ScreenTransition.Cause,
        state: inout State,
    ) -> Effect<Action> {
        guard state.activeScreen != screen else { return .none }
        state.screenTransitions.append(
            ScreenTransition(from: state.activeScreen, to: screen, cause: cause)
        )
        state.activeScreen = screen
        return .none
    }

}
