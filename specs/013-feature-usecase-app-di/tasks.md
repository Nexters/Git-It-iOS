---

description: "기능 구현 작업 목록: Feature → Domain UseCase 의존과 App 소유 의존성 주입"
---

# 작업 목록: Feature → Domain UseCase 의존과 App 소유 의존성 주입

**입력**: `/specs/013-feature-usecase-app-di/`의 설계 문서 (plan.md, spec.md, research.md,
data-model.md, contracts/, quickstart.md)

**선행 조건**: plan.md, spec.md, research.md, data-model.md, contracts/domain-usecase-protocols.md,
contracts/composition-graph.md, contracts/package-dependency-rules.md,
contracts/naming-and-signatures.md, quickstart.md

**테스트**: 명세가 FR-012·FR-020·FR-031로 Infrastructure·Data·Composition 테스트를 명시적으로
요구하므로 각 해당 패키지 단계에 테스트 작업을 포함한다. Domain은 기존 테스트로 rename과
Protocol conformance를 검증하며 새 테스트를 요구하지 않는다.

**구성**: 패키지를 최상위 구현·승인 단위로 사용하고 변경 시나리오는 각 패키지 안에서
추적한다. 이 명세가 변경하는 패키지는 Domain, Infrastructure, Data, Composition뿐이다.
`UI`, `Feature`, `App`은 적용 대상이 아니다(App은 FR-064a의 target 이름 참조 1건만 예외).

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 승인된 현재 패키지 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[시나리오]**: `S1`~`S6`. `S1` Domain UseCase 계약, `S2` Data 실행 구현, `S3` Infrastructure
  기술 API, `S4` Composition 실행 그래프, `S5` 아키텍처 문서 개정(선행), `S6` 네이밍 rename
- **[no-write]**: 추적 파일을 변경하지 않는 명령 실행 또는 수동 검증
- rename 작업(`S6`)과 신설 작업(`S1`~`S4`)은 하나의 작업으로 합치지 않는다. 단,
  `ObserveAuthenticationOutcomes`의 rename(T020~T022)과 Protocol 신설(T023~T026)은 같은
  Domain target을 다루지만 별개 작업으로 분리했다.

## 패키지 순서와 근거

`Domain → Infrastructure → Data → Composition` (contracts/package-dependency-rules.md, R-007).
개정 후 의존 규칙에서 Domain과 Infrastructure는 서로 의존하지 않는 leaf이고
`Data → Infrastructure`, `Composition → Domain·Data·Infrastructure`이므로 Data는
Infrastructure보다 뒤, Composition은 마지막이 강제된다. Domain과 Infrastructure의 상대
순서는 이 문서가 Domain을 먼저 두는 것으로 확정한다. Domain UseCase Protocol이 Composition이
노출할 타입의 기준이고, Infrastructure 보완 범위(FR-010)는 Data 구현 설계에서 도출되므로
Domain 확정 뒤에 판단하는 편이 정확하기 때문이다(R-007).

문서 개정(`docs/architecture.md`, `docs/package-rules/data.md`,
`docs/package-rules/composition.md`)은 FR-060에 따라 어떤 패키지 구현 작업보다 먼저 끝나야
하므로 Domain 단계의 **준비와 기반**으로 배정한다(R-008).

---

## 작업 패키지 1: Domain

**목표**: Feature가 호출할 모든 Authentication 비즈니스 작업을 Protocol로 노출하고,
`DomainLearningProject`와 `DomainAuthentication`의 네이밍 규약 위반을 rename으로 해소한다.
아키텍처 문서 개정을 이 패키지의 선행 작업으로 완료한다.

**소유 경로**: `docs/architecture.md`, `docs/package-rules/data.md`,
`docs/package-rules/composition.md`, `sources/Projects/Domain/Authentication/**`,
`sources/Projects/Domain/LearningProject/**`, `sources/Projects/Domain/Tests/**`

**관련 변경 시나리오**: S1, S5, S6

**독립 검증**: Domain target의 UseCase 선언을 검토해 Protocol 존재와 conformance를 확인하고,
Protocol 시그니처에 Domain 외부 타입이 없는지 확인한다. rename 전후로 동일한 Domain 테스트가
통과하는지 확인한다.

### 준비와 기반 — 아키텍처 문서 개정 (S5, 어떤 패키지 구현보다 선행)

- [X] T001 [S5] `docs/architecture.md`의 3.1 프로젝트 내부 패키지 의존성 표에서 Data의 허용
  의존성에 Infrastructure를 추가하고, 3.3 Adapter 경계의 `Data ↔ Infrastructure` 절을 "Data의
  concrete 구현이 직접 변환을 소유"하는 서술로 정정하고, 4장 패키지 제어 흐름을 개정된 흐름에
  맞게 수정하고, 7.1 금지 의존성 목록에서 `Data → Infrastructure` 항목을 제거하고, 새 `## 9.
  아키텍처 결정 기록` 절을 추가해 `D-ARCH-003`(Feature는 Domain UseCase Protocol에만 의존,
  Composition이 Infrastructure·Data·Adapter·UseCase 구현을 조립해 App에 제공, App이 production
  주입을 수행, FeatureTests는 Domain UseCase Protocol의 local Test Double만 사용)을 기록한다.
  상위 문서 `ARCH-DI-001`의 Composition 정의를 이 결정이 대체하는 범위를 명시하고, FR-032~FR-054
  후속 Feature·App 구현 규범을 옮겨 적는다(FR-055~FR-061).
- [X] T002 [S5] `docs/package-rules/data.md`에서 "프로젝트 내부의 다른 패키지에 의존해서는 안
  됩니다", "Infrastructure 타입 또는 외부 라이브러리의 구체 API를 직접 참조해서는 안 됩니다",
  "Data↔Infrastructure Adapter를 Data 내부에 구현해서는 안 됩니다" 세 제약을 Data가
  Infrastructure에 의존하고 그 위에서 concrete 구현을 소유하도록 개정한다.
- [X] T003 [S5] `docs/package-rules/composition.md`에서 "Data가 정의한 기술 계약은 Core가
  제공하는 내부 API를 이용한 Adapter로 충족" 정책과 "Data 계약의 요청·응답과 Infrastructure
  API 사이의 변환은 Data↔Infrastructure Adapter가 담당" 서술을 제거하고, Composition은
  Domain↔Data Adapter만 소유한다는 개정된 책임으로 수정한다.
- [X] T004 [no-write] [S5] T001~T003에서 개정한 세 문서와
  `contracts/package-dependency-rules.md`를 대조해 모순 서술이 0건인지, `D-ARCH-003` 결정
  기록이 Feature 의존 대상·Composition 책임·App 주입 위치·FeatureTests 정책을 포함하는지
  확인한다(SC-015~SC-017).

### 구현 — 표준 약어 표기 rename (`DomainLearningProject`, S6)

- [X] T005 [P] [S6] `sources/Projects/Domain/LearningProject/Contracts/LearningProjectRepository.swift`의
  `projectId`→`projectID`, `githubRepoUrl`→`githubRepoURL`를 rename한다. 연산 집합과 시그니처의
  나머지 부분은 바꾸지 않는다.
- [X] T006 [P] [S6] `sources/Projects/Domain/LearningProject/UseCases/FetchLearningProjectDetailUseCase.swift`,
  `sources/Projects/Domain/LearningProject/UseCases/FetchLearningProjectDetail.swift`의
  `projectId`→`projectID`를 rename한다.
- [X] T007 [P] [S6] `sources/Projects/Domain/LearningProject/UseCases/DeleteLearningProjectUseCase.swift`,
  `sources/Projects/Domain/LearningProject/UseCases/DeleteLearningProject.swift`의
  `projectId`→`projectID`를 rename한다.
- [X] T008 [P] [S6] `sources/Projects/Domain/LearningProject/UseCases/CreateLearningProjectUseCase.swift`,
  `sources/Projects/Domain/LearningProject/UseCases/CreateLearningProject.swift`의
  `githubRepoUrl`→`githubRepoURL`을 rename한다.
- [X] T009 [P] [S6] `sources/Projects/Domain/LearningProject/Models/LearningProjectSummary.swift`의
  `projectId`→`projectID`, `nextSetId`→`nextSetID`, `nextQuestionId`→`nextQuestionID`를
  rename한다.
- [X] T010 [P] [S6] `sources/Projects/Domain/LearningProject/Models/LearningProjectDetail.swift`의
  `projectId`→`projectID`, `nextQuestionId`→`nextQuestionID`를 rename한다.
- [X] T011 [P] [S6] `sources/Projects/Domain/LearningProject/Models/LearningProjectRegistration.swift`의
  `projectId`→`projectID`를 rename한다.
- [X] T012 [P] [S6] `sources/Projects/Domain/LearningProject/Models/LearningProjectSetProgress.swift`의
  `setId`→`setID`를 rename한다.
- [X] T013 [P] [S6] `sources/Projects/Domain/Tests/LearningProject/Contracts/LearningProjectRepositoryContractTests.swift`의
  호출부와 Test Double 레이블을 T005 rename에 맞게 갱신한다.
- [X] T014 [P] [S6] `sources/Projects/Domain/Tests/LearningProject/Models/LearningProjectDetailTests.swift`의
  레이블을 T010 rename에 맞게 갱신한다.
- [X] T015 [P] [S6] `sources/Projects/Domain/Tests/LearningProject/UseCases/CreateLearningProjectTests.swift`의
  레이블을 T008 rename에 맞게 갱신한다.
- [X] T016 [P] [S6] `sources/Projects/Domain/Tests/LearningProject/UseCases/DeleteLearningProjectTests.swift`의
  레이블을 T007 rename에 맞게 갱신한다.
- [X] T017 [P] [S6] `sources/Projects/Domain/Tests/LearningProject/UseCases/FetchLearningProjectDetailTests.swift`의
  레이블을 T006 rename에 맞게 갱신한다.
- [X] T018 [P] [S6] `sources/Projects/Domain/Tests/LearningProject/UseCases/FetchLearningProjectsTests.swift`의
  레이블을 T009 rename에 맞게 갱신한다.
- [X] T019 [P] [S6] `sources/Projects/Domain/Tests/LearningProject/UseCases/LearningProjectLifecycleTests.swift`의
  레이블을 T005~T012 rename에 맞게 갱신한다.

### 구현 — `ObserveAuthenticationOutcomes` rename과 Authentication UseCase Protocol 신설 (S1, S6)

- [X] T020 [S6] `sources/Projects/Domain/Authentication/UseCases/ObserveAuthorizationChanges.swift`를
  `sources/Projects/Domain/Authentication/UseCases/ObserveAuthenticationOutcomes.swift`로
  rename한다. 파일명과 타입명(`ObserveAuthorizationChanges`→`ObserveAuthenticationOutcomes`)만
  바꾸고 구현 본문과 동작은 그대로 둔다. 책임 분리(관찰과 세션 복원의 분리)는 수행하지 않는다
  (R-013).
- [X] T021 [S6] `sources/Projects/Domain/Authentication/README.md`의
  `ObserveAuthorizationChanges` 언급을 `ObserveAuthenticationOutcomes`로 갱신한다.
- [X] T022 [S6] `sources/Projects/Domain/Tests/Authentication/UseCases/ObserveAuthorizationChangesTests.swift`를
  `sources/Projects/Domain/Tests/Authentication/UseCases/ObserveAuthenticationOutcomesTests.swift`로
  rename하고 파일 내부의 타입 참조를 갱신한다. 테스트 케이스의 검증 내용은 바꾸지 않는다.
- [X] T023 [S1] `sources/Projects/Domain/Authentication/UseCases/SignInUseCase.swift`를 신설해
  `public protocol SignInUseCase: Sendable { func callAsFunction(_ method: AuthenticationMethod) async -> AuthenticationOutcome }`을
  선언하고, `sources/Projects/Domain/Authentication/UseCases/SignIn.swift`의 `SignIn`이
  `SignInUseCase`를 conform하도록 선언을 추가한다. 시그니처는 현재 구현과 문자 그대로 일치시킨다
  (R-012, contracts/domain-usecase-protocols.md).
- [X] T024 [S1] `sources/Projects/Domain/Authentication/UseCases/SignOutUseCase.swift`를 신설해
  `public protocol SignOutUseCase: Sendable { func callAsFunction() async -> AuthenticationOutcome }`을
  선언하고, `sources/Projects/Domain/Authentication/UseCases/SignOut.swift`의 `SignOut`이
  `SignOutUseCase`를 conform하도록 선언을 추가한다.
- [X] T025 [S1] `sources/Projects/Domain/Authentication/UseCases/RestoreSessionUseCase.swift`를
  신설해
  `public protocol RestoreSessionUseCase: Sendable { func callAsFunction() async -> AuthenticationOutcome }`을
  선언하고, `sources/Projects/Domain/Authentication/UseCases/RestoreSession.swift`의
  `RestoreSession`이 `RestoreSessionUseCase`를 conform하도록 선언을 추가한다.
- [X] T026 [S1] `sources/Projects/Domain/Authentication/UseCases/ObserveAuthenticationOutcomesUseCase.swift`를
  신설해
  `public protocol ObserveAuthenticationOutcomesUseCase: Sendable { func callAsFunction() async -> AsyncStream<AuthenticationOutcome> }`을
  선언하고, T020에서 rename한 `ObserveAuthenticationOutcomes`가 이 Protocol을 conform하도록
  선언을 추가한다.

### 정리와 패키지 검증

- [X] T027 [no-write] `"$project_build_runner" compile`과 `"$project_build_runner" test`를
  순차 실행해 Domain 테스트가 전부 통과하는지 확인한다. rename 전후로 동일한 테스트 집합이
  통과했는지(FR-067, SC-020), `projectId`·`githubRepoUrl`·`nextSetId`·`nextQuestionId`·`setId`·
  `ObserveAuthorizationChanges` 표기가 0건 남았는지(SC-018) 확인한다. T023~T026에서 신설한
  Protocol 4개의 시그니처를 검토해 DTO, `HTTPRequest`, `HTTPResponse`, `HTTPClientError`,
  `Data*Error`, 외부 SDK 타입이 0건인지 확인한다(FR-003, FR-004, SC-002). Domain 소스가
  Data·Infrastructure·Composition·Feature·App·UI를 import하지 않는지 확인한다(FR-009).

**승인 게이트**: T001~T027의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가 Infrastructure
패키지를 명시적으로 승인하기 전에는 Infrastructure 파일을 변경하지 않는다.

---

## 작업 패키지 2: Infrastructure

**목표**: Data의 concrete Remote 구현이 요구하는 네트워크·보안 저장소·캐시 기술 API를
Infrastructure 공개 API와 대조하고, 부족한 범위만 최소로 보완한다.

**소유 경로**: `sources/Projects/Infrastructure/**`

**관련 변경 시나리오**: S3

**독립 검증**: Data 구현이 요구하는 기술 API 목록과 Infrastructure 공개 API를 대조하고, 보완한
API를 Infrastructure 테스트로 검증한다.

### 준비와 대조

- [X] T028 [no-write] [S3] Data의 concrete Remote 구현(다음 Data 단계에서 만들 `HTTPProjectRemote`,
  `HTTPAuthenticationRemote`, `HTTPExternalRepositoryRemote`)이 요구하는 기술 API를
  `sources/Projects/Infrastructure/NetworkClient/Client/HTTPClient.swift`,
  `sources/Projects/Infrastructure/NetworkClient/HTTP/HTTPRequest.swift`,
  `sources/Projects/Infrastructure/NetworkClient/Client/HTTPClientError.swift`,
  `sources/Projects/Infrastructure/Authentication/Keychain/KeychainStore.swift`,
  `sources/Projects/Infrastructure/Authentication/AppleAuthentication/AppleAuthorizationProvider.swift`의
  공개 API와 대조하고 부족한 API 목록을 확정해 보고한다. 조사(R-003)는 `HTTPClient.send`가
  baseURL·헤더·타임아웃·취소·오류 분류를 이미 제공해 보완이 불필요할 가능성이 높다고 결론
  지었다.
  **분기**: 부족한 API가 없으면 변경 없이 근거를 보고하고 T029으로 진행한다. 부족한 API가
  있으면 이 시점에서 구현을 중단하고 `/speckit-tasks`를 다시 실행해, 그 API가 실제로 속하는
  정확한 파일 경로 하나(예: `sources/Projects/Infrastructure/NetworkClient/Client/HTTPClient.swift`)와
  대응 테스트 경로를 가진 새 작업으로 이 tasks.md를 갱신한 뒤 계속한다. 이 tasks.md 버전은
  조건부 경로를 가진 예약 작업을 두지 않는다(Constitution 원칙 4, 파일 변경 작업은 정확한
  저장소 상대 경로 하나를 가져야 한다).

### 정리와 패키지 검증

- [X] T029 [no-write] `"$project_build_runner" compile`과 `"$project_build_runner" test`를
  순차 실행해 Infrastructure 테스트가 전부 통과하는지 확인한다. Infrastructure가 Data·Domain·
  Composition·Feature·App·UI를 import하지 않는지 소스를 검토한다(FR-013).

**승인 게이트**: T028~T029의 변경 파일(또는 무변경 근거)과 검증 결과를 보고한 뒤 중단한다.
사용자가 Data 패키지를 명시적으로 승인하기 전에는 Data 파일을 변경하지 않는다.

---

## 작업 패키지 3: Data

**목표**: `ProjectRemote`, `AuthenticationRemote`, `ExternalRepositoryRemote`에 Infrastructure
기반 concrete 구현을 추가하고, Data target에 Infrastructure 의존성을 명시적으로 선언한다.

**소유 경로**: `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`,
`sources/Projects/Data/LearningProject/**`, `sources/Projects/Data/Authentication/**`,
`sources/Projects/Data/ExternalRepository/**`, `sources/Projects/Data/Tests/**`

**관련 변경 시나리오**: S2

**독립 검증**: Data target의 의존성 선언을 확인하고, concrete 구현을 Infrastructure 대역과
함께 실행해 요청 구성·응답 변환·오류 변환을 검증한다.

### 준비와 기반 — Tuist 의존성 선언

- [ ] T030 [S2] `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`에서
  `.DataAuthentication` target에 `.fromInfrastructure(.InfrastructureNetworkClient)`,
  `.fromInfrastructure(.InfrastructureAuthentication)`를, `.DataLearningProject`와
  `.DataExternalRepository` target에 각각
  `.fromInfrastructure(.InfrastructureNetworkClient)`를 `dependencies:`로 선언한다(FR-016).
  `.DataMember`는 변경하지 않는다(FR-030).

### 구현 — concrete Remote

- [ ] T031 [S2] `sources/Projects/Data/LearningProject/Remotes/HTTPProjectRemote.swift`를 신설해
  `ProjectRemote`를 conform하는 `HTTPProjectRemote`를 구현한다. `HTTPClient`를 생성자로 주입받고,
  `ProjectEndpoint`의 `LearningProjectRequest`를 `HTTPRequest`로 변환해 `HTTPClient.send`를
  호출하며, 응답 DTO(`ProjectListResponseDTO`, `ProjectDetailResponseDTO`,
  `RegisterProjectResponseDTO`)로 디코딩하고, `HTTPClientError`를 `DataLearningProjectError`로
  변환한다(R-003, R-004, R-015).
- [ ] T032 [S2] `sources/Projects/Data/Authentication/Remotes/HTTPAuthenticationRemote.swift`를
  신설해 `AuthenticationRemote`를 conform하는 `HTTPAuthenticationRemote`를 구현한다.
  `AuthenticationEndpoint.appleLogin`/`verifyAccessToken`을 `HTTPRequest`로 변환해
  `HTTPClient.send`를 호출하고, `LoginResponseDTO`로 디코딩하며, `HTTPClientError`를
  `DataAuthenticationError`로 변환한다.
- [ ] T033 [S2] `sources/Projects/Data/ExternalRepository/Remotes/HTTPExternalRepositoryRemote.swift`를
  신설해 `ExternalRepositoryRemote`를 conform하는 `HTTPExternalRepositoryRemote`를 구현한다.
  `GitHubRepositoryRequest`를 `HTTPRequest`로 변환해 `HTTPClient.send`를 호출하고,
  `GitHubRepositoryResponseDTO`로 디코딩하며, `HTTPClientError`를 `DataExternalRepositoryError`로
  변환한다.

### 테스트

- [ ] T034 [P] [S2] `sources/Projects/Data/Tests/LearningProject/Remotes/HTTPProjectRemoteTests.swift`를
  신설해 `HTTPProjectRemote`의 요청 구성(`LearningProjectRequest`→`HTTPRequest` 변환), 응답
  변환(DTO 디코딩), 오류 변환(`HTTPClientError`→`DataLearningProjectError`)을 검증한다(FR-020).
- [ ] T035 [P] [S2] `sources/Projects/Data/Tests/Authentication/Remotes/HTTPAuthenticationRemoteTests.swift`를
  신설해 `HTTPAuthenticationRemote`의 요청 구성·응답 변환·오류 변환을 검증한다.
- [ ] T036 [P] [S2] `sources/Projects/Data/Tests/ExternalRepository/Remotes/HTTPExternalRepositoryRemoteTests.swift`를
  신설해 `HTTPExternalRepositoryRemote`의 요청 구성·응답 변환·오류 변환을 검증한다.

### 정리와 패키지 검증

- [ ] T037 [no-write] `"$project_build_runner" compile`과 `"$project_build_runner" test`를
  순차 실행해 Data 테스트가 전부 통과하는지 확인한다. Data가 Domain·Composition·Feature·App·UI를
  import하지 않는지 소스를 검토하고(FR-019), `DataMember`가 변경되지 않았는지 확인한다.

**승인 게이트**: T030~T037의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가 Composition
패키지를 명시적으로 승인하기 전에는 Composition 파일을 변경하지 않는다.

---

## 작업 패키지 4: Composition

**목표**: `CompositionAdepter` target을 `CompositionAdapter`로 rename하고, Domain↔Data
Adapter와 기능별 조립 진입점을 신설해 Domain UseCase Protocol 타입만 노출하는 live 실행
그래프를 구성한다.

**소유 경로**: `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`,
`sources/Projects/Composition/**`

**관련 변경 시나리오**: S4, S6

**독립 검증**: Composition의 live 그래프 생성을 테스트로 실행하고, 공개 API 타입 목록과
Feature·Store·View 생성 코드 유무를 검토한다.

### 준비와 기반 — `CompositionAdapter` target rename (S6)

- [ ] T038 [S6] `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`의
  enum case `CompositionAdepter`→`CompositionAdapter`, `CompositionAdepterTests`→
  `CompositionAdapterTests`로 rename하고 내부 참조를 갱신한다.
- [ ] T039 [S6] `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 `.Composition`
  스킴 정의에서 `CompositionModuleName.CompositionAdepter.rawValue`,
  `CompositionModuleName.CompositionAdepterTests.rawValue` 참조 2건을 rename 후 이름으로
  갱신한다.
- [ ] T040 [S6] `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`의
  `.fromComposition(.CompositionAdepter)` 1건을 `.fromComposition(.CompositionAdapter)`로
  갱신한다. 이는 App target의 의존성 선언에서 target 이름 참조만 바꾸는 변경이며, App 소스
  파일과 실행 동작은 바꾸지 않는다(FR-064a).
- [ ] T041 [S6] `sources/Projects/Composition/Adepter/` 폴더를
  `sources/Projects/Composition/Adapter/`로 rename하고,
  `CompositionAdepterPlaceholder.swift`를 `CompositionAdapterPlaceholder.swift`로 rename해
  타입명 `CompositionAdepterPlaceholder`→`CompositionAdapterPlaceholder`를 갱신한다.
- [ ] T042 [S6] `sources/Projects/Composition/Tests/Adepter/` 폴더를
  `sources/Projects/Composition/Tests/Adapter/`로 rename하고,
  `CompositionAdepterCompilationTests.swift`를 `CompositionAdapterCompilationTests.swift`로
  rename해 파일 내부의 타입명·`@testable import`·`@Suite` 문자열을 갱신한다.

### 준비와 기반 — Tuist 의존성 선언

- [ ] T043 [S4] `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`의
  `CompositionAdapter` target에 `.fromDomain(.DomainAuthentication)`,
  `.fromDomain(.DomainLearningProject)`, `.fromData(.DataAuthentication)`,
  `.fromData(.DataLearningProject)`, `.fromData(.DataExternalRepository)`,
  `.fromInfrastructure(.InfrastructureNetworkClient)`,
  `.fromInfrastructure(.InfrastructureAuthentication)`를 `dependencies:`로 선언한다.
  `DataMember`는 대응 Domain 계약이 없으므로 선언하지 않는다(FR-029, FR-030).

### 구현 — Domain↔Data Adapter

- [ ] T044 [S4] `sources/Projects/Composition/Adapter/LearningProjectRepositoryAdapter.swift`를
  신설해 `LearningProjectRepository`를 conform하는 `LearningProjectRepositoryAdapter`를
  구현한다. `HTTPProjectRemote`를 생성자로 주입받고, `ProjectListResponseDTO`·
  `ProjectDetailResponseDTO`·`RegisterProjectResponseDTO`를 `LearningProjectPage`·
  `LearningProjectDetail`·`LearningProjectRegistration`으로, `DataLearningProjectError`를
  `LearningProjectError`로 변환한다. Domain은 rename 후 `projectID`·`githubRepoURL` 표기를
  사용하고 Data도 이미 같은 표기이므로 식별자·URL 필드의 표기를 뒤집는 변환은 0건이어야
  한다(SC-022).
- [ ] T045 [S4] `sources/Projects/Composition/Adapter/ExternalRepositoryLookupAdapter.swift`를
  신설해 `ExternalRepositoryLookup`을 conform하는 `ExternalRepositoryLookupAdapter`를
  구현한다. `HTTPExternalRepositoryRemote`를 생성자로 주입받고, `GitHubRepositoryResponseDTO`를
  `ExternalRepository`로, `DataExternalRepositoryError`를 `ExternalRepositoryError`로
  변환한다.
- [ ] T046 [S4] `sources/Projects/Composition/Adapter/AuthenticationRepositoryAdapter.swift`를
  신설해 `AuthenticationRepository`를 conform하는 `AuthenticationRepositoryAdapter`를
  구현한다. Infrastructure의 `AppleAuthorizationProvider`, `AppleCredentialStateProvider`를
  생성자로 주입받고, `AppleAuthorizationError`를 `AuthenticationError`로 변환한다.
- [ ] T047 [S4] `sources/Projects/Composition/Adapter/LoginSessionRepositoryAdapter.swift`를
  신설해 `LoginSessionRepository`를 conform하는 `LoginSessionRepositoryAdapter`를 구현한다.
  `HTTPAuthenticationRemote`와 `KeychainStore`를 생성자로 주입받고, `LoginResponseDTO`를
  `AuthenticatedUser`로, `DataAuthenticationError`·`KeychainStoreError`를 `LoginSessionError`로
  변환한다.

### 구현 — 조립 진입점

- [ ] T048 [S4] `sources/Projects/Composition/Adapter/LearningProjectAssembly.swift`를 신설한다.
  실행 환경 설정(baseURL, 타임아웃)을 입력값으로 받아 `HTTPClient`를 1회 생성하고,
  `HTTPProjectRemote`와 `LearningProjectRepositoryAdapter`를 조립해
  `FetchLearningProjectsUseCase`, `FetchLearningProjectDetailUseCase`,
  `CreateLearningProjectUseCase`, `DeleteLearningProjectUseCase` 타입의 property만 노출한다
  (FR-022, FR-027, R-009, R-016).
- [ ] T049 [S4] `sources/Projects/Composition/Adapter/ExternalRepositoryAssembly.swift`를
  신설한다. `HTTPClient`를 1회 생성하고 `HTTPExternalRepositoryRemote`와
  `ExternalRepositoryLookupAdapter`를 조립해 `FetchExternalRepositoryUseCase` 타입의 property만
  노출한다.
- [ ] T050 [S4] `sources/Projects/Composition/Adapter/AuthenticationAssembly.swift`를 신설한다.
  `HTTPClient`, `KeychainStore`, `AppleAuthorizationProvider`를 각각 1회 생성해
  `AuthenticationRepositoryAdapter`와 `LoginSessionRepositoryAdapter`에 공유 주입하고, `SignIn`,
  `SignOut`, `RestoreSession`, `ObserveAuthenticationOutcomes`를 조립해 `SignInUseCase`,
  `SignOutUseCase`, `RestoreSessionUseCase`, `ObserveAuthenticationOutcomesUseCase` 타입의
  property만 노출한다.

### 테스트

- [ ] T051 [P] [S4] `sources/Projects/Composition/Tests/Adapter/LearningProjectAssemblyTests.swift`를
  신설해 live 그래프 생성 성공, 노출 property가 모두 Domain UseCase Protocol 타입인지,
  `LearningProjectRepositoryAdapter`의 DTO→Domain 모델·오류 변환을 검증한다(FR-031).
- [ ] T052 [P] [S4] `sources/Projects/Composition/Tests/Adapter/ExternalRepositoryAssemblyTests.swift`를
  신설해 같은 항목을 `ExternalRepositoryAssembly`에 대해 검증한다.
- [ ] T053 [P] [S4] `sources/Projects/Composition/Tests/Adapter/AuthenticationAssemblyTests.swift`를
  신설해 같은 항목을 `AuthenticationAssembly`에 대해 검증한다.
- [ ] T054 [P] [S4] `sources/Projects/Composition/Tests/Adapter/SharedLifetimeTests.swift`를
  신설해 각 조립 진입점 안에서 `HTTPClient`·`KeychainStore`가 중복 생성되지 않는지 검증한다
  (FR-027, SC-010).

### 정리와 패키지 검증

- [ ] T055 [no-write] `tuist generate`와 `"$project_build_runner" build`,
  `"$project_build_runner" compile`, `"$project_build_runner" test`를 순차 실행한다.
  `Adepter` 표기가 manifest·폴더·target 이름·의존성 선언에 0건 남았는지(`docs/spec-kit/**`의
  append-only 기록 제외, SC-021), App의 변경이 T040의 target 이름 참조 1건뿐이고 App 소스
  파일 변경이 0건인지, Composition 공개 선언에 Domain UseCase Protocol 이외의 타입이 없는지
  (FR-028, SC-008), Feature·Store·View 생성 코드와 Feature·App·UI 의존성 선언이 0건인지
  (FR-024, FR-025, SC-009) 확인한다. `DataMember`·`MemberRemote`를 조립 대상으로 참조하는
  코드가 0건인지 확인한다(FR-030, SC-011).

**승인 게이트**: T038~T055의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가 전체 완료
검증을 명시적으로 승인하기 전에는 추가 파일을 변경하지 않는다.

---

## 전체 완료 검증

**선행 조건**: Composition 패키지의 구현·검증·결과 보고와 사용자 승인이 완료되어야 한다.

- [ ] T056 [no-write] `cd sources && tuist generate && cd ..`를 실행한 뒤
  `"$project_build_runner" build`, `"$project_build_runner" compile`,
  `"$project_build_runner" test`를 순차 실행하고 결과를 기록한다. 의존성 순환이 0건이고 전체
  공유 scheme Debug 빌드가 성공하는지(SC-012), Domain·Data·Infrastructure·Composition
  테스트가 모두 통과하는지(SC-013) 확인한다.
- [ ] T057 [no-write] `Feature`와 `App`의 소스가 변경되지 않았는지(App은 T040의 target 이름
  참조 1건만 예외, SC-014, SC-021), 저장소 Swift 선언에 `Url`·`Id`·`Http` 절충 표기가 0건인지
  (Data `CodingKeys`의 서버 원문 키와 테스트 JSON fixture는 제외, SC-019) `git diff`와
  전수 검토로 확인한다.
- [ ] T058 [no-write] 시나리오 1~6의 독립 수용 기준을 각각 재확인하고, SC-001~SC-022 전체를
  이 기능의 성공 기준과 대조해 미달 항목이 없는지 보고한다.

## 의존성과 실행 순서

### 패키지 순서와 승인 게이트

- `Domain → Infrastructure → Data → Composition` 순서로 실행한다(R-007). `Data`는
  `Infrastructure`에 의존하므로 `Infrastructure` 완료 후에만 착수한다. `Composition`은
  `Domain`·`Data`·`Infrastructure`에 의존하므로 마지막에 착수한다.
- Domain과 Infrastructure는 서로 의존하지 않는 leaf다. 이 문서는 Domain을 먼저 두기로
  확정했다(R-007) — Domain UseCase Protocol이 Composition 공개 타입의 기준이고, Infrastructure
  보완 범위는 Data 구현 설계에서 도출되기 때문이다.
- 한 번에 한 패키지만 구현한다. 현재 패키지의 모든 작업과 검증이 끝나기 전에는 다음 패키지
  작업을 시작하지 않는다.
- 현재 패키지의 변경 파일과 검증 결과를 보고하고 명시적 사용자 승인을 받은 뒤 다음 패키지로
  진행한다. 승인 전 다음 패키지 영향 분석은 허용하지만 해당 패키지 파일 변경은 금지한다.
- 후속 패키지에서 선행 패키지 수정이 필요하면(예: Infrastructure 보완이 Data 착수 후에야
  드러나는 경우) 구현을 중단하고 `/speckit-tasks`로 작업 소유권과 실행 순서를 다시 조정한다.

### 변경 시나리오 추적성

- S1(Domain UseCase 계약)은 T023~T026, T027로 검증한다.
- S2(Data 실행 구현)는 T030~T037로 검증한다.
- S3(Infrastructure 기술 API)는 T028~T029으로 검증한다.
- S4(Composition 실행 그래프)는 T043~T055으로 검증한다.
- S5(아키텍처 문서 개정)는 T001~T004로 검증하며, 다른 모든 시나리오의 선행 조건이다.
- S6(네이밍 rename)은 T005~T022, T038~T042으로 검증하며, rename 전후 동일 테스트 통과로
  순수 rename임을 확인한다(FR-067, SC-020).
- 각 시나리오는 관련된 모든 패키지가 완료된 뒤 T058의 전체 검증에서 독립 수용 기준으로
  재확인한다.

### 패키지 내부 실행

- Infrastructure·Data·Composition 단계는 테스트를 구현과 함께 배치했다. 대상 API·구현이
  존재하지 않는 상태에서 먼저 실패하는 테스트를 작성할 필요는 없다(신규 API에 대한 신규
  테스트이며 기존 동작을 바꾸는 TDD 시나리오가 아니다).
- `[P]`는 승인된 현재 패키지 안의 서로 다른 파일에만 사용한다. 같은 파일을 여러 작업이 바꾸는
  경우(`DataModuleName.swift`, `CompositionModuleName.swift`, `ProjectName.swift`,
  `AppModuleName.swift`)는 순차 실행한다.
- 다른 패키지의 작업은 병렬 실행하지 않는다.

## 구현 전략

1. Domain 패키지를 선택한다. 준비(T001~T004 문서 개정) → rename(T005~T022) → 구현
   (T023~T026) → 정리·검증(T027) 순으로 완료한다.
2. 변경 파일과 실제 검증 결과를 보고하고 Infrastructure 패키지 승인을 요청한 뒤 중단한다.
3. 승인 후 Infrastructure(T028~T029) → Data(T030~T037) → Composition(T038~T055) 순으로 같은
   절차(구현 → 정리·검증 → 보고 → 승인 대기)를 반복한다.
4. Composition 완료와 승인 후에만 전체 완료 검증(T056~T058)을 실행한다.
5. `naming.md` §8 예외를 적용한 rename 3건(T005~T022, T038~T042)의 근거·영향·미검증 범위를
   PR 설명에 기록한다(FR-068).

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 파일 변경 작업은 정확한 경로를 포함한다.
- `LearningSetRemote`, `QuizGenerationRemote`, `AnswerRemote`, `BookmarkRemote`, `MemberRemote`는
  이번 조립 대상(`Authentication`, `LearningProject`, `ExternalRepository`)이 요구하지 않으므로
  concrete 구현을 신설하지 않는다(위험과 대응 표, plan.md).
- 문제 해결과 암묵지 기록(`docs/spec-kit/013-feature-usecase-app-di/trouble-shooting.md`,
  `tacit-knowledge.md`)은 이 tasks.md의 작업 ID로 생성하지 않는다. 조건이 발생하면
  `$speckit-troubleshooting`, `$speckit-tacit-knowledge`가 별도로 기록한다.
