import ComposableArchitecture
import DomainExternalRepository

@Reducer
public struct RepositoryConfirmationFeature: Sendable {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        public init(repository: ExternalRepository? = nil) {
            self.repository = repository
        }

        public var repository: ExternalRepository?

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case input(Input)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case confirmTapped
            case rejectTapped
            case backTapped
        }

        @CasePathable
        public enum Input: Sendable, Equatable {
            case repositoryProvided(ExternalRepository)
            case cleared
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case confirmed
            case rejected
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

            case .input(let action):
                reduce(
                    into: &state,
                    input: action,
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
        case .confirmTapped:
            .send(.delegate(.confirmed))

        case .rejectTapped,
             .backTapped:
            .send(.delegate(.rejected))
        }
    }

    private func reduce(
        into state: inout State,
        input action: Action.Input,
    ) -> Effect<Action> {
        switch action {
        case .repositoryProvided(let repository):
            state.repository = repository
            return .none

        case .cleared:
            state.repository = nil
            return .none
        }
    }

}
