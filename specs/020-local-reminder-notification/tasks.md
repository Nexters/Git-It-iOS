---

description: "기능 구현 작업 목록 템플릿"
---

# 작업 목록: 생성 완료 리마인드 알림의 실제 권한 요청과 로컬 알림 발송

**입력**: `/specs/020-local-reminder-notification/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/notification-permission-contracts.md](./contracts/notification-permission-contracts.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를
snapshot한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만
선택한다.

**테스트**: [contracts/notification-permission-contracts.md](./contracts/notification-permission-contracts.md)의
독립 검증 절이 각 패키지 신규 계약에 대한 테스트를 명시하므로 아래 각 패키지에 테스트 작업을
포함한다(InfrastructurePushMessaging은 기존 관례대로 테스트 target이 없어 build 검증만
포함한다).

**구성**: 실행 단위를 최상위 구조로 사용하고 변경 시나리오는 각 단위 안에서 추적한다. 위상
순서는 [plan.md](./plan.md)의 "실행 단위와 패키지 위상 순서"를 그대로 따른다: **Domain →
Infrastructure → Feature → Composition → App**.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[시나리오]**: S1(알림 옵션 수락 시 실제 권한 요청), S2(권한 허용 시 완료 신호로 로컬 알림
  발송), S3(생성 실패는 로컬 알림 대상 아님)
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 실행 또는 수동
  검증
- 파일 변경 작업은 정확한 저장소 상대 경로와 책임 패키지를 가진다.

## 실행 단위 소유권 규칙

- 패키지 소스·테스트와 패키지 전용 설정은 해당 패키지 단계가 소유한다.
- 준비, 기반, 정리와 횡단 관심사는 별도 구현 단계로 만들지 않고 책임 패키지 단계에 넣는다.
- 019가 이미 구현한 `LearningProjectOutcomesUseCase`, `LearningProjectGenerationOutcome`,
  `openNotificationSettings` 배선은 변경하지 않는다(재사용만 한다).

---

## 작업 패키지 1: Domain(`DomainLearningProject`)

**목표**: 알림 권한 확인·요청과 리마인드 대상 등록이라는 비즈니스 규칙을 명시적 UseCase와
계약으로 정의한다. Feature가 Infrastructure 결과 타입을 직접 참조하지 않고 이 Domain 타입만
받도록 하는 것이 목적이다(연구 근거: [research.md](./research.md) 3절).

**소유 경로**: `sources/Projects/Domain/LearningProject/Models/`,
`sources/Projects/Domain/LearningProject/Contracts/`,
`sources/Projects/Domain/LearningProject/UseCases/RequestGenerationReminder/`,
`sources/Projects/Domain/Tests/LearningProject/UseCases/`

**관련 변경 시나리오**: S1, S2

**독립 검증**: `DomainLearningProject`와 그 Tests target만 build·test하며, 이 패키지가 다른
프로젝트 내부 패키지에 의존하지 않고도 컴파일·테스트되는지 확인한다.

### 구현

- [X] T001 [P] [S1] `sources/Projects/Domain/LearningProject/Models/NotificationAuthorizationOutcome.swift`에
      `NotificationAuthorizationOutcome`(`authorized`/`declined`/`previouslyDenied`, `Sendable,
      Equatable`) enum을 [data-model.md](./data-model.md)에 따라 정의한다.
- [X] T002 [P] [S1] `sources/Projects/Domain/LearningProject/Contracts/NotificationAuthorizationGateway.swift`에
      `NotificationAuthorizationGateway` 프로토콜(`func requestAuthorization() async ->
      NotificationAuthorizationOutcome`)을
      [contracts/notification-permission-contracts.md](./contracts/notification-permission-contracts.md)
      1.2절에 따라 정의한다.
- [X] T003 [P] [S2] `sources/Projects/Domain/LearningProject/Contracts/GenerationReminderRegistry.swift`에
      `GenerationReminderRegistry` 프로토콜(`func register(projectID: String) async`)을 계약
      1.3절에 따라 정의한다.
- [X] T004 [S1] [S2] `sources/Projects/Domain/LearningProject/UseCases/RequestGenerationReminder/RequestGenerationReminderUseCase.swift`에
      `RequestGenerationReminderUseCase` 프로토콜(`func callAsFunction(projectID: String) async
      -> NotificationAuthorizationOutcome`)을 계약 1.4절에 따라 정의한다.
- [X] T005 [S1] [S2] `sources/Projects/Domain/LearningProject/UseCases/RequestGenerationReminder/RequestGenerationReminder.swift`에
      `RequestGenerationReminder` 구조체를 계약 1.4절 스니펫대로 구현한다:
      `authorizationGateway.requestAuthorization()` 결과가 `.authorized`일 때만
      `reminderRegistry.register(projectID:)`를 호출하고 결과를 그대로 반환한다.

### 테스트

- [X] T006 [S1] [S2] `sources/Projects/Domain/Tests/LearningProject/UseCases/RequestGenerationReminderTests.swift`를
      새로 만들어(`LearningProjectOutcomesTests.swift`와 동일한 스타일로 파일 하단에 stub
      `NotificationAuthorizationGateway`/`GenerationReminderRegistry`를 정의) 세 경우를
      검증한다: (1) `.authorized` 반환 시 `register(projectID:)`가 정확히 1회 호출된다, (2)
      `.declined` 반환 시 `register`가 호출되지 않는다, (3) `.previouslyDenied` 반환 시
      `register`가 호출되지 않는다. 세 케이스 모두 `RequestGenerationReminder.callAsFunction`의
      반환값이 gateway의 반환값과 같은지도 확인한다.

### 정리와 패키지 검증

- [X] T007 [no-write] `DomainLearningProject`와 `DomainLearningProject` Tests target을
      build·test해 T001~T006이 다른 프로젝트 내부 패키지 의존 없이 컴파일·통과하는지 확인한다.

**진행 점검**: T001~T007의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행
단위(Infrastructure)로 진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을
요청한다.

---

## 작업 패키지 2: Infrastructure(`InfrastructurePushMessaging`)

**목표**: `UNUserNotificationCenter`를 프로젝트 소유 기술 API로 감싸, 권한 확인·요청과 로컬
알림 발송을 제공한다.

**소유 경로**: `sources/Projects/Infrastructure/PushMessaging/Clients/`

**관련 변경 시나리오**: S1, S2

**독립 검증**: `InfrastructurePushMessaging` target만 build한다(기존
`FirebaseMessagingPushClient`와 동일하게 이 target은 별도 테스트 target을 두지 않는다).

### 구현

- [X] T008 [P] [S1] [S2] `sources/Projects/Infrastructure/PushMessaging/Clients/LocalNotificationClient.swift`에
      `LocalNotificationClient` 프로토콜(`requestAuthorization() async ->
      LocalNotificationAuthorizationOutcome`, `isAuthorized() async -> Bool`,
      `presentGenerationCompletedNotification(projectID: String)`)과
      `LocalNotificationAuthorizationOutcome`(`authorized`/`declined`/`previouslyDenied`) enum을
      계약 2.1절에 따라 정의한다.
- [X] T009 [S1] [S2] `sources/Projects/Infrastructure/PushMessaging/Clients/UNUserNotificationCenterLocalNotificationClient.swift`에
      T008을 구현하는 `UNUserNotificationCenterLocalNotificationClient`를 계약 2.2절에 따라
      작성한다: `requestAuthorization()`은 `UNUserNotificationCenter.current().notificationSettings()`로
      현재 상태를 조회해 `.notDetermined`일 때만 `requestAuthorization(options: [.alert, .badge,
      .sound])`를 호출하고, `.denied`는 다이얼로그 없이 `.previouslyDenied`를, 이미
      허용된 상태는 `.authorized`를 반환한다. `isAuthorized()`는 허용 계열 상태에서만
      `true`를 반환한다. `presentGenerationCompletedNotification(projectID:)`는
      [data-model.md](./data-model.md)의 필드 표대로 `identifier:
      "generation-completed-\(projectID)"`, `trigger: nil`인 `UNNotificationRequest`를 구성해
      `UNUserNotificationCenter.current().add(_:)`로 등록한다.

### 정리와 패키지 검증

- [X] T010 [no-write] `InfrastructurePushMessaging` target을 build해 T008~T009가
      `UserNotifications` 프레임워크와 함께 컴파일되는지 확인한다.

**진행 점검**: T008~T010의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행
단위(Feature)로 진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을 요청한다.

---

## 작업 패키지 3: Feature(`Feature`)

**목표**: 알림 옵션 수락 시 `RequestGenerationReminderUseCase`를 호출해 실제 권한을
확인·요청하고, 결과가 `.previouslyDenied`일 때만 기존 `openNotificationSettings`로 설정
화면을 안내한다.

**소유 경로**: `sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`,
`sources/Projects/Feature/ProjectRegistration/Previews/ProjectRegistrationScreenPreviews.swift`,
`sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/`,
`sources/Projects/Feature/Tests/ProjectRegistration/Reducers/ProjectRegistrationFeatureTests.swift`

**관련 변경 시나리오**: S1

**독립 검증**: `Feature`(`FeatureTests`)만 build·test하며, 이 패키지가
Domain·UI에만 의존하고 Infrastructure를 참조하지 않는지 확인한다.

### 테스트

- [ ] T011 [P] [S1] `sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/StubRequestGenerationReminderUseCase.swift`를
      새로 만들어 `StubFetchExternalRepositoryUseCase.swift`와 같은 스타일의 actor로
      `RequestGenerationReminderUseCase`를 구현한다. 스크립트된
      `[NotificationAuthorizationOutcome]` 결과열과 `callCount`, 마지막으로 전달된
      `projectID`를 기록하는 `snapshot()`을 제공한다.
- [ ] T012 [S1] `sources/Projects/Feature/Tests/ProjectRegistration/Reducers/ProjectRegistrationFeatureTests.swift`의
      `makeProjectRegistrationStore` 헬퍼에 `requestGenerationReminder:
      StubRequestGenerationReminderUseCase = StubRequestGenerationReminderUseCase(results:
      [.authorized])` 인자를 추가하고 `ProjectRegistrationFeature(...)` 생성 호출에 전달한다.
      이어서 세 케이스를 검증하는 테스트를 추가한다: (1) `.authorized` 결과에서
      `notificationOptionAccepted`를 보내면 `openNotificationSettings`가 호출되지 않고 기존
      `finishWaiting`(delegate `.projectRegistered`) 동작이 그대로 유지된다, (2) `.declined`
      결과에서도 `openNotificationSettings`가 호출되지 않는다, (3) `.previouslyDenied`
      결과에서는 `openNotificationSettings`가 정확히 1회 호출된다. `openNotificationSettings`
      호출 여부는 기존 테스트가 쓰는 spy 패턴(예: 호출 횟수를 세는 actor)으로 확인한다.

### 구현

- [ ] T013 [S1] `sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`를
      수정한다: `init`에 `requestGenerationReminder: any RequestGenerationReminderUseCase`를
      (기본값 없이) `learningProjectOutcomes` 다음, `openNotificationSettings` 앞에 추가하고
      `private let requestGenerationReminder: any RequestGenerationReminderUseCase`를
      저장한다. `.view(.notificationOptionAccepted)` 처리를 계약 4.2절 스니펫대로 바꿔
      `requestGenerationReminder(projectID: receipt.projectID)`를 호출하고, 반환값이
      `.previouslyDenied`일 때만 `openNotificationSettings()`를 호출한다. 나머지
      로직(`finishWaiting`과의 `.merge`, `isNotificationOptionSheetPresented = false`)은
      유지한다.
- [ ] T014 [S1] `sources/Projects/Feature/ProjectRegistration/Previews/ProjectRegistrationScreenPreviews.swift`를
      수정한다: 기존 `PreviewFetchExternalRepositoryUseCase` 등과 같은 위치에
      `PreviewRequestGenerationReminderUseCase`(`RequestGenerationReminderUseCase` 채택,
      `.authorized`를 반환)를 추가하고, `ProjectRegistrationFeature(...)` 생성 호출에
      `requestGenerationReminder: PreviewRequestGenerationReminderUseCase()`를 전달한다.

### 정리와 패키지 검증

- [ ] T015 [no-write] `Feature`와 `FeatureTests`
      target을 build·test해 T011~T014가 통과하는지 확인하고, `grep`으로 이 패키지 소스가
      `InfrastructurePushMessaging`을 import하지 않는지 확인한다.

**진행 점검**: T011~T015의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행
단위(Composition)로 진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을
요청한다.

---

## 작업 패키지 4: Composition(`Composition`)

**목표**: Domain 계약을 Infrastructure/내부 조정자로 구현하고, `AppComposition`이
`requestGenerationReminder` UseCase를 명시적으로 공개하도록 배선한다.

**소유 경로**: `sources/Projects/Composition/Adapter/Adapters/`,
`sources/Projects/Composition/Adapter/Factories/`,
`sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`,
`sources/Projects/Composition/Tests/Adapter/Assemblies/AppCompositionPublicSurfaceTests.swift`

**관련 변경 시나리오**: S1, S2, S3

**독립 검증**: `Composition`과 그 Tests target만 build·test하며, `AppComposition`의 공개
표면이 예상한 이름과 타입만 노출하는지 확인한다.

### 구현

- [ ] T016 [P] [S1] `sources/Projects/Composition/Adapter/Factories/GenerationCompletionReminderCoordinator.swift`에
      `GenerationCompletionReminderCoordinator` actor를 계약 3.1절에 따라 구현한다:
      `init(localNotificationClient: any LocalNotificationClient)`, `Set<String>`으로 등록된
      projectID를 관리하는 `register(projectID: String)`, 그리고
      `start(learningProjectOutcomes: any LearningProjectOutcomesUseCase)`—`Task { for await
      outcome in await learningProjectOutcomes() { ... } }`를 시작해 등록된 projectID의 완료
      (`.completed`) 이벤트만 `localNotificationClient.isAuthorized()`가 `true`일 때
      `presentGenerationCompletedNotification(projectID:)`를 호출하고, 등록 여부와 무관하게
      완료·실패(`.failed`) 이벤트 수신 시 해당 projectID를 집합에서 제거한다(S3: 실패는 발송
      없이 제거만).
- [ ] T017 [P] [S1] `sources/Projects/Composition/Adapter/Adapters/NotificationAuthorizationGatewayAdapter.swift`에
      `NotificationAuthorizationGatewayAdapter`(`NotificationAuthorizationGateway` 채택)를
      계약 3.2절 스니펫대로 구현해 `LocalNotificationAuthorizationOutcome` →
      `NotificationAuthorizationOutcome` 1:1 변환을 수행한다.
- [ ] T018 [P] [S1] [S2] `sources/Projects/Composition/Adapter/Adapters/GenerationReminderRegistryAdapter.swift`에
      `GenerationReminderRegistryAdapter`(`GenerationReminderRegistry` 채택)를 계약 3.3절
      스니펫대로 구현해 `coordinator.register(projectID:)`로 위임한다.
- [ ] T019 [S1] [S2] `sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`를
      수정한다: `public let requestGenerationReminder: any RequestGenerationReminderUseCase`를
      `learningProjectOutcomes` 선언 다음에 추가한다. `AppComposition.init` 안, 기존 FCM
      등록 토큰 `Task` 근처에서 (a) `UNUserNotificationCenterLocalNotificationClient()`를
      생성하고, (b) `GenerationCompletionReminderCoordinator(localNotificationClient:)`를
      생성해 `coordinator.start(learningProjectOutcomes:
      learningProject.learningProjectOutcomes)`를 호출하며, (c)
      `requestGenerationReminder = RequestGenerationReminder(authorizationGateway:
      NotificationAuthorizationGatewayAdapter(localNotificationClient:), reminderRegistry:
      GenerationReminderRegistryAdapter(coordinator:))`로 대입한다.

### 테스트

- [ ] T020 [S1] [S2] [S3] `sources/Projects/Composition/Tests/Adapter/Factories/GenerationCompletionReminderCoordinatorTests.swift`를
      새로 만들어(`ExternalRepositoryLookupAdapterTests.swift`와 같은 스타일로 파일 하단에
      stub `LocalNotificationClient`와 스크립트 가능한 `LearningProjectOutcomesUseCase` 스텁을
      정의) 다음을 검증한다: (1) `register(projectID:)` 호출 후 같은 projectID의 `.completed`
      이벤트가 도착하고 stub가 `isAuthorized() == true`를 반환하면
      `presentGenerationCompletedNotification(projectID:)`가 정확히 1회 호출된다, (2) 같은
      상황에서 `isAuthorized() == false`면 호출되지 않는다, (3) 등록하지 않은 projectID의
      `.completed` 이벤트는 무시된다(S1 경계), (4) 등록된 projectID의 `.failed` 이벤트는
      발송 없이 등록 집합에서 제거만 한다(S3), (5) 같은 projectID에 `.completed` 이벤트가
      두 번 도착해도 발송은 1회뿐이다(중복 방지, FR-010).
- [ ] T021 [S1] `sources/Projects/Composition/Tests/Adapter/Assemblies/AppCompositionPublicSurfaceTests.swift`(기존
      파일 수정)의 `expected` 집합에 `"requestGenerationReminder"`를 추가해 공개 표면 목록을
      갱신한다.

### 정리와 패키지 검증

- [ ] T022 [no-write] `Composition`과 `Composition` Tests target을 build·test해 T016~T021이
      통과하는지 확인한다.

**진행 점검**: T016~T022의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행
단위(App)로 진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을 요청한다.

---

## 작업 패키지 5: App(`GitIt`)

**목표**: `AppComposition.requestGenerationReminder`를 `AppRootFeature`를 거쳐
`ProjectRegistrationFeature`까지 배선한다.

**소유 경로**: `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`,
`sources/Projects/App/GitIt/GitItApp.swift`,
`sources/Projects/App/Tests/GitIt/TestDoubles/AppRootTestSupport.swift`

**관련 변경 시나리오**: S1

**독립 검증**: `GitIt` App target과 그 Tests target을 build·test하며, 기존
`notificationOptionSelected` delegate 처리(`AppRootFeature.swift` 203번째 줄 부근, `.none`
유지)가 변경되지 않았는지 확인한다.

### 구현

- [ ] T023 [S1] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`를 수정한다:
      `init`에 `requestGenerationReminder: any RequestGenerationReminderUseCase`를(기본값
      없이) `learningProjectOutcomes` 다음, `openNotificationSettings` 앞에 추가하고
      `private let requestGenerationReminder: any RequestGenerationReminderUseCase`를 저장한다.
      `.ifLet(\.$projectRegistration, action: \.projectRegistration)`가 생성하는
      `ProjectRegistrationFeature(...)` 호출에 `requestGenerationReminder:
      requestGenerationReminder`를 전달한다.
- [ ] T024 [S1] `sources/Projects/App/GitIt/GitItApp.swift`를 수정한다: `AppRootFeature(...)`
      생성 호출의 `openNotificationSettings` 인자 옆에 `requestGenerationReminder:
      composition.requestGenerationReminder`를 추가한다.

### 테스트

- [ ] T025 [S1] `sources/Projects/App/Tests/GitIt/TestDoubles/AppRootTestSupport.swift`를
      수정한다: `NoopRequestGenerationReminderUseCase`(`RequestGenerationReminderUseCase`
      채택, `.authorized` 반환)를 다른 `Noop*UseCase`와 같은 위치에 추가하고,
      `makeAppRootStore`에 `requestGenerationReminder: NoopRequestGenerationReminderUseCase =
      NoopRequestGenerationReminderUseCase()` 인자를 추가해 `AppRootFeature(...)` 생성 호출에
      전달한다.

### 정리와 패키지 검증

- [ ] T026 [no-write] `GitIt` App target build와 `GitIt` Tests target test를 실행해
      T023~T025가 통과하는지, 기존 `notificationOptionSelected` delegate 관련 테스트가
      회귀 없이 통과하는지 확인한다.

**진행 점검**: T023~T026의 변경 파일과 검증 결과를 보고한다. App이 마지막 적용 대상
패키지이므로 다음은 전체 완료 검증이다.

---

## 전체 완료 검증

**선행 조건**: 작업 패키지 5(App)의 파일 변경 작업을 완료하고, 전체 검증과 hook 결과를
포함할 마지막 커밋 단위를 아직 commit하지 않은 상태여야 한다.

**커밋 경계**: 아래 `[no-write]` 작업은 작업 패키지 5의 마지막 커밋 단위에 배정한다. 모든
검증과 필수 `after_implement` hook을 마친 뒤 그 단위를 최종 commit한다. 읽기 전용 전체
검증은 반복 승인 없이 같은 실행에서 이어서 수행한다.

- [ ] T027 [no-write] `project_build_runner`로 전체 `build`, `compile`,
      `test`(`GIT_IT_PROJECT_BUILD_RUNNER`)를 순차 실행하고 결과를 기록한다.
- [ ] T028 [no-write] [S1] [S2] [S3] [quickstart.md](./quickstart.md)의 시뮬레이터 수동 검증
      절차(권한 미결정 시 다이얼로그, 이미 거부 시 설정 안내, Home 복귀 후 리마인드 지속,
      실패 신호에서 로컬 알림 미발송)를 수행한다. T006·T012·T020의 자동화 테스트로 이미
      검증된 판정 로직은 여기서 다시 단정하지 않고, 실제 iOS 알림 권한 다이얼로그·설정 앱
      전환처럼 자동화할 수 없는 시스템 UI 동작만 수동으로 확인해 기록한다.

## 의존성과 실행 순서

### 실행 단위 순서와 위험 기반 승인

- 채택 순서는 [plan.md](./plan.md)의 "실행 단위와 패키지 위상 순서"와 동일하다: **Domain(1) →
  Infrastructure(2) → Feature(3) → Composition(4) → App(5)**. Domain과 Infrastructure는 서로
  의존하지 않아 병렬 진행도 가능하지만, 이 문서는 Domain을 먼저 배치했다(Feature가 Domain
  계약을 다음 단계에서 바로 소비하기 때문).
- Composition(4)은 Domain(1)의 계약과 Infrastructure(2)의 구현이 모두 필요하므로 두 단위
  완료 후에 시작한다.
- App(5)은 Feature(3)와 Composition(4)이 모두 끝나야 두 계약을 연결할 수 있으므로 마지막에
  진행한다.
- 각 단위를 완료·검증한 뒤 다음 단위로 진행하며, 같은 기능 범위에서는 반복 승인을 요구하지
  않는다. 새 범위, 파괴적 작업, remote·외부 상태 변경, 새로운 제품 결정이 필요할 때만
  중단하고 명시적 승인을 요청한다.

### 변경 시나리오 추적성

- **S1**(알림 옵션 수락 시 실제 권한 요청): T001~T006(Domain), T008~T010(Infrastructure),
  T011~T015(Feature), T016~T022(Composition), T023~T026(App) 전체가 관여한다. 독립 수용
  기준은 spec.md 시나리오 1의 4개 수용 시나리오이며, T012(Feature 자동화)·T020(Composition
  조정자 자동화)·T028(실제 시스템 다이얼로그 수동 확인)로 검증한다.
- **S2**(권한 허용 시 완료 신호로 로컬 알림 발송): T003~T006(Domain 등록 계약), T008~T010
  (Infrastructure 발송), T016·T018~T019(Composition 조정자·배선)가 관여한다. 독립 수용
  기준은 spec.md 시나리오 2이며, T020(`GenerationCompletionReminderCoordinatorTests`)이
  등록·발송·Home 복귀 후 지속(등록이 화면 생존과 무관함)·중복 방지를 자동화로 검증하고,
  T028은 실제 기기·FCM 신호를 쓰는 종단 확인만 보완한다.
- **S3**(생성 실패는 로컬 알림 대상 아님): T016의 `.failed` 분기(집합 제거만, 발송 없음)가
  구현하며, T020이 자동화로 검증하고 T028이 quickstart 종단 확인으로 보완한다.
- 최소 가치 범위도 동일한 위험 기반 승인 기준을 적용한다.

### 실행 단위 내부 실행

- 테스트가 있는 단위는 같은 패키지 구현 전에 작성하고(T006 전에 T001~T005, T011~T012 전에
  실제로는 순서상 스텁을 먼저 만들고(T011) 이어서 실패 확인 없이 시나리오 테스트를 작성한다
  (T012)), 구현 후 통과를 확인한다. TDD가 명시적으로 요구되지 않았으므로 "실패를 먼저
  확인"하는 절차는 선택이다.
- `[P]`는 현재 실행 단위 안의 서로 다른 파일에만 사용한다: Domain의 T001~T003, Infrastructure의
  T008, Feature의 T011, Composition의 T016~T018이 해당한다(T020은 T016~T019 구현 완료 후
  작성하므로 병렬 대상이 아니다).
- 서로 다른 실행 단위의 Git index·같은 파일 변경은 병렬 실행하지 않는다.
- `/speckit-implement`는 각 패키지 단위 안의 미완료 작업을 하나의 목적을 갖는 순서화된 커밋
  단위로 묶는다(예: Domain 단위는 T001~T007을 한 커밋으로, Feature 단위는 T011~T015를 한
  커밋으로).

## 구현 전략

1. 먼저 중단 단위와 tasks.md 전체 diff를 분류하고 blob hash와 diff를 기준선으로 고정한다.
   재개 단위가 없으면 Domain(작업 패키지 1)부터 시작한다.
2. 각 작업 패키지의 미완료 작업을 논리적 커밋 단위로 설계한다(패키지 1개당 커밋 1개가
   기본).
3. 각 단위의 구현·검증·완료 표시·커밋을 순서대로 완료하고 생성된 커밋을 확인한다. App(작업
   패키지 5)은 전체 완료 검증과 필수 hook까지 열린 상태로 유지한다.
4. 실행 단위가 커밋되면 변경 파일, 검증 결과와 커밋을 진행 상황으로 보고하고 다음 단위로
   이어간다.
5. 새 권한이 필요한 경계가 나타나면 변경을 시작하기 전에 중단하고 명시적 승인을 요청한다.
6. App에서는 전체 읽기 전용 검증(T027)과 변경 시나리오 수용 검증(T028), 필수
   `after_implement` hook을 실행하고 결과를 재검증한 뒤 마지막 단위를 최종 commit한다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 커밋 단위는 단일 패키지가 기본이며, 이 기능에는 분리 불가능한 다중 패키지 integration
  unit이 없다(각 패키지가 독립적으로 컴파일·테스트 가능하도록 설계했다).
- 019가 이미 구현한 FCM 수신·완료 판정 로직, `openNotificationSettings` 배선,
  `PushMessagingClient`/`FirebaseMessagingPushClient`는 이 기능에서 수정하지 않는다.
