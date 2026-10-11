# 계약: Home 생성 결과 관찰 lifecycle

**요구사항**: FR-025·FR-026, SC-012 | **결정**: [research.md](../research.md) R12

## 1. 동작

| 사건 | 기대 동작 |
|------|-----------|
| Home `.task` 첫 전달 | 생성 결과 관찰 Effect 1개 시작 |
| Home이 보이는 동안 `.task` 재전달 | 이전 관찰 취소 후 새 관찰 시작. 동시에 살아 있는 관찰은 1개 |
| Home이 사라짐(`.task` 취소) | 관찰 Effect 종료 |
| Home이 다시 나타남 | 관찰 Effect 새로 시작 |
| 구독 직후 현재 상태에 끝난 기록이 있음 | 각 기록에 대해 `.effect(.generationOutcomeReceived)` 전달 |
| 이미 반영한 프로젝트의 결과가 다시 전달 | `appliedOutcomeProjectIDs`로 무시(기존 동작) |

## 2. 코드 변경 위치

| 파일 | 변경 |
|------|------|
| `sources/Projects/Feature/Home/HomeFeature.swift` | `State.GenerationOutcomeObservation`과 `generationOutcomeObservation` 제거. `CancelID`에 `generationOutcomes` 추가. `.view(.task)`에서 관찰 Effect를 `.cancellable(id: .generationOutcomes, cancelInFlight: true)`로 매번 시작 |
| `sources/Projects/Feature/Home/HomeScreen.swift` | 변경 없음(`.task { await send(.task).finish() }` 유지) |
| `sources/Projects/Feature/Tests/Home/Home/HomeFeatureGenerationOutcomeTests.swift` | L12 테스트 기대값을 "재호출 시 이전 관찰을 대체해 하나만 유지"로 변경하고 재진입 사례 추가 |

State에 새 프로퍼티를 추가하지 않는다. 프로필·프로젝트 최초 조회를 한 번만 하는 기존 동작
(`HomeFeatureLoadTests.swift:10`)은 유지한다.

## 3. 테스트 사례

| 테스트 이름(한국어 동작 문장) | 검증 |
|-------------------------------|------|
| `task가 다시 전달되면 이전 생성 결과 관찰을 대체해 하나만 유지한다` | `StubTrackGenerationUseCase.establishedSubscriptionCount()`가 동시 1 |
| `화면을 벗어났다 돌아오면 생성 결과 관찰을 다시 시작해 결과를 반영한다` | 첫 `.task` 취소 후 두 번째 `.task`에서 결과 emit → 프로젝트 재조회 |
| `화면을 벗어난 동안 끝난 생성 결과를 돌아왔을 때 반영한다` | 취소 후 상태에 완료 기록 저장 → 두 번째 `.task` 구독 직후 결과 수신 |
