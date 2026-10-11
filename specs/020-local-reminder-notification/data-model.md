# 데이터 모델: 생성 완료 리마인드 알림의 실제 권한 요청과 로컬 알림 발송

이 기능은 019와 동일한 형태로 Domain에 명시적 UseCase·계약·모델을 추가한다(Feature가
Infrastructure 결과 타입을 직접 참조하지 않고, 이미 허용된 Domain 의존성만으로 필요한 정보를
받도록 하기 위해서다. 근거는 [research.md](./research.md) 3절 참고). 영속 저장 스키마는
추가하지 않는다.

## NotificationAuthorizationOutcome (Domain 모델, 신규)

`sources/Projects/Domain/LearningProject/Models/NotificationAuthorizationOutcome.swift`

| 케이스 | 의미 |
| --- | --- |
| `authorized` | 이미 허용됐거나, 방금 요청해 사용자가 허용을 선택했다 |
| `declined` | 방금 요청했고 사용자가 거부를 선택했다(또는 요청 자체가 실패했다) |
| `previouslyDenied` | 과거에 이미 거부한 상태라 이번에는 시스템 다이얼로그를 띄우지 않았다 |

`LearningProjectGenerationOutcome.Status`(기존, `completed`/`failed`)와 같은 위치·스타일의
독립적인 Domain enum이다. Feature는 이미 허용된 Domain 의존성을 통해 이 타입을 그대로
받으므로 Infrastructure 타입을 경계 너머로 노출할 필요가 없다.

## RequestGenerationReminderUseCase (Domain 계약, 신규)

`sources/Projects/Domain/LearningProject/UseCases/RequestGenerationReminder/RequestGenerationReminderUseCase.swift`

```swift
public protocol RequestGenerationReminderUseCase: Sendable {
    func callAsFunction(projectID: String) async -> NotificationAuthorizationOutcome
}
```

`ProjectRegistrationFeature`가 생성자로 주입받는 유일한 신규 의존성이다. 알림 옵션 수락 시
"권한을 확인·요청하고, 허용되면 이 프로젝트를 리마인드 대상으로 등록한다"는 절차 전체를
캡슐화한다.

## RequestGenerationReminder (Domain UseCase 구현, 신규)

`sources/Projects/Domain/LearningProject/UseCases/RequestGenerationReminder/RequestGenerationReminder.swift`

```swift
public struct RequestGenerationReminder: RequestGenerationReminderUseCase, Sendable {
    public init(
        authorizationGateway: any NotificationAuthorizationGateway,
        reminderRegistry: any GenerationReminderRegistry,
    ) { ... }

    public func callAsFunction(projectID: String) async -> NotificationAuthorizationOutcome {
        let outcome = await authorizationGateway.requestAuthorization()
        if outcome == .authorized {
            await reminderRegistry.register(projectID: projectID)
        }
        return outcome
    }
}
```

- 비즈니스 규칙(권한이 허용된 경우에만 리마인드 대상으로 등록한다)을 이 UseCase가 소유한다.
- "이미 거부됨"과 "방금 거부함"을 구분하는 책임은 `NotificationAuthorizationGateway`
  구현(아래)에 있다. UseCase는 결과를 그대로 반환하기만 하면 되므로 별도 사전 조회를 하지
  않는다(019가 `LearningProjectOutcomes`에서 판정 로직 없이 스트림을 그대로 넘기는 것과 같은
  얇은 조립 스타일).

## NotificationAuthorizationGateway (Domain 계약, 신규)

`sources/Projects/Domain/LearningProject/Contracts/NotificationAuthorizationGateway.swift`

```swift
public protocol NotificationAuthorizationGateway: Sendable {
    /// 현재 권한 상태를 확인하고, 아직 결정되지 않았다면 시스템 권한 요청 다이얼로그를
    /// 표시한다. 이미 거부된 상태라면 다이얼로그 없이 `.previouslyDenied`를 반환한다.
    func requestAuthorization() async -> NotificationAuthorizationOutcome
}
```

Composition의 Adapter가 구현하며, 기술적으로는 Infrastructure의 `LocalNotificationClient`에
위임한다(계약은 `contracts/notification-permission-contracts.md` 참고).

## GenerationReminderRegistry (Domain 계약, 신규)

`sources/Projects/Domain/LearningProject/Contracts/GenerationReminderRegistry.swift`

```swift
public protocol GenerationReminderRegistry: Sendable {
    func register(projectID: String) async
}
```

Composition의 Adapter가 구현하며, `GenerationCompletionReminderCoordinator`(Composition
내부 전용, Domain에 노출되지 않음)의 등록 메서드로 위임한다.

## 리마인드 대상 등록 (Composition 내부 전용 상태, 변경 없음)

`GenerationCompletionReminderCoordinator`가 메모리에 유지하는 `Set<String>`(projectID
집합)이다. 등록·소진 규칙은 다음과 같다.

- `GenerationReminderRegistryAdapter.register(projectID:)`를 거쳐 추가된다(알림 옵션 수락과
  권한 허용이 모두 확인된 시점, `RequestGenerationReminder` UseCase 내부에서 트리거).
- `learningProjectOutcomes()` 스트림에서 같은 `projectID`의 완료(`completed`) 또는
  실패(`failed`) 이벤트를 수신하면 즉시 집합에서 제거한다(FR-010의 프로젝트당 1회 발송 보장).
- 실패(`failed`) 이벤트는 집합에서 제거만 하고 로컬 알림은 발송하지 않는다(FR-008).
- 영속 저장소는 없다. 앱 프로세스가 종료되면 등록 정보도 함께 사라진다(가정 참고).

## 생성 완료 로컬 알림 (Infrastructure 내부 전용, 변경 없음)

`UNUserNotificationCenterLocalNotificationClient.presentGenerationCompletedNotification(
projectID:)`가 구성하는 `UNNotificationRequest`다.

| 필드 | 값 |
| --- | --- |
| `identifier` | `"generation-completed-\(projectID)"` (같은 프로젝트 중복 발송 시 시스템이 대체하도록 projectID 기반 고정 식별자 사용) |
| `content.title` | 생성 완료를 안내하는 고정 문구(`NotificationOptionSheet`의 기존 안내 문구와 일관되게 계획 단계에서 확정) |
| `content.body` | 세트 생성 완료를 안내하는 고정 문구 |
| `trigger` | `nil`(즉시 발송) |

## 재사용하는 기존 Domain 모델(변경 없음)

- `LearningProjectGenerationOutcome`(`projectID: String`, `status: .completed \| .failed`) —
  019가 이미 정의했다. 이 기능은 이 모델을 소비만 하며 필드를 추가하지 않는다.
- `LearningProjectOutcomesUseCase`(`() async -> AsyncStream<LearningProjectGenerationOutcome>`)
  — 019가 이미 정의한 멀티캐스트 계약을 그대로 재사용한다.

## 패키지별 소유 관계 요약

```text
Domain (신규)
├── Models/NotificationAuthorizationOutcome.swift
├── Contracts/NotificationAuthorizationGateway.swift
├── Contracts/GenerationReminderRegistry.swift
└── UseCases/RequestGenerationReminder/
    ├── RequestGenerationReminderUseCase.swift
    └── RequestGenerationReminder.swift
        │ implements ↑ / delegates ↓
Composition (신규)
├── Adapter/Adapters/NotificationAuthorizationGatewayAdapter.swift   (implements NotificationAuthorizationGateway, delegates to Infrastructure)
├── Adapter/Adapters/GenerationReminderRegistryAdapter.swift         (implements GenerationReminderRegistry, delegates to coordinator)
└── Adapter/Factories/GenerationCompletionReminderCoordinator.swift  (Composition 내부 전용, Domain에 미노출)
        │ delegates ↓
Infrastructure (신규, InfrastructurePushMessaging)
└── Clients/LocalNotificationClient.swift, UNUserNotificationCenterLocalNotificationClient.swift
```
