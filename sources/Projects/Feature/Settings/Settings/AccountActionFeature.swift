import ComposableArchitecture
import DomainAccount
import DomainUserInfo

@Reducer
public struct AccountActionFeature: Sendable {

    // MARK: Lifecycle

    public init(
        signOut: @escaping @Sendable () async -> SignOutResult,
        withdraw: @escaping @Sendable () async throws -> Void,
    ) {
        self.signOut = signOut
        self.withdraw = withdraw
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(accountAction: AccountAction = .idle) {
            self.accountAction = accountAction
        }

        // MARK: Public

        public enum AccountAction: Equatable, Sendable {
            case idle
            case signingOut
            case confirmingDeletion
            case deletingAccount
            case failed(UserInfoError)

            // MARK: Fileprivate

            fileprivate var canStart: Bool {
                switch self {
                case .idle,
                     .failed:
                    true

                case .signingOut,
                     .confirmingDeletion,
                     .deletingAccount:
                    false
                }
            }
        }

        public var accountAction: AccountAction

    }

    public enum Action: Equatable, Sendable {
        case input(Input)
        case effect(EffectEvent)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum Input: Equatable, Sendable {
            case signOutRequested
            case deletionRequested
            case deletionCancelled
            case deletionConfirmed
        }

        @CasePathable
        public enum EffectEvent: Equatable, Sendable {
            case signOutFinished(SignOutResult)
            case deleteAccountFinished(UserInfoError?)
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            case signedOut
            case accountDeleted
            case deletionConfirmationRequested
            case deletionCancelled
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .input(.signOutRequested):
                guard state.accountAction.canStart else { return .none }
                state.accountAction = .signingOut
                return .run { [signOut] send in
                    let result = await signOut()
                    await send(.effect(.signOutFinished(result)))
                }
                .cancellable(id: CancelID.accountAction)

            case .input(.deletionRequested):
                guard state.accountAction.canStart else { return .none }
                state.accountAction = .confirmingDeletion
                return .send(.delegate(.deletionConfirmationRequested))

            case .input(.deletionCancelled):
                switch state.accountAction {
                case .confirmingDeletion,
                     .failed:
                    state.accountAction = .idle

                case .idle,
                     .signingOut,
                     .deletingAccount:
                    break
                }
                return .send(.delegate(.deletionCancelled))

            case .input(.deletionConfirmed):
                switch state.accountAction {
                case .confirmingDeletion,
                     .failed:
                    break

                case .idle,
                     .signingOut,
                     .deletingAccount:
                    return .none
                }
                state.accountAction = .deletingAccount
                return .run { [withdraw] send in
                    do {
                        try await withdraw()
                        await send(.effect(.deleteAccountFinished(nil)))
                    } catch {
                        let mapped = error as? UserInfoError ?? .temporarilyUnavailable
                        await send(.effect(.deleteAccountFinished(mapped)))
                    }
                }
                .cancellable(id: CancelID.accountAction)

            case .effect(.signOutFinished(.signedOut)):
                state.accountAction = .idle
                return .send(.delegate(.signedOut))

            case .effect(.signOutFinished(.retryableFailure)):
                state.accountAction = .failed(.temporarilyUnavailable)
                return .none

            case .effect(.deleteAccountFinished(nil)):
                state.accountAction = .idle
                return .send(.delegate(.accountDeleted))

            case .effect(.deleteAccountFinished(.some(let error))):
                state.accountAction = .failed(error)
                return .none

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case accountAction
    }

    private let signOut: @Sendable () async -> SignOutResult
    private let withdraw: @Sendable () async throws -> Void

}
