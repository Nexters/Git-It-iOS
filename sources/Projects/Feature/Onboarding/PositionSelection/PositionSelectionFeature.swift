import ComposableArchitecture
import DomainAuthentication
import DomainMember

@Reducer
public struct PositionSelectionFeature: Sendable {

    // MARK: Lifecycle

    public init(signOut: any SignOutUseCase) {
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
            case .view(.positionSelected(let position)):
                state.position = position
                return .none

            case .view(.nextTapped):
                guard let position = state.position else { return .none }
                return .send(.delegate(.confirmed(position)))

            case .view(.backTapped):
                guard state.exitStatus != .inProgress else { return .none }
                state.exitStatus = .inProgress
                return .run { send in
                    let result = await signOut()
                    await send(.effect(.signOutFinished(result)))
                }
                .cancellable(id: CancelID.exit, cancelInFlight: true)

            case .effect(.signOutFinished(let result)):
                switch result {
                case .success:
                    state.exitStatus = .idle
                    return .send(.delegate(.exitRequested))

                case .retryableFailure:
                    state.exitStatus = .failed
                    return .none
                }

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case exit
    }

    private let signOut: any SignOutUseCase

}
