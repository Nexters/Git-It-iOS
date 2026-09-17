import ComposableArchitecture
import DomainAccount

@Reducer
public struct TutorialFeature: Sendable {

    // MARK: Lifecycle

    public init(
        signIn: @escaping @Sendable (SignInMethod) async -> SignInResult,
        withdraw: @escaping @Sendable () async throws -> Void,
        deletesCompletedAccountOnSignIn: Bool = false,
    ) {
        self.signIn = signIn
        self.withdraw = withdraw
        self.deletesCompletedAccountOnSignIn = deletesCompletedAccountOnSignIn
    }

    // MARK: Public

    public enum AuthenticationStatus: Equatable, Sendable {
        case idle
        case signingIn
        case cancelled
        case retryableFailure
    }

    public struct PageProgress: Equatable, Sendable {
        public let currentPage: Int
        public let totalPages: Int
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        public init(bundleVersion: String) {
            self.bundleVersion = bundleVersion
        }

        public var page = 1
        public var authentication = AuthenticationStatus.idle
        public var requestID = 0
        public var hasAttemptedCompletedAccountReset = false
        public let bundleVersion: String

        public var pageProgress: PageProgress {
            PageProgress(currentPage: page - 1, totalPages: Constant.pageCount)
        }

        public var isShowingRecoverableError: Bool {
            authentication == .retryableFailure || authentication == .cancelled
        }

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case input(Input)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case appeared
            case pageChanged(Int)
            case appleSignInTapped
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case signInFinished(requestID: Int, result: SignInResult)
        }

        @CasePathable
        public enum Input: Sendable, Equatable {
            case returnToLastPage
            case startSignIn
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case appeared
            case signInRequested
            case signInSucceeded(needsCuration: Bool)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.appeared):
                return .send(.delegate(.appeared))

            case .view(.pageChanged(let page)):
                state.page = page
                return .none

            case .view(.appleSignInTapped):
                guard state.authentication != .signingIn else { return .none }
                return .send(.delegate(.signInRequested))

            case .input(.startSignIn):
                guard state.authentication != .signingIn else { return .none }
                return startSignIn(&state)

            case .input(.returnToLastPage):
                state.page = Constant.pageCount
                return .none

            case .effect(.signInFinished(let requestID, let result)):
                guard requestID == state.requestID else { return .none }
                switch result {
                case .signedIn(let account):
                    let needsCuration = account.needsCuration
                    if deletesCompletedAccountOnSignIn, !needsCuration, !state.hasAttemptedCompletedAccountReset {
                        state.hasAttemptedCompletedAccountReset = true
                        state.requestID += 1
                        let retryRequestID = state.requestID
                        return .run { send in
                            try? await withdraw()
                            let result = await signIn(.apple)
                            await send(.effect(.signInFinished(requestID: retryRequestID, result: result)))
                        }
                        .cancellable(id: CancelID.signIn, cancelInFlight: true)
                    }
                    state.authentication = .idle
                    return .send(.delegate(.signInSucceeded(needsCuration: needsCuration)))

                case .cancelled:
                    state.authentication = .cancelled
                    return .none

                case .retryableFailure:
                    state.authentication = .retryableFailure
                    return .none
                }

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum Constant {
        static let pageCount = 3
    }

    private enum CancelID: Hashable {
        case signIn
    }

    private let signIn: @Sendable (SignInMethod) async -> SignInResult
    private let withdraw: @Sendable () async throws -> Void
    private let deletesCompletedAccountOnSignIn: Bool

    private func startSignIn(_ state: inout State) -> Effect<Action> {
        state.page = Constant.pageCount
        state.authentication = .signingIn
        state.requestID += 1
        let requestID = state.requestID
        return .run { send in
            let result = await signIn(.apple)
            await send(.effect(.signInFinished(requestID: requestID, result: result)))
        }
        .cancellable(id: CancelID.signIn, cancelInFlight: true)
    }

}
