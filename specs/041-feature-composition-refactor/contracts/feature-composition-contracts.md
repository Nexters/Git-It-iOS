# 계약: 추출 기능 Feature의 공개 표면

**기능**: [spec.md](../spec.md) · **데이터 모델**: [data-model.md](../data-model.md)

이 문서는 이번에 추출하거나 옮기는 기능 Feature가 **상위 Feature에 공개하는 표면**을 정의한다. 표면은
생성자 의존성, 부모가 보내는 `input`, 화면이 직접 보내는 `view`, 부모가 해석하는 `delegate` 네 가지다.
Action 분류와 이름 규칙은 [Action 컨벤션](../../../docs/conventions/tca/action.md), 조합 경계는
[Feature 조합](../../../docs/conventions/tca/feature/composition.md)을 따른다.

## 공통 계약

- **생성자**: 기능 Feature는 자신이 호출하는 Use Case만 `@Sendable` 클로저로 받는다. 상위 Feature는
  같은 subset을 받아 그대로 전달하며, 구현을 바꾸거나 새로 만들지 않는다(FR-004, FR-024).
  필수 의존성에 기본값을 주지 않는다.
- **입력 경로**: 부모의 조정 신호는 `input`, 사용자 입력은 `view`로만 들어온다. 부모는 자식의 State
  필드를 직접 쓰지 않는다(FR-006).
- **출력 경로**: 기능 Feature는 결과를 `delegate`로만 알린다. 자신을 합성한 화면이 무엇인지 알지 않으며,
  화면에 따라 분기하지 않는다(FR-005, SC-006).
- **독립 인스턴스**: 같은 Feature를 여러 상위가 합성해도 각 인스턴스의 State는 독립이다. `@Shared`를
  쓰지 않는다(FR-007, FR-026).
- **View 없음**: 기능 Feature 파일에는 View가 없다. 화면은 `store.scope`로 자식 store를 얻어 렌더링한다
  (FR-027).
- **테스트**: 기능 Feature마다 `Tests/<배치 축>/<Feature>Tests.swift`에서 이 계약의 모든 행을 단독으로
  검증한다(FR-009, SC-004).

---

## `UserProfileLoadFeature` (I1)

| 구분 | 이름 | 계약 |
| --- | --- | --- |
| 생성자 | `profile: @Sendable () async throws -> UserProfile` | 프로필 조회. `UserInfoError`가 아닌 오류는 `.temporarilyUnavailable`로 변환한다 |
| input | `load` | 로딩을 표시하며 조회한다. 어느 상태에서든 받는다 |
| input | `reload` | `loaded`면 상태를 유지한 채 재조회하고 실패는 무시한다. `loading`이면 무시한다. 그 밖에는 `load`와 같다 |
| input | `replace(UserProfile)` | `.loaded(profile)`로 교체하고 진행 중 조회를 무효화한다 |
| delegate | 없음 | 부모는 State를 관찰한다 |

**합성 지점**

- Home: `task`·`accessChanged(.member)` 때 `idle`이면 `load`, `profileRetryTapped` 때 `failed`이고
  회원이면 `load`.
- Profile: `task` 때 `idle/failed → load`, `loaded → reload`. `retryTapped` 때 `failed`이면 `load`.
- Settings: `task` 때 `load`. `CurationUpdateFeature`의 `updated`를 받으면 `replace`.
- SettingsRouter: 화면 이동 시 조회 완료된 프로필을 상대 화면에 `replace`로 전달한다.

## `ProjectSummaryListFeature` (I2)

| 구분 | 이름 | 계약 |
| --- | --- | --- |
| 생성자 | `projects: @Sendable () async -> AsyncStream<ProjectList>`, `refreshProjects: @Sendable () async throws -> Void` | 목록 관찰과 새로고침 |
| input | `start` | 스트림 관찰을 시작하고(`cancelInFlight`) 새로고침한다 |
| input | `refresh` | 새로고침한다. `loaded`가 아니면 `.loading`으로 바꾼다 |
| input | `projectRemoved(ProjectID)` | `loaded` payload에서 해당 행을 제거한다 |
| delegate | `listUpdated(ProjectList)` | `.loaded` 값이 바뀔 때마다 보낸다 |

**합성 지점**

- Home: 회원일 때 `task`에서 `start`, 재적재 요청에서 `refresh`, 재시도는 `failed`이고 회원일 때
  `refresh`. `listUpdated`는 무시한다.
- ProjectList: `task`에서 `start`. `refreshRequested`·재적재 요청에서 `refresh`를 보내고, 페이지네이션에
  `refreshStarted`를 보낸다. `listUpdated`를 받으면 페이지네이션에 `listReplaced(hasNextPage:)`를
  보내고, 목록이 비었으면 삭제 모드를 끝낸다.

## `ProjectDeletionFeature` (I3)

| 구분 | 이름 | 계약 |
| --- | --- | --- |
| 생성자 | `deleteProject: @Sendable (ProjectID) async throws -> Void` | 삭제 |
| input | `request(ProjectID)` | `idle`·`failed`에서 `.confirming(id)` |
| input | `cancel` | `confirming`·`failed`에서 `.idle` |
| input | `confirm` | `confirming(id)`에서 `.committing(id)`로 바꾸고 삭제한다 |
| delegate | `deleted(projectID: ProjectID)` | 성공 또는 `.notFound`일 때 `.idle`로 바꾸고 보낸다. 그 밖의 오류는 `.failed(id, error)` |

**합성 지점**

- ProjectList: `mode == .deleting`일 때만 `request`를 보낸다. `deleted`를 받으면 목록에
  `projectRemoved`를 보내고 `projectDeleted` delegate를 보낸다.
- ProjectDetail: `deleteTapped`에서 메뉴를 닫고 `request(projectID)`를 보낸다. `deleted`를 받으면
  `projectDeleted(projectID:)` delegate를 보낸다.

## `SignInFeature` (I4)

| 구분 | 이름 | 계약 |
| --- | --- | --- |
| 생성자 | `signIn: @Sendable (SignInMethod) async -> SignInResult`, `policyConsentStatus: @Sendable () async throws -> PolicyConsentStatus`, `consent: @Sendable ([PolicyDocumentID]) async throws -> Void` | `withdraw`는 받지 않는다 |
| input | `prepareConsent` | 동의 상태가 적재되지 않았으면 적재한다 |
| input | `start` | `idle`·`cancelled`·`failed`에서 시작한다. 동의 상태를 확인(필요하면 적재 대기)한 뒤, 유효하지 않으면 `.agreeingToPolicies`, 유효하면 `.signingIn`으로 바꾼다 |
| view | `legalAgreementDismissed`, `legalDocumentSheetDismissed`, `failureDismissed` | 오버레이 닫기. `failureDismissed`는 `failed → idle` |
| 자식 | `legalAgreement(LegalAgreementFeature.Action)` | `consentCompleted` → 로그인 시작, `cancelled` → `.idle`과 `consentCancelled` |
| delegate | `signedIn(needsCuration: Bool)` | 성공 시 `.idle` |
| delegate | `consentCancelled` | 동의 화면에서 취소했다 |
| delegate | `signInCancelled` | 로그인 취소 결과. 상태는 `.cancelled` |

- 결과는 `requestID` 일치와 `phase == .signingIn`을 모두 만족할 때만 반영한다.

**합성 지점**

- MainShellRouter: 비회원 `signInTapped`·Home `signInRequested`에서 `start`. `signedIn`을 받으면
  `signInSucceeded(needsCuration:)`로 올린다. View는 `isLegalAgreementPresented`로 동의 오버레이를,
  `failed`로 alert를 표시한다.
- Tutorial: 표시될 때 `prepareConsent`, `appleSignInTapped`에서 `page = 3`으로 바꾸고 `start`.
  `consentCancelled`를 받으면 마지막 페이지로 돌아간다. `signedIn`을 받으면 개발용 재설정 조건을
  판정해 `withdraw` 뒤 `start`하거나 `signInSucceeded`로 올린다. 인라인 오류는 `cancelled`·`failed`에서
  표시한다.

## `LegalAgreementFeature`, `SingleQuestionEntryFeature` (P2·P3, 이동)

공개 표면을 바꾸지 않는다. 파일 위치만 `Feature/Shared/Reducers/`로 옮긴다.

## 화면 고유 분리 Feature

| Feature | 생성자 | input | delegate |
| --- | --- | --- | --- |
| `ProjectListPaginationFeature` | `requestNextPage` | `nextPageRequested`(`idle`만), `retry`(`failed`만), `listReplaced(hasNextPage:)`, `refreshStarted`(진행 요청 취소) | 없음 |
| `CurationUpdateFeature` | `updatePosition`, `updateCareerLevel` | `positionSelected`, `careerLevelSelected`(각 `committing`이 아닐 때) | `positionUpdated(MemberPosition)`, `careerLevelUpdated(CareerLevel)` |
| `AccountActionFeature` | `signOut`, `withdraw` | `signOutRequested`, `deletionRequested`, `deletionCancelled`, `deletionConfirmed` | `signedOut`, `accountDeleted`, `deletionConfirmationRequested`, `deletionCancelled` |
| `NotificationPermissionFeature` | `notificationAuthorization`, `requestNotificationAuthorization`, `openNotificationSettings` | `refresh`(진입·앱 활성화), `rowTapped` | 없음 |
| `ProjectDetailLoadFeature` | `projectDetail` | `load` | 없음 |

`SettingsFeature`는 자식 delegate를 기존 delegate(`signedOut`, `accountDeleted`,
`accountDeletionRequested`, `accountDeletionCancelled`)로 그대로 바꿔 올린다. 상위(`SettingsRouterFeature`)가
보는 표면은 바뀌지 않는다.

## 전환 계층 반납 Feature

| Feature | 생성자 | input | delegate |
| --- | --- | --- | --- |
| `LearningSessionFeature` | 없음 | `started(set:resumption:bookmarkedQuestionIDs:)`, `answerRecorded(choiceCorrect:)`, `advanced` | `questionReady(question:number:isBookmarked:isLast:)`, `emptySetDetected`, `completed(correctChoiceCount:choiceQuestionCount:)` |
| `SharedRepositoryRegistrationFeature` | `parseRepositoryLink`, `externalRepository`, `projectGeneration`, `signInAvailability`, `recordDiagnostic` | `validate(sharedURL:)`, `submit(repository:quizLevel:)`, `retry` | `repositoryResolved(ExternalRepository)` |

- `QuizRouterFeature`는 `questionReady`에서 `QuestionSolvingFeature.State`를 만들어 활성화하고,
  `completed`에서 `learningCompletion`을 채워 활성화한다. `emptySetDetected`에서는
  `learningSetIntro.input(.emptySetReported)`를 보낸다.
- `ShareRegistrationFeature`의 생성자 시그니처는 바뀌지 않는다. 받은 의존성 중 등록 관련 subset을
  자식에 그대로 전달하고 `dismiss`는 자신이 보유한다.
