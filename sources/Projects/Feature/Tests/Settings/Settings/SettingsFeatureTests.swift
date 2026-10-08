import ComposableArchitecture
import DomainAppSetting
import DomainUserInfo
import Foundation
import Testing

@testable import Feature

@MainActor
@Suite("SettingsFeature 자식 합성과 delegate 전달")
struct SettingsFeatureTests {

    // MARK: Internal

    @Test
    func `프로필이 없으면 task는 프로필 조회에 load를 보내 설정 값의 근거로 남긴다`() async {
        let fetchMemberProfile = UserInfoUseCaseProfileMock(results: [.success(SettingsTestFixture.curatedProfile)])
        let store = makeStore(fetchMemberProfile: fetchMemberProfile)
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.view(.task))
        await store.receive(.userProfile(.input(.load))) {
            $0.userProfile.load = .loading
            $0.userProfile.requestID = 1
        }
        await store.receive(.userProfile(.effect(.profileLoadFinished(
            requestID: 1,
            result: .success(SettingsTestFixture.curatedProfile),
        )))) {
            $0.userProfile.load = .loaded(SettingsTestFixture.curatedProfile)
        }

        #expect(await fetchMemberProfile.snapshot() == 1)
    }

    @Test
    func `이미 받은 프로필이 있으면 task는 값을 유지한 채 reload를 보낸다`() async {
        let updated = SettingsTestFixture.profile(
            position: .ios,
            careerLevel: .senior,
        )
        let store = makeStore(
            state: makeState(profile: SettingsTestFixture.curatedProfile),
            fetchMemberProfile: UserInfoUseCaseProfileMock(results: [.success(updated)]),
        )
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.view(.task))
        await store.receive(.userProfile(.input(.reload))) {
            $0.userProfile.requestID = 1
        }
        #expect(store.state.profile == SettingsTestFixture.curatedProfile)
        await store.receive(.userProfile(.effect(.profileLoadFinished(
            requestID: 1,
            result: .success(updated),
        )))) {
            $0.userProfile.load = .loaded(updated)
        }
    }

    @Test
    func `프로필 조회 실패는 값 없이 실패 상태만 남긴다`() async {
        let store = makeStore(
            fetchMemberProfile: UserInfoUseCaseProfileMock(results: [.failure(.temporarilyUnavailable)])
        )
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.view(.task))
        await store.receive(.userProfile(.effect(.profileLoadFinished(
            requestID: 1,
            result: .failure(.temporarilyUnavailable),
        )))) {
            $0.userProfile.load = .failed(.temporarilyUnavailable)
        }

        #expect(store.state.profile == nil)
    }

    @Test
    func `외부에서 받은 프로필은 프로필 조회에 replace로 전달한다`() async {
        let store = makeStore()

        await store.send(.input(.profileProvided(SettingsTestFixture.curatedProfile)))
        await store.receive(.userProfile(.input(.replace(SettingsTestFixture.curatedProfile)))) {
            $0.userProfile.load = .loaded(SettingsTestFixture.curatedProfile)
            $0.userProfile.requestID = 1
        }
    }

    @Test
    func `task는 알림 권한에 refresh를 보낸다`() async {
        let store = makeStore(notificationAuthorization: { .authorized })
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.view(.task))
        await store.receive(.notificationPermission(.input(.refresh)))
        await store.receive(.notificationPermission(.effect(.authorizationChecked(.authorized)))) {
            $0.notificationPermission.notificationStatus = .allowed
        }
    }

    @Test
    func `앱 설정에서 돌아오면 알림 권한에 refresh를 보낸다`() async {
        var state = SettingsFeature.State()
        state.notificationPermission.notificationStatus = .denied
        let store = makeStore(
            state: state,
            notificationAuthorization: { .authorized },
        )

        await store.send(.view(.applicationBecameActive))
        await store.receive(.notificationPermission(.input(.refresh)))
        await store.receive(.notificationPermission(.effect(.authorizationChecked(.authorized)))) {
            $0.notificationPermission.notificationStatus = .allowed
        }
    }

    @Test
    func `알림 항목 탭은 알림 권한에 rowTapped를 보낸다`() async {
        let openedNotificationSettings = LockIsolated(0)
        let store = makeStore(
            notificationAuthorization: { .authorized },
            openNotificationSettings: { openedNotificationSettings.withValue { $0 += 1 } },
        )

        await store.send(.view(.notificationRowTapped))
        await store.receive(.notificationPermission(.input(.rowTapped)))

        #expect(openedNotificationSettings.value == 1)
    }

    @Test
    func `직군 저장 성공은 직군만 바꾸고 연차와 통계를 유지한다`() async {
        let updateMemberPosition = UserInfoUseCasePositionMock()
        let store = makeStore(
            state: makeState(profile: SettingsTestFixture.curatedProfile),
            updateMemberPosition: updateMemberPosition,
        )

        await store.send(.view(.positionSelected(.ios)))
        await store.receive(.curationUpdate(.input(.positionSelected(.ios)))) {
            $0.curationUpdate.positionMutation = .committing
        }
        await store.receive(.curationUpdate(.effect(.positionUpdateFinished(.ios, nil)))) {
            $0.curationUpdate.positionMutation = .idle
        }
        await store.receive(.curationUpdate(.delegate(.positionUpdated(.ios))))
        await store.receive(.userProfile(.input(.replace(SettingsTestFixture.profile(
            position: .ios,
            careerLevel: .entry,
        ))))) {
            $0.userProfile.load = .loaded(SettingsTestFixture.profile(
                position: .ios,
                careerLevel: .entry,
            ))
            $0.userProfile.requestID = 1
        }

        #expect(await updateMemberPosition.snapshot() == [.ios])
    }

    @Test
    func `연차 저장 성공은 연차만 바꾸고 직군과 통계를 유지한다`() async {
        let updateMemberCareerLevel = UserInfoUseCaseCareerLevelMock()
        let store = makeStore(
            state: makeState(profile: SettingsTestFixture.curatedProfile),
            updateMemberCareerLevel: updateMemberCareerLevel,
        )

        await store.send(.view(.careerLevelSelected(.senior)))
        await store.receive(.curationUpdate(.input(.careerLevelSelected(.senior)))) {
            $0.curationUpdate.careerLevelMutation = .committing
        }
        await store.receive(.curationUpdate(.effect(.careerLevelUpdateFinished(.senior, nil)))) {
            $0.curationUpdate.careerLevelMutation = .idle
        }
        await store.receive(.curationUpdate(.delegate(.careerLevelUpdated(.senior))))
        await store.receive(
            .userProfile(.input(.replace(SettingsTestFixture.profile(
                position: .backend,
                careerLevel: .senior,
            ))))
        ) {
            $0.userProfile.load = .loaded(SettingsTestFixture.profile(
                position: .backend,
                careerLevel: .senior,
            ))
            $0.userProfile.requestID = 1
        }

        #expect(await updateMemberCareerLevel.snapshot() == [.senior])
    }

    @Test
    func `저장 실패는 이전 프로필을 그대로 둔다`() async {
        let store = makeStore(
            state: makeState(profile: SettingsTestFixture.curatedProfile),
            updateMemberPosition: UserInfoUseCasePositionMock(errors: [.temporarilyUnavailable]),
        )
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.view(.positionSelected(.ios)))
        await store.receive(.curationUpdate(.effect(.positionUpdateFinished(.ios, .temporarilyUnavailable))))

        #expect(store.state.curationUpdate.positionMutation == .failed(.temporarilyUnavailable))
        #expect(store.state.profile == SettingsTestFixture.curatedProfile)
    }

    @Test(arguments: zip(
        [
            SettingsFeature.Action.View.signOutTapped,
            .deleteAccountTapped,
            .deleteAccountCancelled,
            .deleteAccountConfirmed,
        ],
        [
            AccountActionFeature.Action.Input.signOutRequested,
            .deletionRequested,
            .deletionCancelled,
            .deletionConfirmed,
        ],
    ))
    func `계정 동작 탭은 계정 동작에 대응 input을 보낸다`(
        view: SettingsFeature.Action.View,
        input: AccountActionFeature.Action.Input,
    ) async {
        let store = makeStore()
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.view(view))
        await store.receive(.accountAction(.input(input)))
        await store.finish()
        await store.skipReceivedActions(strict: false)
    }

    @Test(arguments: zip(
        [
            AccountActionFeature.Action.Delegate.signedOut,
            .accountDeleted,
            .deletionConfirmationRequested,
            .deletionCancelled,
        ],
        [
            SettingsFeature.Action.Delegate.signedOut,
            .accountDeleted,
            .accountDeletionRequested,
            .accountDeletionCancelled,
        ],
    ))
    func `계정 동작 delegate는 기존 Settings delegate로 올린다`(
        child: AccountActionFeature.Action.Delegate,
        delegate: SettingsFeature.Action.Delegate,
    ) async {
        let store = makeStore()

        await store.send(.accountAction(.delegate(child)))
        await store.receive(.delegate(delegate))
    }

    @Test(arguments: zip(
        [SettingsFeature.Action.View.backTapped, .positionRowTapped, .careerLevelRowTapped],
        [
            SettingsFeature.Action.Delegate.backRequested,
            .positionSelectionRequested,
            .careerLevelSelectionRequested,
        ],
    ))
    func `이동 행 탭은 대응하는 delegate만 올린다`(
        view: SettingsFeature.Action.View,
        delegate: SettingsFeature.Action.Delegate,
    ) async {
        let store = makeStore()

        await store.send(.view(view))
        await store.receive(.delegate(delegate))
    }

    @Test
    func `서비스 약관 행은 서비스 정책 URL을 외부 링크 요청으로 올린다`() async throws {
        let url = try #require(URL(string: SettingsTestFixture.servicePolicyURLString))
        let store = makeStore()

        await store.send(.view(.termsTapped))
        await store.receive(.delegate(.externalURLRequested(url)))
    }

    // MARK: Private

    private func makeState(profile: UserProfile) -> SettingsFeature.State {
        var state = SettingsFeature.State()
        state.userProfile.load = .loaded(profile)
        return state
    }

    private func makeStore(
        state: SettingsFeature.State = SettingsFeature.State(),
        fetchMemberProfile: UserInfoUseCaseProfileMock = UserInfoUseCaseProfileMock(),
        updateMemberPosition: UserInfoUseCasePositionMock = UserInfoUseCasePositionMock(),
        updateMemberCareerLevel: UserInfoUseCaseCareerLevelMock = UserInfoUseCaseCareerLevelMock(),
        notificationAuthorization: @escaping @Sendable () async -> NotificationAuthorizationStatus = { .denied },
        requestNotificationAuthorization: @escaping @Sendable () async -> NotificationAuthorizationStatus = { .denied },
        openNotificationSettings: @escaping @MainActor @Sendable () async -> Void = { },
    ) -> TestStoreOf<SettingsFeature> {
        TestStore(initialState: state) {
            SettingsFeature(
                signOut: AccountUseCaseSignOutMock().signOut,
                profile: fetchMemberProfile.profile,
                updatePosition: updateMemberPosition.updatePosition,
                updateCareerLevel: updateMemberCareerLevel.updateCareerLevel,
                withdraw: AccountUseCaseWithdrawalMock().withdraw,
                notificationAuthorization: notificationAuthorization,
                requestNotificationAuthorization: requestNotificationAuthorization,
                openNotificationSettings: openNotificationSettings,
            )
        }
    }

}
