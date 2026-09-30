---

description: "서버 프로젝트 목록에서 확인된 생성 중 프로젝트를 완료로 반영 — 작업 목록"
---

# 작업 목록: 서버 프로젝트 목록에서 확인된 생성 중 프로젝트를 완료로 반영

**입력**: `specs/049-generation-list-completion/`의 설계 문서

**선행 조건**: plan.md, spec.md, research.md, data-model.md, contracts/list-confirmed-completion.md, quickstart.md

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를 snapshot한다. 별도
기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만 선택한다.

**테스트**: 명세의 독립 테스트와 성공 기준(SC-001, SC-003, SC-004, SC-005, SC-006)이 자동 검증을 요구하므로
테스트 작업을 포함한다. Swift Testing(`@Suite`, `@Test`)과 한국어 동작 문장 테스트 이름을 쓰고, Test Double은
initializer로 주입한다([테스트 컨벤션](../../docs/conventions/test.md)). 테스트 작업은 같은 단위의 구현 작업보다
먼저 둔다.

**구성**: plan.md "실행 단위"의 순서(U1 Domain → U2 Domain+Composition → U3 문서)를 따른다. Composition은
Domain에 의존하므로 Domain이 먼저이고, U2가 U1의 `confirmCompletion(of:)`을 연결하므로 U1이 앞선다
([research R8](./research.md#r8-실행-단위와-위상-순서)).

**경로 기준**: 모든 소스 경로는 저장소 루트 기준이며 `sources/Projects/` 아래에 있다.

**검증 명령**: 저장소 루트에서 다음으로 실행기를 판독한 뒤 사용한다. `build`·`compile`·`test`는
`sources/DerivedData/PreCommit`을 공유하므로 순차 실행한다. 새 파일·target이 없으므로 `make tuist`는 필요 없다.

```sh
project_build_runner=$(./.tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
```

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[S1]**: 시나리오 1 — 결과 알림 없이 목록에 나타난 프로젝트로 생성 중 해제(P1)
- **[S2]**: 시나리오 2 — 생성 진행 화면이 목록 확인으로 완료 흐름으로 넘어감(P1)
- **[S3]**: 시나리오 3 — 목록 확인과 원격 알림이 함께 와도 결과는 한 번(P2)
- **[S4]**: 시나리오 4 — 결과 경로 가정과 알림 방식 기록 갱신(P3)
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 실행 또는 수동 검증. 실행 전후
  `git status --porcelain`을 비교하고, 추적 파일 변경이 생기면 완료로 처리하지 않는다.

## 실행 단위 소유권 규칙

- 패키지 소스·테스트는 그 패키지를 포함한 실행 단위가 소유한다. 새 파일·target·manifest 변경은 없다.
- 공개 이름은 [research R2](./research.md#r2-공개-이름)를 따른다. `confirmCompletion(of:)`은
  `ProjectGenerationUseCase` 프로토콜에 추가하지 않는다. 그래서 App·Feature의 conformer는 바꾸지 않는다.
- `projectsListed`에 기본값을 두지 않는다([R1](./research.md#r1-두-관심사의-연결-방식fr-001)).
- 각 단위 시작 시 해당 단위의 식별자를 `sources/Projects`에서 다시 검색한다. 이 문서 작성 시점(2026-10-01)의
  목록과 다른 파일이 나오면 누락 파일을 단위에 추가하기 전에 중단하고 보고한다.
- `docs/spec-kit/049-generation-list-completion/trouble-shooting.md`와 `tacit-knowledge.md`는 작업으로 만들지 않는다.

---

## 실행 단위 U1: 목록 확인으로 진행 중 생성 기록을 완료로 반영 (단일 패키지: Domain)

**목표**: `ProjectGeneration`에 목록으로 확인된 프로젝트의 진행 중 기록을 완료로 반영하는 연산을 추가한다
(FR-001~FR-007).

**관련 변경 시나리오**: [S1], [S2], [S3]

**독립 검증**: `"$project_build_runner" compile`. [판정표](./contracts/list-confirmed-completion.md#판정표) 7행과
부수 효과 표를 테스트로 검증한다.

### 테스트

- [X] T001 [S1] [S2] [S3] `sources/Projects/Domain/Tests/ProjectGeneration/UseCases/ProjectGenerationTests.swift`에 다음 테스트를 추가한다. 기존 `Fixture`·`Self.outcome`·`Self.next`·`Self.settle` 헬퍼를 그대로 쓴다
  - `목록에서 확인된 진행 중 프로젝트를 완료로 기록한다` — 요청 뒤 `confirmCompletion(of: ["p1"])`. 기록이 `completed`이고 `finishedAt`이 호출 시점 `sleeper.now`다(판정표 1, FR-003)
  - `목록에 없는 진행 중 프로젝트는 바꾸지 않는다` — `confirmCompletion(of: ["p-other"])` 뒤 기록이 `inProgress`다(판정표 2)
  - `프로젝트 식별자가 없는 기록은 목록 확인으로 바꾸지 않는다` — `Self.unattachedState`로 시작해 어떤 식별자로 불러도 기록이 그대로다(판정표 3)
  - `이미 완료되거나 실패한 기록은 목록 확인으로 바꾸지 않는다` — `.completed`·`.failed` 인자의 parameterized 테스트. 원격 알림으로 먼저 끝낸 뒤 `confirmCompletion`을 불러도 상태와 `finishedAt`이 그대로다(판정표 4·5, FR-005)
  - `기록에 없는 프로젝트의 목록 확인은 기록을 만들지 않는다` — 빈 상태에서 불러도 `records`가 비어 있다(판정표 6)
  - `빈 목록 확인은 어떤 기록도 바꾸지 않는다` — `confirmCompletion(of: [])`(판정표 7)
  - `목록 확인은 도착 알림을 방출하지 않는다` — `outcomeArrivals()` 구독 뒤 `confirmCompletion`. 상태는 `ready`가 되지만 도착 스트림은 아무것도 내지 않는다(FR-006)
  - `목록 확인으로 완료되면 상태 구독자가 ready를 받는다` — `states()` 구독 중 `confirmCompletion`. `Self.next`로 `ready`를 받는다(FR-002)
  - `목록 확인으로 완료된 뒤 같은 프로젝트의 결과가 도착해도 완료 시각이 바뀌지 않는다` — `confirmCompletion` 뒤 `sleeper.advance` 후 `QUIZ_READY` 결과를 emit. `finishedAt`이 목록 확인 시각이고 `finishedProjectIDs`에 호출은 남지만 기록은 그대로다(계약 "순서 조합" 1행)
  - `관찰을 시작하기 전의 목록 확인도 저장소에 반영한다` — `request`만 하고 `states()`를 구독하지 않은 채 `confirmCompletion`. `pendingGenerations.state`의 기록이 `completed`다

### 구현

- [X] T002 [S1] [S2] [S3] `sources/Projects/Domain/ProjectGeneration/UseCases/ProjectGeneration.swift`에 `public func confirmCompletion(of projectIDs: [ProjectID]) async`를 추가한다. `release(_:)` 뒤에 둔다
  - 인자가 비어 있으면 바로 반환한다
  - `pendingGenerations.pendingState().records` 중 `status == .inProgress`이고 `projectID`가 인자 집합에 있는 기록마다 `pendingGenerations.finishGeneration(projectID:status: .completed, finishedAt: now())`를 부른다
  - 하나라도 기록되었고 `startTask`가 있으면 `await startTask.value` 뒤 `apply(pendingGenerations.pendingState())`를 부른다. `startTask`가 없으면 저장소 갱신만 하고 반환한다(`release`와 같은 규칙)
  - `announceArrival`·`recordArrival`·`preserve`는 부르지 않는다
  - `ProjectGenerationUseCase` 프로토콜은 바꾸지 않는다

### 정리와 단위 검증

- [X] T003 [no-write] `"$project_build_runner" compile`이 통과하는지 확인한다. 실행 전후 `git status --porcelain`을 비교한다

---

## 실행 단위 U2: 목록에 반영한 프로젝트를 생성 기록에 알림 (integration: Domain + Composition)

**목표**: `Project`가 목록에 반영한 페이지의 프로젝트 식별자를 클로저로 알리고, Composition이 이를 U1의
`confirmCompletion(of:)`에 연결한다(FR-001, FR-008).

**분리 불가 근거**: `Project.init`에 기본값 없는 인자 `projectsListed`를 추가하면 Composition의
`ConcernUseCaseAssembly`가 같은 커밋에서 인자를 넘겨야 compile된다. 기본값(no-op)은 production 연결 누락을
숨기므로 두지 않는다([R1](./research.md#r1-두-관심사의-연결-방식fr-001)).

**관련 변경 시나리오**: [S1]

**독립 검증**: `"$project_build_runner" compile`. Project 테스트로 알림 조건을 검증한다. Composition 연결은
compile과 실기기 검증(T011)으로 확인한다([R5](./research.md#r5-composition-연결의-검증-범위)).

### 테스트

- [ ] T004 [S1] `sources/Projects/Domain/Tests/Project/UseCases/ProjectTests.swift`를 고친다
  - 파일 끝 `DeletionRecorder` 옆에 같은 형태의 `private actor ListingRecorder`를 추가한다. `record(_ projectIDs: [String])`와 `private(set) var listings: [[String]]`를 둔다
  - `Fixture`에 `listings: ListingRecorder` 프로퍼티를 추가하고 `Project(...)` 생성에 `projectsListed: { await listings.record($0) }`를 넘긴다
  - 다음 테스트를 추가한다. 페이지 데이터는 기존 테스트가 쓰는 `pages:` 딕셔너리 형식을 따른다
    - `첫 페이지를 반영하면 그 페이지의 프로젝트를 알린다` — `refresh()` 뒤 `listings`가 첫 페이지 항목 `id` 배열 하나다
    - `다음 페이지를 붙이면 그 페이지의 프로젝트를 알린다` — 첫 페이지 뒤 `requestNextPage()`. `listings`의 두 번째 항목이 다음 페이지 항목 `id` 배열이다(목록에 이미 있어 걸러진 항목도 포함)
    - `대체된 첫 페이지 응답은 프로젝트를 알리지 않는다` — 기존 `대체된 첫 페이지 응답은 목록에 반영하지 않는다`와 같은 준비로 대체된 응답의 항목이 `listings`에 없다
    - `첫 페이지 로드가 실패하면 프로젝트를 알리지 않는다` — `failure`를 설정한 저장소로 `refresh()`가 던진 뒤 `listings`가 비어 있다
  - 기존 테스트의 이름과 기대값은 바꾸지 않는다

### 구현

- [ ] T005 [S1] `sources/Projects/Domain/Project/UseCases/Project.swift`를 고친다
  - `init`에 `projectsListed: @escaping @Sendable ([ProjectID]) async -> Void` 인자를 `projectDeleted` 뒤, `pageSize` 앞에 추가하고 `private let projectsListed`에 저장한다
  - `requestFirstPage`의 Task 안에서 `replaceWithFirstPage`가 페이지를 목록에 반영했을 때만 `await self.projectsListed(page.summaries.map(\.id))`를 부른다. `requestNextPage`의 Task와 `appendPage`도 같다
  - `replaceWithFirstPage`·`appendPage`는 epoch 가드로 반영 여부를 결정하므로, 반영 여부를 `Bool`로 돌려주고 Task가 그 값으로 호출을 결정한다. 대체된 응답(epoch 불일치)과 실패한 로드는 부르지 않는다
  - `reset`·`delete`·`detail`은 바꾸지 않는다
- [ ] T006 [S1] `sources/Projects/Composition/App/Assemblies/ConcernUseCaseAssembly.swift`의 `Project(...)` 생성에 `projectsListed: { await projectGeneration.confirmCompletion(of: $0) }`를 `projectDeleted:` 뒤에 추가한다. 다른 조립 인자는 바꾸지 않는다

### 정리와 단위 검증

- [ ] T007 [no-write] `"$project_build_runner" compile`이 통과하는지 확인하고, `sources/Projects`에서 `projectDeleted:` 검색 결과의 production 호출처(`ConcernUseCaseAssembly.swift`)마다 `projectsListed:`가 함께 있는지 확인한다. 실행 전후 `git status --porcelain`을 비교한다

---

## 실행 단위 U3: 048 결과 경로 가정 갱신 (문서, 책임: 049 기능)

**목표**: 048 명세의 가정에 목록 확인 경로가 추가되었고 알림 방식은 049를 따른다는 표시를 붙인다(FR-010).

**관련 변경 시나리오**: [S4]

**독립 검증**: 문서 검토. SC-007을 확인한다.

- [ ] T008 [S4] `specs/048-generation-outcome-payload/spec.md` 가정 섹션의 "생성 결과는 원격 알림으로만 들어오므로, 로컬 결과 알림을 제거해도 … 원격 알림이 아닌 결과 경로가 생기면 그때 알림 방식을 다시 정한다." 문장 끝에 "*(2026-10-01 갱신: 서버 프로젝트 목록 확인으로도 완료가 들어온다. 목록 경로에는 추가 알림을 두지 않는다. [049 명세](../049-generation-list-completion/spec.md) FR-007 참조)*"를 붙인다. 다른 문장은 바꾸지 않는다

---

## 전체 완료 검증 (마지막 적용 단위 뒤, `[no-write]`)

- [ ] T009 [no-write] `"$project_build_runner" build`, `"$project_build_runner" compile`, `"$project_build_runner" test`를 순서대로 실행하고 결과를 기록한다(SC-001, SC-003, SC-004, SC-005, SC-006)
- [ ] T010 [no-write] [S4] [quickstart.md](./quickstart.md) "2. 문서 확인"으로 048 가정에 갱신 표시가 있는지 확인한다(SC-007)
- [ ] T011 [no-write] [S1] [S2] [S3] 실기기에서 [quickstart.md](./quickstart.md) "3. 실기기 검증" 1~6을 확인한다(SC-001, SC-002). 실기기를 쓸 수 없거나 알림 누락을 재현할 수 없으면 미검증으로 기록하고 PR 미검증 범위에 적는다
- [ ] T012 [no-write] 실행 전후 `git status --porcelain`을 비교해 검증 작업이 추적 파일을 바꾸지 않았는지 확인한다

---

## 의존성과 실행 순서

```text
U1 (Domain: ProjectGeneration) ─▶ U2 (Domain: Project + Composition) ─▶ U3 (문서) ─▶ 전체 완료 검증
```

- U2는 U1의 `confirmCompletion(of:)`을 연결하므로 U1 뒤에만 compile된다.
- U3은 코드와 무관한 문서 정정이며 마지막 단위로 전체 검증과 필수 후행 훅을 묶는다.

### 시나리오 완료 순서

- **S1, S2, S3**: U1(규칙) + U2(연결). 사용자 효과는 U2에서 나타난다.
- **S4**: U3

## 단위 내부 병렬 실행 예시

- **U1**: 파일이 둘(테스트·구현)이지만 테스트가 구현 API에 의존하므로 순차 진행한다.
- **U2**: T004(테스트)와 T006(Composition)은 서로 다른 파일이지만 둘 다 T005의 새 `init` 시그니처에
  의존한다. T005 뒤에 T004·T006을 병렬로 진행할 수 있다.
- 단위 사이는 병렬로 실행하지 않는다.

## 위험 기반 승인 조건

- 같은 기능 범위의 다음 단위와 읽기 전용 검증은 반복 승인 없이 진행한다.
- 다음 경우에는 멈추고 사용자에게 확인한다.
  - 단위 시작 시 검색 결과가 이 문서 목록과 다르다(특히 `Project(` 생성 호출처가 `ConcernUseCaseAssembly` 외에 더 있다).
  - 기존 생성 결과·목록 테스트가 새 동작 때문에 깨져 기대값을 바꿔야 한다(FR-009 위반 가능성).
  - 실기기 검증에서 목록 확인이 추가 목록 요청을 일으킨다(FR-006 위반).

## 변경 시나리오 추적 전략

| 시나리오 | 요구사항 | 작업 |
|---|---|---|
| S1 | FR-001, FR-002, FR-003, FR-004, FR-008 | T001, T002, T004, T005, T006, T011 |
| S2 | FR-002 | T001(`ready` 구독 테스트), T002, T011 |
| S3 | FR-005, FR-006, FR-007 | T001, T002 |
| S4 | FR-010 | T008, T010 |

FR-008(서버 계약·폴링·새 계기 없음)은 어느 작업도 서버 호출·타이머·목록 요청을 추가하지 않는다는 것으로
충족한다. FR-009(기존 동작 유지)는 T009의 기존 테스트 통과로 확인한다. FR-007(추가 알림 없음)은 048이 로컬
알림 능력을 이미 제거했고 이 작업이 알림 코드를 추가하지 않는 것으로 충족한다([R6](./research.md#r6-알림-방식fr-007)).
