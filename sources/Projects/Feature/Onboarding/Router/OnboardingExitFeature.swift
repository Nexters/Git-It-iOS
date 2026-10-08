import ComposableArchitecture
import Foundation

// MARK: - OnboardingExitFeature

@Reducer
public struct OnboardingExitFeature: Sendable {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {
        public init() { }
    }

    public enum Action: Sendable, Equatable {
        case input(Input)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum Input: Sendable, Equatable {
            case curationSucceeded
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case shouldExit
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

            case .delegate:
                .none
            }
        }
    }

    // MARK: Private

    private func reduce(
        into _: inout State,
        input action: Action.Input,
    ) -> Effect<Action> {
        switch action {
        case .curationSucceeded:
            .send(.delegate(.shouldExit))
        }
    }

}
