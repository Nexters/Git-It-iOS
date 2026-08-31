# 계약: Domain·Data·Infrastructure·Composition 경계

이 문서는 이 기능이 새로 정의하는 패키지 내부 경계 계약을 기록한다. 외부 REST
엔드포인트 계약이 아니라 프로젝트 내부 모듈 간 공개 인터페이스다. 정확한 Swift
선언은 구현 단위에서 확정하며, 여기서는 각 경계가 서로에게 보장해야 하는 행위를
고정한다.

## 1. Domain → 상위 소비자 (Feature) 계약

```swift
public protocol ObserveLearningProjectGenerationOutcomesUseCase: Sendable {
    func callAsFunction() async -> AsyncStream<LearningProjectGenerationOutcome>
}
```

**보장 사항**

- 호출할 때마다 독립적인 새 `AsyncStream`을 반환한다. 이전 호출로 만든 스트림에는
  영향을 주지 않는다(멀티캐스트, 각 소비자가 완전한 이벤트 계열을 받는다).
- 스트림은 소비자가 구독을 취소(`Task` 취소, TCA `cancellable` 종료)할 때까지 값을
  계속 방출할 수 있다. 종료를 명령하는 별도 API는 없다 — 소비자가 구독을 끝낸다.
- 같은 `projectID`에 대해 중복 payload가 도착해도 있는 그대로 전달한다. 멱등 처리
  책임은 소비자(Feature)에 있다(SC-016).
- 시스템 알림 권한 승인 여부와 무관하게 값을 방출한다(명확화 세션 결정).

**소비자 책임**

- `ProjectRegistrationFeature`와 `HomeFeature`는 각각 독립적으로 호출하고, 자신이
  관심 있는 `projectID`만 필터링한다.
- 수신한 이벤트가 이미 처리한 `(projectID, status)` 조합이면 무시한다(멱등).

## 2. Domain 계약 (Composition이 구현)

```swift
public protocol LearningProjectGenerationOutcomeRepository: Sendable {
    func outcomes() async -> AsyncStream<LearningProjectGenerationOutcome>
}
```

`ObserveLearningProjectGenerationOutcomes`가 유일한 호출자다. Composition의
`LearningProjectGenerationOutcomeRepositoryAdapter`가 구현하며 Data DTO를 Domain
모델로 변환한다(알 수 없는 `status` 원시값은 Domain에 전달하지 않고 폐기한다 —
`RawStatus`가 `completed`/`failed` 외 값을 가지면 무시).

## 3. Data 계약 (Composition이 소비, Infrastructure에 의존)

```swift
protocol ProjectGenerationOutcomeRemote: Sendable {
    func outcomes() -> AsyncStream<ProjectGenerationOutcomeDTO>
}
```

**구현체**: `PushProjectGenerationOutcomeRemote`(actor)

- `outcomes()`: 새 continuation을 등록한 `AsyncStream`을 즉시 반환한다(비동기 대기
  없음).
- `func ingest(rawPayload: [String: String]) async`: `AppComposition.ingestPushPayload`
  closure(§5)만 호출하는 진입점. `rawPayload`를 `ProjectGenerationOutcomeDTO`로
  디코딩할 수 있을 때만 등록된 모든 continuation에 `yield`한다.
- 디코딩 실패, 알 수 없는 키 조합은 조용히 폐기한다(원인별 분기 없이 판정 자체를
  내리지 않음 — 예외·경계 사례와 구분되는 "해석 불가능" 케이스).

## 4. Infrastructure 계약 (Composition이 소비)

```swift
public protocol PushMessagingClient: Sendable {
    func registrationToken() async throws -> String
    func setAPNsToken(_ token: Data)
}
```

**구현체**: `FirebaseMessagingPushClient`(내부적으로만 `NSObject`, `MessagingDelegate` 채택)

- `registrationToken()`은 FCM 등록 토큰을 비동기로 반환한다. 토큰이 아직 없으면
  내부 `MessagingDelegate.messaging(_:didReceiveRegistrationToken:)` 콜백이 올
  때까지 대기한다(`CheckedContinuation`으로 콜백을 async API로 변환).
- `setAPNsToken(_:)`은 전달받은 APNs 디바이스 토큰을
  `Messaging.messaging().apnsToken`에 대입한다. 호출부(App의
  `GitItAppDelegate`)는 FirebaseMessaging SDK 타입을 전혀 알 필요가 없다.
- `FirebaseMessagingPushClient`는 자기 초기화 시점에
  `Messaging.messaging().delegate = self`를 등록한다. `MessagingDelegate` 채택은
  이 타입 밖으로 노출되지 않으며, Composition·App 어디에도 FirebaseMessaging SDK
  타입이 나타나지 않는다.

## 5. Composition 조립 계약

### `LearningProjectGenerationOutcomeRepositoryAdapter`

```swift
struct LearningProjectGenerationOutcomeRepositoryAdapter: LearningProjectGenerationOutcomeRepository {
    init(remote: ProjectGenerationOutcomeRemote)
    func outcomes() async -> AsyncStream<LearningProjectGenerationOutcome>
}
```

### `AppComposition`이 노출하는 push 관련 표면

```swift
extension AppComposition {
    public var observeLearningProjectGenerationOutcomes: any ObserveLearningProjectGenerationOutcomesUseCase { get }
    public var forwardAPNsToken: @Sendable (Data) -> Void { get }
    public var ingestPushPayload: @Sendable ([String: String]) async -> Void { get }
}
```

**보장 사항**

- `forwardAPNsToken`은 내부적으로 `pushClient.setAPNsToken(_:)`에 위임한다.
- `ingestPushPayload`는 내부적으로 Data 허브(`PushProjectGenerationOutcomeRemote`)의
  `ingest(rawPayload:)`에 위임한다.
- Composition은 `UIApplicationDelegate`, `MessagingDelegate`,
  `UNUserNotificationCenterDelegate` 중 어느 것도 채택하지 않는다. 두 closure만
  노출해 App이 플랫폼 콜백을 그대로 연결할 수 있게 한다.
- `AppComposition.live(...)`가 인스턴스를 구성하는 시점에 Composition은
  `Task { let token = try await pushClient.registrationToken();
  await registerMemberDevice(MemberDeviceInfo(deviceToken: token, ...)) }`를
  직접 시작한다. 이 Task는 AppDelegate 콜백과 독립적으로 동작하며, 실패 시
  재시도 정책은 다음 앱 실행이나 토큰 재발급 시 자연히 재시도되는 것으로
  충분하다(이번 기능에서 별도 재시도 루프를 만들지 않는다).

## 6. App 조립 계약 — `GitItAppDelegate`

```swift
public final class GitItAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    public static func configure(
        forwardAPNsToken: @escaping @Sendable (Data) -> Void,
        ingestPushPayload: @escaping @Sendable ([String: String]) async -> Void,
    )
    // UIApplicationDelegate
    public func application(_:didFinishLaunchingWithOptions:) -> Bool
    public func application(_:didRegisterForRemoteNotificationsWithDeviceToken:)
    // UNUserNotificationCenterDelegate (silent push 배지·사운드 부가 표시는 처리하지 않음)
    public func application(_:didReceiveRemoteNotification:fetchCompletionHandler:)
}
```

`GitItAppDelegate`는 `MessagingDelegate`를 채택하지 않으며 FirebaseMessaging SDK를
import하지 않는다.

**보장 사항**

- `configure(...)`가 호출되기 전에 도착하는 delegate 콜백은 no-op으로 무시하고
  로그만 남긴다(크래시하지 않는다).
- `didRegisterForRemoteNotificationsWithDeviceToken`을 받으면 즉시
  `forwardAPNsToken(deviceToken)`을 호출한다.
- `didReceiveRemoteNotification`(silent push)을 받으면 raw payload를
  `[String: String]`으로 정규화해 `ingestPushPayload(...)`를 호출한 뒤
  `fetchCompletionHandler(.newData)`를 호출한다.
- 디바이스 등록 토큰 처리(`registerMemberDevice` 호출)는 이 타입의 책임이
  아니다 — Composition이 §5의 Task로 직접 처리한다.

## 7. `GitItApp`/`AppRootFeature`와의 연결 계약

- `GitItApp.init()`은 `AppComposition.live(...)` 직후,
  `GitItAppDelegate.configure(forwardAPNsToken:ingestPushPayload:)`를 호출한
  뒤에만 `rootStore`를 생성한다.
- `GitItApp`은 `@UIApplicationDelegateAdaptor(GitItAppDelegate.self) var
  appDelegate`를 선언한다.
- `AppRootFeature`는 `AppComposition.observeLearningProjectGenerationOutcomes`를
  `ProjectRegistrationFeature`와 `MainShellFeature`(경유해 `HomeFeature`)
  initializer에 동일하게 주입한다.
