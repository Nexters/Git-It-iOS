import ComposableArchitecture
import DomainIdentifier
import DomainQuizDetail
import Foundation

// MARK: - QuizRouterFeature

@Reducer
public struct QuizRouterFeature: Sendable {

    // MARK: Lifecycle

    public init(quizDetail: any QuizDetailUseCase) {
        self.quizDetail = quizDetail
    }

    // MARK: Public

    public enum ActiveScreen: Hashable, Sendable {
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
        }

        public let from: ActiveScreen
        public let to: ActiveScreen
        public let cause: Cause

    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(
            projectID: ProjectID,
            setID: QuizSetID,
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

        public let projectID: ProjectID
        public let setID: QuizSetID
        public let setLabel: String

        public var activeScreen = ActiveScreen.learningSetIntro
        public var screenTransitions = [ScreenTransition]()

        public var learningSetIntro: LearningSetIntroFeature.State
        public var questionSolving: QuestionSolvingFeature.State?
        public var learningCompletion: LearningCompletionFeature.State

        public internal(set) var learningSet: QuizSet?
        public internal(set) var currentQuestionIndex = 0
        public internal(set) var resumption: LearningSetResumption?
        public internal(set) var sessionCorrectChoiceCount = 0
        public internal(set) var bookmarkedQuestionIDs = Set<QuizID>()

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
            case dismissRequested(projectID: ProjectID)
        }
    }

    public static let nextQuestionActionTitle = "다음 문제"
    public static let completeActionTitle = "학습 완료"

    public var body: some ReducerOf<Self> {
        Scope(state: \.learningSetIntro, action: \.learningSetIntro) {
            LearningSetIntroFeature(
                fetchQuizSet: { [quizDetail] setID, projectID in
                    try await quizDetail.quizSet(setID, in: projectID)
                },
                fetchBookmarks: { [quizDetail] filter in try await quizDetail.bookmarks(filter) },
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

                guard set.quizzes.indices.contains(resumption.startIndex) else {
                    return .send(.learningSetIntro(.input(.emptySetReported)))
                }

                state.currentQuestionIndex = resumption.startIndex
                state.sessionCorrectChoiceCount = 0
                state.questionSolving = questionSolvingState(state: state)
                return activate(.questionSolving, cause: .startRequested, state: &state)

            case .learningSetIntro(.delegate(.backRequested)):
                return .send(.delegate(.dismissRequested(projectID: state.projectID)))

            case .questionSolving(.delegate(.backRequested)):
                return .send(.delegate(.dismissRequested(projectID: state.projectID)))

            case .questionSolving(.delegate(.answerSubmitted(_, let choiceCorrect))):
                if choiceCorrect == true {
                    state.sessionCorrectChoiceCount += 1
                }
                return .none

            case .questionSolving(.delegate(.advanceRequested)):
                let nextIndex = state.currentQuestionIndex + 1
                guard let set = state.learningSet, set.quizzes.indices.contains(nextIndex) else {
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
                gradeChoiceAnswer: { [quizDetail] answer in try await quizDetail.grade(answer) },
                gradeEssayAnswer: { [quizDetail] answer in try await quizDetail.grade(answer) },
                setBookmark: { [quizDetail] quizID, projectID, isBookmarked in
                    isBookmarked
                        ? try await quizDetail.bookmark(quizID, in: projectID)
                        : try await quizDetail.unbookmark(quizID, in: projectID)
                },
            )
        }
    }

    // MARK: Private

    private let quizDetail: any QuizDetailUseCase

    private func questionSolvingState(state: State) -> QuestionSolvingFeature.State? {
        guard
            let set = state.learningSet,
            set.quizzes.indices.contains(state.currentQuestionIndex)
        else { return nil }

        let quiz = set.quizzes[state.currentQuestionIndex]
        let isLastQuestion = state.currentQuestionIndex == set.quizzes.count - 1
        return QuestionSolvingFeature.State(
            projectID: state.projectID,
            question: quiz,
            questionNumber: state.currentQuestionIndex + 1,
            advanceActionTitle: isLastQuestion ? Self.completeActionTitle : Self.nextQuestionActionTitle,
            isBookmarked: state.bookmarkedQuestionIDs.contains(quiz.id),
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
