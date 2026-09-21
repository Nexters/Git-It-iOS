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
        public var session = LearningSessionFeature.State()

    }

    public enum Action: Sendable, Equatable {
        case learningSetIntro(LearningSetIntroFeature.Action)
        case questionSolving(QuestionSolvingFeature.Action)
        case learningCompletion(LearningCompletionFeature.Action)
        case session(LearningSessionFeature.Action)
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
        Scope(state: \.session, action: \.session) {
            LearningSessionFeature()
        }
        Reduce { state, action in
            switch action {
            case .learningSetIntro(.delegate(.startRequested(let set, let resumption, let bookmarkedQuestionIDs))):
                let started = Effect<Action>.send(.session(.input(.started(
                    set: set,
                    resumption: resumption,
                    bookmarkedQuestionIDs: bookmarkedQuestionIDs,
                ))))
                guard state.questionSolving != nil else { return started }
                return .merge(started, activate(.questionSolving, cause: .startRequested, state: &state))

            case .session(.delegate(.questionReady(let question, let number, let isBookmarked, let isLast))):
                state.questionSolving = QuestionSolvingFeature.State(
                    projectID: state.projectID,
                    question: question,
                    questionNumber: number,
                    advanceActionTitle: isLast ? Self.completeActionTitle : Self.nextQuestionActionTitle,
                    isBookmarked: isBookmarked,
                )
                return activate(.questionSolving, cause: .startRequested, state: &state)

            case .session(.delegate(.emptySetDetected)):
                return .send(.learningSetIntro(.input(.emptySetReported)))

            case .session(.delegate(.completed(let correctChoiceCount, let choiceQuestionCount))):
                state.learningCompletion.choiceQuestionCount = choiceQuestionCount
                state.learningCompletion.correctChoiceCount = correctChoiceCount
                return activate(.learningCompletion, cause: .advancedToCompletion, state: &state)

            case .learningSetIntro(.delegate(.backRequested)):
                return .send(.delegate(.dismissRequested(projectID: state.projectID)))

            case .questionSolving(.delegate(.backRequested)):
                return .send(.delegate(.dismissRequested(projectID: state.projectID)))

            case .questionSolving(.delegate(.answerSubmitted(_, let choiceCorrect))):
                return .send(.session(.input(.answerRecorded(choiceCorrect: choiceCorrect))))

            case .questionSolving(.delegate(.advanceRequested)):
                return .send(.session(.input(.advanced)))

            case .questionSolving(.delegate(.externalURLRequested(let url))):
                return .send(.delegate(.externalURLRequested(url)))

            case .learningCompletion(.delegate(.dismissRequested)):
                return .send(.delegate(.dismissRequested(projectID: state.projectID)))

            case .learningSetIntro,
                 .questionSolving,
                 .learningCompletion,
                 .session,
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
