---

description: "기능 구현 작업 목록 템플릿"
---

# 작업 목록: 프로젝트 등록·학습 세트 생성 흐름

**입력**: `/specs/019-project-registration-flow/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 `tasks.md`의 blob hash와 전체 diff를
snapshot한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만
선택한다.

**테스트**: spec.md의 각 시나리오가 "독립 테스트"로 reducer/Effect/Adapter 테스트를 명시적으로
요구하므로 테스트 작업을 포함한다.

**구성**: 실행 단위(패키지)를 최상위 구조로 사용하고 변경 시나리오는 각 단위 안에서 `[S#]`
라벨로 추적한다.

**개정 이력**: `/speckit-analyze`가 지적한 불일치(Composition이 `PushRegistrationAppDelegate`를
소유하고 `UIApplicationDelegate`/`MessagingDelegate`/`UNUserNotificationCenterDelegate`를 함께
채택하도록 지시하던 폐기된 설계)를 plan.md·research.md 항목 5·contracts의 최신 설계(App 소유
`GitItAppDelegate` + Composition이 노출하는 `forwardAPNsToken`/`ingestPushPayload` 두 closure)에
맞춰 작업 패키지 4·6을 재작성했다. Domain/Infrastructure/Data 패키지와 Feature 트랙 A/B는
이번 개정에서 변경하지 않았다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[시나리오]**: S1~S5는 spec.md의 시나리오 1~5에 대응한다.
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 실행 또는 수동
  검증. `make tuist`의 파생 산출물 갱신은 허용하되 실행 전후 Git 상태를 비교하고 추적 파일
  변경이 생기면 완료로 처리하지 않는다.

## 실행 단위 순서와 근거

[아키텍처 3.1](../../docs/architecture.md#31-프로젝트-내부-패키지-의존성)의 의존 방향에 따라
다음 순서로 진행한다(이 명세가 변경하지 않는 UI, Quiz, ProjectDetail, Saved, Settings,
Onboarding, AppEntry 패키지는 건너뛴다).

1. **Domain**(LearningProject) — 다른 적용 패키지에 의존하지 않는다.
2. **Infrastructure** — Domain에 의존하지 않는다. Domain과 상대적 순서는 무관하지만 이
   문서는 Domain 다음으로 고정한다.
3. **Data**(LearningProject) — Infrastructure에 의존한다.
4. **Composition** — Domain·Data·Infrastructure 모두에 의존하는 조립 지점이라 하나의
   integration unit으로 묶는다(분리하면 `AppComposition`이 컴파일되지 않는다).
5. **Feature**(ProjectRegistration, Home, MainShell) — Domain에 의존한다. 서로 다른 파일을
   바꾸는 ProjectRegistration 트랙과 Home/MainShell 트랙은 병렬 진행할 수 있다.
6. **App** — Feature·Composition·Domain 모두에 의존하므로 마지막에 진행한다.

---

## 작업 패키지 1: Domain (LearningProject)

**목표**: 학습 세트 생성 완료·실패를 표현하는 Domain 모델과, 여러 소비자가 각자 독립적인
`AsyncStream`을 받을 수 있는 관찰 계약을 제공한다.

**소유 경로**: `sources/Projects/Domain/LearningProject/**`,
`sources/Projects/Domain/Tests/LearningProject/**`

**관련 변경 시나리오**: S3

**독립 검증**: Domain target만으로 build·test하며 다른 패키지를 참조하지 않는다.

### 테스트

- [X] T001 [P] [S3] `sources/Projects/Domain/Tests/LearningProject/UseCases/ObserveLearningProjectGenerationOutcomesTests.swift`에 `ObserveLearningProjectGenerationOutcomes`가 `LearningProjectGenerationOutcomeRepository.outcomes()`를 그대로 위임하고, repository가 여러 이벤트를 순서대로 방출하면 소비자가 같은 순서로 받는지 검증하는 테스트를 작성한다(Test Double repository 사용, `ObserveAuthenticationOutcomesTests.swift` 패턴 참고).

### 구현

- [X] T002 [P] [S3] `sources/Projects/Domain/LearningProject/Models/LearningProject/LearningProjectGenerationOutcome.swift`에 `LearningProjectGenerationOutcome`(projectID: String, status: Status{completed, failed}) 모델을 `data-model.md` 1절에 따라 구현한다.
- [X] T003 [P] [S3] `sources/Projects/Domain/LearningProject/Contracts/LearningProjectGenerationOutcomeRepository.swift`에 `LearningProjectGenerationOutcomeRepository` 프로토콜(`func outcomes() async -> AsyncStream<LearningProjectGenerationOutcome>`)을 `contracts/domain-data-contracts.md` 2절에 따라 구현한다.
- [X] T004 [S3] `sources/Projects/Domain/LearningProject/UseCases/ObserveLearningProjectGenerationOutcomes/ObserveLearningProjectGenerationOutcomesUseCase.swift`에 `ObserveLearningProjectGenerationOutcomesUseCase` 프로토콜(`func callAsFunction() async -> AsyncStream<LearningProjectGenerationOutcome>`)을 T003에 의존해 구현한다.
- [X] T005 [S3] `sources/Projects/Domain/LearningProject/UseCases/ObserveLearningProjectGenerationOutcomes/ObserveLearningProjectGenerationOutcomes.swift`에 T003의 repository를 생성자 주입받아 T004를 구현하는 `ObserveLearningProjectGenerationOutcomes` 구조체를 작성한다. `ObserveAuthenticationOutcomes.swift`와 동일한 형태(생성자 주입 struct가 UseCase 프로토콜을 채택)를 따르되, 내부 로직은 상태 매핑 없이 `repository.outcomes()`를 그대로 위임하는 단순 pass-through로 구현한다(data-model.md "신규 Domain 계약" 절 참고 — `ObserveAuthenticationOutcomes` 자체는 세션 복원 등 더 복잡한 변환을 포함하므로 구조만 참고하고 그대로 옮기지 않는다).

### 정리와 패키지 검증

- [X] T006 [no-write] `"$project_build_runner" test`(Domain target 한정 실행 가능하면 그 범위로) 또는 Xcode의 Domain test plan으로 T001의 테스트가 통과하는지 확인한다.

**진행 점검**: T001~T006의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행
단위(Infrastructure)로 진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을
요청한다.

---

## 작업 패키지 2: Infrastructure

**목표**: Firebase Cloud Messaging의 APNs 등록·등록 토큰 조회를 프로젝트 소유
기술 API(`PushMessagingClient`)로 감싼다.

**소유 경로**: `sources/Projects/Infrastructure/PushMessaging/**`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/ExternalDependenciesName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`

**관련 변경 시나리오**: S3(기반 기술, 사용자 관찰 가능 동작 없음)

**독립 검증**: Infrastructure target만으로 build하며 Domain·Data를 참조하지 않는다.

**경로 정정**: `sources/Projects/Infrastructure/Project.swift`는 `ProjectName.Infrastructure.project`만
참조하는 1줄짜리 위임 파일이라 여기에 target 의존성을 직접 추가할 수 없다. 이 프로젝트의 Tuist
설정에서 실제 target·의존성 선언은 `sources/Tuist/ProjectDescriptionHelpers/` 아래 manifest
helper 파일에 있으므로(`ExternalDependenciesName`이 외부 SPM product 이름을,
`InfrastructureModuleName`이 Infrastructure의 각 하위 모듈 target과 그 의존성을,
`ProjectName`이 패키지별 `buildTargets`/`testTargets` 목록을 선언), T007을 이 세 파일 기준으로
재작성했다.

### 준비

- [X] T007 세 파일을 함께 수정해 새 `InfrastructurePushMessaging` target을 추가한다: (a) `sources/Tuist/ProjectDescriptionHelpers/Projects/ExternalDependenciesName.swift`의 `ExternalDependenciesName` enum에 `case FirebaseMessaging`을 추가한다(워크스페이스 `sources/Tuist/Package.swift`에는 이미 `firebase-ios-sdk` 12.16+가 선언되어 있으므로 새 workspace dependency는 추가하지 않는다). (b) `sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift`의 `InfrastructureModuleName` enum에 `case InfrastructurePushMessaging`을 추가하고(테스트 target은 생성하지 않는다 — T010이 컴파일만 검증), `targets` 배열에 `.module(name: InfrastructureModuleName.InfrastructurePushMessaging.rawValue, sourceDirectory: ..., dependencies: [.external(.FirebaseMessaging)])`를 `InfrastructureAuthentication` 항목과 같은 형태로 추가하며, `sourceDirectory` 계산의 `switch self` 두 분기 모두에 새 case를 추가한다. (c) `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 `.Infrastructure` 케이스 `buildTargets` 배열에 `InfrastructureModuleName.InfrastructurePushMessaging.rawValue`를 추가한다(`testTargets`는 변경하지 않는다).

### 구현

- [X] T008 [S3] `sources/Projects/Infrastructure/PushMessaging/Clients/PushMessagingClient.swift`에 `PushMessagingClient` 프로토콜(`func registrationToken() async throws -> String`, `func setAPNsToken(_ token: Data)`)을 `contracts/domain-data-contracts.md` 4절에 따라 구현한다.
- [X] T009 [S3] `sources/Projects/Infrastructure/PushMessaging/Clients/FirebaseMessagingPushClient.swift`에 T008을 구현하는 `FirebaseMessagingPushClient`를 작성한다. 자기 초기화 시점에 `Messaging.messaging().delegate = self`를 등록해 `MessagingDelegate` 채택 자체를 이 타입 안에 완전히 가두고, `messaging(_:didReceiveRegistrationToken:)` 콜백을 `CheckedContinuation`으로 감싸 `registrationToken()`을 비동기 API로 노출하며, `setAPNsToken(_:)`은 `Messaging.messaging().apnsToken`에 대입한다(`contracts/domain-data-contracts.md` 4절).

### 정리와 패키지 검증

- [X] T010 [no-write] Infrastructure target이 `FirebaseMessaging` 의존성과 함께 컴파일되는지 `"$project_build_runner" compile`로 확인한다(Firebase SDK 콜백 동작 자체는 자동화 테스트로 재현하기 어려우므로 quickstart.md의 수동 시나리오로 후속 검증한다).

**진행 점검**: T007~T010의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행
단위(Data)로 진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을 요청한다.

---

## 작업 패키지 3: Data (LearningProject)

**목표**: silent push의 원시 payload를 `ProjectGenerationOutcomeDTO`로 디코딩하고, 여러
구독자에게 동일 이벤트를 전달하는 멀티캐스트 허브를 제공한다.

**소유 경로**: `sources/Projects/Data/LearningProject/**`,
`sources/Projects/Data/Tests/LearningProject/**`

**관련 변경 시나리오**: S3

**독립 검증**: Data target만으로 build·test하며 Infrastructure의 `PushMessagingClient`
프로토콜만 참조한다(Firebase SDK 구체 타입은 참조하지 않는다).

### 테스트

- [ ] T011 [P] [S3] `sources/Projects/Data/Tests/LearningProject/DTOs/ProjectGenerationOutcomeDTOTests.swift`에 `[String: String]` payload로부터 완료·실패 각각 디코딩 성공, 알 수 없는 상태값과 필수 키 누락 시 디코딩 실패(nil 또는 throw)를 검증하는 테스트를 작성한다.
- [ ] T012 [P] [S3] `sources/Projects/Data/Tests/LearningProject/Remotes/PushProjectGenerationOutcomeRemoteTests.swift`에 (a) `outcomes()`를 두 번 호출해 만든 두 스트림이 `ingest(rawPayload:)` 한 번 호출로 동일 이벤트를 각자 받는지(멀티캐스트), (b) 디코딩 실패 payload가 조용히 폐기되는지, (c) 한 스트림의 소비를 끝내도 다른 스트림이 계속 이벤트를 받는지 검증하는 테스트를 작성한다.

### 구현

- [ ] T013 [P] [S3] `sources/Projects/Data/LearningProject/DTOs/ProjectGenerationOutcomeDTO.swift`에 `ProjectGenerationOutcomeDTO`(projectID, status: RawStatus)와 `[String: String]` payload 디코딩 initializer를 `data-model.md` "신규 Data 계약·모델" 절에 따라 구현한다.
- [ ] T014 [S3] `sources/Projects/Data/LearningProject/Contracts/ProjectGenerationOutcomeRemote.swift`에 `ProjectGenerationOutcomeRemote` 프로토콜(`func outcomes() -> AsyncStream<ProjectGenerationOutcomeDTO>`)을 구현한다.
- [ ] T015 [S3] `sources/Projects/Data/LearningProject/Remotes/PushProjectGenerationOutcomeRemote.swift`에 T014를 구현하는 actor `PushProjectGenerationOutcomeRemote`(continuation 등록/해제, `ingest(rawPayload:)`)를 `contracts/domain-data-contracts.md` 3절에 따라 구현한다.

### 정리와 패키지 검증

- [ ] T016 [no-write] Data target 테스트를 실행해 T011~T012가 통과하는지 확인한다.

**진행 점검**: T011~T016의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행
단위(Composition)로 진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을
요청한다.

---

## 작업 패키지 4: Composition (integration unit — Domain·Data·Infrastructure 조립)

**목표**: Domain 계약을 Data 허브에 연결하는 Adapter를 만들고, `AppComposition`이 새 관찰
Use Case와 두 closure(`forwardAPNsToken`, `ingestPushPayload`)를 노출하며, `live(...)` 조립
시점에 등록 토큰 수신 후 기존 `RegisterMemberDeviceUseCase`를 호출하는 백그라운드 `Task`를
시작한다. **Composition은 어떤 UIKit·Firebase 프로토콜도 채택하지 않는다** — 플랫폼
생명주기(`UIApplicationDelegate`)는 App이 소유하는 `GitItAppDelegate`(작업 패키지 6)가
담당하고, `MessagingDelegate` 채택은 Infrastructure의 `FirebaseMessagingPushClient`(작업
패키지 2, T009) 안에서 이미 완결되어 있다.

**소유 경로**: `sources/Projects/Composition/Adapter/Adapters/LearningProjectGenerationOutcomeRepositoryAdapter.swift`,
`sources/Projects/Composition/Adapter/Assemblies/LearningProjectAssembly.swift`,
`sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`,
`sources/Projects/Composition/Tests/**`

**관련 변경 시나리오**: S3

**분리 불가 근거**: `LearningProjectAssembly`가 새 프로퍼티(관찰 Use Case, push 허브의
`ingest` 진입점에 위임하는 closure)를 노출해야만 `AppComposition`이 그것을
`ingestPushPayload`로 다시 노출할 수 있다. 두 파일을 서로 다른 단위로 나누면 중간 상태에서
컴파일되지 않는다.

**독립 검증**: Composition target 단독 build·test. `AppCompositionPublicSurfaceTests`가
새 공개 프로퍼티(관찰 Use Case, 두 closure)의 타입을 검증한다.

### 테스트

- [ ] T017 [P] [S3] `sources/Projects/Composition/Tests/Adapter/Adapters/LearningProjectGenerationOutcomeRepositoryAdapterTests.swift`에 `ProjectGenerationOutcomeDTO`(completed/failed) → `LearningProjectGenerationOutcome` 변환과, 알 수 없는 `RawStatus`가 Domain으로 전달되지 않고 폐기되는지 검증하는 테스트를 Test Double `ProjectGenerationOutcomeRemote`로 작성한다.
- [ ] T018 [S3] `sources/Projects/Composition/Tests/Adapter/Assemblies/LearningProjectAssemblyTests.swift`(기존 파일 수정)에 `LearningProjectAssembly.observeLearningProjectGenerationOutcomes`가 `any ObserveLearningProjectGenerationOutcomesUseCase` 타입으로 노출되는지, 그리고 push 허브의 `ingest(rawPayload:)`에 위임하는 closure(향후 `AppComposition.ingestPushPayload`가 되는 진입점)가 공개 프로퍼티로 노출되는지 검증하는 케이스를 추가한다.
- [ ] T019 [S3] `sources/Projects/Composition/Tests/Adapter/Assemblies/AppCompositionPublicSurfaceTests.swift`(기존 파일 수정)에 `AppComposition.observeLearningProjectGenerationOutcomes`, `AppComposition.forwardAPNsToken`(`@Sendable (Data) -> Void`), `AppComposition.ingestPushPayload`(`@Sendable ([String: String]) async -> Void`) 세 공개 표면을 `contracts/domain-data-contracts.md` 5절에 따라 검증하는 케이스를 추가한다.

### 구현

- [ ] T020 [S3] `sources/Projects/Composition/Adapter/Adapters/LearningProjectGenerationOutcomeRepositoryAdapter.swift`에 `LearningProjectGenerationOutcomeRepository`를 구현하는 Adapter를 `contracts/domain-data-contracts.md` 5절에 따라 작성한다(생성자로 `ProjectGenerationOutcomeRemote` 주입).
- [ ] T021 [S3] `sources/Projects/Composition/Adapter/Assemblies/LearningProjectAssembly.swift`를 수정해 `PushProjectGenerationOutcomeRemote` 인스턴스를 소유하고, `observeLearningProjectGenerationOutcomes: any ObserveLearningProjectGenerationOutcomesUseCase`와 허브의 `ingest(rawPayload:)`에 위임하는 `ingestGenerationOutcomePayload: @Sendable ([String: String]) async -> Void` closure를 공개 프로퍼티로 노출한다.
- [ ] T022 [S3] `sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`를 수정해 `contracts/domain-data-contracts.md` 5절의 세 공개 표면을 추가한다: (a) `observeLearningProjectGenerationOutcomes`를 `LearningProjectAssembly`로부터 배선, (b) `PushMessagingClient` 인스턴스(`FirebaseMessagingPushClient()`)를 소유하고 그 `setAPNsToken(_:)`에 위임하는 `forwardAPNsToken: @Sendable (Data) -> Void` 노출, (c) `LearningProjectAssembly.ingestGenerationOutcomePayload`에 위임하는 `ingestPushPayload: @Sendable ([String: String]) async -> Void` 노출. 이어서 `AppComposition.live(...)`가 인스턴스를 구성하는 시점에 `Task { let token = try await pushClient.registrationToken(); await registerMemberDevice(MemberDeviceInfo(deviceToken: token, ...)) }`를 직접 시작한다(`registerMemberDevice`는 이미 노출되어 있으므로 그 자체는 변경하지 않는다). Composition은 이 과정에서 `UIApplicationDelegate`, `MessagingDelegate`, `UNUserNotificationCenterDelegate` 어느 것도 채택하지 않는다.

### 정리와 패키지 검증

- [ ] T023 [no-write] Composition target 테스트를 실행해 T017~T019가 통과하는지 확인한다.

**진행 점검**: T017~T023의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행
단위(Feature)로 진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을
요청한다.

---

## 작업 패키지 5: Feature (ProjectRegistration, Home, MainShell)

**목표**: 등록 화면 5종을 실제로 연결하고, 생성 진행 국면(체크리스트·`홈에서 기다리기`·
알림 옵션 시트·FCM 완료·실패 판정)을 `ProjectRegistrationFeature`에 추가하며, Home이
같은 FCM 신호를 관찰해 목록을 갱신하고 1회 재조회를 지원하도록 확장한다.

**소유 경로**: `sources/Projects/Feature/ProjectRegistration/**`,
`sources/Projects/Feature/Tests/ProjectRegistration/**`,
`sources/Projects/Feature/Home/Reducers/HomeFeature.swift`,
`sources/Projects/Feature/Tests/Home/**`,
`sources/Projects/Feature/MainShell/Reducers/MainShellFeature.swift`,
`sources/Projects/Feature/Tests/MainShell/**`

**관련 변경 시나리오**: S1, S2, S3, S4, S5

**독립 검증**: Feature target만으로 build·test(Domain에만 의존). `TestStore` 기반
reducer 테스트로 각 시나리오의 State 전이·delegate 출력을 독립적으로 검증한다.

이 패키지는 서로 다른 파일을 바꾸는 두 트랙으로 나뉜다: **트랙 A(ProjectRegistration)**와
**트랙 B(Home/MainShell)**. 두 트랙은 병렬로 진행할 수 있다.

### 트랙 A: ProjectRegistration — 테스트

- [ ] T024 [P] [S1] `sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/StubFetchExternalRepositoryUseCase.swift`, `StubCreateLearningProjectUseCase.swift`, `StubObserveLearningProjectGenerationOutcomesUseCase.swift`에 `TestStore` 구성에 필요한 Test Double을 작성한다(성공/실패 결과를 스크립트로 지정할 수 있게 구성).
- [ ] T025 [S1] `sources/Projects/Feature/Tests/ProjectRegistration/Reducers/ProjectRegistrationFeatureTests.swift`에 다음 케이스를 작성한다: `repositoryURLChanged`가 `validation`을 `idle`로 되돌리는지, `validateTapped` 성공·실패 전이, 빈 URL에서 `validateTapped`가 아무 효과도 내지 않는지, 늦게 도착한 `validationRequestID` 불일치 응답이 무시되는지(S1 시나리오 1~4).
- [ ] T026 [S2] 같은 파일에 `quizLevelSelected` 3종 반영, 미검증 상태에서 `submitTapped` 무효과, `committing` 중 중복 `submitTapped` 차단, `submitTapped` 성공 시 `createLearningProject`가 검증된 `canonicalURL`과 선택된 `QuizLevel`로 정확히 한 번 호출되는지 검증하는 케이스를 추가한다(S2 시나리오 1~4).
- [ ] T027 [S3] 같은 파일에 제출 성공이 `submission = .awaitingGeneration(receipt)`로 전이하는지, `waitAtHomeTapped`가 (알림 옵션이 꺼져 있으면 시트를 거쳐) `delegate(.projectRegistered)`를 정확히 한 번 출력하는지, `awaitingGeneration` 중 일치하는 `projectID`의 `completed` 이벤트 수신 시 같은 delegate가 출력되는지, 일치하지 않는 `projectID` 이벤트는 무시되는지, `failed` 이벤트 수신 시 `submission = .failed`로 전이하는지, 제출 자체 실패와 FCM 실패가 같은 `.failed` 표현을 쓰는지, `retryTapped`가 동일 입력으로 재제출하는지 검증하는 케이스를 추가한다(S3 시나리오 1~5).
- [ ] T028 [S4] 같은 파일에 알림 옵션이 꺼져 있을 때만 `waitAtHomeTapped`가 시트를 띄우는지, 수락·거절 각각 실제 알림 API 호출 없이 `delegate(.notificationOptionSelected)`를 출력하고 이어서 `waitAtHomeTapped` 동작이 진행되는지, 선택이 상태 전이 자체에 영향을 주지 않는지 검증하는 케이스를 추가한다(S4 시나리오 1~3).
- [ ] T029 [S3] 같은 파일에 `validateTapped` 또는 `submitTapped`로 `.cancellable` Effect가 진행 중인 상태에서 `TestStore`가 `ProjectRegistrationFeature.State`를 폐기(`AppRootFeature`의 `ifLet`이 등록 흐름을 중간에 닫는 상황을 모사)할 때 진행 중이던 검증·제출 Effect가 취소되고 이후 어떤 `EffectEvent`도 수신되지 않는지 검증하는 케이스를 추가한다(FR-016, SC-014 — 기존에는 `quickstart.md` 수동 시나리오 10에만 의존하던 자동화 갭을 메운다).

### 트랙 A: ProjectRegistration — 구현

- [ ] T030 [S1] [S2] [S3] [S4] `sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`를 수정해 `contracts/feature-app-contracts.md` 1절의 계약(신규 init 매개변수 `observeLearningProjectGenerationOutcomes`, `SubmissionStatus.awaitingGeneration` 케이스, `View.waitAtHomeTapped`/`notificationOptionAccepted`/`notificationOptionDeclined`/`retryTapped`, `EffectEvent.generationOutcomeReceived`, `Delegate.notificationOptionSelected`, `isNotificationOptionSheetPresented` State, 관찰 Effect의 `projectID` 필터링·멱등 처리)를 구현한다.
- [ ] T031 [S1] `sources/Projects/Feature/ProjectRegistration/Screens/ProjectRegistrationScreen.swift`에 링크 입력 화면(Figma node `986:13739`/`986:13646` 계열)을 구현한다. 레이아웃·색·타이포는 `.agents/skills/implement-figma-ui` 스킬로 해당 node를 직접 조회해 근거를 확보하고 기존 UIComponent/DesignSystem 토큰을 우선 재사용한다(FR-018/021).
- [ ] T032 [S1] 같은 target에 레포지토리 확인 화면(Figma node `737:10890`, Task2_04)을 구현한다. 근거 확보 방식은 T031과 동일하다.
- [ ] T033 [S2] 같은 target에 기술 이해도 선택 화면(Figma node `737:10882`/`737:10874`, Task2_05/06)과 생성 시작 확정 화면(Figma node `737:10830`, Task2_09)을 구현한다. 근거 확보 방식은 T031과 동일하다.
- [ ] T034 [S3] 같은 target에 생성 진행 화면(Figma node `737:10800`, 5단계 정적 체크리스트 + `홈에서 기다리기` CTA)을 구현한다. 근거 확보 방식은 T031과 동일하며, 진행률(%) 폴링을 유발하는 어떤 네트워크 호출도 추가하지 않는다(SC-010).
- [ ] T035 [S4] 같은 target에 완료 알림 옵션 시트(Figma node `824:12149`)를 구현한다. 근거 확보 방식은 T031과 동일하다.
- [ ] T036 [P] [S5] `sources/Projects/Feature/ProjectRegistration/Previews/ProjectRegistrationScreenPreviews.swift`에 T031~T035 각 화면의 deterministic Preview를 `360×800` 기준으로 작성해 지정된 Figma node와 대조 가능하게 한다(S5 시나리오 1).

### 트랙 B: Home/MainShell — 테스트

- [ ] T037 [P] [S3] `sources/Projects/Feature/Tests/Home/TestDoubles/StubObserveLearningProjectGenerationOutcomesUseCase.swift`에 여러 이벤트를 스크립트로 방출하는 Test Double을 작성한다.
- [ ] T038 [S3] `sources/Projects/Feature/Tests/Home/Reducers/HomeFeatureTests.swift`(기존 파일 확장)에 `view(.task)`가 `generationOutcomeObservation`이 `idle`일 때만 관찰 Effect를 시작하고 재호출 시 중복 구독하지 않는지, `generationOutcomeReceived`가 일치하는 `projectID`의 프로젝트 표시 상태를 갱신하는지, `reloadRequested`가 `projectLoad`가 `.loading`이 아닐 때만 새 조회를 시작하는지 검증하는 케이스를 추가한다(FR-013, FR-022).

### 트랙 B: Home/MainShell — 구현

- [ ] T039 [S3] `sources/Projects/Feature/Home/Reducers/HomeFeature.swift`를 수정해 `contracts/feature-app-contracts.md` 2절의 계약(신규 init 매개변수, `View.reloadRequested`, `EffectEvent.generationOutcomeReceived`, `generationOutcomeObservation` State, 장기 관찰 Effect)을 구현한다.
- [ ] T040 [S3] `sources/Projects/Feature/MainShell/Reducers/MainShellFeature.swift`를 수정해 `observeLearningProjectGenerationOutcomes`를 신규 init 매개변수로 받아 `HomeFeature`로 그대로 전달한다.
- [ ] T041 [S3] `sources/Projects/Feature/Tests/MainShell/Reducers/MainShellFeatureTests.swift`(기존 파일 수정)의 `makeStore(...)` 헬퍼가 `MainShellFeature(...)` 생성자 호출에 `observeLearningProjectGenerationOutcomes` 인자를 추가하도록 갱신한다. T037의 Stub Test Double(또는 동등한 Mock)을 재사용해 인자를 채운다(T040이 추가하는 신규 init 매개변수로 인해 이 파일이 컴파일되지 않는 것을 방지).

### 정리와 패키지 검증

- [ ] T042 [no-write] Feature target 테스트를 실행해 T025~T029, T038이 통과하고, T041 적용 후 `MainShellFeatureTests`가 컴파일·통과하는지 확인한다.

**진행 점검**: T024~T042의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행
단위(App)로 진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을 요청한다.

---

## 작업 패키지 6: App

**목표**: `AppRootFeature`가 등록 흐름을 `@Presents` 자식으로 소유해 전체 화면으로
표시하고, 완료 시 Home으로 복귀하며 1회 재조회를 트리거하게 한다. App이 소유하는 신규
`GitItAppDelegate`(`UIApplicationDelegate`, `UNUserNotificationCenterDelegate`만 채택,
`MessagingDelegate`는 채택하지 않음)가 Composition의 두 closure(`forwardAPNsToken`,
`ingestPushPayload`)를 플랫폼 콜백에 연결한다.

**소유 경로**: `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`,
`sources/Projects/App/GitIt/Screens/AppRootView.swift`,
`sources/Projects/App/GitIt/AppDelegates/GitItAppDelegate.swift`,
`sources/Projects/App/GitIt/GitItApp.swift`,
`sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`,
`sources/Projects/App/Tests/GitIt/TestDoubles/**`,
`docs/conventions/directory-file.md`

**관련 변경 시나리오**: S1, S3

**독립 검증**: App target build·test. `AppRootFeatureTests`가 등록 흐름 표시·종료·Home
복귀를 `TestStore`로 검증한다. `GitItAppDelegate`는 UIKit 콜백 특성상 단위 테스트 대신
quickstart.md의 수동 시나리오로 검증한다(contracts/feature-app-contracts.md 6절).

### 테스트

- [ ] T043 [P] [S1] `sources/Projects/App/Tests/GitIt/TestDoubles/`에 `NoopFetchExternalRepositoryUseCase.swift`, `NoopCreateLearningProjectUseCase.swift`, `ObserveLearningProjectGenerationOutcomesUseCaseMock.swift`를 기존 `NoopFetchLearningProjectsUseCase.swift` 등과 같은 패턴으로 작성한다.
- [ ] T044 [S1] `sources/Projects/App/Tests/GitIt/TestDoubles/AppRootTestSupport.swift`(기존 파일 수정)에 T043의 Test Double을 사용하도록 `AppRootFeature.State`/생성자 호출부를 갱신한다.
- [ ] T045 [S1] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`(기존 파일 확장)에 `mainShell(.delegate(.projectRegistrationRequested))` 수신 시 `state.projectRegistration`이 `ProjectRegistrationFeature.State()`로 채워지는지 검증하는 케이스를 추가한다(S1 시나리오 1).
- [ ] T046 [S3] 같은 파일에 `projectRegistration(.presented(.delegate(.projectRegistered(receipt))))` 수신 시 `state.projectRegistration`이 `nil`로 전이하고 `mainShell(.home(.view(.reloadRequested)))`가 정확히 한 번 발행되는지 검증하는 케이스를 추가한다(FR-012/FR-013, S3 시나리오 2·3).

### 구현

- [ ] T047 [S1] [S3] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`를 수정해 `contracts/feature-app-contracts.md` 4절의 계약(`@Presents var projectRegistration`, `Action.projectRegistration(PresentationAction<…>)`, `ifLet`, 신규 init 매개변수 `fetchExternalRepository`/`createLearningProject`/`observeLearningProjectGenerationOutcomes`, `projectRegistrationRequested`/`projectRegistered`/`notificationOptionSelected` 처리)를 구현한다.
- [ ] T048 [S1] `sources/Projects/App/GitIt/Screens/AppRootView.swift`를 수정해 `mainShell` 분기에 `contracts/feature-app-contracts.md` 5절의 `fullScreenCover(item:)`로 `ProjectRegistrationScreen`을 연결한다.
- [ ] T049 [S1] [S3] `sources/Projects/App/GitIt/AppDelegates/GitItAppDelegate.swift`에 `contracts/domain-data-contracts.md` 6절의 `GitItAppDelegate`(`NSObject`, `UIApplicationDelegate`, `UNUserNotificationCenterDelegate`만 채택 — `MessagingDelegate`는 채택하지 않고 FirebaseMessaging SDK를 import하지 않음)를 구현한다. `static func configure(forwardAPNsToken:ingestPushPayload:)`로 설정 전 delegate 콜백은 no-op 처리(로그만 남김)하고, `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`은 `forwardAPNsToken(deviceToken)`을, `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)`(silent push)는 raw payload를 `[String: String]`으로 정규화해 `ingestPushPayload(...)`를 호출한 뒤 `fetchCompletionHandler(.newData)`를 호출한다. 디바이스 등록(`registerMemberDevice`)은 이 타입의 책임이 아니다(작업 패키지 4의 T022가 이미 처리).
- [ ] T050 [S1] [S3] `sources/Projects/App/GitIt/GitItApp.swift`를 수정해 `@UIApplicationDelegateAdaptor(GitItAppDelegate.self) var appDelegate`를 선언하고, `AppComposition.live(...)` 직후 `rootStore`를 생성하기 전에 `GitItAppDelegate.configure(forwardAPNsToken: appComposition.forwardAPNsToken, ingestPushPayload: appComposition.ingestPushPayload)`를 호출한다(`contracts/domain-data-contracts.md` 7절, `research.md` 5절 근거).
- [ ] T051 `docs/conventions/directory-file.md`의 §7 App 패키지 형태 폴더 표에 이번 기능이 추가하는 새 형태 `AppDelegates/`(플랫폼 생명주기 delegate 타입 전용)를 한 행으로 추가한다(plan.md "구조 결정" 절이 명시한 갱신 대상, 책임 패키지: App). 이 명세가 실제로 만드는 T049의 폴더 배치만 반영하며 다른 패키지의 표 내용은 바꾸지 않는다.

### 정리와 패키지 검증

- [ ] T052 [no-write] App target 테스트를 실행해 T045~T046가 통과하는지 확인한다.

**진행 점검**: T043~T052의 변경 파일과 검증 결과를 보고한다. 이 패키지가 마지막 적용
대상 패키지이므로 다음은 전체 완료 검증이다.

---

## 전체 완료 검증

**선행 조건**: App 패키지의 파일 변경 작업을 완료하고, 전체 검증과 hook 결과를 포함할
마지막 커밋 단위를 아직 commit하지 않은 상태여야 한다.

**커밋 경계**: 아래 `[no-write]` 작업은 App 패키지의 마지막 커밋 단위에 배정한다. 모든
검증과 필수 `after_implement` hook(swift-format)을 마친 뒤 그 단위를 최종 commit한다.

- [ ] T053 [no-write] `"$project_build_runner" build`, `compile`, `test`를 순서대로 실행하고 전체 결과를 기록한다.
- [ ] T054 [no-write] `quickstart.md`의 수동 검증 시나리오 1~11(Simulator)을 실행해 S1~S4 수용 기준과 SC-006/SC-007/SC-009/SC-010/SC-014/SC-015/SC-016을 확인한다.
- [ ] T055 [no-write] [S5] `implement-figma-ui` 스킬로 T031~T035의 5개 화면을 지정 Figma node와 다시 대조하고(SC-011), VoiceOver로 입력·검증/제출/재시도 버튼·이해도 선택 카드·진행 체크리스트를 탐색해 의미 식별 가능 여부와 44×44pt 터치 영역을 확인하며(SC-012), `xSmall`~`accessibility5` 12단계 Dynamic Type에서 핵심 입력·동작이 가려지지 않는지 확인한다(SC-013).

## 의존성과 실행 순서

### 실행 단위 순서와 위험 기반 승인

- Domain → Infrastructure → Data → Composition → Feature → App 순서로 진행한다. 근거는
  "실행 단위 순서와 근거" 절과 [plan.md](./plan.md)의 "실행 단위(패키지 위상 순서)" 절과
  동일하다.
- Feature 패키지 내부의 트랙 A(ProjectRegistration)와 트랙 B(Home/MainShell)는 서로
  다른 파일을 바꾸므로 병렬 진행할 수 있다.
- 하나의 실행 단위를 완료·검증한 뒤 다음 단위로 진행하며, 같은 기능 범위(이 명세) 안에서는
  반복 승인을 요구하지 않는다.
- `GoogleService-Info.plist`(Firebase 앱 등록 파일) 신설·교체처럼 이 세션이 보유하지 않은
  Firebase 콘솔 자격 증명이 필요한 작업이 발견되면, 그 시점에 중단하고 사용자에게 파일
  제공 또는 직접 등록을 요청한다(새로운 외부 상태 변경 권한 필요).

### 변경 시나리오 추적성

- S1: T024~T026, T031~T032, T043~T045, T047~T048
- S2: T026, T033
- S3: T001~T023(Domain/Infrastructure/Data/Composition 전체), T027, T029, T030, T034,
  T037~T041, T046~T047, T050, T054
- S4: T028, T035
- S5: T036, T055

### 최소 가치 범위

작업 패키지 1~4(Domain/Infrastructure/Data/Composition)만으로는 사용자가 관찰 가능한
동작 변화가 없다(FCM 배선만 완성). 최소로 시연 가능한 범위는 작업 패키지 5의 트랙
A(ProjectRegistration 화면 연결, S1·S2)까지 완료한 뒤 작업 패키지 6(App)의
`projectRegistrationRequested` 연결(T043~T045, T047~T048)까지다 — 이 지점부터 Home의
`지금 불러오기`가 실제 등록 화면을 열고 레포 검증·이해도 선택·제출까지 동작한다(S3의
FCM 판정 없이도 제출 자체는 가능하나, `awaitingGeneration` 이후 화면을 벗어날 방법이
`홈에서 기다리기`뿐이므로 S3 관련 코드까지 함께 있어야 흐름이 막히지 않는다). 새 권한이
필요하지 않으면 여기서부터 나머지 범위(S3 FCM 완료·실패 판정, S4 알림 옵션, S5 접근성)로
반복 승인 없이 연속 진행한다.

### 실행 단위 내부 실행

- 각 작업 패키지 안에서는 테스트를 구현보다 먼저 작성한다.
- `[P]`는 현재 작업 패키지 안의 서로 다른 파일에만 사용한다.
- 같은 파일을 변경하는 작업(예: `ProjectRegistrationFeatureTests.swift`에 이어 붙는
  T025~T029)은 순차 실행한다.
- 서로 다른 작업 패키지의 Git index·같은 파일 변경은 병렬 실행하지 않는다.
- `/speckit-implement`는 파일을 수정하기 전에 현재 패키지의 미완료 작업을 논리적 커밋
  단위로 설계한다. 예: 작업 패키지 1은 "Domain 모델+계약+Use Case+테스트" 하나의 커밋
  단위로 묶을 수 있다.
- 마지막 적용 패키지(App)의 마지막 단위는 전체 완료 검증과 필수 `after_implement`
  hook이 끝날 때까지 commit하지 않는다.

## 구현 전략

1. 이 `tasks.md`의 blob hash와 전체 diff를 기준선으로 고정한다.
2. Domain부터 시작해 각 작업 패키지의 미완료 작업을 논리적 커밋 단위로 설계한다.
3. 각 단위의 구현·검증·완료 표시·커밋을 순서대로 완료하고 생성된 커밋을 확인한다.
4. 실행 단위가 커밋되면 변경 파일, 검증 결과와 커밋을 진행 상황으로 보고하고 같은
   범위의 다음 단위로 이어간다.
5. `GoogleService-Info.plist` 등 세션이 보유하지 않은 자격 증명이 필요한 경계가
   나타나면 변경을 시작하기 전에 중단하고 명시적 승인을 요청한다.
6. App 패키지에서는 전체 읽기 전용 검증(T053~T055)과 필수 `after_implement` hook을
   실행하고 결과를 재검증한 뒤 마지막 단위를 최종 commit한다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 커밋 단위는 단일 패키지가 기본이며 작업 패키지 4(Composition)만 분리 불가 근거를 가진
  integration unit이다.
- 문제 해결과 암묵지 기록(`trouble-shooting.md`, `tacit-knowledge.md`)은 이 작업 목록의
  작업 ID로 생성하지 않는다.
