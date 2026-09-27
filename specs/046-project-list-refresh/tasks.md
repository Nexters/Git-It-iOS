---

description: "프로젝트 목록 자동 갱신 구현 작업 목록"
---

# 작업 목록: 프로젝트 목록 자동 갱신과 생성 상태 고착 해결

**입력**: `specs/046-project-list-refresh/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를
snapshot한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만
선택한다.

**테스트**: 명세 성공 기준(SC-003~SC-006, SC-008~SC-012)이 자동 테스트 결과를 요구하고
[research L8](./research.md#l8-테스트-설계)이 테스트 설계를 정했으므로 테스트 작업을 포함한다. 테스트는
같은 단위의 구현보다 먼저 작성하고, 요구사항이 아직 없어 compile되지 않거나 기대와 달라 실패하는
것을 확인한다.

**구성**: 실행 단위를 최상위 구조로 사용하고 변경 시나리오는 각 단위 안에서 추적한다. 단위 1·2는
프로토콜 요구사항 추가로 적합 타입이 함께 바뀌어야 compile되는 integration unit이고, 단위 3은 App
단일 패키지다.

**범위**: 생성 상태 고착 해결(시나리오 3~6, FR-009~FR-018, FR-021, FR-022)은 `0a76670`~`78d065c`에서
구현되었으므로 새 작업이 없다. 회귀는 전체 완료 검증의 기존 테스트 통과로 확인한다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[시나리오]**: [spec.md](./spec.md)의 변경 시나리오. `S1` 앱으로 돌아오면 최신 목록, `S2` 포그라운드 중
  생성 결과 알림으로 목록 갱신, `S7` 실기기 검증
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 실행 또는 수동
  검증. `make tuist`의 파생 workspace·project·심볼릭 링크·cache 갱신은 허용하되 실행 전후
  Git 상태(`git status --porcelain`)를 비교하고 추적 파일 변경이 생기면 완료로 처리하지 않는다.
- 모든 소스 경로는 저장소 루트 기준이다. 빌드 실행기는 저장소 루트에서
  `project_build_runner=$(./.tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)`로 얻는다.
- Swift 소스에는 `// MARK:` 외 주석을 쓰지 않는다. 테스트 함수 이름은 백틱 한국어 동작 문장, 프레임워크는
  Swift Testing(`@Suite`, `@Test`, `#expect`, `#require`)이다([test.md](../../docs/conventions/test.md)).
- `tasks.md`는 원자적인 작업과 의존성만 정의한다. 커밋 단위는 `/speckit-implement`가 설계한다.

## 실행 단위 소유권 규칙

- 패키지 소스·테스트와 패키지 전용 설정은 그 패키지를 소유한 실행 단위가 소유한다.
- 패키지에 속하지 않는 `specs/046-project-list-refresh/device-verification.md`는 그 칸이 검증하는 동작(App 계기
  판정)을 구현하는 실행 단위 3에 배정한다. 전체 완료 검증은 `[no-write]`만 둔다. 이 구성은 plan.md "실행 단위" 표와 같다.
- `docs/spec-kit/046-project-list-refresh/trouble-shooting.md`와 `tacit-knowledge.md`는 구현 작업으로 만들지
  않는다. 기록 조건은 Constitution 원칙 9를 따른다.

---

## 실행 단위 1: 생성 결과 도착 알림 (integration unit: Domain, Feature, App)

**목표**: `ProjectGenerationUseCase`에 `outcomeArrivals() async -> AsyncStream<ProjectID>`를 추가해, 파싱에 성공한
생성 결과가 도착할 때마다 그 프로젝트 식별자를 App이 관찰할 수 있게 한다. 같은 결과의 중복 도착은 한 번만 알린다(FR-005, SC-005, [research L1](./research.md#l1-생성-결과-도착-알림의-소유자))([contracts/domain-contracts.md](./contracts/domain-contracts.md#projectgenerationusecase)).

**분리 불가 근거**: 프로토콜 요구사항을 추가하면 App 프리뷰(`NoopProjectGeneration`), App·Feature 테스트 더블,
Feature 프리뷰 적합 타입이 같은 커밋에 없으면 compile되지 않는다. Feature 프리뷰는 메서드를 덧붙이지 않고 적합
타입을 제거한다([research L9](./research.md#l9-컨벤션과-기존-관행의-충돌)).

**소유 경로**:
- Domain: `sources/Projects/Domain/ProjectGeneration/UseCases/ProjectGenerationUseCase.swift`,
  `sources/Projects/Domain/ProjectGeneration/UseCases/ProjectGeneration.swift`,
  `sources/Projects/Domain/Tests/ProjectGeneration/UseCases/ProjectGenerationTests.swift`
- Feature: `sources/Projects/Feature/ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift`,
  `sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/ProjectGenerationUseCaseStub.swift`,
  `sources/Projects/Feature/Tests/ShareRegistration/TestDoubles/ProjectGenerationUseCaseSpy.swift`
- App: `sources/Projects/App/GitIt/Screens/AppRootView.swift`,
  `sources/Projects/App/Tests/GitIt/TestDoubles/ProjectGenerationUseCaseMock.swift`

**관련 변경 시나리오**: S2

**통합 검증**: `"$project_build_runner" compile`(모든 공유 test scheme의 build-for-testing)

### 테스트

- [X] T001 [S2] `sources/Projects/Domain/Tests/ProjectGeneration/UseCases/ProjectGenerationTests.swift`에 `outcomeArrivals()` 테스트를 추가한다. 기존 `StubGenerationOutcomeRepository.emit(_:)`와 `InMemoryPendingGenerationRepository`로 다음을 각각 별도 `@Test`로 검증한다: (1) `` `생성 결과가 도착하면 그 프로젝트 식별자를 도착 알림으로 방출한다` `` (2) `` `생성 기록이 없는 프로젝트의 결과도 도착 알림으로 방출한다` `` (3) `` `보존한 결과를 다시 반영할 때는 도착 알림을 방출하지 않는다` ``(기록 없이 결과 도착 → 방출 1회 확인 → 기록 추가 후 `synchronize()` → 추가 방출 없음) (4) `` `도착 알림은 생성 기록 반영을 마친 뒤 방출한다` ``(방출을 받은 시점에 `states()`가 이미 그 기록을 `.ready`로 방출했는지 확인) (5) `` `같은 프로젝트의 같은 결과가 다시 도착하면 도착 알림을 다시 방출하지 않는다` ``(같은 `projectID`·`status`를 두 번 `emit` → 방출 1회) (6) `` `같은 프로젝트라도 상태가 다른 결과는 도착 알림을 방출한다` `` (7) `` `보관 기한이 지난 뒤 같은 결과가 다시 도착하면 도착 알림을 방출한다` ``(주입한 `now`를 `retentionLimit` 이후로 진행) (8) `` `로그아웃한 뒤 같은 결과가 다시 도착하면 도착 알림을 방출한다` ``(`signedOutEvents` 방출 후). 실제 시간과 `sleep`에 의존하지 않고 기존 `ManualSleeper`를 사용한다

### 구현

- [X] T002 [S2] `sources/Projects/Domain/ProjectGeneration/UseCases/ProjectGenerationUseCase.swift`에 요구사항 `func outcomeArrivals() async -> AsyncStream<ProjectID>`를 `states()` 다음 순서로 추가한다
- [X] T003 [S2] `sources/Projects/Domain/ProjectGeneration/UseCases/ProjectGeneration.swift`에 `outcomeArrivals()`를 구현한다: `states()`와 같은 방식으로 `startObserving()`을 호출하고 `[UUID: AsyncStream<ProjectID>.Continuation]` 구독자 저장소(종료 시 제거)에 등록한다. `start()`의 결과 스트림 루프는 `finish(outcome)`을 마친 뒤 `outcome.projectID`를 모든 도착 구독자에게 yield하는 private 메서드를 호출한다. `retryPreservedOutcomes()`가 부르는 `finish(_:)` 경로에서는 방출하지 않는다. 구독 전 도착은 재생하지 않는다. 중복 도착 억제를 위해 `[GenerationOutcome]` 타입의 최근 도착 결과 상태를 actor 내부에 두고, 방출 전에 같은 `projectID`·`status`이면서 `now() - arrivedAt ≤ waitPolicy.retentionLimit`인 항목이 있으면 방출하지 않는다. 방출하면 끝에 추가하고 32개를 넘으면 가장 오래된 것부터 제거한다. `releaseAll()`에서 비운다. 기록 반영(`finish`)은 억제 여부와 관계없이 수행한다. 상한 32는 `private static let` 상수로 둔다([data-model §2](./data-model.md#2-생성-결과-도착-알림--projectgeneration-actor-domainprojectgeneration))
- [X] T004 [P] `sources/Projects/Feature/ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift`에서 `PreviewRepositoryLocator`, `PreviewExternalRepository`, `PreviewProjectGeneration` 적합 타입을 제거하고, `store(phase:step:)`가 같은 `State`를 구성한 뒤 `Store(initialState: state) { EmptyReducer() }`를 반환하도록 바꾼다. 쓰이지 않게 된 import(`DomainProjectGeneration`, `DomainIdentifier` 등)를 제거하고 `sampleRepository`와 `#if DEBUG` 범위는 유지한다([feature.md 제약조건](../../docs/package-rules/feature.md), [view/preview.md](../../docs/conventions/view/preview.md))
- [X] T005 [P] `sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/ProjectGenerationUseCaseStub.swift`에 `outcomeArrivals()`를 추가한다. 즉시 끝나는 빈 스트림(`AsyncStream { $0.finish() }`)을 반환한다
- [X] T006 [P] `sources/Projects/Feature/Tests/ShareRegistration/TestDoubles/ProjectGenerationUseCaseSpy.swift`에 `outcomeArrivals()`를 추가한다. 즉시 끝나는 빈 스트림을 반환한다
- [X] T007 [P] `sources/Projects/App/GitIt/Screens/AppRootView.swift`의 프리뷰 `NoopProjectGeneration`에 `outcomeArrivals()`를 추가한다. 즉시 끝나는 빈 스트림을 반환한다
- [X] T008 [P] `sources/Projects/App/Tests/GitIt/TestDoubles/ProjectGenerationUseCaseMock.swift`에 `outcomeArrivals()`를 추가한다. 이 단위에서는 즉시 끝나는 빈 스트림만 반환한다(제어 기능은 T021)

### 정리와 단위 검증

- [X] T009 [no-write] 저장소 루트에서 `"$project_build_runner" compile`을 실행해 Domain·Feature·App test scheme이 모두 compile되는지 통합 검증하고 결과를 기록한다

**진행 점검**: T001~T009의 변경 파일과 검증 결과를 보고하고 실행 단위 2로 진행한다. 새 범위나 권한이 필요하면
여기서 중단하고 명시적 승인을 요청한다.

---

## 실행 단위 2: 진행 중 요청을 대체하는 새로고침 (integration unit: Domain, Feature, App)

**목표**: `ProjectUseCase`에 `refreshReplacingInFlightRequest() async throws`를 추가한다. 진행 중인 첫 페이지·다음
페이지 요청을 취소하고 첫 페이지를 새로 요청하며, 대체된 응답은 반영하지 않고, 대체된 호출자는 오류 없이 최신
결과를 받는다([contracts/domain-contracts.md](./contracts/domain-contracts.md#projectusecase),
[data-model §1](./data-model.md#1-목록-요청-상태--project-actor-domainproject)).

**분리 불가 근거**: 프로토콜 요구사항을 추가하면 App 프리뷰(`NoopProject`), App·Feature 테스트 더블이 같은 커밋에
없으면 compile되지 않는다. 단위 1과 Domain 관심사가 달라 서로 의존하지 않으며 독립적으로 되돌릴 수 있다.

**소유 경로**:
- Domain: `sources/Projects/Domain/Project/UseCases/ProjectUseCase.swift`,
  `sources/Projects/Domain/Project/UseCases/Project.swift`,
  `sources/Projects/Domain/Tests/Project/TestDoubles/StubProjectRepository.swift`,
  `sources/Projects/Domain/Tests/Project/UseCases/ProjectTests.swift`
- Feature: `sources/Projects/Feature/Tests/Home/TestDoubles/ProjectUseCaseMock.swift`,
  `sources/Projects/Feature/Tests/ProjectDetail/TestDoubles/ProjectUseCaseDetailStub.swift`
- App: `sources/Projects/App/GitIt/Screens/AppRootView.swift`,
  `sources/Projects/App/Tests/GitIt/TestDoubles/ProjectUseCaseMock.swift`

**관련 변경 시나리오**: S1, S2

**통합 검증**: `"$project_build_runner" compile`

### 준비

- [X] T010 [S1] `sources/Projects/Domain/Tests/Project/TestDoubles/StubProjectRepository.swift`를 확장한다: 요청마다 붙잡을 수 있게 하고(예: 붙잡을 요청 순번 집합), 순번으로 하나씩 풀 수 있게 하며, 붙잡힌 요청이 취소되면 `withTaskCancellationHandler`로 즉시 `CancellationError`를 던지고 취소된 요청 순번을 기록한다. 페이지별 응답을 요청 순번별로 다르게 줄 수 있게 한다. 기존 `holdsFirstRequest`, `release()`, `setPage(_:at:)`, `setFailure(_:)`, `requestedPageIndexes`의 동작은 유지해 기존 테스트가 그대로 통과해야 한다

### 테스트

- [X] T011 [S1] [S2] `sources/Projects/Domain/Tests/Project/UseCases/ProjectTests.swift`에 새 연산 테스트를 각각 별도 `@Test`로 추가한다: (1) `` `대체 새로고침은 진행 중인 첫 페이지 요청을 취소하고 새로 요청한다` ``(요청 2회, 첫 요청 취소 기록) (2) `` `대체된 첫 페이지 응답은 목록에 반영하지 않는다` ``(취소를 무시하고 늦게 도착한 옛 응답이 목록을 바꾸지 않음) (3) `` `대체된 새로고침 호출자는 오류 없이 최신 요청의 결과를 받는다` ``(`refresh()` 진행 중 대체 → 기존 호출이 throw 없이 반환하고 목록은 새 응답) (4) `` `대체 새로고침이 진행 중인 다음 페이지 요청을 취소하면 오류 없이 끝나고 페이지를 붙이지 않는다` `` (5) `` `대체 새로고침을 연달아 호출해도 진행 중인 첫 페이지 요청은 하나다` `` (6) `` `대체 새로고침이 실패하면 오류를 전달하고 마지막 목록을 유지한다` `` (7) `` `두 구독자가 대체 새로고침 결과를 같은 목록으로 받는다` ``(`projects()` 구독 둘이 새 첫 페이지 목록을 똑같이 받음, FR-008). 기존 8개 테스트(`첫 로드와 새로고침이 동시에 일어나면 첫 페이지를 한 번만 요청한다` 포함)는 수정하지 않는다

### 구현

- [X] T012 [S1] `sources/Projects/Domain/Project/UseCases/ProjectUseCase.swift`에 요구사항 `func refreshReplacingInFlightRequest() async throws`를 `refresh()` 다음 순서로 추가한다
- [X] T013 [S1] `sources/Projects/Domain/Project/UseCases/Project.swift`에 `refreshReplacingInFlightRequest()`를 구현하고 대기 규칙을 보강한다: `epoch`를 증가시키고 진행 중인 `firstPageTask`·`nextPageTask`를 `cancel()` 후 `nil`로 두며 목록은 유지한 채 새 세대로 첫 페이지 요청을 시작한다. 첫 페이지 호출자(`refresh()`와 새 연산)는 기다리던 요청이 대체로 끝나면 오류 없이 최신 `firstPageTask`를 이어서 기다리고, 다음 페이지 호출자는 대체되면 오류 없이 반환한다. "대체됨"은 요청 세대 비교와 대체 사유로 판정하고 오류 종류로 판정하지 않는다. 로그아웃 `reset()`의 기존 동작(요청 미취소, 기다리던 결과 그대로 전달)은 바꾸지 않는다([research L3](./research.md#l3-대체된-요청과-호출자의-처리))
- [X] T014 [P] `sources/Projects/Feature/Tests/Home/TestDoubles/ProjectUseCaseMock.swift`에 `refreshReplacingInFlightRequest()`를 추가한다. 호출 횟수만 기록하고 즉시 반환한다. 기존 `snapshot()` 반환 형태는 바꾸지 않는다
- [X] T015 [P] `sources/Projects/Feature/Tests/ProjectDetail/TestDoubles/ProjectUseCaseDetailStub.swift`에 `refreshReplacingInFlightRequest()`를 추가한다. 기존 `refresh()`처럼 아무 일도 하지 않는다
- [X] T016 [P] `sources/Projects/App/GitIt/Screens/AppRootView.swift`의 프리뷰 `NoopProject`에 `refreshReplacingInFlightRequest()`를 추가한다. 기존 `refresh()`처럼 `CancellationError()`를 던진다
- [X] T017 [P] `sources/Projects/App/Tests/GitIt/TestDoubles/ProjectUseCaseMock.swift`에 `refreshReplacingInFlightRequest()`를 추가한다. 이 단위에서는 즉시 반환만 한다(기록·제어 기능은 T020)

### 정리와 단위 검증

- [X] T018 [no-write] 저장소 루트에서 `"$project_build_runner" compile`을 실행해 통합 검증하고 결과를 기록한다

**진행 점검**: T010~T018의 변경 파일과 검증 결과를 보고하고 실행 단위 3으로 진행한다. 새 범위나 권한이 필요하면
여기서 중단하고 명시적 승인을 요청한다.

---

## 실행 단위 3: 생명주기·생성 결과 계기 판정 (단일 패키지: App)

**목표**: `AppRootFeature`가 백그라운드→활성 전환과 포그라운드 중 생성 결과 도착을 판정해 회원·메인 화면 흐름에서
`refreshReplacingInFlightRequest()`를 한 번 호출한다. `GitItApp`은 `.background` 전환을 전달한다
([contracts/app-lifecycle-refresh.md](./contracts/app-lifecycle-refresh.md), [data-model §3](./data-model.md#3-계기-판정-상태--approotfeature-gitit)).

**소유 경로**: `sources/Projects/App/GitIt/GitItApp.swift`, `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`,
`sources/Projects/App/Tests/GitIt/TestDoubles/ProjectUseCaseMock.swift`,
`sources/Projects/App/Tests/GitIt/TestDoubles/ProjectGenerationUseCaseMock.swift`,
`sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureLearningProjectsRefreshTests.swift`(신규),
`sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`,
`specs/046-project-list-refresh/device-verification.md`(패키지 밖 파일, 이 단위에 배정)

**관련 변경 시나리오**: S1, S2, S7

**독립 검증**: `"$project_build_runner" compile`. App 테스트는 전체 완료 검증의 `test`에서 실행한다.

### 준비

- [X] T019 [S1] `sources/Projects/App/Tests/GitIt/TestDoubles/ProjectUseCaseMock.swift`의 `refreshReplacingInFlightRequest()`가 호출 횟수(`replacingRefreshCallCount`)를 기록하고, 생성자 인자로 받은 오류(`replacingRefreshError: ProjectError?`, 기본 `nil`)를 던지며, 선택적으로 첫 호출을 붙잡았다가 테스트가 풀 수 있게 한다(연속 계기 대체 검증용). 붙잡은 호출은 `withTaskCancellationHandler`로 감싸 Effect가 `cancelInFlight`로 취소되면 즉시 `CancellationError`를 던지고 붙잡힘을 해제해, 테스트가 끝나지 않는 대기를 남기지 않는다. 동시 접근 기록은 `actor` 안에 둔다([test/dependency-isolation.md](../../docs/conventions/test/dependency-isolation.md)). 기존 생성자 기본값과 `refresh()` 동작은 바꾸지 않는다
- [X] T020 [S2] `sources/Projects/App/Tests/GitIt/TestDoubles/ProjectGenerationUseCaseMock.swift`의 `outcomeArrivals()`가 `keepsObservationOpen`이 `true`이면 스트림을 열어 두고, 테스트가 `emitArrival(_ projectID: ProjectID)`로 방출하고 `finishArrivals()`로 끝낼 수 있게 한다. `keepsObservationOpen`이 `false`(기본)이면 즉시 끝난다. 기존 `emit(_:)`, `finish()` 동작은 유지한다

### 테스트

- [X] T021 [S1] [S2] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureLearningProjectsRefreshTests.swift`를 새로 만들고 `@Suite`에 다음 `@Test`를 둔다. 기존 `AppRootTestSupport`·`AppRootTestFixture`로 Store를 만들고, 장기 관찰 Effect는 테스트 더블 스트림을 끝낸 뒤 `await store.finish()`로 정리한다([effect/testing.md](../../docs/conventions/tca/effect/testing.md)): (1) `` `mainShell 표시 중 백그라운드에서 돌아오면 목록을 대체 새로고침한다` ``(`applicationEnteredBackground` → `applicationBecameActive`, `isInBackground` 전이 확인, `replacingRefreshCallCount == 1`, `refreshCallCount == 0`) (2) `` `백그라운드를 거치지 않고 활성화되면 목록을 새로고침하지 않는다` `` (3) `` `onboarding 표시 중 백그라운드에서 돌아와도 목록을 새로고침하지 않는다` `` (4) `` `게스트 상태에서 백그라운드에서 돌아와도 목록을 새로고침하지 않고 백그라운드 표시를 해제한다` `` (5) `` `대체 새로고침이 실패해도 mainShell 화면과 상태를 유지한다` ``(`learningProjectsRefreshFinished(error: .temporarilyUnavailable)` 수신 후 State 불변) (6) `` `포그라운드에서 생성 결과가 도착하면 목록을 대체 새로고침한다` `` (7) `` `백그라운드에서 생성 결과가 도착하면 목록을 새로고침하지 않는다` `` (8) `` `게스트 상태에서 생성 결과가 도착하면 목록을 새로고침하지 않는다` `` (9) `` `연달아 온 계기는 앞선 새로고침 Effect를 대체해 완료 이벤트를 한 번만 받는다` `` (10) `` `상세 화면이 열린 채 백그라운드에서 돌아오면 상세 표시를 유지하고 목록을 새로고침한다` `` (11) `` `백그라운드에서 돌아오면 생성 상태 동기화도 함께 실행한다` `` (12) `` `onboarding 표시 중 생성 결과가 도착하면 목록을 새로고침하지 않는다` ``. 새로고침 결과는 `store.receive(\.effect.learningProjectsRefreshFinished)`로 받는다
- [X] T022 [S1] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`에서 T021로 대체된 기존 테스트 3개 `` `mainShell 표시 중 앱이 활성화되면 프로젝트 목록을 다시 조회한다` ``, `` `onboarding 표시 중 앱이 활성화되면 프로젝트 목록을 조회하지 않는다` ``, `` `포그라운드 목록 갱신이 실패해도 mainShell 화면을 유지한다` ``를 제거한다. 다른 `applicationBecameActive` 테스트(로그인 무효화, 기기 등록 재시도, 생성 상태 동기화, 동시 등록 1회)는 활성화가 더 이상 `learningProjectsReloadRequested`를 보내지 않는 것에 맞춰 기대 Action만 고치고 검증 대상은 유지한다

### 구현

- [X] T023 [S1] [S2] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`를 계약대로 바꾼다: `State.isInBackground: Bool = false` 추가. `Action.View.applicationEnteredBackground`, `Action.EffectEvent.generationOutcomeArrived(ProjectID)`, `Action.EffectEvent.learningProjectsRefreshFinished(error: ProjectError?)` 추가. `CancelID.generationOutcomeObservation`, `CancelID.learningProjectsRefresh` 추가. `.task`의 기존 생성 상태 관찰 옆에 `projectGeneration.outcomeArrivals()` 관찰 Effect를 추가해 원소마다 `.effect(.generationOutcomeArrived)`를 보낸다. `applicationEnteredBackground`는 `isInBackground = true`. `applicationBecameActive`는 기존 guard보다 먼저 `isInBackground`를 읽고 `false`로 되돌리며, 기존 `learningProjectsReloadRequested` 전송을 제거하고, 백그라운드를 거쳤고 `route == .mainShell`이면 목록 새로고침 Effect를 추가한다. `generationOutcomeArrived`는 `!isInBackground`, `route == .mainShell`, `mainShell.access == .member`일 때만 새로고침한다. `learningProjectsRefreshFinished`는 State를 바꾸지 않고 `.none`을 반환하는 분기로 명시한다. 새로고침 helper는 `project.refreshReplacingInFlightRequest()`를 `.run`으로 호출해 성공 시 `error: nil`, 실패 시 `ProjectError`(알 수 없으면 `.unexpected`)로 결과를 보내고 `.cancellable(id: CancelID.learningProjectsRefresh, cancelInFlight: true)`를 붙인다. Action 분기는 연관값 한 단계씩, `default` 없이 작성한다([effect/reducer.md](../../docs/conventions/tca/effect/reducer.md))
- [X] T024 [S1] `sources/Projects/App/GitIt/GitItApp.swift`의 `.onChange(of: scenePhase)`가 새 값이 `.active`이면 `.view(.applicationBecameActive)`, `.background`이면 `.view(.applicationEnteredBackground)`를 보내고 `.inactive`와 알 수 없는 값은 보내지 않도록 바꾼다
- [X] T025 [S7] `specs/046-project-list-refresh/device-verification.md`의 "목록 자동 갱신 (046)" 표에 "갱신 응답에 알림 프로젝트 포함" 열을 추가하고 모든 행을 `(관찰 대기)` 또는 해당 없는 행은 `—`로 채운다. 표 위에 요청 횟수는 네트워크 계측으로 센다는 한 줄을 추가한다([quickstart §4](./quickstart.md#4-실기기-검증fr-019-sc-013)). 다른 표와 기존 관찰 기록은 바꾸지 않는다

### 정리와 단위 검증

- [X] T026 [no-write] 저장소 루트에서 `"$project_build_runner" compile`을 실행해 App 단위를 검증하고 결과를 기록한다

**진행 점검**: T019~T026의 변경 파일과 검증 결과를 보고하고 전체 완료 검증으로 진행한다. 새 범위나 권한이 필요하면
여기서 중단하고 명시적 승인을 요청한다.

---

## 전체 완료 검증

**선행 조건**: 실행 단위 3의 파일 변경 작업을 완료하고, 전체 검증과 hook 결과를 포함할 마지막 커밋 단위를 아직
commit하지 않은 상태여야 한다.

**커밋 경계**: 아래 `[no-write]` 작업은 실행 단위 3의 마지막 커밋 단위에 배정한다. 모든 검증과 필수
`after_implement` hook(`speckit.swift-format.run`)을 마친 뒤 그 단위를 최종 commit한다. 이미 파일 변경 단위가 모두
commit된 단순 재개에서는 `tasks.md` 완료 표시를 위한 별도 최종 검증 단위를 둔다. 읽기 전용 전체 검증은 반복 승인
없이 같은 실행에서 이어서 수행한다.

- [X] T027 [no-write] 저장소 루트에서 `"$project_build_runner" build`, `"$project_build_runner" compile`, `"$project_build_runner" test`를 순서대로 한 번씩 실행하고(병렬 금지) 각 결과를 따로 기록한다. 실패하면 구성·컴파일·테스트·Simulator 환경 중 어디서 실패했는지 분류한다. 기존 Feature 테스트(수동 새로고침, 페이지 이어 받기, 삭제 후 갱신)와 045 관련 Domain·Data 테스트가 변경 없이 통과하는지 확인한다(SC-006, SC-012)
- [X] T028 [no-write] 변경 시나리오별 수용 기준을 확인한다: S1·S2는 T001·T011·T021의 자동 테스트 결과로 확인한다. SC-003의 "파싱할 수 없는 원격 알림은 요청 0회"는 결과가 Domain에 도착하지 않는다는 기존 Data 테스트 `` `디코딩 실패 payload는 조용히 폐기된다` ``(`sources/Projects/Data/Tests/LearningProject/Sources/PushQuizGenerationOutcomeSourceTests.swift`) 통과로, FR-008은 T011 (7)로 확인한다. S3~S6은 기존 테스트 통과로 확인한다. S7(실기기 검증, FR-019·SC-013)과 SC-001·SC-002(2초)는 개발자가 [quickstart §4](./quickstart.md#4-실기기-검증fr-019-sc-013) 절차로 실기기에서 수행해야 하므로, 수행 여부를 확인하고 수행되지 않았으면 백그라운드 수신 경로, 2초 기준, 서버 목록 반영 순서를 PR의 미검증 범위로 넘긴다

## 의존성과 실행 순서

### 실행 단위 순서와 위험 기반 승인

- 순서: 실행 단위 1 → 실행 단위 2 → 실행 단위 3 → 전체 완료 검증.
- 근거: [아키텍처 문서 3.1](../../docs/architecture.md)에서 App → Feature → Domain이다. 단위 1·2는 각 단위 안에서
  Domain → Feature → App 순서로 작업을 배치했다. 단위 1과 2는 서로 다른 Domain 관심사(`DomainProjectGeneration`,
  `DomainProject`)여서 서로 의존하지 않으며, 이 문서는 단위 1을 먼저 두기로 확정한다. 단위 3은 두 연산을 모두
  호출하므로 마지막이다.
- 각 단위의 변경 파일과 검증 결과를 보고하되 같은 기능 범위에서는 반복 승인을 요구하지 않는다.
- 승인이 필요한 경우: 컨벤션 문서 수정이 필요해지거나, 이 문서에 없는 파일(예: Composition, Data, Feature
  production Reducer)을 바꿔야 하거나, 기존 테스트의 검증 대상을 바꿔야 할 때 중단하고 명시적 승인을 요청한다.

### 변경 시나리오 추적성

| 시나리오 | 요구사항 | 작업 |
|---|---|---|
| S1 앱으로 돌아오면 최신 목록 | FR-001, FR-004~FR-008 | T010~T013, T019, T021~T024, T027, T028 |
| S2 포그라운드 중 생성 결과 알림 | FR-002~FR-008(FR-005 중복 도착 억제 포함) | T001~T003, T011, T020, T021, T023, T027, T028 |
| S3~S6 생성 상태 고착(구현됨) | FR-009~FR-018, FR-021, FR-022 | T027(회귀) |
| S7 실기기 검증 | FR-019, SC-013 | T025, T028 |

적합 타입 갱신 작업(T004~T008, T014~T017)은 특정 시나리오가 아니라 compile을 위한 integration 작업이라 라벨이 없다.

### 실행 단위 내부 실행

- 단위 1: T001(Red) → T002 → T003 → T004~T008 병렬 가능 → T009.
- 단위 2: T010 → T011(Red) → T012 → T013 → T014~T017 병렬 가능 → T018.
- 단위 3: T019·T020 병렬 가능 → T021 → T022 → T023 → T024 → T025 → T026.
- `[P]`는 같은 단위 안의 서로 다른 파일에만 붙였다. `AppRootView.swift`는 단위 1(T007)과 단위 2(T016)가 모두 바꾸므로
  단위를 넘어 병렬 실행하지 않는다. `ProjectUseCaseMock.swift`(App)와 `ProjectGenerationUseCaseMock.swift`는 단위 1·2에서
  compile용 최소 구현, 단위 3에서 기록·제어 기능을 더한다.
- 각 커밋 단위는 포함 작업 ID, 정확한 파일 경로, 검증과 커밋 메시지를 먼저 제시한다. 단위의 검증과 `[X]` 표시를 완료한
  뒤 해당 파일과 이 `tasks.md`만 stage·commit하고, 커밋 성공을 확인하기 전에는 다음 단위를 시작하지 않는다.
- 마지막 단위는 전체 완료 검증과 필수 `after_implement` hook이 끝날 때까지 commit하지 않는다.

### 병렬 실행 예시(현재 실행 단위 안에서만)

```text
실행 단위 1, T003 완료 후:
  T004 ShareRegistrationPreviewSupport.swift
  T005 ProjectGenerationUseCaseStub.swift
  T006 ProjectGenerationUseCaseSpy.swift
  T007 AppRootView.swift
  T008 ProjectGenerationUseCaseMock.swift

실행 단위 3 시작:
  T019 ProjectUseCaseMock.swift
  T020 ProjectGenerationUseCaseMock.swift
```

## 구현 전략

1. 이 tasks.md의 blob hash와 전체 diff를 기준선으로 고정한다. 명세 산출물 폴더(`specs/046-project-list-refresh/`)가
   아직 추적되지 않았으므로, 첫 구현 커밋에 섞이지 않도록 기준선 처리 방법(별도 문서 커밋 여부)을 구현 시작 시 확인한다.
2. 실행 단위 1의 미완료 작업을 논리적 커밋 단위로 설계하고 구현·검증·완료 표시·커밋을 마친다.
3. 실행 단위 2, 3을 같은 방식으로 진행한다. 실행 단위 3의 마지막 커밋 단위는 전체 완료 검증과 필수 hook까지 열어 둔다.
4. 최소 가치 범위는 S1(실행 단위 2·3의 S1 작업)이지만, S2와 공유하는 App 파일이 있어 세 단위를 연속 진행한다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 새 공개 이름: `ProjectUseCase.refreshReplacingInFlightRequest()`, `ProjectGenerationUseCase.outcomeArrivals()`,
  `AppRootFeature.State.isInBackground`, `AppRootFeature.Action.View.applicationEnteredBackground`,
  `AppRootFeature.Action.EffectEvent.generationOutcomeArrived(_:)`, `learningProjectsRefreshFinished(error:)`
  ([research L7](./research.md#l7-새-공개-이름)). 네이밍만 바꾸는 작업은 없다.
- 범위 밖 후속 항목: 풀이 흐름 종료 경로의 `try? await project.refresh()`([research L9](./research.md#l9-컨벤션과-기존-관행의-충돌))는
  이 작업 목록에 포함하지 않고 PR에 기록한다.
