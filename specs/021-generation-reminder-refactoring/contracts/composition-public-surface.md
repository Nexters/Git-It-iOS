# 계약: CompositionAdapter 공개 표면

**기능 브랜치**: `feature/generation-reminder-refactoring`

**적용 요구사항**: FR-008, FR-009, FR-010, FR-011, FR-012

이 문서는 App이 의존하는 Composition 공개 표면의 변경 전후를 고정한다. Composition은
Infrastructure 객체와 내부 Adapter를 공개 API에 노출하지 않는다
(`docs/package-rules/composition.md`).

## 1. 조립과 실행의 분리

### 변경 전

`AppComposition`의 private init이 그래프 조립 외에 다음을 **실행**한다.

| 위치 | 부작용 |
| --- | --- |
| `AppComposition.swift:56` | 취소 핸들 없는 `Task`로 생성 결과 관찰 시작 |
| `AppComposition.swift:69` | `PushNotificationAppDelegate.configure(...)` — 전역 static 상태 쓰기 |
| `AppComposition.swift:78` | `Task`로 FCM 토큰 발급 후 서버에 기기 등록 (네트워크 호출) |

결과적으로 `AppComposition.live(...)` 호출만으로 서버에 기기가 등록된다.
`AppCompositionPublicSurfaceTests`가 이 타입을 생성하므로 테스트가 실제 부작용 경로를 건드린다.

### 변경 후

```swift
public struct AppComposition: Sendable {
    public static func live(
        _ environment: Environment,
        keychainStore: KeychainStore = KeychainStore(),
        transport: (any HTTPTransport)? = nil,
    ) -> AppComposition          // 조립만. 부작용 없음.

    /// 생성 결과 관찰, 푸시 콜백 배선과 기기 등록을 시작한다.
    /// 반환한 핸들을 폐기하면 시작한 백그라운드 작업이 취소된다.
    @discardableResult
    public func start() -> AppCompositionRuntime
}

public struct AppCompositionRuntime: Sendable {
    public func cancel()
}
```

**불변 조건**

- `live(...)`가 반환할 때까지 네트워크 호출·전역 상태 쓰기·백그라운드 작업 시작이 0건이다
  (SC-004).
- `start()`를 호출하지 않으면 리마인드 관찰과 기기 등록이 시작되지 않는다.
- `start()`가 시작한 작업은 반환 핸들로 취소할 수 있다(FR-009).

**호출 위치**: `App/GitIt/GitItApp.swift`의 `init`에서 조립 후 `start()`를 호출한다.

## 2. 플랫폼 생명주기 delegate

### 변경 전

```swift
// Composition/Adapter/Factories/PushNotificationAppDelegate.swift
public typealias PushNotificationAppDelegate = FirebaseMessagingAppDelegate
```

`FirebaseMessagingAppDelegate`(Infrastructure 구체 타입)를 Composition 공개 API로 승격한다.
App은 이 이름을 통해 Infrastructure 타입을 직접 다루게 된다.

### 변경 후

```swift
// Composition/Adapter/AppDelegates/PushNotificationAppDelegate.swift
public final class PushNotificationAppDelegate: NSObject, UIApplicationDelegate {
    override public init()
    // UIApplicationDelegate 콜백을 내부 Infrastructure delegate에 위임한다.
}
```

**핵심**: `FirebaseMessagingAppDelegate`는 이 파일 안에서만 참조되며 Composition 공개 API에
나타나지 않는다(FR-011).

**App이 App으로 옮길 수 없는 이유**: `docs/architecture.md:69`의 허용 의존성 표에서 App의
의존성은 `Feature, Composition, Domain`이다. Infrastructure가 없으므로 App이
`FirebaseMessagingAppDelegate`를 상속·참조할 수 없다(R-001).

**형태 폴더**: `Composition/Adapter/AppDelegates/`. 이 어휘는 현재
`docs/conventions/file-vocabulary.md` §3의 Composition 행에 없으므로 **같은 변경에서 표에
행을 추가**한다(FR-012, R-002).

| 소스 루트 | 형태 폴더 | 담는 선언 |
| --- | --- | --- |
| `Composition/Adapter/` | `AppDelegates/` | 플랫폼 생명주기 delegate 타입 |

## 3. 리마인드 스케줄러

### 변경 전

```swift
// Composition/Adapter/Factories/GenerationCompletionReminderCoordinator.swift
actor GenerationCompletionReminderCoordinator {
    init(localNotificationClient: any LocalNotificationClient)
    func register(projectID: String)
    func start(learningProjectOutcomes: any LearningProjectOutcomesUseCase)
    func waitUntilObservationFinished() async    // 테스트 전용
}

// Composition/Adapter/Adapters/GenerationReminderRegistryAdapter.swift
struct GenerationReminderRegistryAdapter: GenerationReminderRegistry { /* 순수 위임 */ }
```

### 변경 후

```swift
// Composition/Adapter/Assemblies/GenerationReminderScheduler.swift
actor GenerationReminderScheduler: GenerationReminderRegistry {
    init(localNotificationClient: any LocalNotificationClient)

    func register(projectID: String) async          // GenerationReminderRegistry 직접 구현

    @discardableResult
    func start(observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase)
        -> Task<Void, Never>                        // 테스트는 이 반환값을 await 한다
}
```

**변경 요지**

- `GenerationReminderRegistryAdapter`를 삭제하고 스케줄러가 Domain 계약을 직접 구현한다.
  어댑터에 변환이 없어 존재 이유가 없다(FR-013).
- `waitUntilObservationFinished()`를 제거한다. `start(...)`가 반환하는 `Task`를 테스트가
  `await`하면 같은 목적을 달성하며 production 공개 API에 테스트 전용 연산이 남지 않는다
  (FR-010).
- 형태 폴더를 `Factories/`(“구현 선택과 생성”)에서 `Assemblies/`(“조립 진입 타입과 객체 수명
  선택”)로 옮긴다. 이 타입은 관찰 Task의 수명과 등록 집합을 소유한다(FR-012).

**판정 로직**(변경 없음, R-006에 따라 Composition 유지)

1. 등록 집합에서 `projectID`를 제거한다. 없으면 무시한다.
2. 상태가 `completed`가 아니면 발송하지 않는다.
3. 알림 권한이 없으면 발송하지 않는다.
4. `LocalNotificationRequest`를 만들어 `present(_:)`에 넘긴다.

**알림 값 생성**(신규 소유, R-003)

| 필드 | 값 |
| --- | --- |
| `identifier` | `"generation-completed-\(projectID)"` |
| `title` | `"세트 생성 완료"` |
| `body` | `"학습 세트 생성이 완료됐어요. 지금 확인해보세요."` |

형식과 내용 모두 현재와 동일하다. 생성 위치만 Infrastructure에서 Composition으로 옮긴다.

## 4. 노출 UseCase 표면

| 프로퍼티 | 변경 전 타입 | 변경 후 타입 |
| --- | --- | --- |
| `learningProjectOutcomes` | `any LearningProjectOutcomesUseCase` | — *(이름 변경)* |
| `observeGenerationOutcomes` | — | `any ObserveGenerationOutcomesUseCase` |
| `requestGenerationReminder` | `any RequestGenerationReminderUseCase` | *(유지, 계약 축소)* |
| `notificationAuthorizationStatus` | — | `any NotificationAuthorizationStatusUseCase` *(신규)* |

## 5. Adapter 이름

| 변경 전 | 변경 후 |
| --- | --- |
| `LearningProjectGenerationOutcomeRepositoryAdapter` | `GenerationOutcomeRepositoryAdapter` |
| `NotificationAuthorizationGatewayAdapter` | *(유지)* |
| `GenerationReminderRegistryAdapter` | *(삭제)* |

`NotificationAuthorizationGatewayAdapter`는 Infrastructure enum → Domain enum 변환을 실제로
수행하므로 유지한다. 현재 이 변환에 테스트가 없으므로 세 분기를 모두 검증하는 테스트를
추가한다(FR-017).
