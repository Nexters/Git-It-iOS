import ComposableArchitecture
import DomainAuthentication
import DomainMember
import Foundation

/// "마이" 탭의 순차 흐름 Router. 프로필 화면과 설정 화면(목록·개발 분야 선택·개발 수준 선택·
/// 계정 삭제 확인 4단계)의 State를 항상 보유하고 활성 화면만 전환한다.
@Reducer
public struct SettingsRouterFeature: Sendable {

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

        // MARK: Lifecycle

        public init() { }

        // MARK: Public

        public enum ActiveScreen: Equatable, Sendable {
            case profile
            case settings(SettingsStep)
        }

        public enum SettingsStep: Equatable, Sendable {
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
            ProfileFeature(fetchMemberProfile: fetchMemberProfile)
        }
        Scope(state: \.settings, action: \.settings) {
            SettingsFeature(
                signOut: signOut,
                fetchMemberProfile: fetchMemberProfile,
                updateMemberPosition: updateMemberPosition,
                updateMemberCareerLevel: updateMemberCareerLevel,
                deleteMemberAccount: deleteMemberAccount,
            )
        }
        Reduce { state, action in
            switch action {
            case .profile(.delegate(.settingsRequested)):
                // 프로필 화면이 이미 받은 값을 설정 화면에 넘겨 재조회 전까지 빈 값이 보이지 않게 한다.
                if case .loaded(let profile) = state.profile.profileLoad {
                    state.settings.profile = profile
                    state.settings.profileLoad = .loaded
                }
                state.activeScreen = .settings(.list)
                return .none

            case .settings(.delegate(.backRequested)):
                switch state.activeScreen {
                case .settings(.list):
                    // 설정에서 바꾼 직군·연차를 프로필 화면에 즉시 반영한다(S2 수용 기준).
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
    private let fetchMemberProfile: any FetchMemberProfileUseCase
    private let updateMemberPosition: any UpdateMemberPositionUseCase
    private let updateMemberCareerLevel: any UpdateMemberCareerLevelUseCase
    private let deleteMemberAccount: any DeleteMemberAccountUseCase

}
