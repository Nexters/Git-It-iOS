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
        Reduce { state, action in
            switch action {
            case .view(let action):
                reduce(
                    into: &state,
                    view: action,
                )

            case .delegate:
                .none
            }
        }
    }

    // MARK: Private

    private func reduce(
        into _: inout State,
        view action: Action.View,
    ) -> Effect<Action> {
        switch action {
        case .startTapped:
            .send(.delegate(.submitRequested))

        case .backTapped:
            .send(.delegate(.backRequested))
        }
    }

}
