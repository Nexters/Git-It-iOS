import ComposableArchitecture
import DomainLearningProject
import Foundation

// MARK: - ProjectDetailRouterFeature

@Reducer
public struct ProjectDetailRouterFeature: Sendable {

    // MARK: Lifecycle

    public init(
        fetchLearningProjectDetail: any FetchLearningProjectDetailUseCase,
        deleteLearningProject: any DeleteLearningProjectUseCase,
        fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase,
        fetchLearningSet: any FetchLearningSetUseCase,
        submitChoiceAnswer: any SubmitChoiceAnswerUseCase,
        submitEssayAnswer: any SubmitEssayAnswerUseCase,
        setQuestionBookmark: any SetQuestionBookmarkUseCase,
    ) {
        self.fetchLearningProjectDetail = fetchLearningProjectDetail
        self.deleteLearningProject = deleteLearningProject
        self.fetchBookmarkedQuestions = fetchBookmarkedQuestions
        self.fetchLearningSet = fetchLearningSet
        self.submitChoiceAnswer = submitChoiceAnswer
        self.submitEssayAnswer = submitEssayAnswer
        self.setQuestionBookmark = setQuestionBookmark
    }

    // MARK: Public

    public enum ActiveScreen: Equatable, Sendable {
        case projectDetail
        case savedQuestions
        case singleQuestion
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
            case savedQuestionsRequested
            case singleQuestionPrepared(questionID: String)
            case singleQuestionFinished
            case backRequested
        }

        public let from: ActiveScreen
        public let to: ActiveScreen
        public let cause: Cause

    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(projectID: String) {
            self.projectID = projectID
            projectDetail = ProjectDetailFeature.State(projectID: projectID)
            savedQuestions = SavedFeature.State(projectFilter: projectID, isBackControlPresented: true)
            singleQuestionEntry = SingleQuestionEntryFeature.State(projectID: projectID)
        }

        // MARK: Public

        public let projectID: String

        public var activeScreen = ActiveScreen.projectDetail
        public var screenTransitions = [ScreenTransition]()

        public var projectDetail: ProjectDetailFeature.State
        public var savedQuestions: SavedFeature.State
        public var singleQuestion: QuestionSolvingFeature.State?
        public var singleQuestionEntry: SingleQuestionEntryFeature.State

    }

    public enum Action: Sendable, Equatable {
        case projectDetail(ProjectDetailFeature.Action)
        case savedQuestions(SavedFeature.Action)
        case singleQuestion(QuestionSolvingFeature.Action)
        case singleQuestionEntry(SingleQuestionEntryFeature.Action)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case learningSetRequested(projectID: String, setID: String, label: String)
            case externalURLRequested(URL)
            case projectDeleted(projectID: String)
            case dismissRequested
        }
    }

    public static let singleQuestionAdvanceActionTitle = "완료"

    public var body: some ReducerOf<Self> {
        Scope(state: \.projectDetail, action: \.projectDetail) {
            ProjectDetailFeature(
                fetchLearningProjectDetail: fetchLearningProjectDetail,
                deleteLearningProject: deleteLearningProject,
            )
        }
        Scope(state: \.savedQuestions, action: \.savedQuestions) {
            SavedFeature(
                fetchBookmarkedQuestions: fetchBookmarkedQuestions,
                setQuestionBookmark: setQuestionBookmark,
            )
        }
        Scope(state: \.singleQuestionEntry, action: \.singleQuestionEntry) {
            SingleQuestionEntryFeature(fetchLearningSet: fetchLearningSet)
        }
        Reduce { state, action in
            switch action {
            case .projectDetail(.delegate(.setStartRequested(let projectID, let setID, let label))):
                return .send(.delegate(.learningSetRequested(projectID: projectID, setID: setID, label: label)))

            case .projectDetail(.delegate(.savedQuestionsRequested)):
                return activate(.savedQuestions, cause: .savedQuestionsRequested, state: &state)

            case .projectDetail(.delegate(.externalURLRequested(let url))),
                 .singleQuestion(.delegate(.externalURLRequested(let url))):
                return .send(.delegate(.externalURLRequested(url)))

            case .projectDetail(.delegate(.projectDeleted(let projectID))):
                return .send(.delegate(.projectDeleted(projectID: projectID)))

            case .projectDetail(.delegate(.dismissRequested)):
                return .send(.delegate(.dismissRequested))

            case .savedQuestions(.delegate(.questionSelected(let question))):
                return .send(.singleQuestionEntry(.input(.questionRequested(
                    setID: question.setID,
                    questionID: question.questionID,
                ))))

            case .savedQuestions(.delegate(.backRequested)):
                return activate(.projectDetail, cause: .backRequested, state: &state)

            case .singleQuestionEntry(.delegate(.questionPrepared(let question, let projectID))):
                state.singleQuestion = QuestionSolvingFeature.State(
                    projectID: projectID,
                    question: question,
                    advanceActionTitle: Self.singleQuestionAdvanceActionTitle,
                    isBookmarked: true,
                )
                return activate(
                    .singleQuestion,
                    cause: .singleQuestionPrepared(questionID: question.questionID),
                    state: &state,
                )

            case .singleQuestionEntry(.delegate(.preparationFailed)):
                return .none

            case .singleQuestion(.delegate(.advanceRequested)),
                 .singleQuestion(.delegate(.backRequested)):
                state.singleQuestion = nil
                return activate(.savedQuestions, cause: .singleQuestionFinished, state: &state)

            case .projectDetail,
                 .savedQuestions,
                 .singleQuestion,
                 .singleQuestionEntry,
                 .delegate:
                return .none
            }
        }
        .ifLet(\.singleQuestion, action: \.singleQuestion) {
            QuestionSolvingFeature(
                submitChoiceAnswer: submitChoiceAnswer,
                submitEssayAnswer: submitEssayAnswer,
                setQuestionBookmark: setQuestionBookmark,
            )
        }
    }

    // MARK: Private

    private let fetchLearningProjectDetail: any FetchLearningProjectDetailUseCase
    private let deleteLearningProject: any DeleteLearningProjectUseCase
    private let fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase
    private let fetchLearningSet: any FetchLearningSetUseCase
    private let submitChoiceAnswer: any SubmitChoiceAnswerUseCase
    private let submitEssayAnswer: any SubmitEssayAnswerUseCase
    private let setQuestionBookmark: any SetQuestionBookmarkUseCase

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
