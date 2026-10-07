import ComposableArchitecture
import DomainLearningProject
import Foundation

// MARK: - SingleQuestionEntryFeature

/// 저장한 문제 하나를 열기 위해 세트를 조회하는 화면 없는 조건부 Feature입니다.
@Reducer
public struct SingleQuestionEntryFeature: Sendable {

    // MARK: Lifecycle

    public init(fetchLearningSet: any FetchLearningSetUseCase) {
        self.fetchLearningSet = fetchLearningSet
    }

    // MARK: Public

    public enum Preparation: Equatable, Sendable {
        case idle
        case loading(questionID: String)
        case failed(LearningProjectError)
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(projectID: String) {
            self.projectID = projectID
        }

        // MARK: Public

        public let projectID: String
        public var preparation = Preparation.idle

        public var isPreparing: Bool {
            if case .loading = preparation {
                return true
            }
            return false
        }

        public var preparationError: LearningProjectError? {
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
            case questionRequested(setID: String, questionID: String)
            case failureDismissed
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case setLoadFinished(questionID: String, result: Result<LearningSet, LearningProjectError>)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case questionPrepared(question: Question, projectID: String)
            case preparationFailed(LearningProjectError)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .input(.questionRequested(let setID, let questionID)):
                guard !state.isPreparing else { return .none }
                state.preparation = .loading(questionID: questionID)
                let projectID = state.projectID
                return .run { send in
                    do {
                        let set = try await fetchLearningSet(projectID: projectID, setID: setID)
                        await send(.effect(.setLoadFinished(questionID: questionID, result: .success(set))))
                    } catch {
                        let mapped = error as? LearningProjectError ?? .unexpected
                        await send(.effect(.setLoadFinished(questionID: questionID, result: .failure(mapped))))
                    }
                }
                .cancellable(id: CancelID.load, cancelInFlight: true)

            case .input(.failureDismissed):
                state.preparation = .idle
                return .none

            case .effect(.setLoadFinished(let questionID, let result)):
                guard
                    case .loading(let pendingQuestionID) = state.preparation,
                    pendingQuestionID == questionID
                else { return .none }

                switch result {
                case .success(let set):
                    guard let question = set.questions.first(where: { $0.questionID == questionID }) else {
                        state.preparation = .failed(.questionUnavailable)
                        return .send(.delegate(.preparationFailed(.questionUnavailable)))
                    }
                    state.preparation = .idle
                    return .send(.delegate(.questionPrepared(question: question, projectID: state.projectID)))

                case .failure(let error):
                    state.preparation = .failed(error)
                    return .send(.delegate(.preparationFailed(error)))
                }

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case load
    }

    private let fetchLearningSet: any FetchLearningSetUseCase

}
