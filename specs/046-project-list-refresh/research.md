# 조사: 프로젝트 목록 자동 갱신과 생성 상태 고착 해결

**명세**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md)

기술 맥락에 남은 미해결 항목은 없다. 1부는 이번 계획에서 새로 정한 목록 자동 갱신 설계(L1~L9)이고,
2부는 045(`feature/fix-generation-stuck`)에서 이관해 이미 구현된 생성 상태 고착 해결 설계(R1~R12)다.
2부는 `0d6e197`(생성 중 목록 필터·준비 대기 시간 제거) 이후 코드에 맞게 문장을 고쳤다.

## 1부. 목록 자동 갱신

**용어**: 이 문서와 작업 목록에서 **대체 새로고침**은 `ProjectUseCase.refreshReplacingInFlightRequest()`, 즉 진행 중인
목록 요청을 취소하고 첫 페이지를 새로 받는 새로고침을 뜻한다(명세 FR-005의 "취소하고 새로 요청"). 기존
`refresh()`는 **합류 새로고침**으로 구분한다.

### 현재 구조 조사

- 목록 정본은 Domain `Project` actor다. Home과 프로젝트 목록 탭은 각자 `ProjectSummaryListFeature`로
  `projects()` 스트림을 관찰하고, `refresh()`로 첫 페이지를 다시 요청한다.
- `Project.refresh()`는 진행 중인 첫 페이지 요청(`firstPageTask`)이 있으면 **그 요청에 합류**한다
  (`sources/Projects/Domain/Project/UseCases/Project.swift`의 `requestFirstPage`). 명확화 2026-09-27의
  "진행 중 요청 취소 후 재요청"과 반대다.
- Feature의 `.cancellable(cancelInFlight:)`는 Effect만 취소하고 Domain 내부 `Task`는 취소하지 않는다. 취소된
  Effect가 시작한 요청의 응답도 목록에 반영된다.
- `MainShellRouterFeature.reloadLearningProjects()`는 Home과 프로젝트 목록 탭에 각각 재조회를 보낸다. 지금은
  두 호출이 Domain에서 합류해 서버 요청이 1회다.
- `AppRootFeature`는 `scenePhase`가 `.active`가 될 때마다 `applicationBecameActive`를 받고, 회원·메인 화면이면
  `learningProjectsReloadRequested`를 보낸다. 비활성→활성 전환과 백그라운드→활성 전환을 구분하지 않는다.
- 생성 결과는 Data `PushQuizGenerationOutcomeSource`가 payload를 파싱해 방출하고, Composition
  `GenerationOutcomeRepositoryAdapter`를 거쳐 `ProjectGeneration`이 유일하게 구독한다. 이 소스는 첫 구독자에게만
  구독 전에 보존한 결과를 넘긴다.

### L1. 생성 결과 도착 알림의 소유자

- **결정**: `ProjectGeneration`이 생성 결과 스트림에서 결과를 받을 때마다, 기록 반영(`finish`)을 마친 뒤 그
  결과의 `projectID`를 새 관찰 스트림 `outcomeArrivals()`의 구독자에게 방출한다. 보존 중인 결과를 다시 반영하는
  재시도는 방출하지 않는다.
- **중복 도착 억제**: 같은 생성 결과(같은 `projectID`와 같은 `status`)가 여러 수신 경로나 여러 번으로 다시 도착하면
  도착 알림을 다시 방출하지 않는다. `ProjectGeneration`은 방출한 결과의 (`projectID`, `status`, `arrivedAt`)를
  "최근 도착 결과"로 기억하고, 새 결과와 같은 `projectID`·`status`를 가진 항목이 보관 기한(`retentionLimit`, 1시간)
  안에 있으면 방출하지 않는다. 최근 도착 결과는 최대 32개를 도착 순서로 보관하고 넘치면 가장 오래된 것부터 버리며,
  로그아웃(`releaseAll`)하면 비운다. 기록 반영(`finish`)은 억제와 관계없이 기존대로 수행한다(FR-012가 이미 한 번만
  전이하도록 보장한다).
- **근거**:
  - FR-002의 "생성 결과 원격 알림"은 payload 파싱에 성공한 알림이다. Domain에 도착하는 결과는 모두 파싱에
    성공한 것이므로 판정을 새로 구현하지 않는다(명확화 2026-09-27 질문 1).
  - 결과 소스의 구독자를 `ProjectGeneration` 하나로 유지해야 구독 전에 보존한 결과가 생성 기록 반영(FR-011)에서
    빠지지 않는다. App이나 다른 Domain 관심사가 결과 소스를 직접 구독하면 첫 구독 순서에 따라 보존 결과를 빼앗는다.
  - 생성 기록이 없는 프로젝트의 결과도 방출한다(명세 FR-002, 경계 사례 "결과 알림의 프로젝트가 생성 기록에 없으면").
  - 기록 반영 뒤에 방출하므로 버튼 상태 갱신이 목록 갱신보다 먼저 일어난다.
  - 중복 도착 억제는 FR-005·SC-005("생성 결과 원격 알림 하나로 목록 요청을 두 번 이상 시작하지 않는다")를 지키기 위해
    필요하다. 포그라운드에서 alert와 content-available을 함께 담은 알림은 표시 콜백과 백그라운드 수신 콜백으로 두 번
    전달될 수 있고(R2), 경로마다 방출하면 계기 하나로 요청이 두 번 시작된다. 알림 하나를 식별하는 값은 payload의
    `projectId`·`status`뿐이므로 이 쌍을 결과의 동일성 기준으로 삼는다.
  - 억제 상태는 [Domain 규칙](../../docs/package-rules/domain.md)의 "순서 보장이나 중복 억제 같은 실행 보장은 계약 구현
    내부의 상태로 둔다"에 따라 `ProjectGeneration` actor 내부에 둔다. 보관 기한과 상한은 기존 보존 결과(R4)와 같은
    정책 값(`retentionLimit`)과 Data 결과 소스 버퍼 상한(32)을 따른다.
  - 같은 프로젝트라도 상태가 다른 결과(예: 실패 뒤 완료)는 다른 알림이므로 방출한다.
- **검토한 대안**:
  - App이 `GenerationOutcomeRepository`를 직접 구독한다. App은 Composition이 공개하는 UseCase 프로토콜만 받고,
    보존 결과를 빼앗는 문제가 있어 기각했다.
  - 중복을 App에서 거른다(예: 짧은 시간 창 안의 같은 `projectID` 무시). App이 Domain 규칙(결과 동일성)을 다시 판단하게
    되어 [App 규칙](../../docs/package-rules/app.md)과 어긋나고 시간 창 값이 임의적이라 기각했다.
  - 명세 경계 사례의 "경로마다 갱신 계기가 될 수 있다"를 근거로 중복 방출을 허용한다. FR-005·SC-005 문장과 어긋나므로
    기각했다. 경계 사례 문구 정리는 명세 소유 스킬(`/speckit-clarify`)의 범위로 남긴다.
  - `states()`가 방출하는 `ProjectGenerationState`에 마지막 도착 결과를 담는다. 상태 스냅숏에 일회성 사건을 섞게 되고,
    기록이 없는 결과는 상태를 바꾸지 않아 방출되지 않으므로 기각했다.

### L2. 취소 후 재요청을 새 연산으로 분리

- **결정**: `ProjectUseCase`에 `refreshReplacingInFlightRequest()`를 추가한다. 기존 `refresh()`의 합류 의미는
  유지하고, 목록 자동 갱신 계기에서만 새 연산을 쓴다.
- **근거**:
  - `refresh()` 자체를 취소 후 재요청으로 바꾸면 기존 호출 경로가 한 계기에 여러 번 요청하게 된다. 탭 전환·삭제·등록
    완료 때 Home과 목록 탭이 함께 `refresh()`를 부르고, 화면 시작 시 `projects()`의 자동 첫 요청과 `start`의
    `refresh()`가 겹친다. 지금은 합류해서 1회인데, 취소 의미로 바꾸면 2회가 되고 먼저 시작한 요청이 버려진다.
  - 명세의 취소 규칙은 자동 갱신 계기(FR-005)와, 자동 갱신 계기가 진행 중인 수동 새로고침과 겹치는 경우에 적용된다.
    새 연산은 진행 중인 요청이 무엇이든 대체하므로 이 두 경우를 모두 덮는다.
  - 자동 갱신 계기는 App이 한 번만 호출하므로 계기당 요청 시작이 1회다(SC-005).
- **검토한 대안**:
  - `refresh()` 의미를 바꾸고 모든 호출 경로를 한 번씩만 부르도록 재구성한다. Home·목록 탭·Router의 재조회 경로와
    테스트를 대부분 바꿔야 하고 탭 전환 첫 방문의 중복 요청을 해소하지 못해 기각했다.
  - `refresh(replacingInFlightRequest: Bool)` 매개변수형. 프로토콜 요구사항에는 기본값을 둘 수 없어 모든 기존 호출을
    바꿔야 하고, 두 의미가 한 이름에 섞여 기각했다.

### L3. 대체된 요청과 호출자의 처리

- **결정**: `Project` actor가 요청 세대(기존 `epoch`)를 증가시켜 진행 중인 첫 페이지·다음 페이지 요청 `Task`를
  취소하고, 목록은 비우지 않은 채 새 첫 페이지 요청을 시작한다. 이후 규칙은 다음과 같다.
  - 대체된 요청의 응답은 세대가 달라 반영하지 않는다. 취소가 전달되지 않아 응답이 늦게 도착해도 같다.
  - 첫 페이지 요청을 기다리던 호출자(`refresh()`, 새 연산 모두)는 자신이 기다리던 요청이 대체되었으면 오류 없이
    **최신 첫 페이지 요청**을 이어서 기다리고 그 결과(성공 또는 오류)를 받는다.
  - 다음 페이지 요청을 기다리던 호출자는 요청이 대체되었으면 오류 없이 반환한다. 페이지는 추가되지 않는다.
  - 로그아웃 초기화(`reset`)는 기존 동작을 유지한다.
- **근거**:
  - 명세 경계 사례: "취소된 요청은 실패로 취급하지 않는다". 대체된 호출자가 `CancellationError`를 받으면 Home·목록
    탭의 `ProjectSummaryListFeature`가 `.unexpected`로 바꿔, 목록을 아직 받지 못한 상태에서 오류 화면을 띄운다.
  - 다음 페이지 요청이 오류로 끝나면 목록 탭 `ProjectListPaginationFeature`가 다음 페이지 재시도 footer를 띄운다.
    대체된 경우 오류 없이 끝나야 FR-006·FR-007을 지킨다. 목록은 첫 페이지로 교체된다(명확화 2026-09-28 질문 1).
  - [요청 식별 컨벤션](../../docs/conventions/tca/state/request-identity.md): 취소만으로 늦은 응답이 반영되지
    않는다고 가정하지 않는다. 판정은 오류 종류가 아니라 세대 비교로 한다.
  - [Domain 규칙](../../docs/package-rules/domain.md): 순서 보장·중복 억제는 UseCase 구현 내부 상태로 둔다.
- **검토한 대안**:
  - 대체된 호출자에게 `CancellationError`를 던지고 Feature가 무시한다. Feature의 오류 해석을 모든 호출 경로에서
    바꿔야 하고, 목록을 아직 받지 못한 화면은 결과를 알 방법이 없어 기각했다.
  - 요청 `Task`를 취소하지 않고 세대 비교만 한다. 명세가 요구하는 "취소"가 네트워크 요청에 전달되지 않아 기각했다.

### L4. 계기 판정의 소유자

- **결정**: 두 계기의 판정과 새로고침 호출은 App `AppRootFeature`가 소유한다. `MainShellRouterFeature`와
  Home·목록 탭 Feature는 바꾸지 않는다.
- **근거**:
  - [App 규칙](../../docs/package-rules/app.md): 플랫폼 생명주기 연결은 App 책임이고, `AppRootFeature`는 이미
    활성화 이벤트로 로그인 확인·생성 상태 동기화·기기 등록 재시도를 조정한다. 두 Domain 관심사(`Project`,
    `ProjectGeneration`)는 서로 import할 수 없으므로 연결도 App이 한다.
  - [Router 컨벤션](../../docs/conventions/tca/navigation/router.md): Router는 전환 상태만 소유한다. 새로고침
    Effect를 `MainShellRouterFeature`에 두면 전환 외 관심사를 Router가 갖게 된다.
  - Home과 목록 탭은 같은 Domain 목록 스트림을 관찰하므로, 새로고침을 한 번 호출하면 두 화면에 같은 결과가
    반영된다(FR-008). `ProjectListFeature`는 `listUpdated`로 페이지 상태를 교체한다.
  - `AppRootFeature`는 이미 풀이 흐름 종료 시 `project.refresh()`를 직접 호출한다. 같은 방식이다.
- **검토한 대안**:
  - `MainShellRouterFeature`에 새 Input을 두고 Router가 새로고침한다. Router 컨벤션 위반이라 기각했다.
  - 새로고침 전용 관심사 Feature를 만들어 Router가 조합한다. 화면 상태가 없는 호출 하나를 위해 Feature와 State를
    늘리고, 계기 판정은 여전히 App에 있어야 하므로 기각했다.

### L5. 백그라운드 경유와 포그라운드 판정

- **결정**:
  - `GitItApp`은 `scenePhase`가 `.background`가 되면 `applicationEnteredBackground`, `.active`가 되면 기존
    `applicationBecameActive`를 보낸다. `.inactive`는 보내지 않는다.
  - `AppRootFeature.State.isInBackground: Bool`을 둔다. `applicationEnteredBackground`에서 `true`,
    `applicationBecameActive`에서 판정에 쓴 뒤 `false`로 되돌린다. 이 초기화는 회원 여부 guard보다 먼저 한다.
  - 포그라운드 계기(FR-001): `applicationBecameActive` 시점에 `isInBackground`가 `true`였고, `route == .mainShell`,
    `mainShell.access == .member`이면 새로고침한다.
  - 알림 계기(FR-002·FR-003): `generationOutcomeArrived` 시점에 `isInBackground == false`이고 같은 회원·메인 화면
    조건이면 새로고침한다.
  - "메인 화면 흐름"은 `route == .mainShell`이다. 그 위에 상세·풀이·등록 흐름이 표시되어 있어도 포함한다. 가려진
    목록이 바뀌어도 사용자에게 보이는 화면은 바뀌지 않으므로(FR-007) 등록 흐름을 따로 제외하지 않는다(명확화 2026-09-28의
    Outstanding 항목 정리).
  - 기존 `learningProjectsReloadRequested` 전송은 `applicationBecameActive`에서 제거한다. 로그인 확인·생성 상태
    동기화·기기 등록 재시도는 모든 활성화에서 그대로 실행한다.
- **근거**:
  - 명확화 2026-09-27 질문 3: 백그라운드를 거치지 않은 비활성→활성 전환은 계기가 아니다. iOS는 백그라운드 복귀 시
    `.background → .inactive → .active` 순으로 전환하므로 `.active` 도착 시 직전 `.background` 여부만 기억하면 된다.
  - 앱 첫 실행은 `.background`를 거치지 않으므로 계기가 아니며, 목록은 화면 시작 시 최초 로드로 받는다(명세 경계 사례).
  - `isInBackground`가 `true`인 동안 도착한 결과는 백그라운드 수신이므로 요청하지 않고, 이어지는 복귀 계기가
    갱신한다(시나리오 2-3). `.inactive`(알림 센터를 내린 상태 등) 동안의 도착은 포그라운드로 본다.
  - [State 형태 컨벤션](../../docs/conventions/tca/state/shape.md): 두 값뿐이고 연관값이 없어 `Bool`이 맞다.
- **검토한 대안**:
  - `scenePhase` 전체를 State에 저장한다. `.inactive` 구분이 판정에 쓰이지 않아 기각했다.
  - SwiftUI `@State`로 기억한다. Effect를 시작하는 판정이므로 [SwiftUI 지역 상태 컨벤션](../../docs/conventions/tca/state/swiftui-local.md)에 맞지 않아 기각했다.

### L6. App의 새로고침 Effect

- **결정**: `AppRootFeature`의 helper가 `project.refreshReplacingInFlightRequest()`를 호출하는 Effect를
  `CancelID.learningProjectsRefresh`, `cancelInFlight: true`로 만든다. 결과는
  `.effect(.learningProjectsRefreshFinished(error: ProjectError?))`로 돌려받고, Reducer는 이 event에서 State를
  바꾸지 않고 `.none`을 반환하는 분기를 명시한다. 알 수 없는 오류는 `ProjectError`의 fallback case로 바꾼다.
  생성 결과 도착 관찰은 `.task`에서 `CancelID.generationOutcomeObservation`으로 시작한다.
- **근거**:
  - [Reducer 책임](../../docs/conventions/tca/effect/reducer.md): "오류를 무시하거나 View가 Domain 오류를 직접
    해석하게 하지 않습니다." `try?`로 결과를 버리지 않고 Reducer가 결과를 받아 "상태를 바꾸지 않는다"는 판단을
    코드로 드러낸다. [Effect 작성](../../docs/conventions/tca/effect/writing.md)의 "`any Error`를 Action에 전달하지
    않는다"에 따라 `ProjectError?`로 전달한다.
  - FR-006: 자동 갱신 실패는 마지막 성공 목록을 유지하고 오류를 표시하지 않는다. App은 목록 상태를 소유하지 않으므로
    반영할 State가 없다. 목록을 아직 받지 못한 화면은 자신의 `refresh()` 호출이 최신 요청 결과를 받아 처리한다(L3).
  - 결과를 State에 반영하지 않으므로 [요청 식별](../../docs/conventions/tca/state/request-identity.md)의 request ID는
    두지 않는다. 늦은 응답의 목록 반영 차단은 Domain 요청 세대가 담당한다(L3).
  - 계기가 연달아 오면 새 Effect가 이전 Effect를 대체하고, Domain은 이전 서버 요청을 취소한다(L3). 동시에 진행되는
    첫 페이지 요청은 1개다(SC-005).
  - 생성 상태 관찰(`CancelID.generationObservation`)과 같은 수명으로 `.task`에서 시작한다.
- **검토한 대안**:
  - `try?`로 결과를 버린다. 기존 풀이 흐름 종료 경로(`dismissRequested`)가 이 방식을 쓰지만 Reducer 책임 컨벤션과
    충돌하므로 새 코드에 따르지 않는다. 기존 경로 정리는 이 기능 범위 밖이다(L9 후속 항목).
  - request ID를 두고 최신 결과만 해석한다. 해석할 State가 없어 형식만 늘어나므로 기각했다.

### L7. 새 공개 이름

| 이름 | 책임 문장 | 근거 |
|---|---|---|
| `ProjectUseCase.refreshReplacingInFlightRequest()` | 진행 중인 목록 요청을 대체하고 첫 페이지를 새로 받는다 | `refresh()`와 다른 효과(대체)를 동사구로 드러낸다([operation.md](../../docs/conventions/naming/operation.md)). 비동기·실패는 시그니처가 표현한다 |
| `ProjectGenerationUseCase.outcomeArrivals() -> AsyncStream<ProjectID>` | 생성 결과가 도착한 프로젝트를 관찰한다 | 관찰 연산은 기존 `states()`처럼 방출 대상 명사로 짓는다. 원소가 "결과가 도착한 프로젝트의 식별자"임을 스트림 이름이 제공한다([boundary-value.md](../../docs/conventions/naming/boundary-value.md)) |
| `AppRootFeature.Action.View.applicationEnteredBackground` | 앱이 백그라운드에 들어갔다는 생명주기 사건 | 기존 `applicationBecameActive`와 짝을 이루는 관찰형 이름([action/naming.md](../../docs/conventions/tca/action/naming.md)) |
| `AppRootFeature.Action.EffectEvent.generationOutcomeArrived(ProjectID)` | 생성 결과 도착 스트림 사건 | Effect 그룹의 스트림 사건 이름 |
| `AppRootFeature.Action.EffectEvent.learningProjectsRefreshFinished(error: ProjectError?)` | 목록 새로고침 완료 | 완료된 작업을 표현하는 Effect event 이름([action/naming.md](../../docs/conventions/tca/action/naming.md)). 기존 `refreshFinished(requestID:error:)`와 같은 오류 전달 형태 |
| `AppRootFeature.State.isInBackground` | 마지막 활성화 이후 백그라운드에 있는지 | 판정 조건을 그대로 드러낸다 |

### L8. 테스트 설계

- **Domain `ProjectTests`**: 새 연산이 진행 중인 첫 페이지 요청을 취소하고 새로 요청한다. 대체된 응답은 목록에
  반영되지 않는다. 대체된 `refresh()` 호출자는 오류 없이 최신 결과를 받는다. 대체된 다음 페이지 호출자는 오류 없이
  반환하고 페이지가 추가되지 않는다. 연달아 호출해도 동시에 진행되는 첫 페이지 요청은 1개다. 기존 `refresh()` 합류
  테스트는 그대로 통과한다.
  - `StubProjectRepository`는 지금 첫 요청 하나만 붙잡는다. 요청별로 붙잡고 풀며, 취소를 관찰할 수 있게 확장한다.
- **Domain `ProjectGenerationTests`**: 결과를 받으면 `outcomeArrivals()`가 그 `projectID`를 방출한다. 기록이 없는
  결과도 방출한다. 보존 결과 재시도는 방출하지 않는다. 기록 반영 뒤에 방출한다. 같은 `projectID`·`status` 결과가
  다시 도착하면 방출하지 않고, 상태가 다른 결과는 방출하며, 보관 기한이 지난 뒤나 로그아웃 뒤 같은 결과는 다시 방출한다.
- **App `AppRootFeatureLearningProjectsRefreshTests`**(신규): 백그라운드→활성 시 새 연산 1회, 비활성→활성 시 0회,
  게스트·온보딩 0회, 포그라운드 결과 도착 1회, 백그라운드 중 도착 0회, 연달아 온 계기는 새 Effect가 이전을 대체한다.
  새로고침 실패는 `learningProjectsRefreshFinished(error:)`를 받아도 State가 바뀌지 않는다. 장기 관찰 Effect는
  테스트 더블의 `outcomeArrivals()` 스트림을 끝낸 뒤 `store.finish()`로 정리한다(기존 `deviceTokenRefreshes` 테스트와 같은 방식,
  [Effect 테스트](../../docs/conventions/tca/effect/testing.md)).
  기존 `AppRootFeatureTests`의 활성화 목록 재조회 테스트 3건(`mainShell 표시 중 앱이 활성화되면…`,
  `onboarding 표시 중 앱이 활성화되면…`, `포그라운드 목록 갱신이 실패해도…`)은 이 파일로 옮기고 계기 규칙에 맞게 고친다.
- **Feature**: 공개 계약이 바뀌지 않는다. 기존 수동 새로고침·페이지 이어 받기·삭제 후 갱신 테스트가 변경 없이
  통과해야 한다(SC-006). 테스트 더블은 새 요구사항만 추가한다.
- **SC-001·SC-002(2초)**와 요청 횟수 실측은 자동 테스트로 재지 않고 [quickstart](./quickstart.md)의 실기기 절차에서
  네트워크 계측으로 확인한다(명확화 2026-09-28 질문 2).

### L9. 컨벤션과 기존 관행의 충돌

- **발견**: `Feature/ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift`가 production target 안에서
  `ExternalRepositoryLocator`, `ExternalRepositoryUseCase`, `ProjectGenerationUseCase`를 구현한다.
  [feature.md 제약조건](../../docs/package-rules/feature.md)은 프리뷰를 위해서도 Domain 프로토콜을 Feature 안에서
  구현하지 말고 프리뷰는 Reducer 없이 State를 구성하라고 정한다.
- **결정**: 컨벤션을 따른다. 프리뷰 Store를 Reducer 없이(`EmptyReducer`) 구성하고 세 적합 타입을 제거한다.
  `ProjectGenerationUseCase` 요구사항을 추가하면 이 파일을 반드시 바꿔야 compile되므로, 그 integration unit 안에서
  메서드를 덧붙이는 대신 적합 타입을 제거하는 방식으로 처리한다. 별도 단위로 앞에 두면 Feature 변경이 Domain 변경보다
  먼저 오게 되어 위상 순서(Constitution 원칙 7)와 어긋난다.
- **후속 항목(범위 밖)**: `AppRootFeature`의 풀이 흐름 종료 경로가 `try? await project.refresh()`로 결과를 버리는 것은
  [Reducer 책임](../../docs/conventions/tca/effect/reducer.md)과 충돌한다. 이 기능은 그 경로를 바꾸지 않으므로 PR에
  후속 항목으로 기록한다.
- **해석 기록**: 같은 문장의 "테스트를 위해서도"는 Feature **production target** 안에 테스트용 구현을 두지 말라는
  뜻으로 해석한다. [테스트 컨벤션 — 의존성 격리](../../docs/conventions/test/dependency-isolation.md)가 테스트
  target의 Test Double이 소유 패키지 프로토콜을 구현하도록 정하고, Router Feature는 UseCase 프로토콜을 받으므로
  테스트 target의 적합 타입은 허용된다. 이 해석은 컨벤션 문서를 수정하지 않으며, 문서 갱신이 필요하면 별도 사용자
  지시로 처리한다.

## 2부. 이관 결정(045, 구현됨)

아래 결정은 `0a76670`, `573a30b`, `756696d`, `78d065c`에 구현되었다. 준비 대기 시간은 `0d6e197`에서 제거되어
완료 알림은 결과 반영 즉시 예약되며, 마감 타이머는 보관 기한만 본다.

### R1. 알림 탭과 종료 상태 실행 경로

- **결정**: `UNUserNotificationCenterDelegate`의 `userNotificationCenter(_:didReceive:)`에서 `userInfo`와
  `notification.date`를 생성 결과 수신 경로로 넘긴다. 종료 상태에서 알림 탭으로 실행되는 경우도 같은 콜백으로 처리하고
  `launchOptions[.remoteNotification]`은 읽지 않는다.
- **근거**: delegate가 `didFinishLaunching`에서 지정되므로 탭 실행 시 시스템이 `didReceive`를 호출한다. `launchOptions`까지
  읽으면 같은 알림이 두 번 전달된다.
- **검토한 대안**: `launchOptions`도 처리한다(경로만 늘어 기각). `didReceive`에서 원격 알림 콜백을 다시 부른다(경로 혼재로 기각).

### R2. 포그라운드 표시 경로도 결과로 반영

- **결정**: `userNotificationCenter(_:willPresent:)`에서도 표시 옵션을 돌려주기 전에 결과를 전달한다.
- **근거**: 시뮬레이터에서 포그라운드 alert+content-available 푸시는 `willPresent`만 호출됐다. 같은 결과가 두 번 들어와도
  기록 전이는 한 번이다(`GenerationRecord`의 확정 상태 보존).
- **검토한 대안**: 실기기 검증 뒤 추가한다(검증 전까지 반영 누락이 남아 기각).

### R3. 결과가 도착한 시각

- **결정**: 원격 알림 전달 정보(경로, 전달 시각)를 Infrastructure → Data → Domain으로 넘긴다. 백그라운드 수신은 콜백
  호출 시각, 표시·탭은 `UNNotification.date`다. `GenerationOutcome.arrivedAt`이 이 값을 받고 기록의 `finishedAt`에 쓴다.
- **근거**: 명확화 2026-09-25 Q2는 유효 시간 기준을 결과 도착 시각으로 정했다. `finishedAt`은 보관 기한 계산에도 쓰인다.
- **검토한 대안**: 기록에 `arrivedAt` 필드를 따로 둔다(영속 형식 변경과 의미 중복으로 기각).

### R4. 관찰 시작 전에 도착한 결과 보존

- **결정**: 두 층으로 보존한다.
  1. Data `PushQuizGenerationOutcomeSource`는 구독자가 없을 때 도착한 결과를 최대 32개 FIFO로 담았다가 첫 구독에 모두 넘긴다.
  2. Domain `ProjectGeneration`은 기록에 없는 프로젝트의 결과를 최대 16개, 도착 후 보관 기한(1시간)까지 메모리에 보존하고,
     상태 적용·동기화 때 다시 반영을 시도한다. 로그아웃하면 비운다.
- **근거**: 구독 전 유실은 수신을 소유한 Data가, 기록과 맞춰 보는 판단은 Domain이 담당한다. Data 버퍼는 첫 구독 전에만
  쌓이고 첫 구독 시 비워지므로 로그아웃·기간 규칙(FR-016, FR-017)은 Domain 보존에만 둔다.
- **검토한 대안**: Domain만 보존한다(구독 전 결과를 받을 수 없어 기각). App Group에 영속한다(필요 없어 기각).
- **1부와의 관계**: 이 보존 구조 때문에 결과 소스의 구독자를 `ProjectGeneration` 하나로 유지한다(L1).

### R5. 실행 중 만료 처리

- **결정**: 마감 타이머는 모든 기록의 보관 기한 도달 시각(`finishedAt ?? requestedAt` + `retentionLimit`) 중 가장 이른
  시각에 울린다. 울리면 만료 기록을 정리하고 저장소 상태를 다시 적용한다.
- **근거**: 주입된 시계와 `sleep`으로 결정적으로 테스트할 수 있고, 포그라운드에 머무는 사용자도 해제된다(FR-014).
- **검토한 대안**: 앱 활성화 시에만 정리한다(포그라운드에 머무는 사용자가 막혀 기각).

### R6. 앱 활성화 시 재동기화

- **결정**: `ProjectGenerationUseCase.synchronize()`는 관찰이 시작되지 않았으면 시작하고, 시작됐으면 만료 정리, 리마인드
  대기열 흡수, 저장소 상태 재적용, 보존 결과 재시도를 차례로 한다. `AppRootFeature`는 회원이면 모든 활성화에서 호출한다.
- **근거**: 공유 확장은 앱이 백그라운드일 때 실행되므로 활성화 시 한 번 동기화하면 반영된다. Darwin notification은 범위를 넘는다.
- **1부와의 관계**: 생성 상태 동기화는 비활성→활성 전환에서도 계속 실행한다. 목록 갱신 계기만 백그라운드 경유로 좁힌다(L5).

### R7. 로컬 알림 유효 시간 판정

- **결정**: `GenerationWaitPolicy.reminderValidity`(표준 300초). 리마인드 대상에서 먼저 꺼낸 뒤, 알림 권한이 있고
  `now - finishedAt ≤ reminderValidity`일 때만 결과 반영 즉시 예약한다.
- **근거**: 명확화 2026-09-25 Q1·Q2. 대상에서 먼저 꺼내 두므로 권한을 나중에 켜도 다시 판정되지 않는다.
- **검토한 대안**: 권한 변경을 관찰해 남은 대상을 판정한다(Q1에서 기각).

### R8. 예약된 로컬 알림 취소

- **결정**: `GenerationReminderScheduler.cancel(projectID:)`를 두고, `ProjectGeneration`이 상태를 적용할 때 이전 상태에
  있었지만 새 상태에 없는 `projectID`마다 취소한다. 로그아웃(`releaseAll`), 만료 정리, `release(_:)`를 이 규칙 하나로 덮는다.
  프로젝트를 삭제하면 `Project`의 생성자 인자 `projectDeleted`가 알리고 Composition이 `ProjectGeneration.release(_:)`에 연결한다.
- **근거**: 예약은 결과 반영 즉시 울리거나 유효 시간 안에만 만들어지고, 기록은 종료 후 1시간 남아 있으므로 기록의 프로젝트
  목록으로 취소 대상을 덮는다. 저장소 구현이 읽을 때 만료 기록을 거르므로 상태 비교 방식이 필요하다.
- **검토한 대안**: 만료 기록을 직접 찾아 취소한다(실제 저장소에서 대상을 찾지 못해 기각). 알림 센터 대기 목록 전체 취소(다른 알림을 건드려 기각).

### R9. 결과 반영 여부 판정

- **결정**: `PendingGenerationRepository.finishGeneration`이 `Bool`을 돌려준다. `false`면 보존 결과(R4)로 옮긴다.
- **근거**: 메모리 상태는 공유 확장이 쓴 기록을 모를 수 있다.

### R10. 진단 로그

- **결정**: Infrastructure(수신 경로·전달 시각), Data 결과 소스(파싱·보존·전달), Data 생성 기록 저장소(저장 후 상태별 개수)에
  로그를 남긴다. Domain·Composition은 로깅하지 않는다.
- **1부와의 관계**: 목록 자동 갱신에는 로그를 추가하지 않는다(명확화 2026-09-28 질문 2).

### R11. 탭 경로의 검증 방법

- **결정**: Infrastructure 탭·표시 콜백은 `UNNotificationResponse`를 테스트에서 만들 수 없어 컴파일 검증과 실기기 검증으로
  확인하고, 값의 흐름은 Data·Domain 테스트로 검증한다. 미검증 범위는 PR에 기록한다.

### R12. 대안으로만 남기는 서버 조회

- **결정**: 서버의 생성 상태 조회 API와 폴링은 채택하지 않는다(FR-020, 019 FR-022). 알림 권한이 없고 백그라운드 수신도
  실패하면 복구는 보관 기한(R5)과 목록 자동 갱신 계기(FR-001)에 의존한다.

## 3부. 알림 누락 뒤 앱 아이콘 복귀 복구 (2026-09-28 추가)

시나리오 8, FR-023~FR-025를 다룬다. 1부·2부 결정은 그대로 유지한다.

### 현재 구조 조사

- 생성 결과는 `FirebaseMessagingAppDelegate`(Infrastructure)의 세 콜백 → `NotificationAppDelegate`(Data) →
  `AppComposition.ingestGenerationOutcomePayload` → `PushQuizGenerationOutcomeSource.ingest`(Data) →
  `GenerationOutcomeRepositoryAdapter.outcomes()`(Composition) → `ProjectGeneration.receive`(Domain) 순서로 흐른다.
- 앱 활성화 시 `AppRootFeature`는 회원일 때 `ProjectGeneration.synchronize()`를 부르고, 백그라운드를 거친 경우
  `Project.refreshReplacingInFlightRequest()`를 부른다.
- `UNUserNotificationCenter`를 쓰는 곳은 Infrastructure(`LocalNotificationAuthorizationClient`, `FirebaseMessagingAppDelegate`)뿐이다.
- `Project`와 `ProjectGeneration`은 서로 import하지 않는다. 프로젝트 삭제 시 기록 해제는 `Project.init`의
  `projectDeleted` 클로저를 `ConcernUseCaseAssembly`가 `projectGeneration.release`로 연결한다.
- `Project.projects()`는 구독 시 목록이 없으면 첫 페이지를 요청한다. 따라서 App이 목록을 관찰해 완료를 판정하면
  게스트·로그인 전에도 목록 요청이 생길 수 있다.
- CompositionLearningProject는 이미 DataNotification에, DataNotification은 InfrastructurePushMessaging에 의존한다.

### D1. 알림 센터를 읽는 시점과 소유자

- 결정: `ProjectGeneration.synchronize()`가 기존 동기화(만료 정리, 리마인드 흡수, 상태 반영) 뒤에
  `GenerationOutcomeRepository.deliveredOutcomes()`로 알림 센터의 생성 결과를 읽어 반영한다. App 호출 지점은 바뀌지 않는다.
- 근거: FR-013의 활성화 동기화가 이미 회원 활성화마다 호출된다. 결과 반영 규칙(FR-012, FR-015, FR-016, FR-021)은
  `ProjectGeneration`이 소유하므로 같은 경로(`finish`)를 재사용하면 규칙이 한 곳에 남는다.
- 검토한 대안: App이 알림 센터를 읽어 `ingestGenerationOutcomePayload`로 다시 넣는 방식. 결과가 도착 알림
  (`outcomeArrivals`)으로도 방출되어 FR-025를 어기고, App이 Infrastructure 능력을 직접 호출해야 한다.

### D2. 알림 센터 결과의 도착 알림 억제

- 결정: 알림 센터에서 읽은 결과는 `finish`로 기록에 반영하고, 도착 알림 중복 판정 목록(`recentArrivals`)에만 넣고
  구독자에게 방출하지 않는다.
- 근거: FR-025. 같은 활성화의 FR-001 갱신이 목록을 맡는다. 판정 목록에 넣어 두면 같은 결과가 뒤늦게 백그라운드 수신으로
  다시 도착해도 목록 요청을 새로 만들지 않는다(FR-005).
- 검토한 대안: 판정 목록에도 넣지 않는 방식. 뒤늦은 중복 도착이 목록 요청을 한 번 더 만든다.

### D3. 알림 센터 읽기의 계층 배치

- 결정:
  - Infrastructure `InfrastructurePushMessaging`: 역할 프로토콜 `DeliveredNotificationClient`와 구현
    `NotificationCenterDeliveredNotificationClient`, 모델 `DeliveredRemoteNotification`(payload 문자열 사전, 전달 시각).
    원격 알림만 고르기 위해 trigger가 `UNPushNotificationTrigger`인 알림만 반환한다. payload 변환은 기존
    `RemoteNotificationPayload`를 쓴다.
  - Data `DataNotification`: 역할 계약 `DeliveredRemoteMessageReader`, 모델 `DeliveredRemoteMessage`, 내부 구현
    `DeliveredRemoteMessageClient`, 생성 진입점 `NotificationFactory.deliveredRemoteMessageReader()`. 읽은 개수를 진단 로그로 남긴다(FR-018 연장).
  - Composition `GenerationOutcomeRepositoryAdapter`: `deliveredOutcomes()`에서 `DeliveredRemoteMessage`를 기존 공개 파서
    `QuizGenerationOutcomeDTO(rawPayload:deliveredAt:)`로 변환하고 파싱 실패분을 버린 뒤 Domain `GenerationOutcome`으로 바꾼다.
    두 조립 지점(`ConcernUseCaseAssembly`, `LearningProjectAssembly`)은 `LocalReminderNotifier`와 같이 선택 인자로 reader를 받고,
    없으면 Factory 기본값을 쓴다.
- 근거: [data.md](../../docs/package-rules/data.md) — 기술 API는 Data 역할 타입 내부에서만 쓰고, Composition·테스트가 대체할 수
  있도록 Data가 역할 계약과 Factory를 공개한다. 파싱 규칙은 원격 수신 경로와 같은 DTO 생성자를 공유해 FR-023의
  "같은 파싱 기준"을 보장한다. manifest 의존성 변경이 필요 없다.
- 검토한 대안: `PushQuizGenerationOutcomeSource`가 알림 센터를 직접 읽는 방식. DataLearningProject에 Infrastructure·
  DataNotification 의존을 새로 추가해야 한다. `PushMessagingClient`에 메서드를 추가하는 방식은 Firebase 활성화 전에는
  클라이언트가 없어 읽을 수 없다.

### D4. 목록 응답으로 완료를 판정하지 않는다 (2026-09-28 수정)

- 결정: 목록 응답에 포함된 프로젝트로 생성 기록을 완료로 바꾸지 않는다. 처음 결정한 `Project.init(projectsListed:)` →
  `ProjectGenerationUseCase.completeGenerations(of:)` 연결(FR-026)은 폐기하고 구현
  커밋 `22f1a09`는 브랜치 이력에서 제거했다(`backup/project-list-refresh-22f1a09`에 보존).
- 근거: 목록 항목에는 생성 상태 필드가 없고, 생성 중인 프로젝트가 목록에 없다는 사실이 실기기에서 확인되지 않았다(`7dd9435`에서
  앱이 생성 중 프로젝트를 목록에서 걸러냈던 이력이 있다). 목록 포함으로 완료를 판정하면 생성 중 목록 갱신(최초 로드, 포그라운드
  진입, 수동 새로고침)에서 기록이 완료로 바뀌고 리마인드 대상이 지워져, 결과가 도착해도 로컬 알림이 예약되지 않는다.
- 결과: 알림 센터 결과(D1~D3)가 없으면 보관 기한 정리(R5)가 복구 경로다.

### D5. 목록 완료 판정 규칙 (폐기)

- FR-026 폐기로 이 결정(`completeGenerations(of:)`의 판정·리마인드 제외 규칙)을 폐기했다. 근거는 D4를 따른다. 식별자 D5는 재사용하지 않는다.

### D6. 새 공개 이름

| 이름 | 책임 문장 |
|---|---|
| `GenerationOutcomeRepository.deliveredOutcomes()` | 사용자에게 이미 전달되어 남아 있는 생성 결과를 조회한다 |
| `DeliveredRemoteMessageReader.deliveredMessages()` | 알림 센터에 남은 원격 메시지를 읽는다(Data 언어, 기술 이름 없음) |
| `DeliveredNotificationClient.deliveredRemoteNotifications()` | 시스템 알림 센터에서 원격 알림을 조회한다(Infrastructure) |

### D7. 테스트 설계

- Domain `ProjectGenerationTests`: 알림 센터 결과로 기록이 결과 상태가 되는지, 도착 알림이 방출되지 않는지, 이미 반영된 결과로
  로컬 알림이 다시 예약되지 않는지, 기록 없는 결과가 기록을 바꾸지 않는지.
- Data `DeliveredRemoteMessageClientTests`: Infrastructure 역할 더블로 payload·전달 시각 변환을 검증한다.
- Composition `GenerationOutcomeRepositoryAdapterTests`: 파싱 성공분만 Domain 결과로 바뀌는지.
- Infrastructure 구현은 시스템 알림 센터에 의존하므로 자동 테스트 대신 실기기 검증(시나리오 7-5)으로 확인한다.
