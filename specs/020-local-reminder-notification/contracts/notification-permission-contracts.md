# 계약: 알림 권한 확인·요청과 리마인드 대상 등록

이 문서는 `/speckit-tasks`가 작업으로 분해할 공개 계약을 패키지별로 정의한다. 019가 확립한
"Domain UseCase + Domain 계약 → Composition Adapter가 Infrastructure/내부 조정자에 위임 →
App이 Composition을 Feature에 명시적으로 주입" 형태를 그대로 따른다. Feature는 Infrastructure
결과 타입을 직접 참조하지 않고, 이미 허용된 Domain 의존성(`RequestGenerationReminderUseCase`,
`NotificationAuthorizationOutcome`) 하나만 명시적으로 주입받는다.

## 1. Domain — `DomainLearningProject`

### 1.1 `NotificationAuthorizationOutcome` (신규 모델)

`sources/Projects/Domain/LearningProject/Models/NotificationAuthorizationOutcome.swift`

```swift
public enum NotificationAuthorizationOutcome: Sendable, Equatable {
    case authorized
    case declined
    case previouslyDenied
}
```

### 1.2 `NotificationAuthorizationGateway` (신규 계약)

`sources/Projects/Domain/LearningProject/Contracts/NotificationAuthorizationGateway.swift`

```swift
public protocol NotificationAuthorizationGateway: Sendable {
    func requestAuthorization() async -> NotificationAuthorizationOutcome
}
```

### 1.3 `GenerationReminderRegistry` (신규 계약)

`sources/Projects/Domain/LearningProject/Contracts/GenerationReminderRegistry.swift`

```swift
public protocol GenerationReminderRegistry: Sendable {
    func register(projectID: String) async
}
```

### 1.4 `RequestGenerationReminderUseCase` / `RequestGenerationReminder` (신규 UseCase)

`sources/Projects/Domain/LearningProject/UseCases/RequestGenerationReminder/RequestGenerationReminderUseCase.swift`

```swift
public protocol RequestGenerationReminderUseCase: Sendable {
    func callAsFunction(projectID: String) async -> NotificationAuthorizationOutcome
}
```

`sources/Projects/Domain/LearningProject/UseCases/RequestGenerationReminder/RequestGenerationReminder.swift`

```swift
public struct RequestGenerationReminder: RequestGenerationReminderUseCase, Sendable {
    public init(
        authorizationGateway: any NotificationAuthorizationGateway,
        reminderRegistry: any GenerationReminderRegistry,
    ) {
        self.authorizationGateway = authorizationGateway
        self.reminderRegistry = reminderRegistry
    }

    public func callAsFunction(projectID: String) async -> NotificationAuthorizationOutcome {
        let outcome = await authorizationGateway.requestAuthorization()
        if outcome == .authorized {
            await reminderRegistry.register(projectID: projectID)
        }
        return outcome
    }

    private let authorizationGateway: any NotificationAuthorizationGateway
    private let reminderRegistry: any GenerationReminderRegistry
}
```

**독립 검증**: `DomainLearningProject` Tests target에서 stub `NotificationAuthorizationGateway`/
`GenerationReminderRegistry`로 세 경로(허용 → 등록 호출, 방금 거부 → 등록 미호출, 이미 거부 →
등록 미호출)를 검증한다(기존 `LearningProjectOutcomesTests`와 같은 스타일).

## 2. Infrastructure — `InfrastructurePushMessaging`

### 2.1 `LocalNotificationClient` 프로토콜

`sources/Projects/Infrastructure/PushMessaging/Clients/LocalNotificationClient.swift`(신규)

```swift
public protocol LocalNotificationClient: Sendable {
    /// 현재 권한 상태를 확인하고, 아직 결정되지 않았다면 시스템 권한 요청 다이얼로그를
    /// 표시한다. 이미 거부된 상태라면 다이얼로그 없이 `.previouslyDenied`를 반환한다.
    func requestAuthorization() async -> LocalNotificationAuthorizationOutcome

    /// 로컬 알림을 실제로 보내기 직전에 현재 권한이 허용 상태인지 다시 확인한다.
    func isAuthorized() async -> Bool

    /// 지정한 프로젝트의 생성 완료를 안내하는, 사용자에게 보이는 로컬 알림을 즉시 발송한다.
    func presentGenerationCompletedNotification(projectID: String)
}

public enum LocalNotificationAuthorizationOutcome: Sendable, Equatable {
    case authorized
    case declined
    case previouslyDenied
}
```

`LocalNotificationAuthorizationOutcome`은 Domain의 `NotificationAuthorizationOutcome`과
케이스가 같지만 서로 다른 패키지가 소유하는 독립 타입이다(Data DTO ↔ Domain 모델 변환과
동일하게, Composition Adapter가 1:1로 변환한다). Infrastructure는 Domain을 참조하지 않는다.

### 2.2 `UNUserNotificationCenterLocalNotificationClient` concrete 구현

`sources/Projects/Infrastructure/PushMessaging/Clients/UNUserNotificationCenterLocalNotificationClient.swift`(신규)

- `requestAuthorization()`은 `UNUserNotificationCenter.current().notificationSettings()`로
  현재 `UNAuthorizationStatus`를 조회한다.
  - `.notDetermined` → `requestAuthorization(options: [.alert, .badge, .sound])` 호출 후
    허용 여부에 따라 `.authorized`/`.declined` 반환(에러 발생 시 `.declined`로 처리).
  - `.denied` → 다이얼로그 없이 `.previouslyDenied` 반환.
  - `.authorized`/`.provisional`/`.ephemeral` → `.authorized` 반환.
  - `@unknown default` → `.declined` 반환.
- `isAuthorized()`는 `notificationSettings().authorizationStatus`가
  `.authorized`/`.provisional`/`.ephemeral`일 때만 `true`.
- `presentGenerationCompletedNotification(projectID:)`는 `data-model.md`의 필드 표에 따라
  `UNMutableNotificationContent`와 `identifier: "generation-completed-\(projectID)"`,
  `trigger: nil`인 `UNNotificationRequest`를 구성해 `UNUserNotificationCenter.current().add(_:)`로
  등록한다(완료 핸들러 결과는 무시하되 실패해도 크래시하지 않아야 한다).
- 외부 라이브러리(`UserNotifications`) 타입과 오류는 이 파일 밖으로 노출하지 않는다
  (Infrastructure 제약조건).

**독립 검증**: `InfrastructurePushMessaging` target build로 컴파일만 확인한다(기존
`FirebaseMessagingPushClient`와 동일하게 이 target에는 별도 테스트 target을 만들지 않는다).

## 3. Composition — `Composition`

### 3.1 `GenerationCompletionReminderCoordinator` (신규, Composition 내부 전용)

`sources/Projects/Composition/Adapter/Factories/GenerationCompletionReminderCoordinator.swift`

```swift
actor GenerationCompletionReminderCoordinator {
    init(localNotificationClient: LocalNotificationClient) { ... }

    /// 리마인드 대상으로 등록한다. 이미 완료·실패 처리가 끝난 projectID를 다시 등록해도
    /// 안전해야 한다(다음 신호를 기다리는 새 등록으로 취급).
    func register(projectID: String) { ... }

    /// `learningProjectOutcomes`를 구독하는 프로세스 수명 Task를 시작한다. 같은 인스턴스에서
    /// 두 번 호출되지 않는다(AppComposition.live가 한 번만 호출).
    func start(learningProjectOutcomes: any LearningProjectOutcomesUseCase) { ... }
}
```

- 내부 상태: `Set<String>`(등록된 projectID).
- `start(...)`는 `Task { for await outcome in await learningProjectOutcomes() { ... } }`를
  실행한다. 수신한 `outcome.projectID`가 등록 집합에 있으면 집합에서 제거하고,
  `outcome.status == .completed`이며 `localNotificationClient.isAuthorized()`가 `true`인
  경우에만 `localNotificationClient.presentGenerationCompletedNotification(projectID:)`를
  호출한다. `.failed`는 집합에서 제거만 한다.
- Infrastructure의 외부 라이브러리 concrete 타입(`UNUserNotificationCenter` 등)을 직접
  참조하지 않고 `LocalNotificationClient` 프로토콜로만 접근한다(Composition 제약조건).
- Domain에 노출되지 않는 순수 Composition 내부 구현이다. Domain은 이 타입을 알지 못하고
  `GenerationReminderRegistry` 계약을 통해서만 접근한다.

**독립 검증**: `Composition` Tests target에 stub `LocalNotificationClient`와 스크립트 가능한
`LearningProjectOutcomesUseCase`를 주입해 등록·발송·중복 방지·실패 시 미발송·미등록
projectID 무시를 검증한다(actor라는 이유로 자동화를 생략하지 않는다 — Swift Testing은 이미
`ExternalRepositoryLookupAdapterTests` 등에서 async 테스트를 지원한다).

### 3.2 `NotificationAuthorizationGatewayAdapter` (신규 Domain↔Infrastructure Adapter)

`sources/Projects/Composition/Adapter/Adapters/NotificationAuthorizationGatewayAdapter.swift`

```swift
struct NotificationAuthorizationGatewayAdapter: NotificationAuthorizationGateway {
    let localNotificationClient: any LocalNotificationClient

    func requestAuthorization() async -> NotificationAuthorizationOutcome {
        switch await localNotificationClient.requestAuthorization() {
        case .authorized: .authorized
        case .declined: .declined
        case .previouslyDenied: .previouslyDenied
        }
    }
}
```

### 3.3 `GenerationReminderRegistryAdapter` (신규 Domain↔Composition 내부 Adapter)

`sources/Projects/Composition/Adapter/Adapters/GenerationReminderRegistryAdapter.swift`

```swift
struct GenerationReminderRegistryAdapter: GenerationReminderRegistry {
    let coordinator: GenerationCompletionReminderCoordinator

    func register(projectID: String) async {
        await coordinator.register(projectID: projectID)
    }
}
```

### 3.4 `AppComposition` 신규 공개 표면

`sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`(수정)

```swift
public let requestGenerationReminder: any RequestGenerationReminderUseCase
```

기존 `fetchExternalRepository`, `createLearningProject` 등과 동일한 형태의 명시적 Domain
UseCase 의존성이다(익명 closure가 아니다). `AppComposition.live(...)`가 조립되는 시점에
다음을 수행한다.

1. `UNUserNotificationCenterLocalNotificationClient()`를 생성한다.
2. `GenerationCompletionReminderCoordinator(localNotificationClient:)`를 생성하고
   `coordinator.start(learningProjectOutcomes: learningProject.learningProjectOutcomes)`를
   호출한다(기존 FCM 등록 토큰 `Task`와 같은 위치, `AppComposition.init` 안).
3. `RequestGenerationReminder(
     authorizationGateway: NotificationAuthorizationGatewayAdapter(localNotificationClient:),
     reminderRegistry: GenerationReminderRegistryAdapter(coordinator:),
   )`를 `requestGenerationReminder`로 공개한다.

**독립 검증**: `AppCompositionPublicSurfaceTests`(기존 파일)에
`requestGenerationReminder: any RequestGenerationReminderUseCase` 공개 표면을 검증하는
케이스를 추가한다(019의 `fetchExternalRepository` 등 기존 UseCase 표면 검증과 동일한 방식).

## 4. Feature — `Feature`

### 4.1 `ProjectRegistrationFeature.init` 신규 인자

`sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`(수정)

```swift
public init(
    fetchExternalRepository: any FetchExternalRepositoryUseCase,
    createLearningProject: any CreateLearningProjectUseCase,
    learningProjectOutcomes: any LearningProjectOutcomesUseCase,
    requestGenerationReminder: any RequestGenerationReminderUseCase,
    openNotificationSettings: @escaping @Sendable () async -> Void = { },
)
```

`requestGenerationReminder`는 다른 Domain UseCase 의존성과 동일하게 기본값 없이 필수
인자로 선언한다(기존 `fetchExternalRepository`/`createLearningProject`와 동일한 관례).
`openNotificationSettings`만 기존처럼 App 플랫폼 진입점 closure로 남는다(변경 없음).

### 4.2 `notificationOptionAccepted` 처리 확장

기존(`sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`
현재 133~139번째 줄 부근)은 수락 시 `openNotificationSettings()`만 호출했다. 이를 다음
순서로 바꾼다.

```swift
case .view(.notificationOptionAccepted):
    guard case .awaitingGeneration(let receipt) = state.submission else { return .none }
    state.isNotificationOptionSheetPresented = false
    return .merge(
        .run { [requestGenerationReminder, openNotificationSettings, projectID = receipt.projectID] _ in
            if await requestGenerationReminder(projectID: projectID) == .previouslyDenied {
                await openNotificationSettings()
            }
        },
        finishWaiting(receipt: receipt, notifyAccepted: true),
    )
```

- `requestGenerationReminder(projectID:)` 하나의 호출이 "권한 확인·요청 + 허용 시 리마인드
  등록"을 모두 처리한다(비즈니스 규칙은 Domain의 `RequestGenerationReminder`가 소유).
- 반환값이 `.previouslyDenied`일 때만 기존 `openNotificationSettings()`로 설정 화면을
  안내한다(spec 수용 시나리오 1-2).
- `.authorized`(spec 수용 시나리오 1-1, 1-3)와 `.declined`(spec 수용 시나리오 1-1의 거부 응답)는
  추가 동작 없이 그대로 `홈에서 기다리기` 흐름(`finishWaiting`)만 진행된다.
- 거절(시트에서 거절 선택)이나 시트를 닫는 경우는 기존 `notificationOptionDeclined` 분기
  그대로이며 `requestGenerationReminder`를 호출하지 않는다(변경 없음).

**독립 검증**: `Feature` Tests target에서 stub
`RequestGenerationReminderUseCase`로 세 결과(`.authorized`, `.declined`,
`.previouslyDenied`)를 각각 주입해, `.previouslyDenied`일 때만
`openNotificationSettings`가 호출되는지 검증한다. 기존 `finishWaiting` delegate 출력·상태
전이는 변경하지 않는다.

## 5. App — `GitIt`

### 5.1 `AppRootFeature` 배선

`sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`(수정) — 기존
`openNotificationSettings` 인자 옆에 `requestGenerationReminder: any
RequestGenerationReminderUseCase` 인자를 추가하고, `ProjectRegistrationFeature` 생성
지점(`.ifLet(\.$projectRegistration, ...)`)에 그대로 전달한다.

### 5.2 `GitItApp` 배선

`sources/Projects/App/GitIt/GitItApp.swift`(수정) — `composition.requestGenerationReminder`를
그대로 `AppRootFeature`에 전달한다(다른 UseCase 표면과 동일한 배선 스타일).

```swift
requestGenerationReminder: composition.requestGenerationReminder,
```

**독립 검증**: `AppRootFeature` Tests에 `notificationOptionSelected` delegate 처리 자체는
변경하지 않으므로 기존 테스트가 그대로 통과하는지만 회귀 확인한다.
