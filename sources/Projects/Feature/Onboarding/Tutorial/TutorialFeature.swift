import ComposableArchitecture
import DomainUseCaseInterface

@Reducer
public struct TutorialFeature: Sendable {

    // MARK: Lifecycle

    public init(
        signIn: @escaping @Sendable (SignInMethod) async -> SignInResult,
        policyConsentStatus: @escaping @Sendable () async throws -> PolicyConsentStatus,
        consent: @escaping @Sendable ([PolicyDocumentID]) async throws -> Void,
        withdraw: @escaping @Sendable () async throws -> Void,
        deletesCompletedAccountOnSignIn: Bool = false,
    ) {
        self.signIn = signIn
        self.policyConsentStatus = policyConsentStatus
        self.consent = consent
        self.withdraw = withdraw
        self.deletesCompletedAccountOnSignIn = deletesCompletedAccountOnSignIn
    }

    // MARK: Public

    public enum AccountReset: Equatable, Sendable {
        case idle
        case resetting
    }

    public struct PageProgress: Equatable, Sendable {
        public let currentPage: Int
        public let totalPages: Int
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(bundleVersion: String) {
            self.bundleVersion = bundleVersion
        }

        // MARK: Public

        public var page = 1
        public var signIn = SignInFeature.State()
        public var accountReset = AccountReset.idle
        public var hasAttemptedCompletedAccountReset = false
        public let bundleVersion: String

        public var pageProgress: PageProgress {
            PageProgress(
                currentPage: page - 1,
                totalPages: Constant.pageCount,
            )
        }

        public var isSigningIn: Bool {
            signIn.isSigningIn || accountReset == .resetting
        }

        public var isShowingRecoverableError: Bool {
            signIn.isFailed || signIn.isCancelled
        }

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case input(Input)
        case delegate(Delegate)
        case signIn(SignInFeature.Action)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case appeared
            case pageChanged(Int)
            case appleSignInTapped
            case guestAccessTapped
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case accountResetFinished
        }

        @CasePathable
        public enum Input: Sendable, Equatable {
            case returnToLastPage
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case signInSucceeded(needsCuration: Bool)
            case guestAccessRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Scope(
            state: \.signIn,
            action: \.signIn,
        ) {
            SignInFeature(
                signIn: signIn,
                policyConsentStatus: policyConsentStatus,
                consent: consent,
            )
        }
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

            case .input(let action):
                reduce(
                    into: &state,
                    input: action,
                )

            case .signIn(let action):
                reduce(
                    into: &state,
                    signIn: action,
                )

            case .delegate:
                .none
            }
        }
    }

    // MARK: Private

    private enum Constant {
        static let pageCount = 3
    }

    private enum CancelID: Hashable {
        case accountReset
    }

    private let signIn: @Sendable (SignInMethod) async -> SignInResult
    private let policyConsentStatus: @Sendable () async throws -> PolicyConsentStatus
    private let consent: @Sendable ([PolicyDocumentID]) async throws -> Void
    private let withdraw: @Sendable () async throws -> Void
    private let deletesCompletedAccountOnSignIn: Bool

    private func reduce(
        into state: inout State,
        view action: Action.View,
    ) -> Effect<Action> {
        switch action {
        case .appeared:
            return .send(.signIn(.input(.prepareConsent)))

        case .pageChanged(let page):
            state.page = page
            return .none

        case .appleSignInTapped:
            guard !state.isSigningIn, state.signIn.canStart else { return .none }
            return .send(.signIn(.input(.start)))

        case .guestAccessTapped:
            guard !state.isSigningIn else { return .none }
            return .send(.delegate(.guestAccessRequested))
        }
    }

    private func reduce(
        into state: inout State,
        effect event: Action.EffectEvent,
    ) -> Effect<Action> {
        switch event {
        case .accountResetFinished:
            state.accountReset = .idle
            return .send(.signIn(.input(.start)))
        }
    }

    private func reduce(
        into state: inout State,
        input action: Action.Input,
    ) -> Effect<Action> {
        switch action {
        case .returnToLastPage:
            state.page = Constant.pageCount
            return .none
        }
    }

    private func reduce(
        into state: inout State,
        signIn action: SignInFeature.Action,
    ) -> Effect<Action> {
        guard case .delegate(let action) = action else { return .none }
        switch action {
        case .signedIn(let needsCuration):
            guard
                deletesCompletedAccountOnSignIn,
                !needsCuration,
                !state.hasAttemptedCompletedAccountReset
            else {
                return .send(.delegate(.signInSucceeded(needsCuration: needsCuration)))
            }
            state.hasAttemptedCompletedAccountReset = true
            state.accountReset = .resetting
            return .run { [withdraw] send in
                try? await withdraw()
                await send(.effect(.accountResetFinished))
            }
            .cancellable(
                id: CancelID.accountReset,
                cancelInFlight: true,
            )

        case .consentCancelled,
             .signInCancelled:
            return .none
        }
    }

}
