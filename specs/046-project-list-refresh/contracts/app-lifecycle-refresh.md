# 계약: 앱 생명주기·생성 결과 계기에 따른 목록 새로고침

**명세**: [../spec.md](../spec.md) FR-001~FR-008 | **데이터 모델**: [../data-model.md](../data-model.md#3-계기-판정-상태--approotfeature-gitit) | **조사**: [../research.md](../research.md) L4~L6

App `GitIt` target 내부 계약이다. `AppRootFeature`는 모듈 내부 타입이므로 공개 API 변경은 없다.

## 플랫폼 연결 — `GitItApp`

| `scenePhase` 새 값 | 전달 Action | 변경 |
|---|---|---|
| `.active` | `.view(.applicationBecameActive)` | 유지 |
| `.background` | `.view(.applicationEnteredBackground)` | **추가** |
| `.inactive` | 없음 | 유지 |

## `AppRootFeature` Action

| 그룹 | Case | 변경 |
|---|---|---|
| `View` | `applicationEnteredBackground` | **추가** |
| `View` | `applicationBecameActive` | 유지(처리 변경) |
| `EffectEvent` | `generationOutcomeArrived(ProjectID)` | **추가** |
| `EffectEvent` | `learningProjectsRefreshFinished(error: ProjectError?)` | **추가** |

## 처리 보장

전제: "회원·메인 화면 흐름"은 `route == .mainShell`이고 `mainShell.access == .member`인 상태다.

| 입력 | 조건 | 결과 |
|---|---|---|
| `applicationEnteredBackground` | 항상 | `isInBackground = true`. Effect 없음 |
| `applicationBecameActive` | 직전 `isInBackground == true`, 회원·메인 화면 흐름 | 목록 새로고침 1회. 기존 로그인 확인·생성 상태 동기화·기기 등록 재시도도 실행 |
| `applicationBecameActive` | 직전 `isInBackground == false`(비활성→활성) | 목록 새로고침 없음. 기존 활성화 동작은 회원이면 실행 |
| `applicationBecameActive` | 게스트, 온보딩·복원 중 | 목록 새로고침 없음. `isInBackground`는 `false`로 초기화 |
| `generationOutcomeArrived` | `isInBackground == false`, 회원·메인 화면 흐름 | 목록 새로고침 1회 |
| `generationOutcomeArrived` | `isInBackground == true` | 없음(다음 백그라운드 복귀 계기가 갱신) |
| `generationOutcomeArrived` | 게스트, 온보딩·복원 중 | 없음 |
| `learningProjectsRefreshFinished` | 성공·실패 모두 | State 변경 없음, Effect 없음(FR-006). 분기를 생략하지 않고 명시한다 |

- 상세·풀이·등록 흐름이 표시되어 있어도 표시 상태(`projectDetail`, `quiz`, `projectRegistration`)를 바꾸지 않는다(FR-007).
- `applicationBecameActive`는 더 이상 `mainShell`에 `learningProjectsReloadRequested`를 보내지 않는다. 다른 재조회 계기
  (등록 완료, 삭제, 탭 전환, 풀이 종료)는 바뀌지 않는다.

## Effect

| Effect | Cancellation ID | 정책 | 결과 처리 |
|---|---|---|---|
| 목록 새로고침: `project.refreshReplacingInFlightRequest()` | `learningProjectsRefresh` | `cancelInFlight: true` | `.effect(.learningProjectsRefreshFinished(error:))`. 알 수 없는 오류는 `ProjectError` fallback으로 변환. 대체된 Effect는 결과를 보내지 않는다 |
| 생성 결과 도착 관찰: `projectGeneration.outcomeArrivals()` | `generationOutcomeObservation` | `.task`에서 1회 시작 | 원소마다 `.effect(.generationOutcomeArrived(projectID))` |

생성 결과 도착 관찰은 기존 생성 상태 관찰(`generationObservation`)과 같이 `route == .restoring`인 첫 `.task`에서만 시작한다.
