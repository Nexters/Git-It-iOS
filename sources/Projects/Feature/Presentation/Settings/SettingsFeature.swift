import ComposableArchitecture
import DomainAuthentication
import DomainMember
import Foundation

// MARK: - SettingsFeature

/// U06 — 회원 프로필 조회(UC16), position/career 변경(UC17, UC18), 로그아웃(UC14), 회원 탈퇴
/// (UC20)를 소유한다. mutation은 서로 독립된 상태로 분리해 하나의 실패가 다른 mutation을
/// 막지 않는다.
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
        public var profileLoad: ProfileLoad = .idle
        public var positionMutation: MutationStatus = .idle
        public var careerLevelMutation: MutationStatus = .idle
        public var accountAction: AccountAction = .idle
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
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case delegate(Delegate)

        @CasePathable
        public enum View: Sendable, Equatable {
            case task
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
            case signOutFinished(AuthenticationOutcome)
            case deleteAccountFinished(MemberError?)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
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
                guard state.accountAction == .idle else { return .none }
                state.accountAction = .signingOut
                return .run { send in
                    let outcome = await signOut()
                    await send(.effect(.signOutFinished(outcome)))
                }
                .cancellable(id: CancelID.accountAction)

            case .view(.deleteAccountTapped):
                guard state.accountAction == .idle else { return .none }
                state.accountAction = .confirmingDeletion
                return .none

            case .view(.deleteAccountCancelled):
                if state.accountAction == .confirmingDeletion {
                    state.accountAction = .idle
                }
                return .none

            case .view(.deleteAccountConfirmed):
                guard state.accountAction == .confirmingDeletion else { return .none }
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
                if state.profile != nil {
                    state.profile?.replacePosition(position)
                }
                return .none

            case .effect(.positionUpdateFinished(_, .some(let error))):
                state.positionMutation = .failed(error)
                return .none

            case .effect(.careerLevelUpdateFinished(let careerLevel, nil)):
                state.careerLevelMutation = .idle
                if state.profile != nil {
                    state.profile?.replaceCareerLevel(careerLevel)
                }
                return .none

            case .effect(.careerLevelUpdateFinished(_, .some(let error))):
                state.careerLevelMutation = .failed(error)
                return .none

            case .effect(.signOutFinished(let outcome)):
                switch outcome {
                case .unauthenticated:
                    state.accountAction = .idle
                    return .send(.delegate(.signedOut))

                case .authenticated, .recoverableFailure:
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

    private let signOut: any SignOutUseCase
    private let fetchMemberProfile: any FetchMemberProfileUseCase
    private let updateMemberPosition: any UpdateMemberPositionUseCase
    private let updateMemberCareerLevel: any UpdateMemberCareerLevelUseCase
    private let deleteMemberAccount: any DeleteMemberAccountUseCase

}

extension MemberProfile {
    fileprivate mutating func replacePosition(_ position: MemberPosition) {
        self = MemberProfile(
            name: name,
            email: email,
            position: position,
            careerLevel: careerLevel,
            statistics: statistics,
        )
    }

    fileprivate mutating func replaceCareerLevel(_ careerLevel: CareerLevel) {
        self = MemberProfile(
            name: name,
            email: email,
            position: position,
            careerLevel: careerLevel,
            statistics: statistics,
        )
    }
}
