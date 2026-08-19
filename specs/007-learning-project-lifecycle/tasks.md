---

description: "기능 구현 작업 목록 템플릿"
---

# 작업 목록: 학습 프로젝트 생명주기 UseCase 구현

**입력**: `/specs/007-learning-project-lifecycle/`의 설계 문서

**선행 조건**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (모두 확인함)

**테스트**: spec.md FR-025("각 UseCase는 성공 경로 1개 이상과 문서화된 모든 오류 경로를 검증하는 자동화된 테스트를 가져야 한다")가 테스트를 명시적으로 요구하므로 포함한다.

**구성**: 패키지를 최상위 구현·승인 단위로 사용하고 변경 시나리오는 각 패키지 안에서
추적한다. 이 명세가 변경하는 패키지는 `Domain(DomainLearningProject)` →
`Data(DataLearningProject)` 두 개뿐이다(Infrastructure·Composition·UI·Feature·App은
spec.md `범위 밖`).

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 승인된 현재 패키지 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[시나리오]**: `S1`(외부 Repository 확인·등록, FR-001~010), `S2`(목록·상세 조회,
  FR-011~019), `S3`(삭제, FR-020~022)
- **[no-write]**: 추적 파일을 변경하지 않는 명령 실행 또는 수동 검증

## 패키지 소유권 규칙

- 패키지 소스·테스트와 패키지 전용 Tuist 설정은 해당 패키지 단계가 소유한다.
- 공용 Tuist 구성 파일(`ProjectName.swift`)이 여러 패키지 선언을 바꿔야 하므로,
  Domain 스킴 항목 추가는 Domain 단계에서, Data 스킴 항목 추가는 Data 단계에서 각각
  자신의 항목만 변경한다.
- `trouble-shooting.md`와 `tacit-knowledge.md` 기록은 이 작업 목록에 포함하지 않는다
  — 조건이 발생한 세션에서 각 전용 Spec Kit 스킬이 별도로 기록한다.

---

## 작업 패키지 1: Domain(DomainLearningProject)

**목표**: `FetchExternalRepository`·`CreateLearningProject`·`FetchLearningProjects`·
`FetchLearningProjectDetail`·`DeleteLearningProject` 5개 UseCase와, 이들이 의존하는
Domain 계약(`ExternalRepositoryLookup`, `LearningProjectRepository`) 및 모델을
`DomainAuthentication`과 동일한 폴더 관례(`Contracts/`, `Models/`, `UseCases/`)로
실제 Swift 코드로 제공한다. Infrastructure·Composition 배선 없이 Test Double만으로
"실제로 동작함"을 계약 테스트로 검증한다.

**소유 경로**: `sources/Projects/Domain/DomainLearningProject/`,
`sources/Projects/Domain/DomainLearningProjectTests/`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/DomainModuleName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`(Domain 케이스 스킴 목록만)

**관련 변경 시나리오**: S1, S2, S3

**독립 검증**: `xcodebuild test -workspace GitIt.xcworkspace -scheme DomainLearningProject
-destination 'platform=iOS Simulator,name=iPhone 17 Pro'`가 Fake
`ExternalRepositoryLookup`/`LearningProjectRepository`만으로 실패 0건을 반환한다
(Data·Infrastructure·Composition이 아직 없어도 통과해야 한다).

### 준비와 기반

- [X] T001 `sources/Tuist/ProjectDescriptionHelpers/Projects/DomainModuleName.swift`의
  `DomainModuleName` enum에 `DomainLearningProject`, `DomainLearningProjectTests` 케이스를
  추가하고, `DomainAuthentication`과 동일한 패턴으로 `target` 프로퍼티 분기(`.module`/
  `.testModule(productionTarget:)`)를 확장한다
- [X] T002 [P] `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의
  `case .Domain` 스킴 배열에 `.module(name: "DomainLearningProject", testTarget:
  "DomainLearningProjectTests")` 항목을 기존 `DomainAuthentication` 항목 옆에 추가한다
  (Data 케이스는 이 작업에서 변경하지 않는다)

### 테스트(FR-025)

- [X] T003 [P] [S1] `sources/Projects/Domain/DomainLearningProjectTests/Models/ExternalRepositoryErrorTests.swift`에
  `ExternalRepositoryError`의 `CaseIterable` 전체 케이스(`invalidURLFormat`, `offline`,
  `other`)가 존재함을 검증하는 테스트를 작성한다(`AuthenticationErrorTests` 관례)
- [X] T004 [P] [S1] `sources/Projects/Domain/DomainLearningProjectTests/Models/QuizLevelTests.swift`에
  `QuizLevel`의 `CaseIterable` 전체 케이스(`l1`, `l2`, `l3`)를 검증하는 테스트를 작성한다
- [X] T005 [P] [S1] [S2] `sources/Projects/Domain/DomainLearningProjectTests/Models/QuizGenerationStatusTests.swift`에
  `QuizGenerationStatus`의 `CaseIterable` 전체 케이스 6개(`ready`~`completed`)를 검증하는
  테스트를 작성한다
- [X] T006 [P] [S1] [S2] [S3] `sources/Projects/Domain/DomainLearningProjectTests/Models/LearningProjectErrorTests.swift`에
  `LearningProjectError`의 `CaseIterable` 전체 케이스(`invalidRequest`, `unauthorized`,
  `notFound`, `unexpected`)를 검증하는 테스트를 작성한다
- [X] T007 [P] [S2] `sources/Projects/Domain/DomainLearningProjectTests/Models/LearningProjectDetailTests.swift`에
  `LearningProjectDetail.nextSet` 계산 프로퍼티를 검증하는 테스트 2개를 작성한다 — (1)
  `sets`에 `completedCount < problemCount`인 세트가 있을 때 그 첫 세트를 반환, (2) 모든
  세트가 `completedCount == problemCount`일 때 `nil`을 반환(FR-019, research.md 결정 9)
- [X] T008 [P] [S1] `sources/Projects/Domain/DomainLearningProjectTests/Contracts/ExternalRepositoryLookupContractTests.swift`에
  `ExternalRepositoryLookup`을 채택한 Probe로 `repository(owner:name:)` 호출과 반환값을
  검증하는 계약 테스트를 작성한다(`AuthenticationRepositoryContractTests` 관례)
- [X] T009 [P] [S1] [S2] [S3] `sources/Projects/Domain/DomainLearningProjectTests/Contracts/LearningProjectRepositoryContractTests.swift`에
  `LearningProjectRepository`를 채택한 Probe로 `register`/`fetchProjects`/
  `fetchProjectDetail`/`deleteProject` 4개 메서드 호출과 반환값을 검증하는 계약 테스트를
  작성한다
- [X] T010 [P] [S1] `sources/Projects/Domain/DomainLearningProjectTests/UseCases/FetchExternalRepositoryTests.swift`에
  contracts/fetch-external-repository.md "FR-025 테스트 매트릭스"의 4개 경로(성공, URL
  형식 오류 시 Fake 미호출, `.offline` 그대로 전파, `.other` 그대로 전파)를 검증하는
  테스트를 작성한다
- [X] T011 [P] [S1] `sources/Projects/Domain/DomainLearningProjectTests/UseCases/CreateLearningProjectTests.swift`에
  contracts/create-learning-project.md "FR-025 테스트 매트릭스"의 5개 경로(신규 등록 성공,
  재등록 멱등 성공(FR-007), 삭제 후 복원 성공(FR-008), `.invalidRequest` 전파,
  `.unauthorized` 전파)를 검증하는 테스트를 작성한다
- [X] T012 [P] [S2] `sources/Projects/Domain/DomainLearningProjectTests/UseCases/FetchLearningProjectsTests.swift`에
  contracts/fetch-learning-projects.md "FR-025 테스트 매트릭스"의 3개 경로(성공 —
  진행률·`nextSetId`/`nextQuestionId`·`hasNext` 그대로 반환, 중복 필터링 없음 비-회귀
  (FR-014), `.unauthorized` 전파)를 검증하는 테스트를 작성한다
- [X] T013 [P] [S2] `sources/Projects/Domain/DomainLearningProjectTests/UseCases/FetchLearningProjectDetailTests.swift`에
  contracts/fetch-learning-project-detail.md "FR-025 테스트 매트릭스"의 3개 경로(진행 중
  세트 존재 시 `nextSet` 일치, 모두 완료 시 `nextSet == nil`, `.notFound` 전파(FR-018))를
  검증하는 테스트를 작성한다
- [X] T014 [P] [S3] `sources/Projects/Domain/DomainLearningProjectTests/UseCases/DeleteLearningProjectTests.swift`에
  contracts/delete-learning-project.md "FR-025 테스트 매트릭스"의 2개 경로(성공, `.notFound`
  전파(FR-022))를 검증하는 테스트를 작성한다
- [X] T015 [P] [S1] [S3] `sources/Projects/Domain/DomainLearningProjectTests/UseCases/LearningProjectLifecycleTests.swift`에
  두 개의 조합 계약 테스트를 작성한다 — (1) `FetchExternalRepository`가 반환한
  `ExternalRepository`를 `CreateLearningProject`에 그대로 전달해 `projectId`/`status`를
  확인(SC-001, quickstart.md 시나리오 1), (2) 같은 Fake `LearningProjectRepository`
  인스턴스에 대해 `DeleteLearningProject` 성공 후 `FetchLearningProjectDetail`이
  `.notFound`를 던지도록 구성해 삭제 후 미노출 회귀를 확인(spec.md 시나리오 3 "독립
  테스트", delete-learning-project.md)

### 구현

- [X] T016 [P] [S1] `sources/Projects/Domain/DomainLearningProject/Models/ExternalRepository.swift`에
  `canonicalURL`/`ownerName`/`repositoryName`/`imageURL`/`starCount`/`techStack` 필드를
  가진 `Sendable` 구조체를 구현한다(data-model.md §1 `ExternalRepository`)
- [X] T017 [P] [S1] `sources/Projects/Domain/DomainLearningProject/Models/ExternalRepositoryError.swift`에
  `invalidURLFormat`/`offline`/`other` 3개 케이스를 가진
  `CaseIterable, Equatable, Error, Sendable` enum을 구현한다
- [X] T018 [P] [S1] `sources/Projects/Domain/DomainLearningProject/Models/QuizLevel.swift`에
  `l1`/`l2`/`l3` 3개 케이스를 가진 `CaseIterable, Equatable, Sendable` enum을 구현한다
  (wire 표기는 노출하지 않는다)
- [X] T019 [P] [S1] [S2] `sources/Projects/Domain/DomainLearningProject/Models/QuizGenerationStatus.swift`에
  `ready`/`analyzed`/`anchored`/`rejected`/`failed`/`completed` 6개 케이스를 가진
  `CaseIterable, Equatable, Sendable` enum을 구현한다
- [X] T020 [P] [S1] `sources/Projects/Domain/DomainLearningProject/Models/LearningProjectRegistration.swift`에
  `projectId: String`/`status: QuizGenerationStatus`/`quizLevel: QuizLevel` 필드를 가진
  `Sendable` 구조체를 구현한다(data-model.md §1 `LearningProjectRegistration`)
- [X] T021 [P] [S2] `sources/Projects/Domain/DomainLearningProject/Models/LearningProjectSummary.swift`에
  `projectId`/`repositoryName`/`repositoryImageURL`/`techStack`/`currentSetLabel`/
  `currentSetTitle`/`nextSetId`/`nextQuestionId`/`overallProgressPercent` 필드를 가진
  `Sendable` 구조체를 구현한다
- [X] T022 [P] [S2] `sources/Projects/Domain/DomainLearningProject/Models/LearningProjectPage.swift`에
  `items: [LearningProjectSummary]`/`hasNext: Bool` 필드를 가진 `Sendable` 구조체를
  구현한다
- [X] T023 [P] [S2] `sources/Projects/Domain/DomainLearningProject/Models/LearningProjectSetProgress.swift`에
  `setId`/`label`/`title`/`problemCount`/`completedCount` 필드를 가진 `Sendable` 구조체를
  구현한다
- [X] T024 [P] [S2] `sources/Projects/Domain/DomainLearningProject/Models/LearningProjectDetail.swift`에
  `projectId`/`repositoryURL`/`repositoryName`/`repositoryImageURL`/`starCount`/
  `techStack`/`overallProgressPercent`/`nextQuestionId`/`sets: [LearningProjectSetProgress]`
  필드와 `nextSet: LearningProjectSetProgress?` 계산 프로퍼티(`sets`에서
  `completedCount < problemCount`인 첫 세트, FR-019)를 가진 `Sendable` 구조체를 구현한다
- [X] T025 [P] [S1] [S2] [S3] `sources/Projects/Domain/DomainLearningProject/Models/LearningProjectError.swift`에
  `invalidRequest`/`unauthorized`/`notFound`/`unexpected` 4개 케이스를 가진
  `CaseIterable, Equatable, Error, Sendable` enum을 구현한다
- [X] T026 [P] [S1] `sources/Projects/Domain/DomainLearningProject/Contracts/ExternalRepositoryLookup.swift`에
  `func repository(owner: String, name: String) async throws -> ExternalRepository`를
  가진 `Sendable` 프로토콜을 구현한다(URL 파싱은 호출자 책임, `.invalidURLFormat`은 이
  메서드가 던지지 않음 — research.md 결정 4)
- [X] T027 [P] [S1] [S2] [S3] `sources/Projects/Domain/DomainLearningProject/Contracts/LearningProjectRepository.swift`에
  `register(githubRepoUrl:quizLevel:)`/`fetchProjects(page:size:)`/
  `fetchProjectDetail(projectId:)`/`deleteProject(projectId:)` 4개 메서드를 가진
  `Sendable` 프로토콜을 구현한다(research.md 결정 3 — 외부 시스템 단위 단일 계약)
- [X] T028 [P] [S1] `sources/Projects/Domain/DomainLearningProject/UseCases/FetchExternalRepository.swift`에
  `init(lookup: ExternalRepositoryLookup)`과
  `callAsFunction(url: String) async throws -> ExternalRepository`를 가진 `Sendable`
  구조체를 구현한다 — `url`에서 소유자·저장소 이름을 파싱(FR-001)해 성공하면
  `lookup.repository(owner:name:)`을 호출해 그대로 반환/재던짐하고, 실패하면 `lookup`을
  호출하지 않고 `.invalidURLFormat`을 던진다
- [X] T029 [P] [S1] `sources/Projects/Domain/DomainLearningProject/UseCases/CreateLearningProject.swift`에
  `init(repository: LearningProjectRepository)`과
  `callAsFunction(githubRepoUrl: String, quizLevel: QuizLevel) async throws ->
  LearningProjectRegistration`을 가진 `Sendable` 구조체를 구현한다 — 입력을 그대로
  `repository.register`에 위임하고 결과를 그대로 반환한다(재등록·복원 판단은 재해석하지
  않음)
- [X] T030 [P] [S2] `sources/Projects/Domain/DomainLearningProject/UseCases/FetchLearningProjects.swift`에
  `init(repository: LearningProjectRepository)`과
  `callAsFunction(page: Int = 0, size: Int = 10) async throws -> LearningProjectPage`를
  가진 `Sendable` 구조체를 구현한다(FR-011 기본값)
- [X] T031 [P] [S2] `sources/Projects/Domain/DomainLearningProject/UseCases/FetchLearningProjectDetail.swift`에
  `init(repository: LearningProjectRepository)`과
  `callAsFunction(projectId: String) async throws -> LearningProjectDetail`을 가진
  `Sendable` 구조체를 구현한다
- [X] T032 [P] [S3] `sources/Projects/Domain/DomainLearningProject/UseCases/DeleteLearningProject.swift`에
  `init(repository: LearningProjectRepository)`과
  `callAsFunction(projectId: String) async throws`를 가진 `Sendable` 구조체를 구현한다

### 정리와 패키지 검증

- [X] T033 [no-write] `xcodebuild test -workspace GitIt.xcworkspace -scheme
  DomainLearningProject -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`로
  패키지를 검증한다(실패 0건, T003~T015의 테스트 매트릭스 전부 통과 확인)

**승인 게이트**: T001~T033의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가 Data
패키지 진행을 명시적으로 승인하기 전에는 `DataLearningProject` 관련 파일을 변경하지
않는다.

---

## 작업 패키지 2: Data(DataLearningProject)

**목표**: GitHub 공개 API·Git-It 서버 응답의 wire 형식을 1:1로 표현하는 DTO와, 후속
Composition Adapter가 위임할 Data 계약(`ExternalRepositoryRemote`,
`LearningProjectRemote`)·Data 오류 타입을 `DataAuthentication`과 동일한 폴더 관례
(`Contracts/`, `DTOs/`, `Errors/`)로 제공한다. DTO↔Domain 변환과 실제 HTTP 호출은 이
패키지가 구현하지 않는다(research.md 결정 6, Composition Adapter 범위 밖).

**소유 경로**: `sources/Projects/Data/DataLearningProject/`,
`sources/Projects/Data/DataLearningProjectTests/`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`(Data 케이스 스킴 목록만)

**관련 변경 시나리오**: S1, S2, S3

**독립 검증**: `xcodebuild test -workspace GitIt.xcworkspace -scheme DataLearningProject
-destination 'platform=iOS Simulator,name=iPhone 17 Pro'`가 `Git-It-server-scheme.json`
예시 응답 디코딩과 오류 케이스 커버리지에서 실패 0건을 반환한다(`DomainLearningProject`에
의존하지 않는다).

### 준비와 기반

- [X] T034 `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`의
  `DataModuleName` enum에 `DataLearningProject`, `DataLearningProjectTests` 케이스를
  추가하고, `DataAuthentication`과 동일한 패턴으로 `target` 프로퍼티 분기를 확장한다
- [X] T035 [P] `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의
  `case .Data` 스킴 배열에 `.module(name: "DataLearningProject", testTarget:
  "DataLearningProjectTests")` 항목을 기존 `DataAuthentication` 항목 옆에 추가한다

### 테스트

- [X] T036 [P] [S1] `sources/Projects/Data/DataLearningProjectTests/DTOs/GitHubRepositoryResponseDTOTests.swift`에
  GitHub API `GET /repos/{owner}/{repo}` 표준 응답 예시 JSON(`full_name`, `html_url`,
  중첩 `owner.avatar_url`, `stargazers_count`, `language`, `topics`)을
  `GitHubRepositoryResponseDTO`로 디코딩하는 테스트를 작성한다
- [X] T037 [P] [S1] `sources/Projects/Data/DataLearningProjectTests/DTOs/RegisterProjectRequestDTOTests.swift`에
  `RegisterProjectRequestDTO`(`githubRepoUrl`, `quizLevel: QuizLevelDTO?`)가
  `RegisterProjectRequest` 스키마와 동일한 키로 인코딩되는지 검증하는 테스트를 작성한다
- [X] T038 [P] [S1] `sources/Projects/Data/DataLearningProjectTests/DTOs/RegisterProjectResponseDTOTests.swift`에
  `Git-It-server-scheme.json`의 `RegisterProjectResponse` 예시(`projectId`,
  `status: QuizGenerationStatusDTO`, `quizLevel` 필드 없음)를
  `RegisterProjectResponseDTO`로 디코딩하는 테스트를 작성한다
- [X] T039 [P] [S2] `sources/Projects/Data/DataLearningProjectTests/DTOs/ProjectListResponseDTOTests.swift`에
  `Git-It-server-scheme.json`의 `GET /api/v1/projects` 예시 응답을
  `ProjectListResponseDTO`(중첩 `ProjectListItemDTO` 포함)로 디코딩하는 테스트를 작성한다
- [X] T040 [P] [S2] `sources/Projects/Data/DataLearningProjectTests/DTOs/ProjectDetailResponseDTOTests.swift`에
  `Git-It-server-scheme.json`의 `GET /api/v1/projects/{projectId}` 예시 응답을
  `ProjectDetailResponseDTO`(중첩 `ProjectSetSummaryDTO` 배열 포함)로 디코딩하는 테스트를
  작성한다
- [X] T041 [P] [S1] [S2] [S3] `sources/Projects/Data/DataLearningProjectTests/Errors/DataExternalRepositoryErrorTests.swift`에
  `DataExternalRepositoryError`의 `CaseIterable` 전체 케이스(`offline`, `other`)를
  검증하는 테스트를 작성한다
- [X] T042 [P] [S1] [S2] [S3] `sources/Projects/Data/DataLearningProjectTests/Errors/DataLearningProjectErrorTests.swift`에
  `DataLearningProjectError`의 `CaseIterable` 전체 케이스(`invalidRequest`,
  `unauthorized`, `notFound`, `serverError`, `unexpected`)를 검증하는 테스트를 작성한다
- [X] T043 [P] [S1] `sources/Projects/Data/DataLearningProjectTests/Contracts/ExternalRepositoryRemoteContractTests.swift`에
  `ExternalRepositoryRemote`를 채택한 Probe로 `repository(owner:name:)` 호출과 반환값을
  검증하는 계약 테스트를 작성한다
- [X] T044 [P] [S1] [S2] [S3] `sources/Projects/Data/DataLearningProjectTests/Contracts/LearningProjectRemoteContractTests.swift`에
  `LearningProjectRemote`를 채택한 Probe로 `registerProject`/`fetchProjects`/
  `fetchProjectDetail`/`deleteProject` 4개 메서드 호출과 반환값을 검증하는 계약 테스트를
  작성한다

### 구현

- [X] T045 [P] [S1] `sources/Projects/Data/DataLearningProject/DTOs/GitHubRepositoryResponseDTO.swift`에
  `fullName`/`htmlURL`/`ownerAvatarURL`/`starCount`/`language`/`topics` 프로퍼티와
  `full_name`/`html_url`/중첩 `owner.avatar_url`/`stargazers_count`/`language`/`topics`
  wire 키에 대응하는 `CodingKeys`를 가진 `Codable` 구조체를 구현한다(data-model.md §2)
- [X] T046 [P] [S1] `sources/Projects/Data/DataLearningProject/DTOs/RegisterProjectRequestDTO.swift`에
  `githubRepoUrl: String`/`quizLevel: QuizLevelDTO?` 필드를 가진 `Codable` 구조체와,
  `L1`/`L2`/`L3` raw value를 가진 `QuizLevelDTO: String, Codable` enum을 같은 파일에
  구현한다
- [X] T047 [P] [S1] `sources/Projects/Data/DataLearningProject/DTOs/RegisterProjectResponseDTO.swift`에
  `projectId: String`/`status: QuizGenerationStatusDTO` 필드를 가진 `Codable` 구조체와,
  `READY`/`ANALYZED`/`ANCHORED`/`REJECTED`/`FAILED`/`COMPLETED` raw value를 가진
  `QuizGenerationStatusDTO: String, Codable` enum을 같은 파일에 구현한다
- [X] T048 [P] [S2] `sources/Projects/Data/DataLearningProject/DTOs/ProjectListResponseDTO.swift`에
  `items: [ProjectListItemDTO]`/`hasNext: Bool` 필드를 가진 `Codable` 구조체를 구현한다
- [X] T049 [P] [S2] `sources/Projects/Data/DataLearningProject/DTOs/ProjectListItemDTO.swift`에
  `projectId`/`repositoryName`/`repositoryImageUrl`/`techStack: [String]`/
  `currentSetLabel`/`currentSetTitle`/`nextSetId`/`nextQuestionId`/
  `overallProgressPercent: Int` 필드를 가진 `Codable` 구조체를 구현한다
- [X] T050 [P] [S2] `sources/Projects/Data/DataLearningProject/DTOs/ProjectDetailResponseDTO.swift`에
  `projectId`/`repositoryUrl`/`repositoryName`/`repositoryImageUrl`/`starCount: Int`/
  `techStack: [String]`/`overallProgressPercent: Int`/`nextQuestionId: String?`/
  `sets: [ProjectSetSummaryDTO]` 필드를 가진 `Codable` 구조체를 구현한다
- [X] T051 [P] [S2] `sources/Projects/Data/DataLearningProject/DTOs/ProjectSetSummaryDTO.swift`에
  `setId`/`label`/`title`/`problemCount: Int`/`completedCount: Int` 필드를 가진 `Codable`
  구조체를 구현한다
- [X] T052 [P] [S1] [S2] [S3] `sources/Projects/Data/DataLearningProject/Errors/DataExternalRepositoryError.swift`에
  `offline`/`other` 2개 케이스를 가진 `CaseIterable, Equatable, Error, Sendable` enum을
  구현한다(`invalidURLFormat`에 대응하는 케이스는 없음 — research.md 결정 4)
- [X] T053 [P] [S1] [S2] [S3] `sources/Projects/Data/DataLearningProject/Errors/DataLearningProjectError.swift`에
  `invalidRequest`(`COMMON-001`)/`unauthorized`(`COMMON-002`)/`notFound`(`PROJECT-001`)/
  `serverError`(`COMMON-005`)/`unexpected` 5개 케이스를 가진
  `CaseIterable, Equatable, Error, Sendable` enum을 구현한다
- [X] T054 [P] [S1] `sources/Projects/Data/DataLearningProject/Contracts/ExternalRepositoryRemote.swift`에
  `func repository(owner: String, name: String) async throws ->
  GitHubRepositoryResponseDTO`를 가진 `Sendable` 프로토콜을 구현한다(`GET
  https://api.github.com/repos/{owner}/{name}`에 대응, FR-002)
- [X] T055 [P] [S1] [S2] [S3] `sources/Projects/Data/DataLearningProject/Contracts/LearningProjectRemote.swift`에
  `registerProject(_:)`/`fetchProjects(page:size:)`/`fetchProjectDetail(projectId:)`/
  `deleteProject(projectId:)` 4개 메서드를 가진 `Sendable` 프로토콜을 구현한다(`/api/v1/projects`
  Bearer 인증 엔드포인트에 대응, FR-005·FR-011·FR-016·FR-020)

### 정리와 패키지 검증

- [X] T056 [no-write] `xcodebuild test -workspace GitIt.xcworkspace -scheme
  DataLearningProject -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`로 패키지를
  검증한다(실패 0건, T036~T044의 디코딩·오류 케이스 전부 통과 확인)

**승인 게이트**: T034~T056의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가 전체
완료 검증 진행을 명시적으로 승인하기 전에는 추가 패키지 파일을 변경하지 않는다.

---

## 전체 완료 검증

**선행 조건**: `DataLearningProject` 패키지의 구현·검증·결과 보고가 완료되어야 한다.

- [X] T057 [no-write] `DomainLearningProject`·`DataLearningProject` 두 스킴의
  `xcodebuild test`를 순서대로 재실행하고 결과를 기록한다(quickstart.md "전체 재확인")
- [X] T058 [no-write] spec.md 시나리오 1·2·3의 수용 시나리오 8+4+2개 전체를 T010~T015,
  T012~T013 테스트 결과와 대조해 SC-001~SC-004가 Domain·Data 범위 안에서 충족되었는지
  확인한다(Composition 배선과 실제 네트워크 왕복 검증은 후속 스펙 범위)

## 의존성과 실행 순서

### 패키지 순서와 승인 게이트

- `Domain(DomainLearningProject)` → `Data(DataLearningProject)` 순서로만 실행한다
  (Infrastructure·Composition·UI·Feature·App은 이 명세가 변경하지 않음).
- 한 번에 한 패키지만 구현한다. Domain 패키지의 모든 작업과 검증(T001~T033)이 끝나기
  전에는 Data 패키지 작업(T034~)을 시작하지 않는다.
- 각 패키지의 변경 파일과 검증 결과를 보고하고 명시적 사용자 승인을 받은 뒤 다음
  패키지로 진행한다.
- Data 패키지에서 Domain 패키지 파일 수정이 필요해지면(예: 계약 시그니처 변경) 구현을
  중단하고 `/speckit-tasks`로 작업 소유권과 실행 순서를 다시 조정한다.

### 변경 시나리오 추적성

- S1(FR-001~010)은 T003~T004, T006, T008, T010~T011, T015~T020, T025~T029, T036~T038,
  T041~T047, T052~T055에서 추적한다.
- S2(FR-011~019)는 T005~T007, T009, T012~T013, T015, T019, T021~T025, T027, T030~T031,
  T039~T041, T044, T048~T051, T053, T055에서 추적한다.
- S3(FR-020~022)는 T006, T009, T014~T015, T025, T027, T032, T041~T042, T044, T052~T053,
  T055에서 추적한다.
- 각 변경 시나리오는 Domain·Data 두 패키지가 모두 완료된 뒤 T058에서 독립 수용 기준으로
  검증한다. 최소 가치 범위(S1)도 패키지 승인 게이트를 건너뛰지 않는다.

### 패키지 내부 실행

- 각 패키지는 테스트(T003~T015 / T036~T044)를 그 패키지의 구현(T016~T032 /
  T045~T055) 전에 작성한다. Swift 컴파일 언어 특성상 "예상한 이유로 실패"는 구현 타입이
  없어 컴파일이 실패하는 상태를 뜻한다.
- `[P]`는 승인된 현재 패키지 안의 서로 다른 파일에만 사용한다 — 같은 파일을 여러 작업이
  바꾸지 않는다.
- 다른 패키지의 작업(예: Domain의 T016~과 Data의 T045~)은 병렬 실행하지 않는다.

## 병렬 실행 예시 (Domain 패키지, 승인 후)

```text
# 테스트 작성을 한 번에 병렬로 시작할 수 있다(서로 다른 파일):
Task: "T003 ExternalRepositoryErrorTests.swift 작성"
Task: "T004 QuizLevelTests.swift 작성"
Task: "T010 FetchExternalRepositoryTests.swift 작성"
Task: "T011 CreateLearningProjectTests.swift 작성"

# 구현 단계에서도 서로 다른 모델 파일은 병렬 실행 가능:
Task: "T016 ExternalRepository.swift 구현"
Task: "T017 ExternalRepositoryError.swift 구현"
Task: "T021 LearningProjectSummary.swift 구현"
```

## 구현 전략

1. Domain 패키지(T001~T033)를 먼저 완료한다 — Tuist 스캐폴딩 → 테스트 → 모델·계약·
   UseCase 구현 → `DomainLearningProject` 스킴 검증.
2. 변경 파일과 `xcodebuild test` 결과를 보고하고 Data 패키지 진행 승인을 요청한 뒤
   중단한다.
3. 승인 후 Data 패키지(T034~T056)를 동일한 절차(스캐폴딩 → 테스트 → DTO·계약·오류
   구현 → `DataLearningProject` 스킴 검증)로 완료한다.
4. 변경 파일과 검증 결과를 보고하고 전체 완료 검증(T057~T058) 진행 승인을 요청한다.
5. 승인 후 T057~T058만 실행한다 — 이 단계는 파일을 변경하지 않는다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 모든 파일 변경 작업은 정확한 저장소 상대 경로 하나와 정확히 하나의 책임 패키지를
  가진다.
- Composition 배선(DI), Feature/UI 화면, 로컬 캐싱·Polling·재시도는 이 작업 목록의
  범위 밖이며 후속 스펙이 담당한다(plan.md·spec.md `범위 밖`).
- 문제 해결과 암묵지 기록은 이 작업 목록의 작업 ID로 생성하지 않는다.
