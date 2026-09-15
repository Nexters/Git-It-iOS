# 작업 목록: 생성 상태 관측 단일화와 무효 스트림 제거

**입력**: `/specs/030-async-stream-redesign/`의 설계 문서

**선행 조건**: [plan.md](./plan.md)(필수), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/README.md](./contracts/README.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를 실행 기준선으로 고정한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 필요한 경우에만 만든다.

**테스트**: 명세 [spec.md](./spec.md)의 SC-001·SC-005·SC-006이 자동화 테스트 증명을 요구하므로 테스트 작업을 포함한다.

**구성**: [plan.md](./plan.md)의 실행 단위 U1~U5와 I1을 최상위 구조로 사용하고, 변경 시나리오는 각 단위 안에서 `[S1]`~`[S3]` 라벨로 추적한다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- `[P]` — 같은 실행 단위 안에서 서로 다른 파일을 다루고 미완료 작업에 의존하지 않는 작업
- `[S1]` 구독 시점과 무관한 생성 상태 관측 / `[S2]` 자격 증명 관측 경로 제거 / `[S3]` 기기 토큰 갱신 신호 정정
- `[no-write]` — 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 검증. `make tuist`의 파생 workspace·project·심볼릭 링크·cache 갱신은 허용하되 실행 전후 Git 상태를 비교하고 추적 파일 변경이 생기면 완료로 처리하지 않는다

## 실행 단위 소유권 규칙

- 파일 변경 작업은 책임 패키지 단계에 배치한다.
- 위상 순서의 근거는 [아키텍처 3.1](../../docs/architecture.md)의 패키지 의존성 표다. `Infrastructure`·`Domain`은 무의존, `Data`는 `Infrastructure` 뒤, `Composition`은 `Domain`·`Data`·`Infrastructure` 뒤, `Feature`는 `Domain` 뒤, `App`은 전부의 뒤에 온다.
- U4·U5가 Domain 공개 계약을 제거하면 Composition·Feature·App이 동시에 컴파일 실패하므로 그 사용처 교체는 불가분한 integration unit I1로 묶는다. 근거는 [plan.md](./plan.md)의 "I1을 다중 패키지 단위로 두는 근거"에 있다.

## 명세 편차 (구현 전 확인 필요)

**FR-008의 표현 방식** — 명세는 기기 토큰 갱신을 "값 없는 연속 스트림이 아니라 갱신 시점을 통지하는 수단"으로 요구한다. 그러나 TCA의 `Effect.run`은 장기 실행 비동기 시퀀스를 전제로 하므로, 통지 수단을 콜백 등록으로 바꾸면 App이 그 콜백을 다시 시퀀스로 감싸야 한다. 결과적으로 감싸는 지점이 Composition에서 App으로 이동할 뿐 계층 수가 줄지 않으며 FR-011(불필요한 재래핑 금지)과 충돌한다.

이 작업 목록은 FR-008의 **의도**(값 없는 재래핑 제거, 주입 누락의 조용한 흡수 제거)를 다음으로 충족한다.

- Composition의 `AsyncStream<Void>` 재래핑을 제거하고 Infrastructure가 소유한 토큰 통지를 그대로 전달한다 (FR-011 충족)
- 전달 값을 `Void`가 아니라 갱신된 토큰으로 바꿔 정보 손실을 없앤다
- App 초기화 인자의 기본값을 제거해 주입 누락이 컴파일 오류가 되게 한다 (FR-009 충족)
- 통지 등록 해제 시 등록 목록에서 제거되게 한다 (FR-010 충족)

FR-008의 문자 그대로의 형태(콜백)를 유지해야 한다면 T003을 시작하기 전에 알려야 한다. 이 편차는 Constitution 원칙 3에 따라 PR에 이유·영향·미검증 범위로 기록한다.

---

## 작업 패키지 1 (U1): Infrastructure

**목표**: 값을 전달하지 않는 자격 증명 변경 전달을 제거하고, 토큰 갱신 통지에 등록 해제를 보장한다.

**소유 경로**: `sources/Projects/Infrastructure/Authentication/**`, `sources/Projects/Infrastructure/PushMessaging/**`, `sources/Projects/Infrastructure/Tests/Authentication/**`

**관련 변경 시나리오**: S2, S3

**주의**: 자격 증명 변경 전달의 제거 자체(T002)는 I1로 옮겼다. U1은 그 제거를 준비하는 테스트 정리와 토큰 갱신 통지 점검만 소유한다.

**독립 검증**: `InfrastructureAuthenticationTests` target이 통과하고, Infrastructure가 다른 프로젝트 패키지를 참조하지 않는 상태가 유지된다.

### 테스트

- [ ] T001 [P] [S2] `sources/Projects/Infrastructure/Tests/Authentication/AppleAuthentication/Providers/AppleCredentialStateProviderTests.swift`에서 `changes()`와 `receiveRevocation(for:)`을 검증하던 테스트를 제거하고, `state(for:)`의 기존 보장이 남아 있는지 확인한다

### 구현

- [ ] T003 [S3] `sources/Projects/Infrastructure/PushMessaging/Remote/Clients/PushMessagingClient.swift`의 토큰 갱신 통지 계약에 등록 해제 보장을 명시한다
- [ ] T004 [S3] `sources/Projects/Infrastructure/PushMessaging/Remote/Clients/FirebaseMessagingPushClient.swift`에서 통지 종료 시 등록 목록에서 제거되도록 하고, 반복 등록·해제 후 목록이 증가하지 않게 한다

### 패키지 검증

- [ ] T005 [no-write] `InfrastructureAuthenticationTests`를 실행해 U1을 검증한다

**진행 점검**: T001~T005의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행 단위로 승인 없이 계속한다.

---

## 작업 패키지 2 (U2): Domain — 생성 상태 모델과 보존 계약 추가

**목표**: 통합 생성 상태의 값 구조와 보존 계약을 추가한다. 기존 코드를 제거하지 않으므로 이 단위만으로 빌드가 유지된다.

**소유 경로**: `sources/Projects/Domain/LearningProject/Models/LearningProject/**`, `sources/Projects/Domain/LearningProject/Contracts/**`, `sources/Projects/Domain/Tests/LearningProject/Models/LearningProject/**`

**관련 변경 시나리오**: S1

**독립 검증**: `DomainLearningProjectTests`가 통과하고 새 모델의 불변식이 테스트로 고정된다.

### 테스트

- [ ] T006 [P] [S1] `sources/Projects/Domain/Tests/LearningProject/Models/LearningProject/GenerationStateTests.swift`에 [data-model.md](./data-model.md) 2절의 불변식과 조회 규칙 테스트를 작성한다 — 같은 프로젝트 식별자 기록 1개, 같은 정규화 URL의 진행 중 기록 1개, 만료 기록 제외
- [ ] T007 [P] [S1] `sources/Projects/Domain/Tests/LearningProject/Models/LearningProject/GenerationRecordTests.swift`에 상태 전이와 URL 정규화 규칙 테스트를 작성한다

### 구현

- [ ] T008 [P] [S1] `sources/Projects/Domain/LearningProject/Models/LearningProject/GenerationRecord.swift`에 생성 기록 값을 정의한다 — 정규화 URL, 프로젝트 식별자, 요청 시각, 상태, 종료 시각
- [ ] T009 [S1] `sources/Projects/Domain/LearningProject/Models/LearningProject/GenerationState.swift`에 생성 상태 스냅샷과 조회 규칙을 정의한다
- [ ] T010 [P] [S1] `sources/Projects/Domain/LearningProject/Contracts/GenerationStateRepository.swift`에 생성 상태 보존 계약을 정의한다

### 패키지 검증

- [ ] T011 [no-write] `DomainLearningProjectTests`를 실행해 U2를 검증한다

**진행 점검**: T006~T011의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 작업 패키지 3 (U3): Data — 생성 상태 저장과 1회 이관

**목표**: 통합 생성 상태의 로컬 저장 구현과 기존 두 키의 1회 이관을 소유한다.

**소유 경로**: `sources/Projects/Data/LearningProject/Contracts/**`, `sources/Projects/Data/LearningProject/DTOs/**`, `sources/Projects/Data/LearningProject/Stores/**`, `sources/Projects/Data/Tests/LearningProject/**`

**관련 변경 시나리오**: S1

**독립 검증**: `DataLearningProjectTests`가 통과하고, 기존 두 키에 값이 있는 상태에서 처음 불러오면 병합·저장·기존 키 제거가 일어남을 테스트가 증명한다.

### 테스트

- [ ] T012 [P] [S1] `sources/Projects/Data/Tests/LearningProject/Stores/LocalGenerationStateStoreTests.swift`에 저장·불러오기 왕복과 만료 정리 테스트를 작성한다
- [ ] T013 [S1] `sources/Projects/Data/Tests/LearningProject/Stores/GenerationStateMigrationTests.swift`에 [data-model.md](./data-model.md) 5절의 병합 규칙 이관 테스트를 작성한다 — 기존 진행 정보만 있는 경우, 기존 등록 상태만 있는 경우, 둘 다 있고 프로젝트 식별자가 겹치는 경우

### 구현

- [ ] T014 [P] [S1] `sources/Projects/Data/LearningProject/DTOs/GenerationStateDTO.swift`에 생성 상태의 저장 표현을 정의한다
- [ ] T015 [S1] `sources/Projects/Data/LearningProject/Contracts/GenerationStateStore.swift`에 Data 저장 계약을 정의한다
- [ ] T016 [S1] `sources/Projects/Data/LearningProject/Stores/LocalGenerationStateStore.swift`에 단일 키 저장 구현과 기존 두 키의 1회 이관을 구현한다
- [ ] T017 [S1] `sources/Projects/Data/LearningProject/Contracts/GenerationProgressStore.swift`와 `sources/Projects/Data/LearningProject/Stores/LocalGenerationProgressStore.swift`를 제거한다
- [ ] T018 [S1] `sources/Projects/Data/LearningProject/DTOs/GenerationProgressDTO.swift`를 제거한다

### 패키지 검증

- [ ] T019 [no-write] `DataLearningProjectTests`를 실행해 U3을 검증한다

**진행 점검**: T012~T019의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 작업 패키지 4 (U4): Domain — 생성 추적 도입과 구 계약 제거

**목표**: 최신 상태를 보유하고 관측 시작 시 현재 상태를 먼저 전달하는 생성 추적을 도입하고, 이를 대체된 구 계약 2종을 제거한다.

**소유 경로**: `sources/Projects/Domain/LearningProject/UseCases/**`, `sources/Projects/Domain/LearningProject/Contracts/**`, `sources/Projects/Domain/LearningProject/Models/LearningProject/**`, `sources/Projects/Domain/Tests/LearningProject/**`

**관련 변경 시나리오**: S1

**독립 검증**: 관측 시작 순서를 바꿔도 같은 상태를 얻는다는 테스트와, 반복 등록·해제 후 관측자 목록이 증가하지 않는다는 테스트가 통과한다.

### 테스트

- [ ] T020 [S1] `sources/Projects/Domain/Tests/LearningProject/UseCases/TrackGenerationTests.swift`에 관측 시점 독립성 테스트를 작성한다 — 완료 통지 후 관측 시작 시 첫 값이 완료 상태, 관측 후 완료 통지 시 진행 중→완료 순서 전달, 관측자 둘이 같은 값 수신
- [ ] T021 [S1] `sources/Projects/Domain/Tests/LearningProject/UseCases/TrackGenerationTests.swift`에 관측 해제 테스트를 추가한다 — 반복 등록·해제 후 내부 관측자 목록 크기가 증가하지 않는다
- [ ] T022 [S1] `sources/Projects/Domain/Tests/LearningProject/UseCases/CreateLearningProjectTests.swift`의 중복 등록 거부 보장을 생성 추적 기준으로 옮긴다
- [ ] T023 [S1] `sources/Projects/Domain/Tests/LearningProject/UseCases/FetchLearningProjectsTests.swift`의 진행 중 항목 필터 보장을 생성 추적 기준으로 옮긴다
- [ ] T024 [S1] `sources/Projects/Domain/Tests/LearningProject/TestDoubles/`에 생성 상태 보존 계약과 생성 결과 수신 계약의 테스트 더블을 추가한다

### 구현

- [ ] T025 [S1] `sources/Projects/Domain/LearningProject/UseCases/TrackGeneration/TrackGenerationUseCase.swift`에 [contracts/README.md](./contracts/README.md) 1.1의 연산 계약을 정의한다
- [ ] T026 [S1] `sources/Projects/Domain/LearningProject/UseCases/TrackGeneration/GenerationStateCoordinator.swift`에 상태 정본을 보유하는 actor를 구현한다 — 보존 계약에서 복원, 생성 결과 수신 반영, 만료 정리
- [ ] T027 [S1] `sources/Projects/Domain/LearningProject/UseCases/TrackGeneration/TrackGeneration.swift`에 관측 시작 시 현재 상태를 먼저 전달하는 구현과 관측 해제 처리를 구현한다
- [ ] T028 [S1] `sources/Projects/Domain/LearningProject/UseCases/CreateLearningProject/CreateLearningProject.swift`가 등록 상태 저장소 대신 생성 추적을 사용하도록 바꾼다. 외부 시그니처는 유지한다
- [ ] T029 [S1] `sources/Projects/Domain/LearningProject/UseCases/FetchLearningProjects/FetchLearningProjects.swift`가 등록 상태 저장소 대신 생성 추적을 사용하도록 바꾼다. 외부 시그니처는 유지한다
- [ ] T030 [S1] `sources/Projects/Domain/LearningProject/Contracts/RepositoryCreationStateRepository.swift`, `sources/Projects/Domain/LearningProject/Contracts/GenerationProgressRepository.swift`, `sources/Projects/Domain/LearningProject/Models/LearningProject/RepositoryCreationState.swift`, `sources/Projects/Domain/LearningProject/Models/LearningProject/GenerationProgress.swift`를 제거한다
- [ ] T031 [S1] `sources/Projects/Domain/LearningProject/UseCases/TrackGenerationProgress/TrackGenerationProgressUseCase.swift`, `sources/Projects/Domain/LearningProject/UseCases/TrackGenerationProgress/TrackGenerationProgress.swift`, `sources/Projects/Domain/LearningProject/UseCases/ObserveGenerationOutcomes/ObserveGenerationOutcomesUseCase.swift`, `sources/Projects/Domain/LearningProject/UseCases/ObserveGenerationOutcomes/ObserveGenerationOutcomes.swift`를 제거한다
- [ ] T032 [S1] `sources/Projects/Domain/LearningProject/Models/LearningProject/GenerationWaitPolicy.swift`의 대기·만료 판정이 생성 기록을 받도록 바꾼다. 값은 변경하지 않는다
- [ ] T033 [S1] `sources/Projects/Domain/Tests/LearningProject/UseCases/TrackGenerationProgressTests.swift`와 `sources/Projects/Domain/Tests/LearningProject/UseCases/ObserveGenerationOutcomesTests.swift`를 제거하고, 각 보장 항목이 T020~T023 중 어디로 이관됐는지 대조표를 이 파일의 "보장 항목 대조표" 절에 기록한다

### 패키지 검증

- [ ] T034 [no-write] `DomainLearningProjectTests`를 실행해 U4를 검증한다

**진행 점검**: T020~T034의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 작업 패키지 5 (U5): Domain — 자격 증명 확인 도입과 인증 관측 제거

**목표**: 앱 활성 전환 시 1회 확인하는 자격 증명 확인 UseCase를 도입하고, 동작하지 않는 인증 결과 관측과 자격 증명 변경 관측 계약을 제거한다.

**소유 경로**: `sources/Projects/Domain/Authentication/**`, `sources/Projects/Domain/Tests/Authentication/**`

**관련 변경 시나리오**: S2

**독립 검증**: `DomainAuthenticationTests`가 통과하고, 재인증 필요일 때만 세션이 정리된다는 보장이 새 테스트로 존재한다.

### 테스트

- [ ] T035 [S2] `sources/Projects/Domain/Tests/Authentication/UseCases/VerifyAuthorizationTests.swift`에 세 가지 자격 증명 상태별 동작 테스트를 작성한다 — 재인증 필요 시 세션·자격 증명 정리, 인증됨 시 무변경, 일시적 확인 불가 시 무변경
- [ ] T036 [S2] `sources/Projects/Domain/Tests/Authentication/UseCases/VerifyAuthorizationTests.swift`에 세션 정리 실패가 반환 값을 바꾸지 않는다는 테스트를 추가한다

### 구현

- [ ] T037 [P] [S2] `sources/Projects/Domain/Authentication/UseCases/VerifyAuthorization/VerifyAuthorizationUseCase.swift`에 [contracts/README.md](./contracts/README.md) 1.2의 계약을 정의한다
- [ ] T038 [S2] `sources/Projects/Domain/Authentication/UseCases/VerifyAuthorization/VerifyAuthorization.swift`에 구현을 작성한다. 기존 `AuthenticationOutcomes`의 무효 세션 정리 절차를 재사용하되 세션 복원은 수행하지 않는다
- [ ] T039 [S2] `sources/Projects/Domain/Authentication/Contracts/AuthenticationRepository.swift`에서 `authorizationChanges()`를 제거한다
- [ ] T040 [S2] `sources/Projects/Domain/Authentication/UseCases/AuthenticationOutcomes/AuthenticationOutcomesUseCase.swift`, `sources/Projects/Domain/Authentication/UseCases/AuthenticationOutcomes/AuthenticationOutcomes.swift`와 인증 결과 값 타입을 제거한다
- [ ] T041 [S2] `sources/Projects/Domain/Tests/Authentication/UseCases/AuthenticationOutcomesTests.swift`와 `sources/Projects/Domain/Tests/Authentication/Contracts/AuthenticationRepositoryContractTests.swift`의 자격 증명 변경 관측 관련 검증을 제거하고, 각 보장 항목의 이관처를 이 파일의 "보장 항목 대조표" 절에 기록한다

### 패키지 검증

- [ ] T042 [no-write] `DomainAuthenticationTests`를 실행해 U5를 검증한다

**진행 점검**: T035~T042의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 통합 단위 1 (I1): Composition + Feature + App

**분리 불가 근거**: U1이 제거하는 Infrastructure 자격 증명 변경 전달과 U4·U5가 제거하는 Domain 공개 계약은 모두 Composition 조립, Feature 초기화 인자, App 주입을 동시에 컴파일 실패시킨다. Feature의 초기화 인자는 App이 채우고 그 값은 Composition이 만들므로 어느 한 패키지만 바꾼 중간 상태가 존재할 수 없다. 상세 근거는 [plan.md](./plan.md)에 있다.

**목표**: 제거된 계약의 사용처를 세 패키지에서 동시에 교체한다.

**소유 경로**: `sources/Projects/Composition/**`, `sources/Projects/Feature/**`, `sources/Projects/App/**`, `sources/Projects/Infrastructure/Authentication/AppleAuthentication/Providers/AppleCredentialStateProvider.swift`(T002)

**관련 변경 시나리오**: S1, S2, S3

**통합 검증**: 단위 검증만으로는 세 패키지의 연결을 확인할 수 없으므로 I1 완료 시점에 전체 `build`·`compile`·`test`를 실행한다.

### 구현 — Composition

- [ ] T043 [S1] `sources/Projects/Composition/Adapter/Adapters/GenerationStateRepositoryAdapter.swift`를 추가해 Domain 생성 상태 보존 계약을 Data 저장 구현에 연결한다
- [ ] T044 [S1] `sources/Projects/Composition/Adapter/Adapters/GenerationProgressRepositoryAdapter.swift`와 `sources/Projects/Composition/Adapter/Adapters/RepositoryCreationStateRepositoryAdapter.swift`를 제거한다
- [ ] T045 [S1] `sources/Projects/Composition/Adapter/Assemblies/LearningProjectAssembly.swift`가 생성 추적을 조립하고 `startObservingRepositoryCreationState`를 제거하도록 바꾼다
- [ ] T046 [S1] `sources/Projects/Composition/Adapter/Factories/GenerationCompletionReminderCoordinator.swift`가 생성 결과 관측 대신 생성 추적의 상태 관측을 사용하도록 바꾼다
- [ ] T047 [S1] `sources/Projects/Composition/Adapter/Assemblies/GenerationReminderAssembly.swift`의 관측 시작 주입을 생성 추적 기준으로 바꾼다
- [ ] T002 [S2] `sources/Projects/Infrastructure/Authentication/AppleAuthentication/Providers/AppleCredentialStateProvider.swift`에서 `changes()`, `receiveRevocation(for:)`, `continuations` 저장소를 제거한다. **T048과 같은 커밋 단위에 둔다** — 분리하면 Composition이 컴파일되지 않는다
- [ ] T048 [S2] `sources/Projects/Composition/Adapter/Adapters/AuthenticationRepositoryAdapter.swift`에서 `authorizationChanges()` 구현을 제거한다
- [ ] T049 [S2] `sources/Projects/Composition/Adapter/Assemblies/AuthenticationAssembly.swift`가 자격 증명 확인 UseCase를 조립하고 인증 결과 관측 조립을 제거하도록 바꾼다
- [ ] T050 [S1] [S2] [S3] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`의 노출 의존성을 교체한다 — 생성 추적 추가, 진행 정보 추적과 생성 결과 관측 제거, 자격 증명 확인 추가, 인증 결과 관측 제거, 토큰 갱신 통지의 재래핑 제거
- [ ] T051 [S1] `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`가 생성 추적을 사용하도록 바꾼다
- [ ] T052 [S1] [S2] `sources/Projects/Composition/Tests/`의 조립 테스트를 새 노출 의존성 기준으로 갱신한다

### 구현 — Feature

- [ ] T053 [S1] `sources/Projects/Feature/Home/HomeFeature.swift`가 생성 결과 관측 대신 생성 추적의 상태 관측을 사용하도록 바꾼다
- [ ] T054 [S1] `sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/QuizGenerationProgressFeature.swift`가 상태 관측을 사용하도록 바꾸고, 생성 요청 전에 미리 관측을 시작하던 순서 의존 코드를 제거한다
- [ ] T055 [S1] `sources/Projects/Feature/ProjectRegistration/Router/ProjectRegistrationRouterFeature.swift`의 초기화 인자와 하위 전달을 생성 추적 기준으로 바꾼다
- [ ] T056 [S1] `sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift`의 초기화 인자와 하위 전달을 생성 추적 기준으로 바꾼다
- [ ] T057 [S1] `sources/Projects/Feature/Tests/ProjectRegistration/QuizGenerationProgress/QuizGenerationProgressFeatureTests.swift`를 새 관측 기준으로 갱신하고, 늦은 관측에서도 완료를 받는다는 검증을 추가한다
- [ ] T058 [S1] `sources/Projects/Feature/Tests/ShareRegistration/TestDoubles/ShareRegistrationTestSupport.swift`의 테스트 더블을 새 계약에 맞춘다

### 구현 — App

- [ ] T059 [S1] [S2] [S3] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`의 초기화 인자를 교체한다 — 생성 추적 추가, 진행 정보 추적과 생성 결과 관측 제거, 자격 증명 확인 추가, 인증 결과 관측 제거, 토큰 갱신 통지의 기본값 제거
- [ ] T060 [S2] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`의 `applicationBecameActive` 처리에 자격 증명 확인을 추가하고, 인증 결과 관측 Effect와 해당 `CancelID`를 제거한다
- [ ] T061 [S1] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`의 생성 진행 복원·해제 Effect를 상태 관측 구독으로 바꾼다
- [ ] T062 [S1] [S2] [S3] `sources/Projects/App/GitIt/GitItApp.swift`의 주입을 새 노출 의존성에 맞춘다
- [ ] T063 [S1] [S2] `sources/Projects/App/GitIt/Screens/AppRootView.swift`의 프리뷰 대체 구현을 새 계약에 맞춘다
- [ ] T064 [S1] `sources/Projects/App/ShareExtension/ShareViewController.swift`가 새 조립 결과를 사용하도록 바꾼다
- [ ] T065 [S1] [S2] [S3] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`와 `sources/Projects/App/Tests/GitIt/TestDoubles/AppRootTestSupport.swift`를 새 계약 기준으로 갱신한다

### 통합 검증

- [ ] T066 [no-write] `make tuist`로 workspace를 갱신하고 실행 전후 Git 상태를 비교해 추적 파일 변경이 없는지 확인한다
- [ ] T067 [no-write] 전체 `build` → `compile` → `test`를 순차 실행하고 결과를 기록한다

**진행 점검**: T043~T067의 변경 파일과 검증 결과를 보고한다.

---

## 전체 완료 검증

**선행 조건**: I1의 파일 변경 작업을 모두 완료했다.

**커밋 경계**: 아래 `[no-write]` 작업은 I1의 마지막 커밋 단위에 배정한다.

- [ ] T068 [no-write] 전체 `build`·`compile`·`test`를 실행하고 결과를 기록한다
- [ ] T069 [no-write] [S1] [S2] [S3] [quickstart.md](./quickstart.md)의 시나리오별 검증 표를 모두 확인한다
- [ ] T070 [no-write] 이 파일의 "보장 항목 대조표"가 제거된 모든 테스트의 이관처 또는 제거 근거를 담고 있는지 확인한다

---

## 보장 항목 대조표

> T033과 T041에서 채운다. 제거한 테스트가 보장하던 항목을 왼쪽에, 그 보장을 이어받은 테스트를 오른쪽에 적는다. 이어받을 곳이 없으면 제거 근거를 적는다.

| 제거한 보장 | 이관처 또는 제거 근거 |
| --- | --- |
| (T033·T041에서 작성) | |

---

## 의존성과 실행 순서

### 실행 단위 순서와 위험 기반 승인

```text
U1 (Infrastructure) ─┐
U2 (Domain 추가)   ─┴─> U3 (Data) ─> U4 (Domain 교체) ─> U5 (Domain 인증) ─> I1 (Composition+Feature+App)
```

- U1과 U2는 서로 의존하지 않는다. tasks.md는 Infrastructure를 먼저 두는데, U1이 가장 작고 독립적이어서 초기 검증 비용이 낮기 때문이다.
- U3은 U2의 값 구조에 대응하는 저장 표현을 만들므로 U2 뒤에 온다.
- U4는 U2의 모델과 U3의 저장 구현이 모두 있어야 생성 추적을 조립할 수 있다.
- U5는 U4와 독립이지만 같은 Domain 패키지이므로 U4 뒤에 두어 Domain 검증을 한 번에 수렴시킨다.
- I1은 U4·U5가 제거한 계약의 사용처를 다루므로 마지막이다.

**승인이 필요한 지점**: 이 목록에는 없다. 새 범위, 파괴적 작업, 외부 상태 변경, 새 제품 결정을 요구하는 작업이 없다. 단 위 "명세 편차" 절의 FR-008 처리 방식은 T003 이전에 사용자에게 알린다.

### 변경 시나리오 추적성

| 시나리오 | 작업 |
| --- | --- |
| S1 구독 시점과 무관한 생성 상태 관측 | T006~T034, T043~T047, T050~T059, T061~T065 |
| S2 자격 증명 관측 경로 제거 | T001, T035~T042, T048~T050, T052, T059, T060, T062, T063, T065 (T002는 I1) |
| S3 기기 토큰 갱신 신호 정정 | T003, T004, T050, T059, T062, T065 |

각 시나리오의 독립 수용 기준은 [quickstart.md](./quickstart.md)의 시나리오별 검증 표가 소유한다.

### 실행 단위 내부 병렬 실행

- U1: T001·T003·T004는 서로 다른 파일이므로 병렬 가능하다.
- U2: T006·T007 병렬, T008·T010 병렬. T009는 T008에 의존한다.
- U3: T012·T014 병렬. T015~T018은 순차.
- U4: 병렬 없음. 같은 UseCase 폴더와 상호 의존 파일을 다룬다.
- U5: T037은 T035·T036과 병렬 가능하다.
- I1: Composition → Feature → App 순서를 유지한다. 같은 그룹 안에서도 `AppComposition.swift`와 `AppRootFeature.swift`는 다른 작업의 결과에 의존하므로 병렬하지 않는다.

## 구현 전략

최소 가치 범위는 **U1 + U5 + I1의 S2 작업**이다. 동작하지 않는 자격 증명 관측 경로가 사라지고 재인증 판정이 실제로 동작하게 되며, 생성 상태 통합과 독립적으로 검증할 수 있다. 다만 T002가 I1에 있으므로 S2만 먼저 완료하려면 I1을 시나리오별로 쪼개야 한다. 다만 이 명세의 핵심 가치인 S1은 U2~U4와 I1을 모두 완료해야 얻어진다.

## 참고

- 근거 문서: [docs/review/async-stream-redesign-requirements.md](../../docs/review/async-stream-redesign-requirements.md)
- 후속 명세: Composition 책임 정리가 T046의 리마인드 정책 이동을 이어받는다
