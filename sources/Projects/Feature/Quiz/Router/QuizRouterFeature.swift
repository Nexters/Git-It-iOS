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

    public static let nextQuestionActionTitle = LocalizedText.Quiz.QuestionSolving.NextQuestion.buttonTitle
    public static let completeActionTitle = LocalizedText.Quiz.QuestionSolving.Complete.buttonTitle

    public var body: some ReducerOf<Self> {
        Scope(
            state: \.learningSetIntro,
            action: \.learningSetIntro,
        ) {
            LearningSetIntroFeature(
                fetchQuizSet: { [quizDetail] setID, projectID in
                    try await quizDetail.quizSet(
                        setID,
                        in: projectID,
                    )
                },
                fetchBookmarks: { [quizDetail] filter in try await quizDetail.bookmarks(filter) },
            )
        }
        Scope(
            state: \.learningCompletion,
            action: \.learningCompletion,
        ) {
            LearningCompletionFeature()
        }
        Scope(
            state: \.session,
            action: \.session,
        ) {
            LearningSessionFeature()
        }
        Reduce { state, action in
            switch action {
            case .learningSetIntro(let action):
                reduce(
                    into: &state,
                    learningSetIntro: action,
                )

            case .questionSolving(let action):
                reduce(
                    into: &state,
                    questionSolving: action,
                )

            case .learningCompletion(let action):
                reduce(
                    into: &state,
                    learningCompletion: action,
                )

            case .session(let action):
                reduce(
                    into: &state,
                    session: action,
                )

            case .delegate:
                .none
            }
        }
        .ifLet(
            \.questionSolving,
            action: \.questionSolving,
        ) {
            QuestionSolvingFeature(
                gradeChoiceAnswer: { [quizDetail] answer in try await quizDetail.grade(answer) },
                gradeEssayAnswer: { [quizDetail] answer in try await quizDetail.grade(answer) },
                setBookmark: { [quizDetail] quizID, projectID, isBookmarked in
                    isBookmarked
                        ? try await quizDetail.bookmark(
                            quizID,
                            in: projectID,
                        )
                        : try await quizDetail.unbookmark(
                            quizID,
                            in: projectID,
                        )
                },
            )
        }
    }

    // MARK: Private

    private let quizDetail: any QuizDetailUseCase

    private func reduce(
        into state: inout State,
        learningSetIntro action: LearningSetIntroFeature.Action,
    ) -> Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .startRequested(let set, let resumption, let bookmarkedQuestionIDs):
            let started = Effect<Action>.send(.session(.input(.started(
                set: set,
                resumption: resumption,
                bookmarkedQuestionIDs: bookmarkedQuestionIDs,
            ))))
            guard state.questionSolving != nil else { return started }
            return .merge(started, activate(
                .questionSolving,
                cause: .startRequested,
                state: &state,
            ))

        case .backRequested:
            return .send(.delegate(.dismissRequested(projectID: state.projectID)))
        }
    }

    private func reduce(
        into state: inout State,
        questionSolving action: QuestionSolvingFeature.Action,
    ) -> Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .backRequested:
            return .send(.delegate(.dismissRequested(projectID: state.projectID)))

        case .answerSubmitted(_, let choiceCorrect):
            return .send(.session(.input(.answerRecorded(choiceCorrect: choiceCorrect))))

        case .advanceRequested:
            return .send(.session(.input(.advanced)))

        case .externalURLRequested(let url):
            return .send(.delegate(.externalURLRequested(url)))
        }
    }

    private func reduce(
        into state: inout State,
        learningCompletion action: LearningCompletionFeature.Action,
    ) -> Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .dismissRequested:
            return .send(.delegate(.dismissRequested(projectID: state.projectID)))
        }
    }

    private func reduce(
        into state: inout State,
        session action: LearningSessionFeature.Action,
    ) -> Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .questionReady(let question, let number, let isBookmarked, let isLast):
            state.questionSolving = QuestionSolvingFeature.State(
                projectID: state.projectID,
                question: question,
                questionNumber: number,
                advanceActionTitle: isLast ? Self.completeActionTitle : Self.nextQuestionActionTitle,
                isBookmarked: isBookmarked,
            )
            return activate(
                .questionSolving,
                cause: .startRequested,
                state: &state,
            )

        case .emptySetDetected:
            return .send(.learningSetIntro(.input(.emptySetReported)))

        case .completed(let correctChoiceCount, let choiceQuestionCount):
            state.learningCompletion.choiceQuestionCount = choiceQuestionCount
            state.learningCompletion.correctChoiceCount = correctChoiceCount
            return activate(
                .learningCompletion,
                cause: .advancedToCompletion,
                state: &state,
            )
        }
    }

    private func activate(
        _ screen: ActiveScreen,
        cause: ScreenTransition.Cause,
        state: inout State,
    ) -> Effect<Action> {
        guard state.activeScreen != screen else { return .none }
        state.screenTransitions.append(
            ScreenTransition(
                from: state.activeScreen,
                to: screen,
                cause: cause,
            )
        )
        state.activeScreen = screen
        return .none
    }

}
