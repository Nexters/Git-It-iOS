# 계약: Domain 공개 API

**명세**: [../spec.md](../spec.md) | **데이터 모델**: [../data-model.md](../data-model.md) | **조사**: [../research.md](../research.md)

이 문서는 시그니처와 동작 보장만 정의한다. 구현 본문은 다루지 않는다. "구현됨"은 045 이관 결정으로 이미 코드에 반영된
항목이고, "**추가**"가 이번 목록 자동 갱신에서 새로 구현할 항목이다.

## `DomainProject`

### `ProjectUseCase`

| 연산 | 변경 | 보장 |
|---|---|---|
| `projects() async -> AsyncStream<ProjectList>` | 유지 | 기존과 같다. 새로고침 중에도 현재 목록을 비우지 않는다 |
| `refresh() async throws` | 유지(대기 규칙 보강) | 진행 중인 첫 페이지 요청이 있으면 합류하고 새 요청을 만들지 않는다. 기다리던 요청이 `refreshReplacingInFlightRequest()`로 대체되면 오류 없이 최신 첫 페이지 요청의 결과를 받는다 |
| `refreshReplacingInFlightRequest() async throws` | **추가** | 진행 중인 첫 페이지·다음 페이지 요청을 취소하고 첫 페이지를 새로 요청한다. 목록은 응답이 올 때까지 유지한다. 대체된 요청의 응답은 목록에 반영하지 않는다. 호출자는 최신 첫 페이지 요청의 결과를 받으며, 그 요청이 다시 대체되면 오류 없이 그다음 최신 요청을 기다린다. 실패는 `ProjectError`로 던지고 목록을 바꾸지 않는다 |
| `requestNextPage() async throws` | 유지(대기 규칙 보강) | 기다리던 요청이 대체되면 오류 없이 반환하고 페이지를 추가하지 않는다 |
| `detail(of:)`, `delete(_:)` | 유지 | 기존과 같다 |

동시성 보장: 어느 시점에도 진행 중인 첫 페이지 요청은 1개 이하다.

적합 타입 갱신 대상(프로토콜 요구사항 추가로 함께 바뀐다):

- `sources/Projects/Domain/Project/UseCases/Project.swift`
- `sources/Projects/App/GitIt/Screens/AppRootView.swift`의 프리뷰 `NoopProject`
- `sources/Projects/App/Tests/GitIt/TestDoubles/ProjectUseCaseMock.swift`
- `sources/Projects/Feature/Tests/Home/TestDoubles/ProjectUseCaseMock.swift`
- `sources/Projects/Feature/Tests/ProjectDetail/TestDoubles/ProjectUseCaseDetailStub.swift`

### `Project.init`

| 인자 | 변경 | 보장 |
|---|---|---|
| `projectDeleted: @escaping @Sendable (ProjectID) async -> Void` | 구현됨 | `delete(_:)`가 저장소 삭제에 성공한 뒤 정확히 한 번 호출한다. Composition이 `ProjectGeneration.release(_:)`에 연결한다 |

생성자 인자는 이번 변경에서 바뀌지 않는다.

## `DomainProjectGeneration`

### `ProjectGenerationUseCase`

| 연산 | 변경 | 보장 |
|---|---|---|
| `request(_:)` | 유지 | 기존과 같다 |
| `states()` | 구현됨 | 상태가 바뀔 때와 보관 기한 마감 시각이 되었을 때 새 상태를 방출한다(FR-014). 새 상태를 적용할 때 이전 상태에 있던 기록이 사라지면 그 프로젝트의 로컬 알림 예약을 취소한다(FR-022) |
| `synchronize()` | 구현됨 | 관찰이 시작되지 않았으면 시작하고, 시작됐으면 만료를 정리하고 저장소 최신 상태·리마인드 대기열·보존 결과를 반영한다(FR-013) |
| `release(_ projectID: ProjectID)` | 구현됨 | 해당 프로젝트의 생성 기록·리마인드 대상·보존 결과를 지우고 예약된 로컬 알림을 취소한다. 기록이 없어도 오류를 내지 않는다(FR-022) |
| `outcomeArrivals() async -> AsyncStream<ProjectID>` | **추가** | 관찰이 시작되지 않았으면 시작한다. 이후 생성 결과를 받을 때마다 기록 반영을 마친 뒤 그 결과의 프로젝트 식별자를 방출한다. 생성 기록이 없는 프로젝트의 결과도 방출한다. 같은 `projectID`·`status`의 결과가 보관 기한(`retentionLimit`) 안에 다시 도착하면 방출하지 않는다(로그아웃하면 이 기억을 비운다). 보존 결과의 재반영은 방출하지 않는다. 구독 전 도착은 재생하지 않는다 |

적합 타입 갱신 대상:

- `sources/Projects/Domain/ProjectGeneration/UseCases/ProjectGeneration.swift`
- `sources/Projects/App/GitIt/Screens/AppRootView.swift`의 프리뷰 `NoopProjectGeneration`
- `sources/Projects/App/Tests/GitIt/TestDoubles/ProjectGenerationUseCaseMock.swift`
- `sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/ProjectGenerationUseCaseStub.swift`
- `sources/Projects/Feature/Tests/ShareRegistration/TestDoubles/ProjectGenerationUseCaseSpy.swift`

`sources/Projects/Feature/ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift`의 프리뷰 적합 타입은 갱신하지 않고
제거한다([research L9](../research.md#l9-컨벤션과-기존-관행의-충돌)).

### 외부 기능 계약(구현됨, 변경 없음)

| 계약 | 연산 | 보장 |
|---|---|---|
| `PendingGenerationRepository` | `finishGeneration(projectID:status:finishedAt:) -> Bool` | 해당 `projectID`의 기록이 있으면 `true`, 없으면 `false`. 이미 확정된 기록은 상태를 바꾸지 않고 `true` |
| `PendingGenerationRepository` | `pendingState()`, `pendingStateChanges()` | 구현은 보관 기한이 지난 기록을 결과에서 제외할 수 있다. Domain은 이전 상태와 비교해 사라진 기록을 판정한다 |
| `GenerationReminderScheduler` | `cancel(projectID:)` | 그 프로젝트의 완료·실패 로컬 알림 예약을 모두 취소한다 |
| `GenerationOutcomeRepository` | `outcomes()` | 파싱에 성공한 생성 결과만 방출한다. 구독자는 `ProjectGeneration` 하나다 |

### 모델(구현됨)

- `GenerationOutcome.init(projectID:status:arrivedAt:)`: `arrivedAt`은 필수다.
- `GenerationWaitPolicy.init(retentionLimit:reminderValidity:)`: `.standard`는 3600초, 300초다.

## 2026-09-28 추가 — 알림 누락 뒤 복구

### `GenerationOutcomeRepository`

```swift
public protocol GenerationOutcomeRepository: Sendable {
    func outcomes() async -> AsyncStream<GenerationOutcome>
    func deliveredOutcomes() async -> [GenerationOutcome]
}
```

- `deliveredOutcomes()`는 알림 센터에 남은 생성 결과를 전달 시각과 함께 반환한다. 파싱 실패분은 포함하지 않는다.

### `ProjectGenerationUseCase`

- `synchronize()`는 기존 동작 뒤에 `deliveredOutcomes()`를 반영한다(도착 알림 방출 없음).
