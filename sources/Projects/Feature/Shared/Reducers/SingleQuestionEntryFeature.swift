import ComposableArchitecture
import DomainIdentifier
import DomainQuizDetail
import Foundation

// MARK: - SingleQuestionEntryFeature

@Reducer
public struct SingleQuestionEntryFeature: Sendable {

    // MARK: Lifecycle

    public init(fetchQuizSet: @escaping @Sendable (QuizSetID, ProjectID) async throws -> QuizSet) {
        self.fetchQuizSet = fetchQuizSet
    }

    // MARK: Public

    public enum Preparation: Equatable, Sendable {
        case idle
        case loading(questionID: QuizID)
        case failed(QuizDetailError)
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(projectID: ProjectID) {
            self.projectID = projectID
        }

        // MARK: Public

        public let projectID: ProjectID
        public var preparation = Preparation.idle

        public var isPreparing: Bool {
            if case .loading = preparation {
                return true
            }
            return false
        }

        public var preparationError: QuizDetailError? {
            guard case .failed(let error) = preparation else { return nil }
            return error
        }

    }

    public enum Action: Sendable, Equatable {
        case input(Input)
        case effect(EffectEvent)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum Input: Sendable, Equatable {
            case questionRequested(setID: QuizSetID, questionID: QuizID)
            case failureDismissed
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case setLoadFinished(questionID: QuizID, result: Result<QuizSet, QuizDetailError>)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case questionPrepared(question: Quiz, projectID: ProjectID)
            case preparationFailed(QuizDetailError)
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
        case load
    }

    private let fetchQuizSet: @Sendable (QuizSetID, ProjectID) async throws -> QuizSet

    private func reduce(
        into state: inout State,
        input action: Action.Input,
    ) -> Effect<Action> {
        switch action {
        case .questionRequested(let setID, let questionID):
            guard !state.isPreparing else { return .none }
            state.preparation = .loading(questionID: questionID)
            let projectID = state.projectID
            return .run { send in
                do {
                    let set = try await fetchQuizSet(setID, projectID)
                    await send(.effect(.setLoadFinished(
                        questionID: questionID,
                        result: .success(set),
                    )))
                } catch {
                    let mapped = error as? QuizDetailError ?? .unexpected
                    await send(.effect(.setLoadFinished(
                        questionID: questionID,
                        result: .failure(mapped),
                    )))
                }
            }
            .cancellable(
                id: CancelID.load,
                cancelInFlight: true,
            )

        case .failureDismissed:
            state.preparation = .idle
            return .none
        }
    }

    private func reduce(
        into state: inout State,
        effect event: Action.EffectEvent,
    ) -> Effect<Action> {
        switch event {
        case .setLoadFinished(let questionID, let result):
            guard
                case .loading(let pendingQuestionID) = state.preparation,
                pendingQuestionID == questionID
            else { return .none }

            switch result {
            case .success(let set):
                guard let quiz = set.quizzes.first(where: { $0.id == questionID }) else {
                    state.preparation = .failed(.quizUnavailable)
                    return .send(.delegate(.preparationFailed(.quizUnavailable)))
                }
                state.preparation = .idle
                return .send(.delegate(.questionPrepared(
                    question: quiz,
                    projectID: state.projectID,
                )))

            case .failure(let error):
                state.preparation = .failed(error)
                return .send(.delegate(.preparationFailed(error)))
            }
        }
    }

}
