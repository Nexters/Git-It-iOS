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
        public var curationUpdate = CurationUpdateFeature.State()
        public var accountAction = AccountActionFeature.State()
        public var notificationPermission = NotificationPermissionFeature.State()

        public var profile: UserProfile? {
            userProfile.profile
        }
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case input(Input)
        case delegate(Delegate)
        case userProfile(UserProfileLoadFeature.Action)
        case curationUpdate(CurationUpdateFeature.Action)
        case accountAction(AccountActionFeature.Action)
        case notificationPermission(NotificationPermissionFeature.Action)

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
        Scope(state: \.curationUpdate, action: \.curationUpdate) {
            CurationUpdateFeature(updatePosition: updatePosition, updateCareerLevel: updateCareerLevel)
        }
        Scope(state: \.accountAction, action: \.accountAction) {
            AccountActionFeature(signOut: signOut, withdraw: withdraw)
        }
        Scope(state: \.notificationPermission, action: \.notificationPermission) {
            NotificationPermissionFeature(
                notificationAuthorization: notificationAuthorization,
                requestNotificationAuthorization: requestNotificationAuthorization,
                openNotificationSettings: openNotificationSettings,
            )
        }
        Reduce { state, action in
            switch action {
            case .view(.task):
                let profileInput: UserProfileLoadFeature.Action.Input =
                    state.profile == nil ? .load : .reload
                return .merge(
                    .send(.userProfile(.input(profileInput))),
                    .send(.notificationPermission(.input(.refresh))),
                )

            case .input(.profileProvided(let profile)):
                return .send(.userProfile(.input(.replace(profile))))

            case .view(.applicationBecameActive):
                return .send(.notificationPermission(.input(.refresh)))

            case .view(.backTapped):
                return .send(.delegate(.backRequested))

            case .view(.positionRowTapped):
                return .send(.delegate(.positionSelectionRequested))

            case .view(.careerLevelRowTapped):
                return .send(.delegate(.careerLevelSelectionRequested))

            case .view(.notificationRowTapped):
                return .send(.notificationPermission(.input(.rowTapped)))

            case .view(.termsTapped):
                guard let url = Constant.servicePolicyURL else { return .none }
                return .send(.delegate(.externalURLRequested(url)))

            case .view(.positionSelected(let position)):
                return .send(.curationUpdate(.input(.positionSelected(position))))

            case .view(.careerLevelSelected(let careerLevel)):
                return .send(.curationUpdate(.input(.careerLevelSelected(careerLevel))))

            case .view(.signOutTapped):
                return .send(.accountAction(.input(.signOutRequested)))

            case .view(.deleteAccountTapped):
                return .send(.accountAction(.input(.deletionRequested)))

            case .view(.deleteAccountCancelled):
                return .send(.accountAction(.input(.deletionCancelled)))

            case .view(.deleteAccountConfirmed):
                return .send(.accountAction(.input(.deletionConfirmed)))

            case .curationUpdate(.delegate(.positionUpdated(let position))):
                guard let profile = state.profile?.replacing(position: position) else { return .none }
                return .send(.userProfile(.input(.replace(profile))))

            case .curationUpdate(.delegate(.careerLevelUpdated(let careerLevel))):
                guard let profile = state.profile?.replacing(careerLevel: careerLevel) else { return .none }
                return .send(.userProfile(.input(.replace(profile))))

            case .accountAction(.delegate(.signedOut)):
                return .send(.delegate(.signedOut))

            case .accountAction(.delegate(.accountDeleted)):
                return .send(.delegate(.accountDeleted))

            case .accountAction(.delegate(.deletionConfirmationRequested)):
                return .send(.delegate(.accountDeletionRequested))

            case .accountAction(.delegate(.deletionCancelled)):
                return .send(.delegate(.accountDeletionCancelled))

            case .userProfile,
                 .curationUpdate,
                 .accountAction,
                 .notificationPermission,
                 .delegate:
                return .none
            }
        }
    }

    // MARK: Private

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
