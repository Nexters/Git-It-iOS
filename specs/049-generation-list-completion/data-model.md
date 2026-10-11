# 데이터 모델: 서버 프로젝트 목록에서 확인된 생성 중 프로젝트를 완료로 반영

**날짜**: 2026-10-01 | **명세**: [spec.md](./spec.md)

이 기능은 새 모델을 만들지 않는다. 기존 모델과 그 사이의 새 흐름만 적는다.

## 기존 엔터티(변경 없음)

### 생성 기록 — `GenerationRecord` (Domain `ProjectGeneration`)

| 필드 | 형태 | 이 기능에서의 역할 |
|---|---|---|
| `repositoryURL` | 정규화된 저장소 URL | 사용하지 않음 |
| `projectID` | `ProjectID?` | 목록 항목과 대조하는 키. `nil`이면 대조 대상이 아님 |
| `requestedAt` | `Date` | 사용하지 않음 |
| `status` | `inProgress` / `completed` / `failed` | `inProgress`만 완료로 전이 |
| `finishedAt` | `Date?` | 목록 확인 시 로드 성공 시각(`now()`)으로 채움 |

전이 규칙 `finishing(status:at:)`: `status == .inProgress`일 때만 바뀌고 그 외에는 자신을 돌려준다.
이 규칙이 FR-004·FR-005를 보장한다([research R3](./research.md#r3-중복-반영과-결과-뒤집힘-방지fr-004-fr-005)).

### 프로젝트 목록 항목 — `ProjectSummary` (Domain `Project`)

| 필드 | 이 기능에서의 역할 |
|---|---|
| `id: ProjectID` | 생성 기록과 대조하는 유일한 입력 |
| 나머지 필드 | 사용하지 않음. 항목에 생성 상태 필드는 없다 |

### 생성 결과 — `GenerationOutcome`

원격 알림 경로의 입력이다. 목록 확인 경로는 이 값을 만들지 않는다. 도착 알림·중복 제거(`recentArrivals`)
는 원격 알림 경로 전용으로 남는다([R4](./research.md#r4-목록-확인이-목록-갱신-계기가-되지-않게fr-006)).

## 새 흐름: 목록 확인 결과

값 타입을 새로 두지 않고 `[ProjectID]`와 호출 시각으로 표현한다.

```text
Project(actor)                              Composition                ProjectGeneration(actor)
──────────────                              ───────────                ────────────────────────
페이지 로드 성공 & 목록에 반영
  └─ projectsListed(page.summaries.map(\.id)) ──▶ 클로저 전달 ──▶ confirmCompletion(of: ids)
                                                                       ├─ 진행 중 기록 ∩ ids 각각
                                                                       │    finishGeneration(.completed, now())
                                                                       ├─ 관찰 중이면 apply → states() 방출
                                                                       └─ outcomeArrivals() 방출 없음
```

### `projectsListed` 호출 조건

| 로드 종류 | 호출 | 전달 값 |
|---|---|---|
| 첫 페이지(초기 로드, `refresh`, `refreshReplacingInFlightRequest`) 반영 | 예 | 그 페이지 항목 전체의 `id` |
| 다음 페이지 반영 | 예 | 그 페이지 항목 전체의 `id`(목록에 이미 있어 걸러진 항목 포함) |
| 대체 새로고침으로 버려진 응답(epoch 불일치) | 아니오 | — |
| 로드 실패 | 아니오 | — |
| 로그아웃 초기화 | 아니오 | — |

### `confirmCompletion(of:)` 판정

[contracts/list-confirmed-completion.md](./contracts/list-confirmed-completion.md)의 판정표를 정본으로
한다.

## 상태 전이 요약

```text
inProgress ──(원격 알림 QUIZ_READY)──────────▶ completed
inProgress ──(원격 알림 QUIZ_REJECTED)───────▶ failed
inProgress ──(목록 확인, 이 기능)────────────▶ completed
completed / failed ──(어떤 입력이든)─────────▶ (변화 없음)
어떤 상태 ──(삭제 release / 만료 / 로그아웃)──▶ 기록 제거(기존)
```
