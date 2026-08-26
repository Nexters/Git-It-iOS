import ComposableArchitecture
import DomainAuthentication
import DomainMember
import Foundation

// MARK: - OnboardingFeature

/// splash·tutorial·legalAgreement·position·career·completing 단일 phase로 세션 복구, 법적 동의,
/// Apple 로그인과 curation을 관리한다. `activeRequest`를 겸하는 `requestID`로 restore와 sign-in의
/// stale 응답을 무시한다. `phase`와 `authentication`은 [contracts/onboarding-flow.md](../../../../../../specs/016-onboarding-login-tutorial-app-integration/contracts/onboarding-flow.md)의
/// Phase 계약을 따른다.
@Reducer
public struct OnboardingFeature: Sendable {

    // MARK: Lifecycle

    public init(
        restoreSession: any RestoreSessionUseCase,
        signIn: any SignInUseCase,
        signOut: any SignOutUseCase,
        fetchMemberProfile: any FetchMemberProfileUseCase,
        completeCuration: any CompleteCurationUseCase,
        policyConsent: any PolicyConsentUseCase,
    ) {
        self.restoreSession = restoreSession
        self.signIn = signIn
        self.signOut = signOut
        self.fetchMemberProfile = fetchMemberProfile
        self.completeCuration = completeCuration
        self.policyConsent = policyConsent
    }

    // MARK: Public

    public enum Phase: Equatable, Sendable {
        case splash
        case restoreError
        case tutorial(page: Int)
        case legalAgreement
        case position
        case career
        case completing
    }

    public enum AuthenticationStatus: Equatable, Sendable {
        case idle
        case restoring
        case signingIn
        case success
        case cancelled
        case retryableFailure
    }

    public enum ExitStatus: Equatable, Sendable {
        case idle
        case inProgress
        case failed
    }

    /// `PageIndicator`·`ProgressSegments` 같은 UIComponent 표시 값으로 그대로 옮길 수 있는
    /// 0-index 현재/전체 진행도다. Feature가 UI 타입을 직접 참조하지 않고도 화면이 검증 가능한
    /// 값으로 변환할 수 있도록 State가 소유한다.
    public struct PageProgress: Equatable, Sendable {
        public let currentPage: Int
        public let totalPages: Int
    }

    public struct CurationSelection: Equatable, Sendable {
        public init() { }

        public enum Submission: Equatable, Sendable {
            case idle
            case submitting
            case failed
        }

        public var position: MemberPosition?
        public var careerLevel: CareerLevel?
        public var submission: Submission = .idle
    }

    public struct LegalAgreementState: Equatable, Sendable {
        public init() { }

        public enum LinkStatus: Equatable, Sendable {
            case idle
            case opening
            case openFailed
        }

        public var requiredDocuments: [PolicyDocument] = []
        public var storedConsentRecords: [PolicyConsentRecord] = []
        public var selectedDocumentIDs: Set<String> = []
        public var linkStatus: [String: LinkStatus] = [:]

        /// 현재 sheet 선택이 필수 문서를 모두 포함할 때만 계속하기를 허용한다.
        public var canContinue: Bool {
            let requiredIDs = Set(requiredDocuments.filter(\.isRequired).map(\.identifier))
            guard !requiredIDs.isEmpty else { return false }
            return requiredIDs.isSubset(of: selectedDocumentIDs)
        }

        /// 저장 기록이 필수 문서마다 ID·version 모두 일치할 때만 유효하다. sheet의 현재 선택과는
        /// 별개로 로그인 직전 저장 동의 수명을 판정한다.
        public var isStoredConsentValid: Bool {
            PolicyConsentRecord.isConsentValid(storedRecords: storedConsentRecords, for: requiredDocuments)
        }
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        public init(bundleVersion: String) {
            self.bundleVersion = bundleVersion
        }

        public var phase: Phase = .splash
        public var authentication: AuthenticationStatus = .idle
        public var curation = CurationSelection()
        public var positionExitStatus: ExitStatus = .idle
        public var legal = LegalAgreementState()
        public var requestID = 0
        public let bundleVersion: String

        /// tutorial 단계의 현재/전체 페이지. tutorial phase가 아니면 nil이다.
        public var tutorialPageProgress: PageProgress? {
            guard case .tutorial(let page) = phase else { return nil }
            return PageProgress(currentPage: page - 1, totalPages: 3)
        }

        /// curation 단계(position·career)의 진행도. 그 외 phase에서는 nil이다.
        public var curationStepProgress: PageProgress? {
            switch phase {
            case .position:
                PageProgress(currentPage: 0, totalPages: 2)
            case .career:
                PageProgress(currentPage: 1, totalPages: 2)
            default:
                nil
            }
        }

        /// VoiceOver가 즉시 알릴 수 있는 재시도 가능한 오류가 현재 표시돼야 하는지 나타낸다.
        public var isShowingRecoverableError: Bool {
            if case .restoreError = phase { return true }
            return curation.submission == .failed
                || positionExitStatus == .failed
                || authentication == .retryableFailure
                || authentication == .cancelled
        }
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case delegate(Delegate)

        @CasePathable
        public enum View: Sendable, Equatable {
            case task
            case retryRestoreTapped
            case tutorialAppeared
            case tutorialPageChanged(Int)
            case appleSignInTapped
            case legalDocumentToggled(documentID: String)
            case legalDocumentLinkTapped(documentID: String)
            case legalDocumentLinkOpenResult(documentID: String, success: Bool)
            case legalSheetCancelTapped
            case legalContinueTapped
            case positionSelected(MemberPosition)
            case positionBackTapped
            case careerLevelSelected(CareerLevel)
            case careerBackTapped
            case curationSubmitTapped
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case legalDocumentsLoaded(requiredDocuments: [PolicyDocument], storedConsentRecords: [PolicyConsentRecord])
            case restoreSessionFinished(requestID: Int, result: RestoreSessionResult)
            case memberProfileFetchFinished(requestID: Int, result: Result<MemberProfile, MemberError>)
            case localCleanupFinished(requestID: Int, result: SignOutResult)
            case signInFinished(requestID: Int, result: SignInResult)
            case positionExitSignOutFinished(SignOutResult)
            case curationFinished(success: Bool)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case mainShellRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.task):
                guard state.authentication == .idle else { return .none }
                state.authentication = .restoring
                state.requestID += 1
                let requestID = state.requestID
                return .run { send in
                    let result = await restoreSession()
                    await send(.effect(.restoreSessionFinished(requestID: requestID, result: result)))
                }
                .cancellable(id: CancelID.restore, cancelInFlight: true)

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

            case .view(.retryRestoreTapped):
                guard state.authentication != .restoring else { return .none }
                state.phase = .splash
                state.authentication = .restoring
                state.requestID += 1
                let requestID = state.requestID
                return .run { send in
                    let result = await restoreSession()
                    await send(.effect(.restoreSessionFinished(requestID: requestID, result: result)))
                }
                .cancellable(id: CancelID.restore, cancelInFlight: true)

            case .view(.tutorialPageChanged(let page)):
                guard case .tutorial = state.phase else { return .none }
                state.phase = .tutorial(page: page)
                return .none

            case .view(.appleSignInTapped):
                guard state.authentication != .signingIn else { return .none }
                if state.legal.isStoredConsentValid {
                    return startSignIn(&state)
                } else {
                    state.phase = .legalAgreement
                    state.legal.selectedDocumentIDs = []
                    return .none
                }

            case .view(.legalDocumentToggled(let documentID)):
                if state.legal.selectedDocumentIDs.contains(documentID) {
                    state.legal.selectedDocumentIDs.remove(documentID)
                } else {
                    state.legal.selectedDocumentIDs.insert(documentID)
                }
                return .none

            case .view(.legalDocumentLinkTapped(let documentID)):
                state.legal.linkStatus[documentID] = .opening
                return .none

            case .view(.legalDocumentLinkOpenResult(let documentID, let success)):
                state.legal.linkStatus[documentID] = success ? .idle : .openFailed
                return .none

            case .view(.legalSheetCancelTapped):
                state.phase = .tutorial(page: 3)
                state.legal.selectedDocumentIDs = []
                return .none

            case .view(.legalContinueTapped):
                guard state.legal.canContinue, state.authentication != .signingIn else { return .none }
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
                return startSignIn(&state, persistingConsent: records)

            case .view(.positionSelected(let position)):
                guard state.curation.submission != .submitting else { return .none }
                state.curation.position = position
                state.phase = .career
                return .none

            case .view(.positionBackTapped):
                guard
                    state.curation.submission != .submitting,
                    state.positionExitStatus != .inProgress
                else { return .none }
                state.positionExitStatus = .inProgress
                return .run { send in
                    let result = await signOut()
                    await send(.effect(.positionExitSignOutFinished(result)))
                }
                .cancellable(id: CancelID.positionExit, cancelInFlight: true)

            case .view(.careerLevelSelected(let careerLevel)):
                guard state.curation.submission != .submitting else { return .none }
                state.curation.careerLevel = careerLevel
                return .none

            case .view(.careerBackTapped):
                guard state.curation.submission != .submitting else { return .none }
                state.phase = .position
                return .none

            case .view(.curationSubmitTapped):
                guard
                    let position = state.curation.position,
                    let careerLevel = state.curation.careerLevel,
                    state.curation.submission != .submitting
                else { return .none }
                state.curation.submission = .submitting
                return .run { send in
                    do {
                        try await completeCuration(position: position, careerLevel: careerLevel)
                        await send(.effect(.curationFinished(success: true)))
                    } catch {
                        await send(.effect(.curationFinished(success: false)))
                    }
                }
                .cancellable(id: CancelID.curation)

            case .effect(.legalDocumentsLoaded(let documents, let records)):
                state.legal.requiredDocuments = documents
                state.legal.storedConsentRecords = records
                return .none

            case .effect(.restoreSessionFinished(let requestID, let result)):
                guard requestID == state.requestID else { return .none }
                switch result {
                case .authenticated:
                    state.authentication = .success
                    return .run { send in
                        do {
                            let profile = try await fetchMemberProfile()
                            await send(.effect(.memberProfileFetchFinished(requestID: requestID, result: .success(profile))))
                        } catch {
                            let mapped = error as? MemberError ?? .temporarilyUnavailable
                            await send(.effect(.memberProfileFetchFinished(requestID: requestID, result: .failure(mapped))))
                        }
                    }
                    .cancellable(id: CancelID.profile, cancelInFlight: true)

                case .unauthenticated:
                    state.authentication = .idle
                    state.phase = .tutorial(page: 1)
                    return .none

                case .recoverableFailure:
                    state.authentication = .retryableFailure
                    state.phase = .restoreError
                    return .none
                }

            case .effect(.memberProfileFetchFinished(let requestID, let result)):
                guard requestID == state.requestID else { return .none }
                switch result {
                case .success(let profile):
                    if profile.position != nil, profile.careerLevel != nil {
                        state.phase = .completing
                        return .send(.delegate(.mainShellRequested))
                    } else {
                        state.curation = CurationSelection()
                        state.phase = .position
                        return .none
                    }

                case .failure(.memberUnavailable):
                    return .run { send in
                        let result = await signOut()
                        await send(.effect(.localCleanupFinished(requestID: requestID, result: result)))
                    }
                    .cancellable(id: CancelID.cleanup, cancelInFlight: true)

                case .failure:
                    state.authentication = .retryableFailure
                    state.phase = .restoreError
                    return .none
                }

            case .effect(.localCleanupFinished(let requestID, let result)):
                guard requestID == state.requestID else { return .none }
                switch result {
                case .success:
                    state.authentication = .idle
                    state.phase = .tutorial(page: 1)
                    return .none

                case .retryableFailure:
                    state.authentication = .retryableFailure
                    state.phase = .restoreError
                    return .none
                }

            case .effect(.signInFinished(let requestID, let result)):
                guard requestID == state.requestID else { return .none }
                switch result {
                case .success(_, let needsCuration):
                    state.authentication = .success
                    if needsCuration {
                        state.curation = CurationSelection()
                        state.phase = .position
                        return .none
                    } else {
                        state.phase = .completing
                        return .send(.delegate(.mainShellRequested))
                    }

                case .cancelled:
                    state.authentication = .cancelled
                    return .none

                case .retryableFailure:
                    state.authentication = .retryableFailure
                    return .none
                }

            case .effect(.positionExitSignOutFinished(let result)):
                switch result {
                case .success:
                    state.positionExitStatus = .idle
                    state.authentication = .idle
                    state.curation = CurationSelection()
                    state.phase = .tutorial(page: 3)

                case .retryableFailure:
                    state.positionExitStatus = .failed
                }
                return .none

            case .effect(.curationFinished(true)):
                state.curation.submission = .idle
                state.phase = .completing
                return .send(.delegate(.mainShellRequested))

            case .effect(.curationFinished(false)):
                state.curation.submission = .failed
                return .none

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case restore
        case profile
        case cleanup
        case signIn
        case curation
        case positionExit
    }

    private let restoreSession: any RestoreSessionUseCase
    private let signIn: any SignInUseCase
    private let signOut: any SignOutUseCase
    private let fetchMemberProfile: any FetchMemberProfileUseCase
    private let completeCuration: any CompleteCurationUseCase
    private let policyConsent: any PolicyConsentUseCase

    private func startSignIn(
        _ state: inout State,
        persistingConsent records: [PolicyConsentRecord]? = nil,
    ) -> Effect<Action> {
        state.phase = .tutorial(page: 3)
        state.authentication = .signingIn
        state.requestID += 1
        let requestID = state.requestID
        return .run { send in
            if let records {
                try? await policyConsent.saveConsentRecords(records)
            }
            let result = await signIn(.apple)
            await send(.effect(.signInFinished(requestID: requestID, result: result)))
        }
        .cancellable(id: CancelID.signIn, cancelInFlight: true)
    }

}
