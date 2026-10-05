---

description: "Domain 패키지 target의 UseCase 역할 기준 재구성 작업 목록"
---

# 작업 목록: Domain 패키지 target의 UseCase 역할 기준 재구성

**입력**: `/specs/050-domain-usecase-role-targets/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/domain-targets.md](./contracts/domain-targets.md),
[quickstart.md](./quickstart.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를
snapshot한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만
선택한다.

**테스트**: 명세가 새 테스트를 요구하지 않는다. 기존 테스트는 import만 갱신하고 내용과 위치를
바꾸지 않는다.

**구성**: 실행 단위를 최상위 구조로 사용하고 변경 시나리오는 각 단위 안에서 추적한다. 이 기능에
남은 구현은 불가분한 다중 패키지 integration unit 하나다. 규칙 문서 개정은 이 작업 목록을 만들기
전에 끝났다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[시나리오]**: 작업이 지원하는 변경 시나리오(S1, S2, S3)
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 실행 또는 수동
  검증. `make tuist`의 파생 workspace·project·심볼릭 링크·cache 갱신은 허용하되 실행 전후
  Git 상태를 비교하고 추적 파일 변경이 생기면 완료로 처리하지 않는다.
- 파일 변경 작업은 정확한 저장소 상대 경로와 책임 단위를 가진다. 한 작업이 여러 파일을 다루면
  기준 디렉터리와 그 아래 파일 이름을 모두 적는다. 적히지 않은 파일은 고치지 않는다.
- "Domain 모듈 import"는 옛 모듈 `DomainIdentifier`, `DomainAccount`, `DomainUserInfo`,
  `DomainAppSetting`, `DomainExternalRepository`, `DomainQuizDetail`, `DomainProject`,
  `DomainProjectGeneration`과 새 역할 모듈 `DomainUseCaseInterface`, `DomainUseCaseDependency`,
  `DomainUseCaseImplementation`의 `import`·`@testable import` 줄을 가리킨다.
- "Domain 모듈 import가 …만 남게 한다"는 옛 Domain 모듈 import를 모두 지우고 적힌 줄만 두라는
  뜻이다. 적힌 줄이 없던 파일에는 추가한다. import 블록의 순서는 기존 관행(일반 import
  알파벳순, 그 뒤 `@testable` 알파벳순)을 유지한다([research.md R-05](./research.md#r-05-import-갱신-규칙)).
- 경로와 target 이름은 [plan.md](./plan.md)의 "적용 컨벤션"과
  [Domain 패키지 규칙 — 역할별 타깃 구성](../../docs/package-rules/domain.md#역할별-타깃-구성)으로
  확인한 값이다.

## 실행 단위 순서

[아키텍처 문서 3.1](../../docs/architecture.md)의 의존 방향은 Domain → (Composition, Feature) → App이다.

- **완료된 선행 단위** — 규칙 문서 개정. 커밋 `4d13a76`, `2c3ca6e`가 규칙 문서 다섯 개를 네 역할
  target 구조로 고쳤다(FR-014~FR-018). 이 작업 목록에는 그 결과를 확인하는 `[no-write]` 검증만 둔다.
1. **실행 단위 1** — Domain target 재구성. Domain과 그 소비 패키지, Tuist 헬퍼, 검사 설정을 함께
   바꾼다. 단위 안의 작업 순서는 위상 순서(Domain → Tuist 헬퍼 → Composition → Feature → App)를
   따른다. Composition과 Feature는 서로 의존하지 않으며 이 문서는 Composition을 먼저 둔다.
   구현을 조립하는 쪽을 먼저 고쳐 Implementation target의 사용처를 일찍 확인하기 위해서다.
2. **전체 완료 검증** — `[no-write]`만. 실행 단위 1의 커밋에 포함한다.

---

## 실행 단위 1: Domain target 재구성 (integration unit: Domain, Composition, Feature, App, Tuist 헬퍼, 의존성 검사 설정)

**목표**: 관심사별 Domain target 16개를 역할별 target 4개로 바꾸고, 모든 소비 지점이 새 모듈
이름과 실제로 쓰는 역할 target만 참조하게 한다.

**분리 불가 근거**: 옛 target을 지우면 그 모듈을 import하는 모든 파일이 compile되지 않는다. 새
target은 소스가 새 소스 루트에 있어야 선언할 수 있다. `source-roots`는 매니페스트와 1:1이 아니면
의존성 검사가 실패한다([research.md R-04](./research.md#r-04-실행-단위)).

**소유 경로**: `sources/Projects/Domain/`, `sources/Projects/Composition/`,
`sources/Projects/Feature/`, `sources/Projects/App/` 아래 이 단위의 작업에 적힌 파일,
`sources/Tuist/ProjectDescriptionHelpers/`의 여섯 파일,
`.tools/package-dependencies/config/source-roots`

**관련 변경 시나리오**: S2, S3

**통합 검증**: workspace 재생성, 패키지 의존성 검사, 옛 target 이름 검색,
build 실행기의 `compile`

### 준비와 기반

- [ ] T001 [no-write] 기준 상태를 확인하고 보고한다. `git status --short`가 비어 있는지, test 소스 루트별 `@Test` 선언 수가 [research.md R-09](./research.md#r-09-테스트-수-기준선)의 기준선(Domain 129, Feature 421, Composition 59, App 70, Data 195, Infrastructure 59, UI 126)과 같은지, `./.tools/package-dependencies/bin/run.sh`가 위반 0건으로 끝나는지 확인한다

### Domain 소스 이동과 import 갱신

아래 작업의 이동은 `git mv`로 하고 하위 경로(형태 폴더와 타입 패밀리 폴더)를 그대로 유지한다. 파일 내용은 적힌 import 변경 외에는 바꾸지 않는다. 한 관심사의 이동이 모두 끝나 비게 된 옛 관심사 폴더(`sources/Projects/Domain/<관심사>/`)는 지운다.

- [ ] T002 [P] [S2] `sources/Projects/Domain/Identifier/` 아래 파일 4개를 `sources/Projects/Domain/UseCaseInterface/Identifier/` 아래 같은 하위 경로로 옮긴다: `Models/ExternalRepositoryURL.swift`, `Models/ProjectID.swift`, `Models/QuizID.swift`, `Models/QuizSetID.swift`. import 변경은 없다.
- [ ] T003 [P] [S2] `sources/Projects/Domain/Account/` 아래 파일 17개를 `sources/Projects/Domain/UseCaseInterface/Account/` 아래 같은 하위 경로로 옮긴다: `Errors/AccountError.swift`, `Models/PolicyConsent/PolicyConsent.swift`, `Models/PolicyConsent/PolicyConsentStatus.swift`, `Models/PolicyConsent/PolicyDocument.swift`, `Models/PolicyConsent/PolicyDocumentID.swift`, `Models/SignIn/AccountID.swift`, `Models/SignIn/AuthenticationGrant.swift`, `Models/SignIn/SignInAvailability.swift`, `Models/SignIn/SignInMethod.swift`, `Models/SignIn/SignInRecord.swift`, `Models/SignIn/SignInRestoration.swift`, `Models/SignIn/SignInResult.swift`, `Models/SignIn/SignInState.swift`, `Models/SignIn/SignInVerification.swift`, `Models/SignIn/SignOutResult.swift`, `Models/SignIn/SignedInAccount.swift`, `UseCases/AccountUseCase.swift`. import 변경은 없다.
- [ ] T004 [P] [S2] `sources/Projects/Domain/Account/` 아래 파일 4개를 `sources/Projects/Domain/UseCaseDependency/Account/` 아래 같은 하위 경로로 옮긴다: `Contracts/AuthenticationRepository.swift`, `Contracts/PolicyConsentRepository.swift`, `Contracts/SignInRepository.swift`, `Contracts/WithdrawalRepository.swift`. 이 중 import가 바뀌는 파일: `Contracts/AuthenticationRepository.swift`, `Contracts/PolicyConsentRepository.swift`, `Contracts/SignInRepository.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T005 [P] [S2] `sources/Projects/Domain/Account/` 아래 파일 1개를 `sources/Projects/Domain/UseCaseImplementation/Account/` 아래 같은 하위 경로로 옮긴다: `UseCases/Account.swift`. 이 중 import가 바뀌는 파일: `UseCases/Account.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `import DomainUseCaseInterface`만 남게 한다.
- [ ] T006 [P] [S2] `sources/Projects/Domain/UserInfo/` 아래 파일 9개를 `sources/Projects/Domain/UseCaseInterface/UserInfo/` 아래 같은 하위 경로로 옮긴다: `Errors/UserInfoError.swift`, `Models/CareerLevel.swift`, `Models/Curation.swift`, `Models/LearningStatistics.swift`, `Models/MemberPosition.swift`, `Models/UserDetail.swift`, `Models/UserProfile.swift`, `Models/WeeklyLearningCount.swift`, `UseCases/UserInfoUseCase.swift`. import 변경은 없다.
- [ ] T007 [P] [S2] `sources/Projects/Domain/UserInfo/` 아래 파일 1개를 `sources/Projects/Domain/UseCaseDependency/UserInfo/` 아래 같은 하위 경로로 옮긴다: `Contracts/UserInfoRepository.swift`. 이 중 import가 바뀌는 파일: `Contracts/UserInfoRepository.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T008 [P] [S2] `sources/Projects/Domain/UserInfo/` 아래 파일 1개를 `sources/Projects/Domain/UseCaseImplementation/UserInfo/` 아래 같은 하위 경로로 옮긴다: `UseCases/UserInfo.swift`. 이 중 import가 바뀌는 파일: `UseCases/UserInfo.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `import DomainUseCaseInterface`만 남게 한다.
- [ ] T009 [P] [S2] `sources/Projects/Domain/AppSetting/` 아래 파일 7개를 `sources/Projects/Domain/UseCaseInterface/AppSetting/` 아래 같은 하위 경로로 옮긴다: `Errors/AppSettingError.swift`, `Models/DeviceID.swift`, `Models/DevicePlatform.swift`, `Models/DeviceRegistration.swift`, `Models/DeviceToken.swift`, `Models/NotificationAuthorizationStatus.swift`, `UseCases/AppSettingUseCase.swift`. import 변경은 없다.
- [ ] T010 [P] [S2] `sources/Projects/Domain/AppSetting/` 아래 파일 3개를 `sources/Projects/Domain/UseCaseDependency/AppSetting/` 아래 같은 하위 경로로 옮긴다: `Contracts/DeviceIdentifierRepository.swift`, `Contracts/DeviceRegistrationRepository.swift`, `Contracts/NotificationAuthorization.swift`. 이 중 import가 바뀌는 파일: `Contracts/DeviceIdentifierRepository.swift`, `Contracts/DeviceRegistrationRepository.swift`, `Contracts/NotificationAuthorization.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T011 [P] [S2] `sources/Projects/Domain/AppSetting/` 아래 파일 1개를 `sources/Projects/Domain/UseCaseImplementation/AppSetting/` 아래 같은 하위 경로로 옮긴다: `UseCases/AppSetting.swift`. 이 중 import가 바뀌는 파일: `UseCases/AppSetting.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `import DomainUseCaseInterface`만 남게 한다.
- [ ] T012 [P] [S2] `sources/Projects/Domain/ExternalRepository/` 아래 파일 4개를 `sources/Projects/Domain/UseCaseInterface/ExternalRepository/` 아래 같은 하위 경로로 옮긴다: `Errors/ExternalRepositoryError.swift`, `Models/ExternalRepository.swift`, `Models/ExternalRepositoryLocation.swift`, `UseCases/ExternalRepositoryUseCase.swift`. 이 중 import가 바뀌는 파일: `Models/ExternalRepository.swift`, `UseCases/ExternalRepositoryUseCase.swift` — Domain 모듈 import를 모두 지운다.
- [ ] T013 [P] [S2] `sources/Projects/Domain/ExternalRepository/` 아래 파일 2개를 `sources/Projects/Domain/UseCaseDependency/ExternalRepository/` 아래 같은 하위 경로로 옮긴다: `Contracts/ExternalRepositoryLocator.swift`, `Contracts/ExternalRepositoryLookup.swift`. 이 중 import가 바뀌는 파일: `Contracts/ExternalRepositoryLocator.swift`, `Contracts/ExternalRepositoryLookup.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T014 [P] [S2] `sources/Projects/Domain/ExternalRepository/` 아래 파일 1개를 `sources/Projects/Domain/UseCaseImplementation/ExternalRepository/` 아래 같은 하위 경로로 옮긴다: `UseCases/ExternalRepositoryResolver.swift`. 이 중 import가 바뀌는 파일: `UseCases/ExternalRepositoryResolver.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `import DomainUseCaseInterface`만 남게 한다.
- [ ] T015 [P] [S2] `sources/Projects/Domain/QuizDetail/` 아래 파일 17개를 `sources/Projects/Domain/UseCaseInterface/QuizDetail/` 아래 같은 하위 경로로 옮긴다: `Errors/QuizDetailError.swift`, `Models/Bookmark/QuizBookmark.swift`, `Models/Bookmark/QuizBookmarkFilter.swift`, `Models/Bookmark/QuizBookmarkList.swift`, `Models/Bookmark/QuizBookmarkProject.swift`, `Models/Bookmark/QuizBookmarkState.swift`, `Models/Grading/ChoiceAnswer.swift`, `Models/Grading/ChoiceGrading.swift`, `Models/Grading/EssayAnswer.swift`, `Models/Grading/EssayGrading.swift`, `Models/Quiz/ChoiceSubmission.swift`, `Models/Quiz/EssaySubmission.swift`, `Models/Quiz/Quiz.swift`, `Models/Quiz/QuizContent.swift`, `Models/Quiz/QuizSet.swift`, `Models/Quiz/QuizSource.swift`, `UseCases/QuizDetailUseCase.swift`. 이 중 import가 바뀌는 파일: `Models/Bookmark/QuizBookmark.swift`, `Models/Bookmark/QuizBookmarkFilter.swift`, `Models/Bookmark/QuizBookmarkProject.swift`, `Models/Bookmark/QuizBookmarkState.swift`, `Models/Grading/ChoiceAnswer.swift`, `Models/Grading/EssayAnswer.swift`, `Models/Quiz/Quiz.swift`, `Models/Quiz/QuizSet.swift`, `UseCases/QuizDetailUseCase.swift` — Domain 모듈 import를 모두 지운다.
- [ ] T016 [P] [S2] `sources/Projects/Domain/QuizDetail/` 아래 파일 3개를 `sources/Projects/Domain/UseCaseDependency/QuizDetail/` 아래 같은 하위 경로로 옮긴다: `Contracts/AnswerRepository.swift`, `Contracts/BookmarkRepository.swift`, `Contracts/QuizSetRepository.swift`. 이 중 import가 바뀌는 파일: `Contracts/AnswerRepository.swift`, `Contracts/BookmarkRepository.swift`, `Contracts/QuizSetRepository.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T017 [P] [S2] `sources/Projects/Domain/QuizDetail/` 아래 파일 1개를 `sources/Projects/Domain/UseCaseImplementation/QuizDetail/` 아래 같은 하위 경로로 옮긴다: `UseCases/QuizDetail.swift`. 이 중 import가 바뀌는 파일: `UseCases/QuizDetail.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `import DomainUseCaseInterface`만 남게 한다.
- [ ] T018 [P] [S2] `sources/Projects/Domain/Project/` 아래 파일 10개를 `sources/Projects/Domain/UseCaseInterface/Project/` 아래 같은 하위 경로로 옮긴다: `Errors/ProjectError.swift`, `Models/ProjectDetail.swift`, `Models/ProjectList.swift`, `Models/ProjectNextQuiz.swift`, `Models/ProjectPage.swift`, `Models/ProjectRepositoryInfo.swift`, `Models/ProjectSetLabel.swift`, `Models/ProjectSetProgress.swift`, `Models/ProjectSummary.swift`, `UseCases/ProjectUseCase.swift`. 이 중 import가 바뀌는 파일: `Models/ProjectDetail.swift`, `Models/ProjectNextQuiz.swift`, `Models/ProjectSetProgress.swift`, `Models/ProjectSummary.swift`, `UseCases/ProjectUseCase.swift` — Domain 모듈 import를 모두 지운다.
- [ ] T019 [P] [S2] `sources/Projects/Domain/Project/` 아래 파일 1개를 `sources/Projects/Domain/UseCaseDependency/Project/` 아래 같은 하위 경로로 옮긴다: `Contracts/ProjectRepository.swift`. 이 중 import가 바뀌는 파일: `Contracts/ProjectRepository.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T020 [P] [S2] `sources/Projects/Domain/Project/` 아래 파일 1개를 `sources/Projects/Domain/UseCaseImplementation/Project/` 아래 같은 하위 경로로 옮긴다: `UseCases/Project.swift`. 이 중 import가 바뀌는 파일: `UseCases/Project.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `import DomainUseCaseInterface`만 남게 한다.
- [ ] T021 [P] [S2] `sources/Projects/Domain/ProjectGeneration/` 아래 파일 12개를 `sources/Projects/Domain/UseCaseInterface/ProjectGeneration/` 아래 같은 하위 경로로 옮긴다: `Errors/ProjectGenerationError.swift`, `Models/GenerationWaitPolicy.swift`, `Models/ProjectGenerationPhase.swift`, `Models/ProjectGenerationReceipt.swift`, `Models/ProjectGenerationRequest.swift`, `Models/ProjectGenerationRequestState.swift`, `Models/ProjectGenerationState.swift`, `Models/QuizLevel.swift`, `Models/Records/GenerationOutcome.swift`, `Models/Records/GenerationRecord.swift`, `Models/Records/GenerationState.swift`, `UseCases/ProjectGenerationUseCase.swift`. 이 중 import가 바뀌는 파일: `Models/ProjectGenerationReceipt.swift`, `Models/ProjectGenerationRequest.swift`, `Models/ProjectGenerationRequestState.swift`, `Models/Records/GenerationOutcome.swift`, `Models/Records/GenerationRecord.swift`, `Models/Records/GenerationState.swift`, `UseCases/ProjectGenerationUseCase.swift` — Domain 모듈 import를 모두 지운다.
- [ ] T022 [P] [S2] `sources/Projects/Domain/ProjectGeneration/` 아래 파일 3개를 `sources/Projects/Domain/UseCaseDependency/ProjectGeneration/` 아래 같은 하위 경로로 옮긴다: `Contracts/GenerationOutcomeRepository.swift`, `Contracts/PendingGenerationRepository.swift`, `Contracts/ProjectGenerationRepository.swift`. 이 중 import가 바뀌는 파일: `Contracts/GenerationOutcomeRepository.swift`, `Contracts/PendingGenerationRepository.swift`, `Contracts/ProjectGenerationRepository.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T023 [P] [S2] `sources/Projects/Domain/ProjectGeneration/` 아래 파일 1개를 `sources/Projects/Domain/UseCaseImplementation/ProjectGeneration/` 아래 같은 하위 경로로 옮긴다: `UseCases/ProjectGeneration.swift`. 이 중 import가 바뀌는 파일: `UseCases/ProjectGeneration.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `import DomainUseCaseInterface`만 남게 한다.

### Domain 테스트 import 갱신

아래 작업의 파일은 옮기지 않는다.

- [ ] T024 [P] [S2] `sources/Projects/Domain/Tests/Identifier/` 아래 파일 1개의 import를 갱신한다: `Models/IdentifierTests.swift` — Domain 모듈 import가 `@testable import DomainUseCaseInterface`만 남게 한다.
- [ ] T025 [P] [S2] `sources/Projects/Domain/Tests/Account/` 아래 파일 7개의 import를 갱신한다: `TestDoubles/InMemoryPolicyConsentRepository.swift`, `TestDoubles/StubAuthenticationRepository.swift`, `TestDoubles/StubSignInRepository.swift`, `TestDoubles/StubWithdrawalRepository.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `@testable import DomainUseCaseInterface`만 남게 한다; `UseCases/AccountAvailabilityTests.swift` — Domain 모듈 import가 `@testable import DomainUseCaseImplementation`만 남게 한다; `UseCases/AccountPolicyConsentTests.swift`, `UseCases/AccountTests.swift` — Domain 모듈 import가 `@testable import DomainUseCaseImplementation`, `@testable import DomainUseCaseInterface`만 남게 한다.
- [ ] T026 [P] [S2] `sources/Projects/Domain/Tests/UserInfo/` 아래 파일 2개의 import를 갱신한다: `TestDoubles/StubUserInfoRepository.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `@testable import DomainUseCaseInterface`만 남게 한다; `UseCases/UserInfoTests.swift` — Domain 모듈 import가 `@testable import DomainUseCaseImplementation`, `@testable import DomainUseCaseInterface`만 남게 한다.
- [ ] T027 [P] [S2] `sources/Projects/Domain/Tests/AppSetting/` 아래 파일 3개의 import를 갱신한다: `TestDoubles/SpyDeviceRegistrationRepository.swift`, `TestDoubles/StubNotificationAuthorization.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `@testable import DomainUseCaseInterface`만 남게 한다; `UseCases/AppSettingTests.swift` — Domain 모듈 import가 `@testable import DomainUseCaseImplementation`, `@testable import DomainUseCaseInterface`만 남게 한다.
- [ ] T028 [P] [S2] `sources/Projects/Domain/Tests/ExternalRepository/` 아래 파일 3개의 import를 갱신한다: `TestDoubles/StubExternalRepositoryLocator.swift`, `TestDoubles/StubExternalRepositoryLookup.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `@testable import DomainUseCaseInterface`만 남게 한다; `UseCases/ExternalRepositoryResolverTests.swift` — Domain 모듈 import가 `@testable import DomainUseCaseImplementation`, `@testable import DomainUseCaseInterface`만 남게 한다.
- [ ] T029 [P] [S2] `sources/Projects/Domain/Tests/QuizDetail/` 아래 파일 5개의 import를 갱신한다: `TestDoubles/SpyAnswerRepository.swift`, `TestDoubles/SpyBookmarkRepository.swift`, `TestDoubles/StubQuizSetRepository.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `@testable import DomainUseCaseInterface`만 남게 한다; `UseCases/QuizDetailBookmarkTests.swift`, `UseCases/QuizDetailGradingTests.swift` — Domain 모듈 import가 `@testable import DomainUseCaseImplementation`, `@testable import DomainUseCaseInterface`만 남게 한다.
- [ ] T030 [P] [S2] `sources/Projects/Domain/Tests/Project/` 아래 파일 2개의 import를 갱신한다: `TestDoubles/StubProjectRepository.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `@testable import DomainUseCaseInterface`만 남게 한다; `UseCases/ProjectTests.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `@testable import DomainUseCaseImplementation`, `@testable import DomainUseCaseInterface`만 남게 한다.
- [ ] T031 [P] [S2] `sources/Projects/Domain/Tests/ProjectGeneration/` 아래 파일 7개의 import를 갱신한다: `Models/GenerationStateTests.swift`, `Models/GenerationWaitPolicyTests.swift`, `Models/ProjectGenerationStateTests.swift` — Domain 모듈 import가 `@testable import DomainUseCaseInterface`만 남게 한다; `TestDoubles/InMemoryPendingGenerationRepository.swift`, `TestDoubles/StubGenerationOutcomeRepository.swift`, `TestDoubles/StubProjectGenerationRepository.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `@testable import DomainUseCaseInterface`만 남게 한다; `UseCases/ProjectGenerationTests.swift` — Domain 모듈 import가 `@testable import DomainUseCaseImplementation`, `@testable import DomainUseCaseInterface`만 남게 한다.

### Tuist 헬퍼와 검사 설정

- [ ] T032 [S2] [S3] `sources/Tuist/ProjectDescriptionHelpers/Projects/DomainModuleName.swift`의 `DomainModuleName` case를 `DomainUseCaseInterface`, `DomainUseCaseDependency`, `DomainUseCaseImplementation`, `DomainTests` 네 개로 바꾸고 옛 case 16개와 그 target 분기를 지운다. `sourceDirectory`는 `rawValue.droppingPrefix(ProjectName.Domain.rawValue)`로 계산하고 `DomainTests`만 `droppingSuffix("Tests")`를 더 적용하며 문자열 리터럴 경로를 쓰지 않는다. target 선언과 Domain 안의 의존은 [contracts/domain-targets.md](./contracts/domain-targets.md#domain-target-선언)의 표를 따른다(production은 `.module`, `DomainTests`는 `productionTarget`이 `DomainUseCaseImplementation`이고 `additionalDependencies`가 `DomainUseCaseInterface`와 `DomainUseCaseDependency`인 `.testModule`). `fromDomain` helper는 그대로 둔다
- [ ] T033 [S2] `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 `.Domain` scheme에서 `buildTargets`를 `DomainUseCaseInterface`, `DomainUseCaseDependency`, `DomainUseCaseImplementation`으로, `testTargets`를 `DomainTests` 하나로 바꾼다
- [ ] T034 [S2] `sources/Tuist/ProjectDescriptionHelpers/AllTestsScheme.swift`에서 옛 Domain test target 8개 항목을 `DomainModuleName.DomainTests` 항목 하나로 바꾼다
- [ ] T035 [S2] [S3] `.tools/package-dependencies/config/source-roots`의 Domain 구간 16줄을 [contracts/domain-targets.md](./contracts/domain-targets.md#검사-설정)의 네 줄로 바꾼다

### Composition

- [ ] T036 [S3] `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`의 production target 다섯 개에서 `.fromDomain(…)` 선언을 [contracts/domain-targets.md](./contracts/domain-targets.md#소비-target의-의존-선언)의 표대로 바꾼다(`CompositionAuthentication`: Interface·Dependency, `CompositionLearningProject`와 `CompositionMember`: Interface·Dependency·Implementation, `CompositionApp`: Interface·Implementation, `CompositionShareExtension`: Interface·Dependency). `.fromData(…)` 선언, 같은 패키지 `.target` 선언과 test target은 바꾸지 않는다
- [ ] T037 [P] [S2] `sources/Projects/Composition/Authentication/` 아래 파일 4개의 import를 갱신한다: `Adapters/AuthenticationRepositoryAdapter.swift`, `Adapters/PolicyConsentRepositoryAdapter.swift`, `Adapters/SignInRepositoryAdapter.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `import DomainUseCaseInterface`만 남게 한다; `Assemblies/SessionAvailabilityAssembly.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다. 모듈 이름으로 한정한 참조는 [contracts/domain-targets.md](./contracts/domain-targets.md#모듈-한정-참조)의 표대로 바꾼다.
- [ ] T038 [P] [S2] `sources/Projects/Composition/LearningProject/` 아래 파일 12개의 import를 갱신한다: `Adapters/ExternalRepositoryLocatorAdapter.swift`, `Adapters/ExternalRepositoryLookupAdapter.swift`, `Adapters/GenerationOutcomeRepositoryAdapter.swift`, `Adapters/NotificationAuthorizationAdapter.swift`, `Adapters/PendingGenerationRepositoryAdapter.swift`, `Adapters/ProjectGenerationRepositoryAdapter.swift`, `Adapters/ProjectRepositoryAdapter.swift`, `Adapters/QuizAnswerRepositoryAdapter.swift`, `Adapters/QuizBookmarkRepositoryAdapter.swift`, `Adapters/QuizSetRepositoryAdapter.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `import DomainUseCaseInterface`만 남게 한다; `Assemblies/ExternalRepositoryAssembly.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `import DomainUseCaseImplementation`, `import DomainUseCaseInterface`만 남게 한다; `Assemblies/LearningProjectAssembly.swift` — Domain 모듈 import가 `import DomainUseCaseImplementation`, `import DomainUseCaseInterface`만 남게 한다. 모듈 이름으로 한정한 참조는 [contracts/domain-targets.md](./contracts/domain-targets.md#모듈-한정-참조)의 표대로 바꾼다.
- [ ] T039 [P] [S2] `sources/Projects/Composition/Member/` 아래 파일 5개의 import를 갱신한다: `Adapters/DeviceIdentifierRepositoryAdapter.swift`, `Adapters/DeviceRegistrationRepositoryAdapter.swift`, `Adapters/UserInfoRepositoryAdapter.swift`, `Adapters/WithdrawalRepositoryAdapter.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `import DomainUseCaseInterface`만 남게 한다; `Assemblies/MemberAssembly.swift` — Domain 모듈 import가 `import DomainUseCaseImplementation`, `import DomainUseCaseInterface`만 남게 한다.
- [ ] T040 [P] [S2] `sources/Projects/Composition/App/` 아래 파일 2개의 import를 갱신한다: `Assemblies/AppComposition.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다; `Assemblies/ConcernUseCaseAssembly.swift` — Domain 모듈 import가 `import DomainUseCaseImplementation`, `import DomainUseCaseInterface`만 남게 한다.
- [ ] T041 [P] [S2] `sources/Projects/Composition/ShareExtension/` 아래 파일 1개의 import를 갱신한다: `Assemblies/ShareExtensionComposition.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `import DomainUseCaseInterface`만 남게 한다.
- [ ] T042 [P] [S2] `sources/Projects/Composition/Tests/Authentication/` 아래 파일 1개의 import를 갱신한다: `Adapters/SignInRepositoryAdapterTests.swift` — Domain 모듈 import가 `@testable import DomainUseCaseInterface`만 남게 한다.
- [ ] T043 [P] [S2] `sources/Projects/Composition/Tests/LearningProject/` 아래 파일 9개의 import를 갱신한다: `Adapters/ExternalRepositoryLookupAdapterTests.swift`, `Adapters/GenerationOutcomeRepositoryAdapterTests.swift`, `Adapters/PendingGenerationRepositoryAdapterTests.swift`, `Adapters/ProjectRepositoryAdapterTests.swift`, `Adapters/QuizAnswerRepositoryAdapterTests.swift`, `Adapters/QuizBookmarkRepositoryAdapterTests.swift`, `Adapters/QuizSetRepositoryAdapterTests.swift`, `Assemblies/LearningProjectAssemblyTests.swift` — Domain 모듈 import가 `@testable import DomainUseCaseInterface`만 남게 한다; `Assemblies/ExternalRepositoryAssemblyTests.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `@testable import DomainUseCaseInterface`만 남게 한다.
- [ ] T044 [P] [S2] `sources/Projects/Composition/Tests/Member/` 아래 파일 1개의 import를 갱신한다: `Adapters/UserInfoRepositoryAdapterTests.swift` — Domain 모듈 import가 `@testable import DomainUseCaseInterface`만 남게 한다.
- [ ] T045 [P] [S2] `sources/Projects/Composition/Tests/App/` 아래 파일 2개의 import를 갱신한다: `Assemblies/AppCompositionTests.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다; `SharedLifetimeTests.swift` — Domain 모듈 import를 모두 지운다.
- [ ] T046 [P] [S2] `sources/Projects/Composition/Tests/ShareExtension/` 아래 파일 1개의 import를 갱신한다: `ShareExtensionCompositionTests.swift` — Domain 모듈 import가 `@testable import DomainUseCaseInterface`만 남게 한다.

### Feature

- [ ] T047 [S3] `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`의 `Feature` target에서 `.fromDomain(…)` 선언 8개를 `.fromDomain(.DomainUseCaseInterface)`, `.fromDomain(.DomainUseCaseDependency)` 두 개로 바꾼다. `FeatureTests`와 다른 선언은 바꾸지 않는다
- [ ] T048 [P] [S2] `sources/Projects/Feature/AppEntry/` 아래 파일 1개의 import를 갱신한다: `AppEntryFeature.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T049 [P] [S2] `sources/Projects/Feature/Home/` 아래 파일 4개의 import를 갱신한다: `HomeFeature.swift`, `Previews/HomeScreenPreviews.swift`, `ViewModels/HomeProfileDisplay.swift`, `ViewModels/HomeProjectDisplay.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T050 [P] [S2] `sources/Projects/Feature/MainShell/` 아래 파일 1개의 import를 갱신한다: `Router/MainShellRouterFeature.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T051 [P] [S2] `sources/Projects/Feature/Onboarding/` 아래 파일 10개의 import를 갱신한다: `CareerSelection/CareerSelectionFeature.swift`, `CareerSelection/CareerSelectionScreen.swift`, `CareerSelection/Previews/CareerSelectionScreenPreviews.swift`, `PositionSelection/PositionSelectionFeature.swift`, `PositionSelection/PositionSelectionScreen.swift`, `PositionSelection/Previews/PositionSelectionScreenPreviews.swift`, `Previews/OnboardingPreviewSupport.swift`, `Router/OnboardingRouterFeature.swift`, `Tutorial/TutorialFeature.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다; `LegalAgreement/LegalAgreementScreen.swift` — Domain 모듈 import를 모두 지운다.
- [ ] T052 [P] [S2] `sources/Projects/Feature/ProjectDetail/` 아래 파일 6개의 import를 갱신한다: `Previews/ProjectDetailScreenPreviews.swift`, `ProjectDetailFeature.swift`, `ProjectDetailLoadFeature.swift`, `Router/Previews/ProjectDetailRouterPreviews.swift`, `Router/ProjectDetailRouterFeature.swift`, `ViewModels/ProjectDetailSetDisplay.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T053 [P] [S2] `sources/Projects/Feature/ProjectList/` 아래 파일 4개의 import를 갱신한다: `Previews/ProjectListScreenPreviews.swift`, `ProjectListFeature.swift`, `ProjectListPaginationFeature.swift`, `ViewModels/ProjectListDisplay.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T054 [P] [S2] `sources/Projects/Feature/ProjectRegistration/` 아래 파일 10개의 import를 갱신한다: `Previews/ProjectRegistrationPreviewSupport.swift`, `QuizGenerationProgress/QuizGenerationProgressFeature.swift`, `QuizLevelSelection/QuizLevelSelectionFeature.swift`, `QuizLevelSelection/QuizLevelSelectionScreen.swift`, `QuizLevelSelection/ViewModels/QuizLevel+Identifier.swift`, `RepositoryConfirmation/RepositoryConfirmationFeature.swift`, `RepositoryLinkInput/RepositoryLinkInputFeature.swift`, `Router/ProjectRegistrationRouterFeature.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다; `QuizLevelSelection/Previews/QuizLevelSelectionScreenPreviews.swift`, `RepositoryConfirmation/RepositoryConfirmationScreen.swift` — Domain 모듈 import를 모두 지운다.
- [ ] T055 [P] [S2] `sources/Projects/Feature/Quiz/` 아래 파일 11개의 import를 갱신한다: `LearningSetIntro/LearningSetIntroFeature.swift`, `LearningSetIntro/Previews/LearningSetIntroScreenPreviews.swift`, `QuestionSolving/Previews/QuestionSolvingScreenPreviews.swift`, `QuestionSolving/QuestionSolvingFeature.swift`, `QuestionSolving/ViewModels/ChoiceOptionDisplay.swift`, `QuestionSolving/ViewModels/QuestionSourceDisplay.swift`, `Router/LearningSessionFeature.swift`, `Router/Previews/QuizRouterPreviews.swift`, `Router/QuizRouterFeature.swift`, `Shared/Models/LearningSetResumption.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다; `QuestionSolving/QuestionSolvingScreen.swift` — Domain 모듈 import를 모두 지운다.
- [ ] T056 [P] [S2] `sources/Projects/Feature/Saved/` 아래 파일 4개의 import를 갱신한다: `Previews/SavedScreenPreviews.swift`, `SavedFeature.swift`, `SubViews/SavedScreen+FilterSection.swift`, `ViewModels/SavedQuestionDisplay.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T057 [P] [S2] `sources/Projects/Feature/Settings/` 아래 파일 11개의 import를 갱신한다: `Profile/Previews/ProfileScreenPreviews.swift`, `Profile/ProfileFeature.swift`, `Profile/ViewModels/ProfileDisplay.swift`, `Router/SettingsRouterFeature.swift`, `Settings/AccountActionFeature.swift`, `Settings/CurationUpdateFeature.swift`, `Settings/NotificationPermissionFeature.swift`, `Settings/Previews/SettingsScreenPreviews.swift`, `Settings/SettingsFeature.swift`, `Shared/ViewModels/CareerLevelDisplay.swift`, `Shared/ViewModels/PositionDisplay.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T058 [P] [S2] `sources/Projects/Feature/ShareRegistration/` 아래 파일 4개의 import를 갱신한다: `ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift`, `ShareRegistration/ShareRegistrationDiagnosticEvent.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다; `ShareRegistration/ShareRegistrationFeature.swift`, `ShareRegistration/SharedRepositoryRegistrationFeature.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `import DomainUseCaseInterface`만 남게 한다.
- [ ] T059 [P] [S2] `sources/Projects/Feature/Shared/` 아래 파일 6개의 import를 갱신한다: `Reducers/LegalAgreementFeature.swift`, `Reducers/ProjectDeletionFeature.swift`, `Reducers/ProjectSummaryListFeature.swift`, `Reducers/SignInFeature/SignInFeature.swift`, `Reducers/SingleQuestionEntryFeature.swift`, `Reducers/UserProfileLoadFeature.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T060 [P] [S2] `sources/Projects/Feature/Tests/AppEntry/` 아래 파일 3개의 import를 갱신한다: `AppEntry/AppEntryFeatureTests.swift` — Domain 모듈 import를 모두 지운다; `TestDoubles/AccountUseCaseRestorationMock.swift`, `TestDoubles/UserInfoUseCaseProfileMock.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T061 [P] [S2] `sources/Projects/Feature/Tests/Home/` 아래 파일 7개의 import를 갱신한다: `Home/HomeFeatureGenerationOutcomeTests.swift` — Domain 모듈 import를 모두 지운다; `Home/HomeFeatureNavigationTests.swift`, `Home/ViewModels/HomeProjectDisplayTests.swift`, `Home/ViewModels/HomeScreen+ProjectSectionStateTests.swift`, `TestDoubles/HomeTestFixture.swift`, `TestDoubles/ProjectUseCaseMock.swift`, `TestDoubles/UserInfoUseCaseSuspendableProfileMock.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T062 [P] [S2] `sources/Projects/Feature/Tests/MainShell/` 아래 파일 2개의 import를 갱신한다: `Router/MainShellRouterFeatureTests.swift`, `TestDoubles/MainShellAccountUseCaseStub.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T063 [P] [S2] `sources/Projects/Feature/Tests/Onboarding/` 아래 파일 11개의 import를 갱신한다: `CareerSelection/CareerSelectionFeatureTests.swift`, `Router/OnboardingRouterFeatureTests.swift`, `TestDoubles/AccountUseCaseConsentMock.swift`, `TestDoubles/AccountUseCaseSignInMock.swift`, `TestDoubles/AccountUseCaseSignOutMock.swift`, `TestDoubles/AccountUseCaseWithdrawalMock.swift`, `TestDoubles/OnboardingTestFixture.swift`, `TestDoubles/UserInfoUseCaseCurationMock.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다; `PositionSelection/PositionSelectionFeatureTests.swift`, `TestDoubles/OnboardingTestSupport.swift`, `Tutorial/TutorialFeatureTests.swift` — Domain 모듈 import를 모두 지운다.
- [ ] T064 [P] [S2] `sources/Projects/Feature/Tests/ProjectDetail/` 아래 파일 5개의 import를 갱신한다: `ProjectDetail/ProjectDetailFeatureTests.swift`, `TestDoubles/ProjectDetailTestFixture.swift`, `TestDoubles/ProjectUseCaseDeletionStub.swift`, `TestDoubles/ProjectUseCaseDetailStub.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다; `ProjectDetail/ProjectDetailLoadFeatureTests.swift` — Domain 모듈 import를 모두 지운다.
- [ ] T065 [P] [S2] `sources/Projects/Feature/Tests/ProjectList/` 아래 파일 3개의 import를 갱신한다: `ProjectList/ProjectListFeatureTests.swift`, `ViewModels/ProjectListDisplayTests.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다; `ProjectList/ProjectListPaginationFeatureTests.swift` — Domain 모듈 import를 모두 지운다.
- [ ] T066 [P] [S2] `sources/Projects/Feature/Tests/ProjectRegistration/` 아래 파일 10개의 import를 갱신한다: `QuizGenerationProgress/QuizGenerationProgressFeatureTests.swift`, `QuizLevelSelection/QuizLevelSelectionFeatureTests.swift`, `Router/ProjectRegistrationRouterFeatureTests.swift`, `TestDoubles/AppSettingUseCaseStub.swift`, `TestDoubles/ExternalRepositoryUseCaseStub.swift`, `TestDoubles/ProjectGenerationStateStreamStub.swift`, `TestDoubles/ProjectGenerationUseCaseStub.swift`, `TestDoubles/ProjectRegistrationTestSupport.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다; `RepositoryConfirmation/RepositoryConfirmationFeatureTests.swift`, `RepositoryLinkInput/RepositoryLinkInputFeatureTests.swift` — Domain 모듈 import를 모두 지운다.
- [ ] T067 [P] [S2] `sources/Projects/Feature/Tests/Quiz/` 아래 파일 11개의 import를 갱신한다: `LearningSetIntro/LearningSetIntroFeatureTests.swift` — Domain 모듈 import를 모두 지운다; `QuestionSolving/QuestionSolvingFeatureTests.swift`, `QuestionSolving/ViewModels/ChoiceOptionDisplayTests.swift`, `Router/LearningSessionFeatureTests.swift`, `TestDoubles/QuizDetailUseCaseBookmarkListStub.swift`, `TestDoubles/QuizDetailUseCaseBookmarkStub.swift`, `TestDoubles/QuizDetailUseCaseChoiceGradingStub.swift`, `TestDoubles/QuizDetailUseCaseEssayGradingStub.swift`, `TestDoubles/QuizDetailUseCaseMock.swift`, `TestDoubles/QuizDetailUseCaseQuizSetStub.swift`, `TestDoubles/QuizTestFixture.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T068 [P] [S2] `sources/Projects/Feature/Tests/Saved/` 아래 파일 1개의 import를 갱신한다: `Saved/SavedFeatureTests.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T069 [P] [S2] `sources/Projects/Feature/Tests/Settings/` 아래 파일 9개의 import를 갱신한다: `Profile/ViewModels/ProfileDisplayTests.swift`, `Router/SettingsRouterFeatureTests.swift`, `Settings/NotificationPermissionFeatureTests.swift`, `Settings/SettingsFeatureTests.swift`, `TestDoubles/SettingsTestFixture.swift`, `TestDoubles/UserInfoUseCaseCareerLevelMock.swift`, `TestDoubles/UserInfoUseCaseMock.swift`, `TestDoubles/UserInfoUseCasePositionMock.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다; `Settings/CurationUpdateFeatureTests.swift` — Domain 모듈 import를 모두 지운다.
- [ ] T070 [P] [S2] `sources/Projects/Feature/Tests/ShareRegistration/` 아래 파일 7개의 import를 갱신한다: `ShareRegistration/ShareRegistrationFeatureFailureTests.swift`, `ShareRegistration/SharedRepositoryRegistrationFeatureTests.swift`, `ShareRegistration/TestDoubles/ExternalRepositoryUseCaseFixedResultStub.swift`, `ShareRegistration/TestDoubles/ProjectGenerationUseCaseSpy.swift`, `ShareRegistration/TestDoubles/ShareRegistrationTestSupport.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다; `ShareRegistration/ShareRegistrationFeatureStepTests.swift` — Domain 모듈 import를 모두 지운다; `ShareRegistration/TestDoubles/StubRepositoryURLParser.swift` — Domain 모듈 import가 `import DomainUseCaseDependency`, `import DomainUseCaseInterface`만 남게 한다.
- [ ] T071 [P] [S2] `sources/Projects/Feature/Tests/Shared/` 아래 파일 5개의 import를 갱신한다: `Reducers/LegalAgreementFeatureTests.swift`, `Reducers/ProjectDeletionFeatureTests.swift`, `Reducers/SignInFeatureTests.swift` — Domain 모듈 import를 모두 지운다; `Reducers/ProjectSummaryListFeatureTests.swift`, `Reducers/UserProfileLoadFeatureTests.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.

### App

- [ ] T072 [S3] `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`에서 `GitIt`과 `GitItTests`의 `.fromDomain(…)` 선언 8개씩을 각각 `.fromDomain(.DomainUseCaseInterface)` 하나로 바꾸고, `ShareExtension`의 `.fromDomain(…)` 선언 4개를 지운다. `buildVersion`과 다른 선언은 바꾸지 않는다
- [ ] T073 [P] [S2] `sources/Projects/App/GitIt/` 아래 파일 4개의 import를 갱신한다: `GitItApp.swift` — Domain 모듈 import를 모두 지운다; `Loaders/PolicyManifestLoader.swift`, `Reducers/AppRootFeature.swift`, `Screens/AppRootView.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.
- [ ] T074 [P] [S2] `sources/Projects/App/ShareExtension/` 아래 파일 1개의 import를 갱신한다: `ShareViewController.swift` — Domain 모듈 import를 모두 지운다.
- [ ] T075 [P] [S2] `sources/Projects/App/Tests/GitIt/` 아래 파일 13개의 import를 갱신한다: `GitItCompositionLifetimeTests.swift`, `Loaders/PolicyManifestTests.swift`, `Reducers/AppRootFeatureLearningProjectsRefreshTests.swift`, `TestDoubles/AppRootTestSupport.swift` — Domain 모듈 import를 모두 지운다; `Reducers/AppRootFeatureTests.swift`, `TestDoubles/AccountUseCaseMock.swift`, `TestDoubles/AppRootTestFixture.swift`, `TestDoubles/AppSettingUseCaseMock.swift`, `TestDoubles/NoopExternalRepositoryUseCase.swift`, `TestDoubles/NoopQuizDetailUseCase.swift`, `TestDoubles/ProjectGenerationUseCaseMock.swift`, `TestDoubles/ProjectUseCaseMock.swift`, `TestDoubles/UserInfoUseCaseMock.swift` — Domain 모듈 import가 `import DomainUseCaseInterface`만 남게 한다.

### 정리와 단위 검증

- [ ] T076 [no-write] `make tuist`로 workspace와 project를 다시 만든다. 실행 전후 `git status --short`를 비교해 이 단위의 작업에 적힌 파일 외에 추적 파일 변경이 없는지 확인한다
- [ ] T077 [no-write] [S2] [S3] 구조를 확인한다. `sources/Projects/Domain/` 아래 소스 폴더가 `UseCaseInterface`, `UseCaseDependency`, `UseCaseImplementation`, `Tests` 넷뿐인지, [quickstart.md](./quickstart.md) 4절의 옛 target 이름 검색 결과가 0건인지, `./.tools/package-dependencies/bin/run.sh`가 위반 0건으로 끝나는지, 세 매니페스트의 `.fromDomain(…)` 선언이 [contracts/domain-targets.md](./contracts/domain-targets.md#소비-target의-의존-선언)의 표와 같은지 확인한다
- [ ] T078 [no-write] [S2] build 실행기의 `compile`(build-for-testing)이 통과하는지 확인한다. 실패하면 [quickstart.md](./quickstart.md)의 "실패했을 때" 표에 따라 처리하고, 표가 사용자 확인을 요구하는 경우에는 중단한다

**진행 점검**: T001~T078의 변경 파일과 검증 결과를 보고하고 전체 완료 검증으로 진행한다. 새 범위나
권한이 필요하면 여기서 중단하고 명시적 승인을 요청한다.

---

## 전체 완료 검증

**선행 조건**: 실행 단위 1의 파일 변경 작업을 완료하고, 전체 검증과 hook 결과를 포함할 마지막
커밋 단위를 아직 commit하지 않은 상태여야 한다.

**커밋 경계**: 아래 `[no-write]` 작업은 실행 단위 1의 마지막 커밋 단위에 배정한다. 모든 검증과
필수 `after_implement` hook을 마친 뒤 그 단위를 최종 commit한다. 이미 파일 변경 단위가 모두
commit된 단순 재개에서는 `tasks.md` 완료 표시를 위한 별도 최종 검증 단위를 둔다. 읽기 전용 전체
검증은 반복 승인 없이 같은 실행에서 이어서 수행한다.

- [ ] T079 [no-write] build 실행기의 `build`, `compile`, `test`를 순서대로 하나씩 실행하고 결과를 기록한다. test 소스 루트별 `@Test` 선언 수가 T001의 기준선과 같은지, test 로그의 Domain 실행 테스트 수가 129 이상인지 확인한다(SC-002)
- [ ] T080 [no-write] [S1] 시나리오 1의 수용 기준을 [quickstart.md](./quickstart.md) 1절과 5절로 검증한다. `docs/`만 바꾼 커밋 `4d13a76`, `2c3ca6e`가 `sources/`나 `.tools/`를 바꾼 첫 커밋보다 앞에 있는지(SC-009), [Domain 패키지 규칙](../../docs/package-rules/domain.md#역할별-타깃-구성)의 target 목록·소유·허용 의존이 실제 target 구성과 같은지(SC-010), 규칙 문서만으로 새 관심사의 다섯 선언 경로를 정할 수 있는지(SC-008), `./.tools/script-tests/bin/run.sh`가 통과하는지(SC-007) 확인한다
- [ ] T081 [no-write] [S2] 시나리오 2의 수용 기준을 [quickstart.md](./quickstart.md) 2절과 4절로 검증한다. Domain target이 4개인지(SC-001), `git diff --stat -M a4cc97c..HEAD -- sources/Projects/Domain`에서 production 104개 파일이 rename으로 잡히고 내용이 바뀐 46개 파일의 변경이 import 줄뿐인지(SC-006), 옛 target 이름 검색 결과가 0건인지(SC-004) 확인한다. 변경은 아직 commit 전이므로 diff는 작업 트리 기준으로 본다
- [ ] T082 [no-write] [S3] 시나리오 3의 수용 기준을 [quickstart.md](./quickstart.md) 3절로 검증한다. 패키지 의존성 검사 위반이 0건인지(SC-003), `AppModuleName.swift`와 `FeatureModuleName.swift`에 `DomainUseCaseImplementation` 선언이 없는지(SC-005), 각 소비 target의 선언이 실제 import와 1:1인지 확인한다

## 의존성과 실행 순서

### 실행 단위 순서와 위험 기반 승인

- 실행 단위는 하나다. 단위 안에서는 Domain → Tuist 헬퍼와 검사 설정 → Composition → Feature →
  App 순서로 작업한다. 근거는 [아키텍처 문서 3.1](../../docs/architecture.md)의 의존성 표다.
- 원칙 7의 제거 예외는 쓰지 않는다. 이 변경은 공개 선언의 제거가 아니라 이동이다.
- 작업 사이의 중간 상태는 build되지 않는다. T002~T075을 모두 끝낸 뒤 T076부터 검증한다.
- 변경 파일과 검증 결과를 보고하되 같은 기능 범위에서는 반복 승인을 요구하지 않는다.
- 다음 경우에만 중단하고 명시적 승인을 요청한다.
  - 테스트 선언의 이름을 바꿔야 `DomainTests`가 compile되는 경우
  - 접근 수준을 넓혀야 하는 선언이 FR-007의 예외 범위(해당 선언에 한정)를 넘는 경우
  - UseCase 계약이나 모델이 주입 계약의 타입을 참조해 Interface → Dependency 의존이 필요한 경우
  - 규칙 문서와 다른 구조가 필요한 경우. 구조를 바꾸기 전에 규칙 문서를 먼저 고친다(FR-019)
  - 이 문서에 적히지 않은 파일을 고쳐야 하는 경우

### 변경 시나리오 추적성

| 시나리오 | 구현 작업 | 수용 검증 |
| --- | --- | --- |
| S1 규칙 문서가 구조를 먼저 규정한다 | 완료된 선행 단위(`4d13a76`, `2c3ca6e`) | T080 |
| S2 Domain이 네 역할 target이다 | T002~T035, 소비 패키지의 import 갱신(T037~T046, T048~T071, T073~T075) | T077, T078, T079, T081 |
| S3 필요한 역할에만 의존한다 | T032, T035, T036, T047, T072 | T077, T082 |

- 변경 시나리오는 실행 단위 1이 끝난 뒤 독립 수용 기준으로 검증한다.
- 최소 가치 범위는 실행 단위 1 전체다. 일부만 적용한 상태는 build되지 않는다.

### 실행 단위 내부 실행

- `[P]` 작업은 서로 다른 파일을 다루므로 순서를 바꾸거나 함께 진행할 수 있다. Git index를 쓰는
  `git mv`와 stage는 한 번에 하나씩 실행한다.
- 한 관심사의 이동 작업(Interface, Dependency, Implementation)이 모두 끝나야 옛 관심사 폴더를
  지울 수 있다.
- 매니페스트 작업(T032~T034, T036, T047, T072)은 `DomainModuleName`의 새 case를 참조하므로 T032 뒤에 한다.
- 이 단위의 커밋은 하나다. 대규모 파일 이동과 import 갱신을 나누면 중간 커밋이 compile되지
  않는다. 로직 변경은 포함하지 않는다.
- 마지막 단위이므로 전체 완료 검증과 필수 `after_implement` hook이 끝날 때까지 commit하지
  않는다. Hook이 이 단위의 파일에 만든 허용된 포맷 결과를 재검증해 같은 commit에 포함하며,
  commit 성공 뒤 hook을 다시 실행하지 않는다.

## 구현 전략

1. 이 tasks.md의 blob hash와 전체 diff를 기준선으로 고정하고 T001로 기준 상태를 확인한다.
2. 실행 단위 1의 작업을 위상 순서로 수행한다. 파일 이동과 import 갱신은 작업에 적힌 파일만
   다룬다.
3. T076~T078으로 단위를 검증하고 변경 파일과 결과를 보고한다.
4. T079~T082으로 전체 기능과 시나리오별 수용 기준을 검증한다.
5. 필수 `after_implement` hook을 실행하고 결과를 재검증한 뒤 단위를 commit한다.
6. 새 권한이 필요한 경계가 나타나면 변경을 시작하기 전에 중단하고 명시적 승인을 요청한다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 파일 변경 작업은 정확한 경로를 포함한다. 한 작업에 적힌 파일 수의 합은 Domain production
  104개(이동), Domain 테스트 30개, Composition 38개, Feature 146개, App 18개다.
- import를 모두 지우는 파일에서 compile 오류가 나면 오류가 가리키는 타입의 역할 모듈만
  import한다. 그 파일은 이미 해당 작업에 적혀 있으므로 범위 확대가 아니다.
- 문제 해결과 암묵지 기록을 구현 작업 ID로 생성하지 않는다.
