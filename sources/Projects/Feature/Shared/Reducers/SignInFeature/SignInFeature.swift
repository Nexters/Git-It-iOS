import ComposableArchitecture
import DomainAccount
import Foundation

@Reducer
public struct SignInFeature: Sendable {

    // MARK: Lifecycle

    public init(
        signIn: @escaping @Sendable (SignInMethod) async -> SignInResult,
        policyConsentStatus: @escaping @Sendable () async throws -> PolicyConsentStatus,
        consent: @escaping @Sendable ([PolicyDocumentID]) async throws -> Void,
    ) {
        self.signIn = signIn
        self.policyConsentStatus = policyConsentStatus
        self.consent = consent
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init() { }

        // MARK: Public

        public var phase = Phase.idle
        public var legalAgreement = LegalAgreementFeature.State()
        public var requestID = 0

        public var isLegalAgreementPresented: Bool {
            phase == .agreeingToPolicies
        }

        public var isSigningIn: Bool {
            phase == .signingIn
        }

        public var isFailed: Bool {
            phase == .failed
        }

        public var isCancelled: Bool {
            phase == .cancelled
        }

        public var canStart: Bool {
            switch phase {
            case .idle,
                 .cancelled,
                 .failed:
                true

            case .checkingConsent,
                 .agreeingToPolicies,
                 .signingIn:
                false
            }
        }

        public static func ==(
            lhs: Self,
            rhs: Self,
        ) -> Bool {
            lhs.phase == rhs.phase && lhs.legalAgreement == rhs.legalAgreement && lhs.requestID == rhs.requestID
        }

        // MARK: Fileprivate

        fileprivate let instanceID = UUID()

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case input(Input)
        case effect(EffectEvent)
        case delegate(Delegate)
        case legalAgreement(LegalAgreementFeature.Action)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case legalAgreementDismissed
            case legalDocumentSheetDismissed
            case failureDismissed
        }

        @CasePathable
        public enum Input: Sendable, Equatable {
            case prepareConsent
            case start
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case signInFinished(requestID: Int, result: SignInResult)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case signedIn(needsCuration: Bool)
            case consentCancelled
            case signInCancelled
        }
    }

    public var body: some ReducerOf<Self> {
        Scope(
            state: \.legalAgreement,
            action: \.legalAgreement,
        ) {
            LegalAgreementFeature(
                policyConsentStatus: policyConsentStatus,
                consent: consent,
            )
        }
        Reduce { state, action in
            switch action {
            case .input(.prepareConsent):
                guard state.legalAgreement.requiredDocuments.isEmpty else { return .none }
                return .send(.legalAgreement(.input(.load)))

            case .input(.start):
                guard state.canStart else { return .none }
                state.phase = .checkingConsent
                guard !state.legalAgreement.requiredDocuments.isEmpty else {
                    return .send(.legalAgreement(.input(.load)))
                }
                return proceedAfterConsentCheck(&state)

            case .legalAgreement(.effect(.statusLoaded)):
                guard state.phase == .checkingConsent else { return .none }
                return proceedAfterConsentCheck(&state)

            case .legalAgreement(.delegate(.consentCompleted)):
                guard state.phase == .agreeingToPolicies else { return .none }
                return startSignIn(&state)

            case .legalAgreement(.delegate(.cancelled)):
                guard state.phase == .agreeingToPolicies else { return .none }
                state.phase = .idle
                return .send(.delegate(.consentCancelled))

            case .view(.legalAgreementDismissed):
                return .send(.legalAgreement(.view(.cancelTapped)))

            case .view(.legalDocumentSheetDismissed):
                return .send(.legalAgreement(.view(.documentSheetDismissed)))

            case .view(.failureDismissed):
                guard state.phase == .failed else { return .none }
                state.phase = .idle
                return .none

            case .effect(.signInFinished(let requestID, let result)):
                guard requestID == state.requestID, state.phase == .signingIn else { return .none }
                switch result {
                case .signedIn(let account):
                    state.phase = .idle
                    return .send(.delegate(.signedIn(needsCuration: account.needsCuration)))

                case .cancelled:
                    state.phase = .cancelled
                    return .send(.delegate(.signInCancelled))

                case .retryableFailure:
                    state.phase = .failed
                    return .none
                }

            case .legalAgreement,
                 .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case signIn(UUID)
    }

    private let signIn: @Sendable (SignInMethod) async -> SignInResult
    private let policyConsentStatus: @Sendable () async throws -> PolicyConsentStatus
    private let consent: @Sendable ([PolicyDocumentID]) async throws -> Void

    private func proceedAfterConsentCheck(_ state: inout State) -> Effect<Action> {
        guard state.legalAgreement.isStoredConsentValid else {
            state.phase = .agreeingToPolicies
            return .send(.legalAgreement(.input(.prepare)))
        }
        return startSignIn(&state)
    }

    private func startSignIn(_ state: inout State) -> Effect<Action> {
        state.phase = .signingIn
        state.requestID += 1
        let requestID = state.requestID
        return .run { [signIn] send in
            let result = await signIn(.apple)
            await send(.effect(.signInFinished(
                requestID: requestID,
                result: result,
            )))
        }
        .cancellable(
            id: CancelID.signIn(state.instanceID),
            cancelInFlight: true,
        )
    }

}
