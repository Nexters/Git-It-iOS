# 계약: 로컬 알림 예약 (Infrastructure)

**대상 요구사항**: FR-010, FR-012, FR-014, FR-016

## 변경 전

```swift
public protocol LocalNotificationClient: Sendable {
    func requestAuthorization() async -> LocalNotificationAuthorizationOutcome
    func isAuthorized() async -> Bool
    func present(_ request: LocalNotificationRequest)   // 즉시 발송만 가능
}
```

## 변경 후 (추가만, 기존 API 유지)

```swift
public protocol LocalNotificationClient: Sendable {
    func requestAuthorization() async -> LocalNotificationAuthorizationOutcome
    func isAuthorized() async -> Bool
    func present(_ request: LocalNotificationRequest)

    /// 지정한 시각에 발송되도록 시스템에 예약한다. 이미 지난 시각이면 즉시 발송한다.
    func schedule(_ request: LocalNotificationRequest, at date: Date)

    /// 아직 발송되지 않은 예약을 취소한다. 해당 식별자의 예약이 없으면 아무 일도 하지 않는다.
    func cancel(identifier: String)
}
```

**변경 성격**: 추가 전용. `present`의 시그니처와 동작은 그대로라 기존 호출자는 영향을 받지
않는다. Infrastructure 단독으로 컴파일되므로 Composition 반영과 분리할 수 있다(R-007).

## 동작 계약

| 조건 | 기대 |
| --- | --- |
| `schedule`에 미래 시각을 전달 | 앱이 백그라운드·잠자기·종료 상태여도 그 시각에 도착한다(FR-010) |
| `schedule`에 과거 시각을 전달 | 추가 지연 없이 즉시 발송한다(FR-012) |
| 같은 식별자로 `schedule`을 두 번 호출 | 예약이 1건만 남아 알림도 1회만 도착한다(FR-014) |
| `cancel` 후 예정 시각 도달 | 알림이 도착하지 않는다 |
| 알림 권한 없음 | 예약·발송하지 않는다. 판단은 호출자가 `isAuthorized`로 수행한다(FR-016) |

**구현 메모**: `UNTimeIntervalNotificationTrigger`와
`removePendingNotificationRequests(withIdentifiers:)`를 사용한다. 시스템이 예약을 보관하므로
인프로세스 타이머와 달리 앱 정지 상태에서도 발화한다.
