# 계약: Domain·Data 생성 결과 표면

**기능 브랜치**: `feature/generation-reminder-refactoring`

**적용 요구사항**: FR-004, FR-005, FR-006, FR-007, FR-019

이 문서는 생성 결과 어휘 통일이 바꾸는 Domain·Data 공개 계약을 고정한다. 연산 시그니처와
값 의미는 보존하며 이름과 배치만 바꾼다(FR-018).

## 1. Domain 계약

### 1.1 생성 결과 저장소

```swift
// 변경 전: LearningProjectGenerationOutcomeRepository
public protocol GenerationOutcomeRepository: Sendable {
    func outcomes() async -> AsyncStream<GenerationOutcome>
}
```

**위치**: `Domain/LearningProject/Contracts/GenerationOutcomeRepository.swift`

### 1.2 리마인드 등록 *(이름 유지)*

```swift
public protocol GenerationReminderRegistry: Sendable {
    func register(projectID: String) async
}
```

이름은 이미 책임과 최소 문맥을 드러낸다. 변경하지 않는다.

### 1.3 알림 권한 게이트웨이 — 책임 분리

**변경 전**: `NotificationAuthorizationGateway`가 요청과 조회를 함께 제공하고,
`RequestGenerationReminderUseCase`도 `isAuthorized()`를 함께 노출한다.

**변경 후**: 게이트웨이는 그대로 두되, **UseCase 계약을 둘로 나눈다**(FR-007).

```swift
public protocol NotificationAuthorizationGateway: Sendable {
    func requestAuthorization() async -> NotificationAuthorizationOutcome
    func isAuthorized() async -> Bool
}
```

게이트웨이는 "알림 권한"이라는 하나의 관심사에 대한 요청·조회 두 연산을 갖는 것이 자연스럽다.
문제는 UseCase 쪽이다(§2.3).

## 2. Domain UseCase

### 2.1 생성 결과 관찰

```swift
// 변경 전: LearningProjectOutcomesUseCase / LearningProjectOutcomes
public protocol ObserveGenerationOutcomesUseCase: Sendable {
    func callAsFunction() async -> AsyncStream<GenerationOutcome>
}

public struct ObserveGenerationOutcomes: ObserveGenerationOutcomesUseCase, Sendable {
    public init(repository: any GenerationOutcomeRepository)
}
```

**위치**: `Domain/LearningProject/UseCases/ObserveGenerationOutcomes/`

**`Observe` 접두어의 근거**: `docs/conventions/naming.md` §3.3 — 무한 스트림을 반환하는 관찰과
1회 조회(`FetchLearningProjects`)는 수명이 다르므로 이름에서 구분한다.

### 2.2 리마인드 요청 — 축소

```swift
// 변경 전: isAuthorized()를 함께 가짐
public protocol RequestGenerationReminderUseCase: Sendable {
    func callAsFunction(projectID: String) async -> NotificationAuthorizationOutcome
}
```

**동작**(변경 없음): 권한을 요청하고, 결과가 `authorized`일 때만 `projectID`를 리마인드 대상으로
등록한 뒤 결과를 그대로 반환한다.

### 2.3 알림 권한 조회 — 신규 분리

```swift
public protocol NotificationAuthorizationStatusUseCase: Sendable {
    /// 시스템 권한 다이얼로그를 띄우지 않고 현재 알림 권한이 허용 상태인지 확인한다.
    func callAsFunction() async -> Bool
}

public struct NotificationAuthorizationStatus: NotificationAuthorizationStatusUseCase, Sendable {
    public init(authorizationGateway: any NotificationAuthorizationGateway)
}
```

**위치**: `Domain/LearningProject/UseCases/NotificationAuthorizationStatus/`

**분리 근거**: `RequestGenerationReminderUseCase`라는 이름은 "리마인드를 요청한다"만 설명한다.
`isAuthorized()`는 아무것도 요청하지 않고 현재 상태만 읽으며, 호출부(등록 화면의 "홈에서
기다리기")도 리마인드가 아니라 시트 표시 여부를 판단하려고 쓴다. 이름이 설명하지 않는 연산은
별도 계약으로 분리한다(FR-007).

**동작 보존**: 호출부는 두 UseCase를 주입받아 기존과 동일한 순서로 호출한다. 관찰 가능한
동작은 바뀌지 않는다.

## 3. Domain 모델 배치

```text
Domain/LearningProject/
├── Contracts/
│   ├── GenerationOutcomeRepository.swift
│   ├── GenerationReminderRegistry.swift
│   └── NotificationAuthorizationGateway.swift
├── Models/
│   ├── LearningProject/
│   │   └── GenerationOutcome.swift
│   └── Notification/
│       └── NotificationAuthorizationOutcome.swift
└── UseCases/
    ├── ObserveGenerationOutcomes/
    ├── RequestGenerationReminder/
    └── NotificationAuthorizationStatus/
```

`NotificationAuthorizationOutcome.swift`는 현재 `Models/` 최상위에 홀로 있다. 다른 모델은 모두
타입 패밀리 폴더(`Answer/`, `Bookmark/`, `LearningProject/`, `Quiz/`) 안에 있으므로
`Models/Notification/`으로 옮겨 배치를 일관되게 한다(명세 `가정`의 알림 관심사 항목).

## 4. Data 계약

```swift
// 변경 전: ProjectGenerationOutcomeRemote
public protocol GenerationOutcomeStream: Sendable {
    func outcomes() -> AsyncStream<GenerationOutcomeDTO>
}
```

**위치**: `Data/LearningProject/Contracts/GenerationOutcomeStream.swift`

**구현**: `PushGenerationOutcomeStream` *(변경 전 `PushProjectGenerationOutcomeRemote`)* —
`Data/LearningProject/Remotes/`에 유지한다(R-005).

```swift
public final class PushGenerationOutcomeStream: GenerationOutcomeStream, Sendable {
    public init()
    public func outcomes() -> AsyncStream<GenerationOutcomeDTO>
    public func ingest(rawPayload: [String: String]) async
}
```

**멀티캐스트 계약**(변경 없음):

- `outcomes()` 호출마다 독립 구독을 만든다.
- 한 번의 `ingest`는 호출 시점의 모든 활성 구독에 전달된다.
- 한 구독의 종료가 다른 구독에 영향을 주지 않는다.
- 디코딩에 실패한 payload는 조용히 폐기된다.

**`ingest`가 계약 밖에 있는 이유**: 입력과 출력의 소비자가 다르다. 출력은 Composition의
어댑터가, 입력은 push delegate 경로가 사용한다. 이번 범위에서는 구조를 바꾸지 않고 이름만
정리한다.

## 5. Data DTO

```swift
// 변경 전: ProjectGenerationOutcomeDTO
public struct GenerationOutcomeDTO: Equatable, Sendable {
    public init(projectID: String, status: RawStatus)
    public init?(rawPayload: [String: String])

    public enum RawStatus: String, Sendable {
        case completed
        case failed
    }

    public let projectID: String
    public let status: RawStatus
}
```

**외부 계약 고정**: `rawPayload`의 키 `projectId`·`status`와 값 `completed`·`failed`는 서버가
소유한다. 변경하지 않는다.

## 6. 경계 변환의 전수성

`GenerationOutcomeDTO.RawStatus` → `GenerationOutcome.Status` 변환은 프로젝트가 소유한 두 enum
사이의 매핑이다. 라이브러리 non-frozen enum 전용 미지 케이스 분기를 제거해 전수 분기로 만든다
(FR-019).

| 변경 전 | 변경 후 |
| --- | --- |
| 반환 타입 `GenerationOutcome?` | 반환 타입 `GenerationOutcome` |
| 미지 케이스에서 `nil` → 이벤트 폐기 | 미지 케이스 없음. 새 케이스 추가 시 컴파일 오류 |

동일한 정리를 `ProjectRegistrationFeature`의 `GenerationOutcome.Status` 분기에도 적용한다.
