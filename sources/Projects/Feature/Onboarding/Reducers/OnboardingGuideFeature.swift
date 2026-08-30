import ComposableArchitecture
import DomainAuthentication
import DomainMember
import Foundation

// MARK: - OnboardingGuideFeature

@Reducer
public struct OnboardingGuideFeature: Sendable {

    // MARK: Lifecycle

    public init(
        signIn: any SignInUseCase,
        policyConsent: any PolicyConsentUseCase,
        deleteMemberAccount: any DeleteMemberAccountUseCase,
        deletesCompletedAccountOnSignIn: Bool = false,
    ) {
        self.signIn = signIn
        self.policyConsent = policyConsent
        self.deleteMemberAccount = deleteMemberAccount
        self.deletesCompletedAccountOnSignIn = deletesCompletedAccountOnSignIn
    }

    // MARK: Public

    public enum Screen: Equatable, Sendable {
        case tutorial(page: Int)
        case legalAgreement
    }

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

    public struct LegalAgreementState: Equatable, Sendable {

        // MARK: Lifecycle

        public init() { }

        // MARK: Public

        public var requiredDocuments = [PolicyDocument]()
        public var storedConsentRecords = [PolicyConsentRecord]()
        public var selectedDocumentIDs = Set<String>()
        public var presentedDocumentID: String?

        public var presentedDocument: PolicyDocument? {
            guard let presentedDocumentID else { return nil }
            return requiredDocuments.first { $0.identifier == presentedDocumentID }
        }

        public var isAllSelected: Bool {
            guard !requiredDocuments.isEmpty else { return false }
            return Set(requiredDocuments.map(\.identifier))
                .isSubset(of: selectedDocumentIDs)
        }

        public var canContinue: Bool {
            let requiredIDs = Set(requiredDocuments.filter(\.isRequired).map(\.identifier))
            guard !requiredIDs.isEmpty else { return false }
            return requiredIDs.isSubset(of: selectedDocumentIDs)
        }

        public var isStoredConsentValid: Bool {
            PolicyConsentRecord.isConsentValid(storedRecords: storedConsentRecords, for: requiredDocuments)
        }

    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(bundleVersion: String) {
            self.bundleVersion = bundleVersion
        }

        // MARK: Public

        public var screen = Screen.tutorial(page: 1)
        public var legal = LegalAgreementState()
        public var authentication = AuthenticationStatus.idle
        public var requestID = 0
        public var hasAttemptedCompletedAccountReset = false
        public var pendingSignInNeedsCuration: Bool?
        public let bundleVersion: String

        public var tutorialPageProgress: PageProgress? {
            guard case .tutorial(let page) = screen else { return nil }
            return PageProgress(currentPage: page - 1, totalPages: 3)
        }

        public var isShowingRecoverableError: Bool {
            authentication == .retryableFailure || authentication == .cancelled
        }

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case tutorialAppeared
            case tutorialPageChanged(Int)
            case appleSignInTapped
            case legalDocumentToggled(documentID: String)
            case legalAllDocumentsToggled
            case legalDocumentLinkTapped(documentID: String)
            case legalDocumentSheetDismissed
            case legalSheetCancelTapped
            case legalContinueTapped
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case legalDocumentsLoaded(requiredDocuments: [PolicyDocument], storedConsentRecords: [PolicyConsentRecord])
            case signInFinished(requestID: Int, result: SignInResult)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case signInSucceeded(needsCuration: Bool)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.tutorialAppeared):
                guard state.legal.requiredDocuments.isEmpty else { return .none }
                return .run { send in
                    async let documents = policyConsent.requiredDocuments()
                    async let records = policyConsent.storedConsentRecords()
                    let loadedDocuments = (try? await documents) ?? []
                    let loadedRecords = (try? await records) ?? []
                    await send(
                        .effect(
                            .legalDocumentsLoaded(
                                requiredDocuments: loadedDocuments,
                                storedConsentRecords: loadedRecords,
                            )
                        )
                    )
                }

            case .view(.tutorialPageChanged(let page)):
                guard case .tutorial = state.screen else { return .none }
                state.screen = .tutorial(page: page)
                return .none

            case .view(.appleSignInTapped):
                guard state.authentication != .signingIn else { return .none }
                return startSignIn(&state)

            case .view(.legalDocumentToggled(let documentID)):
                if state.legal.selectedDocumentIDs.contains(documentID) {
                    state.legal.selectedDocumentIDs.remove(documentID)
                } else {
                    state.legal.selectedDocumentIDs.insert(documentID)
                }
                return .none

            case .view(.legalAllDocumentsToggled):
                if state.legal.isAllSelected {
                    state.legal.selectedDocumentIDs.removeAll()
                } else {
                    state.legal.selectedDocumentIDs = Set(state.legal.requiredDocuments.map(\.identifier))
                }
                return .none

            case .view(.legalDocumentLinkTapped(let documentID)):
                state.legal.presentedDocumentID = documentID
                return .none

            case .view(.legalDocumentSheetDismissed):
                state.legal.presentedDocumentID = nil
                return .none

            case .view(.legalSheetCancelTapped):
                state.screen = .tutorial(page: 3)
                state.legal.selectedDocumentIDs = []
                state.legal.presentedDocumentID = nil
                state.pendingSignInNeedsCuration = nil
                return .none

            case .view(.legalContinueTapped):
                guard state.legal.canContinue, let needsCuration = state.pendingSignInNeedsCuration else { return .none }
                let records = state.legal.requiredDocuments
                    .filter { state.legal.selectedDocumentIDs.contains($0.identifier) }
                    .map {
                        PolicyConsentRecord(
                            documentIdentifier: $0.identifier,
                            version: $0.version,
                            acceptedAt: Date(),
                        )
                    }
                state.legal.storedConsentRecords = records
                state.pendingSignInNeedsCuration = nil
                state.screen = .tutorial(page: 3)
                return .run { send in
                    try? await policyConsent.saveConsentRecords(records)
                    await send(.delegate(.signInSucceeded(needsCuration: needsCuration)))
                }

            case .effect(.legalDocumentsLoaded(let documents, let records)):
                state.legal.requiredDocuments = documents
                state.legal.storedConsentRecords = records
                return .none

            case .effect(.signInFinished(let requestID, let result)):
                guard requestID == state.requestID else { return .none }
                switch result {
                case .success(_, let needsCuration):
                    if deletesCompletedAccountOnSignIn, !needsCuration, !state.hasAttemptedCompletedAccountReset {
                        state.hasAttemptedCompletedAccountReset = true
                        state.requestID += 1
                        let retryRequestID = state.requestID
                        return .run { send in
                            _ = try? await deleteMemberAccount()
                            let result = await signIn(.apple)
                            await send(.effect(.signInFinished(requestID: retryRequestID, result: result)))
                        }
                        .cancellable(id: CancelID.signIn, cancelInFlight: true)
                    }
                    state.authentication = .idle
                    if state.legal.isStoredConsentValid {
                        return .send(.delegate(.signInSucceeded(needsCuration: needsCuration)))
                    } else {
                        state.pendingSignInNeedsCuration = needsCuration
                        state.screen = .legalAgreement
                        state.legal.selectedDocumentIDs = []
                        return .none
                    }

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

    private enum CancelID: Hashable {
        case signIn
    }

    private let signIn: any SignInUseCase
    private let policyConsent: any PolicyConsentUseCase
    private let deleteMemberAccount: any DeleteMemberAccountUseCase
    private let deletesCompletedAccountOnSignIn: Bool

    private func startSignIn(_ state: inout State) -> Effect<Action> {
        state.screen = .tutorial(page: 3)
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
