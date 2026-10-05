import ComposableArchitecture
import DomainUseCaseInterface
import Foundation

// MARK: - QuestionSolvingFeature

@Reducer
public struct QuestionSolvingFeature: Sendable {

    // MARK: Lifecycle

    public init(
        gradeChoiceAnswer: @escaping @Sendable (ChoiceAnswer) async throws -> ChoiceGrading,
        gradeEssayAnswer: @escaping @Sendable (EssayAnswer) async throws -> EssayGrading,
        setBookmark: @escaping @Sendable (QuizID, ProjectID, Bool) async throws -> QuizBookmarkState,
    ) {
        self.gradeChoiceAnswer = gradeChoiceAnswer
        self.gradeEssayAnswer = gradeEssayAnswer
        self.setBookmark = setBookmark
    }

    // MARK: Public

    public enum AnswerOutcome: Equatable, Sendable {
        case choice(ChoiceGrading)
        case essay(EssayGrading)
    }

    public enum Submission: Equatable, Sendable {
        case editing
        case submitting
        case answered(AnswerOutcome)
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
            projectID: ProjectID,
            question: Quiz,
            questionNumber: Int? = nil,
            advanceActionTitle: String,
            isBookmarked: Bool = false,
        ) {
            self.projectID = projectID
            self.question = question
            self.questionNumber = questionNumber
            self.advanceActionTitle = advanceActionTitle
            self.isBookmarked = isBookmarked
        }

        // MARK: Public

        public let projectID: ProjectID
        public var question: Quiz
        public var questionNumber: Int?
        public let advanceActionTitle: String

        public var submission = Submission.editing
        public var draftChoiceIndex: Int?
        public var draftEssayText = ""
        public var isBookmarked = false
        public var bookmarkMutation = BookmarkMutation.idle
        public var isSourceSheetPresented = false

        public var isSourceControlPresented: Bool {
            !question.sources.isEmpty
        }

        public var answerOutcome: AnswerOutcome? {
            guard case .answered(let outcome) = submission else { return nil }
            return outcome
        }

        public var submissionError: QuizDetailError? {
            guard case .failed(let error) = submission else { return nil }
            return error
        }

        public var isSubmitting: Bool {
            submission == .submitting
        }

        public var isSubmitEnabled: Bool {
            guard !isSubmitting, answerOutcome == nil else { return false }
            switch question.content {
            case .choice:
                return draftChoiceIndex != nil

            case .essay:
                return true
            }
        }

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case choiceSelected(Int)
            case essayTextChanged(String)
            case submitAnswerTapped
            case advanceTapped
            case bookmarkToggleTapped
            case sourceTapped
            case sourceSheetDismissed
            case sourceLinkTapped(URL)
            case backTapped
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case choiceAnswerFinished(
                questionID: QuizID,
                result: Result<ChoiceGrading, QuizDetailError>,
            )
            case essayAnswerFinished(
                questionID: QuizID,
                result: Result<EssayGrading, QuizDetailError>,
            )
            case bookmarkFinished(
                questionID: QuizID,
                result: Result<QuizBookmarkState, QuizDetailError>,
            )
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case answerSubmitted(questionID: QuizID, choiceCorrect: Bool?)
            case advanceRequested
            case externalURLRequested(URL)
            case backRequested
        }
    }

    public static let essayCharacterLimit = 400

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
        case submit
        case bookmark
    }

    private let gradeChoiceAnswer: @Sendable (ChoiceAnswer) async throws -> ChoiceGrading
    private let gradeEssayAnswer: @Sendable (EssayAnswer) async throws -> EssayGrading
    private let setBookmark: @Sendable (QuizID, ProjectID, Bool) async throws -> QuizBookmarkState

    private func reduce(
        into state: inout State,
        view action: Action.View,
    ) -> Effect<Action> {
        switch action {
        case .choiceSelected(let index):
            guard state.submission != .submitting, state.answerOutcome == nil else { return .none }
            state.draftChoiceIndex = index
            return .none

        case .essayTextChanged(let text):
            guard state.submission != .submitting, state.answerOutcome == nil else { return .none }
            state.draftEssayText = String(text.prefix(Self.essayCharacterLimit))
            return .none

        case .submitAnswerTapped:
            return submit(&state)

        case .advanceTapped:
            guard state.answerOutcome != nil else { return .none }
            return .send(.delegate(.advanceRequested))

        case .bookmarkToggleTapped:
            guard state.bookmarkMutation != .committing else { return .none }
            state.bookmarkMutation = .committing
            let projectID = state.projectID
            let questionID = state.question.id
            let bookmarked = !state.isBookmarked
            return .run { send in
                do {
                    let bookmarkState = try await setBookmark(questionID, projectID, bookmarked)
                    await send(.effect(.bookmarkFinished(
                        questionID: questionID,
                        result: .success(bookmarkState),
                    )))
                } catch {
                    let mapped = error as? QuizDetailError ?? .unexpected
                    await send(.effect(.bookmarkFinished(
                        questionID: questionID,
                        result: .failure(mapped),
                    )))
                }
            }
            .cancellable(
                id: CancelID.bookmark,
                cancelInFlight: true,
            )

        case .sourceTapped:
            guard state.isSourceControlPresented else { return .none }
            state.isSourceSheetPresented = true
            return .none

        case .sourceSheetDismissed:
            state.isSourceSheetPresented = false
            return .none

        case .sourceLinkTapped(let url):
            return .send(.delegate(.externalURLRequested(url)))

        case .backTapped:
            guard state.submission != .submitting else { return .none }
            return .send(.delegate(.backRequested))
        }
    }

    private func reduce(
        into state: inout State,
        effect event: Action.EffectEvent,
    ) -> Effect<Action> {
        switch event {
        case .choiceAnswerFinished(let questionID, let result):
            guard questionID == state.question.id else { return .none }
            switch result {
            case .success(let grading):
                state.submission = .answered(.choice(grading))
                return .send(.delegate(.answerSubmitted(
                    questionID: questionID,
                    choiceCorrect: grading.isCorrect,
                )))

            case .failure(let error):
                state.submission = .failed(error)
                return .none
            }

        case .essayAnswerFinished(let questionID, let result):
            guard questionID == state.question.id else { return .none }
            switch result {
            case .success(let grading):
                state.submission = .answered(.essay(grading))
                return .send(.delegate(.answerSubmitted(
                    questionID: questionID,
                    choiceCorrect: nil,
                )))

            case .failure(let error):
                state.submission = .failed(error)
                return .none
            }

        case .bookmarkFinished(let questionID, let result):
            guard questionID == state.question.id else { return .none }
            switch result {
            case .success(let bookmarkState):
                state.isBookmarked = bookmarkState.isBookmarked
                state.bookmarkMutation = .idle

            case .failure(let error):
                state.bookmarkMutation = .failed(error)
            }
            return .none
        }
    }

    private func submit(_ state: inout State) -> Effect<Action> {
        guard state.submission != .submitting, state.answerOutcome == nil else { return .none }
        let projectID = state.projectID
        let questionID = state.question.id

        switch state.question.content {
        case .choice:
            guard let selectedIndex = state.draftChoiceIndex else { return .none }
            state.submission = .submitting
            let answer = ChoiceAnswer(
                projectID: projectID,
                quizID: questionID,
                selectedIndex: selectedIndex,
            )
            return .run { send in
                do {
                    let grading = try await gradeChoiceAnswer(answer)
                    await send(.effect(.choiceAnswerFinished(
                        questionID: questionID,
                        result: .success(grading),
                    )))
                } catch {
                    let mapped = error as? QuizDetailError ?? .unexpected
                    await send(.effect(.choiceAnswerFinished(
                        questionID: questionID,
                        result: .failure(mapped),
                    )))
                }
            }
            .cancellable(
                id: CancelID.submit,
                cancelInFlight: true,
            )

        case .essay:
            state.submission = .submitting
            let answer = EssayAnswer(
                projectID: projectID,
                quizID: questionID,
                text: state.draftEssayText,
            )
            return .run { send in
                do {
                    let grading = try await gradeEssayAnswer(answer)
                    await send(.effect(.essayAnswerFinished(
                        questionID: questionID,
                        result: .success(grading),
                    )))
                } catch {
                    let mapped = error as? QuizDetailError ?? .unexpected
                    await send(.effect(.essayAnswerFinished(
                        questionID: questionID,
                        result: .failure(mapped),
                    )))
                }
            }
            .cancellable(
                id: CancelID.submit,
                cancelInFlight: true,
            )
        }
    }

}
