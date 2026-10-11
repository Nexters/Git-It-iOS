# 계약: 생성 대기 Repository

**요구사항**: FR-001~FR-010, SC-001~SC-003 | **결정**: [research.md](../research.md) R1~R6

이 문서는 생성 대기 상태를 다루는 Domain 계약, Data 저장 구현, Composition 연결의 공개 모양을
정의한다. 구현 본문은 다루지 않는다.

## 1. Domain 계약

위치: `sources/Projects/Domain/LearningProject/Contracts/PendingGenerationRepository.swift`

```swift
public protocol PendingGenerationRepository: Sendable {
    func pendingState() async -> GenerationState

    func pendingStateChanges() async -> AsyncStream<GenerationState>

    func beginGeneration(
        githubRepoURL: String,
        requestedAt: Date,
    ) async -> Bool

    func attachProjectID(
        _ projectID: String,
        toGithubRepoURL githubRepoURL: String,
    ) async

    func finishGeneration(
        projectID: String,
        status: GenerationRecord.Status,
        finishedAt: Date,
    ) async

    func releaseGeneration(githubRepoURL: String) async

    func releaseGeneration(projectID: String) async

    func enqueueReminder(projectID: String) async

    func drainReminderProjectIDs() async -> [String]
}
```

| 연산 | 의미 | 사전·사후 조건 |
|------|------|----------------|
| `pendingState()` | 만료 기록을 정리한 현재 생성 대기 상태 | 매 호출마다 App Group 저장소를 다시 읽는다. App Group 없음 → 빈 상태 |
| `pendingStateChanges()` | 구독 직후 현재 상태 1회, 이후 같은 프로세스의 기록마다 새 상태 | 구독자 등록은 스트림 생성 시점에 끝난다. 종료 시 등록 해제 |
| `beginGeneration` | 같은 정규화 URL이 진행 중이면 `false`, 아니면 진행 중 기록을 남기고 `true` | 조회·판정·기록이 원자적이다. App Group 없음 → 기록하지 않고 `true` |
| `attachProjectID` | URL 기록에 프로젝트 식별자를 연결 | 같은 식별자를 가진 다른 기록 제거(`GenerationState.attachingProjectID`) |
| `finishGeneration` | 진행 중 기록을 완료·실패로 전환 | `.inProgress` 전환은 무시(`GenerationRecord.finishing`) |
| `releaseGeneration(githubRepoURL:)` | URL 기록 제거 | 등록 실패, 준비 완료 해제, 계정 삭제 정리에서 사용 |
| `releaseGeneration(projectID:)` | 프로젝트 기록 제거 | 기존 `end(projectID:)` 의미 유지 |
| `enqueueReminder` | 완료 알림 대기에 프로젝트 추가 | 중복 무시, 상한 32 초과 시 오래된 항목 제거 |
| `drainReminderProjectIDs` | 완료 알림 대기를 읽고 비움 | 손상된 값은 빈 목록 |

제거 대상 Domain 계약: `GenerationStateRepository`, `PendingGenerationReminders`.

## 2. Domain UseCase 변경

| 타입 | 변경 전 의존 | 변경 후 의존 | 공개 API |
|------|--------------|--------------|----------|
| `CreateLearningProject` | `trackGeneration: any TrackGenerationUseCase` | `pendingGenerations: any PendingGenerationRepository` | `init(repository:pendingGenerations:now:)`, `callAsFunction` 불변 |
| `FetchLearningProjects` | `trackGeneration` | `pendingGenerations` | `init(repository:pendingGenerations:)`, `callAsFunction` 불변 |
| `TrackGeneration` | `stateRepository`, `outcomeRepository`, `waitPolicy`, `now` | `pendingGenerations`, `outcomeRepository`, `now` | `TrackGenerationUseCase` 연산 6개 불변 |
| `ScheduleGenerationReminder` | `pendingReminders: (any PendingGenerationReminders)?` | `pendingGenerations: (any PendingGenerationRepository)?` | `ScheduleGenerationReminderUseCase` 불변 |

`TrackGeneration` 연산 대응:

| `TrackGenerationUseCase` | 위임 대상 |
|--------------------------|-----------|
| `begin(githubRepoURL:requestedAt:)` | `beginGeneration` |
| `attachProjectID(_:toGithubRepoURL:)` | `attachProjectID` |
| `end(githubRepoURL:)` | `releaseGeneration(githubRepoURL:)` |
| `end(projectID:)` | `releaseGeneration(projectID:)` |
| `current()` | `pendingState()` |
| `states()` | `pendingStateChanges()` |

`TrackGeneration`은 최초 연산 호출 시 `GenerationOutcomeRepository.outcomes()` 관찰을 한 번만 시작하고 각 결과를
`finishGeneration(projectID:status:finishedAt: now())`으로 반영한다.

## 3. Data 저장 구현

위치: `sources/Projects/Data/LearningProject/Stores/LocalPendingGenerationStore.swift`

```swift
public actor LocalPendingGenerationStore {
    public init(storage: any KeyValueStorage)

    public func state() async -> GenerationStateDTO
    public func stateChanges() -> AsyncStream<GenerationStateDTO>
    @discardableResult
    public func modifyState(
        _ transform: @Sendable (GenerationStateDTO) -> GenerationStateDTO?
    ) async -> GenerationStateDTO?

    public func appendReminder(projectID: String, requestedAt: Date) async
    public func drainReminderProjectIDs() async -> [String]
}
```

- `modifyState`는 actor 격리 안에서 읽기·변환·기록을 한 번에 수행한다. 변환이 `nil`을 돌려주면 기록하지 않고
  `nil`을 돌려준다. 기록하면 모든 구독자에게 새 상태를 보낸다.
- 저장 좌표는 [data-model.md](../data-model.md) "저장 좌표"를 따른다.
- 제거 대상: `LocalGenerationStateStore`, `PendingGenerationReminderCoding`, Data 계약 `GenerationStateStore`.
  `QuizGenerationOutcomeSource`·`PushQuizGenerationOutcomeSource`는 유지한다.

## 4. Composition 연결

| 위치 | 변경 |
|------|------|
| `Composition/LearningProject/Adapters/PendingGenerationRepositoryAdapter.swift`(신규) | `init(store: LocalPendingGenerationStore, waitPolicy: GenerationWaitPolicy, now: @Sendable () -> Date)`. DTO↔모델 변환, 만료 정리, Domain 모델 전이 메서드 호출만 수행 |
| `Composition/LearningProject/Adapters/GenerationStateRepositoryAdapter.swift`, `PendingGenerationRemindersAdapter.swift` | 제거 |
| `Composition/LearningProject/Assemblies/LearningProjectAssembly.swift` | 프로세스당 Repository 1개를 만들어 `TrackGeneration`, `CreateLearningProject`, `FetchLearningProjects`에 공유. `pendingGenerations`를 모듈 내부(`internal` 또는 `package`)로 노출 |
| `Composition/LearningProject/Assemblies/GenerationReminderAssembly.swift` | `pendingReminderCoding` 인자와 `makePendingReminderEnqueue` 제거. Repository를 받아 `ScheduleGenerationReminder`에 전달 |
| `Composition/App/Assemblies/AppComposition.swift` | LearningProject와 GenerationReminder가 같은 Repository 인스턴스를 사용 |
| `Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift` | `enqueueGenerationReminder`를 Share Extension Repository의 `enqueueReminder(projectID:)`에 연결. 공개 프로퍼티 이름·타입 유지 |

## 5. 검증 사례

| 사례 | 테스트 위치 |
|------|-------------|
| 같은 저장소를 공유하는 두 Repository에서 기록·조회·흡수 | `Composition/Tests/LearningProject/Adapters/PendingGenerationRepositoryAdapterTests.swift` |
| 동시 `beginGeneration` 같은 URL 중 하나만 `true` | 같은 파일 |
| 중복 알림 대기, 상한 32, 손상된 값, App Group 없음 | `Data/Tests/LearningProject/Stores/LocalPendingGenerationStoreTests.swift` |
| 중복 요청 차단, 등록 실패 시 해제, 생성 중 프로젝트 목록 제외 | `Domain/Tests/LearningProject/UseCases/CreateLearningProjectTests.swift`, `FetchLearningProjectsTests.swift` |
| 결과 반영과 관찰자 전달 | `Domain/Tests/LearningProject/UseCases/TrackGenerationTests.swift` |
| Share Extension 기록을 앱 경로가 흡수 | `Composition/Tests/ShareExtension/ShareExtensionCompositionTests.swift` |
