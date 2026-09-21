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
            case .input(.repositoryProvided(let repository)):
                state.repository = repository
                return .none

            case .input(.cleared):
                state.repository = nil
                return .none

            case .view(.confirmTapped):
                return .send(.delegate(.confirmed))

            case .view(.rejectTapped),
                 .view(.backTapped):
                return .send(.delegate(.rejected))

            case .delegate:
                return .none
            }
        }
    }

}
