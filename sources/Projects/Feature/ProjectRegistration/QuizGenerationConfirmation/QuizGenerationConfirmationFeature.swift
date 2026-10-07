import ComposableArchitecture

@Reducer
public struct QuizGenerationConfirmationFeature: Sendable {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

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
                .send(.delegate(.submitRequested))

            case .view(.backTapped):
                .send(.delegate(.backRequested))

            case .delegate:
                .none
            }
        }
    }

}
