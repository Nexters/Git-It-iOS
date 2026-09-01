# 계약: 공개 이름 변경 매핑

**기능 브랜치**: `feature/registration-flow-review-fixes`

이 표가 rename 작업의 정본이다. 각 행은 **소유 패키지**와 **컴파일 소비자**를 함께 적는다.
소비자가 소유 패키지와 다르면 그 rename은 불가분한 다중 패키지 단위에 속한다.

## 1. Domain (`DomainLearningProject`)

| 변경 전 | 변경 후 | 소비자 | 근거 |
| --- | --- | --- | --- |
| `LearningProjectOutcomesUseCase` | `ObserveGenerationOutcomesUseCase` | Composition, Feature, App | FR-022a |
| `LearningProjectOutcomes` | `ObserveGenerationOutcomes` | Composition | FR-022a |
| `UseCases/LearningProjectOutcomes/` | `UseCases/ObserveGenerationOutcomes/` | — | FR-022a |
| 주입 프로퍼티 `learningProjectOutcomes` | `observeGenerationOutcomes` | Composition, Feature, App | FR-022a |

`GenerationOutcome`, `GenerationOutcomeRepository`는 변경하지 않는다.

## 2. Data (`DataLearningProject`)

| 변경 전 | 변경 후 | 소비자 | 근거 |
| --- | --- | --- | --- |
| `GenerationOutcomeDTO` | `QuizGenerationOutcomeDTO` | Composition | FR-022b |
| `GenerationOutcomeStream` | `QuizGenerationOutcomeSource` | Composition | FR-022b, FR-027 |
| `PushGenerationOutcomeStream` | `PushQuizGenerationOutcomeSource` | Composition | FR-022b, FR-027 |
| `Remotes/PushGenerationOutcomeStream.swift` | `Sources/PushQuizGenerationOutcomeSource.swift` | — | FR-027 |
| 지역 변수 `id` | `subscriptionID` | — | 리포트 §4 |

**함께 갱신**: `docs/conventions/file-vocabulary.md` §3 `Data/<관심사>/` 행에 `Sources/` 추가.

## 3. Infrastructure (`InfrastructurePushMessaging`)

| 변경 전 | 변경 후 | 소비자 | 근거 |
| --- | --- | --- | --- |
| `PushNotificationCallbacks.ingestPushPayload` | `ingestGenerationOutcomePayload` | Composition | FR-025 |
| `FirebaseMessagingAppDelegate.state` (static) | 인스턴스 `callbacks` + 대기 슬롯 | Composition, App | FR-017 |

## 4. Composition (`CompositionAdapter`)

| 변경 전 | 변경 후 | 소비자 | 근거 |
| --- | --- | --- | --- |
| `AppComposition.ingestPushPayload` | `ingestGenerationOutcomePayload` | App | FR-025 |
| `AppComposition.deviceID(keychainStore:)` | `loadOrCreateDeviceID(keychainStore:)` | 내부 | FR-029 |
| `GenerationOutcomeRepositoryAdapter(remote:)` | `(source:)` | 내부 | FR-027 |

## 5. Feature

### `FeatureProjectRegistration`

| 변경 전 | 변경 후 | 소비자 | 근거 |
| --- | --- | --- | --- |
| `SubmissionStatus` | `RegistrationProgress` | Feature 내부 | FR-023 |
| `.committing` | `.submitting` | Feature 내부 | FR-023 |
| `.awaitingGeneration` | `.awaitingOutcome` | Feature 내부 | FR-023 |
| `State.submission` | `State.progress` | Feature 내부 | FR-023 |
| `isNotificationOptionSheetPresented` | `isGenerationReminderSheetPresented` | Feature 내부 | FR-024 |
| `view(.notificationOptionAccepted)` | `view(.generationReminderAccepted)` | Feature 내부 | FR-024 |
| `view(.notificationOptionDeclined)` | `view(.generationReminderDeclined)` | Feature 내부 | FR-024 |
| `delegate(.notificationOptionSelected(accepted:))` | `delegate(.generationReminderPreferenceSelected(isEnabled:))` | **App** | FR-024 |
| `NotificationOptionSheet` | `GenerationReminderSheet` | Feature 내부 | FR-024, FR-028 |
| `GenerationConfirmationScreen` | `QuizGenerationConfirmationScreen` | Feature 내부 | FR-028 |
| `GenerationProgressScreen` | `QuizGenerationProgressScreen` | Feature 내부 | FR-028 |

### `FeatureHome`

| 변경 전 | 변경 후 | 소비자 | 근거 |
| --- | --- | --- | --- |
| `Action.View.reloadRequested` | `Action.Input.learningProjectsReloadRequested` | **App** | FR-026 |

### `FeatureMainShell`

| 변경 전 | 변경 후 | 소비자 | 근거 |
| --- | --- | --- | --- |
| `Delegate.projectSelected(projectID:)` | 제거, `projectDetailRequested(projectID:)`로 통합 | **App** | FR-030 |

## 6. App (`GitIt`)

| 변경 전 | 변경 후 | 근거 |
| --- | --- | --- |
| `openNotificationSettings: @Sendable () async -> Void` | `@MainActor @Sendable () async -> Void` | FR-010, FR-011 |

이 타입 변경은 `ProjectRegistrationFeature` → `AppRootFeature` → `GitItApp` 전 경로에 동일하게
적용한다.

## 7. 검증

rename 완료 후 아래 심볼이 `sources/Projects` 전체에서 0건이어야 한다(SC-010).

```text
LearningProjectOutcomes
GenerationOutcomeDTO
GenerationOutcomeStream
PushGenerationOutcomeStream
SubmissionStatus
notificationOption
ingestPushPayload
```

`projectSelected`는 0건 검색 대상이 아니다. 제거 대상은 `MainShellFeature`가 **외부로 내보내는**
`Delegate.projectSelected(projectID:)` 하나이며, 아래 두 참조는 rename 후에도 남는다.

- `ProjectListFeature.Delegate.projectSelected(projectID:)` — child 소유 UI 사건, §5 범위 밖
- `MainShellFeature`의 child delegate 수신 패턴
  `case .projectList(.delegate(.projectSelected(let projectID))):` — 방출 대상만
  `projectDetailRequested`로 바뀐다

따라서 `sources/Projects/App`에서만 0건을 확인하고, `MainShellFeature`는 `Delegate` 선언과
방출부에서 사라졌는지를 확인한다.

추가로 Domain 공개 surface에 `QuizGeneration` 0건, 생성 결과 타입 이름에 `LearningSet` 0건을
확인한다.
