# 계약: 목록 확인으로 생성 완료 반영

두 Domain 관심사가 Composition을 거쳐 연결되는 경계다. 근거는 [research R1·R2](../research.md)에 있다.

## 1. `Project` → 알림 클로저

**소유**: Domain `Project` (`Domain/Project/UseCases/Project.swift`)
**소비**: Composition `ConcernUseCaseAssembly`

```swift
public init(
    repository: any ProjectRepository,
    signedOutEvents: @escaping @Sendable () async -> AsyncStream<Void>,
    projectDeleted: @escaping @Sendable (ProjectID) async -> Void,
    projectsListed: @escaping @Sendable ([ProjectID]) async -> Void,   // 추가
    pageSize: Int = 20,
)
```

| 항목 | 계약 |
|---|---|
| 호출 시점 | 서버 페이지 응답이 목록에 반영된 직후(첫 페이지 교체, 다음 페이지 추가). `emit()` 뒤에 부른다 |
| 전달 값 | 그 페이지 항목의 `id` 전체. 순서는 서버 응답 순서 |
| 부르지 않는 경우 | 대체된 응답(epoch 불일치), 로드 실패, 로그아웃 초기화 |
| 예외 | 던지지 않는다. 로드 결과 전달(`refresh` 등의 반환)은 클로저 완료를 기다리지 않아도 된다 |
| 기본값 | 없음. 조립 시 반드시 넘긴다 |

## 2. `ProjectGeneration.confirmCompletion(of:)`

**소유**: Domain `ProjectGeneration` (`Domain/ProjectGeneration/UseCases/ProjectGeneration.swift`)
**소비**: Composition `ConcernUseCaseAssembly`의 `projectsListed` 클로저

```swift
public func confirmCompletion(of projectIDs: [ProjectID]) async
```

`ProjectGenerationUseCase` 프로토콜에는 추가하지 않는다(R2).

### 판정표

`ids`는 인자, "기록"은 공유 저장소의 생성 기록이다. 완료 시각은 호출 시점의 `now()`다.

| # | 기록 상태 | `projectID` | `ids`에 포함 | 결과 |
|---|---|---|---|---|
| 1 | `inProgress` | 있음 | 예 | `completed`, `finishedAt = now()` |
| 2 | `inProgress` | 있음 | 아니오 | 변화 없음 |
| 3 | `inProgress` | 없음(등록 응답 전) | — | 변화 없음 |
| 4 | `completed` | 있음 | 예 | 변화 없음(`finishedAt` 유지) |
| 5 | `failed` | 있음 | 예 | 변화 없음 |
| 6 | 기록 없음 | — | 예 | 기록을 만들지 않음 |
| 7 | `ids`가 빈 배열 | — | — | 아무 기록도 바꾸지 않음 |

### 부수 효과

| 효과 | 발생 여부 |
|---|---|
| 공유 저장소 기록 갱신 | 1번 행에서만 |
| `states()` 방출 | 관찰 중(`startTask != nil`)이고 기록이 바뀌었으면 `apply`로 방출. 관찰 전이면 저장소만 갱신하고 반환(`release`와 같은 규칙) |
| `outcomeArrivals()` 방출 | 없음(FR-006) |
| `recentArrivals` 기록 | 없음 |
| 보존 결과(`preservedOutcomes`) 변경 | 직접 변경 없음. `apply` 안의 기존 재시도만 그대로 동작 |
| 로컬·사용자 알림 | 없음(FR-007) |

### 원격 알림과의 순서 조합(FR-005)

| 먼저 | 나중 | 최종 기록 | 근거 |
|---|---|---|---|
| 목록 확인 → `completed` | `QUIZ_READY` | `completed`, `finishedAt`은 목록 확인 시각 | `finishing` 가드. 원격 알림은 도착 알림만 방출 |
| 목록 확인 → `completed` | `QUIZ_REJECTED` | `completed` | `finishing` 가드 |
| `QUIZ_REJECTED` → `failed` | 목록 확인 | `failed` | `finishing` 가드 |
| `QUIZ_READY` → `completed` | 목록 확인 | `completed`, `finishedAt`은 알림 도착 시각 | `finishing` 가드 |
