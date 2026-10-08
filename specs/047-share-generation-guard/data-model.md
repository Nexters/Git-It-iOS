# 데이터 모델: 공유 확장에서 진행 중인 생성이 있으면 새 생성 요청 차단

**명세**: [spec.md](./spec.md) | **조사**: [research.md](./research.md)

새 Domain 상태 모델은 추가하지 않는다(FR-008). 기존 모델에 판정 프로퍼티와 오류 사례를 더하고, 공유 확장 Feature는 판정 전용
타입 없이 현재 생성 상태 조회 클로저 결과로 화면 상태를 바꾼다(명확화 2026-09-29).

## Domain `DomainProjectGeneration`

### `ProjectGenerationState` (기존, 확장)

| 필드 | 타입 | 설명 |
|---|---|---|
| requests | `[ProjectGenerationRequestState]` | 기존. 보관 기한이 지나지 않은 생성 요청과 단계 |
| hasRequestInProgress | `Bool` (계산) | **추가**. `requests` 중 `phase == .inProgress`가 하나라도 있으면 참. "생성 중" 판정 규칙의 유일한 정의(FR-011) |

### `ProjectGenerationError` (기존, 확장)

| 사례 | 의미 |
|---|---|
| stateUnavailable | **추가**. 생성 기록을 읽을 수 없어 생성 상태를 확인할 수 없다(저장소 없음, 저장 값 해석 불가) |

### `GenerationState` (기존, 변경 없음)

`PendingGenerationRepository.confirmedPendingState()`가 돌려주는 대기 상태다. 보관 기한 정리 규칙은 기존 `pendingState()`와 같다.
읽을 수 없으면 Adapter가 `ProjectGenerationError.stateUnavailable`을 던진다.

## Data `DataShared`

### `KeyValueStorageError` (신규)

| 사례 | 발생 조건 |
|---|---|
| unavailable | 저장소를 만들 수 없다(`UnavailableKeyValueStorage`) |
| unreadable | 저장된 값이 있으나 요청한 형식으로 해석할 수 없다 |

값이 없는 경우는 오류가 아니라 `nil`이다. 이 오류는 Data 안에서만 쓰이고, Composition Adapter가 Domain 오류 `stateUnavailable`로 바꾼다.

## Feature `ShareRegistration`

### 공유 확장 판정 입력 (타입 없음)

`SharedRepositoryRegistrationFeature`는 UseCase 전체 대신 `lookUpRepository`·`requestGeneration`·`currentGenerationState` 클로저만 받고
(명확화 2026-09-29), `currentGenerationState: @Sendable () async throws -> ProjectGenerationState` 결과를 다음처럼 해석한다.

| 조회 결과 | 공유 확장 결과 |
|---|---|
| 상태를 읽었고 `hasRequestInProgress == false` | 기존 흐름 진행(`lookUpRepository` 또는 `requestGeneration`) |
| 상태를 읽었고 `hasRequestInProgress == true` | `generationInProgress` 상태 |
| 오류를 던졌다 | `generationUnverified(retry:)` 상태 |

### `SharedRepositoryRegistrationFeature.State.Phase` (기존, 확장)

| 사례 | 의미 | 닫기 | 재시도 |
|---|---|---|---|
| generationInProgress | **추가**. 생성이 진행 중이라 등록할 수 없다 | 가능 | 없음 |
| generationUnverified(retry: RetryTarget) | **추가**. 생성 상태를 확인하지 못해 등록할 수 없다 | 가능 | `retry` 대상(`lookup`·`registration`)부터 판정을 다시 한다 |

### 상태 전이

```text
validating ──(URL 오류)──────────────▶ invalidURL
    │──(로그인 필요·앱 실행 필요)────▶ signInRequired / appLaunchRequired
    │──조회: 생성 중──────────────────▶ generationInProgress
    │──조회: 오류──────────────────────▶ generationUnverified(retry: .lookup)
    └──조회: 생성 중 아님 ─▶ 저장소 조회 ─▶ ready / failed(…, .lookup)

ready ──submit──▶ submitting
    │──조회: 생성 중──────────────────▶ generationInProgress
    │──조회: 오류──────────────────────▶ generationUnverified(retry: .registration)
    └──조회: 생성 중 아님 ─▶ request ─▶ succeeded / failed(…, .registration) / signInRequired

generationUnverified(retry: .lookup) ──retry──▶ validating(판정부터)
generationUnverified(retry: .registration) ──retry──▶ submitting(판정부터)
```

### `ShareRegistrationDiagnosticEvent` (기존, 확장)

| 사례 | 기록 시점 |
|---|---|
| generationInProgressBlocked | **추가**. 조회한 상태가 생성 중이라 등록을 막았을 때 |
| generationStateUnverified | **추가**. 상태 조회가 실패해 등록을 막았을 때 |

토큰·개인정보·저장소 URL은 기록하지 않는다(FR-007).

### 용어 대응

| 명세 용어 | 식별자 |
|---|---|
| 생성 중 안내 상태 | `generationInProgress`, 진단 `generationInProgressBlocked` |
| 확인 실패 안내 상태 | `generationUnverified(retry:)`, 진단 `generationStateUnverified` |
| 생성 기록을 읽지 못함 | Data `KeyValueStorageError`, Domain `ProjectGenerationError.stateUnavailable` |
