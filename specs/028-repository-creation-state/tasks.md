---

description: "기능 구현 작업 목록: 레포지토리 생성 상태관리 Repository"
---

# 작업 목록: 레포지토리 생성 상태관리 Repository

**입력**: `/specs/028-repository-creation-state/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/repository-creation-state-repository.md](./contracts/repository-creation-state-repository.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를
snapshot한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만
선택한다.

**테스트**: Constitution 원칙 3("동작 변경에는 관련 빌드나 테스트 결과를 남깁니다")과
quickstart.md의 검증 절차에 따라 각 패키지에 테스트 작업을 포함한다.

**구성**: 이 기능은 Domain과 Composition 두 패키지만 변경한다(Data·Feature·UI·App 소스는
공개 UseCase 시그니처가 바뀌지 않아 변경 불필요 — plan.md "구조 결정" 참고). 두 패키지는
서로 독립적으로 컴파일 가능한 단일 패키지 단위이며, Domain이 Composition의 컴파일 의존성이므로
Domain을 먼저 구현한다(아키텍처 문서의 패키지 의존성 표: Composition → Domain).

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[시나리오]**: S1(중복 생성 차단), S2(목록 필터링), S3(완료/실패·타임아웃 해제)
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 실행. `make tuist`의
  파생 workspace·project·심볼릭 링크·cache 갱신은 허용하되 실행 전후 Git 상태를 비교하고
  추적 파일 변경이 생기면 완료로 처리하지 않는다.

---

## 작업 패키지 1: Domain (LearningProject 모듈)

**목표**: "생성 중" 상태 계약·모델을 정의하고, `CreateLearningProject`/`FetchLearningProjects`
UseCase가 이를 사용해 중복 생성을 막고 목록을 필터링하도록 한다.

**소유 경로**: `sources/Projects/Domain/LearningProject/**`, `sources/Projects/Domain/Tests/LearningProject/**`

**관련 변경 시나리오**: S1, S2, S3

**독립 검증**: in-memory 테스트 더블만으로 `CreateLearningProjectTests`/`FetchLearningProjectsTests`가
통과한다(Composition·Data 구현 없이도 Domain 계약·UseCase 로직이 자체 검증됨).

### 구현

- [X] T001 [S1] [S3] `sources/Projects/Domain/LearningProject/Models/LearningProject/RepositoryCreationState.swift`에
  `RepositoryCreationState` 모델(`normalizedGithubRepoURL: String`, `projectID: String?`,
  `recordedAt: Date`)을 `data-model.md`에 정의한 대로 구현한다.
- [X] T002 [S1] `sources/Projects/Domain/LearningProject/Errors/LearningProjectError.swift`에
  `duplicateCreationInProgress` case를 추가한다(`CaseIterable` 준수 유지).
- [X] T003 [S1] [S2] [S3] `sources/Projects/Domain/LearningProject/Contracts/RepositoryCreationStateRepository.swift`를
  신설해 `contracts/repository-creation-state-repository.md`에 정의한 프로토콜
  (`isCreating(githubRepoURL:)`, `beginCreation(githubRepoURL:)`, `attachProjectID(_:toGithubRepoURL:)`,
  `endCreation(githubRepoURL:)`, `endCreation(projectID:)`, `activeProjectIDs()`)을 선언한다.
- [X] T004 [S1] `sources/Projects/Domain/LearningProject/UseCases/CreateLearningProject/CreateLearningProject.swift`를
  수정한다: `init(repository:creationStateRepository:)`로 새 의존성을 주입받고,
  `callAsFunction`에서 (1) `githubRepoURL`을 정규화(트림·소문자·끝 슬래시 제거)하고,
  (2) `beginCreation`이 `false`면 `register` 호출 없이 `LearningProjectError.duplicateCreationInProgress`를
  던지고, (3) `register` 실패 시 `endCreation(githubRepoURL:)`을 호출한 뒤 원래 오류를
  다시 던지며, (4) 성공 시 `attachProjectID(receipt.projectID, toGithubRepoURL:)`를 호출한다.
- [X] T005 [S2] `sources/Projects/Domain/LearningProject/UseCases/FetchLearningProjects/FetchLearningProjects.swift`를
  수정한다: `init(repository:creationStateRepository:)`로 새 의존성을 주입받고,
  `callAsFunction`에서 `repository.fetchProjects(...)` 결과의 `items`에서
  `creationStateRepository.activeProjectIDs()`에 포함된 `projectID`를 가진 항목을 제외한 뒤
  반환한다(`hasNext`는 그대로 유지).

### 테스트

- [X] T006 [P] [S1] `sources/Projects/Domain/Tests/LearningProject/UseCases/CreateLearningProjectTests.swift`를
  갱신한다: 기존 `CreateLearningProjectRepository` 스텁 초기화에 새 in-memory
  `RepositoryCreationStateRepository` 스텁을 추가하고, 다음 시나리오를 검증하는 테스트를
  추가한다 — (a) 동일 `githubRepoURL` 두 번째 요청이 `register` 호출 없이
  `duplicateCreationInProgress`를 던진다, (b) 서로 다른 `githubRepoURL`은 정상적으로
  `register`가 호출된다, (c) `register` 실패 시 상태가 해제되어 같은 URL 재시도가 허용된다.
- [X] T007 [P] [S2] `sources/Projects/Domain/Tests/LearningProject/UseCases/FetchLearningProjectsTests.swift`를
  갱신한다: `activeProjectIDs()`가 특정 `projectID` 집합을 반환하도록 스텁을 구성하고,
  `callAsFunction()` 결과 `items`에서 해당 `projectID`가 제외되는지, 활성 상태가 없을 때는
  서버 응답이 그대로 반환되는지 검증하는 테스트를 추가한다.

### 정리와 패키지 검증

- [X] T008 [no-write] `project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)`
  뒤 `"$project_build_runner" compile`과 `"$project_build_runner" test`를 실행해 Domain 패키지와
  기존 `FetchBookmarkedQuestionsTests` 등 회귀 대상이 통과하는지 확인한다.

**진행 점검**: T001~T008의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행
단위(Composition)로 진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을
요청한다.

---

## 작업 패키지 2: Composition (Adapter)

**목표**: `RepositoryCreationStateRepository`의 실제 in-memory 구현을 제공하고,
`ObserveGenerationOutcomesUseCase` 스트림을 구독해 완료/실패 시 상태를 해제하며, App 부트스트랩에
구독 시작을 배선한다.

**소유 경로**: `sources/Projects/Composition/Adapter/**`, `sources/Projects/Composition/Tests/Adapter/**`,
`sources/Projects/Composition/App/Assemblies/AppComposition.swift`

**관련 변경 시나리오**: S1, S2, S3

**독립 검증**: `RepositoryCreationStateRepositoryAdapterTests`가 실제 actor 구현의 상태 기록·조회·
해제·만료·outcome 구독 동작을 Domain 계약 기준으로 검증한다.

### 구현

- [ ] T009 [S1] [S2] [S3] `sources/Projects/Composition/Adapter/Adapters/RepositoryCreationStateRepositoryAdapter.swift`를
  신설한다: `RepositoryCreationStateRepository`를 구현하는 `actor`로,
  - `githubRepoURL` 정규화(트림·소문자·끝 슬래시 제거)와 `RepositoryCreationState` 딕셔너리
    보관,
  - 모든 메서드 진입 시 `recordedAt`으로부터 900초(15분)를 초과한 레코드를 lazy expiry로
    제거,
  - `isCreating(githubRepoURL:)`은 정규화 후 만료되지 않은 레코드 존재 여부만 반환하는
    부수효과 없는 순수 조회 메서드로 구현,
  - `start(observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase) async` 메서드로
    스트림을 구독해 각 `GenerationOutcome` 수신 시 `endCreation(projectID:)`를 호출
    (`GenerationCompletionReminderCoordinator.start(observeGenerationOutcomes:)`와 유사한 구독
    형태이되, 이 타입은 `Adapter/Factories/`의 순수 outcome 구독자가 아니라 `Adapter/Adapters/`의
    기존 `*Adapter` 명명 관례를 따르는 Domain 계약 구현체다)
  을 구현한다.
- [ ] T010 [S1] [S2] `sources/Projects/Composition/Adapter/Assemblies/LearningProjectAssembly.swift`를
  수정한다: `RepositoryCreationStateRepositoryAdapter` 인스턴스를 생성해 `createLearningProject`와
  `fetchLearningProjects` 초기화에 `creationStateRepository:`로 전달하고, App 부트스트랩이
  구독을 시작할 수 있도록 concrete 타입을 공개 프로퍼티 `repositoryCreationStateAdapter`로
  노출한다(`start(observeGenerationOutcomes:)`가 Domain 계약에 없는 Adapter 전용 메서드이므로
  `any RepositoryCreationStateRepository`가 아닌 concrete 타입으로 노출해야 한다).
- [ ] T011 [S3] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`를 수정한다:
  기존 `startObservingGenerationOutcomes(observeGenerationOutcomes)` 호출 지점(부트스트랩
  클로저)에 `await learningProject.repositoryCreationStateAdapter.start(observeGenerationOutcomes: observeGenerationOutcomes)`
  호출을 추가해 앱 실행 시 구독이 시작되도록 배선한다.

### 테스트

- [ ] T012 [P] [S1] [S2] [S3] `sources/Projects/Composition/Tests/Adapter/Adapters/RepositoryCreationStateRepositoryAdapterTests.swift`를
  신설한다: (a) `beginCreation` → `attachProjectID` → `activeProjectIDs()` 반영, (b) 동일
  정규화 URL 두 번째 `beginCreation`이 `false`를 반환하고 그 URL에 대한 `isCreating`이 `true`를
  반환, (c) `endCreation(githubRepoURL:)`/`endCreation(projectID:)` 해제 뒤 `isCreating`이
  `false`로 돌아옴, (d) 가짜 `ObserveGenerationOutcomesUseCase` 스트림으로
  `GenerationOutcome(projectID:, status: .completed)`를 흘려보내면 `activeProjectIDs()`에서
  사라짐, (e) 900초를 초과한 `recordedAt`을 가진 레코드가 다음 조회에서 사라짐(테스트용 시계
  주입 또는 fixture 사용)을 검증하는 테스트를 작성한다.

### 정리와 패키지 검증

- [ ] T013 [no-write] `"$project_build_runner" compile`과 `"$project_build_runner" test`를 실행해
  Composition 패키지와 기존 `LearningProjectRepositoryAdapterTests`,
  `BookmarkRepositoryAdapterTests`가 회귀 없이 통과하는지 확인한다.

**진행 점검**: T009~T013의 변경 파일과 검증 결과를 보고하고 마지막 적용 패키지이므로 전체
완료 검증으로 진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을 요청한다.

---

## 전체 완료 검증

**선행 조건**: 마지막 적용 대상 패키지(Composition)의 파일 변경 작업을 완료하고, 전체 검증과
hook 결과를 포함할 마지막 커밋 단위를 아직 commit하지 않은 상태여야 한다.

**커밋 경계**: 아래 `[no-write]` 작업은 마지막 적용 패키지의 마지막 커밋 단위에 배정한다.
모든 검증과 필수 `after_implement` hook을 마친 뒤 그 단위를 최종 commit한다.

- [ ] T014 [no-write] `"$project_build_runner" build`, `"$project_build_runner" compile`,
  `"$project_build_runner" test`를 순서대로 실행해 전체 빌드·컴파일·테스트가 회귀 없이
  통과하는지 확인한다. `LearningProjectError`에 case를 추가했으므로 이 enum을 `switch`하는
  기존 호출부가 컴파일되는지(빌드 실패 시 exhaustive switch에 새 case 처리를 추가해야 함을
  T014 결과에 기록) 함께 확인한다.
- [ ] T015 [no-write] spec.md의 수용 시나리오 1~3을 quickstart.md 절차에 따라 최종 확인한다:
  동일 `githubRepoURL` 중복 요청 즉시 거부(S1), "생성 중" 항목의 목록 제외(S2), 완료/실패
  신호 또는 15분 경과 후 상태 해제와 재요청 허용(S3).

## 의존성과 실행 순서

### 실행 단위 순서와 위험 기반 승인

- 아키텍처 문서의 패키지 의존성 표에 따라 Composition은 Domain에 컴파일 타임으로 의존한다.
  따라서 Domain(패키지 1)을 먼저 구현하고 Composition(패키지 2)을 그 뒤에 구현한다. Data,
  Feature, App(부트스트랩 배선 한 줄 제외), UI 패키지는 이 기능으로 변경되지 않으므로 별도
  실행 단위를 만들지 않는다(plan.md "구조 결정" 참고, T011만 예외적으로 `App/Assemblies` 안의
  기존 배선 지점 한 줄을 Composition 단위 안에서 함께 수정한다 — 새 App 패키지 소스나 UseCase
  시그니처 변경이 아니므로 별도 패키지 단위가 아니라 Composition 단위에 귀속시킨다).
- Domain과 Composition은 서로 다른 파일을 변경하므로 각 단위 내부에서는 [P] 병렬화가
  가능하지만, 두 단위 자체는 컴파일 의존성 때문에 순차 실행한다.
- 각 단위를 완료·검증한 뒤 변경 파일과 결과를 보고하고, 같은 기능 범위 안에서는 반복 승인
  없이 다음 단위로 진행한다. 새 범위, 파괴적 작업, remote·외부 상태 변경, 새로운 제품 결정이
  필요할 때만 중단하고 명시적 승인을 요청한다.

### 변경 시나리오 추적성

- S1(중복 생성 차단): T003, T004, T006, T009, T010, T012, T014, T015
- S2(목록 필터링): T003, T005, T007, T009, T010, T012, T014, T015
- S3(완료/실패·타임아웃 해제): T001, T003, T004, T006, T009, T011, T012, T014, T015
- 각 시나리오는 Domain과 Composition 두 패키지가 모두 완료된 뒤(T014~T015) 독립 수용 기준으로
  최종 검증한다.
- 최소 가치 범위: S1(중복 생성 차단)이 사용자에게 가장 직접적인 회귀 방지 가치를 제공하지만,
  Domain UseCase 시그니처가 `RepositoryCreationStateRepository`를 필수로 요구하도록 설계했기
  때문에(T004, T005) 두 패키지를 함께 완료해야 컴파일된다. 따라서 이 기능은 패키지 1·2를
  하나의 연속 범위로 진행하며 중간에 반복 승인을 요구하지 않는다.

### 실행 단위 내부 실행

- 각 패키지 단위 안에서 테스트 작업(T006·T007, T012)은 구현 작업 뒤에 배치했지만, 구현과 같은
  커밋 단위로 묶어 함께 커밋할 수 있다(Constitution 원칙 7: 구현과 직접 관련된 테스트는 같은
  커밋 단위 허용).
- `[P]` 표시가 있는 T006·T007, T012는 각각 서로 다른 테스트 파일을 변경하므로 같은 패키지
  단위 안에서 병렬 실행할 수 있다.
- 서로 다른 패키지 단위(Domain vs. Composition)는 컴파일 의존성이 있으므로 병렬 실행하지
  않는다.

## 구현 전략

1. tasks.md의 blob hash와 전체 diff를 기준선으로 고정한다.
2. 패키지 1(Domain)의 미완료 작업을 논리적 커밋 단위로 설계해 구현·검증·완료 표시·commit을
   순서대로 진행한다.
3. 패키지 2(Composition)로 이어서 진행하되, 이 패키지가 마지막 적용 패키지이므로 마지막
   커밋 단위는 전체 완료 검증(T014, T015)과 필수 `after_implement` hook까지 마친 뒤에
   commit한다.
4. 각 단위 commit 뒤 변경 파일, 검증 결과와 커밋을 보고하고 같은 범위의 다음 단위로 이어간다.
5. 새 권한이 필요한 경계가 나타나면 변경을 시작하기 전에 중단하고 명시적 승인을 요청한다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 파일 변경 작업은 정확한 경로를 포함한다.
- 커밋 단위는 Domain 단위와 Composition 단위 각각 단일 패키지로 구성하며 다중 패키지
  integration unit은 사용하지 않는다(공개 API 이전이나 공용 manifest 변경이 없음).
- 모호한 소유권과 검증되지 않은 범위 확대를 허용하지 않는다.
- 문제 해결과 암묵지 기록을 구현 작업 ID로 생성하지 않는다.
