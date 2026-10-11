---
description: "기능 구현 작업 목록"
---

# 작업 목록: 프로젝트 등록 흐름 리뷰 지적 사항 해소

**입력**: `/specs/022-registration-flow-review-fixes/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를
snapshot한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만
선택한다.

**테스트**: 포함한다. 명세 FR-005·FR-032와 SC-012가 회귀 테스트를 명시적으로 요구한다.

**구성**: 실행 단위를 최상위 구조로 사용하고 변경 시나리오는 각 단위 안의 `[S#]` 라벨로
추적한다. 단일 패키지 단위가 기본이며 분리하면 compile되지 않는 변경만 integration unit으로
묶는다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[시나리오]**: S1~S6. 매핑은 아래 표를 따른다.
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 실행 또는 수동 검증.
  `make tuist`의 파생 workspace·project·심볼릭 링크·cache 갱신은 허용한다. `.xcodeproj`는
  `.gitignore:74`가 제외하므로 파생 산출물이다. 실행 전후 `git status --porcelain`을 비교하고
  추적 파일 변경이 생기면 완료로 처리하지 않는다.

### 변경 시나리오 매핑

| 라벨 | 시나리오 | 요구사항 |
| --- | --- | --- |
| S1 | 생성 결과 구독을 확립한 뒤에 생성 요청을 보낸다 | FR-001 ~ FR-005 |
| S2 | 실패와 인증 종료에서 등록 흐름을 벗어날 수 있다 | FR-006 ~ FR-009 |
| S3 | 시스템 설정 화면 이동이 UIKit 실행 조건을 지킨다 | FR-010 ~ FR-012 |
| S4 | 푸시 부트스트랩과 기기 등록에 명시적 수명 소유자가 있다 | FR-013 ~ FR-018 |
| S5 | 화면 단계와 목록 갱신을 Feature 상태가 소유한다 | FR-019 ~ FR-021 |
| S6 | 공개 이름이 실제 책임과 범위를 드러낸다 | FR-022 ~ FR-030 |

라벨 없는 작업은 검증 게이트(FR-031, FR-032) 또는 기준선 확인이다.

**공용 문서 경로**: `GIT_IT_DOCS_ROOT` 판독 결과는 `docs`다. 이 문서의 문서 변경 작업은
`docs/conventions/file-vocabulary.md` 파일 하나뿐이다.

---

## 실행 단위 1 (integration): 생성 결과 관찰 Use Case 이름 정렬

**관련 패키지**: Domain → Composition → Feature → App

**분리 불가 근거**: `LearningProjectOutcomesUseCase`는 Domain 공개 protocol이며 Composition,
Feature, App이 모두 컴파일 의존한다. Domain만 rename하면 나머지 세 패키지가 compile되지 않는다.

**관련 변경 시나리오**: S6

**통합 검증**: App production build + `AllTests` compile + test

### 준비와 기반

- [X] T001 [no-write] `project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)`로 해석한 진입점에서 `compile`과 `test`를 순차 실행해 FR-032의 `Early unexpected exit` 재현 여부를 기준선으로 기록한다
- [X] T002 [no-write] `./tools/githooks/swift-format/bin/run.sh lint`를 실행해 FR-031의 현재 위반 2건을 기준선으로 기록한다

### 구현

- [X] T003 [S6] `sources/Projects/Domain/LearningProject/UseCases/LearningProjectOutcomes/LearningProjectOutcomesUseCase.swift`를 `sources/Projects/Domain/LearningProject/UseCases/ObserveGenerationOutcomes/ObserveGenerationOutcomesUseCase.swift`로 옮기고 protocol 이름을 `ObserveGenerationOutcomesUseCase`로 바꾼다
- [X] T004 [S6] `sources/Projects/Domain/LearningProject/UseCases/LearningProjectOutcomes/LearningProjectOutcomes.swift`를 `sources/Projects/Domain/LearningProject/UseCases/ObserveGenerationOutcomes/ObserveGenerationOutcomes.swift`로 옮기고 타입 이름을 `ObserveGenerationOutcomes`로 바꾼다
- [X] T005 [S6] `sources/Projects/Domain/Tests/LearningProject/UseCases/LearningProjectOutcomesTests.swift`를 `ObserveGenerationOutcomesTests.swift`로 옮기고 참조를 갱신한다
- [X] T006 [P] [S6] `sources/Projects/Composition/Adapter/Assemblies/LearningProjectAssembly.swift`의 타입 참조와 프로퍼티 이름을 `observeGenerationOutcomes`로 바꾼다
- [X] T007 [P] [S6] `sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`의 공개 프로퍼티 `learningProjectOutcomes`를 `observeGenerationOutcomes`로 바꾼다
- [X] T008 [P] [S6] `sources/Projects/Composition/Adapter/Factories/GenerationCompletionReminderCoordinator.swift`의 `start(learningProjectOutcomes:)` 인자 이름과 타입을 갱신한다
- [X] T009 [S6] `sources/Projects/Composition/Tests/Adapter/Assemblies/AppCompositionPublicSurfaceTests.swift`, `sources/Projects/Composition/Tests/Adapter/Assemblies/LearningProjectAssemblyTests.swift`, `sources/Projects/Composition/Tests/Adapter/Factories/GenerationCompletionReminderCoordinatorTests.swift`의 참조를 갱신한다
- [X] T010 [P] [S6] `sources/Projects/Feature/Home/Reducers/HomeFeature.swift`와 `sources/Projects/Feature/Home/Previews/HomePreviewSupport/HomePreviewSupport.swift`의 주입 프로퍼티를 `observeGenerationOutcomes`로 바꾼다
- [X] T011 [P] [S6] `sources/Projects/Feature/MainShell/Reducers/MainShellFeature.swift`의 주입 프로퍼티와 전달 인자를 갱신한다
- [X] T012 [P] [S6] `sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`와 `sources/Projects/Feature/ProjectRegistration/Previews/ProjectRegistrationScreenPreviews.swift`의 주입 프로퍼티를 갱신한다
- [X] T013 [S6] `sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/StubLearningProjectOutcomesUseCase.swift`를 `StubObserveGenerationOutcomesUseCase.swift`로 옮기고, `sources/Projects/Feature/Tests/ProjectRegistration/Reducers/ProjectRegistrationFeatureTests.swift`, `sources/Projects/Feature/Tests/Home/Reducers/HomeFeatureGenerationOutcomeTests.swift`, `sources/Projects/Feature/Tests/Home/Reducers/HomeFeatureLoadTests.swift`, `sources/Projects/Feature/Tests/Home/Reducers/HomeFeatureNavigationTests.swift`, `sources/Projects/Feature/Tests/MainShell/Reducers/MainShellFeatureTests.swift`의 참조를 갱신한다
- [X] T014 [S6] `sources/Projects/App/GitIt/GitItApp.swift`, `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`, `sources/Projects/App/GitIt/Screens/AppRootView.swift`의 주입 이름을 갱신한다
- [X] T015 [S6] `sources/Projects/App/Tests/GitIt/TestDoubles/LearningProjectOutcomesUseCaseMock.swift`를 `ObserveGenerationOutcomesUseCaseMock.swift`로 옮기고 `sources/Projects/App/Tests/GitIt/TestDoubles/AppRootTestSupport.swift`의 참조를 갱신한다

### 정리와 단위 검증

- [ ] T016 [no-write] App production build와 `AllTests`의 `compile`·`test`를 실행해 rename 이후에도 동작이 동일한지 확인한다

**진행 점검**: T001~T016의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행 단위로
진행한다.

---

## 실행 단위 2 (integration): 푸시 콜백 소유권과 명시적 부트스트랩

**관련 패키지**: Infrastructure → Composition → App

**분리 불가 근거**: `FirebaseMessagingAppDelegate`의 static 콜백 저장소를 인스턴스 소유로 바꾸면
Composition의 주입 방식과 App의 AppDelegate 배선이 같은 변경에서 바뀌어야 compile되고, 중간
상태에서는 푸시 수신 경로가 끊긴다.

**관련 변경 시나리오**: S4

**통합 검증**: App production build + `AllTests` compile·test + Simulator 실행 1회

### 테스트

- [X] T017 [S4] `sources/Projects/App/Tests/GitIt/GitItCompositionLifetimeTests.swift`에 `AppComposition` 생성만으로 외부 푸시 SDK 접근, Keychain read/write와 서버 호출이 발생하지 않음을 검증하는 테스트를 추가한다
- [X] T018 [P] [S4] `sources/Projects/Composition/Tests/Adapter/Factories/GenerationCompletionReminderCoordinatorTests.swift`에 `start(...)` 반환 시점에 구독이 확립돼 있음을 검증하는 테스트를 추가한다

### 구현

- [X] T019 [S4] `sources/Projects/Infrastructure/PushMessaging/Remote/AppDelegates/FirebaseMessagingAppDelegate.swift`의 `private static let state` Mutex를 제거하고 콜백을 인스턴스 프로퍼티로 옮긴다
- [X] T020 [S4] `sources/Projects/Infrastructure/PushMessaging/Remote/AppDelegates/FirebaseMessagingAppDelegate.swift`에 콜백 주입 전 도착 payload를 인스턴스 범위 대기 슬롯에 1건 보관했다가 주입 직후 정확히 1회 전달하는 수명 동작을 추가한다
- [X] T021 [P] [S4] `sources/Projects/Infrastructure/PushMessaging/Local/Models/LocalNotificationRequest.swift:7`의 ParameterFormatter 위반을 해소한다
- [X] T022 [S4] `sources/Projects/Composition/Adapter/Factories/GenerationCompletionReminderCoordinator.swift`의 `start(...)`가 스트림 확보를 마친 뒤 반환하도록 바꾸고 관찰 Task 생성 순서를 조정한다
- [X] T023 [S4] `sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`에서 initializer의 `FirebaseMessagingPushClient` 생성과 `Task { await reminderCoordinator.start(...) }`를 제거하고, [contracts/push-lifecycle.md](./contracts/push-lifecycle.md) §2의 순서 계약을 따르는 `bootstrap` 경계 값을 추가한다
- [X] T024 [S4] `sources/Projects/App/GitIt/GitItApp.swift`에서 `bootstrap()`을 `await`하고 `@UIApplicationDelegateAdaptor` 인스턴스에 `PushNotificationCallbacks`를 주입한다

### 정리와 단위 검증

- [X] T025 [no-write] Simulator에서 앱을 1회 실행해 `App.init()`과 `application(_:didFinishLaunchingWithOptions:)`의 실제 순서와 콜백 주입 시점을 확인하고 research.md R3의 미확정 위험 판정 결과를 진행 보고에 남긴다
- [ ] T026 [no-write] App production build와 `AllTests`의 `compile`·`test`를 실행한다

**진행 점검**: T017~T026의 변경 파일과 검증 결과를 보고한다. T025에서 대기 슬롯 설계로도 정확성을
보장할 수 없다고 판명되면 새 설계 결정이 필요하므로 여기서 중단하고 승인을 요청한다.

---

## 실행 단위 3 (integration): 등록 token 갱신과 기기 등록 시점 이전

**관련 패키지**: Infrastructure → Composition → App

**분리 불가 근거**: 새 Infrastructure 연산, Composition 경계 값, App의 호출 시점이 모두 있어야
기기 등록이 동작한다. 어느 하나만 바꾸면 등록 경로가 끊기거나 compile되지 않는다.

**관련 변경 시나리오**: S4

**통합 검증**: App production build + `AllTests` compile·test

**선행 조건**: 실행 단위 2. `bootstrap()` 경계 위에서 동작한다.

### 테스트

- [X] T027 [S4] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`에 인증 세션 확립 시 기기 등록이 1회 수행되고 실패가 상태로 남은 뒤 앱 활성화 사건에서 최신 token으로 재시도하는 테스트를 추가한다
- [X] T028 [P] [S4] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`와 `sources/Projects/App/Tests/GitIt/TestDoubles/AppRootTestSupport.swift`에 실패 후 token 갱신 시 갱신 token으로 재등록하고, 앱 활성화와 token 갱신이 동시에 발생해도 서버 요청이 1회인 시나리오와 Test Double을 추가한다

### 구현

- [X] T029 [S4] `sources/Projects/Infrastructure/PushMessaging/Remote/Clients/PushMessagingClient.swift`에 `registrationTokenRefreshes() -> AsyncStream<String>`를 추가한다
- [X] T030 [S4] `sources/Projects/Infrastructure/PushMessaging/Remote/Clients/FirebaseMessagingPushClient.swift`에서 `MessagingDelegate.didReceiveRegistrationToken`의 갱신을 위 스트림으로 방출하도록 구현한다
- [X] T031 [S4] `sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`에서 initializer의 기기 등록 `Task`를 제거하고 `registerCurrentDevice`와 `deviceTokenRefreshes` 경계 값을 노출한다
- [X] T032 [S4] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`에 인증 세션 확립 시 기기 등록을 수행하고 실패를 상태로 보존하며, 실패 후 앱 활성화·token 갱신 재시도와 동시 trigger 단일 Effect 직렬화, 인증 종료 시 상태·Effect 제거를 구현한다
- [X] T033 [S4] `sources/Projects/App/GitIt/GitItApp.swift`에서 `registerCurrentDevice`와 `deviceTokenRefreshes`를 `AppRootFeature`에 주입한다
- [X] T034 [S4] `sources/Projects/Composition/Tests/Adapter/Assemblies/AppCompositionPublicSurfaceTests.swift`에 신규 공개 경계 값을 반영한다

### 정리와 단위 검증

- [ ] T035 [no-write] App production build와 `AllTests`의 `compile`·`test`를 실행한다

**진행 점검**: T027~T035의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 실행 단위 4 (integration): Data 경계 어휘와 역할어 정렬

**관련 패키지**: Data → Composition, 공용 문서 1개

**분리 불가 근거**: `GenerationOutcomeDTO`와 `GenerationOutcomeStream`은 Composition의 adapter와
assembly가 컴파일 의존한다. 또한 새 형태 폴더 `Sources/`는
`docs/conventions/file-vocabulary.md` §3이 같은 PR에서의 표 갱신을 요구한다.

**관련 변경 시나리오**: S6

**통합 검증**: App production build + `AllTests` compile·test

### 준비와 기반

- [X] T036 [S6] `docs/conventions/file-vocabulary.md` §3의 `Data/<관심사>/` 행에 `Sources/`(외부에서 주입되는 프로세스 내 데이터 소스 구현)를 추가한다

### 구현

- [X] T037 [S6] `sources/Projects/Data/LearningProject/DTOs/GenerationOutcomeDTO.swift`를 `QuizGenerationOutcomeDTO.swift`로 옮기고 타입 이름을 바꾼다. payload 키 `"projectId"`는 서버 고정 이름이므로 유지한다
- [X] T038 [S6] `sources/Projects/Data/LearningProject/Contracts/GenerationOutcomeStream.swift`를 `QuizGenerationOutcomeSource.swift`로 옮기고 protocol 이름을 `QuizGenerationOutcomeSource`로 바꾼다
- [X] T039 [S6] `sources/Projects/Data/LearningProject/Remotes/PushGenerationOutcomeStream.swift`를 `sources/Projects/Data/LearningProject/Sources/PushQuizGenerationOutcomeSource.swift`로 옮기고 타입 이름과 지역 변수 `id`를 `subscriptionID`로 바꾼다
- [X] T040 [S6] `sources/Projects/Data/Tests/LearningProject/DTOs/GenerationOutcomeDTOTests.swift`를 `QuizGenerationOutcomeDTOTests.swift`로 옮기고 참조를 갱신한다
- [X] T041 [S6] `sources/Projects/Data/Tests/LearningProject/Remotes/PushGenerationOutcomeStreamTests.swift`를 `sources/Projects/Data/Tests/LearningProject/Sources/PushQuizGenerationOutcomeSourceTests.swift`로 옮기고 참조를 갱신한다
- [X] T042 [S6] `sources/Projects/Composition/Adapter/Adapters/GenerationOutcomeRepositoryAdapter.swift`의 주입 인자 `remote`를 `source`로 바꾸고 새 Data 타입을 참조한다
- [X] T043 [S6] `sources/Projects/Composition/Adapter/Assemblies/LearningProjectAssembly.swift`의 지역 변수와 생성 호출을 새 이름으로 갱신한다
- [X] T044 [S6] `sources/Projects/Composition/Tests/Adapter/Adapters/GenerationOutcomeRepositoryAdapterTests.swift`의 참조를 갱신한다

### 정리와 단위 검증

- [ ] T045 [no-write] `make tuist`로 파생 project를 갱신한 뒤 실행 전후 `git status --porcelain`을 비교하고, App production build와 `AllTests`의 `compile`·`test`를 실행한다

**진행 점검**: T036~T045의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 실행 단위 5 (단일): Feature/ProjectRegistration — 구독-요청 직렬화와 실패 탈출

**소유 경로**: `sources/Projects/Feature/ProjectRegistration/Reducers/`,
`sources/Projects/Feature/Tests/ProjectRegistration/Reducers/`

**관련 변경 시나리오**: S1, S2

**독립 검증**: reducer 테스트만으로 생성 요청 전 구독 확립, 응답 전 도착 결과 반영, 실패 시 시트
종료를 확인할 수 있다.

### 테스트

- [X] T046 [S1] `sources/Projects/Feature/Tests/ProjectRegistration/Reducers/ProjectRegistrationFeatureTests.swift`에 생성 요청이 전송되는 시점에 생성 결과 구독이 이미 확립돼 있음을 검증하는 테스트를 추가한다
- [X] T047 [S1] `sources/Projects/Feature/Tests/ProjectRegistration/Reducers/ProjectRegistrationFeatureTests.swift`에 생성 요청 응답보다 먼저 도착한 완료 결과가 진행 화면 상태에 반영되는 테스트를 추가한다
- [X] T048 [S1] `sources/Projects/Feature/Tests/ProjectRegistration/Reducers/ProjectRegistrationFeatureTests.swift`에 같은 프로젝트의 완료 결과를 2회 수신해도 최종 상태와 delegate 전달이 1회 수신과 동일한 테스트를 추가한다
- [X] T049 [S2] `sources/Projects/Feature/Tests/ProjectRegistration/Reducers/ProjectRegistrationFeatureTests.swift`에 알림 옵션 시트 표시 중 실패 결과가 도착하면 시트가 닫히고 재시도·종료 Action이 유효한 테스트를 추가한다

### 구현

- [X] T050 [S1] `sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`의 제출 처리를 단일 `.run` Effect로 합쳐 생성 결과 스트림 확보 → 생성 요청 → 응답 receipt의 `projectID`로 필터링 순서로 직렬화하고, `CancelID.submission`과 `CancelID.generationOutcomeObservation`을 단일 ID로 통합한다
- [X] T051 [S2] `sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`에서 생성 실패 전이 시 시트 표시 상태를 함께 닫고, 실패 상태에서 재시도와 흐름 종료 Action이 항상 유효하도록 guard를 조정한다

### 정리와 단위 검증

- [ ] T052 [no-write] `AllTests`의 `compile`·`test`를 실행해 `ProjectRegistrationFeatureTests`의 기존 시나리오가 계속 통과하는지 확인한다

**진행 점검**: T046~T052의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 실행 단위 6 (단일): Feature/ProjectRegistration — 단계 상태 소유와 진행 상태 이름

**소유 경로**: `sources/Projects/Feature/ProjectRegistration/`,
`sources/Projects/Feature/Tests/ProjectRegistration/`

**관련 변경 시나리오**: S5, S6

**독립 검증**: reducer 테스트로 단계 전이를 검증하고, 화면에서 `@State` 두 개가 사라졌는지 확인한다.

### 테스트

- [X] T053 [S5] `sources/Projects/Feature/Tests/ProjectRegistration/Reducers/ProjectRegistrationFeatureTests.swift`에 저장소 확인 → 이해도 선택 → 생성 확정과 역방향 전이가 Feature 상태로 유지되는 테스트를 추가한다

### 구현

- [X] T054 [S5] `sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`의 `State`에 배타적 단계 enum `RegistrationStep`(`.repositoryConfirmation`, `.quizLevelSelection`, `.generationConfirmation`)과 전이 Action을 추가한다
- [X] T055 [S5] `sources/Projects/Feature/ProjectRegistration/Screens/ProjectRegistrationScreen.swift`의 `@State hasConfirmedRepository`와 `@State hasSelectedQuizLevel`을 제거하고 store의 단계 상태를 읽도록 바꾼다. `@State isGuideExpanded`는 유지한다
- [X] T056 [S6] `sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`에서 `SubmissionStatus`를 `RegistrationProgress`로, `.committing`을 `.submitting`으로, `.awaitingGeneration`을 `.awaitingOutcome`으로, `State.submission`을 `State.progress`로 바꾼다
- [X] T056a [S6] `sources/Projects/Feature/ProjectRegistration/Screens/ProjectRegistrationScreen.swift:55-57`의 `store.submission` switch와 `.committing`·`.awaitingGeneration` case를 `store.progress`, `.submitting`, `.awaitingOutcome`으로 갱신한다. T055와 같은 파일이므로 순차 실행한다
- [X] T056b [S6] `sources/Projects/Feature/Tests/ProjectRegistration/Reducers/ProjectRegistrationFeatureTests.swift`의 `state.submission`·`$0.submission`·`$0.child?.submission`과 `.committing`·`.awaitingGeneration` 참조 전체를 새 이름으로 갱신한다. 기존 테스트 시나리오의 동작은 바꾸지 않고 이름만 정렬한다
- [X] T057 [S6] `sources/Projects/Feature/ProjectRegistration/Previews/ProjectRegistrationScreenPreviews.swift`의 상태 구성을 새 이름과 단계 상태로 갱신한다. `ProjectRegistrationFeature.SubmissionStatus` 타입 참조와 `submission:` 인자 이름도 함께 바꾼다
- [X] T058 `sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/StubRequestGenerationReminderUseCase.swift:7`의 ParameterFormatter 위반을 해소한다

### 정리와 단위 검증

- [ ] T059 [no-write] `AllTests`의 `compile`·`test`를 실행한다

**진행 점검**: T053~T059(T056a·T056b 포함)의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로
진행한다.

---

## 실행 단위 7 (단일): Feature/Home — 조회 중 생성 결과 반영과 중복 멱등

**소유 경로**: `sources/Projects/Feature/Home/Reducers/`,
`sources/Projects/Feature/Tests/Home/Reducers/`

**관련 변경 시나리오**: S5

**독립 검증**: reducer 테스트만으로 조회 중 수신·조회 완료 후 반영·중복 무시를 확인할 수 있다.

### 테스트

- [X] T060 [S5] `sources/Projects/Feature/Tests/Home/Reducers/HomeFeatureGenerationOutcomeTests.swift`에 `projectLoad == .loading` 중 도착한 결과가 조회 완료 후 재조회로 반영되는 테스트를 추가한다
- [X] T061 [S5] `sources/Projects/Feature/Tests/Home/Reducers/HomeFeatureGenerationOutcomeTests.swift`에 이미 반영한 프로젝트의 동일 결과가 다시 도착해도 재조회가 발생하지 않는 테스트를 추가한다

### 구현

- [X] T062 [S5] `sources/Projects/Feature/Home/Reducers/HomeFeature.swift`의 `State`에 `isProjectRefreshPending`과 `appliedOutcomeProjectIDs`를 추가하고, 조회 중 수신 시 폐기 대신 pending 기록 후 조회 완료 시점에 재조회하도록 바꾼다

### 정리와 단위 검증

- [ ] T063 [no-write] `AllTests`의 `compile`·`test`를 실행한다

**진행 점검**: T060~T063의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 실행 단위 8 (integration): 리마인드 Action과 화면 이름 정렬

**관련 패키지**: Feature → App

**분리 불가 근거**: `delegate(.notificationOptionSelected(accepted:))`를 `AppRootFeature`가
소비하므로 Feature만 rename하면 App이 compile되지 않는다.

**관련 변경 시나리오**: S6

**통합 검증**: App production build + `AllTests` compile·test

### 구현

- [X] T064 [S6] `sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`의 `isNotificationOptionSheetPresented`를 `isGenerationReminderSheetPresented`로, `view(.notificationOptionAccepted)`·`view(.notificationOptionDeclined)`를 `view(.generationReminderAccepted)`·`view(.generationReminderDeclined)`로, `delegate(.notificationOptionSelected(accepted:))`를 `delegate(.generationReminderPreferenceSelected(isEnabled:))`로 바꾼다
- [X] T065 [S6] `sources/Projects/Feature/ProjectRegistration/Screens/NotificationOptionSheet.swift`를 `GenerationReminderSheet.swift`로 옮기고 타입 이름을 바꾼다
- [X] T066 [P] [S6] `sources/Projects/Feature/ProjectRegistration/Screens/GenerationConfirmationScreen.swift`를 `QuizGenerationConfirmationScreen.swift`로 옮기고 타입 이름을 바꾼다
- [X] T067 [P] [S6] `sources/Projects/Feature/ProjectRegistration/Screens/GenerationProgressScreen.swift`를 `QuizGenerationProgressScreen.swift`로 옮기고 타입 이름을 바꾼다
- [X] T068 [S6] `sources/Projects/Feature/ProjectRegistration/Screens/ProjectRegistrationScreen.swift`와 `sources/Projects/Feature/ProjectRegistration/Previews/ProjectRegistrationScreenPreviews.swift`의 화면·Action 참조를 갱신한다
- [X] T069 [S6] `sources/Projects/Feature/Tests/ProjectRegistration/Reducers/ProjectRegistrationFeatureTests.swift`의 Action 참조를 갱신한다
- [X] T070 [S6] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`의 delegate 처리 case를 새 이름으로 갱신한다

### 정리와 단위 검증

- [ ] T071 [no-write] `make tuist`로 파생 project를 갱신하고 실행 전후 `git status --porcelain`을 비교한 뒤, App production build와 `AllTests`의 `compile`·`test`를 실행한다

**진행 점검**: T064~T071의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 실행 단위 9 (integration): Home Action 출처 분류와 MainShell delegate 통합

**관련 패키지**: Feature → App

**분리 불가 근거**: `AppRootFeature`가 `.mainShell(.home(.view(.reloadRequested)))`를 직접 보내고
`projectSelected`·`projectDetailRequested` 두 delegate를 함께 처리하므로, Feature 쪽 분류 변경과
App 쪽 handler 변경이 같은 단위에 있어야 compile된다.

**관련 변경 시나리오**: S6

**통합 검증**: App production build + `AllTests` compile·test

### 구현

- [X] T072 [S6] `sources/Projects/Feature/Home/Reducers/HomeFeature.swift`의 `Action`에 `input(Input)` 분류를 추가하고 `View.reloadRequested`를 `Input.learningProjectsReloadRequested`로 옮긴다
- [X] T073 [P] [S6] `sources/Projects/Feature/MainShell/Reducers/MainShellFeature.swift`의 `Delegate.projectSelected(projectID:)`를 제거하고 `projectList` child delegate를 `projectDetailRequested(projectID:)`로 변환해 내보낸다
- [X] T074 [S6] `sources/Projects/Feature/Tests/Home/Reducers/HomeFeatureGenerationOutcomeTests.swift`와 `sources/Projects/Feature/Tests/MainShell/Reducers/MainShellFeatureTests.swift`의 Action 참조를 갱신한다
- [X] T075 [S6] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`에서 Home 재조회 전송을 `input` 분류로 바꾸고 `projectSelected` 처리 case를 제거한다
- [X] T076 [S6] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`의 참조를 갱신한다

### 정리와 단위 검증

- [ ] T077 [no-write] App production build와 `AllTests`의 `compile`·`test`를 실행한다

**진행 점검**: T072~T077의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 실행 단위 10 (integration): 설정 화면 이동의 메인 액터 계약

**관련 패키지**: Feature → App

**분리 불가 근거**: 의존성 클로저 타입에 `@MainActor`를 추가하면 선언부(Feature)와 주입부(App)가
동시에 바뀌어야 compile된다.

**관련 변경 시나리오**: S3

**통합 검증**: App production build + `AllTests` compile·test + Main Thread Checker 수동 확인

### 구현

- [X] T078 [S3] `sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`의 `openNotificationSettings` 타입을 `@MainActor @Sendable () async -> Void`로 바꾼다
- [X] T079 [S3] `sources/Projects/Feature/Tests/ProjectRegistration/Reducers/ProjectRegistrationFeatureTests.swift`의 `OpenNotificationSettingsSpy`를 새 계약에 맞춘다
- [X] T080 [S3] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`의 `openNotificationSettings` 프로퍼티와 initializer 인자 타입을 갱신한다
- [X] T081 [S3] `sources/Projects/App/GitIt/GitItApp.swift`의 클로저를 새 계약으로 선언하고 `MainActor.run` 래핑 없이 `UIApplication.shared.open(url)`을 호출한다

### 정리와 단위 검증

- [ ] T082 [no-write] App production build와 `AllTests`의 `compile`·`test`를 실행한다

**진행 점검**: T078~T082의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 실행 단위 11 (단일): App — 인증 종료 시 등록 흐름 child 정리

**소유 경로**: `sources/Projects/App/GitIt/Reducers/`, `sources/Projects/App/Tests/GitIt/Reducers/`

**관련 변경 시나리오**: S2

**독립 검증**: `AppRootFeatureTests`만으로 child 제거와 Effect 취소, 재로그인 시 stale presentation
부재를 확인할 수 있다.

### 테스트

- [X] T083 [S2] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`에 인증 종료 시 `projectRegistration`이 `nil`이 되고 child의 생성 결과 관찰 Effect가 취소되는 테스트를 추가한다
- [X] T084 [S2] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`에 재로그인 시 이전 세션의 full-screen cover가 다시 표시되지 않는 테스트를 추가한다

### 구현

- [X] T085 [S2] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`의 `returnToOnboarding(_:)`이 `projectRegistration`을 `nil`로 설정하도록 바꾸고 모든 인증 종료·초기화 경로가 이를 거치는지 확인한다

### 정리와 단위 검증

- [ ] T086 [no-write] `AllTests`의 `compile`·`test`를 실행한다

**진행 점검**: T083~T086의 변경 파일과 검증 결과를 보고하고 전체 완료 검증으로 진행한다.

---

## 실행 단위 12 (단일): Composition — 식별자 획득 연산 이름 정렬

**소유 경로**: `sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`

**관련 변경 시나리오**: S6

**독립 검증**: 이전 연산 이름이 남지 않고 Composition 테스트가 통과한다.

### 구현

- [X] T087 [S6] `sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`의 `deviceID(keychainStore:)`를 `loadOrCreateDeviceID(keychainStore:)`로 바꿔 조회·생성·저장 부수효과를 이름에 드러낸다

### 정리와 단위 검증

- [X] T088 [no-write] Composition 테스트 target의 `compile`·`test`를 실행하고 `deviceID(keychainStore:)` 잔여 참조가 0건인지 확인한다

---

## 실행 단위 13 (integration): 생성 결과 payload 인입 API 이름 정렬

**관련 패키지**: Infrastructure → Composition

**분리 불가 근거**: Infrastructure 콜백 필드와 Composition 조립 공개 경계가 같은 이름으로 함께
바뀌어야 compile되며, 동작·수명 변경은 실행 단위 2에서 이미 완료된 후다.

**관련 변경 시나리오**: S6

**통합 검증**: App production build + `AllTests` compile·test

### 구현

- [X] T089 [S6] `sources/Projects/Infrastructure/PushMessaging/Remote/Models/PushNotificationCallbacks.swift`, `sources/Projects/Infrastructure/PushMessaging/Remote/AppDelegates/FirebaseMessagingAppDelegate.swift`, `sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`의 `ingestPushPayload`를 `ingestGenerationOutcomePayload`로 정렬한다

### 정리와 단위 검증

- [ ] T090 [no-write] App production build와 `AllTests`의 `compile`·`test`를 실행하고 `ingestPushPayload` 잔여 참조가 0건인지 확인한다

---

## 전체 완료 검증

**선행 조건**: 실행 단위 13의 파일 변경 작업을 완료하고, 전체 검증과 hook 결과를 포함할 마지막
커밋 단위를 아직 commit하지 않은 상태여야 한다.

**커밋 경계**: 아래 `[no-write]` 작업은 실행 단위 13의 마지막 커밋 단위에 배정한다. 모든 검증과
필수 `after_implement` hook을 마친 뒤 그 단위를 최종 commit한다.

- [ ] T091 [no-write] [quickstart.md](./quickstart.md) §3.1의 `build`·`compile`·`test`·formatter lint 네 명령을 순차 실행하고 결과를 기록한다 (SC-011, SC-012)
- [X] T092 [no-write] [quickstart.md](./quickstart.md) §3.3의 심볼 검색을 모두 실행해 잔여 참조가 기대와 일치하는지 확인한다. `projectSelected`는 0건이 아니라 §3.3이 명시한 존속 참조 기준으로 판정한다 (SC-010)
- [ ] T093 [no-write] [quickstart.md](./quickstart.md) §3.2의 14개 회귀 시나리오가 실제 테스트로 존재하고 통과하는지 대조한다 (SC-012)
- [ ] T094 [no-write] [quickstart.md](./quickstart.md) §4.1·§4.2·§4.4의 Simulator 수동 검증을 수행하고 결과를 기록한다 (SC-003, SC-005, SC-008)
- [X] T095 [no-write] 변경 시나리오 S1~S6의 독립 수용 기준을 대조하고, 실행하지 못한 검증(§4.3의 실제 기기 APNs 수신 포함)을 미검증으로 명시한다

## 의존성과 실행 순서

### 실행 단위 순서와 근거

채택한 순서는 아키텍처 §3.1의 위상 순서를 따른다.

```text
Domain (의존 없음) · Infrastructure (의존 없음)
  → Data (→ Infrastructure)
  → Composition (→ Domain, Data, Infrastructure)
  → Feature (→ Domain, UI)
  → App (→ Feature, Composition, Domain)
```

| 순서 | 실행 단위 | 근거 |
| --- | --- | --- |
| 1 | 단위 1 (Domain rename) | Domain 공개 protocol 이름이 나머지 모든 단위의 파일에 나타난다. 먼저 정리해야 같은 파일을 두 번 건드리지 않는다 |
| 2 → 3 | 단위 2 → 단위 3 | 단위 3의 기기 등록이 단위 2가 만든 `bootstrap()` 경계 위에서 동작한다 |
| 4 | 단위 4 (Data) | Data → Composition 방향. Feature·App과 파일이 겹치지 않아 단위 5 이후로 미뤄도 되지만, 위상 순서를 따라 Composition 변경을 앞에 모은다 |
| 5 · 6 · 7 | Feature 단일 단위 | 서로 다른 파일을 다루며 상호 의존이 없다. 이 순서를 구현 종료까지 바꾸지 않는다 |
| 8 · 9 · 10 | Feature + App 통합 단위 | 모두 `AppRootFeature.swift`를 건드리므로 순차 실행한다 |
| 11 | App 단일 단위 | App 변경을 마지막에 모아 `AppRootFeature.swift`의 반복 수정을 줄인다 |
| 12 | Composition 네이밍 단위 | 식별자 획득 연산 rename을 기기 등록 수명 변경과 분리한다 |
| 13 | Infrastructure + Composition 네이밍 통합 단위 | payload 인입 API rename을 콜백 수명·bootstrap 변경이 완료된 후 적용한다 |

`sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`는 단위 1·3·8·9·10·11이 모두 수정한다.
이 파일을 다루는 단위는 병렬 실행하지 않는다.

### 변경 시나리오 추적성

| 시나리오 | 작업 | 독립 수용 기준 |
| --- | --- | --- |
| S1 | T046~T048, T050 | 생성 요청 전송 시점에 구독이 확립돼 있고, 응답보다 먼저 도착한 결과가 반영되며, 중복 수신이 멱등하다 |
| S2 | T049, T051, T083~T085 | 시트 표시 중 실패에서 재시도·종료가 가능하고, 인증 종료 시 등록 흐름 child와 그 Effect가 사라진다 |
| S3 | T078~T081 | 권한 거부 상태에서 리마인드 수락 시 Main Thread Checker 경고가 0건이다 |
| S4 | T017~T024, T027~T034 | 조립만으로 외부 SDK·Keychain·서버 접근이 0건이고, `bootstrap()` 반환 시 리마인드 구독이 확립돼 있으며, 기기 등록 실패 후 앱 활성화·token 갱신으로 재시도하고 동시 trigger는 요청 1회로 직렬화된다 |
| S5 | T053~T055, T060~T062 | View 재생성 후 단계가 유지되고, 조회 중 도착한 결과가 조회 완료 후 반영된다 |
| S6 | T003~T015, T036~T044, T056·T056a·T056b·T057, T064~T070, T072~T076, T087, T089 | [contracts/naming-map.md](./contracts/naming-map.md) §7의 심볼 검색이 모두 기대와 일치한다 |

### 실행 단위 내부 실행

- 테스트를 포함한 단위는 구현 전에 테스트를 작성하고 예상한 이유로 실패하는지 확인한다.
- `[P]`는 현재 실행 단위 안의 서로 다른 파일에만 사용한다.
- 같은 파일을 변경하는 작업과 Red → Green 의존 작업은 순차 실행한다.
- 서로 다른 실행 단위의 Git index·같은 파일 변경은 병렬 실행하지 않는다.
- `/speckit-implement`는 파일을 수정하기 전에 현재 실행 단위의 미완료 작업을 하나의 목적과
  독립적인 rollback 경계를 갖는 순서화된 커밋 단위로 묶는다. 구현과 직접 관련된 테스트는 같은
  단위에 둘 수 있지만 기능, 구조 정리, rename과 자동 포맷은 목적이 다르면 분리한다.
- 각 커밋 단위는 포함 작업 ID, 정확한 파일 경로, 검증과 커밋 메시지를 먼저 제시한다. 단위의
  검증과 `[X]` 표시를 완료한 뒤 해당 파일과 이 `tasks.md`만 stage·commit하고, 커밋 성공을 확인하기
  전에는 다음 단위를 시작하지 않는다.
- 실행 단위 13의 마지막 단위는 전체 완료 검증과 필수 `after_implement` hook이 끝날 때까지
  commit하지 않는다.

### 위험 기반 승인 조건

같은 기능 범위의 후속 단위와 읽기 전용 전체 검증은 반복 승인 없이 진행한다. 아래 두 경우에만
중단하고 명시적 승인을 요청한다.

1. **T025의 판정이 설계를 바꿀 때** — SwiftUI 초기화 순서 확인 결과 대기 슬롯 설계로도 정확성을
   보장할 수 없다면 새 설계 결정이 필요하다.
2. **실제 기기 APNs 검증이 필요할 때** — quickstart §4.3은 provisioning과 APNs key가 연결된 기기를
   요구한다. 준비 여부는 사용자만 판단할 수 있다.

## 구현 전략

1. 중단 단위와 tasks.md 전체 diff를 분류하고 blob hash와 diff를 기준선으로 고정한다. 재개 단위가
   없으면 실행 단위 1의 T001부터 시작한다.
2. 선택한 실행 단위의 미완료 작업을 논리적 커밋 단위로 설계한다.
3. 각 단위의 구현·검증·완료 표시·커밋을 순서대로 완료하고 생성된 커밋을 확인한다.
4. 실행 단위가 커밋되면 변경 파일, 검증 결과와 커밋을 진행 상황으로 보고하고 다음 단위로 이어간다.
5. 위 승인 조건에 해당하는 경계가 나타나면 변경을 시작하기 전에 중단한다.
6. 실행 단위 13에서 전체 완료 검증과 필수 `after_implement` hook을 실행하고 결과를 재검증한 뒤
   마지막 단위를 최종 commit한다.

## 최소 가치 범위

**실행 단위 1 + 실행 단위 5**가 최소 가치 범위다. 단위 1이 이름 충돌을 먼저 제거하고, 단위 5가
S1(생성 결과 유실)과 S2의 절반(실패 시 시트 고정)을 해소한다. 두 결함 모두 사용자가 앱에서
빠져나오지 못하거나 무기한 대기하게 만드는 P1이며, 나머지 단위 없이도 독립적으로 검증·배포할 수
있다. 새 권한이 필요하지 않으므로 이후 단위로 연속 진행한다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 이 문서는 커밋 단위를 미리 고정하지 않는다. `/speckit-implement`가 실행 시점에 설계한다.
- 문제 해결과 암묵지 기록은 구현 작업으로 만들지 않는다. 조건 충족 시 전용 스킬을 별도 실행한다.
