import ComposableArchitecture

@Reducer
public struct QuizGenerationConfirmationFeature: Sendable {

    public init() { }

    @ObservableState
    public struct State: Equatable, Sendable {
        public init() { }
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case delegate(Delegate)

        @CasePathable
        public enum View: Sendable, Equatable {
            case startTapped
            case backTapped
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case submitRequested
            case backRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .view(.startTapped):
                return .send(.delegate(.submitRequested))

            case .view(.backTapped):
                return .send(.delegate(.backRequested))

            case .delegate:
                return .none
            }
        }
    }

}
