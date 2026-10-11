# 데이터 모델: 프로젝트 등록 흐름 리뷰 지적 사항 해소

**기능 브랜치**: `feature/registration-flow-review-fixes`

**날짜**: 2026-09-01

이 기능은 새 비즈니스 엔터티를 도입하지 않는다. 기존 모델의 **이름, 소유 패키지, 상태 전이**를
바꾸고 Feature 상태에 필드를 추가한다. 아래는 변경 후 기준이다.

## 1. Domain 모델 (공급자 중립)

### GenerationOutcome — 변경 없음

| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `projectID` | `String` | 생성 결과가 속한 프로젝트 식별자. 이 이벤트의 유일한 식별 키 |
| `status` | `Status` | `.completed` 또는 `.failed` |

**소유**: `Domain/LearningProject/Models/LearningProject/GenerationOutcome.swift`

**규칙**: FR-022c에 따라 이 타입과 그 계약·Use Case 이름에 `LearningSet` 어휘를 사용하지 않는다.
`LearningSet`은 set 식별자로 조회되는 별개 모델(`Models/Quiz/LearningSet.swift`)이다.

### GenerationOutcomeRepository — 변경 없음

`Domain/LearningProject/Contracts/GenerationOutcomeRepository.swift`

### 생성 결과 관찰 Use Case — 이름 변경

| 변경 전 | 변경 후 |
| --- | --- |
| `LearningProjectOutcomesUseCase` | `ObserveGenerationOutcomesUseCase` |
| `LearningProjectOutcomes` | `ObserveGenerationOutcomes` |
| `UseCases/LearningProjectOutcomes/` | `UseCases/ObserveGenerationOutcomes/` |

계약 형태는 유지한다: `func callAsFunction() async -> AsyncStream<GenerationOutcome>`.
프로젝트 필터가 없다는 점이 FR-002(응답 전 구독 시작)의 전제다.

### MemberDeviceInfo — 변경 없음

`deviceID`, `deviceType`, `appVersion`, `osVersion`, `deviceToken`. 인증 세션이 있어야 등록할 수
있고 `deviceToken` 갱신 시 재등록 대상이 된다(FR-016).

## 2. Data 모델 (백엔드 어휘)

### QuizGenerationOutcomeDTO — 이름 변경

| 변경 전 | 변경 후 |
| --- | --- |
| `GenerationOutcomeDTO` | `QuizGenerationOutcomeDTO` |

| 필드 | 타입 | 원본 payload 키 |
| --- | --- | --- |
| `projectID` | `String` | `"projectId"` (서버 고정 이름, 변경하지 않음) |
| `status` | `RawStatus` (`completed` \| `failed`) | `"status"` |

**소유**: `Data/LearningProject/DTOs/QuizGenerationOutcomeDTO.swift`

**근거**: 기존 `QuizGenerationRemote`, `QuizGenerationStatusResponseDTO`, `QuizGenerationEndpoint`와
같은 계열을 이룬다(FR-022b).

### 생성 결과 소스 — 이름·역할어·폴더 변경

| 변경 전 | 변경 후 | 위치 |
| --- | --- | --- |
| `GenerationOutcomeStream` (protocol) | `QuizGenerationOutcomeSource` | `Data/LearningProject/Contracts/` (유지) |
| `PushGenerationOutcomeStream` (구현) | `PushQuizGenerationOutcomeSource` | `Data/LearningProject/Remotes/` → `Data/LearningProject/Sources/` |
| 지역 변수 `id` | `subscriptionID` | 구현 내부 |

**상태**: `[UUID: AsyncStream<QuizGenerationOutcomeDTO>.Continuation]` 멀티캐스트. 버퍼는 도입하지
않는다(FR-004).

**형태 폴더**: `Sources/`는 새 어휘다. 같은 작업 단위에서
[`docs/conventions/file-vocabulary.md`](../../docs/conventions/file-vocabulary.md) §3의
`Data/<관심사>/` 행에 추가한다.

## 3. Composition 경계 값

| 변경 전 | 변경 후 | 비고 |
| --- | --- | --- |
| `AppComposition.ingestPushPayload` | `ingestGenerationOutcomePayload` | App 경계이므로 Domain 어휘 사용(FR-025) |
| `AppComposition.deviceID(keychainStore:)` | `loadOrCreateDeviceID(keychainStore:)` | 조회·생성·저장 부수효과 노출(FR-029) |
| `GenerationOutcomeRepositoryAdapter(remote:)` | `GenerationOutcomeRepositoryAdapter(source:)` | 인자명만 변경(FR-027) |

### 신규 노출 (FR-014 ~ FR-016)

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `registerCurrentDevice` | `@Sendable () async throws -> Void` | token 획득 + `MemberDeviceInfo` 구성 + 서버 등록 |
| `deviceTokenRefreshes` | `@Sendable () -> AsyncStream<Void>` | 등록 token 갱신 신호 |
| `bootstrap` | `@Sendable () async -> Void` | 푸시 client 초기화, 콜백 주입, 리마인드 구독 확립 |

App은 Infrastructure를 의존할 수 없으므로 세 값 모두 Swift 표준 타입만 노출한다.

## 4. Infrastructure 경계

### PushMessagingClient — 연산 추가

| 연산 | 상태 |
| --- | --- |
| `registrationToken() async throws -> String` | 유지 |
| `setAPNsToken(_:)` | 유지 |
| `registrationTokenRefreshes() -> AsyncStream<String>` | **추가** (FR-016) |

### PushNotificationCallbacks — 필드 이름 변경

| 변경 전 | 변경 후 |
| --- | --- |
| `ingestPushPayload` | `ingestGenerationOutcomePayload` |

`forwardAPNsToken`은 유지한다.

### FirebaseMessagingAppDelegate — 저장 위치 변경

| 변경 전 | 변경 후 |
| --- | --- |
| `private static let state = Mutex<PushNotificationCallbacks?>` | 인스턴스 프로퍼티 `callbacks`와 주입 전 대기 슬롯 |

**대기 슬롯**: 콜백 주입 전에 도착한 payload를 최대 1건 보관했다가 주입 직후 전달한다. 프로세스
진입점의 launch push 손실을 막기 위한 것이며 Data 계층 버퍼가 아니다(R3).

## 5. Feature 상태

### ProjectRegistrationFeature.State

| 필드 | 변경 |
| --- | --- |
| `submission: SubmissionStatus` | → `progress: RegistrationProgress` |
| `isNotificationOptionSheetPresented` | → `isGenerationReminderSheetPresented` |
| `step: RegistrationStep` | **추가** — View의 `@State` 2개를 대체 |
| `repositoryURLInput`, `quizLevel`, `validation`, `validationRequestID` | 변경 없음 |

#### RegistrationStep (신규)

```text
.repositoryConfirmation → .quizLevelSelection → .generationConfirmation
```

역방향 전이(뒤로 가기)를 허용한다. View 재생성으로 손실되지 않는다(FR-019).

#### RegistrationProgress (이름 변경)

| 변경 전 | 변경 후 |
| --- | --- |
| `.idle` | `.idle` |
| `.committing` | `.submitting` |
| `.awaitingGeneration(ProjectRegistrationReceipt)` | `.awaitingOutcome(ProjectRegistrationReceipt)` |
| `.failed(LearningProjectError)` | `.failed(LearningProjectError)` |

**상태 전이 규칙 (FR-006)**: `.awaitingOutcome` → `.failed` 전이는
`isGenerationReminderSheetPresented = false`를 함께 수행한다. 실패 상태에서 재시도와 흐름 종료
Action은 항상 유효해야 한다(FR-007).

#### Action 이름 변경 (FR-024)

| 변경 전 | 변경 후 |
| --- | --- |
| `view(.notificationOptionAccepted)` | `view(.generationReminderAccepted)` |
| `view(.notificationOptionDeclined)` | `view(.generationReminderDeclined)` |
| `delegate(.notificationOptionSelected(accepted:))` | `delegate(.generationReminderPreferenceSelected(isEnabled:))` |
| `effect(.waitAtHomeAuthorizationChecked(isAuthorized:))` | 유지 |

### HomeFeature.State

| 필드 | 변경 |
| --- | --- |
| `isProjectRefreshPending: Bool` | **추가** (FR-020) |
| `appliedOutcomeProjectIDs: Set<String>` | **추가** (FR-021) |
| `projectLoad`, `profileLoad`, `generationOutcomeObservation` | 변경 없음 |

#### Action 분류 변경 (FR-026)

| 변경 전 | 변경 후 |
| --- | --- |
| `Action.View.reloadRequested` | `Action.Input.learningProjectsReloadRequested` |

`HomeFeature.Action`에 `input(Input)` 분류를 추가한다.

### AppRootFeature.State 기기 등록 수명

| 상태 | 설명 |
| --- | --- |
| 기기 등록 진행 여부 | 동시 앱 활성화·token 갱신 trigger를 하나의 등록 Effect로 직렬화한다 |
| 마지막 기기 등록 실패 | 인증 세션 소유자가 관찰하며 재시도 성공 또는 인증 종료 전까지 유지한다 |

**전이 규칙(FR-014 ~ FR-016)**:

1. 인증 세션 확립 → 최초 기기 등록을 시작한다.
2. 등록 실패 → 실패 상태를 보존한다.
3. 실패 상태에서 앱 활성화 또는 token 갱신 → 최신 token으로 재시도한다.
4. 동시 trigger → 등록 요청 1회로 직렬화한다.
5. 등록 성공 → 실패 상태를 제거한다.
6. 인증 종료 → 실패 상태와 진행 중인 등록 Effect를 제거한다.

### MainShellFeature.Action.Delegate (FR-030)

| 변경 전 | 변경 후 |
| --- | --- |
| `projectDetailRequested(projectID:)` + `projectSelected(projectID:)` | `projectDetailRequested(projectID:)` 하나 |

### AppRootFeature.State (FR-008, FR-009)

`returnToOnboarding(_:)`이 `projectRegistration = nil`을 수행해 child 수명과 그 child가 시작한
생성 결과 관찰을 함께 종료한다.

## 6. 화면 타입 이름 (FR-028)

| 변경 전 | 변경 후 |
| --- | --- |
| `GenerationConfirmationScreen` | `QuizGenerationConfirmationScreen` |
| `GenerationProgressScreen` | `QuizGenerationProgressScreen` |
| `NotificationOptionSheet` | `GenerationReminderSheet` |
| `QuizLevelSelectionScreen` | 유지 |
| `RepositoryConfirmationScreen` | 유지 |
