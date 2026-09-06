import ComposableArchitecture
import DomainLearningProject
import Foundation

// MARK: - QuestionSolvingFeature

@Reducer
public struct QuestionSolvingFeature: Sendable {

    // MARK: Lifecycle

    public init(
        submitChoiceAnswer: any SubmitChoiceAnswerUseCase,
        submitEssayAnswer: any SubmitEssayAnswerUseCase,
        setQuestionBookmark: any SetQuestionBookmarkUseCase,
    ) {
        self.submitChoiceAnswer = submitChoiceAnswer
        self.submitEssayAnswer = submitEssayAnswer
        self.setQuestionBookmark = setQuestionBookmark
    }

    // MARK: Public

    public enum AnswerOutcome: Equatable, Sendable {
        case choice(ChoiceAnswerResult)
        case essay(EssayAnswerResult)
    }

    public enum Submission: Equatable, Sendable {
        case editing
        case submitting
        case answered(AnswerOutcome)
        case failed(LearningProjectError)
    }

    public enum BookmarkMutation: Equatable, Sendable {
        case idle
        case committing
        case failed(LearningProjectError)
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(
            projectID: String,
            question: Question,
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

        public let projectID: String
        public var question: Question
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

        public var submissionError: LearningProjectError? {
            guard case .failed(let error) = submission else { return nil }
            return error
        }

        public var isSubmitting: Bool {
            submission == .submitting
        }

        public var isSubmitEnabled: Bool {
            guard !isSubmitting, answerOutcome == nil else { return false }
            switch question.format {
            case .multipleChoice:
                return draftChoiceIndex != nil

            case .essay:
                return !draftEssayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                questionID: String,
                result: Result<ChoiceAnswerResult, LearningProjectError>,
            )
            case essayAnswerFinished(
                questionID: String,
                result: Result<EssayAnswerResult, LearningProjectError>,
            )
            case bookmarkFinished(
                questionID: String,
                result: Result<BookmarkState, LearningProjectError>,
            )
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case answerSubmitted(questionID: String, choiceCorrect: Bool?)
            case advanceRequested
            case externalURLRequested(URL)
            case backRequested
        }
    }

    public static let essayCharacterLimit = 400

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.choiceSelected(let index)):
                guard state.submission != .submitting, state.answerOutcome == nil else { return .none }
                state.draftChoiceIndex = index
                return .none

            case .view(.essayTextChanged(let text)):
                guard state.submission != .submitting, state.answerOutcome == nil else { return .none }
                state.draftEssayText = String(text.prefix(Self.essayCharacterLimit))
                return .none

            case .view(.submitAnswerTapped):
                return submit(&state)

            case .view(.advanceTapped):
                guard state.answerOutcome != nil else { return .none }
                return .send(.delegate(.advanceRequested))

            case .view(.bookmarkToggleTapped):
                guard state.bookmarkMutation != .committing else { return .none }
                state.bookmarkMutation = .committing
                let projectID = state.projectID
                let questionID = state.question.questionID
                let bookmarked = !state.isBookmarked
                return .run { send in
                    do {
                        let result = try await setQuestionBookmark(
                            projectID: projectID,
                            questionID: questionID,
                            bookmarked: bookmarked,
                        )
                        await send(.effect(.bookmarkFinished(questionID: questionID, result: .success(result))))
                    } catch {
                        let mapped = error as? LearningProjectError ?? .unexpected
                        await send(.effect(.bookmarkFinished(questionID: questionID, result: .failure(mapped))))
                    }
                }
                .cancellable(id: CancelID.bookmark, cancelInFlight: true)

            case .view(.sourceTapped):
                guard state.isSourceControlPresented else { return .none }
                state.isSourceSheetPresented = true
                return .none

            case .view(.sourceSheetDismissed):
                state.isSourceSheetPresented = false
                return .none

            case .view(.sourceLinkTapped(let url)):
                return .send(.delegate(.externalURLRequested(url)))

            case .view(.backTapped):
                guard state.submission != .submitting else { return .none }
                return .send(.delegate(.backRequested))

            case .effect(.choiceAnswerFinished(let questionID, let result)):
                guard questionID == state.question.questionID else { return .none }
                switch result {
                case .success(let outcome):
                    state.submission = .answered(.choice(outcome))
                    return .send(.delegate(.answerSubmitted(
                        questionID: questionID,
                        choiceCorrect: outcome.correct,
                    )))

                case .failure(let error):
                    state.submission = .failed(error)
                    return .none
                }

            case .effect(.essayAnswerFinished(let questionID, let result)):
                guard questionID == state.question.questionID else { return .none }
                switch result {
                case .success(let outcome):
                    state.submission = .answered(.essay(outcome))
                    return .send(.delegate(.answerSubmitted(questionID: questionID, choiceCorrect: nil)))

                case .failure(let error):
                    state.submission = .failed(error)
                    return .none
                }

            case .effect(.bookmarkFinished(let questionID, let result)):
                guard questionID == state.question.questionID else { return .none }
                switch result {
                case .success(let bookmarkState):
                    state.isBookmarked = bookmarkState.bookmarked
                    state.bookmarkMutation = .idle

                case .failure(let error):
                    state.bookmarkMutation = .failed(error)
                }
                return .none

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case submit
        case bookmark
    }

    private let submitChoiceAnswer: any SubmitChoiceAnswerUseCase
    private let submitEssayAnswer: any SubmitEssayAnswerUseCase
    private let setQuestionBookmark: any SetQuestionBookmarkUseCase

    private func submit(_ state: inout State) -> Effect<Action> {
        guard state.submission != .submitting, state.answerOutcome == nil else { return .none }
        let projectID = state.projectID
        let questionID = state.question.questionID

        switch state.question.format {
        case .multipleChoice:
            guard let selectedIndex = state.draftChoiceIndex else { return .none }
            state.submission = .submitting
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
            .cancellable(id: CancelID.submit, cancelInFlight: true)

        case .essay:
            let text = state.draftEssayText
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return .none }
            state.submission = .submitting
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
            .cancellable(id: CancelID.submit, cancelInFlight: true)
        }
    }

}
