import ComposableArchitecture
import DomainAccount
import DomainAppSetting
import DomainUserInfo
import Foundation
import Testing

@testable import Feature

// MARK: - SettingsRouterFeatureTests

@MainActor
@Suite("SettingsRouterFeature 화면 전환")
struct SettingsRouterFeatureTests {

    // MARK: Internal

    @Test
    func `초기 활성 화면은 프로필이다`() {
        #expect(SettingsRouterFeature.State().activeScreen == .profile)
    }

    @Test
    func `설정 아이콘을 탭하면 설정 목록으로 전환하고 프로필 값을 input으로 설정에 넘긴다`() async {
        var state = SettingsRouterFeature.State()
        state.profile.profile.load = .loaded(profile)
        let store = makeStore(state: state)

        await store.send(.profile(.view(.settingsTapped)))
        await store.receive(.profile(.delegate(.settingsRequested))) {
            $0.activeScreen = .settings(.list)
        }
        await store.receive(.settings(.input(.profileProvided(profile))))
        await store.receive(.settings(.userProfile(.input(.replace(profile))))) {
            $0.settings.userProfile.load = .loaded(profile)
            $0.settings.userProfile.requestID = 1
        }
    }

    @Test
    func `개발 분야·개발 수준 행은 각 선택 화면으로, 뒤로가기는 목록으로 되돌린다`() async {
        var state = SettingsRouterFeature.State()
        state.activeScreen = .settings(.list)
        let store = makeStore(state: state)
        store.exhaustivity = .off

        await store.send(.settings(.view(.positionRowTapped)))
        await store.receive(.settings(.delegate(.positionSelectionRequested)))
        #expect(store.state.activeScreen == .settings(.positionSelection))

        await store.send(.settings(.view(.backTapped)))
        await store.receive(.settings(.delegate(.backRequested)))
        #expect(store.state.activeScreen == .settings(.list))

        await store.send(.settings(.view(.careerLevelRowTapped)))
        await store.receive(.settings(.delegate(.careerLevelSelectionRequested)))
        #expect(store.state.activeScreen == .settings(.careerLevelSelection))

        await store.send(.settings(.view(.backTapped)))
        await store.receive(.settings(.delegate(.backRequested)))
        #expect(store.state.activeScreen == .settings(.list))
    }

    @Test
    func `설정 목록에서 뒤로가기는 프로필 화면으로 돌아가고 변경된 프로필을 input으로 반영한다`() async {
        var state = SettingsRouterFeature.State()
        state.activeScreen = .settings(.list)
        state.profile.profile.load = .loaded(profile)
        state.settings.userProfile.load = .loaded(updatedProfile)
        let store = makeStore(state: state)

        await store.send(.settings(.view(.backTapped)))
        await store.receive(.settings(.delegate(.backRequested))) {
            $0.activeScreen = .profile
        }
        await store.receive(.profile(.profile(.input(.replace(updatedProfile))))) {
            $0.profile.profile.load = .loaded(updatedProfile)
            $0.profile.profile.requestID = 1
        }
    }

    @Test
    func `계정 삭제 행은 확인 화면으로, 취소는 목록으로 되돌리며 확인 상태를 해제한다`() async {
        var state = SettingsRouterFeature.State()
        state.activeScreen = .settings(.list)
        let store = makeStore(state: state)

        await store.send(.settings(.view(.deleteAccountTapped)))
        await store.receive(.settings(.accountAction(.input(.deletionRequested)))) {
            $0.settings.accountAction.accountAction = .confirmingDeletion
        }
        await store.receive(.settings(.accountAction(.delegate(.deletionConfirmationRequested))))
        await store.receive(.settings(.delegate(.accountDeletionRequested))) {
            $0.activeScreen = .settings(.accountDeletion)
        }

        await store.send(.settings(.view(.deleteAccountCancelled)))
        await store.receive(.settings(.accountAction(.input(.deletionCancelled)))) {
            $0.settings.accountAction.accountAction = .idle
        }
        await store.receive(.settings(.accountAction(.delegate(.deletionCancelled))))
        await store.receive(.settings(.delegate(.accountDeletionCancelled))) {
            $0.activeScreen = .settings(.list)
        }
    }

    @Test(arguments: [SettingsFeature.Action.Delegate.signedOut, .accountDeleted])
    func `로그아웃과 계정 삭제 delegate는 Router delegate로 그대로 올린다`(
        delegate: SettingsFeature.Action.Delegate
    ) async {
        let store = makeStore()

        await store.send(.settings(.delegate(delegate)))
        switch delegate {
        case .signedOut:
            await store.receive(.delegate(.signedOut))

        case .accountDeleted:
            await store.receive(.delegate(.accountDeleted))

        default:
            Issue.record("예상하지 않은 delegate: \(delegate)")
        }
    }

    @Test
    func `서비스 약관 행은 외부 링크 요청을 Router delegate로 올린다`() async throws {
        let url = try #require(URL(string: SettingsTestFixture.servicePolicyURLString))
        var state = SettingsRouterFeature.State()
        state.activeScreen = .settings(.list)
        let store = makeStore(state: state)
        store.exhaustivity = .off

        await store.send(.settings(.view(.termsTapped)))
        await store.receive(.settings(.delegate(.externalURLRequested(url))))
        await store.receive(.delegate(.externalURLRequested(url)))
        #expect(store.state.activeScreen == .settings(.list))
    }

    // MARK: Private

    private let profile = SettingsTestFixture.profile(
        position: .backend,
        careerLevel: .entry,
    )

    private let updatedProfile = SettingsTestFixture.profile(
        position: .ios,
        careerLevel: .senior,
    )

    private func makeStore(
        state: SettingsRouterFeature.State = .init()
    ) -> TestStoreOf<SettingsRouterFeature> {
        TestStore(initialState: state) {
            SettingsRouterFeature(
                account: SettingsRouterAccountUseCaseStub(),
                userInfo: UserInfoUseCaseMock(),
                appSetting: SettingsRouterAppSettingUseCaseStub(),
            )
        }
    }

}

// MARK: - SettingsRouterAccountUseCaseStub

private struct SettingsRouterAccountUseCaseStub: AccountUseCase {

    func signIn(with method: SignInMethod) async -> SignInResult {
        _ = method
        return .retryableFailure
    }

    func signOut() async -> SignOutResult {
        .signedOut
    }

    func signInStates() async -> AsyncStream<SignInState> {
        AsyncStream { $0.finish() }
    }

    func restoreSignIn() async -> SignInRestoration {
        .signedOut
    }

    func verifySignIn() async -> SignInVerification {
        .valid
    }

    func signInAvailability() async -> SignInAvailability {
        .signedIn
    }

    func policyConsentStatus() async throws -> PolicyConsentStatus {
        PolicyConsentStatus(
            documents: [],
            consents: [],
            isSatisfied: false,
        )
    }

    func consent(to documentIDs: [PolicyDocumentID]) async throws {
        _ = documentIDs
    }

    func withdraw() async throws { }

}

// MARK: - SettingsRouterAppSettingUseCaseStub

private struct SettingsRouterAppSettingUseCaseStub: AppSettingUseCase {

    func notificationAuthorization() async -> NotificationAuthorizationStatus {
        .denied
    }

    func requestNotificationAuthorization() async -> NotificationAuthorizationStatus {
        .denied
    }

    func registerDevice() async throws { }

    func updateDeviceToken(_ token: DeviceToken) async throws {
        _ = token
    }

}
