# 구현 계획: 생성 결과 원격 알림을 서버의 실제 payload 형식으로 인식하고 로컬 결과 알림 제거

**Git-flow 유형**: `feature`

**브랜치**: `feature/generation-outcome-payload`

**날짜**: 2026-09-30 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/048-generation-outcome-payload/spec.md`의 기능 명세

## 요약

서버의 생성 결과 원격 알림은 `status`가 아니라 최상위 `type`(`QUIZ_READY`는 완료, `QUIZ_REJECTED`는 실패)으로
결과를 보낸다. 그런데 앱은 `status`만 인식해 모든 결과를 버린다. 이 계획은 두 가지를 함께 처리한다.

- **payload 인식**: Data의 `QuizGenerationOutcomeDTO` 한 곳에서 `type`을 먼저 인식하고, 인식하지 못하면
  `status`로 판정한다. 네 수신 경로가 모두 이 판정을 거친다([research R1·R2](./research.md#r1-서버-payload-해석-규칙)).
- **로컬 결과 알림 제거**: 결과 반영이 시작되면 로컬 결과 알림이 서버 알림과 중복되므로, 이 기능을 Domain부터
  Infrastructure까지 걷어낸다([R5](./research.md#r5-로컬-결과-알림-제거-범위fr-010-fr-011)).

나머지 변경은 다음과 같다.

- "홈에서 기다리기"의 권한 시트는 유지하고, 어디에도 쓰이지 않던 선택값 전달만 제거한다([R7](./research.md#r7-홈에서-기다리기-흐름fr-012-fr-013)).
- 설정 화면이 계속 쓰는 권한 계약은 별도 rename 커밋으로 권한 책임 이름으로 바꾼다([R8](./research.md#r8-알림-권한-계약-이름fr-015)).
- 046 문서의 payload 가정을 정정한다([R9](./research.md#r9-이전-명세-기록fr-008-fr-016)).

## 기술 맥락

**언어/버전**: Swift 6(typed throws), iOS 26.0 이상

**주요 의존성**: SwiftUI, TCA(The Composable Architecture), Firebase Messaging(Infrastructure 내부),
UserNotifications(Infrastructure 내부)

**저장소**: App Group 공유 `UserDefaults` 계열 키 값 저장소. 생성 기록 키는 `generationState`로 유지하고,
결과 대기 대기열 키 `pendingGenerationReminders`는 읽기·쓰기를 모두 제거한다.

**테스트**: Swift Testing, TCA `TestStore`. 빌드 실행기의 `build`·`compile`·`test`를 사용한다.

**대상 플랫폼**: iOS 26.0 이상 앱과 공유 확장

**프로젝트 유형**: 모바일 앱(Tuist 멀티 패키지)

**성능 목표**: 해당 없음. payload 판정은 사전 조회 몇 번이다.

**제약 조건**:
- 서버 payload와 API를 바꾸지 않는다(FR-009).
- 폴링을 추가하지 않는다.
- 설정 화면의 알림 권한 동작을 유지한다(FR-011).

**규모/범위**: 운영·테스트 파일 약 55개. 6개 패키지(Domain, Data, Infrastructure, Composition, Feature, App)와
`specs/046-project-list-refresh` 문서 2개가 대상이다.

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

| 원칙 | 점검 | 결과 |
|---|---|---|
| 브랜치 네임스페이스 | `feature/generation-outcome-payload`는 `/speckit-specify`가 2026-09-29에 만들고 2026-09-30에 재사용했다. 047 끝 `e7ad2f1` 위에 있다. | 통과 |
| 허용 수정 경로 | 이 명령은 plan·research·data-model·quickstart·contracts만 만든다. 구현 경로는 아래 "실행 단위"에 기록한다. | 통과 |
| 의존성 방향(architecture.md 7.1) | 새 의존성이 없다. 제거만 한다. Data는 Domain을 모르는 채로 서버 형식만 해석한다. | 통과 |
| 생성자 주입 | `ProjectGeneration`·Assembly·Feature의 주입 인자를 줄이기만 하고, 새 전역 상태나 `@Dependency`를 쓰지 않는다. | 통과 |
| 책임 기반 네이밍(원칙 10) | payload 동작 변경과 rename을 분리한다(U5와 U7). 서버 고정 명칭 `QUIZ_READY`·`QUIZ_REJECTED`·`projectId`·`type`은 원문을 보존한다. | 통과 |
| 위상 순서(원칙 7) | U1→U2→U3은 공개 선언 제거만 하는 단위라 원칙 7의 제거 예외로 사용처부터 역위상 순서를 따른다([R10](./research.md#r10-실행-단위와-위상-순서)). U4~U7은 위상 순서를 지키거나 서로 의존하지 않는다. | 통과(예외 적용) |
| 커밋 단위 구현 | 8개 단위. 다중 패키지 단위 4개(U1·U3·U4·U7)는 아래에 분리 불가 근거와 통합 검증을 적었다. | 통과 |
| 테스트 컨벤션 | 새·수정 테스트는 Swift Testing과 한국어 동작 문장 이름을 쓴다. | 통과 |
| 세션 지식 기록(원칙 9) | 서버 payload가 한 번도 실기기에서 확인되지 않은 채 외부 계약으로 고정된 경위는 문턱을 넘는다. 구현 뒤 `speckit-tacit-knowledge` 또는 `speckit-troubleshooting` 사용 여부를 따로 판단하며, 계획 산출물로 만들지 않는다. | 해당 시 별도 |

설계 후 재점검 결과, 위 판정은 바뀌지 않았다. 복잡성 추적에 올릴 위반은 없다.

## 적용 컨벤션

| 문서 | 이번 설계에 부과한 제약 |
| --- | --- |
| `docs/architecture.md` | Domain·Data는 서로 의존하지 않는다. 서버 형식 해석은 Data, Domain↔Data 변환은 Composition, 결과 반영 규칙은 Domain에 둔다. |
| `docs/package-rules/data.md` | 서버 payload 형식은 Data DTO가 소유한다. Data 공개 이름은 기술(`Local`, `UNUserNotification`)이 아니라 역할을 드러낸다(R8). |
| `docs/package-rules/domain.md` | `ProjectGeneration` 주입 인자와 계약에서 로컬 예약 역할을 뺀다. 결과 반영·보존·만료 규칙은 그대로 둔다. |
| `docs/package-rules/composition.md` | Adapter는 변환만 한다. 사용자 노출 문구를 Composition이 갖지 않으므로, 결과 알림 문구 조립 인자(`Environment`)를 제거하는 것이 원칙과 맞다. |
| `docs/package-rules/infrastructure.md` | 쓰이지 않게 된 기술 API(`schedule`·`present`·`cancel`·`isAuthorized`)를 제거한다. 권한 두 기능은 유지한다. |
| `docs/package-rules/feature.md`, `docs/conventions/tca/README.md` | delegate는 상위가 실제로 쓰는 사건만 둔다. 버려지던 `generationReminderPreferenceSelected`를 제거한다. |
| `docs/package-rules/app.md` | App은 사용자 노출 문구와 기동 순서를 소유한다. 쓰이지 않게 된 결과 알림 문구와 카탈로그를 제거한다. |
| `docs/conventions/naming.md` §7·§8 | 외부 고정 명칭을 보존한다. rename은 동작 변경과 다른 커밋으로 한다(U7). |
| `docs/conventions/localization.md` | App 카탈로그의 키 4개가 모두 제거 대상이므로 `LocalizedText.swift`와 `Localizable.xcstrings`를 함께 삭제한다. Feature 시트 문구 키는 문구가 그대로라 유지한다(R7). |
| `docs/conventions/test.md` | 제거한 동작의 테스트는 삭제하고, 바뀐 동작(`type` 인식)은 새 한국어 동작 문장 테스트로 검증한다. "예약하지 않는다"는 예약 능력 제거와 정적 검색으로 검증한다. |
| `docs/conventions/directory-file.md`, `docs/conventions/file-vocabulary.md` | rename한 타입은 파일 이름도 함께 바꾼다(파일당 타입 1개). 새 폴더는 만들지 않는다. |

## 프로젝트 구조

### 문서(이 기능)

```text
specs/048-generation-outcome-payload/
├── spec.md
├── plan.md              # 이 파일
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── generation-outcome-payload.md
│   └── notification-permission.md
├── checklists/requirements.md
└── tasks.md             # /speckit-tasks 산출물
```

### 소스 코드

아래 경로는 모두 `sources/Projects/` 기준이다.

```text
Domain/ProjectGeneration/{Contracts,Models,UseCases}/   # 로컬 결과 알림 계약·모델·예약 제거
Data/LearningProject/{DTOs,Stores}/                     # payload 인식, 결과 대기 대기열 제거
Data/Notification/{Contracts,Clients,Models,Factories}/ # 예약 능력 제거, 권한 계약 rename
Infrastructure/LocalNotification/{Clients,Models}/      # 예약·표시·취소 API 제거
Composition/{LearningProject,App,ShareExtension}/       # Adapter·조립 인자 제거, rename 반영
Feature/ProjectRegistration/{QuizGenerationProgress,Router}/  # 선택값 전달 제거
App/GitIt/{GitItApp.swift,Localization,Reducers}/       # 결과 알림 문구 제거, delegate 분기 제거
```

**구조 결정**: 기존 패키지·target 구조를 유지하고 파일 삭제와 수정만 한다. App의 `Localization/` 폴더는
비게 되지만 manifest의 resources glob(`Localization/**/*.xcstrings`)은 대상이 없어도 유효하다. 파일을
추가·삭제한 단위마다 `make tuist`로 workspace를 재생성한다.

## 실행 단위

위상 순서와 근거는 [research R10](./research.md#r10-실행-단위와-위상-순서)을 따른다. 각 단위가 끝나면
`"$project_build_runner" compile`을 실행하고, 마지막 단위에서 `build`·`compile`·`test`를 모두 실행한다.

### U1 — [Remove] 생성 결과 로컬 알림 예약 제거 (Domain + Composition + App, 통합 단위)

- **분리 불가 근거**:
  - `GenerationReminderScheduler` 계약과 `ProjectGeneration.init(reminderScheduler:)`를 지우면
    Composition의 Adapter와 Assembly가 compile되지 않는다.
  - `AppComposition.Environment`의 문구 인자를 지우면 App의 `GitItApp`이 compile되지 않는다.
- **Domain**:
  - 삭제: `Domain/ProjectGeneration/Contracts/GenerationReminderScheduler.swift`, `Domain/ProjectGeneration/Models/Records/GenerationReminder.swift`
  - 수정: `Domain/ProjectGeneration/Contracts/PendingGenerationRepository.swift`, `Domain/ProjectGeneration/Models/GenerationWaitPolicy.swift`, `Domain/ProjectGeneration/UseCases/ProjectGeneration.swift`
  - 테스트 삭제: `Domain/Tests/ProjectGeneration/TestDoubles/SpyGenerationReminderScheduler.swift`
  - 테스트 수정: `Domain/Tests/ProjectGeneration/TestDoubles/InMemoryPendingGenerationRepository.swift`, `Domain/Tests/ProjectGeneration/UseCases/ProjectGenerationTests.swift`, `Domain/Tests/ProjectGeneration/Models/GenerationWaitPolicyTests.swift`
- **Composition**:
  - 삭제: `Composition/LearningProject/Adapters/GenerationReminderSchedulerAdapter.swift`
  - 수정: `Composition/LearningProject/Adapters/PendingGenerationRepositoryAdapter.swift`, `Composition/LearningProject/Assemblies/LearningProjectAssembly.swift`, `Composition/App/Assemblies/ConcernUseCaseAssembly.swift`, `Composition/App/Assemblies/AppComposition.swift`, `Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`
  - 테스트 삭제: `Composition/Tests/LearningProject/Adapters/GenerationReminderSchedulerAdapterTests.swift`, `Composition/Tests/LearningProject/TestDoubles/SpyLocalReminderNotifier.swift`, `Composition/Tests/ShareExtension/TestDoubles/SpyLocalReminderNotifier.swift`
  - 테스트 수정: `Composition/Tests/LearningProject/Adapters/PendingGenerationRepositoryAdapterTests.swift`, `Composition/Tests/ShareExtension/ShareExtensionCompositionTests.swift`, `Composition/Tests/App/Assemblies/AppCompositionTests.swift`, `Composition/Tests/App/Assemblies/AppCompositionPublicSurfaceTests.swift`, `Composition/Tests/App/Assemblies/AppCompositionSharedLifetimeTests.swift`
- **App**:
  - 수정: `App/GitIt/GitItApp.swift`
  - 삭제: `App/GitIt/Localization/LocalizedText.swift`, `App/GitIt/Localization/Localizable.xcstrings`, `App/Tests/GitIt/Localization/LocalizedTextTests.swift`
- **검증**:
  - `make tuist` 후 `compile`
  - 결과 반영·보존·만료 테스트는 계속 통과해야 한다(SC-004). SC-007은 예약 능력(계약·Adapter·기술 API) 자체를 제거하고, 잔여 참조 검색(quickstart "2", T057)이 0건인 것으로 검증한다. 예약 주체가 없으므로 실행 시점 테스트는 두지 않는다.

### U2 — [Remove] 결과 대기 대기열 저장과 로컬 알림 예약 능력 제거 (Data)

- 수정: `Data/LearningProject/Stores/LocalPendingGenerationStore.swift`, `Data/Notification/Contracts/LocalReminderNotifier.swift`, `Data/Notification/Clients/ReminderNotificationClient.swift`
- 삭제: `Data/Notification/Models/ReminderNotification.swift`
- 테스트 수정: `Data/Tests/LearningProject/Layouts/GenerationReminderStorageCoordinateTests.swift`, `Data/Tests/LearningProject/Stores/LocalPendingGenerationStoreTests.swift`, `Data/Tests/Notification/Clients/ReminderNotificationClientTests.swift`
- **검증**: `compile`. 이 단위의 수정은 권한 조회·요청 테스트(SC-009)를 건드리지 않는다.

### U3 — [Remove] 로컬 알림 예약·표시·취소 기술 API 제거 (Infrastructure + Data 테스트 더블, 통합 단위)

- **분리 불가 근거**: Data 테스트 더블 `SpyNotificationAuthorizationClient`는 Infrastructure 프로토콜을 준수하고
  `LocalNotificationRequest`를 참조한다. Data의 `ReminderNotificationClient`도 같은 프로토콜의 구현을 받는다.
- 수정: `Infrastructure/LocalNotification/Clients/NotificationAuthorizationClient.swift`, `Infrastructure/LocalNotification/Clients/LocalNotificationAuthorizationClient.swift`
- 삭제: `Infrastructure/LocalNotification/Models/LocalNotificationRequest.swift`
- Data 테스트 수정: `Data/Tests/Notification/TestDoubles/SpyNotificationAuthorizationClient.swift`
- **검증**: `make tuist` 후 `compile`

### U4 — [Refactor] 홈에서 기다리기 선택값 전달 제거 (Feature + App, 통합 단위)

- **분리 불가 근거**: `ProjectRegistrationRouterFeature.Action.Delegate.generationReminderPreferenceSelected`를
  지우면 `AppRootFeature`의 exhaustive `switch`가 compile되지 않는다.
- Feature 수정: `Feature/ProjectRegistration/QuizGenerationProgress/QuizGenerationProgressFeature.swift`, `Feature/ProjectRegistration/Router/ProjectRegistrationRouterFeature.swift`
- Feature 테스트 수정: `Feature/Tests/ProjectRegistration/QuizGenerationProgress/QuizGenerationProgressFeatureTests.swift`, `Feature/Tests/ProjectRegistration/Router/ProjectRegistrationRouterFeatureTests.swift`
- App 수정: `App/GitIt/Reducers/AppRootFeature.swift`
- **검증**:
  - `compile`
  - 권한 상태 4가지에서 홈 이동과 권한 요청·설정 열기를 검증한다(SC-008).
  - 시트 View·프리뷰·문구 키는 변경하지 않는다.

### U5 — [Fix] 생성 결과 원격 알림을 서버 type 값으로 인식 (Data)

- 수정: `Data/LearningProject/DTOs/QuizGenerationOutcomeDTO.swift`
- 테스트 수정: `Data/Tests/LearningProject/DTOs/QuizGenerationOutcomeDTOTests.swift`, `Data/Tests/LearningProject/Sources/PushQuizGenerationOutcomeSourceTests.swift`
- **검증**:
  - `compile`
  - [contracts/generation-outcome-payload.md](./contracts/generation-outcome-payload.md)의 판정표를 모두 검증한다(SC-001·SC-003). 관찰 payload 원문 3건은 전달 계층 키를 포함해 그대로 사용한다.

### U6 — [Test] 알림 센터 경로의 서버 type payload 반영 검증 (Composition)

- 테스트 수정: `Composition/Tests/LearningProject/Adapters/GenerationOutcomeRepositoryAdapterTests.swift`
- **검증**: 알림 센터 읽기 경로에서 `QUIZ_READY`·`QUIZ_REJECTED` payload가 완료·실패 결과가 되는지 확인한다
  (FR-003, SC-001). 이 단위는 운영 코드를 바꾸지 않는다.

### U7 — [Rename] 알림 권한 계약 이름을 권한 책임으로 변경 (Data + Composition, 통합 단위)

- **분리 불가 근거**: Data 공개 계약·모델·생성 진입점 이름을 바꾸면 Composition의 `NotificationAuthorizationAdapter`와
  `ConcernUseCaseAssembly`가 같은 커밋에서 따라가야 compile된다.
- 이름 대응은 [research R8](./research.md#r8-알림-권한-계약-이름fr-015)과 [contracts/notification-permission.md](./contracts/notification-permission.md)를 따른다.
- Data 파일 rename:
  - `Data/Notification/Contracts/LocalReminderNotifier.swift` → `NotificationPermissionRequester.swift`
  - `Data/Notification/Clients/ReminderNotificationClient.swift` → `NotificationPermissionClient.swift`
  - `Data/Notification/Models/ReminderAuthorizationSetting.swift` → `NotificationPermissionSetting.swift`
  - `Data/Notification/Models/ReminderAuthorizationStatus.swift` → `NotificationPermissionRequestResult.swift`
- Data 수정: `Data/Notification/Factories/NotificationFactory.swift`
- Data 테스트 rename:
  - `Data/Tests/Notification/Clients/ReminderNotificationClientTests.swift` → `NotificationPermissionClientTests.swift`
  - `Data/Tests/LearningProject/Layouts/GenerationReminderStorageCoordinateTests.swift` → `PendingGenerationStorageCoordinateTests.swift`
- Composition 수정: `Composition/LearningProject/Adapters/NotificationAuthorizationAdapter.swift`, `Composition/App/Assemblies/ConcernUseCaseAssembly.swift`
- **검증**:
  - `make tuist` 후 `compile`
  - 동작 변경이 없는지 확인한다. 테스트 본문은 식별자 외에 바꾸지 않는다.

### U8 — [Docs] 046 서버 payload 가정 정정 (문서, 마지막 단위)

- 수정: `specs/046-project-list-refresh/spec.md`, `specs/046-project-list-refresh/device-verification.md`
- **검증**:
  - 전체 `build`·`compile`·`test`와 필수 `after_implement` hook(`speckit.swift-format.run`)을 실행한다.
  - SC-010 검색을 실행한다. 로컬 결과 알림 전용 식별자·저장 키·문구 참조가 0건이어야 한다.
  - 실기기 확인(SC-005)은 [quickstart.md](./quickstart.md)를 따르며, 수행하지 못하면 미검증으로 기록한다.

## 복잡성 추적

헌법 점검에서 정당화가 필요한 위반이 없다.
