import ComposableArchitecture
import DomainAppSetting
import Testing

@testable import Feature

@MainActor
@Suite("NotificationPermissionFeature 알림 권한")
struct NotificationPermissionFeatureTests {

    // MARK: Internal

    @Test(arguments: [
        (NotificationAuthorizationStatus.authorized, NotificationPermissionFeature.State.NotificationStatus.allowed),
        (.denied, .denied),
        (.notDetermined, .denied),
    ])
    func `refresh는 알림 권한 상태를 조회해 켜짐·꺼짐 값으로 남긴다`(
        authorization: NotificationAuthorizationStatus,
        expected: NotificationPermissionFeature.State.NotificationStatus,
    ) async {
        let store = makeStore(notificationAuthorization: { authorization })

        await store.send(.input(.refresh))
        await store.receive(.effect(.authorizationChecked(authorization))) {
            $0.notificationStatus = expected
        }
    }

    @Test
    func `알림이 켜져 있으면 rowTapped는 시스템 알림 설정 화면을 연다`() async {
        let openedNotificationSettings = LockIsolated(0)
        let requestedAuthorizationCount = LockIsolated(0)
        let store = makeStore(
            notificationAuthorization: { .authorized },
            requestNotificationAuthorization: {
                requestedAuthorizationCount.withValue { $0 += 1 }
                return .authorized
            },
            openNotificationSettings: { openedNotificationSettings.withValue { $0 += 1 } },
        )

        await store.send(.input(.rowTapped))

        #expect(openedNotificationSettings.value == 1)
        #expect(requestedAuthorizationCount.value == 0)
    }

    @Test
    func `알림 권한을 정하지 않았으면 rowTapped는 시스템 권한을 요청하고 결과로 상태를 갱신한다`() async {
        let openedNotificationSettings = LockIsolated(0)
        let requestedAuthorizationCount = LockIsolated(0)
        let store = makeStore(
            state: NotificationPermissionFeature.State(notificationStatus: .denied),
            notificationAuthorization: { .notDetermined },
            requestNotificationAuthorization: {
                requestedAuthorizationCount.withValue { $0 += 1 }
                return .authorized
            },
            openNotificationSettings: { openedNotificationSettings.withValue { $0 += 1 } },
        )

        await store.send(.input(.rowTapped))
        await store.receive(.effect(.authorizationChecked(.authorized))) {
            $0.notificationStatus = .allowed
        }

        #expect(requestedAuthorizationCount.value == 1)
        #expect(openedNotificationSettings.value == 0)
    }

    @Test
    func `이미 거부한 알림 권한은 rowTapped에서 권한을 요청하지 않고 시스템 알림 설정 화면으로 이어진다`() async {
        let openedNotificationSettings = LockIsolated(0)
        let requestedAuthorizationCount = LockIsolated(0)
        let store = makeStore(
            state: NotificationPermissionFeature.State(notificationStatus: .denied),
            notificationAuthorization: { .denied },
            requestNotificationAuthorization: {
                requestedAuthorizationCount.withValue { $0 += 1 }
                return .authorized
            },
            openNotificationSettings: { openedNotificationSettings.withValue { $0 += 1 } },
        )

        await store.send(.input(.rowTapped))

        #expect(openedNotificationSettings.value == 1)
        #expect(requestedAuthorizationCount.value == 0)
    }

    // MARK: Private

    private func makeStore(
        state: NotificationPermissionFeature.State = NotificationPermissionFeature.State(),
        notificationAuthorization: @escaping @Sendable () async -> NotificationAuthorizationStatus = { .denied },
        requestNotificationAuthorization: @escaping @Sendable () async -> NotificationAuthorizationStatus = { .denied },
        openNotificationSettings: @escaping @MainActor @Sendable () async -> Void = { },
    ) -> TestStoreOf<NotificationPermissionFeature> {
        TestStore(initialState: state) {
            NotificationPermissionFeature(
                notificationAuthorization: notificationAuthorization,
                requestNotificationAuthorization: requestNotificationAuthorization,
                openNotificationSettings: openNotificationSettings,
            )
        }
    }

}
