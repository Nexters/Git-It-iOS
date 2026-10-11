import ComposableArchitecture
import DomainUseCaseInterface

@Reducer
public struct PositionSelectionFeature: Sendable {

    // MARK: Lifecycle

    public init(signOut: @escaping @Sendable () async -> SignOutResult) {
        self.signOut = signOut
    }

    // MARK: Public

    public enum ExitStatus: Equatable, Sendable {
        case idle
        case inProgress
        case failed
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        public init() { }

        public var position: MemberPosition?
        public var exitStatus = ExitStatus.idle
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case positionSelected(MemberPosition)
            case nextTapped
            case backTapped
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case signOutFinished(SignOutResult)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case confirmed(MemberPosition)
            case exitRequested
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

            case .effect(let event):
                reduce(
                    into: &state,
                    effect: event,
                )

            case .delegate:
                .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case exit
    }

    private let signOut: @Sendable () async -> SignOutResult

    private func reduce(
        into state: inout State,
        view action: Action.View,
    ) -> Effect<Action> {
        switch action {
        case .positionSelected(let position):
            state.position = position
            return .none

        case .nextTapped:
            guard let position = state.position else { return .none }
            return .send(.delegate(.confirmed(position)))

        case .backTapped:
            guard state.exitStatus != .inProgress else { return .none }
            state.exitStatus = .inProgress
            return .run { send in
                let result = await signOut()
                await send(.effect(.signOutFinished(result)))
            }
            .cancellable(
                id: CancelID.exit,
                cancelInFlight: true,
            )
        }
    }

    private func reduce(
        into state: inout State,
        effect event: Action.EffectEvent,
    ) -> Effect<Action> {
        switch event {
        case .signOutFinished(let result):
            switch result {
            case .signedOut:
                state.exitStatus = .idle
                return .send(.delegate(.exitRequested))

            case .retryableFailure:
                state.exitStatus = .failed
                return .none
            }
        }
    }

}
