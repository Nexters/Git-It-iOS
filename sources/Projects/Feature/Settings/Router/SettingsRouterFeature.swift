import ComposableArchitecture
import DomainAccount
import DomainAppSetting
import DomainUserInfo
import Foundation

@Reducer
public struct SettingsRouterFeature: Sendable {

    // MARK: Lifecycle

    public init(
        account: any AccountUseCase,
        userInfo: any UserInfoUseCase,
        appSetting: any AppSettingUseCase,
        openNotificationSettings: @escaping @MainActor @Sendable () async -> Void = { },
    ) {
        self.account = account
        self.userInfo = userInfo
        self.appSetting = appSetting
        self.openNotificationSettings = openNotificationSettings
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init() { }

        // MARK: Public

        public enum ActiveScreen: Hashable, Sendable {
            case profile
            case settings(SettingsStep)
        }

        public enum SettingsStep: Hashable, Sendable {
            case list
            case positionSelection
            case careerLevelSelection
            case accountDeletion
        }

        public var profile = ProfileFeature.State()
        public var settings = SettingsFeature.State()
        public var activeScreen = ActiveScreen.profile

    }

    public enum Action: Equatable, Sendable {
        case profile(ProfileFeature.Action)
        case settings(SettingsFeature.Action)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            case signedOut
            case accountDeleted
            case externalURLRequested(URL)
        }
    }

    public var body: some ReducerOf<Self> {
        Scope(state: \.profile, action: \.profile) {
            ProfileFeature(profile: { [userInfo] in try await Self.profile(from: userInfo) })
        }
        Scope(state: \.settings, action: \.settings) {
            SettingsFeature(
                signOut: { [account] in await account.signOut() },
                profile: { [userInfo] in try await Self.profile(from: userInfo) },
                updatePosition: { [userInfo] in try await userInfo.updatePosition($0) },
                updateCareerLevel: { [userInfo] in try await userInfo.updateCareerLevel($0) },
                withdraw: { [account] in try await account.withdraw() },
                notificationAuthorization: { [appSetting] in await appSetting.notificationAuthorization() },
                requestNotificationAuthorization: { [appSetting] in
                    await appSetting.requestNotificationAuthorization()
                },
                openNotificationSettings: openNotificationSettings,
            )
        }
        Reduce { state, action in
            switch action {
            case .profile(.delegate(.settingsRequested)):
                state.activeScreen = .settings(.list)
                guard let profile = state.profile.profile.profile else { return .none }
                return .send(.settings(.input(.profileProvided(profile))))

            case .settings(.delegate(.backRequested)):
                switch state.activeScreen {
                case .settings(.list):
                    state.activeScreen = .profile
                    guard let profile = state.settings.profile else { return .none }
                    return .send(.profile(.profile(.input(.replace(profile)))))

                case .settings(.positionSelection),
                     .settings(.careerLevelSelection),
                     .settings(.accountDeletion):
                    state.activeScreen = .settings(.list)

                case .profile:
                    break
                }
                return .none

            case .settings(.delegate(.positionSelectionRequested)):
                state.activeScreen = .settings(.positionSelection)
                return .none

            case .settings(.delegate(.careerLevelSelectionRequested)):
                state.activeScreen = .settings(.careerLevelSelection)
                return .none

            case .settings(.delegate(.accountDeletionRequested)):
                state.activeScreen = .settings(.accountDeletion)
                return .none

            case .settings(.delegate(.accountDeletionCancelled)):
                state.activeScreen = .settings(.list)
                return .none

            case .settings(.delegate(.signedOut)):
                return .send(.delegate(.signedOut))

            case .settings(.delegate(.accountDeleted)):
                return .send(.delegate(.accountDeleted))

            case .settings(.delegate(.externalURLRequested(let url))):
                return .send(.delegate(.externalURLRequested(url)))

            case .profile,
                 .settings,
                 .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private let account: any AccountUseCase
    private let userInfo: any UserInfoUseCase
    private let appSetting: any AppSettingUseCase
    private let openNotificationSettings: @MainActor @Sendable () async -> Void

    private static func profile(from userInfo: any UserInfoUseCase) async throws -> UserProfile {
        async let detail = userInfo.detail()
        async let curation = userInfo.curation()
        return try await UserProfile(detail: detail, curation: curation)
    }

}
