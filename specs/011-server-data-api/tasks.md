---

description: "기능 구현 작업 목록 템플릿"
---

# 작업 목록: Git-It Server API 전체 Data 패키지 구현

**입력**: `/specs/011-server-data-api/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/](./contracts)

**개정 사유**: `/speckit-analyze` 보고서(C1/C2/C3/U1)를 반영해 재생성했다. 이전 버전에는
공통 응답 envelope(`APIResponseDTO`/`FieldErrorDTO`/`ServerAPIError`, FR-005) 구현 작업,
`Endpoints/` HTTP method/path/query/body·Bearer 헤더 구현 작업(FR-003/FR-004),
`ServerAPIError → 도메인 오류` 매핑 함수 구현 작업(FR-006)이 누락되어 있었고,
LearningProject의 배열 순서 보존 검증(FR-009)이 명시적이지 않았다. 이번 버전은 세 target
모두에 이 네 가지를 추가하고 T001부터 다시 번호를 매겼다.

**테스트**: spec.md FR-015(각 operation의 request/response contract test)와 FR-016(production
target에 test fixture 금지)이 테스트 작업을 명시적으로 요구하므로 테스트 작업을 포함한다.

**구성**: 이 명세는 Data 패키지만 변경한다(`Domain → Data → Infrastructure → Composition →
UI → Feature → App` 중 Data만 해당). Data 패키지 내부는 서로 독립된 3개 target
(`DataAuthentication`, `DataLearningProject`, `DataMember`)으로 나뉘며, plan.md 헌법
점검에서 이 3개 target을 각각 하나의 구현·승인 단위로 순차 진행하기로 결정했다
(research.md 결정 1~4 근거). 아래 "작업 패키지"는 이 target 단위를 뜻한다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 승인된 현재 작업 패키지 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[S1]/[S2]/[S3]**: spec.md의 변경 시나리오 1~3에 대응
- **[no-write]**: 추적 파일을 변경하지 않는 명령 실행 또는 검증
- 파일 변경 작업은 정확한 저장소 상대 경로 하나와 정확히 하나의 책임 target을 가진다.

## 패키지 소유권 규칙

- `sources/Projects/Data/Authentication/**`, `sources/Projects/Data/Tests/Authentication/**`는
  작업 패키지 1(Authentication)이 소유한다.
- `sources/Projects/Data/LearningProject/**`,
  `sources/Projects/Data/Tests/LearningProject/**`는 작업 패키지 2(LearningProject)가
  소유한다.
- `sources/Projects/Data/Member/**`, `sources/Projects/Data/Tests/Member/**`는 작업 패키지
  3(Member)이 소유한다.
- `APIResponseDTO`/`FieldErrorDTO`/`ServerAPIError`는 3개 target에 각각 독립적으로
  선언한다(research.md 결정 4 — Data 패키지 내부에 공유 target을 두지 않는다). 같은 이름의
  타입이 서로 다른 target에 중복 선언되는 것은 의도된 설계다.
- `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`와
  `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`는 3개 target 선언을 모두
  담는 공용 파일이다. `DataAuthentication`/`DataLearningProject` 선언은 이미 존재하므로
  수정하지 않고, `DataMember`/`DataMemberTests` 선언만 추가한다 — 이 추가는 작업 패키지
  3(Member)에서 처음 필요하므로 그 단계에 배정한다.
- 전체 기능 검증(19/19 operation, 제외 대상 검색)은 마지막 작업 패키지(Member) 뒤에
  `[no-write]`로만 둔다.

---

## 작업 패키지 1: Data — Authentication

**목표**: 참조 문서 AUTH-01(Apple 로그인), AUTH-02(Access Token 확인) 2개 operation만
표현하는 `AuthenticationRemote` 계약으로 `DataAuthentication`을 재작성하고, refresh/revoke
세션 관리와 관련된 기존 코드를 제거한다(research.md 결정 1). 공통 envelope·오류 매핑·
Endpoint 계약도 이 target에 처음 도입한다.

**소유 경로**: `sources/Projects/Data/Authentication/**`,
`sources/Projects/Data/Tests/Authentication/**`

**관련 변경 시나리오**: S1, S2, S3

**독립 검증**: `DataAuthenticationTests`만 build-for-testing/test-without-building하여
AUTH-01/AUTH-02 contract test, envelope/오류 매핑 테스트, 민감 값 노출 테스트가 통과하고,
저장소 전체에서 `refreshSession`/`revokeRefreshToken`/`RefreshRequestDTO`/
`RefreshResponseDTO`/`googleLogin` 검색 결과가 0건임을 확인한다.

### 준비 — 기존 refresh/revoke 계약 제거

- [X] T001 [S3] `sources/Projects/Data/Authentication/Contracts/LoginSessionRemote.swift`,
  `sources/Projects/Data/Authentication/Contracts/LoginSessionStorage.swift`,
  `sources/Projects/Data/Authentication/Contracts/AuthenticationAuthorizationStorage.swift`,
  `sources/Projects/Data/Authentication/Contracts/AuthenticationProvider.swift`를 삭제한다
  (research.md 결정 1 — SPEC-DATA-API-001에 없는 세션 저장 계약).
- [X] T002 [S3] `sources/Projects/Data/Authentication/DTOs/LoginSessionResponseDTO.swift`,
  `sources/Projects/Data/Authentication/DTOs/LoginSessionStartRequestDTO.swift`,
  `sources/Projects/Data/Authentication/DTOs/RefreshRequestDTO.swift`,
  `sources/Projects/Data/Authentication/DTOs/RefreshResponseDTO.swift`를 삭제한다.
- [X] T003 [S3] `sources/Projects/Data/Authentication/Models/AuthenticationEvidence.swift`,
  `sources/Projects/Data/Authentication/Models/AuthorizationState.swift`,
  `sources/Projects/Data/Authentication/Models/StoredAuthorizationReference.swift`,
  `sources/Projects/Data/Authentication/Models/StoredLoginSession.swift`를 삭제한다.
- [X] T004 [S3] `sources/Projects/Data/Tests/Authentication/Contracts/AuthenticationAuthorizationStorageContractTests.swift`,
  `sources/Projects/Data/Tests/Authentication/Contracts/AuthenticationProviderContractTests.swift`,
  `sources/Projects/Data/Tests/Authentication/Contracts/LoginSessionRemoteContractTests.swift`,
  `sources/Projects/Data/Tests/Authentication/Contracts/LoginSessionStorageContractTests.swift`,
  `sources/Projects/Data/Tests/Authentication/DTOs/LoginSessionResponseDTOTests.swift`,
  `sources/Projects/Data/Tests/Authentication/DTOs/LoginSessionStartRequestDTOTests.swift`,
  `sources/Projects/Data/Tests/Authentication/DTOs/RefreshDTOTests.swift`,
  `sources/Projects/Data/Tests/Authentication/Models/AuthenticationEvidenceTests.swift`,
  `sources/Projects/Data/Tests/Authentication/Models/AuthorizationStateTests.swift`,
  `sources/Projects/Data/Tests/Authentication/Models/StoredAuthorizationReferenceTests.swift`,
  `sources/Projects/Data/Tests/Authentication/Models/StoredLoginSessionTests.swift`를 삭제한다.

### 테스트

- [X] T005 [P] [S1] `sources/Projects/Data/Tests/Authentication/DTOs/APIResponseDTOTests.swift`에
  `APIResponseDTO<Payload>`의 `data` key 부재·`null` Unit 응답 decode 성공, `FieldErrorDTO`
  decode 테스트를 작성한다(FR-005, data-model.md 공통 형태).
- [X] T006 [P] [S2] `sources/Projects/Data/Tests/Authentication/Errors/ServerAPIErrorTests.swift`에
  `ServerAPIError(httpStatus, code, message, fieldErrors)` decode 테스트를 작성한다.
- [X] T007 [P] [S1] `sources/Projects/Data/Tests/Authentication/Endpoints/AuthenticationEndpointTests.swift`에
  AUTH-01(인증 헤더 없음)·AUTH-02(`Authorization: Bearer`, `Accept`, `Content-Type` 헤더
  포함) 요청 조립 테스트를 작성한다(FR-003, FR-004 — method/path/query/body는 참조 문서
  operation ID로만 지칭하고 리터럴 URL을 테스트 설명에 적지 않는다).
- [X] T008 [P] [S1] `sources/Projects/Data/Tests/Authentication/Contracts/AuthenticationRemoteContractTests.swift`에
  AUTH-01(`appleLogin`)·AUTH-02(`verifyAccessToken`) request/response contract test를
  작성한다(fixture: Apple Login 성공, Access Token Verify 성공 — spec.md 14절 항목 1·2).
- [X] T009 [P] [S1] `sources/Projects/Data/Tests/Authentication/DTOs/AppleLoginRequestDTOTests.swift`에
  `AppleLoginRequestDTO` 인코딩과 `description`/`debugDescription`의 `idToken` `<redacted>`
  치환 테스트를 작성한다.
- [X] T010 [P] [S1] `sources/Projects/Data/Tests/Authentication/DTOs/LoginResponseDTOTests.swift`에
  `LoginResponseDTO` 디코딩과 `accessToken`/`refreshToken` `<redacted>` 치환 테스트를
  작성한다.
- [X] T011 [P] [S2] `sources/Projects/Data/Tests/Authentication/Errors/DataAuthenticationErrorTests.swift`에
  `DataAuthenticationError.init(from:)` 매핑 함수의 대표 오류 매핑(400 `COMMON-001`→
  `invalidRequest`, 401 `COMMON-002`→`unauthorized`, 500 `COMMON-005`→
  `temporarilyUnavailable`) fixture 테스트를 작성한다(FR-006).
- [X] T012 [S3] `sources/Projects/Data/Tests/Authentication/Security/SensitiveValueExposureTests.swift`를
  새 DTO(`AppleLoginRequestDTO`, `LoginResponseDTO`) 기준으로 다시 작성해 Apple ID Token/
  Access Token/Refresh Token/Authorization header 원문이 로그·debug description에
  노출되지 않음을 검증한다(FR-014, SC-006).

### 구현

- [X] T013 [P] [S1] `sources/Projects/Data/Authentication/DTOs/APIResponseDTO.swift`에
  `APIResponseDTO<Payload>`(`success`/`data`/`code`/`message`/`errors`)와 `FieldErrorDTO`를
  구현한다(FR-005).
- [X] T014 [P] [S2] `sources/Projects/Data/Authentication/Errors/ServerAPIError.swift`에
  `httpStatus`/`code`/`message`/`fieldErrors`를 구현한다(FR-006 변환 입력).
- [X] T015 [S1] `sources/Projects/Data/Authentication/Endpoints/AuthenticationEndpoint.swift`에
  AUTH-01/AUTH-02의 method/path/query/body 조립과 Bearer 인증 헤더 적용 규칙을
  구현한다(FR-003, FR-004 — 리터럴 URL은 참조 문서를 정본으로 하고 이 파일의 문서 주석에도
  재기재하지 않으며 operation ID만 인용한다).
- [X] T016 [S1] `sources/Projects/Data/Authentication/Contracts/AuthenticationRemote.swift`에
  `appleLogin(idToken:) async throws -> LoginResponseDTO`,
  `verifyAccessToken() async throws` 2개 메서드만 선언한 프로토콜을 구현한다
  (contracts/authentication-remote.md 근거, `googleLogin`/refresh/revoke 선언 금지).
- [X] T017 [P] [S1] `sources/Projects/Data/Authentication/DTOs/AppleLoginRequestDTO.swift`에
  `idToken: String` 요청 DTO를 구현하고 `<redacted>` 치환 `description`/`debugDescription`을
  추가한다.
- [X] T018 [P] [S1] `sources/Projects/Data/Authentication/DTOs/LoginResponseDTO.swift`에
  `accessToken`/`refreshToken`/`needsCuration` 응답 DTO를 구현하고 `<redacted>` 치환을
  추가한다.
- [X] T019 [S2] `sources/Projects/Data/Authentication/Errors/DataAuthenticationError.swift`에
  `invalidRequest`, `unauthorized`, `temporarilyUnavailable`, `transport`, `decoding`,
  `unexpectedStatus` 6개 케이스와 `init(from serverError: ServerAPIError)` 매핑 함수를
  구현한다(data-model.md `DataAuthentication target` 근거).

### 정리와 패키지 검증

- [X] T020 [no-write] `"$project_build_runner" compile`과
  `"$project_build_runner" test`를 `DataAuthenticationTests` 대상으로 실행해 T005~T019를
  검증한다.
- [X] T021 [no-write] 저장소 전체에서
  `grep -rn "refreshSession\|revokeRefreshToken\|RefreshRequestDTO\|RefreshResponseDTO\|googleLogin(\|GoogleLoginRequestDTO\|GoogleLoginEndpoint" sources/Projects/Data/Authentication sources/Projects/Data/Tests/Authentication`
  결과가 0건임을 확인한다(SC-002, SC-008 부분 검증).

**승인 게이트**: T001~T021의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가 다음
적용 대상 target(LearningProject)을 명시적으로 승인하기 전에는 그 target 파일을 변경하지
않는다.

---

## 작업 패키지 2: Data — LearningProject

**목표**: 참조 문서 PROJECT-01~11 11개 operation을 표현하는 `LearningProjectRemote`를
placeholder 상태에서 신규 구현한다(research.md 결정 2). Authentication과 동일한 형태의
공통 envelope·오류 매핑·Endpoint 계약을 이 target에도 독립적으로 구현한다.

**소유 경로**: `sources/Projects/Data/LearningProject/**`,
`sources/Projects/Data/Tests/LearningProject/**`

**관련 변경 시나리오**: S1, S2

**독립 검증**: `DataLearningProjectTests`만 build-for-testing/test-without-building하여
PROJECT-01~11 11개 contract test와 nullable/배열 순서/`correct` 미생성/generation status
raw value 보존 테스트가 통과함을 확인한다.

### 준비

- [X] T022 [S1] `sources/Projects/Data/LearningProject/DataLearningProjectPlaceholder.swift`를
  삭제한다(구현으로 대체되어 더 이상 필요하지 않음).

### 테스트

- [X] T023 [P] [S1] `sources/Projects/Data/Tests/LearningProject/DTOs/APIResponseDTOTests.swift`에
  `APIResponseDTO<Payload>`의 `data` key 부재·`null` Unit 응답 decode 성공, `FieldErrorDTO`
  decode 테스트를 작성한다(FR-005).
- [X] T024 [P] [S2] `sources/Projects/Data/Tests/LearningProject/Errors/ServerAPIErrorTests.swift`에
  `ServerAPIError` decode 테스트를 작성한다.
- [X] T025 [P] [S1] `sources/Projects/Data/Tests/LearningProject/Endpoints/LearningProjectEndpointTests.swift`에
  PROJECT-01~11 각 operation의 method/path/query/body 조립과 Bearer 인증 헤더 적용
  테스트를 작성한다(FR-003, FR-004).
- [X] T026 [P] [S1] `sources/Projects/Data/Tests/LearningProject/Contracts/LearningProjectRemoteContractTests.swift`에
  PROJECT-01(프로젝트 등록)·PROJECT-02(프로젝트 목록)·PROJECT-03(프로젝트 상세)·
  PROJECT-04(프로젝트 삭제) contract test를 작성한다(spec.md 14절 항목 3~5).
- [X] T027 [P] [S1] `sources/Projects/Data/Tests/LearningProject/Contracts/LearningProjectGenerationContractTests.swift`에
  PROJECT-05(생성 상태 조회, 알려지지 않은 raw value 포함)·PROJECT-06(생성 재시도, 409
  `QUIZ-007`) contract test를 작성한다(spec.md 14절 항목 6~7, FR-011).
- [X] T028 [P] [S1] `sources/Projects/Data/Tests/LearningProject/Contracts/LearningProjectLearningSetContractTests.swift`에
  PROJECT-07(학습 세트) contract test를 작성하며, 객관식/서술형 질문과 `myAnswer` nil
  fixture를 모두 포함한다(spec.md 14절 항목 8~10).
- [X] T029 [P] [S1] `sources/Projects/Data/Tests/LearningProject/Contracts/LearningProjectAnswerContractTests.swift`에
  PROJECT-08(객관식 답변)·PROJECT-09(서술형 답변, 응답에 `correct` 없음 검증) contract
  test를 작성한다(spec.md 14절 항목 11~12, FR-010).
- [X] T030 [P] [S1] `sources/Projects/Data/Tests/LearningProject/Contracts/LearningProjectBookmarkContractTests.swift`에
  PROJECT-10(북마크 설정, toggle이 아닌 최종 상태 전달)·PROJECT-11(북마크 목록,
  `projectId`/`setId`/`questionId` 보존) contract test를 작성한다(spec.md 14절 항목
  13~14, FR-008).
- [X] T031 [P] [S1] `sources/Projects/Data/Tests/LearningProject/DTOs/ProjectListItemDTOTests.swift`에
  `repositoryImageUrl`/`nextSetId`/`nextQuestionId` nil fixture decoding 테스트를
  작성한다(FR-007, SC-004).
- [X] T032 [P] [S1] `sources/Projects/Data/Tests/LearningProject/DTOs/ArrayOrderPreservationTests.swift`에
  `ProjectDetailResponseDTO.sets`, `LearningSetResponseDTO.questions`,
  `QuestionResponseDTO.choices`가 서버 응답 배열 순서를 그대로 보존함을 검증하는 fixture
  테스트를 작성한다(FR-009 — 서버가 반환한 순서와 다르게 정렬된 fixture를 입력해 정렬되지
  않았음을 확인).
- [X] T033 [P] [S2] `sources/Projects/Data/Tests/LearningProject/Errors/DataLearningProjectErrorTests.swift`에
  `DataLearningProjectError.init(from:)` 매핑 함수의 대표 오류 매핑(404 `PROJECT-001`→
  `projectUnavailable`, 404 `QUIZ-005`→`questionUnavailable`, 404 `QUIZ-006`→
  `learningSetUnavailable`, 409 `QUIZ-007`→`generationRetryUnavailable`) fixture 테스트를
  작성한다.

### 구현

- [X] T034 [P] [S1] `sources/Projects/Data/LearningProject/DTOs/APIResponseDTO.swift`에
  `APIResponseDTO<Payload>`와 `FieldErrorDTO`를 구현한다(FR-005, research.md 결정 4 —
  Authentication과 동일한 형태를 이 target에 독립적으로 선언).
- [X] T035 [P] [S2] `sources/Projects/Data/LearningProject/Errors/ServerAPIError.swift`에
  `ServerAPIError`를 구현한다.
- [X] T036 [S1] `sources/Projects/Data/LearningProject/Endpoints/LearningProjectEndpoint.swift`에
  PROJECT-01~11의 method/path/query/body 조립과 Bearer 인증 헤더 적용 규칙을 구현한다
  (FR-003, FR-004).
- [X] T037 [S1] `sources/Projects/Data/LearningProject/Contracts/LearningProjectRemote.swift`에
  11개 메서드(`registerProject`, `fetchProjects`, `fetchProjectDetail`, `deleteProject`,
  `fetchGenerationStatus`, `retryQuizGeneration`, `fetchLearningSet`,
  `submitChoiceAnswer`, `submitEssayAnswer`, `setBookmark`, `fetchBookmarks`)를
  선언한다(contracts/learning-project-remote.md 근거).
- [X] T038 [P] [S1] `sources/Projects/Data/LearningProject/DTOs/RegisterProjectDTOs.swift`에
  `RegisterProjectRequestDTO`, `QuizLevelDTO`, `RegisterProjectResponseDTO`를 구현한다
  (PROJECT-01).
- [X] T039 [P] [S1] `sources/Projects/Data/LearningProject/DTOs/ProjectListDTOs.swift`에
  `ProjectListResponseDTO`, `ProjectListItemDTO`를 구현하며 `repositoryImageUrl`/
  `nextSetId`/`nextQuestionId`를 optional로 선언한다(PROJECT-02, FR-007).
- [X] T040 [P] [S1] `sources/Projects/Data/LearningProject/DTOs/ProjectDetailDTOs.swift`에
  `ProjectDetailResponseDTO`, `ProjectSetSummaryDTO`를 구현하며 `sets` 배열을 서버 응답
  순서 그대로 저장한다(PROJECT-03, FR-009).
- [X] T041 [P] [S1] `sources/Projects/Data/LearningProject/DTOs/QuizGenerationStatusResponseDTO.swift`에
  `status: String` raw value를 그대로 보존하는 응답 DTO를 구현한다(PROJECT-05, FR-011).
- [X] T042 [P] [S1] `sources/Projects/Data/LearningProject/DTOs/LearningSetDTOs.swift`에
  `LearningSetResponseDTO`, `QuestionResponseDTO`, `SourceResponseDTO`,
  `MyAnswerResponseDTO`(ISO-8601 `answeredAt: Date`)를 구현하며 `questions`/`choices`
  배열을 서버 응답 순서 그대로 저장한다(PROJECT-07, research.md 결정 5, FR-009).
- [X] T043 [P] [S1] `sources/Projects/Data/LearningProject/DTOs/AnswerDTOs.swift`에
  `SubmitChoiceAnswerRequestDTO`, `SubmitChoiceAnswerResponseDTO`,
  `SubmitEssayAnswerRequestDTO`, `SubmitEssayAnswerResponseDTO`, `RubricResponseDTO`를
  구현하며 `SubmitEssayAnswerResponseDTO`에 `correct` 필드를 추가하지 않는다(PROJECT-08,
  PROJECT-09, FR-010).
- [X] T044 [P] [S1] `sources/Projects/Data/LearningProject/DTOs/BookmarkDTOs.swift`에
  `BookmarkQuestionRequestDTO`(최종 `bookmarked` 상태), `BookmarkQuestionResponseDTO`,
  `BookmarkedQuestionListResponseDTO`, `AvailableProjectResponseDTO`,
  `BookmarkedQuestionResponseDTO`(`projectId`/`setId`/`questionId` 보존)를 구현한다
  (PROJECT-10, PROJECT-11, FR-008).
- [X] T045 [S2] `sources/Projects/Data/LearningProject/Errors/DataLearningProjectError.swift`에
  공통 6개 케이스(`invalidRequest`, `unauthorized`, `temporarilyUnavailable`, `transport`,
  `decoding`, `unexpectedStatus`) + 도메인 4개 케이스(`projectUnavailable`,
  `questionUnavailable`, `learningSetUnavailable`, `generationRetryUnavailable`)와
  `init(from serverError: ServerAPIError)` 매핑 함수를 구현한다(data-model.md
  `DataLearningProject target` 근거).

### 정리와 패키지 검증

- [X] T046 [no-write] `"$project_build_runner" compile`과
  `"$project_build_runner" test`를 `DataLearningProjectTests` 대상으로 실행해
  T023~T045를 검증한다.
- [X] T047 [no-write] 저장소 전체에서
  `grep -rn "googleLogin(\|GoogleLoginRequestDTO\|GoogleLoginEndpoint\|refreshSession\|revokeRefreshToken" sources/Projects/Data/LearningProject sources/Projects/Data/Tests/LearningProject`
  결과가 0건임을 확인한다.

**승인 게이트**: T022~T047의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가 다음
적용 대상 target(Member)을 명시적으로 승인하기 전에는 그 target 파일을 변경하지 않는다.

---

## 작업 패키지 3: Data — Member

**목표**: 참조 문서 MEMBER-01~06 6개 operation을 표현하는 `DataMember` target을 신규
생성한다(spec.md 가정 2). 공통 envelope·오류 매핑·Endpoint 계약을 이 target에도 독립적으로
구현한다.

**소유 경로**: `sources/Projects/Data/Member/**`, `sources/Projects/Data/Tests/Member/**`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`(Member 선언 추가),
`sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`(Member scheme 등록 추가)

**관련 변경 시나리오**: S1, S2

**독립 검증**: `DataMemberTests`만 build-for-testing/test-without-building하여 MEMBER-01~06
6개 contract test가 통과하고, `DataMember`/`DataMemberTests`가 Data scheme build/test
target에 포함됨을 확인한다(SC-007).

### 준비 — target 선언

- [X] T048 `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`에
  `DataMember`, `DataMemberTests` case와 `sourceDirectory`/`target` 분기를 추가한다
  (`DataAuthentication`/`DataLearningProject` 기존 선언은 변경하지 않는다).
- [X] T049 `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 `.Data` scheme
  `buildTargets`에 `DataModuleName.DataMember.rawValue`,
  `testTargets`에 `DataModuleName.DataMemberTests.rawValue`를 추가한다(기존
  Authentication/LearningProject 항목은 유지).

### 테스트

- [X] T050 [P] [S1] `sources/Projects/Data/Tests/Member/DTOs/APIResponseDTOTests.swift`에
  `APIResponseDTO<Payload>`의 `data` key 부재·`null` Unit 응답 decode 성공, `FieldErrorDTO`
  decode 테스트를 작성한다(FR-005).
- [X] T051 [P] [S2] `sources/Projects/Data/Tests/Member/Errors/ServerAPIErrorTests.swift`에
  `ServerAPIError` decode 테스트를 작성한다.
- [X] T052 [P] [S1] `sources/Projects/Data/Tests/Member/Endpoints/MemberEndpointTests.swift`에
  MEMBER-01~06 각 operation의 method/path/query/body 조립과 Bearer 인증 헤더 적용 테스트를
  작성한다(FR-003, FR-004).
- [X] T053 [P] [S1] `sources/Projects/Data/Tests/Member/Contracts/MemberRemoteContractTests.swift`에
  MEMBER-01(프로필)·MEMBER-06(회원 탈퇴) contract test를 작성한다(spec.md 14절 항목
  15, 20).
- [X] T054 [P] [S1] `sources/Projects/Data/Tests/Member/Contracts/MemberDeviceContractTests.swift`에
  MEMBER-02(기기 정보 등록, `deviceType == "ios"` 고정) contract test를 작성한다
  (spec.md 14절 항목 16).
- [X] T055 [P] [S1] `sources/Projects/Data/Tests/Member/Contracts/MemberPreferenceContractTests.swift`에
  MEMBER-03(큐레이션)·MEMBER-04(분야 변경)·MEMBER-05(수준 변경) contract test를
  작성한다(spec.md 14절 항목 17~19).
- [X] T056 [P] [S1] `sources/Projects/Data/Tests/Member/DTOs/MemberProfileResponseDTOTests.swift`에
  `weeklyChart` 배열 순서 보존 fixture 테스트를 작성한다(FR-009).
- [X] T057 [P] [S2] `sources/Projects/Data/Tests/Member/Errors/DataMemberErrorTests.swift`에
  `DataMemberError.init(from:)` 매핑 함수의 대표 오류 매핑(404 `MEMBER-001`→
  `memberUnavailable`) fixture 테스트를 작성한다.

### 구현

- [X] T058 [P] [S1] `sources/Projects/Data/Member/DTOs/APIResponseDTO.swift`에
  `APIResponseDTO<Payload>`와 `FieldErrorDTO`를 구현한다(FR-005).
- [X] T059 [P] [S2] `sources/Projects/Data/Member/Errors/ServerAPIError.swift`에
  `ServerAPIError`를 구현한다.
- [X] T060 [S1] `sources/Projects/Data/Member/Endpoints/MemberEndpoint.swift`에
  MEMBER-01~06의 method/path/query/body 조립과 Bearer 인증 헤더 적용 규칙을 구현한다
  (FR-003, FR-004).
- [X] T061 [S1] `sources/Projects/Data/Member/Contracts/MemberRemote.swift`에 6개
  메서드(`fetchProfile`, `registerDeviceInfo`, `curateMember`, `updatePosition`,
  `updateCareerLevel`, `withdrawMember`)를 선언한다(contracts/member-remote.md 근거).
- [X] T062 [P] [S1] `sources/Projects/Data/Member/DTOs/MemberProfileResponseDTO.swift`에
  `name`/`email`/`position`/`careerLevel`/`thisWeekSolvedCount`/`thisMonthSolvedCount`/
  `streakDays`/`weeklyChart: [WeeklyChartItemDTO]`를 구현하며 `weeklyChart`를 서버 응답
  순서 그대로 저장한다(MEMBER-01, FR-009).
- [X] T063 [P] [S1] `sources/Projects/Data/Member/DTOs/DeviceInfoRequestDTO.swift`에
  `deviceId`/`deviceType`/`appVersion`/`osVersion`/`deviceToken: String?`를 구현한다
  (MEMBER-02).
- [X] T064 [P] [S1] `sources/Projects/Data/Member/DTOs/PreferenceDTOs.swift`에
  `PositionDTO`, `CareerLevelDTO`, `CurationRequestDTO`, `PositionRequestDTO`,
  `CareerLevelRequestDTO`를 구현한다(MEMBER-03~05).
- [X] T065 [S2] `sources/Projects/Data/Member/Errors/DataMemberError.swift`에 공통 6개
  케이스 + `memberUnavailable`과 `init(from serverError: ServerAPIError)` 매핑 함수를
  구현한다(data-model.md `DataMember target` 근거).

### 정리와 패키지 검증

- [X] T066 [no-write] `"$project_build_runner" build`로 `DataMember` target이 Data
  scheme build에 포함됨을 확인한다.
- [X] T067 [no-write] `"$project_build_runner" compile`과
  `"$project_build_runner" test`를 `DataMemberTests` 대상으로 실행해 T050~T065를
  검증한다.

**승인 게이트**: T048~T067의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가 전체
완료 검증 진행을 명시적으로 승인하기 전에는 아래 작업을 실행하지 않는다.

---

## 전체 완료 검증

**선행 조건**: 작업 패키지 3(Member)의 구현·검증·결과 보고가 완료되어야 한다.

- [X] T068 [no-write] `"$project_build_runner" build`, `"$project_build_runner" compile`,
  `"$project_build_runner" test`를 전체 Data scheme 대상으로 순차 실행하고 결과를
  기록한다(SC-003, SC-007).
- [X] T069 [no-write] `AuthenticationRemote`(2) + `LearningProjectRemote`(11) +
  `MemberRemote`(6) = 19개 operation을 열거해 Auth 2/Project 11/Member 6 합계가 19임을
  확인한다(SC-001, quickstart.md 3절).
- [X] T070 [no-write] 저장소 전체에서
  `grep -rn "GoogleLoginRequestDTO\|googleLogin(\|GoogleLoginEndpoint" sources/Projects/Data`와
  `grep -rn "refreshSession\|revokeRefreshToken\|RefreshRequestDTO\|RefreshResponseDTO" sources/Projects/Data`
  결과가 각각 0건임을 확인한다(SC-002, SC-008).
- [X] T071 [no-write] `grep -rln "Mock\|Fixture" sources/Projects/Data/Authentication sources/Projects/Data/LearningProject sources/Projects/Data/Member`가
  `Tests/` 경로를 제외하고 결과 없음을 확인한다(FR-016).
- [X] T072 [no-write] spec.md 변경 시나리오 1~3의 수용 시나리오를 quickstart.md 절차에
  따라 재확인하고 결과를 보고한다.

## 의존성과 실행 순서

### 패키지 순서와 승인 게이트

- Authentication → LearningProject → Member 순으로 한 번에 한 target만 구현한다.
- 각 target의 모든 작업과 검증이 끝나야 다음 target 작업을 시작한다.
- 각 target 완료 후 변경 파일과 검증 결과를 보고하고 명시적 사용자 승인을 받은 뒤 다음
  target으로 진행한다.
- 승인 전 다음 target 영향 분석은 허용하지만 해당 target 파일 변경은 금지한다.

### 변경 시나리오 추적성

- S1(19개 operation 노출, 공통 envelope·Endpoint 계약 포함)은 T005, T007~T010, T013,
  T015~T018, T022~T032, T034, T036~T044, T050, T052~T056, T058, T060~T064가 구현하고
  T068·T069가 전체 검증한다.
- S2(오류 코드 구분 보존)는 T006, T011, T014, T019, T024, T033, T035, T045, T051, T057,
  T059, T065가 구현하고 T072가 재확인한다.
- S3(제품 범위 밖 API 제외)는 T001~T004, T012, T021, T047, T070이 구현·검증한다.

### 작업 패키지 내부 실행

- 테스트 작업(T005~T012, T023~T033, T050~T057)은 같은 target 구현 작업 전에 작성하고
  예상한 이유로 실패하는지 확인한 뒤 구현 작업을 진행한다.
- `[P]`는 승인된 현재 target 안의 서로 다른 파일에만 사용한다(예: T038~T044는 서로 다른
  DTO 파일이므로 병렬 가능하되, T036 `LearningProjectEndpoint.swift`와 T037
  `LearningProjectRemote.swift`가 참조하는 DTO 시그니처와 합의가 필요하면 T038~T044를
  먼저 완료한다).
- 다른 target의 작업은 병렬 실행하지 않는다.

## 구현 전략

1. Authentication target만 선택해 T001~T021을 모두 완료한다.
2. 변경 파일과 실제 검증 결과(T020, T021)를 보고하고 LearningProject 진행 승인을
   요청한 뒤 중단한다.
3. 승인 후 LearningProject target에서 T022~T047을 완료하고 결과를 보고한 뒤 Member 진행
   승인을 요청한다.
4. 승인 후 Member target에서 T048~T067을 완료하고 결과를 보고한 뒤 전체 완료 검증 진행
   승인을 요청한다.
5. 최종 승인 후 T068~T072 전체 읽기 전용 검증을 실행한다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다(T001~T072).
- 파일 변경 작업은 정확한 경로를 포함한다.
- 변경 시나리오의 독립성은 유지하되 구현·승인 단위는 target(Authentication/
  LearningProject/Member)이다.
- `APIResponseDTO`/`FieldErrorDTO`/`ServerAPIError`는 3개 target에 의도적으로 중복
  선언한다(research.md 결정 4). 같은 이름이 여러 target에 나타나는 것은 누락이 아니다.
- `docs/spec-kit/011-server-data-api/trouble-shooting.md`와
  `docs/spec-kit/011-server-data-api/tacit-knowledge.md`는 이 작업 목록의 대상이 아니다.
  조건이 발생한 세션에서 각 전용 Spec Kit 스킬이 별도로 기록한다.
