import ComposableArchitecture
import DomainAccount
import DomainAppSetting
import DomainUserInfo
import Foundation

// MARK: - SettingsFeature

@Reducer
public struct SettingsFeature: Sendable {

    // MARK: Lifecycle

    public init(
        signOut: @escaping @Sendable () async -> SignOutResult,
        profile: @escaping @Sendable () async throws -> UserProfile,
        updatePosition: @escaping @Sendable (MemberPosition) async throws -> Void,
        updateCareerLevel: @escaping @Sendable (CareerLevel) async throws -> Void,
        withdraw: @escaping @Sendable () async throws -> Void,
        notificationAuthorization: @escaping @Sendable () async -> NotificationAuthorizationStatus,
        requestNotificationAuthorization: @escaping @Sendable () async -> NotificationAuthorizationStatus,
        openNotificationSettings: @escaping @MainActor @Sendable () async -> Void,
    ) {
        self.signOut = signOut
        self.profile = profile
        self.updatePosition = updatePosition
        self.updateCareerLevel = updateCareerLevel
        self.withdraw = withdraw
        self.notificationAuthorization = notificationAuthorization
        self.requestNotificationAuthorization = requestNotificationAuthorization
        self.openNotificationSettings = openNotificationSettings
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {
        public init() { }

        public var userProfile = UserProfileLoadFeature.State()
        public var positionMutation = MutationStatus.idle
        public var careerLevelMutation = MutationStatus.idle
        public var accountAction = AccountAction.idle
        public var notificationStatus = NotificationStatus.idle

        public var profile: UserProfile? {
            userProfile.profile
        }
    }

    public enum MutationStatus: Equatable, Sendable {
        case idle
        case committing
        case failed(UserInfoError)
    }

    public enum AccountAction: Equatable, Sendable {
        case idle
        case signingOut
        case confirmingDeletion
        case deletingAccount
        case failed(UserInfoError)

        // MARK: Fileprivate

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

    public enum NotificationStatus: Equatable, Sendable {
        case idle
        case allowed
        case denied
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case input(Input)
        case effect(EffectEvent)
        case delegate(Delegate)
        case userProfile(UserProfileLoadFeature.Action)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case task
            case applicationBecameActive
            case backTapped
            case positionRowTapped
            case careerLevelRowTapped
            case notificationRowTapped
            case termsTapped
            case positionSelected(MemberPosition)
            case careerLevelSelected(CareerLevel)
            case signOutTapped
            case deleteAccountTapped
            case deleteAccountCancelled
            case deleteAccountConfirmed
        }

        @CasePathable
        public enum Input: Sendable, Equatable {
            case profileProvided(UserProfile)
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case notificationAuthorizationChecked(NotificationAuthorizationStatus)
            case positionUpdateFinished(MemberPosition, UserInfoError?)
            case careerLevelUpdateFinished(CareerLevel, UserInfoError?)
            case signOutFinished(SignOutResult)
            case deleteAccountFinished(UserInfoError?)
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
        Scope(state: \.userProfile, action: \.userProfile) {
            UserProfileLoadFeature(profile: profile)
        }
        Reduce { state, action in
            switch action {
            case .view(.task):
                let profileInput: UserProfileLoadFeature.Action.Input =
                    state.profile == nil ? .load : .reload
                return .merge(
                    .send(.userProfile(.input(profileInput))),
                    checkNotificationAuthorization(),
                )

            case .input(.profileProvided(let profile)):
                return .send(.userProfile(.input(.replace(profile))))

            case .view(.applicationBecameActive):
                return checkNotificationAuthorization()

            case .view(.backTapped):
                return .send(.delegate(.backRequested))

            case .view(.positionRowTapped):
                return .send(.delegate(.positionSelectionRequested))

            case .view(.careerLevelRowTapped):
                return .send(.delegate(.careerLevelSelectionRequested))

            case .view(.notificationRowTapped):
                return .run { [notificationAuthorization, requestNotificationAuthorization, openNotificationSettings] send in
                    switch await notificationAuthorization() {
                    case .notDetermined:
                        let status = await requestNotificationAuthorization()
                        await send(.effect(.notificationAuthorizationChecked(status)))

                    case .authorized,
                         .denied:
                        await openNotificationSettings()
                    }
                }

            case .view(.termsTapped):
                guard let url = Constant.servicePolicyURL else { return .none }
                return .send(.delegate(.externalURLRequested(url)))

            case .view(.positionSelected(let position)):
                guard state.positionMutation != .committing else { return .none }
                state.positionMutation = .committing
                return .run { send in
                    do {
                        try await updatePosition(position)
                        await send(.effect(.positionUpdateFinished(position, nil)))
                    } catch {
                        let mapped = error as? UserInfoError ?? .temporarilyUnavailable
                        await send(.effect(.positionUpdateFinished(position, mapped)))
                    }
                }
                .cancellable(id: CancelID.positionMutation)

            case .view(.careerLevelSelected(let careerLevel)):
                guard state.careerLevelMutation != .committing else { return .none }
                state.careerLevelMutation = .committing
                return .run { send in
                    do {
                        try await updateCareerLevel(careerLevel)
                        await send(.effect(.careerLevelUpdateFinished(careerLevel, nil)))
                    } catch {
                        let mapped = error as? UserInfoError ?? .temporarilyUnavailable
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
                        try await withdraw()
                        await send(.effect(.deleteAccountFinished(nil)))
                    } catch {
                        let mapped = error as? UserInfoError ?? .temporarilyUnavailable
                        await send(.effect(.deleteAccountFinished(mapped)))
                    }
                }
                .cancellable(id: CancelID.accountAction)

            case .effect(.notificationAuthorizationChecked(let status)):
                state.notificationStatus = status == .authorized ? .allowed : .denied
                return .none

            case .effect(.positionUpdateFinished(let position, nil)):
                state.positionMutation = .idle
                guard let profile = state.profile?.replacing(position: position) else { return .none }
                return .send(.userProfile(.input(.replace(profile))))

            case .effect(.positionUpdateFinished(_, .some(let error))):
                state.positionMutation = .failed(error)
                return .none

            case .effect(.careerLevelUpdateFinished(let careerLevel, nil)):
                state.careerLevelMutation = .idle
                guard let profile = state.profile?.replacing(careerLevel: careerLevel) else { return .none }
                return .send(.userProfile(.input(.replace(profile))))

            case .effect(.careerLevelUpdateFinished(_, .some(let error))):
                state.careerLevelMutation = .failed(error)
                return .none

            case .effect(.signOutFinished(let result)):
                switch result {
                case .signedOut:
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

            case .userProfile,
                 .delegate:
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
        static let servicePolicyURL = URL(
            string: "https://git-it-service-policy.notion.site/Git-it-3bb7221e5fe78005bcd9fab953906df1"
        )
    }

    private let signOut: @Sendable () async -> SignOutResult
    private let profile: @Sendable () async throws -> UserProfile
    private let updatePosition: @Sendable (MemberPosition) async throws -> Void
    private let updateCareerLevel: @Sendable (CareerLevel) async throws -> Void
    private let withdraw: @Sendable () async throws -> Void
    private let notificationAuthorization: @Sendable () async -> NotificationAuthorizationStatus
    private let requestNotificationAuthorization: @Sendable () async -> NotificationAuthorizationStatus
    private let openNotificationSettings: @MainActor @Sendable () async -> Void

    private func checkNotificationAuthorization() -> Effect<Action> {
        .run { [notificationAuthorization] send in
            await send(.effect(.notificationAuthorizationChecked(notificationAuthorization())))
        }
    }

}

extension UserProfile {
    fileprivate func replacing(
        position: MemberPosition? = nil,
        careerLevel: CareerLevel? = nil,
    ) -> UserProfile {
        guard
            let position = position ?? curation?.position,
            let careerLevel = careerLevel ?? curation?.careerLevel
        else {
            return self
        }
        return UserProfile(
            detail: detail,
            curation: Curation(position: position, careerLevel: careerLevel),
        )
    }
}
