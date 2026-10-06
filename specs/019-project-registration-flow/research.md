# 조사: 프로젝트 등록·학습 세트 생성 흐름

## 1. 등록 흐름을 Router-Feature로 분리할지, 기존 `ProjectRegistrationFeature`를 확장할지

- **결정**: 기존 `ProjectRegistrationFeature`(단일 Reducer)를 확장한다. Router-Feature
  ([TCA 컨벤션 §7.3](../../docs/conventions/tca.md))는 만들지 않는다.
- **근거**: 현재 `ProjectRegistrationFeature.State`는 이미 URL 입력, 검증 상태,
  `QuizLevel` 선택, 제출 상태를 하나의 State로 소유하며 Figma의 링크 입력·레포 확인·
  이해도 선택 화면은 이 State에서 파생되는 화면 분기일 뿐 독립적인 비동기 수명이나
  재사용 단위가 아니다([TCA 컨벤션 §3.1](../../docs/conventions/tca.md)의 "같은 논리
  화면의 loading, loaded, confirmation은 하나의 Feature가 소유하는 State 변형"에
  해당). 생성 진행 국면(체크리스트, `홈에서 기다리기`, 알림 옵션)도 같은 제출 결과의
  후속 상태이며 별도 Child Feature로 분리할 독립적 오류·재시도 수명이 없다.
- **검토한 대안**: Router-Feature로 5개 화면을 순차 Child Feature로 묶는 방안 — 각
  화면이 독립된 State 소유자가 아니라 기각. 완전히 새 Feature로 재작성하는 방안 —
  기존 계약(`ProjectRegistrationFeature.Action.Delegate.projectRegistered`)과
  `AppRootFeature`/테스트 자산을 무의미하게 깨뜨려 기각.

## 2. 생성 진행 화면의 완료·실패 판정을 어디서 관찰할지 (Home과 등록 화면이 동시에 필요)

- **결정**: Domain에 새 관찰 계약 `ObserveLearningProjectGenerationOutcomesUseCase`를
  추가한다. `func callAsFunction() async -> AsyncStream<LearningProjectGenerationOutcome>`
  형태로 기존 `ObserveAuthenticationOutcomesUseCase` 패턴을 그대로 따른다.
  `ProjectRegistrationFeature`와 `HomeFeature`는 각각 독립적으로 이 Use Case를
  호출해 자신만의 `AsyncStream`을 받는다(같은 Use Case 인스턴스를 두 Feature
  initializer에 동일하게 주입).
- **근거**: 두 Feature가 동시에 살아있는 구간(제출 성공 → `홈에서 기다리기` 이전)과
  한 Feature만 살아있는 구간(그 이후 Home만)이 모두 존재하므로 단일 소비자
  `AsyncStream`으로는 부족하다. 여러 구독자가 각자 스트림을 받을 수 있어야 하므로
  공급 측(Data 계층의 허브)이 멀티캐스트를 책임진다.
- **검토한 대안**: `MainShellFeature` 또는 `AppRootFeature`가 하나의 스트림을 구독해
  자식에게 input Action으로 전파하는 방식 — 등록 흐름이 `AppRootFeature`의 `@Presents`
  자식이고 Home은 `MainShellFeature`의 상시 자식이라 라우팅 경로가 복잡해지고
  "Feature는 Domain dependency를 initializer로 받는다"는 기존 패턴과도 어긋나
  기각. 폴링 API 신설 — SC-010이 명시적으로 금지.

## 3. Data 계층의 멀티캐스트 허브 설계

- **결정**: `Data/LearningProject`에 actor 기반 허브
  `PushProjectGenerationOutcomeRemote: ProjectGenerationOutcomeRemote`를 추가한다.
  내부에 `[UUID: AsyncStream<ProjectGenerationOutcomeDTO>.Continuation]`을 보관하고,
  `outcomes()` 호출마다 새 `AsyncStream`을 만들어 등록하며, `ingest(rawPayload:)`가
  호출되면 보관 중인 모든 continuation에 동일한 값을 `yield`한다. 구독이 끝나면
  `onTermination`에서 등록을 해제한다.
- **근거**: 여러 구독자가 각자 완전한 이벤트를 받아야 하고(멱등 처리는 상위
  Feature/Home이 프로젝트 ID 기준으로 판단), 프로세스 메모리 내에서만 유효하면
  충분하다(영속 저장소 불필요, 명세의 "저장소: N/A"와 일치).
- **검토한 대안**: `NotificationCenter` 기반 브로드캐스트 — 외부 프레임워크 API가
  Data 계층에 새며 [Data 패키지 규칙]의 "Swift Standard Library"만 의존한다는 제약과
  충돌해 기각. Combine `PassthroughSubject` — 같은 이유로 프로젝트 표준(TCA는 이미
  `AsyncStream` 관용구를 `ObserveAuthenticationOutcomes`에서 확립)과 불일치해 기각.

## 4. Infrastructure의 Firebase Cloud Messaging 통합 범위

- **결정**: `Infrastructure`에 새 역할 폴더 `PushMessaging/`을 추가하고(기존
  `Authentication/`, `NetworkClient/`, `Storage/`, `Cache/`와 같은 결로 존재하는
  target 내부 폴더), `PushMessagingClient` 프로토콜(`registrationToken() async
  throws -> String`, `setAPNsToken(_:)`)과 이를 구현하는 `FirebaseMessagingPushClient`를
  둔다. `FirebaseMessagingPushClient`는 자기 초기화 시점에
  `Messaging.messaging().delegate = self`를 등록해 `MessagingDelegate` 채택
  자체를 Infrastructure 안에 완전히 가둔다 — 다른 어떤 패키지도 FirebaseMessaging
  SDK 타입을 직접 참조하지 않는다. 새 Tuist target은 만들지 않고 기존
  Infrastructure target에 소스만 추가한다(기존 `InfrastructureAuthentication`처럼
  별도 target으로 쪼갤 만큼 독립적인 소비자가 아직 없음).
- **근거**: `firebase-ios-sdk`는 이미 `sources/Tuist/Package.swift`에 워크스페이스
  의존성으로 선언되어 있으나 어떤 target도 소비하지 않는다. `FirebaseMessaging`
  product를 Infrastructure target의 의존성에 추가하면 되고, [아키텍처 문서
  6절]의 "Infrastructure: 허용 — 담당 기술 기능 구현에 필요한 외부 라이브러리를
  사용"과 일치한다. `MessagingDelegate`를 Infrastructure 밖(Composition·App)에
  노출하지 않는 것은 [아키텍처 문서]의 "Composition의 외부 기술 사용은
  Infrastructure API를 통해 수행"과 App의 "플랫폼 생명주기 담당"이 서로 다른
  패키지의 책임임을 지키기 위함이다(항목 5와 함께 `/speckit-analyze`가 지적한
  경계 위반의 근본 수정).
- **검토한 대안**: Composition에서 직접 `FirebaseMessaging`을 import — Composition의
  "외부 기술 사용은 Infrastructure API를 통해 수행" 정책과 충돌해 기각. 최초 설계처럼
  Composition이 소유하는 `AppDelegate` 타입이 `MessagingDelegate`까지 채택 — 같은
  이유로 기각(아래 항목 5 참고).

## 5. `UIApplicationDelegateAdaptor`와 생성자 주입(FR-017)·패키지 경계의 동시 충족

- **문제**: `@UIApplicationDelegateAdaptor`는 SwiftUI가 delegate 타입을 기본
  초기화자로 직접 생성하므로, `registerMemberDevice` Use Case와 Data 허브의
  `ingest` 진입점을 생성자로 주입할 수 없다. 또한 플랫폼 생명주기
  (`UIApplicationDelegate`)는 [아키텍처 문서](../../docs/architecture.md)가 App의
  책임으로 명시하고, Composition은 외부 기술(FirebaseMessaging SDK 등)을
  Infrastructure API를 통해서만 사용해야 하므로 하나의 타입이 두 책임(플랫폼
  생명주기 + FirebaseMessaging SDK 직접 채택)을 동시에 가지면 안 된다. 최초 설계
  (`PushRegistrationAppDelegate`를 Composition이 소유하고
  `UIApplicationDelegate`/`MessagingDelegate`를 함께 채택)는 `/speckit-analyze`
  점검에서 이 두 제약을 모두 위반한 것으로 확인됐다.
- **결정**: 책임을 세 패키지로 분리한다.
  1. **Infrastructure**: `FirebaseMessagingPushClient`가 `MessagingDelegate`를
     전담하고, `PushMessagingClient` 프로토콜로 `registrationToken()`과
     `setAPNsToken(_:)`만 노출한다(항목 4).
  2. **Composition**: `AppComposition`이 `forwardAPNsToken: @Sendable (Data) ->
     Void`(`pushClient.setAPNsToken(_:)` 위임)와 `ingestPushPayload: @Sendable
     ([String: String]) async -> Void`(Data 허브 `ingest(rawPayload:)` 위임) 두
     closure만 공개 프로퍼티로 노출한다. UIKit·Firebase 프로토콜은 채택하지 않는다.
  3. **App**: 신규 `GitItAppDelegate`(`NSObject`, `UIApplicationDelegate`,
     `UNUserNotificationCenterDelegate` — `MessagingDelegate`는 채택하지 않음)에
     `configure(forwardAPNsToken:ingestPushPayload:)` 정적 설정 지점을 두고,
     `GitItApp.init()`이 `AppComposition.live(...)` 호출 직후 가장 먼저 이 설정을
     호출한다. `didRegisterForRemoteNotificationsWithDeviceToken`은
     `forwardAPNsToken(deviceToken)`을, silent push
     `didReceiveRemoteNotification`은 payload를 `[String: String]`으로 정규화해
     `ingestPushPayload(...)`를 호출한 뒤 `.newData`를 반환한다. SwiftUI는
     `App.init()`을 실행한 뒤에야 `application(_:didFinishLaunchingWithOptions:)`를
     호출하므로 delegate 메서드가 실행되는 시점에는 항상 설정이 끝나 있다. 설정 전
     delegate 콜백이 오는 경로는 없다고 간주하되, 방어적으로 설정 전 호출은
     무시(no-op)하고 로그만 남긴다.
- **근거**: TCA Dependencies의 `@Dependency`나 전역 mutable container를 쓰지 않고도
  플랫폼이 강제하는 `AppDelegate` 인스턴스화 시점 문제를 해결하는 표준적인 방법이며,
  이 static 설정 지점은 production 의존성을 여러 곳에서 조회하는 Service Locator가
  아니라 단일 조립 시점에 한 번만 값을 채우는 좁은 통로다(FR-017과 배치되지 않음).
  동시에 각 패키지가 아키텍처 문서가 정한 책임(Infrastructure=SDK 접촉,
  Composition=Adapter·조립, App=플랫폼 생명주기)만 소유하게 되어 최초 설계의 경계
  위반이 사라진다.
- **검토한 대안**: `UIApplicationDelegateAdaptor` 없이 `.onOpenURL`/`.task`만으로
  처리 — silent push의 `application(_:didReceiveRemoteNotification:
  fetchCompletionHandler:)`는 AppDelegate 콜백이 유일한 진입점이라 불가능.
  Composition이 `UIApplicationDelegate`까지 소유(최초 설계) — 아키텍처 문서가
  플랫폼 생명주기를 App 책임으로 명시하므로 기각.

## 6. 디바이스 등록(FR-023)과 기존 `RegisterMemberDeviceUseCase`의 관계

- **결정**: 새 Use Case를 만들지 않는다. AppDelegate 콜백과는 완전히 분리해,
  `AppComposition.live(...)`가 인스턴스를 만드는 시점에 Composition이 직접
  `Task { let token = try await pushClient.registrationToken();
  await registerMemberDevice(MemberDeviceInfo(deviceToken: token, ...)) }`를
  시작한다. `registrationToken()`은 Infrastructure 내부의
  `MessagingDelegate.messaging(_:didReceiveRegistrationToken:)` 콜백이 올 때까지
  `CheckedContinuation`으로 대기하므로, 이 Task는 토큰이 실제로 발급될 때까지
  자연히 기다린 뒤 한 번만 등록을 수행한다.
- **근거**: `Domain/Member`에 이미 `RegisterMemberDeviceUseCase`/`MemberDeviceInfo`
  (`deviceToken: String?` 필드 포함)와 `AppComposition.registerMemberDevice`가
  존재하지만 어떤 화면·진입점도 아직 호출하지 않는다. 이 기능이 최초 소비자가 된다.
  등록 토큰 처리를 AppDelegate 콜백에서 분리하면 `GitItAppDelegate`가
  `MessagingDelegate`를 채택할 필요가 완전히 사라져 항목 5의 경계 분리가 더
  단순해진다.
- **검토한 대안**: 새 Domain 계약 신설 — 기존 계약이 정확히 이 책임을 이미 표현하고
  있어 불필요한 중복. `GitItAppDelegate`가 `MessagingDelegate`를 채택해 토큰 수신
  즉시 등록 — 항목 5가 기각한 최초 설계와 같은 경계 위반이라 기각.

## 7. 알림 옵션 시트(FR-014/015)의 상태 표현

- **결정**: `@Presents` 대신 `ProjectRegistrationFeature.State`에
  `var isNotificationOptionSheetPresented = false`(단순 Bool)를 추가한다.
- **근거**: [TCA 컨벤션 §4.2](../../docs/conventions/tca.md)는 "payload가 없고 실제로
  두 경우만 존재하는 표현 상태"에 `Bool` 사용을 허용한다. 시트는 고정 문구와 수락/거절
  두 선택지만 가지며 별도 비동기 수명이나 오류 상태가 없다.
- **검토한 대안**: 별도 Destination enum — 페이로드가 없어 과설계로 판단해 기각.

## 8. Figma 시각 근거와 UIComponent 재사용

- **결정**: 계획 단계에서 픽셀 값을 추정하지 않는다. 각 화면 구현 시
  `.agents/skills/implement-figma-ui` 스킬로 지정된 Figma node(`986:13739`/
  `986:13646`, `737:10890`, `737:10882`/`737:10874`, `737:10830`, `737:10800`/
  `824:12149`)를 직접 조회해 기존 UIComponent·DesignSystem 토큰과 대조한다
  (FR-018/021).
- **근거**: Constitution과 AGENTS.md가 "Figma 노드 근거 없이 레이아웃 값을 추정해
  구현하지 않는다"를 명시하며, 이 판단은 구현 단위 착수 시점에 실제 노드를 조회해야만
  가능하다.
