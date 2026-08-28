import ComposableArchitecture
import Foundation

// MARK: - OnboardingExitFeature

/// Onboarding Router가 상위(App Root)로 전환해야 하는지("완료 여부"가 아니라 "Router 전환
/// 여부")만 판단하는 얇은 조건부 Feature.
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
        Reduce { _, action in
            switch action {
            case .input(.curationSucceeded):
                .send(.delegate(.shouldExit))

            case .delegate:
                .none
            }
        }
    }

}
