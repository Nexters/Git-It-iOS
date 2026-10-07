import ComposableArchitecture
import DomainLearningProject

@Reducer
public struct RepositoryConfirmationFeature: Sendable {

    public init() { }

    @ObservableState
    public struct State: Equatable, Sendable {

        public init(repository: ExternalRepository? = nil) {
            self.repository = repository
        }

        public var repository: ExternalRepository?
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case delegate(Delegate)

        @CasePathable
        public enum View: Sendable, Equatable {
            case confirmTapped
            case rejectTapped
            case backTapped
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case confirmed
            case rejected
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
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
