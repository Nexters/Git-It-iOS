import ComposableArchitecture
import DomainLearningProject

@Reducer
public struct QuizLevelSelectionFeature: Sendable {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        public init(quizLevel: QuizLevel = .l1) {
            self.quizLevel = quizLevel
        }

        public var quizLevel: QuizLevel

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case delegate(Delegate)

        @CasePathable
        public enum View: Sendable, Equatable {
            case levelSelected(QuizLevel)
            case nextTapped
            case backTapped
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case confirmed(QuizLevel)
            case backRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.levelSelected(let level)):
                state.quizLevel = level
                return .none

            case .view(.nextTapped):
                return .send(.delegate(.confirmed(state.quizLevel)))

            case .view(.backTapped):
                return .send(.delegate(.backRequested))

            case .delegate:
                return .none
            }
        }
    }

}
