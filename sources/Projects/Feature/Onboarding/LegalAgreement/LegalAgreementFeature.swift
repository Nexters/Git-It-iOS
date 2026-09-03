import ComposableArchitecture
import DomainAuthentication
import DomainMember
import Foundation

@Reducer
public struct LegalAgreementFeature: Sendable {

    public init(policyConsent: any PolicyConsentUseCase) {
        self.policyConsent = policyConsent
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        public init() { }

        public var requiredDocuments = [PolicyDocument]()
        public var storedConsentRecords = [PolicyConsentRecord]()
        public var selectedDocumentIDs = Set<String>()
        public var presentedDocumentID: String?

        var pendingNeedsCuration: Bool?

        public var presentedDocument: PolicyDocument? {
            guard let presentedDocumentID else { return nil }
            return requiredDocuments.first { $0.identifier == presentedDocumentID }
        }

        public var isAllSelected: Bool {
            guard !requiredDocuments.isEmpty else { return false }
            return Set(requiredDocuments.map(\.identifier)).isSubset(of: selectedDocumentIDs)
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

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case input(Input)
        case delegate(Delegate)

        @CasePathable
        public enum View: Sendable, Equatable {
            case documentToggled(documentID: String)
            case allDocumentsToggled
            case documentLinkTapped(documentID: String)
            case documentSheetDismissed
            case cancelTapped
            case continueTapped
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case documentsLoaded(requiredDocuments: [PolicyDocument], storedConsentRecords: [PolicyConsentRecord])
        }

        @CasePathable
        public enum Input: Sendable, Equatable {
            case load
            case prepare(needsCuration: Bool)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case consentCompleted(needsCuration: Bool)
            case cancelled
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .input(.load):
                guard state.requiredDocuments.isEmpty else { return .none }
                return .run { send in
                    async let documents = policyConsent.requiredDocuments()
                    async let records = policyConsent.storedConsentRecords()
                    let loadedDocuments = (try? await documents) ?? []
                    let loadedRecords = (try? await records) ?? []
                    await send(
                        .effect(
                            .documentsLoaded(
                                requiredDocuments: loadedDocuments,
                                storedConsentRecords: loadedRecords,
                            )
                        )
                    )
                }

            case .input(.prepare(let needsCuration)):
                state.pendingNeedsCuration = needsCuration
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
                    state.selectedDocumentIDs = Set(state.requiredDocuments.map(\.identifier))
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
                state.pendingNeedsCuration = nil
                return .send(.delegate(.cancelled))

            case .view(.continueTapped):
                guard state.canContinue, let needsCuration = state.pendingNeedsCuration else { return .none }
                let records = state.requiredDocuments
                    .filter { state.selectedDocumentIDs.contains($0.identifier) }
                    .map {
                        PolicyConsentRecord(
                            documentIdentifier: $0.identifier,
                            version: $0.version,
                            acceptedAt: Date(),
                        )
                    }
                state.storedConsentRecords = records
                state.pendingNeedsCuration = nil
                return .run { send in
                    try? await policyConsent.saveConsentRecords(records)
                    await send(.delegate(.consentCompleted(needsCuration: needsCuration)))
                }

            case .effect(.documentsLoaded(let documents, let records)):
                state.requiredDocuments = documents
                state.storedConsentRecords = records
                return .none

            case .delegate:
                return .none
            }
        }
    }

    private let policyConsent: any PolicyConsentUseCase

}
