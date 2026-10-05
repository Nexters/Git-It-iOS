# 계약: 알림 권한 조회·요청 (Data)

**소유**: Data `DataNotification`
**소비**: Composition `NotificationAuthorizationAdapter` → Domain `NotificationAuthorization` →
`AppSetting`(설정 화면, "홈에서 기다리기" 권한 시트)

## 이후 공개면 (U2·U3에서 기능 축소, U7에서 이름 변경)

| 요소 | 형태 |
|---|---|
| 계약 | `protocol NotificationPermissionRequester: Sendable` |
| 권한 요청 | `func requestAuthorization() async -> NotificationPermissionRequestResult` |
| 현재 설정 조회 | `func authorizationSetting() async -> NotificationPermissionSetting` |
| 구현 | `NotificationPermissionClient` (Infrastructure `NotificationAuthorizationClient` 위에서 동작) |
| 생성 진입점 | `NotificationFactory.notificationPermissionRequester() -> any NotificationPermissionRequester` |
| Composition | `NotificationAuthorizationAdapter(permissionRequester:)`, `ConcernUseCaseAssembly(… notificationPermissionRequester:)` |

## 제거되는 공개면

| 요소 | 제거 단위 |
|---|---|
| `isAuthorized() async -> Bool` | U2 |
| `schedule(_:at:)`, `cancel(identifier:)`, `ReminderNotification` | U2 |
| Infrastructure `NotificationAuthorizationClient.isAuthorized`·`present`·`schedule`·`cancel`, `LocalNotificationRequest` | U3 |

## 동작 (변경 없음)

| Infrastructure 결과 | `NotificationPermissionRequestResult` | Domain `NotificationAuthorizationStatus` |
|---|---|---|
| 허용 | `authorized` | `authorized` |
| 이번 요청에서 거절 | `declined` | `denied` |
| 이전에 거절 | `previouslyDenied` | `denied` |
