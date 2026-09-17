---

description: "관심사별 Domain UseCase 재설계와 호출부 전환 작업 목록"
---

# 작업 목록: 관심사별 Domain UseCase 재설계와 호출부 전환

**입력**: `/specs/037-domain-usecase-redesign/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md),
[contracts/domain-api.md](./contracts/domain-api.md), [contracts/integration-surface.md](./contracts/integration-surface.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를 snapshot한다. 별도 기준선 commit은
사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만 선택한다.

**테스트**: 명세 SC-005가 시나리오 2–4의 자동 테스트를 요구하므로 테스트 작업을 포함한다.

**구성**: 실행 단위를 최상위 구조로 사용하고 변경 시나리오는 각 단위 안에서 추적한다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[S#]**: 명세의 변경 시나리오 1–5
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 검증. `make tuist`의 파생 workspace·project·심볼릭
  링크·cache 갱신은 허용하되 실행 전후 `git status --porcelain`을 비교하고 추적 파일 변경이 생기면 완료로 처리하지 않는다.
- 모든 경로는 저장소 루트 기준이다. 새 Swift 파일은 파일당 타입 1개, 주석은 `// MARK:`만 쓴다.
- 선언 모양은 [domain-api.md](./contracts/domain-api.md)·[integration-surface.md](./contracts/integration-surface.md), 동작 규칙은
  [data-model.md](./data-model.md)가 정본이다. 작업 설명은 그 정본을 따르는 대상 파일만 지정한다.
- 프로젝트 `build`·`compile`·`test` 실행기는 사용자 지시에 따라 에이전트가 실행하지 않는다. 각 단위 검증은 정적 검사로
  수행하고, 실행기 검증은 사용자 확인 항목으로 보고한다.

## 실행 단위 순서와 근거

아키텍처 문서 3.1의 의존 방향(Domain·Infrastructure → Data → Composition → Feature → App)을 따른다.

1. **U1 Domain 추가** — 다른 패키지에 의존하지 않고, 이후 모든 단위가 새 타깃을 참조한다.
2. **U2 알림 권한 설정 조회** — Infrastructure 요구사항 추가가 Data 구현·테스트 대역과 Composition 테스트 대역을 함께 바꿔야
   compile된다.
3. **U3 요청 인증 정보** — Data Remote 공개 init 변경이 Composition 조립·테스트와 함께 바뀌어야 compile된다.
4. **U4 새 UseCase 조립** — U1의 타깃과 U2·U3의 Data 표면을 사용한다.
5. **U5 호출부 전환** — plan의 U5–U7을 하나의 integration unit으로 합친다. `MainShellRouterFeature`, `AppRootFeature`,
   `AppRootView` 프리뷰와 App 테스트 지원 파일이 세 관심사 묶음의 의존을 함께 받아 파일별로 옛·새 모듈 import를 분리할 수 없기
   때문이다(plan의 합침 조건).
6. **U6 옛 선언 제거** — 모든 호출부가 옮겨진 뒤에만 compile된다.
7. **U7 규칙 문서** — 최종 구조를 기록한다.
8. **전체 검증** — `[no-write]`만.

---

## U1: 새 Domain 타깃 추가 (integration: Domain + Tuist 헬퍼 + 의존성 검사 설정)

**목표**: 기존 세 타깃을 유지한 채 `DomainIdentifier`와 관심사 타깃 7개, 테스트 타깃 8개를 추가한다.

**분리 불가 근거**: `tools/package-dependencies/config/source-roots`는 매니페스트 타깃과 소스 루트의 1:1 일치를 검사하므로 타깃
선언·scheme·소스 루트가 같은 단위여야 검사가 통과한다.

**독립 검증**: 각 새 타깃 소스를 `swiftc -typecheck`로 검사하고 의존성 검사 스크립트가 통과한다.

### 매니페스트

- [X] T001 [S1] `sources/Tuist/ProjectDescriptionHelpers/Projects/DomainModuleName.swift`에 case `DomainIdentifier`, `DomainIdentifierTests`, `DomainAccount`, `DomainAccountTests`, `DomainUserInfo`, `DomainUserInfoTests`, `DomainAppSetting`, `DomainAppSettingTests`, `DomainExternalRepository`, `DomainExternalRepositoryTests`, `DomainQuizDetail`, `DomainQuizDetailTests`, `DomainProject`, `DomainProjectTests`, `DomainProjectGeneration`, `DomainProjectGenerationTests`를 추가한다. 관심사 production 타깃은 `.module(name:sourceDirectory:dependencies: [.target(name: DomainModuleName.DomainIdentifier.rawValue)])`, 테스트 타깃은 기존 패턴의 `.testModule(productionTarget:)`로 선언한다
- [X] T002 [S1] `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 `Domain` scheme `buildTargets`·`testTargets`에 T001의 새 타깃을 추가한다
- [X] T003 [S1] `sources/Tuist/ProjectDescriptionHelpers/AllTestsScheme.swift`의 `allTestTargets`에 새 Domain 테스트 타깃 8개를 추가한다
- [X] T004 [S1] `tools/package-dependencies/config/source-roots`에 새 타깃 16개의 `<타깃> Domain/<루트>`·`<타깃>Tests Domain/Tests/<루트>` 줄을 추가한다(`DomainIdentifier Domain/Identifier` 등)

### DomainIdentifier

- [X] T005 [P] [S1] `sources/Projects/Domain/Identifier/Models/ProjectID.swift`, `sources/Projects/Domain/Identifier/Models/QuizSetID.swift`, `sources/Projects/Domain/Identifier/Models/QuizID.swift`, `sources/Projects/Domain/Identifier/Models/ExternalRepositoryURL.swift`를 만든다
- [X] T006 [P] [S1] `sources/Projects/Domain/Tests/Identifier/Models/IdentifierTests.swift`에 식별자가 `String` 값으로 상호 대입되는지 검증하는 테스트를 만든다

### DomainAccount

- [X] T007 [P] [S1] [S4] 로그인 모델을 만든다: `sources/Projects/Domain/Account/Models/SignIn/AccountID.swift`, `SignInMethod.swift`, `SignedInAccount.swift`, `SignInState.swift`, `SignInResult.swift`, `SignOutResult.swift`, `SignInRestoration.swift`, `SignInVerification.swift`, `SignInAvailability.swift`, `AuthenticationGrant.swift`, `SignInRecord.swift` (모두 `sources/Projects/Domain/Account/Models/SignIn/` 아래)
- [X] T008 [P] [S1] [S5] 약관 동의 모델을 만든다: `sources/Projects/Domain/Account/Models/PolicyConsent/PolicyDocumentID.swift`, `PolicyDocument.swift`, `PolicyConsent.swift`, `PolicyConsentStatus.swift` (모두 `sources/Projects/Domain/Account/Models/PolicyConsent/` 아래)
- [X] T009 [P] [S1] `sources/Projects/Domain/Account/Errors/AccountError.swift`를 만든다
- [X] T010 [S1] 계약을 만든다: `sources/Projects/Domain/Account/Contracts/AuthenticationRepository.swift`, `sources/Projects/Domain/Account/Contracts/SignInRepository.swift`, `sources/Projects/Domain/Account/Contracts/WithdrawalRepository.swift`, `sources/Projects/Domain/Account/Contracts/PolicyConsentRepository.swift`
- [X] T011 [S1] `sources/Projects/Domain/Account/UseCases/AccountUseCase.swift`를 만든다
- [X] T012 [S1] [S4] [S5] `sources/Projects/Domain/Account/UseCases/Account.swift`에 data-model §1의 상태 전이·동작 규칙(`.unknown` 초기 상태, 무효 신호 관찰, 무효 정리, 약관 판정, 탈퇴)을 구현한다
- [X] T013 [P] [S4] 테스트 대역을 만든다: `sources/Projects/Domain/Tests/Account/TestDoubles/StubAuthenticationRepository.swift`, `StubSignInRepository.swift`, `StubWithdrawalRepository.swift`, `InMemoryPolicyConsentRepository.swift` (모두 `sources/Projects/Domain/Tests/Account/TestDoubles/` 아래)
- [X] T014 [S4] `sources/Projects/Domain/Tests/Account/UseCases/AccountTests.swift`에 로그인·로그아웃·복원·확인 결과와 상태 방출(`.unknown` 첫 값, 복원 일시 실패 시 `.unknown` 유지, 무효 신호 수신 시 `.signedOut`)을 검증한다
- [X] T015 [P] [S4] `sources/Projects/Domain/Tests/Account/UseCases/AccountAvailabilityTests.swift`에 `signInAvailability()` 판정표 4가지를 검증한다
- [X] T016 [P] [S5] `sources/Projects/Domain/Tests/Account/UseCases/AccountPolicyConsentTests.swift`에 약관 충족 판정(버전 변경 시 불충족), `consent(to:)` 기록, 탈퇴 시 동의 삭제와 `.signedOut` 방출을 검증한다

### DomainUserInfo

- [X] T017 [P] [S1] [S5] 모델을 만든다: `sources/Projects/Domain/UserInfo/Models/UserDetail.swift`, `Curation.swift`, `UserProfile.swift`, `MemberPosition.swift`, `CareerLevel.swift`, `LearningStatistics.swift`, `WeeklyLearningCount.swift` (모두 `sources/Projects/Domain/UserInfo/Models/` 아래)
- [X] T018 [P] [S1] `sources/Projects/Domain/UserInfo/Errors/UserInfoError.swift`와 `sources/Projects/Domain/UserInfo/Contracts/UserInfoRepository.swift`를 만든다
- [X] T019 [S1] [S5] `sources/Projects/Domain/UserInfo/UseCases/UserInfoUseCase.swift`와 `sources/Projects/Domain/UserInfo/UseCases/UserInfo.swift`(진행 중 조회 공유, 변경 단일 직렬화 키)를 만든다
- [X] T020 [S5] `sources/Projects/Domain/Tests/UserInfo/TestDoubles/StubUserInfoRepository.swift`와 `sources/Projects/Domain/Tests/UserInfo/UseCases/UserInfoTests.swift`에 동시 `detail()`·`curation()` 호출 시 조회 1회, 큐레이션 파생, 변경 직렬 순서를 검증한다

### DomainAppSetting

- [X] T021 [P] [S1] [S5] 모델과 오류를 만든다: `sources/Projects/Domain/AppSetting/Models/NotificationAuthorizationStatus.swift`, `DeviceID.swift`, `DeviceToken.swift`, `DevicePlatform.swift`, `DeviceRegistration.swift` (모두 `sources/Projects/Domain/AppSetting/Models/` 아래), `sources/Projects/Domain/AppSetting/Errors/AppSettingError.swift`
- [X] T022 [P] [S1] 계약을 만든다: `sources/Projects/Domain/AppSetting/Contracts/NotificationAuthorization.swift`, `sources/Projects/Domain/AppSetting/Contracts/DeviceRegistrationRepository.swift`, `sources/Projects/Domain/AppSetting/Contracts/DeviceIdentifierRepository.swift`
- [X] T023 [S1] [S5] `sources/Projects/Domain/AppSetting/UseCases/AppSettingUseCase.swift`와 `sources/Projects/Domain/AppSetting/UseCases/AppSetting.swift`를 만든다
- [X] T024 [S5] `sources/Projects/Domain/Tests/AppSetting/TestDoubles/StubNotificationAuthorization.swift`, `sources/Projects/Domain/Tests/AppSetting/TestDoubles/SpyDeviceRegistrationRepository.swift`, `sources/Projects/Domain/Tests/AppSetting/UseCases/AppSettingTests.swift`에 권한 상태 전달, 등록 정보 구성, 토큰 제공 실패 전파, 토큰 갱신 등록을 검증한다

### DomainExternalRepository

- [X] T025 [P] [S1] [S5] `sources/Projects/Domain/ExternalRepository/Models/ExternalRepository.swift`, `sources/Projects/Domain/ExternalRepository/Models/ExternalRepositoryLocation.swift`, `sources/Projects/Domain/ExternalRepository/Errors/ExternalRepositoryError.swift`, `sources/Projects/Domain/ExternalRepository/Contracts/ExternalRepositoryLocator.swift`, `sources/Projects/Domain/ExternalRepository/Contracts/ExternalRepositoryLookup.swift`를 만든다
- [X] T026 [S1] [S5] `sources/Projects/Domain/ExternalRepository/UseCases/ExternalRepositoryUseCase.swift`와 `sources/Projects/Domain/ExternalRepository/UseCases/ExternalRepositoryResolver.swift`를 만든다
- [X] T027 [S5] `sources/Projects/Domain/Tests/ExternalRepository/TestDoubles/StubExternalRepositoryLocator.swift`, `sources/Projects/Domain/Tests/ExternalRepository/TestDoubles/StubExternalRepositoryLookup.swift`, `sources/Projects/Domain/Tests/ExternalRepository/UseCases/ExternalRepositoryResolverTests.swift`에 해석 실패 시 조회 없이 `invalidURLFormat`, 성공 시 위임을 검증한다

### DomainQuizDetail

- [X] T028 [P] [S1] [S5] 퀴즈 모델을 만든다: `sources/Projects/Domain/QuizDetail/Models/Quiz/QuizSet.swift`, `Quiz.swift`, `QuizContent.swift`, `ChoiceSubmission.swift`, `EssaySubmission.swift`, `QuizSource.swift` (모두 `sources/Projects/Domain/QuizDetail/Models/Quiz/` 아래)
- [X] T029 [P] [S1] [S5] 채점 모델을 만든다: `sources/Projects/Domain/QuizDetail/Models/Grading/ChoiceAnswer.swift`, `ChoiceGrading.swift`, `EssayAnswer.swift`, `EssayGrading.swift` (모두 `sources/Projects/Domain/QuizDetail/Models/Grading/` 아래)
- [X] T030 [P] [S1] [S5] 북마크 모델을 만든다: `sources/Projects/Domain/QuizDetail/Models/Bookmark/QuizBookmarkState.swift`, `QuizBookmarkFilter.swift`, `QuizBookmark.swift`, `QuizBookmarkProject.swift`, `QuizBookmarkList.swift` (모두 `sources/Projects/Domain/QuizDetail/Models/Bookmark/` 아래)
- [X] T031 [P] [S1] `sources/Projects/Domain/QuizDetail/Errors/QuizDetailError.swift`, `sources/Projects/Domain/QuizDetail/Contracts/QuizSetRepository.swift`, `sources/Projects/Domain/QuizDetail/Contracts/AnswerRepository.swift`, `sources/Projects/Domain/QuizDetail/Contracts/BookmarkRepository.swift`를 만든다
- [X] T032 [S1] [S5] `sources/Projects/Domain/QuizDetail/UseCases/QuizDetailUseCase.swift`와 `sources/Projects/Domain/QuizDetail/UseCases/QuizDetail.swift`(입력 검증, 문제별 북마크 직렬화)를 만든다
- [X] T033 [S5] `sources/Projects/Domain/Tests/QuizDetail/TestDoubles/StubQuizSetRepository.swift`, `sources/Projects/Domain/Tests/QuizDetail/TestDoubles/SpyAnswerRepository.swift`, `sources/Projects/Domain/Tests/QuizDetail/TestDoubles/SpyBookmarkRepository.swift`, `sources/Projects/Domain/Tests/QuizDetail/UseCases/QuizDetailGradingTests.swift`, `sources/Projects/Domain/Tests/QuizDetail/UseCases/QuizDetailBookmarkTests.swift`에 음수 인덱스·공백·2000자 초과 거부, 공백 제거 제출, 북마크 순서 보장을 검증한다

### DomainProject

- [X] T034 [P] [S1] [S2] 모델을 만든다: `sources/Projects/Domain/Project/Models/ProjectList.swift`, `ProjectPage.swift`, `ProjectSummary.swift`, `ProjectSetLabel.swift`, `ProjectNextQuiz.swift`, `ProjectDetail.swift`, `ProjectRepositoryInfo.swift`, `ProjectSetProgress.swift` (모두 `sources/Projects/Domain/Project/Models/` 아래)
- [X] T035 [P] [S1] `sources/Projects/Domain/Project/Errors/ProjectError.swift`와 `sources/Projects/Domain/Project/Contracts/ProjectRepository.swift`를 만든다
- [X] T036 [S1] [S2] `sources/Projects/Domain/Project/UseCases/ProjectUseCase.swift`와 `sources/Projects/Domain/Project/UseCases/Project.swift`에 data-model §6 규칙(공유 목록, 첫 구독 로드, 로드 공유, 제외 집합 재적용·빠진 ID 새로고침, 삭제 반영, 로그아웃 정리)을 구현한다
- [X] T037 [S2] `sources/Projects/Domain/Tests/Project/TestDoubles/StubProjectRepository.swift`와 `sources/Projects/Domain/Tests/Project/UseCases/ProjectTests.swift`에 구독자 둘 동일 값, 첫 로드·새로고침 동시 호출 시 요청 1회, 다음 페이지 이어 붙이기, 제외 집합 필터와 재요청 없음, 집합에서 빠진 ID로 새로고침, 삭제 반영, 로그아웃 정리, 실패 시 마지막 목록 유지를 검증한다

### DomainProjectGeneration

- [X] T038 [P] [S1] [S3] 공개 모델을 만든다: `sources/Projects/Domain/ProjectGeneration/Models/QuizLevel.swift`, `ProjectGenerationRequest.swift`, `ProjectGenerationReceipt.swift`, `ProjectGenerationPhase.swift`, `ProjectGenerationRequestState.swift`, `ProjectGenerationState.swift`, `GenerationWaitPolicy.swift` (모두 `sources/Projects/Domain/ProjectGeneration/Models/` 아래)
- [X] T039 [P] [S1] [S3] 계약 모델을 만든다: `sources/Projects/Domain/ProjectGeneration/Models/Records/GenerationRecord.swift`, `GenerationState.swift`, `GenerationOutcome.swift`, `GenerationReminder.swift` (모두 `sources/Projects/Domain/ProjectGeneration/Models/Records/` 아래, `GenerationRecord`·`GenerationState`는 현재 `sources/Projects/Domain/LearningProject/Models/LearningProject/`의 동작을 `repositoryURL` 이름으로 옮긴다)
- [X] T040 [P] [S1] `sources/Projects/Domain/ProjectGeneration/Errors/ProjectGenerationError.swift`와 계약 `sources/Projects/Domain/ProjectGeneration/Contracts/ProjectGenerationRepository.swift`, `sources/Projects/Domain/ProjectGeneration/Contracts/PendingGenerationRepository.swift`, `sources/Projects/Domain/ProjectGeneration/Contracts/GenerationOutcomeRepository.swift`, `sources/Projects/Domain/ProjectGeneration/Contracts/GenerationReminderScheduler.swift`를 만든다
- [X] T041 [S1] [S3] `sources/Projects/Domain/ProjectGeneration/UseCases/ProjectGenerationUseCase.swift`와 `sources/Projects/Domain/ProjectGeneration/UseCases/ProjectGeneration.swift`에 data-model §7 규칙(중복 거부, 등록 보상, 알림 대상 영속 등록, 관찰 시작 시 만료 정리·대기열 흡수·결과 수신·로그아웃 구독, 단계 계산, 준비 타이머, 완료·실패 알림)을 구현한다
- [X] T042 [P] [S3] 테스트 대역을 만든다: `sources/Projects/Domain/Tests/ProjectGeneration/TestDoubles/InMemoryPendingGenerationRepository.swift`, `StubProjectGenerationRepository.swift`, `StubGenerationOutcomeRepository.swift`, `SpyGenerationReminderScheduler.swift`, `ManualSleeper.swift` (모두 `sources/Projects/Domain/Tests/ProjectGeneration/TestDoubles/` 아래)
- [X] T043 [P] [S3] `sources/Projects/Domain/Tests/ProjectGeneration/Models/GenerationStateTests.swift`에 정규화·시작 거부·완료 전이·만료 판정(현재 `sources/Projects/Domain/Tests/LearningProject/Models/LearningProject/GenerationStateTests.swift`·`GenerationRecordTests.swift` 대응)을 검증한다
- [X] T044 [S3] `sources/Projects/Domain/Tests/ProjectGeneration/UseCases/ProjectGenerationTests.swift`에 수용 시나리오 3-1~3-6(중복 거부, `preparing` 배너 기준, 타이머로 `ready` 방출, 실패 즉시 `failed`와 실패 알림, 요청만 호출 시 관찰 미시작, 만료 기록 정리)과 로그아웃 정리를 검증한다

### U1 검증

- [X] T045 [no-write] 새 타깃마다 `xcrun swiftc -typecheck`를 실행한다: `DomainIdentifier`는 `sources/Projects/Domain/Identifier/**/*.swift`만, 관심사 타깃은 해당 소스와 `sources/Projects/Domain/Identifier/**/*.swift`를 함께 넣고 SDK는 `xcrun --sdk iphonesimulator --show-sdk-path`, `-target arm64-apple-ios26.0-simulator`로 지정한다. 오류 0건
- [X] T046 [no-write] `./tools/package-dependencies/bin/run.sh`가 통과하고, `grep -rn "^import Domain" sources/Projects/Domain/{Identifier,Account,UserInfo,AppSetting,ExternalRepository,QuizDetail,Project,ProjectGeneration} | grep -v "import DomainIdentifier"`가 0줄이다
- [X] T047 [no-write] 변경 파일과 검증 결과를 보고하고, Domain 테스트 scheme 실행을 사용자 확인 항목으로 남긴다

---

## U2: 알림 권한 설정 조회 (integration: Infrastructure + Data + Composition 테스트 대역)

**목표**: 권한 요청 없이 현재 알림 권한 설정을 조회하는 경로를 Infrastructure → Data로 연결한다(research R-08).

**분리 불가 근거**: `NotificationAuthorizationClient`와 `LocalReminderNotifier`에 요구사항을 추가하면 각 패키지의 준수 타입
(`SpyNotificationAuthorizationClient`, `ReminderNotificationClient`, `SpyLocalReminderNotifier`)이 같은 커밋에서 바뀌어야 compile된다.

- [X] T048 [P] [S5] `sources/Projects/Infrastructure/LocalNotification/Models/NotificationAuthorizationSetting.swift`를 만든다
- [X] T049 [S5] `sources/Projects/Infrastructure/LocalNotification/Clients/NotificationAuthorizationClient.swift`에 `authorizationSetting()` 요구사항을 추가하고 `sources/Projects/Infrastructure/LocalNotification/Clients/LocalNotificationAuthorizationClient.swift`에 integration-surface §1 매핑으로 구현한다
- [X] T050 [P] [S5] `sources/Projects/Data/Notification/Models/ReminderAuthorizationSetting.swift`를 만든다
- [X] T051 [S5] `sources/Projects/Data/Notification/Contracts/LocalReminderNotifier.swift`에 `authorizationSetting()`을 추가하고 `sources/Projects/Data/Notification/Clients/ReminderNotificationClient.swift`에서 Infrastructure 값을 매핑한다
- [X] T052 [S5] `sources/Projects/Data/Tests/Notification/TestDoubles/SpyNotificationAuthorizationClient.swift`에 설정 조회를 추가하고 `sources/Projects/Data/Tests/Notification/Clients/ReminderNotificationClientTests.swift`에 세 값 매핑 테스트를 추가한다
- [X] T053 [S5] `sources/Projects/Composition/Tests/ShareExtension/TestDoubles/SpyLocalReminderNotifier.swift`에 `authorizationSetting()`을 추가한다
- [X] T054 [no-write] 변경 파일을 보고하고 Infrastructure·Data·Composition 테스트 scheme compile을 사용자 확인 항목으로 남긴다

---

## U3: 요청 인증 정보 (integration: Data + Composition)

**목표**: 만료·401 시 로그인 정보를 지우고 무효 신호를 보내는 Data 구성요소를 만들고 모든 인증 요청이 사용하게 한다(FR-020–023).

**분리 불가 근거**: Remote 공개 init의 `accessTokenProvider`를 `credential`·`credentialRejected`로 바꾸면 Composition 조립과
Composition 테스트가 같은 커밋에서 바뀌어야 compile된다.

### Data

- [X] T055 [P] [S4] `sources/Projects/Data/Shared/Models/RequestCredential.swift`를 만든다
- [X] T056 [S4] `sources/Projects/Data/Authentication/Stores/RequestCredentialProvider.swift`에 data-model §8 규칙을 구현한다(`SessionRecordStorageCoding` 사용, `Mutex`로 구독자 보호)
- [X] T057 [S4] `sources/Projects/Data/Tests/Authentication/Stores/RequestCredentialProviderTests.swift`에 기록 없음·만료·유효, 만료 시 삭제와 신호 1회, 401 거부 시 삭제와 신호, 기록이 없을 때 거부 신호 미방출, 구독자 둘 모두 수신을 검증한다
- [X] T058 [S4] `sources/Projects/Data/Authentication/Remotes/AuthenticationRemote.swift`의 `accessTokenProvider`를 `credential`로 바꾸고, `verifyAccessToken()`이 `.signedOut`이면 요청 없이 `unauthorized`를 던지게 한다
- [X] T059 [S4] `sources/Projects/Data/LearningProject/Remotes/LearningProjectRequestExecutor.swift`가 `credential`·`credentialRejected`를 받아 `.signedOut`이면 전송 없이 `unauthorized`, 401이면 `credentialRejected()` 후 `unauthorized`를 던지게 한다
- [X] T060 [S4] `sources/Projects/Data/LearningProject/Remotes/ProjectRemote.swift`, `sources/Projects/Data/LearningProject/Remotes/LearningSetRemote.swift`, `sources/Projects/Data/LearningProject/Remotes/AnswerRemote.swift`, `sources/Projects/Data/LearningProject/Remotes/BookmarkRemote.swift`의 공개 init 인자를 `credential`·`credentialRejected`로 바꾼다
- [X] T061 [S4] `sources/Projects/Data/Member/Remotes/MemberRemote.swift`에 T059와 같은 규칙을 적용한다
- [X] T062 [S4] Data 테스트를 새 init에 맞춘다: `sources/Projects/Data/Tests/Authentication/Remotes/AuthenticationRemoteTests.swift`, `sources/Projects/Data/Tests/LearningProject/Remotes/ProjectRemoteTests.swift`, `sources/Projects/Data/Tests/LearningProject/Remotes/ProjectRemoteAuthorizationTests.swift`, `sources/Projects/Data/Tests/LearningProject/Remotes/LearningSetRemoteTests.swift`, `sources/Projects/Data/Tests/LearningProject/Remotes/AnswerRemoteTests.swift`, `sources/Projects/Data/Tests/LearningProject/Remotes/BookmarkRemoteTests.swift`, `sources/Projects/Data/Tests/Member/Remotes/MemberRemoteTests.swift`
- [X] T063 [S4] `sources/Projects/Data/Tests/LearningProject/Remotes/LearningProjectRequestExecutorTests.swift`와 `sources/Projects/Data/Tests/Member/Remotes/MemberRemoteCredentialTests.swift`에 `.signedOut` 시 전송 0회, 401 시 거부 호출 1회·재전송 0회를 검증한다

### Composition

- [X] T064 [S4] `sources/Projects/Composition/Authentication/Assemblies/AuthenticationAssembly.swift`가 `RequestCredentialProvider`를 만들어 `requestCredentialProvider`로 공개하고, `accessTokenProvider`를 제거하며, `recordSharedSessionState`가 `credential()`의 `available` 여부로 공유 표시를 기록하게 한다
- [X] T065 [S4] `sources/Projects/Composition/Authentication/Assemblies/SessionAvailabilityAssembly.swift`의 `accessTokenProvider`를 제거하고 `RequestCredentialProvider`를 공개한다
- [X] T066 [S4] `sources/Projects/Composition/LearningProject/Assemblies/LearningProjectAssembly.swift`와 `sources/Projects/Composition/Member/Assemblies/MemberAssembly.swift`의 `accessTokenProvider` 인자를 `credential`·`credentialRejected`로 바꿔 Remote에 전달한다
- [X] T067 [S4] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`와 `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`가 인증 조립의 `RequestCredentialProvider` 하나를 모든 Remote에 연결하게 한다
- [X] T068 [S4] Composition 테스트를 새 init에 맞춘다: `sources/Projects/Composition/Tests/LearningProject/Assemblies/LearningProjectAssemblyTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Adapters/LearningSetRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Adapters/AnswerRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Adapters/BookmarkRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Adapters/LearningProjectRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/App/SharedLifetimeTests.swift`, `sources/Projects/Composition/Tests/Member/Adapters/MemberRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/Authentication/Adapters/AuthenticationRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/Authentication/Adapters/LoginSessionRepositoryAdapterTests.swift`
- [X] T069 [no-write] `grep -rn "accessTokenProvider" sources/Projects --include="*.swift" | grep -v /Derived/`가 0줄임을 확인하고, 변경 파일과 Data·Composition 테스트 실행을 사용자 확인 항목으로 보고한다

---

## U4: 새 관심사 UseCase 조립 (integration: Composition + Tuist 헬퍼)

**목표**: 기존 공개 속성을 유지한 채 관심사 UseCase 7개를 조립해 `AppComposition`·`ShareExtensionComposition`에 추가한다.

**분리 불가 근거**: Composition 모듈의 새 Domain 타깃 import는 매니페스트 `.fromDomain` 선언과 같은 커밋이어야 compile되고
의존성 검사가 통과한다.

- [X] T070 [S1] `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`의 각 Composition 타깃에 integration-surface §3 표의 새 Domain 의존을 추가한다(옛 의존 유지)
- [X] T071 [S4] `sources/Projects/Composition/Authentication/Adapters/SignInRepositoryAdapter.swift`를 만든다(`DomainAccount.SignInRepository`: 로그인 시작·복원·로컬 로그아웃·공유 표시·`hasUsableCredential()`은 `RequestCredentialProvider.credential()`이 `available`인지)
- [X] T072 [S4] `sources/Projects/Composition/Authentication/Adapters/AccountAuthenticationRepositoryAdapter.swift`를 만든다(`DomainAccount.AuthenticationRepository`, 취소는 `AccountError.signInCancelled`)
- [X] T073 [S5] `sources/Projects/Composition/Authentication/Adapters/AccountPolicyConsentRepositoryAdapter.swift`를 만든다(`DomainAccount.PolicyConsentRepository`)
- [X] T074 [S5] `sources/Projects/Composition/Member/Adapters/WithdrawalRepositoryAdapter.swift`, `sources/Projects/Composition/Member/Adapters/UserInfoRepositoryAdapter.swift`(큐레이션 완료 시 저장 기록 `needsCuration = false`, research R-07), `sources/Projects/Composition/Member/Adapters/DeviceRegistrationRepositoryAdapter.swift`, `sources/Projects/Composition/Member/Adapters/AppSettingDeviceIdentifierRepositoryAdapter.swift`를 만든다
- [X] T075 [S5] `sources/Projects/Composition/LearningProject/Adapters/AppSettingNotificationAuthorizationAdapter.swift`를 만든다(설정 조회와 요청 결과 매핑)
- [X] T076 [S5] `sources/Projects/Composition/LearningProject/Adapters/QuizSetRepositoryAdapter.swift`, `sources/Projects/Composition/LearningProject/Adapters/QuizAnswerRepositoryAdapter.swift`, `sources/Projects/Composition/LearningProject/Adapters/QuizBookmarkRepositoryAdapter.swift`를 만든다(data-model §5의 `Quiz` 변환 포함)
- [X] T077 [S2] `sources/Projects/Composition/LearningProject/Adapters/ProjectRepositoryAdapter.swift`를 만든다(data-model §6의 요약·상세 변환)
- [X] T078 [S3] `sources/Projects/Composition/LearningProject/Adapters/ProjectGenerationRepositoryAdapter.swift`, `sources/Projects/Composition/LearningProject/Adapters/ProjectGenerationPendingRepositoryAdapter.swift`(`releaseAll()` 포함), `sources/Projects/Composition/LearningProject/Adapters/ProjectGenerationOutcomeRepositoryAdapter.swift`, `sources/Projects/Composition/LearningProject/Adapters/ProjectGenerationReminderSchedulerAdapter.swift`(종류별 제목·본문)를 만든다
- [X] T079 [S5] `sources/Projects/Composition/LearningProject/Adapters/ResolverExternalRepositoryLocatorAdapter.swift`와 `sources/Projects/Composition/LearningProject/Adapters/ResolverExternalRepositoryLookupAdapter.swift`를 만든다(`DomainExternalRepository` 계약)
- [X] T080 [S1] `sources/Projects/Composition/App/Assemblies/ConcernUseCaseAssembly.swift`를 만들어 integration-surface §3 조립 규칙대로 관심사 UseCase 7개를 앱 수명 인스턴스로 만든다(`signedOutEvents`·`preparingProjectIDs` 변환 포함)
- [X] T081 [S1] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`에 `account`, `userInfo`, `appSetting`, `externalRepository`, `quizDetail`, `project`, `projectGeneration` 속성과 `Environment.generationFailureReminderTitle`·`generationFailureReminderBody`를 추가한다
- [X] T082 [S3] `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`에 `externalRepository`, `projectGeneration`, `signInAvailability`를 추가한다(빈 로그아웃·무효 신호)
- [X] T083 [S1] `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionPublicSurfaceTests.swift`의 기대 속성 목록에 새 속성 7개를 추가한다
- [X] T084 [P] [S4] `sources/Projects/Composition/Tests/Authentication/Adapters/SignInRepositoryAdapterTests.swift`에 로그인 시작 시 `needsCuration` 전달, 로컬 로그아웃 시 기록·공유 표시 정리, 만료 기록의 `hasUsableCredential() == false`를 검증한다
- [X] T085 [P] [S5] `sources/Projects/Composition/Tests/Member/Adapters/UserInfoRepositoryAdapterTests.swift`에 큐레이션 완료 후 저장 기록 `needsCuration == false`, 한쪽만 선택된 프로필의 `curation == nil`을 검증한다
- [X] T086 [P] [S2] `sources/Projects/Composition/Tests/LearningProject/Adapters/ProjectRepositoryAdapterTests.swift`에 요약·상세 변환(`next`, `quizCount`)을 검증한다
- [X] T087 [P] [S3] `sources/Projects/Composition/Tests/ShareExtension/ShareExtensionCompositionTests.swift`에 확장 앱 `projectGeneration.request` 후 알림 대상이 대기열에 남고 상태 관찰이 시작되지 않음, `signInAvailability()`가 만료 기록에서 `signInRequired`임을 추가 검증한다
- [X] T088 [no-write] `./tools/package-dependencies/bin/run.sh`가 통과하고 변경 파일과 Composition 테스트 실행을 사용자 확인 항목으로 보고한다

---

## U5: 호출부 전환 (integration: Feature + App + Tuist 헬퍼)

**목표**: Feature·App이 관심사 UseCase 7개만 사용하게 하고, 퀴즈 후 갱신·생성 배너·확장 앱 동작을 새 규칙으로 바꾼다.

**분리 불가 근거**: Router init 인자 변경은 App 루트 호출부와 같은 커밋이어야 compile되고, `MainShellRouterFeature`·`AppRootFeature`·
`AppRootView`·App 테스트 지원 파일이 세 관심사 묶음을 함께 전달해 묶음별 분리가 불가능하다. 전환이 끝난 파일은 옛 Domain 모듈을
import하지 않는다.

### 매니페스트

- [X] T089 [S1] `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`와 `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`의 `.fromDomain` 의존을 새 타깃(`GitIt`·`GitItTests`·`Feature`는 8개 전부, `ShareExtension`은 `DomainIdentifier`·`DomainAccount`·`DomainExternalRepository`·`DomainProjectGeneration`)으로 바꾼다

### Account·UserInfo·AppSetting

- [X] T090 [S4] [S5] `sources/Projects/Feature/AppEntry/AppEntryFeature.swift`를 `AccountUseCase.restoreSignIn()`·`signOut()`과 `UserInfoUseCase.curation()` 클로저로 전환한다
- [X] T091 [S5] `sources/Projects/Feature/Onboarding/Router/OnboardingRouterFeature.swift`, `sources/Projects/Feature/Onboarding/Tutorial/TutorialFeature.swift`(`deletesCompletedAccountOnSignIn` → `withdraw()`), `sources/Projects/Feature/Onboarding/LegalAgreement/LegalAgreementFeature.swift`(`policyConsentStatus()`·`consent(to:)`), `sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionFeature.swift`, `sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionFeature.swift`(`updateCuration(Curation)`)를 전환한다
- [X] T092 [S5] 온보딩 화면·프리뷰 import와 모델 타입을 바꾼다: `sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionScreen.swift`, `sources/Projects/Feature/Onboarding/CareerSelection/Previews/CareerSelectionScreenPreviews.swift`, `sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionScreen.swift`, `sources/Projects/Feature/Onboarding/PositionSelection/Previews/PositionSelectionScreenPreviews.swift`, `sources/Projects/Feature/Onboarding/LegalAgreement/LegalAgreementScreen.swift`, `sources/Projects/Feature/Onboarding/Previews/OnboardingPreviewSupport.swift`
- [X] T093 [S5] `sources/Projects/Feature/Settings/Router/SettingsRouterFeature.swift`, `sources/Projects/Feature/Settings/Settings/SettingsFeature.swift`(research R-08 알림 분기, `withdraw()`, `UserInfoError`), `sources/Projects/Feature/Settings/Profile/ProfileFeature.swift`를 전환한다
- [X] T094 [S5] 설정 표시 모델·프리뷰를 바꾼다: `sources/Projects/Feature/Settings/Profile/ViewModels/ProfileDisplay.swift`, `sources/Projects/Feature/Settings/Shared/ViewModels/CareerLevelDisplay.swift`, `sources/Projects/Feature/Settings/Shared/ViewModels/PositionDisplay.swift`, `sources/Projects/Feature/Settings/Profile/Previews/ProfileScreenPreviews.swift`, `sources/Projects/Feature/Settings/Settings/Previews/SettingsScreenPreviews.swift`
- [X] T095 [S5] Account 계열 Feature 테스트를 전환한다: `sources/Projects/Feature/Tests/AppEntry/AppEntry/AppEntryFeatureTests.swift`, `sources/Projects/Feature/Tests/AppEntry/TestDoubles/FetchMemberProfileUseCaseMock.swift`, `sources/Projects/Feature/Tests/AppEntry/TestDoubles/RestoreSessionUseCaseMock.swift`, `sources/Projects/Feature/Tests/Onboarding/CareerSelection/CareerSelectionFeatureTests.swift`, `sources/Projects/Feature/Tests/Onboarding/LegalAgreement/LegalAgreementFeatureTests.swift`, `sources/Projects/Feature/Tests/Onboarding/PositionSelection/PositionSelectionFeatureTests.swift`, `sources/Projects/Feature/Tests/Onboarding/Router/OnboardingRouterFeatureTests.swift`, `sources/Projects/Feature/Tests/Onboarding/Tutorial/TutorialFeatureTests.swift`, `sources/Projects/Feature/Tests/Onboarding/TestDoubles/CompleteCurationUseCaseMock.swift`, `sources/Projects/Feature/Tests/Onboarding/TestDoubles/DeleteMemberAccountUseCaseMock.swift`, `sources/Projects/Feature/Tests/Onboarding/TestDoubles/OnboardingTestFixture.swift`, `sources/Projects/Feature/Tests/Onboarding/TestDoubles/OnboardingTestSupport.swift`, `sources/Projects/Feature/Tests/Onboarding/TestDoubles/PolicyConsentUseCaseMock.swift`, `sources/Projects/Feature/Tests/Onboarding/TestDoubles/SignInUseCaseMock.swift`, `sources/Projects/Feature/Tests/Onboarding/TestDoubles/SignOutUseCaseMock.swift`, `sources/Projects/Feature/Tests/Settings/Profile/ViewModels/ProfileDisplayTests.swift`, `sources/Projects/Feature/Tests/Settings/Router/SettingsRouterFeatureTests.swift`, `sources/Projects/Feature/Tests/Settings/Settings/SettingsFeatureTests.swift`, `sources/Projects/Feature/Tests/Settings/TestDoubles/MemberAccountUseCaseMock.swift`, `sources/Projects/Feature/Tests/Settings/TestDoubles/SettingsTestFixture.swift`, `sources/Projects/Feature/Tests/Settings/TestDoubles/UpdateMemberCareerLevelUseCaseMock.swift`, `sources/Projects/Feature/Tests/Settings/TestDoubles/UpdateMemberPositionUseCaseMock.swift`
- [X] T096 [S5] `sources/Projects/Feature/Tests/Settings/Settings/SettingsFeatureTests.swift`에 알림 항목 선택 시 `.notDetermined`면 요청, `.denied`면 설정 이동을 검증하는 테스트를 추가한다

### QuizDetail

- [X] T097 [S5] `sources/Projects/Feature/Quiz/Router/QuizRouterFeature.swift`(`progressInvalidated` delegate 제거), `sources/Projects/Feature/Quiz/LearningSetIntro/LearningSetIntroFeature.swift`, `sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingFeature.swift`, `sources/Projects/Feature/Saved/SavedFeature.swift`, `sources/Projects/Feature/ProjectDetail/SingleQuestionEntry/SingleQuestionEntryFeature.swift`를 `QuizDetailUseCase`와 새 모델(`QuizSet`, `Quiz`, `QuizContent`, `ChoiceGrading`, `EssayGrading`, `QuizBookmarkState`, `QuizBookmarkList`, `QuizDetailError`)로 전환한다
- [X] T098 [S5] 퀴즈 표시 모델·화면·프리뷰를 바꾼다: `sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingScreen.swift`, `sources/Projects/Feature/Quiz/QuestionSolving/ViewModels/ChoiceOptionDisplay.swift`, `sources/Projects/Feature/Quiz/QuestionSolving/ViewModels/QuestionSourceDisplay.swift`, `sources/Projects/Feature/Quiz/Shared/Models/LearningSetResumption.swift`, `sources/Projects/Feature/Saved/SubViews/SavedScreen+FilterSection.swift`, `sources/Projects/Feature/Saved/ViewModels/SavedQuestionDisplay.swift`, `sources/Projects/Feature/Quiz/LearningSetIntro/Previews/LearningSetIntroScreenPreviews.swift`, `sources/Projects/Feature/Quiz/QuestionSolving/Previews/QuestionSolvingScreenPreviews.swift`, `sources/Projects/Feature/Quiz/Router/Previews/QuizRouterPreviews.swift`, `sources/Projects/Feature/Saved/Previews/SavedScreenPreviews.swift`
- [X] T099 [S5] QuizDetail 계열 Feature 테스트를 전환한다: `sources/Projects/Feature/Tests/Quiz/LearningSetIntro/LearningSetIntroFeatureTests.swift`, `sources/Projects/Feature/Tests/Quiz/QuestionSolving/QuestionSolvingFeatureTests.swift`, `sources/Projects/Feature/Tests/Quiz/QuestionSolving/ViewModels/ChoiceOptionDisplayTests.swift`, `sources/Projects/Feature/Tests/Quiz/QuestionSolving/ViewModels/QuestionSourceDisplayTests.swift`, `sources/Projects/Feature/Tests/Quiz/Router/QuizRouterFeatureTests.swift`, `sources/Projects/Feature/Tests/Quiz/Shared/Models/LearningSetResumptionTests.swift`, `sources/Projects/Feature/Tests/Quiz/TestDoubles/LearningLibraryUseCaseMock.swift`, `sources/Projects/Feature/Tests/Quiz/TestDoubles/QuizTestFixture.swift`, `sources/Projects/Feature/Tests/Quiz/TestDoubles/StubFetchBookmarkedQuestionsUseCase.swift`, `sources/Projects/Feature/Tests/Quiz/TestDoubles/StubFetchLearningSetUseCase.swift`, `sources/Projects/Feature/Tests/Quiz/TestDoubles/StubSetQuestionBookmarkUseCase.swift`, `sources/Projects/Feature/Tests/Quiz/TestDoubles/StubSubmitChoiceAnswerUseCase.swift`, `sources/Projects/Feature/Tests/Quiz/TestDoubles/StubSubmitEssayAnswerUseCase.swift`, `sources/Projects/Feature/Tests/Saved/Saved/SavedFeatureTests.swift`, `sources/Projects/Feature/Tests/ProjectDetail/SingleQuestionEntry/SingleQuestionEntryFeatureTests.swift`

### Project·ProjectGeneration·ExternalRepository

- [X] T100 [S2] `sources/Projects/Feature/Home/HomeFeature.swift`와 `sources/Projects/Feature/ProjectList/ProjectListFeature.swift`를 `ProjectUseCase.projects()` 구독·`refresh()`·`requestNextPage()`와 `ProjectGenerationUseCase.states()` 단계 기반 배너·결과 표시로 전환하고, Home 프로필은 `UserInfoUseCase`로 받는다
- [X] T101 [S2] `sources/Projects/Feature/ProjectDetail/ProjectDetailFeature.swift`와 `sources/Projects/Feature/ProjectDetail/Router/ProjectDetailRouterFeature.swift`를 `ProjectUseCase.detail(of:)`·`delete(_:)`와 `QuizDetailUseCase`로 전환한다
- [X] T102 [S3] `sources/Projects/Feature/ProjectRegistration/Router/ProjectRegistrationRouterFeature.swift`, `sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputFeature.swift`, `sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/QuizGenerationProgressFeature.swift`(`request(_:)`, 단계 기반 진행, 알림 권한은 `AppSettingUseCase`), `sources/Projects/Feature/ProjectRegistration/QuizLevelSelection/QuizLevelSelectionFeature.swift`, `sources/Projects/Feature/ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationFeature.swift`를 전환한다
- [X] T103 [S3] `sources/Projects/Feature/ShareRegistration/ShareRegistrationFeature.swift`를 `signInAvailability`·`ExternalRepositoryUseCase`·`ProjectGenerationUseCase`·`ExternalRepositoryLocator`로 전환하고 알림 대기열·권한 조회 의존을 제거한다
- [X] T104 [S2] [S3] `sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift`와 `sources/Projects/Feature/MainShell/Router/MainShellTab.swift`를 관심사 UseCase 인자로 전환한다
- [X] T105 [S2] [S3] 목록·등록 표시 모델·화면·프리뷰를 바꾼다: `sources/Projects/Feature/Home/ViewModels/HomeProfileDisplay.swift`, `sources/Projects/Feature/Home/ViewModels/HomeProjectDisplay.swift`, `sources/Projects/Feature/Home/Previews/HomeScreenPreviews.swift`, `sources/Projects/Feature/ProjectList/ViewModels/ProjectListDisplay.swift`, `sources/Projects/Feature/ProjectList/Previews/ProjectListScreenPreviews.swift`, `sources/Projects/Feature/ProjectDetail/ViewModels/ProjectDetailSetDisplay.swift`, `sources/Projects/Feature/ProjectDetail/Previews/ProjectDetailScreenPreviews.swift`, `sources/Projects/Feature/ProjectDetail/Router/Previews/ProjectDetailRouterPreviews.swift`, `sources/Projects/Feature/ProjectRegistration/QuizLevelSelection/QuizLevelSelectionScreen.swift`, `sources/Projects/Feature/ProjectRegistration/QuizLevelSelection/ViewModels/QuizLevel+Identifier.swift`, `sources/Projects/Feature/ProjectRegistration/QuizLevelSelection/Previews/QuizLevelSelectionScreenPreviews.swift`, `sources/Projects/Feature/ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationScreen.swift`, `sources/Projects/Feature/ProjectRegistration/Previews/ProjectRegistrationPreviewSupport.swift`, `sources/Projects/Feature/ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift`, `sources/Projects/Feature/ShareRegistration/Previews/ShareRegistrationScreenPreviews.swift`
- [X] T106 [S2] [S3] Project 계열 Feature 테스트를 전환한다: `sources/Projects/Feature/Tests/Home/Home/HomeFeatureGenerationOutcomeTests.swift`, `sources/Projects/Feature/Tests/Home/Home/ViewModels/HomeProjectDisplayTests.swift`, `sources/Projects/Feature/Tests/Home/TestDoubles/HomeLearningProjectsUseCaseMock.swift`, `sources/Projects/Feature/Tests/Home/TestDoubles/HomeMemberProfileUseCaseMock.swift`, `sources/Projects/Feature/Tests/Home/TestDoubles/HomeTestFixture.swift`, `sources/Projects/Feature/Tests/MainShell/Router/MainShellRouterFeatureTests.swift`, `sources/Projects/Feature/Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift`, `sources/Projects/Feature/Tests/ProjectDetail/Router/ProjectDetailRouterFeatureTests.swift`, `sources/Projects/Feature/Tests/ProjectDetail/TestDoubles/ProjectDetailTestFixture.swift`, `sources/Projects/Feature/Tests/ProjectDetail/TestDoubles/StubDeleteLearningProjectUseCase.swift`, `sources/Projects/Feature/Tests/ProjectDetail/TestDoubles/StubFetchLearningProjectDetailUseCase.swift`, `sources/Projects/Feature/Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift`, `sources/Projects/Feature/Tests/ProjectList/ViewModels/ProjectListDisplayTests.swift`, `sources/Projects/Feature/Tests/ProjectRegistration/QuizGenerationProgress/QuizGenerationProgressFeatureTests.swift`, `sources/Projects/Feature/Tests/ProjectRegistration/QuizLevelSelection/QuizLevelSelectionFeatureTests.swift`, `sources/Projects/Feature/Tests/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputFeatureTests.swift`, `sources/Projects/Feature/Tests/ProjectRegistration/Router/ProjectRegistrationRouterFeatureTests.swift`, `sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/ProjectRegistrationTestSupport.swift`, `sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/StubCreateLearningProjectUseCase.swift`, `sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/StubFetchExternalRepositoryUseCase.swift`, `sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/StubRequestGenerationReminderUseCase.swift`, `sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/StubTrackGenerationUseCase.swift`, `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistrationDiagnosticsTests.swift`, `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistrationFeatureFailureTests.swift`, `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistrationFeatureStepTests.swift`, `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistrationFeatureSubmissionTests.swift`, `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistrationFeatureValidationTests.swift`, `sources/Projects/Feature/Tests/ShareRegistration/TestDoubles/ShareRegistrationTestSupport.swift`

### App

- [X] T107 [S2] [S3] [S4] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`를 integration-surface §4대로 전환한다(관심사 UseCase 인자, `waitPolicy`·`generationRecord`·`releaseGeneration`·`generationReleased` 제거, 배너는 단계로 계산, 퀴즈 닫기 시 `project.refresh()`와 상세 갱신 요청, `progressInvalidated` 처리 제거, 기기 등록은 `appSetting`)
- [X] T108 [S1] `sources/Projects/App/GitIt/GitItApp.swift`와 `sources/Projects/App/GitIt/Launch/AppLaunchSequence.swift`를 새 `AppComposition` 속성으로 연결하고 `startObservingGenerationState`·`registerCurrentDevice` 사용을 제거한다
- [X] T109 [P] [S3] `sources/Projects/App/GitIt/GenerationReminderContent.swift`에 실패 알림 제목·본문을 추가하고 `sources/Projects/App/GitIt/GitItApp.swift`의 `Environment`에 전달한다(T108과 같은 파일은 T108 이후 적용)
- [X] T110 [P] [S5] `sources/Projects/App/GitIt/Loaders/PolicyManifestLoader.swift`가 `DomainAccount.PolicyDocument`를 만들게 한다
- [X] T111 [S1] `sources/Projects/App/GitIt/Screens/AppRootView.swift`의 프리뷰 지원 대역을 관심사 UseCase 7개로 교체한다
- [X] T112 [S3] `sources/Projects/App/ShareExtension/ShareViewController.swift`를 `ShareExtensionComposition`의 새 속성으로 연결한다
- [X] T113 [S2] [S4] App 테스트를 전환한다: `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`, `sources/Projects/App/Tests/GitIt/TestDoubles/AppRootTestSupport.swift`, `sources/Projects/App/Tests/GitIt/TestDoubles/NoopCreateLearningProjectUseCase.swift`, `sources/Projects/App/Tests/GitIt/TestDoubles/NoopDeleteMemberAccountUseCase.swift`, `sources/Projects/App/Tests/GitIt/TestDoubles/NoopFetchExternalRepositoryUseCase.swift`, `sources/Projects/App/Tests/GitIt/TestDoubles/NoopFetchLearningProjectsUseCase.swift`, `sources/Projects/App/Tests/GitIt/TestDoubles/NoopPolicyConsentUseCase.swift`, `sources/Projects/App/Tests/GitIt/TestDoubles/NoopSignInUseCase.swift`, `sources/Projects/App/Tests/GitIt/TestDoubles/RestoreSessionUseCaseMock.swift`, `sources/Projects/App/Tests/GitIt/TestDoubles/SignOutUseCaseMock.swift`, `sources/Projects/App/Tests/GitIt/TestDoubles/TrackGenerationUseCaseMock.swift`, `sources/Projects/App/Tests/GitIt/TestDoubles/VerifyAuthorizationUseCaseMock.swift`, `sources/Projects/App/Tests/GitIt/GitItCompilationTests.swift`, `sources/Projects/App/Tests/GitIt/GitItCompositionLifetimeTests.swift`, `sources/Projects/App/Tests/GitIt/Launch/AppLaunchSequenceTests.swift`, `sources/Projects/App/Tests/GitIt/Loaders/PolicyManifestTests.swift`
- [X] T114 [S2] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`에 퀴즈 닫기 시 `project.refresh()` 1회와 열린 상세 갱신 요청, 답안 제출 시 갱신 없음을 검증하는 테스트를 추가한다
- [X] T115 [no-write] `grep -rln "import DomainAuthentication\|import DomainLearningProject\|import DomainMember" sources/Projects/Feature sources/Projects/App`가 0줄이고 `./tools/package-dependencies/bin/run.sh`가 통과함을 확인한 뒤, 변경 파일과 Feature·App 테스트 실행을 사용자 확인 항목으로 보고한다

---

## U6: 옛 선언 제거 (integration: Domain + Composition + Tuist 헬퍼 + 의존성 검사 설정)

**목표**: 옛 Domain 타깃·UseCase·계약·모델과 이를 조립하던 Composition 코드·공개 속성·테스트를 제거한다(FR-001·002·015·056).

**분리 불가 근거**: 옛 타깃 선언 제거는 그 타깃을 import하는 모든 파일 제거와 같은 커밋이어야 compile되고 `source-roots` 검사가
통과한다.

- [ ] T116 [S1] 옛 Domain 소스·테스트 디렉터리 `sources/Projects/Domain/Authentication/`, `sources/Projects/Domain/LearningProject/`, `sources/Projects/Domain/Member/`, `sources/Projects/Domain/Tests/Authentication/`, `sources/Projects/Domain/Tests/LearningProject/`, `sources/Projects/Domain/Tests/Member/`의 파일을 모두 삭제한다(삭제 전 `git ls-files`로 목록을 기록하고 그 목록만 삭제)
- [ ] T117 [S1] `sources/Tuist/ProjectDescriptionHelpers/Projects/DomainModuleName.swift`, `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`, `sources/Tuist/ProjectDescriptionHelpers/AllTestsScheme.swift`, `tools/package-dependencies/config/source-roots`에서 `DomainAuthentication`·`DomainLearningProject`·`DomainMember`와 테스트 타깃을 제거한다
- [ ] T118 [S1] `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`에서 옛 Domain 의존을 제거한다
- [ ] T119 [S4] Authentication 조립의 옛 코드를 제거한다: `sources/Projects/Composition/Authentication/Adapters/CurrentSessionRepositoryAdapter.swift`, `sources/Projects/Composition/Authentication/Adapters/LoginSessionRepositoryAdapter.swift`, `sources/Projects/Composition/Authentication/Adapters/SharedSignInStateRepositoryAdapter.swift`, `sources/Projects/Composition/Authentication/Adapters/AuthenticationRepositoryAdapter.swift`, `sources/Projects/Composition/Authentication/Adapters/PolicyConsentRepositoryAdapter.swift`, `sources/Projects/Composition/Authentication/Codings/SessionRecordCoding.swift` 삭제, `sources/Projects/Composition/Authentication/Assemblies/AuthenticationAssembly.swift`와 `sources/Projects/Composition/Authentication/Assemblies/SessionAvailabilityAssembly.swift`에서 옛 UseCase 조립 제거
- [ ] T120 [S2] [S3] LearningProject 조립의 옛 코드를 제거한다: `sources/Projects/Composition/LearningProject/Adapters/AnswerRepositoryAdapter.swift`, `sources/Projects/Composition/LearningProject/Adapters/BookmarkRepositoryAdapter.swift`, `sources/Projects/Composition/LearningProject/Adapters/ExternalRepositoryLocatorAdapter.swift`, `sources/Projects/Composition/LearningProject/Adapters/ExternalRepositoryLookupAdapter.swift`, `sources/Projects/Composition/LearningProject/Adapters/GenerationOutcomeRepositoryAdapter.swift`, `sources/Projects/Composition/LearningProject/Adapters/GenerationReminderSchedulerAdapter.swift`, `sources/Projects/Composition/LearningProject/Adapters/LearningProjectRepositoryAdapter.swift`, `sources/Projects/Composition/LearningProject/Adapters/LearningSetRepositoryAdapter.swift`, `sources/Projects/Composition/LearningProject/Adapters/NotificationAuthorizationAdapter.swift`, `sources/Projects/Composition/LearningProject/Adapters/PendingGenerationRepositoryAdapter.swift`, `sources/Projects/Composition/LearningProject/Assemblies/GenerationReminderAssembly.swift` 삭제, `sources/Projects/Composition/LearningProject/Assemblies/LearningProjectAssembly.swift`와 `sources/Projects/Composition/LearningProject/Assemblies/ExternalRepositoryAssembly.swift`에서 옛 UseCase 조립 제거
- [ ] T121 [S5] Member 조립의 옛 코드를 제거한다: `sources/Projects/Composition/Member/Adapters/CurationRepositoryAdapter.swift`, `sources/Projects/Composition/Member/Adapters/MemberRepositoryAdapter.swift`, `sources/Projects/Composition/Member/Adapters/DeviceIdentifierRepositoryAdapter.swift` 삭제, `sources/Projects/Composition/Member/Assemblies/MemberAssembly.swift`에서 옛 UseCase 조립 제거
- [ ] T122 [S1] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`와 `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`에서 integration-surface §3의 제거 대상 공개 속성과 `clearLocalStateAfterAccountDeletion` 조립을 제거한다
- [ ] T123 [S1] 옛 Composition 테스트를 제거·갱신한다: `sources/Projects/Composition/Tests/Authentication/RefreshSessionReleaseBlockerTests.swift`, `sources/Projects/Composition/Tests/Authentication/Adapters/LoginSessionRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/Authentication/Adapters/AuthenticationRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/Authentication/Adapters/PolicyConsentRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Adapters/AnswerRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Adapters/BookmarkRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Adapters/ExternalRepositoryLookupAdapterTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Adapters/GenerationOutcomeRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Adapters/LearningProjectRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Adapters/LearningSetRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Adapters/PendingGenerationRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/Member/Adapters/MemberRepositoryAdapterTests.swift` 삭제 또는 새 어댑터 대상으로 이름·내용 이전(같은 경로의 새 이름 파일: `sources/Projects/Composition/Tests/LearningProject/Adapters/QuizAnswerRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Adapters/QuizBookmarkRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Adapters/QuizSetRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Adapters/ProjectGenerationPendingRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Adapters/ProjectGenerationOutcomeRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Adapters/ResolverExternalRepositoryLookupAdapterTests.swift`)
- [ ] T124 [S1] 남은 Composition 테스트를 새 표면에 맞춘다: `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionPublicSurfaceTests.swift`, `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionTests.swift`, `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionSharedLifetimeTests.swift`, `sources/Projects/Composition/Tests/App/SharedLifetimeTests.swift`, `sources/Projects/Composition/Tests/Authentication/Assemblies/AuthenticationAssemblyTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Assemblies/LearningProjectAssemblyTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Assemblies/ExternalRepositoryAssemblyTests.swift`, `sources/Projects/Composition/Tests/ShareExtension/ShareExtensionCompositionTests.swift`
- [ ] T125 [S1] 옛 이름 접미사로 만든 새 어댑터 이름을 정리한다: `sources/Projects/Composition/Authentication/Adapters/AccountAuthenticationRepositoryAdapter.swift` → `sources/Projects/Composition/Authentication/Adapters/AuthenticationRepositoryAdapter.swift`, `sources/Projects/Composition/Authentication/Adapters/AccountPolicyConsentRepositoryAdapter.swift` → `sources/Projects/Composition/Authentication/Adapters/PolicyConsentRepositoryAdapter.swift`, `sources/Projects/Composition/Member/Adapters/AppSettingDeviceIdentifierRepositoryAdapter.swift` → `sources/Projects/Composition/Member/Adapters/DeviceIdentifierRepositoryAdapter.swift`, `sources/Projects/Composition/LearningProject/Adapters/AppSettingNotificationAuthorizationAdapter.swift` → `sources/Projects/Composition/LearningProject/Adapters/NotificationAuthorizationAdapter.swift`, `sources/Projects/Composition/LearningProject/Adapters/ResolverExternalRepositoryLocatorAdapter.swift` → `sources/Projects/Composition/LearningProject/Adapters/ExternalRepositoryLocatorAdapter.swift`, `sources/Projects/Composition/LearningProject/Adapters/ResolverExternalRepositoryLookupAdapter.swift` → `sources/Projects/Composition/LearningProject/Adapters/ExternalRepositoryLookupAdapter.swift`, `sources/Projects/Composition/LearningProject/Adapters/ProjectGenerationOutcomeRepositoryAdapter.swift` → `sources/Projects/Composition/LearningProject/Adapters/GenerationOutcomeRepositoryAdapter.swift`, `sources/Projects/Composition/LearningProject/Adapters/ProjectGenerationReminderSchedulerAdapter.swift` → `sources/Projects/Composition/LearningProject/Adapters/GenerationReminderSchedulerAdapter.swift`, `sources/Projects/Composition/LearningProject/Adapters/ProjectGenerationPendingRepositoryAdapter.swift` → `sources/Projects/Composition/LearningProject/Adapters/PendingGenerationRepositoryAdapter.swift` 및 대응 테스트 `sources/Projects/Composition/Tests/LearningProject/Adapters/ResolverExternalRepositoryLookupAdapterTests.swift` → `sources/Projects/Composition/Tests/LearningProject/Adapters/ExternalRepositoryLookupAdapterTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Adapters/ProjectGenerationOutcomeRepositoryAdapterTests.swift` → `sources/Projects/Composition/Tests/LearningProject/Adapters/GenerationOutcomeRepositoryAdapterTests.swift`, `sources/Projects/Composition/Tests/LearningProject/Adapters/ProjectGenerationPendingRepositoryAdapterTests.swift` → `sources/Projects/Composition/Tests/LearningProject/Adapters/PendingGenerationRepositoryAdapterTests.swift` (타입 이름 포함, 동작 변경 없음)
- [ ] T126 [S1] `sources/Projects/Domain/Authentication/README.md`를 삭제한다(T116 디렉터리 정리)
- [ ] T127 [no-write] [quickstart.md](./quickstart.md) 1절의 구조 검증 명령 5개가 모두 기대 결과를 내고 `./tools/package-dependencies/bin/run.sh`가 통과함을 확인한 뒤 변경 파일과 전체 테스트 실행을 사용자 확인 항목으로 보고한다

---

## U7: 규칙 문서 갱신 (문서)

**목표**: 새 Domain 타깃 구성과 `DomainIdentifier` 예외 규칙을 규칙 문서에 기록한다(FR-008).

- [ ] T128 [P] [S1] `docs/package-rules/domain.md`의 "통합 후 남은 UseCase" 절을 관심사 UseCase 7개·타깃 구성표·`DomainIdentifier` 규칙(식별자 `typealias`만, 관심사 타깃이 import할 수 있는 유일한 Domain 타깃)으로 교체하고, 제약조건에 타깃 간 import 금지를 추가한다
- [ ] T129 [P] [S1] `docs/package-rules/composition.md`의 "Target 구성"과 "이동 후 남는 책임과 남지 않는 책임" 표의 Domain 타깃 이름을 새 이름으로 바꾸고 `RequestCredentialProvider` 연결 책임을 추가한다
- [ ] T130 [P] [S1] `docs/conventions/directory-file/production-source-root.md`의 예시를 `DomainAccount` → `Domain/Account/`로 바꾼다
- [ ] T131 [no-write] 세 문서의 링크와 표 형식을 확인하고 결과를 보고한다

---

## 전체 검증

- [ ] T132 [no-write] `make tuist` 전후 `git status --porcelain`을 비교해 추적 파일 변경이 없음을 확인한다
- [ ] T133 [no-write] [quickstart.md](./quickstart.md) 1절 구조 검증 전체를 다시 실행해 SC-001·002·004·007을 확인한다
- [ ] T134 [no-write] 명세 수용 시나리오 S2–S4 각각에 대응하는 테스트 파일(T014, T015, T037, T044, T057, T063, T096, T114)이 존재함을 확인해 SC-005 추적표를 보고한다
- [ ] T135 [no-write] 프로젝트 `build`·`compile`·`test` 실행기와 quickstart 4절 수동 확인을 사용자 확인 항목으로 보고한다(SC-006)

## 의존성과 시나리오 완료 순서

- U1 → U2 → U3 → U4 → U5 → U6 → U7 → 전체 검증
- S1(구조): U1에서 시작, U6에서 완료
- S2(목록 공유): U1 T034–T037 → U4 T077·T080 → U5 T100·T101·T107·T114
- S3(생성): U1 T038–T044 → U4 T078·T080·T082 → U5 T102·T103·T107·T109·T112
- S4(로그인 무효): U1 T007·T012·T014 → U3 전체 → U4 T071 → U5 T090·T107
- S5(회귀): 각 관심사 U1 작업 → U2 → U4 어댑터 → U5 전환

## 실행 단위 내부 병렬 예시

- U1: T005·T006·T007·T008·T009·T017·T018·T021·T022·T025·T028·T029·T030·T031·T034·T035·T038·T039·T040은 서로 다른 파일의 모델·계약
  선언이므로 동시에 작성할 수 있다. 각 UseCase 구현(T012, T019, T023, T026, T032, T036, T041)은 자기 관심사 모델 작업 뒤에 진행한다.
- U4: T084·T085·T086·T087은 서로 다른 테스트 파일이다.
- U7: T128·T129·T130은 서로 다른 문서다.

## 위험 기반 승인 조건

- **구현 시작 전 확인 필요**: research R-13의 사용자 소유 미커밋 변경 31개 파일 중 이 작업 목록의 경로와 겹치는 파일
  (`sources/Projects/Composition/Tests/**`, `sources/Projects/Data/Tests/**`의 테스트 대역·어댑터 테스트,
  `sources/Projects/Domain/Tests/LearningProject/UseCases/CreateLearningProjectTests.swift`,
  `sources/Projects/Feature/Tests/Home/Home/HomeFeatureGenerationOutcomeTests.swift`)의 처리 방법.
- 그 밖의 단위 전환은 같은 기능 범위이므로 반복 승인 없이 진행한다. 서버 API 형식 변경, 새 제품 결정(알림 문구 이외의 UI 변경)이
  필요해지면 중단하고 확인한다.

## 변경 시나리오 추적 전략

각 작업의 `[S#]` 라벨로 명세 시나리오를 추적하고, 전체 검증 T134에서 시나리오별 테스트 파일 존재를 표로 보고한다.

---

## 단계 8: 수렴

**목표**: U5 전환 중 tasks.md에 경로가 없어 남은 Feature 파일을 새 Domain API로 맞춰 Feature 타깃이 컴파일되게 한다.

**분리 불가 근거**: 아래 파일은 U5에서 이미 바뀐 Feature 공개 타입(`ProjectList`, `ProjectDetail`, `QuizBookmarkList`,
`UserProfile`, `PolicyDocument`)을 직접 참조하므로, 같은 커밋 안에서 함께 바꿔야 Feature 패키지가 compile된다.

### 작업 패키지: Feature

- [X] T136 [S2] `sources/Projects/Feature/Home/ViewModels/HomeProjectSectionState.swift`가 `HomeFeature.State.ProjectLoad.loaded`의 `ProjectList.summaries`를 쓰도록 바꾼다 (partial, FR-035)
- [X] T137 [S2] `sources/Projects/Feature/ProjectDetail/ProjectDetailScreen.swift`가 `ProjectDetail.repository.*`와 `progressPercent`를 쓰도록 바꾼다 (partial, FR-035)
- [X] T138 [S2] `sources/Projects/Feature/ProjectList/ProjectListScreen.swift`가 `ProjectSummary.id`를 쓰도록 바꾼다 (partial, FR-035)
- [X] T139 [S5] `sources/Projects/Feature/Saved/SavedScreen.swift`가 `QuizBookmarkList.projects`와 `QuizBookmark.quizID`를 쓰도록 바꾼다 (partial, FR-035)
- [X] T140 [S5] `sources/Projects/Feature/Settings/Settings/SettingsScreen.swift`가 `UserProfile.curation?.position`·`careerLevel`을 쓰도록 바꾼다 (partial, FR-035)
- [X] T141 [S5] `sources/Projects/Feature/Onboarding/LegalAgreement/Previews/LegalAgreementScreenPreviews.swift`가 `PolicyDocument.id`를 쓰도록 바꾼다 (partial, FR-035)
- [X] T142 [S2] `sources/Projects/Feature/Tests/Home/Home/HomeFeatureLoadTests.swift`를 새 `HomeFeature` init과 `ProjectList` 스트림 기준으로 전환한다 (missing, SC-005)
- [X] T143 [S2] `sources/Projects/Feature/Tests/Home/Home/HomeFeatureNavigationTests.swift`를 새 `HomeFeature` init과 `ProjectSummary`로 전환한다 (missing, SC-005)
- [X] T144 [S2] `sources/Projects/Feature/Tests/Home/Home/HomeFeatureGenerationProgressTests.swift`를 새 `HomeFeature` init과 `generationProgressChanged` 입력 기준으로 전환한다 (missing, SC-005)
- [X] T145 [S5] `sources/Projects/Feature/Tests/Home/Home/ViewModels/HomeProfileDisplayTests.swift`를 `UserProfile`·`Curation` 기준과 현재 `HomeProfileDisplay` 출력 기준으로 전환한다 (missing, SC-005)
- [X] T146 [S2] `sources/Projects/Feature/Tests/Home/Home/ViewModels/HomeProjectSectionStateTests.swift`를 `ProjectList`·`ProjectSummary` 픽스처로 전환한다 (missing, SC-005)
- [X] T147 [S5] `sources/Projects/Feature/Tests/Settings/Profile/ProfileFeatureTests.swift`를 새 `ProfileFeature(profile:)`과 `UserProfile`·`UserInfoError`로 전환한다 (missing, SC-005)
- [X] T148 [S5] `sources/Projects/Feature/Tests/Settings/Settings/SettingsFeatureAccountActionTests.swift`를 새 `SettingsFeature` init(`profile`·`withdraw`·`notificationAuthorization`)으로 전환한다 (missing, SC-005)

### 전체 수렴 완료 검증

- [ ] T149 [no-write] `grep -rln "import DomainAuthentication\|import DomainLearningProject\|import DomainMember" sources/Projects/Feature sources/Projects/App`가 0줄이고 `./tools/package-dependencies/bin/run.sh`가 통과함을 확인한다
- [ ] T150 [no-write] 프로젝트 `build`·`compile`·`test` 실행기와 변경 시나리오 S2·S3·S5 수용 기준 재확인을 사용자 확인 항목으로 보고한다
