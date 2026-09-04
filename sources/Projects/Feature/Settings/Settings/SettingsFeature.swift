import ComposableArchitecture
import DomainAuthentication
import DomainMember
import Foundation

// MARK: - SettingsFeature

@Reducer
public struct SettingsFeature: Sendable {

    // MARK: Lifecycle

    public init(
        signOut: any SignOutUseCase,
        fetchMemberProfile: any FetchMemberProfileUseCase,
        updateMemberPosition: any UpdateMemberPositionUseCase,
        updateMemberCareerLevel: any UpdateMemberCareerLevelUseCase,
        deleteMemberAccount: any DeleteMemberAccountUseCase,
    ) {
        self.signOut = signOut
        self.fetchMemberProfile = fetchMemberProfile
        self.updateMemberPosition = updateMemberPosition
        self.updateMemberCareerLevel = updateMemberCareerLevel
        self.deleteMemberAccount = deleteMemberAccount
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {
        public init() { }

        public var profile: MemberProfile?
        public var profileLoad = ProfileLoad.idle
        public var positionMutation = MutationStatus.idle
        public var careerLevelMutation = MutationStatus.idle
        public var accountAction = AccountAction.idle
    }

    public enum ProfileLoad: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failed(MemberError)
    }

    public enum MutationStatus: Equatable, Sendable {
        case idle
        case committing
        case failed(MemberError)
    }

    public enum AccountAction: Equatable, Sendable {
        case idle
        case signingOut
        case confirmingDeletion
        case deletingAccount
        case failed(MemberError)

        // MARK: Fileprivate

        /// 대기 중이거나 이전 요청이 실패한 뒤에는 새 계정 작업을 다시 시작할 수 있다.
        fileprivate var canStartAccountAction: Bool {
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

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case task
            case backTapped
            case positionRowTapped
            case careerLevelRowTapped
            case termsTapped
            case positionSelected(MemberPosition)
            case careerLevelSelected(CareerLevel)
            case signOutTapped
            case deleteAccountTapped
            case deleteAccountCancelled
            case deleteAccountConfirmed
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case profileLoadFinished(Result<MemberProfile, MemberError>)
            case positionUpdateFinished(MemberPosition, MemberError?)
            case careerLevelUpdateFinished(CareerLevel, MemberError?)
            case signOutFinished(SignOutResult)
            case deleteAccountFinished(MemberError?)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case backRequested
            case positionSelectionRequested
            case careerLevelSelectionRequested
            case accountDeletionRequested
            case accountDeletionCancelled
            case externalURLRequested(URL)
            case signedOut
            case accountDeleted
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.task):
                state.profileLoad = .loading
                return .run { send in
                    do {
                        let profile = try await fetchMemberProfile()
                        await send(.effect(.profileLoadFinished(.success(profile))))
                    } catch {
                        let mapped = error as? MemberError ?? .temporarilyUnavailable
                        await send(.effect(.profileLoadFinished(.failure(mapped))))
                    }
                }

            case .view(.backTapped):
                return .send(.delegate(.backRequested))

            case .view(.positionRowTapped):
                return .send(.delegate(.positionSelectionRequested))

            case .view(.careerLevelRowTapped):
                return .send(.delegate(.careerLevelSelectionRequested))

            case .view(.termsTapped):
                guard let url = Constant.servicePolicyURL else { return .none }
                return .send(.delegate(.externalURLRequested(url)))

            case .view(.positionSelected(let position)):
                guard state.positionMutation != .committing else { return .none }
                state.positionMutation = .committing
                return .run { send in
                    do {
                        try await updateMemberPosition(position)
                        await send(.effect(.positionUpdateFinished(position, nil)))
                    } catch {
                        let mapped = error as? MemberError ?? .temporarilyUnavailable
                        await send(.effect(.positionUpdateFinished(position, mapped)))
                    }
                }
                .cancellable(id: CancelID.positionMutation)

            case .view(.careerLevelSelected(let careerLevel)):
                guard state.careerLevelMutation != .committing else { return .none }
                state.careerLevelMutation = .committing
                return .run { send in
                    do {
                        try await updateMemberCareerLevel(careerLevel)
                        await send(.effect(.careerLevelUpdateFinished(careerLevel, nil)))
                    } catch {
                        let mapped = error as? MemberError ?? .temporarilyUnavailable
                        await send(.effect(.careerLevelUpdateFinished(careerLevel, mapped)))
                    }
                }
                .cancellable(id: CancelID.careerLevelMutation)

            case .view(.signOutTapped):
                guard state.accountAction.canStartAccountAction else { return .none }
                state.accountAction = .signingOut
                return .run { send in
                    let result = await signOut()
                    await send(.effect(.signOutFinished(result)))
                }
                .cancellable(id: CancelID.accountAction)

            case .view(.deleteAccountTapped):
                guard state.accountAction.canStartAccountAction else { return .none }
                state.accountAction = .confirmingDeletion
                return .send(.delegate(.accountDeletionRequested))

            case .view(.deleteAccountCancelled):
                switch state.accountAction {
                case .confirmingDeletion,
                     .failed:
                    state.accountAction = .idle

                case .idle,
                     .signingOut,
                     .deletingAccount:
                    break
                }
                return .send(.delegate(.accountDeletionCancelled))

            case .view(.deleteAccountConfirmed):
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
                return .run { send in
                    do {
                        try await deleteMemberAccount()
                        await send(.effect(.deleteAccountFinished(nil)))
                    } catch {
                        let mapped = error as? MemberError ?? .temporarilyUnavailable
                        await send(.effect(.deleteAccountFinished(mapped)))
                    }
                }
                .cancellable(id: CancelID.accountAction)

            case .effect(.profileLoadFinished(let result)):
                switch result {
                case .success(let profile):
                    state.profile = profile
                    state.profileLoad = .loaded

                case .failure(let error):
                    state.profileLoad = .failed(error)
                }
                return .none

            case .effect(.positionUpdateFinished(let position, nil)):
                state.positionMutation = .idle
                state.profile = state.profile?.replacing(position: position)
                return .none

            case .effect(.positionUpdateFinished(_, .some(let error))):
                state.positionMutation = .failed(error)
                return .none

            case .effect(.careerLevelUpdateFinished(let careerLevel, nil)):
                state.careerLevelMutation = .idle
                state.profile = state.profile?.replacing(careerLevel: careerLevel)
                return .none

            case .effect(.careerLevelUpdateFinished(_, .some(let error))):
                state.careerLevelMutation = .failed(error)
                return .none

            case .effect(.signOutFinished(let result)):
                switch result {
                case .success:
                    state.accountAction = .idle
                    return .send(.delegate(.signedOut))

                case .retryableFailure:
                    state.accountAction = .failed(.temporarilyUnavailable)
                    return .none
                }

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
        case positionMutation
        case careerLevelMutation
        case accountAction
    }

    private enum Constant {
        /// Figma `1465:19712` 주석: "클릭 시 브라우저를 열고 서비스 정책 노션을 호출함".
        static let servicePolicyURL = URL(
            string: "https://git-it-service-policy.notion.site/Git-it-3bb7221e5fe78005bcd9fab953906df1"
        )
    }

    private let signOut: any SignOutUseCase
    private let fetchMemberProfile: any FetchMemberProfileUseCase
    private let updateMemberPosition: any UpdateMemberPositionUseCase
    private let updateMemberCareerLevel: any UpdateMemberCareerLevelUseCase
    private let deleteMemberAccount: any DeleteMemberAccountUseCase

}

extension MemberProfile {
    /// 저장에 성공한 직군·연차만 갈아 끼운 프로필을 만든다. 생략한 항목은 기존 값을 유지한다.
    fileprivate func replacing(
        position: MemberPosition? = nil,
        careerLevel: CareerLevel? = nil,
    ) -> MemberProfile {
        MemberProfile(
            name: name,
            email: email,
            position: position ?? self.position,
            careerLevel: careerLevel ?? self.careerLevel,
            statistics: statistics,
        )
    }
}
