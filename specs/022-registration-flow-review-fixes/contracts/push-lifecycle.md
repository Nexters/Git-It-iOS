# 계약: 푸시 수명과 기기 등록 경계

**기능 브랜치**: `feature/registration-flow-review-fixes`

FR-013 ~ FR-018이 요구하는 경계를 정의한다. 아키텍처 §3.1의 의존 방향(App → Composition,
Composition → Infrastructure, App ↛ Infrastructure)을 지킨다.

## 1. Infrastructure가 노출하는 계약

### `PushMessagingClient`

```text
func registrationToken() async throws -> String
func setAPNsToken(_ token: Data)
func registrationTokenRefreshes() -> AsyncStream<String>   // 신규
```

`registrationTokenRefreshes()`는 `MessagingDelegate.didReceiveRegistrationToken`이 보고하는 갱신을
방출한다. 최초 발급은 `registrationToken()`이 담당하므로 이 스트림은 갱신만 다룬다.

### `PushNotificationCallbacks`

```text
forwardAPNsToken: @Sendable (Data) -> Void
ingestGenerationOutcomePayload: @Sendable ([String: String]) async -> Void
```

### `FirebaseMessagingAppDelegate`

```text
func configure(_ callbacks: PushNotificationCallbacks)   // 인스턴스 메서드
```

**수명 규칙**

1. 콜백은 인스턴스가 소유한다. static 저장소를 사용하지 않는다(FR-017).
2. `configure(_:)` 이전에 도착한 remote notification payload는 인스턴스 범위 대기 슬롯에 보관하고
   `configure(_:)` 직후 정확히 1회 전달한다.
3. `configure(_:)`를 두 번 호출하면 마지막 콜백이 유효하다. 대기 슬롯은 첫 전달 후 비운다.

## 2. Composition이 노출하는 경계 값

```text
AppComposition.bootstrap:              @Sendable () async -> Void
AppComposition.registerCurrentDevice:  @Sendable () async throws -> Void
AppComposition.deviceTokenRefreshes:   @Sendable () -> AsyncStream<Void>
AppComposition.ingestGenerationOutcomePayload: @Sendable ([String: String]) async -> Void
```

**`bootstrap()` 순서 계약 (FR-013, FR-013a)**

1. 푸시 client 생성과 외부 SDK 구성
2. AppDelegate에 `PushNotificationCallbacks` 주입
3. 리마인드 구독 확립 완료까지 `await`

`bootstrap()`이 반환하면 리마인드 구독이 확립돼 있어야 한다. `AppComposition` initializer는 어떤
`Task`도 시작하지 않는다.

**`registerCurrentDevice()` 계약 (FR-014, FR-015)**

- 호출 시점은 App이 결정한다. Composition은 시점을 판단하지 않는다.
- 실패는 `throws`로 전달한다. 내부에서 삼키지 않는다.
- 멱등하지 않다. 중복 호출 방지는 호출자 책임이다.

## 3. App이 소유하는 시점 판단

| 사건 | 동작 |
| --- | --- |
| 앱 시작 | `bootstrap()`을 `await`한 뒤 나머지 흐름 진행 |
| 세션 복원 성공 | `registerCurrentDevice()` 호출 |
| 로그인 성공 | `registerCurrentDevice()` 호출 |
| `deviceTokenRefreshes()` 방출 | 인증 세션이 있으면 최신 token으로 `registerCurrentDevice()`를 재호출 |
| `registerCurrentDevice()` 실패 | 실패를 상태로 기록한다. 조용히 무시하지 않는다 |
| 실패 후 앱 활성화 | 인증 세션이 유지되면 최신 token으로 재시도 |
| 실패 후 token 갱신 | 갱신 token으로 재시도 |
| 앱 활성화·token 갱신 동시 발생 | 등록 Effect 하나만 실행해 서버 요청을 1회로 제한 |
| 로그아웃·인증 종료 | 실패 상태와 진행 중인 등록 Effect를 제거하고 재등록을 시도하지 않는다 |

## 4. 테스트 대체 가능성 (FR-018)

- `AppComposition`의 객체 생성만으로 외부 푸시 SDK 접근, Keychain read/write와 서버 호출이
  발생하지 않아야 한다.
- 푸시 전달 경로는 `PushMessagingClient` 구현 교체로 대체할 수 있어야 한다.
- 전역 static 상태가 없으므로 테스트 간 누수가 없어야 한다.
- 실패 후 앱 활성화·token 갱신 재시도와 동시 trigger 직렬화는 `AppRootFeatureTests`에서
  외부 SDK·Keychain 접근 없이 검증할 수 있어야 한다.

기존 [`GitItCompositionLifetimeTests.swift`](../../../sources/Projects/App/Tests/GitIt/GitItCompositionLifetimeTests.swift)를
이 계약 검증에 사용한다.
