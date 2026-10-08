# 계약: InfrastructurePushMessaging 공개 API

**기능 브랜치**: `feature/generation-reminder-refactoring`

**적용 요구사항**: FR-001, FR-002, FR-003, FR-016, FR-017

이 문서는 `InfrastructurePushMessaging` target이 외부(현재 소비자는 Composition)에 제공하는
공개 표면의 변경 전후를 고정한다. Infrastructure는 범용 기술 능력만 제공하며 서비스 고유
개념을 소유하지 않는다(`docs/package-rules/infrastructure.md`).

## 1. 로컬 알림 계약

### 변경 전

```swift
public protocol LocalNotificationClient: Sendable {
    func requestAuthorization() async -> LocalNotificationAuthorizationOutcome
    func isAuthorized() async -> Bool
    func presentGenerationCompletedNotification(projectID: String)
}

public enum LocalNotificationAuthorizationOutcome: Sendable, Equatable {
    case authorized
    case declined
    case previouslyDenied
}
```

**위반 사항**

- `presentGenerationCompletedNotification(projectID:)` — 연산 이름이 "생성 완료"라는 서비스
  고유 개념을 담는다. 구현체가 한국어 표시 문구와 `generation-completed-` 식별자를 소유한다.
- 한 파일이 파일 밖에서 참조되는 최상위 타입 둘(`protocol` + `enum`)을 정의한다.

### 변경 후

```swift
public protocol LocalNotificationClient: Sendable {
    func requestAuthorization() async -> LocalNotificationAuthorizationOutcome
    func isAuthorized() async -> Bool
    func present(_ request: LocalNotificationRequest)
}

public enum LocalNotificationAuthorizationOutcome: Sendable, Equatable {
    case authorized
    case declined
    case previouslyDenied
}

public struct LocalNotificationRequest: Sendable, Equatable {
    public init(identifier: String, title: String, body: String)
    public let identifier: String
    public let title: String
    public let body: String
}
```

**타입 분리**: Swift는 protocol 내부에 타입을 중첩할 수 없다(언어 제약,
[research.md](../research.md) R-010). `LocalNotificationAuthorizationOutcome`은 이름을
바꾸지 않고 최상위 타입으로 유지하되, "파일 하나에 타입 하나" 규칙(FR-003)을 지키기 위해
`LocalNotificationClient`와 별도 파일로 분리한다
([file-vocabulary.md §2.4](../../../docs/conventions/file-vocabulary.md#24-중첩할-수-없는-타입)).

**계약 의미**

| 연산 | 의미 | 실패 처리 |
| --- | --- | --- |
| `requestAuthorization()` | 미결정이면 시스템 다이얼로그를 띄우고, 이미 거부면 다이얼로그 없이 `previouslyDenied`를 반환한다 | 요청 자체가 던지면 `declined` |
| `isAuthorized()` | 다이얼로그 없이 현재 권한이 허용 상태인지 반환한다 | 없음 (`Bool`) |
| `present(_:)` | 전달받은 값 그대로 즉시 표시 알림을 발송한다 | 발송 실패를 호출자에게 보고하지 않는다 (변경 없음) |

**권한 상태 매핑**(구현체, 변경 없음)

| `UNAuthorizationStatus` | `requestAuthorization()` | `isAuthorized()` |
| --- | --- | --- |
| `.notDetermined` | 시스템 요청 후 `authorized` 또는 `declined` | `false` |
| `.denied` | `previouslyDenied` | `false` |
| `.authorized` / `.provisional` / `.ephemeral` | `authorized` | `true` |

**불변 조건**

- 이 target의 어떤 소스도 "세트", "학습", "generation-completed" 문자열을 포함하지 않는다
  (SC-001).
- `present(_:)`는 전달받은 `identifier`·`title`·`body`를 변형하지 않는다.

## 2. 원격 푸시 계약 *(변경 없음)*

```swift
public protocol PushMessagingClient: Sendable {
    func registrationToken() async throws -> String
    func setAPNsToken(_ token: Data)
}
```

`FirebaseMessagingPushClient`의 동작은 이번 범위에서 바꾸지 않는다.

## 3. 플랫폼 생명주기 delegate

`FirebaseMessagingAppDelegate`는 이 target에 계속 존재하되, **Composition 밖으로 재노출되지
않는다**. Composition이 자신의 타입으로 감싼다([composition-public-surface.md](./composition-public-surface.md) 참조).

`PushNotificationHandlers`는 이름을 `PushNotificationCallbacks`로 바꾼다. 필드 구성과
`configure(_:)` 동작은 변경하지 않는다.

## 4. 폴더 배치

원격 푸시와 로컬 알림은 하위 능력 폴더로 분리한다. target은 분리하지 않는다(명세 `가정`).

```text
Infrastructure/PushMessaging/
├── Local/
│   ├── Clients/       LocalNotificationClient, UserNotificationCenterLocalClient
│   └── Models/        LocalNotificationRequest, LocalNotificationAuthorizationOutcome
└── Remote/
    ├── AppDelegates/  FirebaseMessagingAppDelegate
    ├── Clients/       PushMessagingClient, FirebaseMessagingPushClient
    └── Models/        PushNotificationCallbacks, RemoteNotificationPayload
```

`docs/conventions/file-vocabulary.md` §3의 Infrastructure 행은
`Infrastructure/<능력>/[<하위 능력>/]`을 이미 허용하므로 어휘 갱신이 필요 없다.

## 5. 테스트 target

`InfrastructurePushMessagingTests`를 신설한다. 다른 Infrastructure 기술 패키지와 동일한
구성을 따르며, 소스 폴더는 `Infrastructure/Tests/PushMessaging/`이다.

**최소 검증 범위**(외부 라이브러리 링크 없이 가능한 것부터):

| 대상 | 검증 |
| --- | --- |
| `RemoteNotificationPayload` | `[AnyHashable: Any]` → `[String: String]` 변환에서 비문자열 키가 제외되는지 |
| `LocalNotificationRequest` | 값 보존(생성한 필드가 그대로 읽히는지) |
| `UserNotificationCenterLocalClient` | 권한 상태 → 결과 매핑 3분기 (§1 표) |

**등록 위치**

- `Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift` — enum case,
  module 정의, `sourceDirectory` 분기
- `Tuist/ProjectDescriptionHelpers/ProjectName.swift` — Infrastructure 프로젝트의 `testTargets`
