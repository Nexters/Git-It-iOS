# 데이터 모델: 프로젝트 목록 자동 갱신과 생성 상태 고착 해결

**명세**: [spec.md](./spec.md) | **조사**: [research.md](./research.md) | **계약**: [contracts/](./contracts/)

이 기능은 영속 데이터 형식을 바꾸지 않는다. 아래는 상태 소유자별 메모리 상태와 전이 규칙이다. 생성 기록·생성 결과·보존
중인 결과(045 이관, 구현됨)는 끝의 "이관 모델"에 요약한다.

## 1. 목록 요청 상태 — `Project` actor (`DomainProject`)

| 상태 | 타입 | 기존/변경 | 의미 |
|---|---|---|---|
| `loaded` | `[ProjectSummary]` | 기존 | 현재 목록. 새로고침 중에도 비우지 않는다 |
| `nextPageIndex`, `hasNextPage`, `isLoaded` | `Int`, `Bool`, `Bool` | 기존 | 페이지 진행 상태 |
| `epoch` | `Int` | **의미 확장** | 요청 세대. 로그아웃 초기화와 **진행 중 요청 대체** 때 증가한다. 세대가 다른 응답은 반영하지 않는다 |
| `firstPageTask` | 첫 페이지 요청 `Task` | 기존 | 진행 중인 첫 페이지 요청. 동시에 1개 이하 |
| `nextPageTask` | 다음 페이지 요청 `Task` | 기존 | 진행 중인 다음 페이지 요청. 동시에 1개 이하 |

### 전이 규칙

| 사건 | 조건 | 전이 |
|---|---|---|
| `refresh()` | `firstPageTask` 있음 | 새 요청을 만들지 않고 합류한다(기존) |
| `refresh()` | `firstPageTask` 없음 | 현재 세대로 첫 페이지 요청을 시작한다(기존) |
| `refreshReplacingInFlightRequest()` | 항상 | `epoch += 1`. 진행 중인 `firstPageTask`·`nextPageTask`를 취소하고 `nil`로 둔다. 목록은 유지한다. 새 세대로 첫 페이지 요청을 시작한다 |
| 첫 페이지 응답 도착 | 요청 세대 == `epoch` | 목록을 첫 페이지로 교체하고 `nextPageIndex = 1`, 방출한다(기존) |
| 첫 페이지 응답 도착 | 요청 세대 != `epoch` | 버린다 |
| 다음 페이지 응답 도착 | 요청 세대 != `epoch` | 버린다(기존) |
| 로그아웃 | — | `reset()`: `epoch += 1`, 목록·페이지·요청을 비우고 방출한다(기존, 요청 취소는 하지 않음) |

### 호출자 대기 규칙

| 호출자 | 기다리던 요청이 대체됨 | 기다리던 요청이 현재 세대로 끝남 |
|---|---|---|
| 첫 페이지(`refresh()`, `refreshReplacingInFlightRequest()`) | 오류 없이 최신 `firstPageTask`를 이어서 기다린다. 최신 요청이 없으면 반환한다 | 그 결과(성공 반환 또는 `ProjectError`)를 받는다 |
| 다음 페이지(`requestNextPage()`) | 오류 없이 반환한다 | 그 결과를 받는다 |

"대체됨"은 기다리던 요청의 세대가 현재 `epoch`와 다르고, 그 원인이 `refreshReplacingInFlightRequest()`인 경우다.
로그아웃 초기화로 세대가 바뀐 경우는 기존처럼 기다리던 요청의 결과를 그대로 받는다. 판정은 오류 종류가 아니라 요청 세대로
한다([research L3](./research.md#l3-대체된-요청과-호출자의-처리)).

### 불변식

- 동시에 진행되는 첫 페이지 요청은 1개 이하다(SC-005).
- 목록에 반영되는 첫 페이지 응답은 마지막으로 시작한 요청의 응답뿐이다.
- 대체로 인해 호출자가 `CancellationError`나 `ProjectError`를 받지 않는다.

## 2. 생성 결과 도착 알림 — `ProjectGeneration` actor (`DomainProjectGeneration`)

| 상태 | 타입 | 기존/변경 | 의미 |
|---|---|---|---|
| `arrivalSubscribers` | `[UUID: AsyncStream<ProjectID>.Continuation]` | **추가** | `outcomeArrivals()` 구독자 |
| `recentArrivals` | `[GenerationOutcome]` | **추가** | 도착 알림을 방출한 최근 결과. 도착 순서, 최대 32개, 보관 기한(`retentionLimit`) 안의 항목만 억제에 쓴다 |

### 전이 규칙

| 사건 | 전이 |
|---|---|
| `outcomeArrivals()` 호출 | 관찰을 시작하지 않았으면 시작하고, 구독자를 등록한다. 지난 도착은 재생하지 않는다 |
| 생성 결과 스트림에서 결과 수신 | 기존 `finish(_:)`로 기록 반영 또는 보존을 마친다. 이어서 `recentArrivals`에 같은 `projectID`·`status`이고 `now - arrivedAt ≤ retentionLimit`인 항목이 있으면 방출하지 않는다. 없으면 결과를 `recentArrivals` 끝에 추가하고(32개 초과 시 가장 오래된 것 제거) `projectID`를 모든 `arrivalSubscribers`에 방출한다. 기록이 없는 결과도 같은 규칙으로 방출한다 |
| 로그아웃(`releaseAll`) | `recentArrivals`를 비운다 |
| 보존 결과 재시도(`retryPreservedOutcomes`) | 방출하지 않는다 |
| 구독 종료 | 구독자를 제거한다 |

- 도착 알림은 사건 스트림이며 상태를 보관하지 않는다. 구독 전에 도착한 결과는 도착 알림으로 재생하지 않는다. 앱이 알림으로
  실행되는 경우 목록은 화면 시작 시 최초 로드로 받는다(명세 경계 사례).
- 같은 결과가 여러 경로로 오면 도착 알림은 한 번만 방출된다. 따라서 생성 결과 원격 알림 하나로 목록 요청은 한 번만
  시작된다(FR-005, SC-005). 같은 프로젝트라도 상태가 다르면 다른 결과로 방출한다
  ([research L1](./research.md#l1-생성-결과-도착-알림의-소유자)).

## 3. 계기 판정 상태 — `AppRootFeature` (`GitIt`)

| 상태 | 타입 | 기존/변경 | 의미 |
|---|---|---|---|
| `route` | `Route` | 기존 | `.mainShell`일 때만 메인 화면 흐름 |
| `mainShell.access` | `MainShellAccess` | 기존 | `.member`일 때만 회원 |
| `isInBackground` | `Bool` | **추가** | 마지막 활성화 이후 앱이 백그라운드에 들어갔는지. 초기값 `false` |

"메인 화면 흐름"은 `route == .mainShell`이다. 그 위에 상세·풀이·등록 흐름이 표시되어 있어도 포함한다(명세 FR-001, 등록
흐름 포함 여부는 [research L5](./research.md#l5-백그라운드-경유와-포그라운드-판정)에서 포함으로 정리).

### 전이 규칙

| 사건 | 전이 | Effect |
|---|---|---|
| `view(.applicationEnteredBackground)` | `isInBackground = true` | 없음 |
| `view(.applicationBecameActive)` | `returnedFromBackground = isInBackground`, `isInBackground = false` | 회원이면 기존 로그인 확인·생성 상태 동기화·기기 등록 재시도. 추가로 `returnedFromBackground`이고 메인 화면 흐름·회원이면 목록 새로고침 |
| `effect(.generationOutcomeArrived(projectID))` | 없음 | `isInBackground == false`이고 메인 화면 흐름·회원이면 목록 새로고침 |
| `effect(.learningProjectsRefreshFinished(error:))` | 없음(성공·실패 모두) | 없음 |
| 로그아웃·로그인 무효화 | 기존 초기화. `isInBackground`는 유지 | 없음 |

목록 새로고침 Effect는 `CancelID.learningProjectsRefresh`, `cancelInFlight: true`로 `refreshReplacingInFlightRequest()`를
호출하고 결과를 `learningProjectsRefreshFinished(error:)`로 돌려받되 State를 바꾸지 않는다([contracts/app-lifecycle-refresh.md](./contracts/app-lifecycle-refresh.md)).

## 4. 이관 모델(045, 구현됨)

| 엔터티 | 소유자 | 요약 |
|---|---|---|
| 생성 기록(`GenerationRecord`) | Data 저장소, Domain 계약 `PendingGenerationRepository` | 저장소 URL, 프로젝트 식별자, 요청 시각, 상태(`inProgress`·`completed`·`failed`), `finishedAt`. 확정 상태는 반대 결과로 바뀌지 않는다. 보관 기한 `retentionLimit`(3600초) |
| 생성 결과(`GenerationOutcome`) | Domain | `projectID`, `status`, `arrivedAt`. `arrivedAt`이 기록의 `finishedAt`이 된다 |
| 보존 중인 결과 | `ProjectGeneration` 메모리 | 최대 16개, 도착 후 보관 기한까지, 로그아웃 시 폐기 |
| 결과 소스 버퍼 | Data `PushQuizGenerationOutcomeSource` | 첫 구독 전 최대 32개 FIFO, 첫 구독에 모두 전달 |
| 설정 전 도착 슬롯 | Infrastructure `FirebaseMessagingAppDelegate` | `configure(_:)` 전 최대 8개 FIFO |
| 리마인드 판정 | `GenerationWaitPolicy.reminderValidity` | 300초. 결과 반영 즉시 예약 |

## 5. 알림 누락 뒤 복구 (2026-09-28 추가)

### 알림 센터 결과 — `DeliveredRemoteNotification`(Infrastructure) → `DeliveredRemoteMessage`(Data) → `GenerationOutcome`(Domain)

| 필드 | 형식 | 규칙 |
|---|---|---|
| payload | `[String: String]` | 원격 알림 `userInfo`를 문자열 사전으로 바꾼 값. 로컬 알림(trigger가 원격 푸시가 아님)은 포함하지 않는다 |
| deliveredAt | `Date` | 시스템이 알림을 전달한 시각. Domain 결과의 `arrivedAt`이 된다(FR-023) |

- Composition에서 `QuizGenerationOutcomeDTO(rawPayload:deliveredAt:)` 파싱에 실패한 항목은 버린다.

### 전이 규칙 — `ProjectGeneration`

| 계기 | 조건 | 결과 |
|---|---|---|
| `synchronize()` 중 알림 센터 결과 | 기록 있음, 진행 중 | 결과 상태로 전이, 리마인드 유효 시간 판정(FR-021), 도착 알림 방출 없음 |
| `synchronize()` 중 알림 센터 결과 | 기록 있음, 이미 결과 상태 | 기록 변화 없음, 로컬 알림 재예약 없음 |
| `synchronize()` 중 알림 센터 결과 | 기록 없음 | 기존 보존 규칙(개수·기간 상한) 적용, 기록 변화 없음 |

- 알림 센터 결과는 도착 알림 중복 판정 목록에 기록되어, 같은 결과의 뒤늦은 수신이 도착 알림을 만들지 않는다.
