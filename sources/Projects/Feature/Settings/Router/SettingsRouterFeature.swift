import ComposableArchitecture
import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation

@Reducer
public struct SettingsRouterFeature: Sendable {

    // MARK: Lifecycle

    public init(
        signOut: any SignOutUseCase,
        memberAccount: any MemberAccountUseCase,
        deleteMemberAccount: any DeleteMemberAccountUseCase,
        requestGenerationReminder: any RequestGenerationReminderUseCase,
        openNotificationSettings: @escaping @MainActor @Sendable () async -> Void = { },
    ) {
        self.signOut = signOut
        self.memberAccount = memberAccount
        self.deleteMemberAccount = deleteMemberAccount
        self.requestGenerationReminder = requestGenerationReminder
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
            ProfileFeature(fetchMemberProfile: { [memberAccount] in try await memberAccount.profile() })
        }
        Scope(state: \.settings, action: \.settings) {
            SettingsFeature(
                signOut: signOut,
                fetchMemberProfile: { [memberAccount] in try await memberAccount.profile() },
                updateMemberPosition: { [memberAccount] in try await memberAccount.updatePosition($0) },
                updateMemberCareerLevel: { [memberAccount] in try await memberAccount.updateCareerLevel($0) },
                deleteMemberAccount: deleteMemberAccount,
                requestGenerationReminder: requestGenerationReminder,
                openNotificationSettings: openNotificationSettings,
            )
        }
        Reduce { state, action in
            switch action {
            case .profile(.delegate(.settingsRequested)):
                if case .loaded(let profile) = state.profile.profileLoad {
                    state.settings.profile = profile
                    state.settings.profileLoad = .loaded
                }
                state.activeScreen = .settings(.list)
                return .none

            case .settings(.delegate(.backRequested)):
                switch state.activeScreen {
                case .settings(.list):
                    if let profile = state.settings.profile {
                        state.profile.profileLoad = .loaded(profile)
                    }
                    state.activeScreen = .profile

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

    private let signOut: any SignOutUseCase
    private let memberAccount: any MemberAccountUseCase
    private let deleteMemberAccount: any DeleteMemberAccountUseCase
    private let requestGenerationReminder: any RequestGenerationReminderUseCase
    private let openNotificationSettings: @MainActor @Sendable () async -> Void

}
