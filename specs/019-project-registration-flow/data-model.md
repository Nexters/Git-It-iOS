# 데이터 모델: 프로젝트 등록·학습 세트 생성 흐름

## 신규 Domain 모델

### `LearningProjectGenerationOutcome` (`Domain/LearningProject`)

서버가 FCM으로 전달하는 학습 세트 생성 완료·실패 신호를 표현하는 Domain 정본. 공급자
중립 이름을 쓰며 "FCM"·"Firebase"라는 단어를 포함하지 않는다.

| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `projectID` | `String` | `ProjectRegistrationReceipt.projectID`와 동일 발급 주체의 프로젝트 식별자 |
| `status` | `Status` | 아래 열거형 |

```swift
public struct LearningProjectGenerationOutcome: Equatable, Sendable {
    public enum Status: Equatable, Sendable {
        case completed
        case failed
    }
    public let projectID: String
    public let status: Status
}
```

**불변식**: `projectID`는 비어 있지 않다(Data 계층의 디코딩 단계에서 검증하며, 검증
실패 payload는 Domain에 전달하지 않고 무시한다 — 예외·경계 사례의 "원인 불문 재시도
가능 실패"와는 별개로, 애초에 해석 불가능한 payload는 완료·실패 어느 쪽으로도
해석하지 않는다).

## 신규 Domain 계약

### `LearningProjectGenerationOutcomeRepository`

```swift
public protocol LearningProjectGenerationOutcomeRepository: Sendable {
    func outcomes() async -> AsyncStream<LearningProjectGenerationOutcome>
}
```

호출마다 독립적인 새 `AsyncStream`을 반환해 여러 구독자(등록 흐름 화면, Home)가 각자
완전한 이벤트 계열을 받을 수 있어야 한다(멀티캐스트).

### `ObserveLearningProjectGenerationOutcomesUseCase`

```swift
public protocol ObserveLearningProjectGenerationOutcomesUseCase: Sendable {
    func callAsFunction() async -> AsyncStream<LearningProjectGenerationOutcome>
}

public struct ObserveLearningProjectGenerationOutcomes: ObserveLearningProjectGenerationOutcomesUseCase {
    public init(repository: any LearningProjectGenerationOutcomeRepository) { … }
    public func callAsFunction() async -> AsyncStream<LearningProjectGenerationOutcome> {
        await repository.outcomes()
    }
}
```

`ObserveAuthenticationOutcomesUseCase`/`ObserveAuthenticationOutcomes`와 동일한 형태.

## 신규 Data 계약·모델 (`Data/LearningProject`)

### `ProjectGenerationOutcomeDTO`

```swift
struct ProjectGenerationOutcomeDTO: Equatable, Sendable {
    let projectID: String
    let status: RawStatus
    enum RawStatus: String { case completed, failed }
}
```

silent push의 `[String: String]` payload에서 프로젝트 식별자 키와 상태 키를 읽어
디코딩한다. 정확한 키 이름은 백엔드 payload 계약에 따라 구현 시 확정한다(연구 항목
아님 — 구현 단위에서 백엔드 문서를 조회해 매핑만 채운다. 매핑 실패 시 이 DTO
자체를 만들지 않고 payload를 폐기한다).

### `ProjectGenerationOutcomeRemote`

```swift
protocol ProjectGenerationOutcomeRemote: Sendable {
    func outcomes() -> AsyncStream<ProjectGenerationOutcomeDTO>
}
```

### `PushProjectGenerationOutcomeRemote` (actor, `ProjectGenerationOutcomeRemote` 구현)

- 상태: `continuations: [UUID: AsyncStream<ProjectGenerationOutcomeDTO>.Continuation]`
- `outcomes() -> AsyncStream<ProjectGenerationOutcomeDTO>`: 새 continuation을 등록하고
  스트림을 반환한다. `onTermination`에서 등록을 해제한다.
- `ingest(rawPayload: [String: String])`: payload를 `ProjectGenerationOutcomeDTO`로
  디코딩할 수 있으면 보관 중인 모든 continuation에 `yield`한다. 실패하면 무시한다.

App의 `GitItAppDelegate`가 silent push를 받으면 `AppComposition.ingestPushPayload`
closure를 호출하고, 이 closure가 내부적으로 이 `ingest`를 호출하는 유일한 경로다.

## 신규 Infrastructure 계약 (`Infrastructure/PushMessaging`)

### `PushMessagingClient`

```swift
public protocol PushMessagingClient: Sendable {
    func registrationToken() async throws -> String
    func setAPNsToken(_ token: Data)
}
```

등록 토큰 조회와 APNs 토큰 대입만 계약으로 노출한다. 수신 payload 자체는 App의
`GitItAppDelegate`(`UIApplicationDelegate`)가 직접 받아 Composition의
`ingestPushPayload` closure로 전달하므로(`MessagingDelegate` 채택은
`FirebaseMessagingPushClient` 안에서 완결) 별도 스트림 계약을 두지 않는다.

### `FirebaseMessagingPushClient`

`PushMessagingClient`를 구현하며 `FirebaseMessaging`의 `Messaging.messaging().token`
API를 감싼다.

## 변경되는 기존 모델·상태

### `ProjectRegistrationFeature.State` (`Feature/ProjectRegistration`)

| 필드 | 변경 | 설명 |
| --- | --- | --- |
| `submission` | 케이스 추가 | `SubmissionStatus`에 `.awaitingGeneration(ProjectRegistrationReceipt)` 추가. 기존 `.failed(LearningProjectError)`를 FCM 실패 신호에도 재사용(원인 불문 단일 실패 표현, FR-011/FR-011a). `LearningProjectGenerationOutcome`은 실패 원인을 담지 않으므로 FCM `failed` 이벤트는 항상 `LearningProjectError.unexpected`로 매핑한다 |
| `isNotificationOptionSheetPresented` | 신규 | `Bool`, 기본값 `false` |

`isNotificationOptionSheetPresented` 외에 시트를 이미 거쳤는지 별도로 추적하는 필드는
두지 않는다(research.md §7 최종 결정). 시트에서의 수락·거절 선택 직후에는 항상
`waitAtHomeTapped` 동작이 이어져 `delegate(.projectRegistered)`가 발행되고
`ProjectRegistrationFeature.State` 자체가 제거되므로, 같은 State 생애주기 안에서
`waitAtHomeTapped`가 시트를 거친 뒤 다시 호출될 경로가 없다. 따라서 "이미 결정했는지"를
별도 필드로 기억할 필요가 없다.

```swift
public enum SubmissionStatus: Equatable, Sendable {
    case idle
    case committing
    case awaitingGeneration(ProjectRegistrationReceipt)
    case failed(LearningProjectError)
}
```

**상태 전이**:

```text
idle → committing → awaitingGeneration(receipt)
                        │  FCM completed          → delegate(.projectRegistered) 발행 후 State 제거
                        │  FCM failed              → failed(error)
                        │  "홈에서 기다리기" 탭      → (알림 옵션 시트 필요 시 경유) → delegate(.projectRegistered) 발행 후 State 제거
failed → (재시도) → committing
```

`awaitingGeneration`에 머무는 동안 `ProjectRegistrationFeature`는
`observeLearningProjectGenerationOutcomes()`로 받은 스트림을 구독하며,
`projectID`가 일치하는 이벤트만 반영한다(다른 프로젝트의 이벤트는 무시 — 동시에 여러
등록 흐름이 존재하지 않으므로 방어적 검사).

### `HomeFeature.State` (`Feature/Home`)

| 필드 | 변경 | 설명 |
| --- | --- | --- |
| `generationOutcomeObservation` | 신규 | `enum { idle, observing }`, `.view(.task)`에서 idle일 때만 구독 Effect 시작(장기 observation, 취소는 State 소유 종료 시 — MainShell 존속 중에는 취소하지 않음) |
| `pendingReloadAfterRegistration`(가칭) | 검토 후 불필요 | FR-013의 "1회 재조회"는 `AppRootFeature`가 등록 흐름 종료 delegate를 받은 시점에 `HomeFeature`로 명시적 View/input Action(`reloadRequested`)을 보내 트리거하므로 Home 자체 상태로 따로 기억할 필요 없음 |

`HomeFeature`는 수신한 `LearningProjectGenerationOutcome`을 `state.projectLoad`의
`LearningProjectPage` 항목 중 일치하는 `projectID`에 반영한다(완료/실패에 따른 표시
전이는 `LearningProjectSummary`가 이미 노출하는 필드 범위 내에서만 처리하며, 이
명세는 `LearningProjectSummary` 계약 자체를 확장하지 않는다 — 018-home-screen 범위
경계 참고).

## 엔터티 관계 요약

```text
ProjectRegistrationFeature.State ──uses──> ExternalRepository (기존)
                                  ──produces──> ProjectRegistrationReceipt (기존)
                                  ──observes──> LearningProjectGenerationOutcome (신규)

HomeFeature.State ──observes──> LearningProjectGenerationOutcome (신규, 같은 Use Case 별도 구독)

LearningProjectGenerationOutcomeRepository ──implemented by──> Composition Adapter
                                             ──delegates to──> ProjectGenerationOutcomeRemote (Data)
                                             ──fed by──> AppComposition.ingestPushPayload (Composition)
                                             ──sourced from──> GitItAppDelegate (App) ──uses──> PushMessagingClient (Infrastructure)
```
