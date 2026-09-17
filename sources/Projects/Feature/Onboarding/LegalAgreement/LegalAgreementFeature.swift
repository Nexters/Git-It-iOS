import ComposableArchitecture
import DomainAccount
import Foundation

@Reducer
public struct LegalAgreementFeature: Sendable {

    // MARK: Lifecycle

    public init(
        policyConsentStatus: @escaping @Sendable () async throws -> PolicyConsentStatus,
        consent: @escaping @Sendable ([PolicyDocumentID]) async throws -> Void,
    ) {
        self.policyConsentStatus = policyConsentStatus
        self.consent = consent
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init() { }

        // MARK: Public

        public var requiredDocuments = [PolicyDocument]()
        public var isStoredConsentValid = false
        public var selectedDocumentIDs = Set<PolicyDocumentID>()
        public var presentedDocumentID: PolicyDocumentID?

        public var presentedDocument: PolicyDocument? {
            guard let presentedDocumentID else { return nil }
            return requiredDocuments.first { $0.id == presentedDocumentID }
        }

        public var isAllSelected: Bool {
            guard !requiredDocuments.isEmpty else { return false }
            return Set(requiredDocuments.map(\.id)).isSubset(of: selectedDocumentIDs)
        }

        public var canContinue: Bool {
            let requiredIDs = Set(requiredDocuments.filter(\.isRequired).map(\.id))
            guard !requiredIDs.isEmpty else { return false }
            return requiredIDs.isSubset(of: selectedDocumentIDs)
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
            case documentToggled(documentID: PolicyDocumentID)
            case allDocumentsToggled
            case documentLinkTapped(documentID: PolicyDocumentID)
            case documentSheetDismissed
            case cancelTapped
            case continueTapped
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case statusLoaded(requiredDocuments: [PolicyDocument], isStoredConsentValid: Bool)
        }

        @CasePathable
        public enum Input: Sendable, Equatable {
            case load
            case prepare
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case consentCompleted
            case cancelled
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .input(.load):
                guard state.requiredDocuments.isEmpty else { return .none }
                return .run { send in
                    let status = try? await policyConsentStatus()
                    await send(
                        .effect(
                            .statusLoaded(
                                requiredDocuments: status?.documents ?? [],
                                isStoredConsentValid: status?.isSatisfied ?? false,
                            )
                        )
                    )
                }

            case .input(.prepare):
                state.selectedDocumentIDs = []
                return .none

            case .view(.documentToggled(let documentID)):
                if state.selectedDocumentIDs.contains(documentID) {
                    state.selectedDocumentIDs.remove(documentID)
                } else {
                    state.selectedDocumentIDs.insert(documentID)
                }
                return .none

            case .view(.allDocumentsToggled):
                if state.isAllSelected {
                    state.selectedDocumentIDs.removeAll()
                } else {
                    state.selectedDocumentIDs = Set(state.requiredDocuments.map(\.id))
                }
                return .none

            case .view(.documentLinkTapped(let documentID)):
                state.presentedDocumentID = documentID
                return .none

            case .view(.documentSheetDismissed):
                state.presentedDocumentID = nil
                return .none

            case .view(.cancelTapped):
                state.selectedDocumentIDs = []
                state.presentedDocumentID = nil
                return .send(.delegate(.cancelled))

            case .view(.continueTapped):
                guard state.canContinue else { return .none }
                let documentIDs = state.requiredDocuments
                    .map(\.id)
                    .filter { state.selectedDocumentIDs.contains($0) }
                state.isStoredConsentValid = true
                return .run { send in
                    try? await consent(documentIDs)
                    await send(.delegate(.consentCompleted))
                }

            case .effect(.statusLoaded(let documents, let isStoredConsentValid)):
                state.requiredDocuments = documents
                state.isStoredConsentValid = isStoredConsentValid
                return .none

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private let policyConsentStatus: @Sendable () async throws -> PolicyConsentStatus
    private let consent: @Sendable ([PolicyDocumentID]) async throws -> Void

}
