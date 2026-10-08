---

description: "기능 구현 작업 목록 템플릿"
---

# 작업 목록: GitHub·Git-It 프로젝트 API Composition Adapter 구축

**입력**: `/specs/008-network-composition-adapters/`의 설계 문서

**선행 조건**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (모두 확인함).
**추가 선행 조건(research.md 결정 0)**: `007-learning-project-lifecycle`의 Domain
(`DomainLearningProject`)·Data(`DataLearningProject`) 패키지가 이미 구현·검증되어
`sources/Projects/Domain/DomainLearningProject/`·`sources/Projects/Data/DataLearningProject/`에
존재해야 한다. 이 저장소에서 두 패키지가 아직 확인되지 않으면 이 작업 목록의 T001부터
착수할 수 없다 — 먼저 007의 `/speckit-implement`를 완료해야 한다.

**테스트**: spec.md FR-014("각 Adapter는 성공 경로 1개 이상과 예외·경계 사례 절이 식별한
모든 오류 경로를 검증하는 자동화된 테스트를 가져야 한다")가 테스트를 명시적으로 요구하므로
포함한다.

**구성**: 패키지를 최상위 구현·승인 단위로 사용하고 변경 시나리오는 패키지 안에서 추적한다.
이 명세가 변경하는 패키지는 `Composition` 하나뿐이다(Domain·Data·Infrastructure는 007·003·
001이 이미 소유하며 이 기능이 재정의하지 않는다).

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 승인된 현재 패키지 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[시나리오]**: `S1`(GitHub Composition Adapter, FR-001~004), `S2`(Git-It 서버 Composition
  Adapter, FR-005~009)
- **[no-write]**: 추적 파일을 변경하지 않는 명령 실행 또는 수동 검증

## 패키지 소유권 규칙

- 패키지 소스·테스트와 패키지 전용 Tuist 설정은 해당 패키지 단계가 소유한다.
- `Composition`은 기능별 target이 아닌 앱 전체 단일 target이다 — 이 기능은 새 target을
  만들지 않고 기존 target 내부에 `LearningProjectLifecycle/` 하위 폴더를 새로 도입한다
  (research.md 결정 6).
- `trouble-shooting.md`와 `tacit-knowledge.md` 기록은 이 작업 목록에 포함하지 않는다 —
  조건이 발생한 세션에서 각 전용 Spec Kit 스킬이 별도로 기록한다.

---

## 작업 패키지 1: Composition

**목표**: 007의 `ExternalRepositoryLookup`(GitHub)과 `LearningProjectRepository`(Git-It
서버)를 구현하는 4개 Composition Adapter(`ExternalRepositoryRemoteAdapter`,
`ExternalRepositoryLookupAdapter`, `LearningProjectRemoteAdapter`,
`LearningProjectRepositoryAdapter`)를 제공해 007의 5개 UseCase가 Fake가 아닌 실제
`HTTPClient` 응답을 근거로 동작하게 한다.

**소유 경로**: `sources/Projects/Composition/Composition/LearningProjectLifecycle/`,
`sources/Projects/Composition/CompositionTests/LearningProjectLifecycle/`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`

**관련 변경 시나리오**: S1, S2

**독립 검증**: `xcodebuild test -workspace GitIt.xcworkspace -scheme Composition
-destination 'platform=iOS Simulator,name=iPhone 17 Pro'`가 Fake `HTTPTransport`·Fake
`LoginSessionStorage`만으로 실패 0건을 반환한다(실제 GitHub·Git-It 서버 네트워크 호출
없이도 통과해야 한다).

### 준비와 기반

- [X] T001 `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`의
  `.Composition`/`.CompositionTests` 케이스 `dependencies`(`.CompositionTests`는
  `additionalDependencies`)에 `.fromDomain(.DomainLearningProject)`,
  `.fromData(.DataLearningProject)`, `.fromInfrastructure(.InfrastructureNetworkClient)`를
  기존 Authentication 계열 의존성 옆에 추가한다(research.md 결정 7)

### 테스트(FR-014)

- [X] T002 [P] [S1] `sources/Projects/Composition/CompositionTests/LearningProjectLifecycle/ExternalRepositoryRemoteAdapterTests.swift`에
  contracts/github-composition-adapter.md "FR-014 테스트 매트릭스"의
  `ExternalRepositoryRemoteAdapter` 항목(성공, 404/403/5xx→`.other`,
  `connectionFailed`→`.offline`, `timedOut`/`.cancelled`/`.responseDecodingFailed`→`.other`,
  실제 구성된 `HTTPTransportRequest`의 URL이 `https://api.github.com/repos/{owner}/{name}`과
  일치)을 Fake `HTTPTransport`를 주입한 실제 `HTTPClient`로 검증하는 테스트를 작성한다
- [X] T003 [P] [S1] `sources/Projects/Composition/CompositionTests/LearningProjectLifecycle/ExternalRepositoryLookupAdapterTests.swift`에
  contracts/github-composition-adapter.md의 `ExternalRepositoryLookupAdapter` 항목(성공,
  `.offline` 전파, `.other` 전파)을 Fake `ExternalRepositoryRemote`로 검증하는 테스트를
  작성한다
- [X] T004 [P] [S2] `sources/Projects/Composition/CompositionTests/LearningProjectLifecycle/LearningProjectRemoteAdapterTests.swift`에
  contracts/git-it-server-composition-adapter.md "FR-014 테스트 매트릭스"의
  `LearningProjectRemoteAdapter` 항목(4개 메서드 성공, 400/401/404/500→대응
  `DataLearningProjectError`, `HTTPClientError`→`.unexpected`, `Authorization: Bearer` 헤더
  첨부 검증, 토큰 부재 시 401→`.unauthorized` 검증, 4개 메서드 요청 구성 검증)을 Fake
  `HTTPTransport` + Fake `LoginSessionStorage`를 주입한 실제 `HTTPClient`로 검증하는
  테스트를 작성한다
- [X] T005 [P] [S2] `sources/Projects/Composition/CompositionTests/LearningProjectLifecycle/LearningProjectRepositoryAdapterTests.swift`에
  contracts/git-it-server-composition-adapter.md의 `LearningProjectRepositoryAdapter` 항목
  (4개 메서드 성공 시 Domain 모델 변환, `DataLearningProjectError` 4개 케이스 각각의
  `LearningProjectError` 변환)을 Fake `LearningProjectRemote`로 검증하는 테스트를 작성한다

### 구현

- [X] T006 [P] [S1] `sources/Projects/Composition/Composition/LearningProjectLifecycle/ExternalRepositoryRemoteAdapter.swift`에
  `init(httpClient: HTTPClient)`와 `ExternalRepositoryRemote` 프로토콜(`func
  repository(owner:name:) async throws -> GitHubRepositoryResponseDTO`)을 구현한다 — `GET
  {baseURL}/repos/{owner}/{name}`을 전송하고(FR-002), 성공 응답을 디코딩해 반환하며, 실패는
  data-model.md §1 오류 매핑 표대로 `DataExternalRepositoryError`로 던진다(FR-004·FR-010,
  재시도 없음 FR-015, 로깅 없음 FR-016)
- [X] T007 [P] [S1] `sources/Projects/Composition/Composition/LearningProjectLifecycle/ExternalRepositoryLookupAdapter.swift`에
  `init(remote: ExternalRepositoryRemote)`와 `ExternalRepositoryLookup` 프로토콜(`func
  repository(owner:name:) async throws -> ExternalRepository`)을 구현한다 — `remote`가 반환한
  `GitHubRepositoryResponseDTO`를 `ExternalRepository`로 변환하고(FR-003),
  `DataExternalRepositoryError`를 대응 `ExternalRepositoryError`로 매핑해 다시 던진다
- [X] T008 [P] [S2] `sources/Projects/Composition/Composition/LearningProjectLifecycle/LearningProjectRemoteAdapter.swift`에
  `init(httpClient: HTTPClient, sessionStorage: LoginSessionStorage)`와
  `LearningProjectRemote` 프로토콜(`registerProject`/`fetchProjects`/`fetchProjectDetail`/
  `deleteProject`)을 구현한다 — 매 호출 전 `sessionStorage.load()?.accessToken`으로
  `Authorization: Bearer` 헤더를 구성하고(FR-007, 토큰이 없으면 헤더 없이 요청), 대응
  `/api/v1/projects` 엔드포인트를 전송하며(FR-006), 실패는 data-model.md §2 오류 매핑
  표대로 `DataLearningProjectError`로 던진다(FR-009·FR-010, 재시도 없음 FR-015, 로깅 없음
  FR-016)
- [X] T009 [P] [S2] `sources/Projects/Composition/Composition/LearningProjectLifecycle/LearningProjectRepositoryAdapter.swift`에
  `init(remote: LearningProjectRemote)`와 `LearningProjectRepository` 프로토콜(`register`/
  `fetchProjects`/`fetchProjectDetail`/`deleteProject`)을 구현한다 — `remote`가 반환한 DTO를
  007의 Domain 모델로 변환하고(FR-008, `register`의 `quizLevel`은 호출 시 전달받은 값을
  보존), `DataLearningProjectError`를 대응 `LearningProjectError`로 매핑해 다시 던진다

### 정리와 패키지 검증

- [X] T010 [no-write] `xcodebuild test -workspace GitIt.xcworkspace -scheme Composition
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`로 패키지를 검증한다(실패 0건,
  T002~T005의 테스트 매트릭스 전부 통과 확인)

**승인 게이트**: T001~T010의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 이 기능이 변경하는
패키지는 `Composition`뿐이므로, 승인 후에는 전체 완료 검증만 남는다.

---

## 전체 완료 검증

**선행 조건**: `Composition` 패키지의 구현·검증·결과 보고가 완료되어야 한다.

- [X] T011 [no-write] `Composition` 스킴의 `xcodebuild test`를 재실행하고
  quickstart.md 시나리오 1·2 절차와 대조해 결과를 기록한다
- [X] T012 [no-write] spec.md 시나리오 1·2의 수용 시나리오 3+6개 전체를 T002~T005 테스트
  결과와 대조해 SC-001~SC-004가 충족되었는지 확인한다(로그인·세션 Adapter가 없어 실제 기기
  End-to-End 검증은 범위 밖이라는 점을 함께 기록한다)

## 의존성과 실행 순서

### 패키지 순서와 승인 게이트

- 이 명세가 변경하는 패키지는 `Composition` 하나뿐이다(Domain·Data·Infrastructure는 007·
  003·001이 이미 소유). `Composition` 착수 전 007의 `DomainLearningProject`/
  `DataLearningProject` 구현·검증이 끝나 있어야 한다(위 "추가 선행 조건").
- T001~T010의 변경 파일과 검증 결과를 보고하고 명시적 사용자 승인을 받은 뒤 전체 완료
  검증(T011~T012)으로 진행한다.

### 변경 시나리오 추적성

- S1(FR-001~004)은 T002·T003·T006·T007에서 추적한다.
- S2(FR-005~009)는 T004·T005·T008·T009에서 추적한다.
- 각 변경 시나리오는 `Composition` 패키지 완료 뒤 T012에서 독립 수용 기준으로 검증한다.
  최소 가치 범위(S1)도 패키지 승인 게이트를 건너뛰지 않는다.

### 패키지 내부 실행

- 테스트(T002~T005)를 구현(T006~T009) 전에 작성한다. Swift 컴파일 특성상 "예상한 이유로
  실패"는 구현 타입이 없어 컴파일이 실패하는 상태를 뜻한다.
- `[P]`는 승인된 현재 패키지 안의 서로 다른 파일에만 사용한다 — T002~T005, T006~T009는
  각각 서로 다른 파일이며 서로의 완료를 기다리지 않으므로 병렬 실행할 수 있다.
- T001(Tuist 설정)은 T002~T009보다 먼저 완료되어야 한다(의존성 선언 없이는 새 target
  참조가 컴파일되지 않는다).

## 병렬 실행 예시 (Composition 패키지, 승인 후)

```text
# T001 완료 후 테스트 작성을 한 번에 병렬로 시작할 수 있다(서로 다른 파일):
Task: "T002 ExternalRepositoryRemoteAdapterTests.swift 작성"
Task: "T003 ExternalRepositoryLookupAdapterTests.swift 작성"
Task: "T004 LearningProjectRemoteAdapterTests.swift 작성"
Task: "T005 LearningProjectRepositoryAdapterTests.swift 작성"

# 구현 단계에서도 서로 다른 Adapter 파일은 병렬 실행 가능:
Task: "T006 ExternalRepositoryRemoteAdapter.swift 구현"
Task: "T007 ExternalRepositoryLookupAdapter.swift 구현"
Task: "T008 LearningProjectRemoteAdapter.swift 구현"
Task: "T009 LearningProjectRepositoryAdapter.swift 구현"
```

## 구현 전략

1. 007의 `DomainLearningProject`/`DataLearningProject` 구현·검증이 끝났는지 먼저 확인한다.
2. `Composition` 패키지(T001~T010)를 완료한다 — Tuist 의존성 추가 → 테스트 → 4개 Adapter
   구현 → `Composition` 스킴 검증.
3. 변경 파일과 `xcodebuild test` 결과를 보고하고 전체 완료 검증 진행 승인을 요청한다.
4. 승인 후 T011~T012만 실행한다 — 이 단계는 파일을 변경하지 않는다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 모든 파일 변경 작업은 정확한 저장소 상대 경로 하나와 정확히 하나의 책임 패키지를
  가진다.
- 로그인·세션·토큰 갱신 Composition Adapter, Feature/UI 화면, App 수준 DI Container 등록은
  이 작업 목록의 범위 밖이며 후속 스펙이 담당한다(plan.md·spec.md `범위 밖`).
- 문제 해결과 암묵지 기록은 이 작업 목록의 작업 ID로 생성하지 않는다.
