---

description: "기능 구현 작업 목록: UC01~UC20 전체 UseCase end-to-end 구현"
---

# 작업 목록: UC01~UC20 전체 UseCase end-to-end 구현

**입력**: `/specs/014-all-usecases-implementation/`의 설계 문서(`plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/usecase-catalog.md`, `quickstart.md`)

**선행 조건**: plan.md, spec.md, research.md, data-model.md, contracts/usecase-catalog.md 모두 존재

**테스트**: `spec.md` 16장(패키지별 테스트 요구사항)과 `research.md` C-TEST-001/002가 테스트를 명시적으로 요구하므로 각 패키지 단계에 테스트 작업을 포함한다. 테스트 함수 이름은 한국어 동작 문장, Swift Testing을 기본으로 사용한다(`docs/conventions/test.md`).

**구성**: 패키지를 최상위 구현·승인 단위로 사용하고 변경 시나리오(`spec.md`의 S1~S6)는 각 패키지 단계 안에서 `[S#]` 라벨로 추적한다. 순서는 [plan.md의 패키지 진행 순서](./plan.md#패키지-진행-순서)를 그대로 따른다: **Domain → Infrastructure → Data → Composition → UI → Feature → App**.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 승인된 현재 패키지 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[S#]**: `spec.md`의 시나리오 1~6(S1 Domain 계약, S2 Data Remote, S3 Composition graph, S4 Feature, S5 App, S6 CI/release gate)
- **[no-write]**: 추적 파일을 변경하지 않는 명령 실행 또는 수동 검증
- 파일 변경 작업은 정확한 저장소 상대 경로 하나와 정확히 하나의 책임 패키지를 가진다. 모든 소스 경로는 `sources/Projects/` 기준이다.

## 패키지 소유권 규칙

- 패키지 소스·테스트·패키지 전용 Tuist 설정은 해당 패키지 단계가 소유한다.
- `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`는 패키지별 `switch self` case 섹션으로 분리돼 있으므로, 이 파일을 여러 패키지가 수정해야 하면 각 패키지 단계에서 자신의 case 섹션만 변경하는 별도 작업으로 분리한다.
- 준비·기반·정리는 별도 단계를 만들지 않고 책임 패키지 단계에 포함한다.
- 전체 기능 검증은 마지막 패키지(App) 뒤에 `[no-write]`로만 둔다.

---

## 작업 패키지 1: Domain

**목표**: UC01~UC20 전체의 `Sendable` UseCase Protocol·concrete·모델·Repository 계약·오류를 완비하고, `GAP-014-001~009`(optional ID, registration receipt, idToken 오사용 등)를 교정한다.

**소유 경로**: `sources/Projects/Domain/**`, `sources/Tuist/ProjectDescriptionHelpers/Projects/DomainModuleName.swift`, `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 `.Domain` case

**관련 변경 시나리오**: S1

**독립 검증**: Domain target만 `build`·`compile`·`test`하여 Protocol/concrete 대응, 모델 불변식, optional/raw value 보존, 401·404 오류 구분을 검증한다(DTO·HTTP·TCA·SwiftUI import 0건).

### 준비와 기반

- [X] T001 `sources/Tuist/ProjectDescriptionHelpers/Projects/DomainModuleName.swift`에 `DomainMember`, `DomainMemberTests` case와 `sourceDirectory`/`target`(의존성 없음)을 추가한다
- [X] T002 `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 `.Domain` case에 `DomainModuleName.DomainMember`, `DomainModuleName.DomainMemberTests`를 `buildTargets`/`testTargets`에 추가한다

### Authentication 모델·오류·계약 교정 (UC11~UC14, RestoreSession, ObserveAuthenticationOutcomes)

- [X] T003 [S1] `sources/Projects/Domain/Authentication/Models/AuthenticatedUser.swift`에서 idToken을 사용자 ID로 저장하는 경로를 제거한다(GAP-014-007)
- [X] T004 [S1] `sources/Projects/Domain/Authentication/Models/SessionRecord.swift`를 새로 만들어 `tokens: SessionTokens`, `onboarding: LocalOnboardingState`를 정의한다(C-SESSION-001)
- [X] T005 [S1] `sources/Projects/Domain/Authentication/Models/SessionTokens.swift`를 새로 만들어 `accessToken`, `refreshToken`, `accessTokenExpiresAt`, `refreshTokenExpiresAt`을 정의한다(서버 미제공 시 임의 값 생성 금지)
- [X] T006 [S1] `sources/Projects/Domain/Authentication/Models/LocalOnboardingState.swift`를 새로 만들어 `needsCuration`, `acceptedLegalVersions`, `acceptedAt`을 정의한다(GAP-014-008)
- [X] T007 [S1] `sources/Projects/Domain/Authentication/Models/SessionRefreshOutcome.swift`를 새로 만들어 거부/temporary failure를 구분하는 outcome을 정의한다
- [X] T008 [S1] `sources/Projects/Domain/Authentication/Models/LegalDocument.swift`를 새로 만든다
- [X] T009 [S1] `sources/Projects/Domain/Authentication/Models/LegalAcceptanceRecord.swift`를 새로 만든다
- [X] T010 [S1] `sources/Projects/Domain/Authentication/Errors/AuthenticationError.swift`에 `authenticationCancelled`, `invalidAuthenticationCallback`, `temporarilyUnavailable` 케이스를 정합한다
- [X] T011 [S1] `sources/Projects/Domain/Authentication/Errors/LoginSessionError.swift`에 `unauthorized`, `sessionExpired`, `temporarilyUnavailable`을 구분하는 케이스를 정합한다(401을 unexpected로 축약 금지)
- [X] T012 [S1] `sources/Projects/Domain/Authentication/Contracts/LoginSessionRepository.swift`에 `needsCuration` 원자적 저장·조회, refresh token pair 원자적 교체, `SessionRecord` 기반 API를 추가한다(GAP-014-008, GAP-014-009)

### Authentication UseCase 신규 (UC12, UC13)

- [X] T013 [S1] `sources/Projects/Domain/Authentication/UseCases/Protocols/RefreshSessionUseCase.swift`를 새로 만든다(`callAsFunction() async throws -> SessionRefreshOutcome`)
- [X] T014 [S1] `sources/Projects/Domain/Authentication/UseCases/RefreshSession.swift`를 새로 만들어 single-flight 규칙을 반영한 구조를 구현한다. UC12는 서버 endpoint 미확보(`INT-API-001`)이므로 임의 request/response DTO를 만들지 않고 Repository 계약 호출까지만 구현한다
- [X] T015 [S1] `sources/Projects/Domain/Authentication/UseCases/Protocols/VerifyAccessTokenUseCase.swift`를 새로 만든다
- [X] T016 [S1] `sources/Projects/Domain/Authentication/UseCases/VerifyAccessToken.swift`를 새로 만들어 `GET /api/v1/auth/token` 결과를 검증하고 local onboarding state를 변경하지 않는다

### LearningProject 모델 교정 (GAP-014-001~006)

- [X] T017 [S1] `sources/Projects/Domain/LearningProject/Models/LearningProjectSummary.swift`의 `nextSetID`, `nextQuestionID`를 optional로 변경하고 빈 문자열 보정을 제거한다(GAP-014-001, GAP-014-002)
- [X] T018 [S1] `sources/Projects/Domain/LearningProject/Models/LearningProjectRegistration.swift`를 `ProjectRegistrationReceipt.swift`로 교체해 `projectID + raw requestStatus: String + QuizLevel`을 보존한다(GAP-014-003)
- [X] T019 [S1] `sources/Projects/Domain/LearningProject/Models/QuizGenerationStatus.swift`를 삭제해 서버에 없는 `analyzed`/`anchored` 상태를 제거한다(GAP-014-004)
- [X] T020 [S1] `sources/Projects/Domain/LearningProject/Models/LearningProjectDetail.swift`를 수정해 `nextQuestionID?`, ordered `sets`를 보존하고 detail set count 하드코딩을 제거한다(GAP-014-005)
- [X] T021 [S1] `sources/Projects/Domain/LearningProject/Models/LearningProjectSetProgress.swift`를 수정해 검증된 서버 필드를 매핑한다(GAP-014-005)
- [X] T022 [S1] `sources/Projects/Domain/LearningProject/Errors/LearningProjectError.swift`에 `learningSetUnavailable`, `questionUnavailable`을 `projectUnavailable`과 분리된 케이스로 추가한다(GAP-014-011)

### LearningProject 신규 모델 (UC06~UC10)

- [X] T023 [P] [S1] `sources/Projects/Domain/LearningProject/Models/LearningSet.swift`를 새로 만든다
- [X] T024 [P] [S1] `sources/Projects/Domain/LearningProject/Models/Question.swift`를 새로 만든다
- [X] T025 [P] [S1] `sources/Projects/Domain/LearningProject/Models/QuestionFormat.swift`를 새로 만든다
- [X] T026 [P] [S1] `sources/Projects/Domain/LearningProject/Models/QuestionSource.swift`를 새로 만든다
- [X] T027 [P] [S1] `sources/Projects/Domain/LearningProject/Models/ChoiceAnswerResult.swift`를 새로 만든다
- [X] T028 [P] [S1] `sources/Projects/Domain/LearningProject/Models/EssayAnswerResult.swift`를 새로 만든다
- [X] T029 [P] [S1] `sources/Projects/Domain/LearningProject/Models/Rubric.swift`를 새로 만든다
- [X] T030 [P] [S1] `sources/Projects/Domain/LearningProject/Models/BookmarkState.swift`를 새로 만든다
- [X] T031 [P] [S1] `sources/Projects/Domain/LearningProject/Models/BookmarkedQuestion.swift`를 새로 만든다
- [X] T032 [P] [S1] `sources/Projects/Domain/LearningProject/Models/BookmarkedQuestionCollection.swift`를 새로 만든다

### LearningProject Repository 계약 확장

- [X] T033 [S1] `sources/Projects/Domain/LearningProject/Contracts/LearningProjectRepository.swift`를 수정해 UC02~UC05 시그니처를 `ProjectRegistrationReceipt`·optional ID 기준으로 정합한다
- [X] T034 [P] [S1] `sources/Projects/Domain/LearningProject/Contracts/LearningSetRepository.swift`를 새로 만든다(UC06)
- [X] T035 [P] [S1] `sources/Projects/Domain/LearningProject/Contracts/AnswerRepository.swift`를 새로 만든다(UC07, UC08)
- [X] T036 [P] [S1] `sources/Projects/Domain/LearningProject/Contracts/BookmarkRepository.swift`를 새로 만든다(UC09, UC10)

### LearningProject UseCase 교정·신규

- [X] T037 [S1] `sources/Projects/Domain/LearningProject/UseCases/Protocols/CreateLearningProjectUseCase.swift`, `CreateLearningProject.swift`를 `ProjectRegistrationReceipt` 반환으로 수정한다(UC02)
- [X] T038 [S1] `sources/Projects/Domain/LearningProject/UseCases/Protocols/FetchLearningProjectsUseCase.swift`, `FetchLearningProjects.swift`를 pagination 상태 없는 snapshot 계약으로 수정한다(UC03)
- [X] T039 [S1] `sources/Projects/Domain/LearningProject/UseCases/Protocols/FetchLearningProjectDetailUseCase.swift`, `FetchLearningProjectDetail.swift`를 first-incomplete/replay fallback 규칙으로 수정한다(UC04)
- [X] T040 [P] [S1] `sources/Projects/Domain/LearningProject/UseCases/Protocols/FetchLearningSetUseCase.swift`를 새로 만든다(UC06)
- [X] T041 [S1] `sources/Projects/Domain/LearningProject/UseCases/FetchLearningSet.swift`를 새로 만든다(UC06, T040 의존)
- [X] T042 [P] [S1] `sources/Projects/Domain/LearningProject/UseCases/Protocols/SubmitChoiceAnswerUseCase.swift`를 새로 만든다(UC07)
- [X] T043 [S1] `sources/Projects/Domain/LearningProject/UseCases/SubmitChoiceAnswer.swift`를 새로 만든다(UC07, T042 의존)
- [X] T044 [P] [S1] `sources/Projects/Domain/LearningProject/UseCases/Protocols/SubmitEssayAnswerUseCase.swift`를 새로 만든다(UC08)
- [X] T045 [S1] `sources/Projects/Domain/LearningProject/UseCases/SubmitEssayAnswer.swift`를 새로 만든다(UC08, T044 의존)
- [X] T046 [P] [S1] `sources/Projects/Domain/LearningProject/UseCases/Protocols/SetQuestionBookmarkUseCase.swift`를 새로 만든다(UC09)
- [X] T047 [S1] `sources/Projects/Domain/LearningProject/UseCases/SetQuestionBookmark.swift`를 새로 만든다(UC09, T046 의존)
- [X] T048 [P] [S1] `sources/Projects/Domain/LearningProject/UseCases/Protocols/FetchBookmarkedQuestionsUseCase.swift`를 새로 만든다(UC10)
- [X] T049 [S1] `sources/Projects/Domain/LearningProject/UseCases/FetchBookmarkedQuestions.swift`를 새로 만든다(UC10, T048 의존)

### DomainMember 신규 target (UC15~UC20)

- [X] T050 [P] [S1] `sources/Projects/Domain/Member/Models/MemberProfile.swift`를 새로 만든다
- [X] T051 [P] [S1] `sources/Projects/Domain/Member/Models/MemberPosition.swift`를 새로 만든다
- [X] T052 [P] [S1] `sources/Projects/Domain/Member/Models/CareerLevel.swift`를 새로 만든다
- [X] T053 [P] [S1] `sources/Projects/Domain/Member/Models/LearningStatistics.swift`를 새로 만든다
- [X] T054 [P] [S1] `sources/Projects/Domain/Member/Models/WeeklyLearningCount.swift`를 새로 만든다
- [X] T055 [P] [S1] `sources/Projects/Domain/Member/Models/MemberDeviceInfo.swift`를 새로 만든다
- [X] T056 [S1] `sources/Projects/Domain/Member/Errors/MemberError.swift`를 새로 만들어 `memberUnavailable`/`temporarilyUnavailable`을 구분한다
- [X] T057 [S1] `sources/Projects/Domain/Member/Contracts/MemberRepository.swift`를 새로 만든다(UC15~UC20 전체 operation)
- [X] T058 [P] [S1] `sources/Projects/Domain/Member/UseCases/Protocols/CompleteCurationUseCase.swift`를 새로 만든다(UC15)
- [X] T059 [S1] `sources/Projects/Domain/Member/UseCases/CompleteCuration.swift`를 새로 만든다(UC15, T058 의존)
- [X] T060 [P] [S1] `sources/Projects/Domain/Member/UseCases/Protocols/FetchMemberProfileUseCase.swift`를 새로 만든다(UC16)
- [X] T061 [S1] `sources/Projects/Domain/Member/UseCases/FetchMemberProfile.swift`를 새로 만든다(UC16, T060 의존)
- [X] T062 [P] [S1] `sources/Projects/Domain/Member/UseCases/Protocols/UpdateMemberPositionUseCase.swift`를 새로 만든다(UC17)
- [X] T063 [S1] `sources/Projects/Domain/Member/UseCases/UpdateMemberPosition.swift`를 새로 만든다(UC17, T062 의존)
- [X] T064 [P] [S1] `sources/Projects/Domain/Member/UseCases/Protocols/UpdateMemberCareerLevelUseCase.swift`를 새로 만든다(UC18)
- [X] T065 [S1] `sources/Projects/Domain/Member/UseCases/UpdateMemberCareerLevel.swift`를 새로 만든다(UC18, T064 의존)
- [X] T066 [P] [S1] `sources/Projects/Domain/Member/UseCases/Protocols/RegisterMemberDeviceUseCase.swift`를 새로 만든다(UC19)
- [X] T067 [S1] `sources/Projects/Domain/Member/UseCases/RegisterMemberDevice.swift`를 새로 만든다(UC19, T066 의존)
- [X] T068 [P] [S1] `sources/Projects/Domain/Member/UseCases/Protocols/DeleteMemberAccountUseCase.swift`를 새로 만든다(UC20)
- [X] T069 [S1] `sources/Projects/Domain/Member/UseCases/DeleteMemberAccount.swift`를 새로 만든다(UC20, T068 의존)

### 테스트

- [X] T070 [P] [S1] `sources/Projects/Domain/Tests/Authentication/Models/SessionRecordTests.swift`에 `SessionRecord`/`SessionTokens`/`LocalOnboardingState` 불변식 테스트를 한국어 동작 문장으로 작성한다(T004~T006)
- [X] T071 [P] [S1] `sources/Projects/Domain/Tests/Authentication/UseCases/RefreshSessionTests.swift`에 single-flight 구조와 거부/temporary 분기 테스트를 작성한다(T014)
- [X] T072 [P] [S1] `sources/Projects/Domain/Tests/Authentication/UseCases/VerifyAccessTokenTests.swift`에 valid/401/transport, onboarding state 불변 테스트를 작성한다(T016)
- [X] T073 [P] [S1] `sources/Projects/Domain/Tests/LearningProject/Models/LearningProjectSummaryTests.swift`에 optional ID 보존 테스트를 작성한다(T017)
- [X] T074 [P] [S1] `sources/Projects/Domain/Tests/LearningProject/Models/ProjectRegistrationReceiptTests.swift`에 raw status 무손실 테스트를 작성한다(T018)
- [X] T075 [P] [S1] `sources/Projects/Domain/Tests/LearningProject/UseCases/FetchLearningSetTests.swift`에 UC06 검증(전 형식 매핑·서버 순서·3단계 resume·제출 전 비공개)을 작성한다(T041)
- [X] T076 [P] [S1] `sources/Projects/Domain/Tests/LearningProject/UseCases/SubmitChoiceAnswerTests.swift`에 UC07 검증(invalid index no-call·정확한 index·중복 제출 단일화)을 작성한다(T043)
- [X] T077 [P] [S1] `sources/Projects/Domain/Tests/LearningProject/UseCases/SubmitEssayAnswerTests.swift`에 UC08 검증(공백 제출 차단·2000자 경계·rubric 보존)을 작성한다(T045)
- [X] T078 [P] [S1] `sources/Projects/Domain/Tests/LearningProject/UseCases/SetQuestionBookmarkTests.swift`에 UC09 검증(desired bool 정확 전송·최종 응답 정본·직렬화)을 작성한다(T047)
- [X] T079 [P] [S1] `sources/Projects/Domain/Tests/LearningProject/UseCases/FetchBookmarkedQuestionsTests.swift`에 UC10 검증(availableProjects 불변·route ID 완전성)을 작성한다(T049)
- [X] T080 [P] [S1] `sources/Projects/Domain/Tests/Member/UseCases/CompleteCurationTests.swift`에 UC15 검증(정확한 요청 필드·성공 전 상태 불변)을 작성한다(T059)
- [X] T081 [P] [S1] `sources/Projects/Domain/Tests/Member/UseCases/FetchMemberProfileTests.swift`에 UC16 검증(전체 프로필 매핑·클라이언트 재계산 0건)을 작성한다(T061)
- [X] T082 [P] [S1] `sources/Projects/Domain/Tests/Member/UseCases/UpdateMemberPositionTests.swift`에 UC17 검증(position-only 요청·career 불변)을 작성한다(T063)
- [X] T083 [P] [S1] `sources/Projects/Domain/Tests/Member/UseCases/UpdateMemberCareerLevelTests.swift`에 UC18 검증(career-only 요청·position 불변)을 작성한다(T065)
- [X] T084 [P] [S1] `sources/Projects/Domain/Tests/Member/UseCases/RegisterMemberDeviceTests.swift`에 UC19 검증(필드 정확성·nil token 허용)을 작성한다(T067)
- [X] T085 [P] [S1] `sources/Projects/Domain/Tests/Member/UseCases/DeleteMemberAccountTests.swift`에 UC20 검증(confirmation 계약·정확히 1회 요청·committing lock)을 작성한다(T069)

### 정리와 패키지 검증

- [X] T086 [no-write] `sources` 디렉터리에서 `tuist generate`를 실행해 `DomainMember`/`DomainMemberTests` target을 workspace에 반영한다
- [X] T087 [no-write] Domain shared scheme으로 `build`·`compile`·`test`를 실행하고(`GIT_IT_PROJECT_BUILD_RUNNER`) 결과를 기록한다

**구현 중 확인된 편차**(계획 대비 실제):

- T003: `AuthenticatedUser.swift`에는 idToken 참조가 없어(grep 확인) 변경 대상이 없었다. GAP-014-007의 실제 위반 지점은 Composition의 `LoginSessionRepositoryAdapter`(T112)이므로 그 단계에서 처리한다.
- T010: `AuthenticationError`에는 이미 `.cancelled`/`.temporarilyUnavailable`이 있어 `invalidCallback` 케이스 1개만 추가했다(원래 이름 `invalidAuthenticationCallback` 대신 기존 네이밍 규칙에 맞춰 `invalidCallback`으로 명명).
- T011: `sessionExpired` 대신 기존 `.refreshRejectedOrExpired`가 그 의미를 이미 담당하고 있어 `.unauthorized` 케이스만 추가했다.
- T012, T013~T016: `LoginSessionRepository`에 `currentSession`/`replaceTokens`/`updateOnboarding`/`refresh`/`verifyAccessToken`을 추가했다. 기존 exhaustive switch(SignIn, RestoreSession, ObserveAuthenticationOutcomes 3개 파일)가 깨져 `.unauthorized` 분기를 추가해 수정했다(범위 내 필수 수정).
- T021: `LearningProjectSetProgress`는 이미 실제 값을 받는 생성자 구조였다. 하드코딩 제거는 Data 계층(T095)에서 처리한다.
- T069(UC20): committing lock은 Feature 계층 책임(기존 UC05 `DeleteLearningProject`도 Domain에 lock이 없음)이라 Domain에는 별도 lock을 두지 않았다.
- 기존 테스트 4개(`AuthenticationErrorTests`, `LoginSessionErrorTests`, `LearningProjectErrorTests`, `LearningProjectDetailTests`, `FetchLearningProjectDetailTests`)가 새 케이스·replay fallback 변경으로 깨져 함께 수정했다(같은 패키지 내 필수 회귀 수정).

**검증 결과**: `tuist generate` 성공(DomainMember/DomainMemberTests 인식 확인). `GIT_IT_PROJECT_BUILD_RUNNER`의 `build`/`test`는 scope=all(전체 workspace)만 지원해 이 시점(Composition 등 하위 패키지 미착수)에는 사용할 수 없어, `xcodebuild -workspace GitIt.xcworkspace -scheme Domain -destination 'platform=iOS Simulator,id=<default-1>' test`로 직접 검증했다. 결과: **BUILD SUCCEEDED / TEST SUCCEEDED**, 90개 테스트(DomainAuthenticationTests 32개, DomainLearningProjectTests 47개, DomainMemberTests 11개) 전부 통과.

**승인 게이트**: T001~T087의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가 Infrastructure 패키지를 명시적으로 승인하기 전에는 Infrastructure 파일을 변경하지 않는다.

---

## 작업 패키지 2: Infrastructure

**목표**: Data가 요구하는 범용 인증 header/transport/storage 기술 API를 완비한다. Git-It/GitHub 전용 의미는 추가하지 않는다.

**소유 경로**: `sources/Projects/Infrastructure/**`, `sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift`, `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 `.Infrastructure` case

**관련 변경 시나리오**: S2

**독립 검증**: Infrastructure target만 `build`·`test`하여 HTTP request/header 구성, Keychain atomic write/rollback, Apple callback 검증이 Git-It 의미 없이 통과하는지 확인한다.

### 구현

- [X] T088 [S2] `sources/Projects/Infrastructure/NetworkClient/Client/HTTPClient.swift`를 검토해 동적 `accessTokenProvider` 주입을 지원하는 request 실행 경로가 이미 충분한지 확인하고, 부족하면 매 요청 시점 헤더 병합 지점을 추가한다(C-DATA-002)

### 테스트

- [X] T089 [P] [S2] `sources/Projects/Infrastructure/Tests/NetworkClient/HTTPClientAuthorizationHeaderTests.swift`에 요청 직전 시점 헤더 병합 테스트를 작성한다(T088)

### 정리와 패키지 검증

- [X] T090 [no-write] Infrastructure shared scheme으로 `build`·`test`를 실행하고 결과를 기록한다

**구현 중 확인된 편차**(계획 대비 실제):

- T088: `HTTPClient.send`는 매 호출마다 `request.headers`를 `commonHeaders`에 병합해 전송하므로(`RequestCompositionTests`의 기존 "요청별 헤더가 표기와 무관하게 공통 헤더를 하나로 덮어쓴다" 테스트가 이를 증명) 이미 요청 시점 헤더 병합 지점이 존재한다. 동적 `accessTokenProvider`는 Data 계층의 Remote(T092)가 매 요청 직전 최신 token으로 `HTTPRequest.headers`를 구성해 전달하는 방식으로 충분하며, `HTTPClient` 자체에는 코드 변경이 필요하지 않았다.

**검증 결과**: `tuist generate` 성공. `xcodebuild -workspace GitIt.xcworkspace -scheme Infrastructure -destination 'platform=iOS Simulator,id=<default-1>' test` 실행 결과 **BUILD SUCCEEDED / TEST SUCCEEDED**, 37개 테스트(신규 `HTTPClientAuthorizationHeaderTests` 1개 포함) 전부 통과.

**승인 게이트**: T088~T090의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가 Data 패키지를 명시적으로 승인하기 전에는 Data 파일을 변경하지 않는다.

---

## 작업 패키지 3: Data

**목표**: UC01~UC20 전체 operation의 실행 가능한 concrete Remote를 완비하고, 보호 request에 매 요청 시점 Bearer header를 싣는다(GAP-014-010).

**소유 경로**: `sources/Projects/Data/**`, `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`, `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 `.Data` case(이미 DataMember 포함 — 변경 불필요 시 스킵)

**관련 변경 시나리오**: S2

**독립 검증**: Infrastructure stub transport를 주입해 request·header·body·response·오류를 검증한다.

### 준비와 기반

- [X] T091 [S2] `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`의 `.DataMember` case에 `.fromInfrastructure(.InfrastructureNetworkClient)` 의존성을 추가한다(NFR-014-003)

### 기존 Remote 교정 (UC01~UC05)

- [X] T092 [S2] `sources/Projects/Data/LearningProject/Remotes/HTTPProjectRemote.swift`에 `accessTokenProvider: @escaping @Sendable () async -> String?`를 받는 초기화와 매 요청 Bearer header 삽입을 추가한다(GAP-014-010)
- [X] T093 [S2] `sources/Projects/Data/LearningProject/DTOs/ProjectListDTOs.swift`의 optional ID(`nextSetID`, `nextQuestionID`)가 optional로 디코딩되는지 확인·수정한다
- [X] T094 [S2] `sources/Projects/Data/LearningProject/DTOs/RegisterProjectDTOs.swift`의 `requestStatus`를 String으로 디코딩하도록 수정한다(GAP-014-003)
- [X] T095 [S2] `sources/Projects/Data/LearningProject/DTOs/ProjectDetailDTOs.swift`의 set 진행률 필드를 서버 실제 필드와 재대조해 하드코딩 0을 제거한다(GAP-014-005)

### 신규 concrete Remote (UC06~UC10)

- [X] T096 [S2] `sources/Projects/Data/LearningProject/Remotes/HTTPLearningSetRemote.swift`를 새로 만들어 `LearningSetRemote`를 구현한다(UC06)
- [X] T097 [S2] `sources/Projects/Data/LearningProject/Remotes/HTTPAnswerRemote.swift`를 새로 만들어 `AnswerRemote`를 구현한다(UC07, UC08)
- [X] T098 [S2] `sources/Projects/Data/LearningProject/Remotes/HTTPBookmarkRemote.swift`를 새로 만들어 `BookmarkRemote`를 구현한다(UC09, UC10)
- [X] T099 [P] [S2] `sources/Projects/Data/LearningProject/DTOs/LearningSetDTOs.swift`를 검토해 question format/choices/rubric 공개 시점 필드를 확정한다
- [X] T100 [P] [S2] `sources/Projects/Data/LearningProject/DTOs/AnswerDTOs.swift`를 검토해 choice/essay 응답을 별도 DTO로 유지하는지 확정한다
- [X] T101 [P] [S2] `sources/Projects/Data/LearningProject/DTOs/BookmarkDTOs.swift`를 검토해 `setID` 필수 디코딩을 확정한다

### DataMember concrete Remote (UC15~UC20)

- [X] T102 [S2] `sources/Projects/Data/Member/Remotes/HTTPMemberRemote.swift`를 새로 만들어 `MemberRemote`를 구현한다(UC15~UC20 전체 operation, T091 의존)

### 테스트

- [X] T103 [P] [S2] `sources/Projects/Data/Tests/LearningProject/Remotes/HTTPLearningSetRemoteTests.swift`에 request/header/response/오류 매핑 테스트를 작성한다(T096)
- [X] T104 [P] [S2] `sources/Projects/Data/Tests/LearningProject/Remotes/HTTPAnswerRemoteTests.swift`에 request/header/response/오류 매핑 테스트를 작성한다(T097)
- [X] T105 [P] [S2] `sources/Projects/Data/Tests/LearningProject/Remotes/HTTPBookmarkRemoteTests.swift`에 request/header/response/오류 매핑 테스트를 작성한다(T098)
- [X] T106 [P] [S2] `sources/Projects/Data/Tests/LearningProject/Remotes/HTTPProjectRemoteAuthorizationTests.swift`에 매 요청 Bearer header 테스트를 작성한다(T092)
- [X] T107 [P] [S2] `sources/Projects/Data/Tests/Member/Remotes/HTTPMemberRemoteTests.swift`에 request/header/response/오류 매핑 테스트를 작성한다(T102)
- [X] T108 [P] [S2] `sources/Projects/Data/Tests/ExternalRepository/Remotes/HTTPExternalRepositoryRemoteNoAuthorizationTests.swift`에 GitHub 요청에 Git-It Bearer token이 없는지 확인하는 회귀 테스트를 작성한다(기존 Remote 검증)

### 정리와 패키지 검증

- [X] T109 [no-write] `tuist generate` 재실행 후 Data shared scheme으로 `build`·`compile`·`test`를 실행하고 결과를 기록한다

**구현 중 확인된 편차**(계획 대비 실제):

- T092: 네 concrete Remote(`HTTPProjectRemote`, `HTTPLearningSetRemote`, `HTTPAnswerRemote`, `HTTPBookmarkRemote`)가 요청 조립·오류 변환 로직을 동일하게 반복해야 해서, 공유 로직을 `LearningProjectHTTPExecutor`(non-public struct)로 추출했다. `HTTPProjectRemote`는 기존 private 헬퍼를 제거하고 이 executor를 사용하도록 재작성했다. `RegisterProjectResponseDTO.status`를 `requestStatus`로 rename하면서(T094) 기존 `HTTPProjectRemoteTests`, `LearningProjectRemoteProbe`의 참조도 함께 수정했다(같은 파일 범위 내 필수 회귀 수정).
- T093, T095, T099~T101: 검토 결과 기존 DTO(`ProjectListDTOs`의 optional ID, `ProjectDetailDTOs`의 실제 서버 필드 매핑, `LearningSetDTOs`/`AnswerDTOs`/`BookmarkDTOs`)가 이미 계획과 일치해 코드 변경이 필요하지 않았다.
- T102: `HTTPMemberRemote`는 `MemberEndpoint`가 이미 제공하는 `headers(accessToken:)`를 사용해 매 요청 시점 Bearer 헤더를 구성했다. `LearningProjectHTTPExecutor`와 별개로 자체 오류 변환 헬퍼를 두었다(Member DTO/오류 타입이 `DataLearningProject`가 아닌 `DataMember` 모듈 소속이라 executor를 공유할 수 없음).
- T107: `sources/Projects/Data/Tests/Member/TestDouble/StubHTTPTransport.swift`를 신규 작성했다(Member 테스트 target에 기존 stub transport가 없었음).
- 매크로 제약 확인: Swift Testing의 `#require` 매크로는 중첩 호출(`#require(... try #require(...) ...)`) 시 "recursive expansion" 컴파일 오류가 발생해, `HTTPAnswerRemoteTests`/`HTTPBookmarkRemoteTests`에서 body 추출을 두 단계로 분리했다.

**검증 결과**: `tuist generate` 성공. `xcodebuild -workspace GitIt.xcworkspace -scheme Data -destination 'platform=iOS Simulator,id=<default-1>' build test` 실행 결과 **BUILD SUCCEEDED / TEST SUCCEEDED**, DataLearningProjectTests 56개·DataMemberTests 24개·DataExternalRepositoryTests 13개(및 기존 DataAuthenticationTests) 전부 통과.

**승인 게이트**: T091~T109의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가 Composition 패키지를 명시적으로 승인하기 전에는 Composition 파일을 변경하지 않는다.

---

## 작업 패키지 4: Composition

**목표**: Domain↔Data Adapter와 Assembly를 완비해 UC01~UC20 중 외부 capability가 확보된 UseCase 전체를 `AppComposition`에서 Domain Protocol 타입으로 노출한다.

**소유 경로**: `sources/Projects/Composition/**`, `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`

**관련 변경 시나리오**: S3

**독립 검증**: in-memory Keychain/stub transport로 조립한 graph에서 protocol-typed public surface와 공유 세션/transport identity를 검증한다.

### 준비와 기반

- [X] T110 [S3] `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`의 `.CompositionAdapter` case에 `.fromDomain(.DomainMember)`, `.fromData(.DataMember)` 의존성을 추가한다(NFR-014-004)

### 기존 Adapter 교정

- [X] T111 [S3] `sources/Projects/Composition/Adapter/AuthenticationRepositoryAdapter.swift`를 수정해 `SessionRecord`/`needsCuration`/오류 정본 매핑을 반영한다
- [X] T112 [S3] `sources/Projects/Composition/Adapter/LoginSessionRepositoryAdapter.swift`를 수정해 idToken→ID 매핑을 제거하고(GAP-014-007) 원자적 token 교체를 구현한다
- [X] T113 [S3] `sources/Projects/Composition/Adapter/LearningProjectRepositoryAdapter.swift`를 수정해 optional ID·raw status·replay fallback을 손실 없이 매핑한다(GAP-014-001~006)

### 신규 Adapter

- [X] T114 [P] [S3] `sources/Projects/Composition/Adapter/LearningSetRepositoryAdapter.swift`를 새로 만든다(UC06)
- [X] T115 [P] [S3] `sources/Projects/Composition/Adapter/AnswerRepositoryAdapter.swift`를 새로 만든다(UC07, UC08)
- [X] T116 [P] [S3] `sources/Projects/Composition/Adapter/BookmarkRepositoryAdapter.swift`를 새로 만든다(UC09, UC10)
- [X] T117 [S3] `sources/Projects/Composition/Adapter/MemberRepositoryAdapter.swift`를 새로 만든다(UC15~UC20, T110 의존)
- [X] T118 [S3] `sources/Projects/Composition/Adapter/CurationRepositoryAdapter.swift`를 새로 만들어 UC15 원자적 완료 조정을 구현한다

### Assembly와 App composition root

- [X] T119 [S3] `sources/Projects/Composition/Adapter/LearningProjectAssembly.swift`를 수정해 UC02~UC10 UseCase 전체를 조립한다(T113~T116 의존)
- [X] T120 [S3] `sources/Projects/Composition/Adapter/AuthenticationAssembly.swift`를 수정해 UC11~UC14(UC12/UC14는 구조만), RestoreSession, ObserveAuthenticationOutcomes, single-flight refresh coordinator를 조립한다(T111, T112, T118 의존)
- [X] T121 [S3] `sources/Projects/Composition/Adapter/MemberAssembly.swift`를 새로 만들어 UC15~UC20을 조립한다(T117 의존)
- [X] T122 [S3] `sources/Projects/Composition/Adapter/AppComposition.swift`를 새로 만들어 공유 environment·session store·transport를 생성하고 `any XxxUseCase` typed bundle을 노출한다(T119~T121 의존, `CompositionAdapterPlaceholder.swift` 대체)

### 테스트

- [X] T123 [P] [S3] `sources/Projects/Composition/Tests/Adapter/LearningSetRepositoryAdapterTests.swift`에 DTO→Domain 매핑 테스트를 작성한다(T114)
- [X] T124 [P] [S3] `sources/Projects/Composition/Tests/Adapter/AnswerRepositoryAdapterTests.swift`에 DTO→Domain 매핑 테스트를 작성한다(T115)
- [X] T125 [P] [S3] `sources/Projects/Composition/Tests/Adapter/BookmarkRepositoryAdapterTests.swift`에 DTO→Domain 매핑 테스트를 작성한다(T116)
- [X] T126 [P] [S3] `sources/Projects/Composition/Tests/Adapter/MemberRepositoryAdapterTests.swift`에 DTO→Domain 매핑 테스트를 작성한다(T117)
- [X] T127 [S3] `sources/Projects/Composition/Tests/Adapter/AppCompositionSharedLifetimeTests.swift`에 여러 보호 Remote가 동일 session/transport identity를 공유하는 테스트를 작성한다(T122)
- [X] T128 [S3] `sources/Projects/Composition/Tests/Adapter/AppCompositionPublicSurfaceTests.swift`에 모든 public property가 `any XxxUseCase` 타입인지 검증하는 테스트를 작성한다(T122)
- [X] T129 [S3] `sources/Projects/Composition/Tests/Adapter/RefreshSessionReleaseBlockerTests.swift`에 UC12/UC14의 서버 capability 부재가 release blocker로 명시되는지 검증하는 테스트를 작성한다(T120)

### 정리와 패키지 검증

- [X] T130 [no-write] `tuist generate` 재실행 후 Composition shared scheme으로 `build`·`compile`·`test`를 실행하고 결과를 기록한다

**구현 중 확인된 편차**(계획 대비 실제):

- T112: `SessionRecord`를 단일 key JSON blob으로 원자적 저장하는 `SessionRecordKeychainCoding.swift`를 새로 만들었다(GAP-014-008, GAP-014-009 — token pair·onboarding state를 분리된 key로 나누면 부분 갱신 상태가 생길 수 있음). `SessionKeychainLayout`을 3-key(`accessToken`/`refreshToken`/`userID`) 구조에서 1-key(`sessionRecord`) 구조로 교체했다.
- T112(GAP-014-007): `AuthenticatedUser.id`를 idToken(JWT) 대신 `AuthenticationRepositoryAdapter`가 이미 저장하던 Apple 안정 사용자 식별자로 바꿨다. 두 Adapter가 이 값을 공유하도록 `AppleIdentityKeychainLayout.swift`를 새로 만들고 `AuthenticationRepositoryAdapter`의 기존 private 상수를 이 공유 레이아웃으로 교체했다(범위 내 필수 수정).
- T112: `refresh()`는 UC12 서버 endpoint 미확보(`INT-API-001`)로 항상 `LoginSessionError.temporarilyUnavailable`을 던지도록 구현했다(임의 성공 금지, T129로 검증).
- T113~T117: `LearningSetRepositoryAdapter`/`AnswerRepositoryAdapter`/`BookmarkRepositoryAdapter`/`MemberRepositoryAdapter`가 각각 매핑하는 Domain 모델과 기존(Domain·Data 패키지 모두 승인 완료) DTO 사이에 서버 OpenAPI 미확정으로 인한 1:1 대응 gap이 있었다. 사용자 승인(추정 매핑) 하에 다음과 같이 처리했다: (1) `MemberProfile.statistics`(totalAnsweredCount/totalCorrectCount) ← `MemberProfileResponseDTO`(thisWeekSolvedCount/thisMonthSolvedCount/streakDays) — `totalAnsweredCount`는 `thisMonthSolvedCount`로 추정 매핑하고 `totalCorrectCount`는 서버가 정답 수를 내려주지 않아 0으로 둔다(재계산 아님), `streakDays`는 대응 필드가 없어 보존하지 않는다. (2) `EssayAnswerResult.rubric.criteria` ← `RubricResponseDTO.feedback`만 담고 `score`는 대응 필드가 없어 버린다. (3) `BookmarkedQuestion.prompt` ← `BookmarkedQuestionResponseDTO`에 prompt 필드가 없어 빈 문자열로 둔다. (4) `LearningProjectSetProgress.problemCount`/`completedCount` ← `ProjectSetSummaryDTO`에 대응 필드가 없어 기존과 동일하게 0으로 유지한다(GAP-014-005는 optional ID·replay fallback 부분만 해결, 진행률 카운트는 Data DTO 확장이 필요해 미해결로 남긴다). 실제 서버 계약이 확정되면 이 매핑들을 갱신해야 한다.
- T119~T122: `LearningProjectAssembly`/`MemberAssembly`/`AuthenticationAssembly`가 각각 자체 `HTTPClient`를 만들던 기존 구조 대신, `HTTPClientFactory.swift`(`makeHTTPClient`)로 통일하고 모든 Assembly에 `transport: (any HTTPTransport)? = nil` 파라미터를 추가했다. `AppComposition.live`가 하나의 `KeychainStore`·`accessTokenProvider`·(테스트용) `transport`를 세 Assembly에 공유 주입해 세션 정본을 일원화한다. `AuthenticationAssembly`는 `loginSessionRepository`를 `internal`(non-public) 프로퍼티로 노출해 `MemberAssembly`의 `CurationRepositoryAdapter`가 재사용하도록 했다(public API 표면은 `any XxxUseCase`만 유지, T128로 검증).
- T120: `AuthenticationAssembly`가 `CompleteCurationUseCase`(UC15)도 함께 노출한다 — UC15는 U01(온보딩) Feature가 소비하므로 `plan.md`/`tasks.md` 원안대로 Authentication 조립 단계에 포함했다. 이를 위해 `AuthenticationAssembly`가 자체 `HTTPMemberRemote`/`MemberRepositoryAdapter`/`CurationRepositoryAdapter`를 내부적으로 하나 더 구성한다(같은 baseURL, `MemberAssembly`와는 별개 인스턴스).
- T122: `CompositionAdapterPlaceholder.swift`와 그 테스트(`CompositionAdapterCompilationTests.swift`)를 삭제했다.
- 기존 테스트 3개(`AuthenticationAssemblyTests`, `LearningProjectAssemblyTests`)가 API 시그니처 변경(accessTokenProvider 추가, `RegisterProjectResponseDTO.requestStatus` rename, Apple 식별자 기반 `AuthenticatedUser.id`)으로 깨져 함께 수정했다(같은 패키지 내 필수 회귀 수정).

**검증 결과**: `tuist generate` 성공. `xcodebuild -workspace GitIt.xcworkspace -scheme Composition -destination 'platform=iOS Simulator,id=<default-1>' build test` 실행 결과 **BUILD SUCCEEDED / TEST SUCCEEDED**, 15개 Suite 29개 테스트 전부 통과.

**승인 게이트**: T110~T130의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가 UI 패키지를 명시적으로 승인하기 전에는 UI 파일을 변경하지 않는다.

---

## 작업 패키지 5: UI

**목표**: U02·U06·U07·U08에 필요한 누락 component를 ViewModel 없이 구현하고, `UIComponentLayoutHarness`를 `UIComponentPreviewApp`으로 교정한다.

**소유 경로**: `sources/Projects/UI/**`, `sources/Tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift`, `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 `.UI` case

**관련 변경 시나리오**: S4(선행 준비, U01~U08 자체 구현은 Feature 단계)

**독립 검증**: `UIComponentPreviewApp`에서 신규 component가 scalar/value·Binding·callback만으로 렌더링되는지 카탈로그로 확인한다.

### Preview app 명칭 교정

- [X] T131 [S4] `sources/Projects/UI/ComponentLayoutHarness/` 디렉터리를 `sources/Projects/UI/ComponentPreviewApp/`로 이동한다(파일: `LayoutContractCatalog.swift`, `UIComponentLayoutHarnessApp.swift`→`UIComponentPreviewAppApp.swift`)
- [X] T132 [S4] `sources/Tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift`의 `UIComponentLayoutHarness`/`UIComponentUITests` case를 `UIComponentPreviewApp`/`UIComponentPreviewAppUITests`로 rename하고 `sourceDirectory`를 T131 경로로 갱신한다(NFR-014-008)
- [X] T133 [S4] `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 `.UI` case에서 `buildTargets`/`testTargets`의 harness 이름을 갱신한다

### 신규 component

- [X] T134 [P] [S4] `sources/Projects/UI/Component/Components/Leaf/TextField.swift`를 새로 만들어 Default/Active/Filled/Error 상태를 scalar/Binding/callback으로 표현한다(U02)
- [X] T135 [P] [S4] `sources/Projects/UI/Component/Components/Composite/SettingRow.swift`를 새로 만든다(U06)
- [X] T136 [P] [S4] `sources/Projects/UI/Component/Components/Composite/SelectableSettingRow.swift`를 새로 만든다(U06)
- [X] T137 [P] [S4] `sources/Projects/UI/Component/Components/Composite/AccountActionRow.swift`를 새로 만든다(U06)
- [X] T138 [P] [S4] `sources/Projects/UI/Component/Components/Composite/LearningSetRow.swift`를 새로 만들어 320×130pt 의미 계약을 구현한다(U07)
- [X] T139 [P] [S4] `sources/Projects/UI/Component/Components/Composite/QuestionPrompt.swift`를 새로 만든다(U08)
- [X] T140 [P] [S4] `sources/Projects/UI/Component/Components/Leaf/ChoiceAnswerOption.swift`를 새로 만들어 correct/incorrect를 token+텍스트/아이콘/접근성으로 표현한다(U08)
- [X] T141 [P] [S4] `sources/Projects/UI/Component/Components/Composite/EssayAnswerInput.swift`를 새로 만든다(U08)
- [X] T142 [P] [S4] `sources/Projects/UI/Component/Components/Composite/RubricView.swift`를 새로 만든다(U08)
- [X] T143 [P] [S4] `sources/Projects/UI/Component/Components/Leaf/LabeledProgressBar.swift`를 새로 만든다(U08)
- [X] T144 [S4] `sources/Projects/UI/ComponentPreviewApp/LayoutContractCatalog.swift`에 T134~T143 component를 카탈로그 항목으로 등록한다

### 테스트

- [X] T145 [P] [S4] `sources/Projects/UI/Tests/Component/Unit/TextFieldTests.swift`에 상태별 렌더링·콜백 테스트를 작성한다(T134)
- [X] T146 [P] [S4] `sources/Projects/UI/Tests/Component/Unit/LearningSetRowTests.swift`에 크기·Dynamic Type 테스트를 작성한다(T138)
- [X] T147 [P] [S4] `sources/Projects/UI/Tests/Component/Unit/ChoiceAnswerOptionTests.swift`에 correct/incorrect 접근성 semantics 테스트를 작성한다(T140)
- [X] T148 [S4] `sources/Projects/UI/Tests/Component/UI/UIComponentPreviewAppLaunchTests.swift`(구 `UIComponentUITests`)를 rename·수정해 새 target 이름으로 카탈로그 도달성을 검증한다(T131, T132)

### 정리와 패키지 검증

- [X] T149 [no-write] `tuist generate` 재실행 후 UI shared scheme으로 `build`·`compile`·`test`를 실행하고 결과를 기록한다

**구현 중 확인된 편차**(계획 대비 실제):

- T131~T148: 이번 세션 시작 시점에 이미 이전 세션에서 구현이 완료되어 있었다(커밋 `2995d4b`). 이번 세션에서는 `EssayAnswerInput`의 `TextEditor`가 외부 `ScrollView` 안에서 높이가 무제한으로 확장되는 문제를 발견해 `.scrollDisabled(true)`와 `maxHeight` 상한(240pt)을 추가했고, `LayoutContractCatalog`의 `learningSetRowContracts`가 두 `LearningSetRow`(각 320pt, 합 652pt)를 화면 폭(402pt)보다 넓은 일반 `HStack`에 배치해 `ScrollView`가 전체 콘텐츠를 중앙 정렬·클리핑하던 실제 레이아웃 결함을 시뮬레이터로 재현·이진 탐색해 원인을 확정하고, 해당 섹션을 가로 `ScrollView`로 감싸 수정했다(범위 내 필수 수정, T144 소유 파일).

**검증 결과**: `tuist install`·`tuist generate` 성공. `xcodebuild -workspace GitIt.xcworkspace -scheme UI -destination 'platform=iOS Simulator,id=<default-1>' build test` 실행 결과 **BUILD SUCCEEDED / TEST SUCCEEDED**, 8개 Suite 31개 테스트(신규 `ChoiceAnswerOption 계약`·`LearningSetRow 계약`·`TextField 계약` 포함) 전부 통과. 시뮬레이터에 `UIComponentPreviewApp`을 직접 설치·실행해 `LayoutContractCatalog` 전체(제목부터 `questionContracts`/`EssayAnswerInput`까지)가 화면 폭 안에서 정상 렌더링되는지 스크린샷으로 확인했다.

**승인 게이트**: T131~T149의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가 Feature 패키지를 명시적으로 승인하기 전에는 Feature 파일을 변경하지 않는다.

---

## 작업 패키지 6: Feature

**목표**: U01~U08 reducer/view를 구현해 UseCase Protocol만 initializer로 소비하고, 401 delegate·중복 방지·late response 무시를 반영한다.

**소유 경로**: `sources/Projects/Feature/**`, `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`, `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 `.Feature` case

**관련 변경 시나리오**: S4

**독립 검증**: FeatureTests의 local Test Double과 TCA `TestStore`만으로 각 reducer의 상태·오류·delegate·취소·중복 방지를 검증한다.

### 준비와 기반

- [ ] T150 [S4] `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`의 `.Feature` case에 `.fromDomain(.DomainAuthentication)`, `.fromDomain(.DomainMember)` 의존성을 추가한다(NFR-014-005)
- [ ] T151 [S4] `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`에 `FeatureTests` case를 추가하고 `productionTarget: Feature`로 연결한다(NFR-014-002)
- [ ] T152 [S4] `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 `.Feature` case에 `FeatureModuleName.FeatureTests`를 `testTargets`에 추가한다
- [ ] T153 [S4] `sources/Projects/Feature/Presentation/FeaturePlaceholder.swift`를 삭제한다

### U01 — Onboarding/Authentication

- [ ] T154 [S4] `sources/Projects/Feature/Presentation/Onboarding/OnboardingFeature.swift`를 새로 만들어 `authentication`/`onboarding` 상태 머신과 UC11~UC15, RestoreSession, legal UseCase를 initializer로 주입받는다
- [ ] T155 [S4] `sources/Projects/Feature/Presentation/Onboarding/OnboardingView.swift`를 새로 만든다(T154 의존)
- [ ] T156 [P] [S4] `sources/Projects/Feature/Tests/Onboarding/Mocks/OnboardingUseCaseDoubles.swift`에 local Test Double을 작성한다
- [ ] T157 [S4] `sources/Projects/Feature/Tests/Onboarding/OnboardingFeatureTests.swift`에 TCA `TestStore` 기반 성공/취소/401/온보딩 전이 테스트를 작성한다(T154, T156)

### U02 — Repository/Registration

- [ ] T158 [S4] `sources/Projects/Feature/Presentation/ProjectRegistration/ProjectRegistrationFeature.swift`를 새로 만들어 UC01, UC02를 주입받고 generation polling 상태를 만들지 않는다
- [ ] T159 [S4] `sources/Projects/Feature/Presentation/ProjectRegistration/ProjectRegistrationView.swift`를 새로 만든다(T158 의존)
- [ ] T160 [P] [S4] `sources/Projects/Feature/Tests/ProjectRegistration/Mocks/ProjectRegistrationUseCaseDoubles.swift`에 local Test Double을 작성한다
- [ ] T161 [S4] `sources/Projects/Feature/Tests/ProjectRegistration/ProjectRegistrationFeatureTests.swift`에 quizLevel 포함·중복 제출 단일화 테스트를 작성한다(T158, T160)

### U03 — MainShell/Home

- [ ] T162 [S4] `sources/Projects/Feature/Presentation/MainShell/MainShellFeature.swift`를 새로 만들어 UC03, UC13(또는 Root 전달 세션 상태)을 주입받고 `selectedTab`과 탭별 child state를 소유한다
- [ ] T163 [S4] `sources/Projects/Feature/Presentation/MainShell/MainShellView.swift`를 새로 만든다(T162 의존, `TabShell(selected:onSelect:)` 사용)
- [ ] T164 [P] [S4] `sources/Projects/Feature/Tests/MainShell/Mocks/MainShellUseCaseDoubles.swift`에 local Test Double을 작성한다
- [ ] T165 [S4] `sources/Projects/Feature/Tests/MainShell/MainShellFeatureTests.swift`에 탭 전환·logout 시 child state 폐기 테스트를 작성한다(T162, T164)

### U04 — Project List

- [ ] T166 [S4] `sources/Projects/Feature/Presentation/ProjectList/ProjectListFeature.swift`를 새로 만들어 UC03, UC05를 주입받고 full snapshot·삭제 committing lock을 소유한다
- [ ] T167 [S4] `sources/Projects/Feature/Presentation/ProjectList/ProjectListView.swift`를 새로 만든다(T166 의존)
- [ ] T168 [P] [S4] `sources/Projects/Feature/Tests/ProjectList/Mocks/ProjectListUseCaseDoubles.swift`에 local Test Double을 작성한다
- [ ] T169 [S4] `sources/Projects/Feature/Tests/ProjectList/ProjectListFeatureTests.swift`에 confirm 1회·404 reconciliation·late refresh 무시 테스트를 작성한다(T166, T168)

### U05 — Saved

- [ ] T170 [S4] `sources/Projects/Feature/Presentation/Saved/SavedFeature.swift`를 새로 만들어 UC10을 주입받고 filter request identity와 route ID를 소유한다
- [ ] T171 [S4] `sources/Projects/Feature/Presentation/Saved/SavedView.swift`를 새로 만든다(T170 의존, 직접 unbookmark control 없음)
- [ ] T172 [P] [S4] `sources/Projects/Feature/Tests/Saved/Mocks/SavedUseCaseDoubles.swift`에 local Test Double을 작성한다
- [ ] T173 [S4] `sources/Projects/Feature/Tests/Saved/SavedFeatureTests.swift`에 availableProjects 불변·stale filter response 무시 테스트를 작성한다(T170, T172)

### U06 — My/Settings

- [ ] T174 [S4] `sources/Projects/Feature/Presentation/Settings/SettingsFeature.swift`를 새로 만들어 UC14, UC16~UC20을 주입받고 profile load와 position/career/device/account action 상태를 분리한다
- [ ] T175 [S4] `sources/Projects/Feature/Presentation/Settings/SettingsView.swift`를 새로 만든다(T174 의존)
- [ ] T176 [P] [S4] `sources/Projects/Feature/Tests/Settings/Mocks/SettingsUseCaseDoubles.swift`에 local Test Double을 작성한다
- [ ] T177 [S4] `sources/Projects/Feature/Tests/Settings/SettingsFeatureTests.swift`에 position/career mutation 격리·계정 삭제 committing lock 테스트를 작성한다(T174, T176)

### U07 — Project Detail

- [ ] T178 [S4] `sources/Projects/Feature/Presentation/ProjectDetail/ProjectDetailFeature.swift`를 새로 만들어 UC04를 주입받고 target set selection, empty sets copy, U08 route reason을 소유한다
- [ ] T179 [S4] `sources/Projects/Feature/Presentation/ProjectDetail/ProjectDetailView.swift`를 새로 만든다(T178 의존)
- [ ] T180 [P] [S4] `sources/Projects/Feature/Tests/ProjectDetail/Mocks/ProjectDetailUseCaseDoubles.swift`에 local Test Double을 작성한다
- [ ] T181 [S4] `sources/Projects/Feature/Tests/ProjectDetail/ProjectDetailFeatureTests.swift`에 first-incomplete/replay/empty fallback 테스트를 작성한다(T178, T180)

### U08 — Quiz

- [ ] T182 [S4] `sources/Projects/Feature/Presentation/Quiz/QuizFeature.swift`를 새로 만들어 UC06~UC10을 주입받고 set load·bookmark load를 독립 effect로 실행하며 같은 question mutation을 직렬화한다(DEC-024 progress invalidation 포함)
- [ ] T183 [S4] `sources/Projects/Feature/Presentation/Quiz/QuizView.swift`를 새로 만든다(T182 의존)
- [ ] T184 [P] [S4] `sources/Projects/Feature/Tests/Quiz/Mocks/QuizUseCaseDoubles.swift`에 local Test Double을 작성한다
- [ ] T185 [S4] `sources/Projects/Feature/Tests/Quiz/QuizFeatureTests.swift`에 resume 3단계·정답 제출 전 비공개·bookmark 직렬화·DEC-024 invalidation 테스트를 작성한다(T182, T184)

### 정리와 패키지 검증

- [ ] T186 [no-write] `tuist generate` 재실행 후 Feature shared scheme으로 `build`·`compile`·`test`를 실행하고 결과를 기록한다

**승인 게이트**: T150~T186의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가 App 패키지를 명시적으로 승인하기 전에는 App 파일을 변경하지 않는다.

---

## 작업 패키지 7: App

**목표**: Composition root를 1회 생성하고 session restore → U01/U03 분기, U01~U08 route, MainShell 탭 수명, logout purge를 연결한다. `Hello, world!` stub을 제거한다.

**소유 경로**: `sources/Projects/App/**`, `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`, `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 `.App` case

**관련 변경 시나리오**: S5

**독립 검증**: App test에서 fake composition을 주입해 launch/root/route 도달성을 검증한다.

### 준비와 기반

- [ ] T187 [S5] `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`의 `.GitIt` case `dependencies`에 `.fromDomain(.DomainLearningProject)`, `.fromDomain(.DomainMember)`를 추가한다(NFR-014-006)
- [ ] T188 [S5] `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 `.App` case에서 `AppTests` scheme의 host dependency를 확인·보강해 `GitItTests`가 App root를 검증할 수 있게 한다(NFR-014-007)

### Root 구현

- [ ] T189 [S5] `sources/Projects/App/Sources/ContentView.swift`를 삭제한다(`Hello, world!` stub 제거)
- [ ] T190 [S5] `sources/Projects/App/Sources/RootFeature.swift`를 새로 만들어 `restoring`/`onboarding(U01)`/`mainShell(U03)` 상태와 UC13/RestoreSession 기반 분기를 구현한다
- [ ] T191 [S5] `sources/Projects/App/Sources/RootView.swift`를 새로 만든다(T190 의존)
- [ ] T192 [S5] `sources/Projects/App/Sources/GitItApp.swift`를 수정해 `AppComposition.live(environment)`를 1회 생성하고 `RootFeature`/`RootView`로 진입점을 교체한다(T190, Composition T122 의존)
- [ ] T193 [S5] `sources/Projects/App/Sources/Navigation/AppRoute.swift`를 새로 만들어 U01→U02/U03, U02→U03, U03/U04→U07, U03/U04→U08, U05→U08, U07→U08, unauthorized→Root, logout→U01 payload를 정의한다
- [ ] T194 [S5] `sources/Projects/App/Sources/Lifecycle/DeviceRegistrationCoordinator.swift`를 새로 만들어 UC19를 login 완료·APNs token 변경·app/OS 버전 변경 시점에 호출한다

### 테스트

- [ ] T195 [P] [S5] `sources/Projects/App/Tests/GitIt/RootFeatureTests.swift`에 무세션→U01, 유효세션+온보딩완료→U03, 유효세션+온보딩미완료→U01 잔여, verify 401+refresh outcome 테스트를 작성한다(T190)
- [ ] T196 [P] [S5] `sources/Projects/App/Tests/GitIt/AppRouteReachabilityTests.swift`에 U01~U08 route payload 손실 없음 테스트를 작성한다(T193)
- [ ] T197 [S5] `sources/Projects/App/Tests/GitIt/LogoutPurgeTests.swift`에 logout/withdrawal 시 보호 탭 state와 child effect 폐기 테스트를 작성한다(T190)
- [ ] T198 [S5] `sources/Projects/App/Tests/GitIt/GitItCompilationTests.swift`를 수정해 `Hello, world!`/preview-only root/sample store 참조가 없음을 검증한다(T189)

### 정리와 패키지 검증

- [ ] T199 [no-write] `tuist generate` 재실행 후 App shared scheme으로 `build`·`compile`·`test`를 실행하고 결과를 기록한다
- [ ] T200 [no-write] [S5] Simulator(`iPhone 17 Pro`)에서 앱을 실행해 [quickstart.md](./quickstart.md) 7단계 수동 확인(세션 분기, U01 완료 후 이동, 탭 전환/logout, route payload)을 수행한다

**승인 게이트**: T187~T200의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 마지막 패키지이므로 승인 후 전체 완료 검증으로 진행한다.

---

## 전체 완료 검증

**선행 조건**: App 패키지(작업 패키지 7)의 구현·검증·결과 보고가 완료되어야 한다.

- [ ] T201 [no-write] 전체 build·compile·test(`"$project_build_runner" build/compile/test`)를 실행하고 결과를 기록한다
- [ ] T202 [no-write] [S6] CI 워크플로 실행 결과에서 `GIT_IT_CI_VALIDATION_ENABLED` global flag로 인해 lint/build/unit/App/UI required job이 skip되지 않았는지 확인한다
- [ ] T203 [no-write] [S1] [S2] [S3] `spec.md`의 성공 기준 SC-014-001~015를 항목별로 재확인하고 UC12/UC14를 "구조 완료 / production 차단"으로 구분 표시한다
- [ ] T204 [no-write] [S4] [S5] `spec.md` 시나리오 4·5의 수용 시나리오(Feature dependency 0건, App route 도달성, Hello World 0건)를 재확인한다
- [ ] T205 [no-write] 변경 셸 스크립트가 있으면 `./tools/script-tests/bin/run.sh`와 `./tools/script-verification/bin/run.sh`를 실행하고 결과를 기록한다

---

## 의존성과 실행 순서

### 패키지 순서와 승인 게이트

Domain → Infrastructure → Data → Composition → UI → Feature → App. 근거는 [plan.md 패키지 진행 순서](./plan.md#패키지-진행-순서) 표와 동일하다: Domain·Infrastructure·UI는 서로 독립(피의존)이지만 downstream 계약을 먼저 고정하기 위해 Domain을 최우선으로 두고, Data가 즉시 필요로 하는 Infrastructure를 다음으로 둔다. Composition과 UI도 서로 독립이지만 live UseCase graph를 먼저 검증하기 위해 Composition을 UI보다 먼저 둔다. 이 순서는 이 명세의 구현이 끝날 때까지 바꾸지 않는다.

각 패키지 단계의 모든 작업과 검증이 끝나고 변경 파일·검증 결과를 보고한 뒤 사용자의 명시적 승인을 받아야 다음 패키지로 진행한다. 승인 전 다음 패키지 영향 분석은 허용하지만 해당 패키지 파일은 변경하지 않는다.

### 변경 시나리오 추적성

- S1(Domain 계약 완비)은 작업 패키지 1 전체.
- S2(Data Remote 완비)는 작업 패키지 2, 3.
- S3(Composition live graph)는 작업 패키지 4.
- S4(Feature 소비)는 작업 패키지 5(선행 UI), 6.
- S5(App root/navigation)는 작업 패키지 7.
- S6(CI/release gate 차단)은 전체 완료 검증의 T202.
- 각 시나리오는 관련된 모든 패키지가 완료된 뒤 `spec.md`의 수용 시나리오로 독립 검증한다.

### 패키지 내부 실행

- `[P]` 작업은 승인된 현재 패키지 안의 서로 다른 파일에만 사용한다(예: Domain 신규 모델 T023~T032, Feature Mock 파일들).
- Protocol → concrete 순서(예: T040 → T041)처럼 같은 UC 안의 의존 작업은 순차 실행한다.
- 다른 패키지의 작업은 병렬 실행하지 않는다.

## 구현 전략

1. 헌법 순서에서 첫 미완료 적용 대상 패키지(Domain)만 선택한다.
2. 그 패키지의 준비·테스트·구현·정리·검증을 모두 완료한다.
3. 변경 파일과 실제 검증 결과를 보고하고 다음 패키지(Infrastructure) 승인을 요청한 뒤 중단한다.
4. 명시적 승인 후 다음 적용 대상 패키지에서 같은 절차를 반복한다(Infrastructure → Data → Composition → UI → Feature → App).
5. App 완료 뒤에만 전체 읽기 전용 검증(T201~T205)과 변경 시나리오 수용 검증을 실행한다.

## 참고

- UC12(RefreshSession)·UC14(SignOut revoke)는 `INT-API-001`(서버 endpoint 미확보)로 구조만 구현하며, 모든 패키지 단계에서 "구조 완료"와 "production capability 완료"를 분리 표시한다.
- 작업 ID는 실제 실행 순서대로 증가한다.
- 모호한 소유권, 다중 패키지 작업, 승인 게이트를 넘는 병렬 실행을 허용하지 않는다.
- 문제 해결과 암묵지 기록(`trouble-shooting.md`, `tacit-knowledge.md`)은 이 작업 목록의 작업 ID로 만들지 않는다. 실제 발생 시 각 전용 Spec Kit 스킬이 별도로 기록한다.
