---

description: "공유 확장에서 진행 중인 생성이 있으면 새 생성 요청 차단 — 작업 목록"
---

# 작업 목록: 공유 확장에서 진행 중인 생성이 있으면 새 생성 요청 차단

**입력**: `specs/047-share-generation-guard/`의 설계 문서

**선행 조건**: plan.md, spec.md, research.md, data-model.md, contracts/generation-state-read.md, quickstart.md

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를
snapshot한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만
선택한다.

**테스트**: 명세의 독립 테스트와 성공 기준(SC-001~SC-005)이 자동 테스트 검증을 요구하므로 테스트 작업을 포함한다.
Swift Testing(`@Suite`, `@Test`)과 한국어 동작 문장 테스트 이름을 쓰고, Test Double은 initializer로 주입한다
([테스트 컨벤션](../../docs/conventions/test.md)). 프로토콜 요구사항·새 타입을 참조하는 테스트는 구현 전에 작성하면
컴파일 실패가 Red 상태다.

**구성**: plan.md "실행 단위"의 순서(배치 이동 → Data → Domain → Composition → Feature → App)와 integration unit 구분을
그대로 따른다. 변경 시나리오는 각 단위 안의 `[S1]`, `[S2]` 라벨로 추적한다.

**경로 기준**: 모든 소스 경로는 저장소 루트 기준이며 `sources/Projects/` 아래에 있다. 실행 단위 0 이후 공유 확장 흐름의
소스는 `sources/Projects/Feature/ShareRegistration/ShareRegistration/`, 테스트는
`sources/Projects/Feature/Tests/ShareRegistration/ShareRegistration/`에 있다([research R9](./research.md#r9-공유-확장-흐름-배치-정리-fr-012-명확화-2026-09-29)).

**검증 명령**: 저장소 루트에서 다음으로 실행기를 판독한 뒤 사용한다. 세 명령은 `sources/DerivedData/PreCommit`을
공유하므로 순차 실행한다.

```sh
project_build_runner=$(./.tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
```

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[S1]**: 시나리오 1 — 생성이 진행 중이면 공유로 새 생성을 시작할 수 없다(P1)
- **[S2]**: 시나리오 2 — 공유 확장이 앱과 같은 기준으로 생성 진행 여부를 판정한다(P2)
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 실행 또는 수동 검증.
  `make tuist`의 파생 workspace·project·심볼릭 링크·cache 갱신은 허용하되 실행 전후 `git status --porcelain`을
  비교하고 추적 파일 변경이 생기면 완료로 처리하지 않는다.
- 적합 타입 목록은 각 단위 시작 시 `: KeyValueStorage`, `: PendingGenerationRepository`, `: ProjectGenerationUseCase`,
  `ShareRegistrationDiagnosticEvent`, `SharedRepositoryRegistrationFeature(` 검색으로 다시 확인한다. 이 문서
  작성 시점(2026-09-29) 검색 결과와 목록이 다르면 누락 파일을 해당 단위에 추가하기 전에 중단하고 보고한다.

## 실행 단위 소유권 규칙

- 패키지 소스·테스트는 그 패키지를 포함한 실행 단위가 소유한다. 새 target·manifest 변경은 없다.
- 공개 이름은 [research R7](./research.md#r7-새-공개-이름)에서 확정한 이름만 사용한다.
- 실행 단위 0은 파일 위치만 바꾼다. 같은 단위에서 파일 내용을 수정하지 않는다.
- `docs/spec-kit/047-share-generation-guard/trouble-shooting.md`와 `tacit-knowledge.md`는 작업으로 만들지 않는다.

---

## 실행 단위 0: 공유 확장 흐름 배치 정리 (단일 패키지: Feature)

**목표**: `ShareRegistration` 흐름의 소스와 테스트를 동작 변경 없이 [Feature 흐름 배치](../../docs/conventions/directory-file/feature-layout.md)를
따르는 화면 폴더로 옮긴다(FR-012).

**소유 경로**: 아래 T001·T002에 적힌 이동 전·후 경로

**관련 변경 시나리오**: FR-012(시나리오 공통 기반)

**독립 검증**: `"$project_build_runner" compile`

### 구현

- [X] T001 `git mv`로 공유 확장 소스 8개를 화면 폴더로 옮긴다. 파일 내용은 바꾸지 않는다:
  `sources/Projects/Feature/ShareRegistration/ShareRegistrationScreen.swift` → `sources/Projects/Feature/ShareRegistration/ShareRegistration/ShareRegistrationScreen.swift`,
  `sources/Projects/Feature/ShareRegistration/ShareRegistrationFeature.swift` → `sources/Projects/Feature/ShareRegistration/ShareRegistration/ShareRegistrationFeature.swift`,
  `sources/Projects/Feature/ShareRegistration/SharedRepositoryRegistrationFeature.swift` → `sources/Projects/Feature/ShareRegistration/ShareRegistration/SharedRepositoryRegistrationFeature.swift`,
  `sources/Projects/Feature/ShareRegistration/ShareRegistrationDiagnosticEvent.swift` → `sources/Projects/Feature/ShareRegistration/ShareRegistration/ShareRegistrationDiagnosticEvent.swift`,
  `sources/Projects/Feature/ShareRegistration/SubViews/ShareRegistrationScreen+GuidanceView.swift` → `sources/Projects/Feature/ShareRegistration/ShareRegistration/SubViews/ShareRegistrationScreen+GuidanceView.swift`,
  `sources/Projects/Feature/ShareRegistration/SubViews/ShareRegistrationScreen+LoadingView.swift` → `sources/Projects/Feature/ShareRegistration/ShareRegistration/SubViews/ShareRegistrationScreen+LoadingView.swift`,
  `sources/Projects/Feature/ShareRegistration/Previews/ShareRegistrationScreenPreviews.swift` → `sources/Projects/Feature/ShareRegistration/ShareRegistration/Previews/ShareRegistrationScreenPreviews.swift`,
  `sources/Projects/Feature/ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift` → `sources/Projects/Feature/ShareRegistration/ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift`
- [X] T002 `git mv`로 공유 확장 테스트 7개를 같은 축으로 옮긴다. 파일 내용은 바꾸지 않는다:
  `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistrationFeatureFailureTests.swift` → `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistration/ShareRegistrationFeatureFailureTests.swift`,
  `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistrationFeatureStepTests.swift` → `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistration/ShareRegistrationFeatureStepTests.swift`,
  `sources/Projects/Feature/Tests/ShareRegistration/SharedRepositoryRegistrationFeatureTests.swift` → `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistration/SharedRepositoryRegistrationFeatureTests.swift`,
  `sources/Projects/Feature/Tests/ShareRegistration/TestDoubles/ExternalRepositoryUseCaseFixedResultStub.swift` → `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistration/TestDoubles/ExternalRepositoryUseCaseFixedResultStub.swift`,
  `sources/Projects/Feature/Tests/ShareRegistration/TestDoubles/ProjectGenerationUseCaseSpy.swift` → `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistration/TestDoubles/ProjectGenerationUseCaseSpy.swift`,
  `sources/Projects/Feature/Tests/ShareRegistration/TestDoubles/ShareRegistrationTestSupport.swift` → `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistration/TestDoubles/ShareRegistrationTestSupport.swift`,
  `sources/Projects/Feature/Tests/ShareRegistration/TestDoubles/StubRepositoryURLParser.swift` → `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistration/TestDoubles/StubRepositoryURLParser.swift`

### 정리와 단위 검증

- [X] T003 [no-write] `git status --porcelain`으로 T001·T002 변경이 이름 변경(`R`)만인지 확인한다. `sources/Projects/Feature/ShareRegistration/`와
  `sources/Projects/Feature/Tests/ShareRegistration/` 1뎁스에는 `ShareRegistration/` 폴더만 남아야 한다(추적되지 않는 `.DS_Store` 제외).
  이후 `make tuist`로 파생 project를 갱신하고 `"$project_build_runner" compile`이 통과하는지 확인한다

**진행 점검**: T001~T003의 이동 목록과 검증 결과를 보고하고 실행 단위 1로 진행한다.

---

## 실행 단위 1: 저장소 판독 실패 전달 (integration unit: Data, Composition 테스트)

**목표**: 공유 저장 계약이 "값 없음"과 "판독 실패(저장소 없음·해석 불가)"를 구분하고, 생성 기록 저장소가 그 실패를 전파한다.

**분리 불가 근거**: `KeyValueStorage`에 `verifiedValue` 요구사항을 추가하면 Data 테스트 target 3개와 Composition 테스트
target 3개의 `InMemoryKeyValueStorage`가 같은 커밋에서 새 연산을 구현해야 compile된다(research R3: 프로토콜 extension
기본 구현 기각).

**소유 경로**: `sources/Projects/Data/Shared/**`의 아래 명시 파일, `sources/Projects/Data/LearningProject/Stores/LocalPendingGenerationStore.swift`,
`sources/Projects/Data/Tests/**`와 `sources/Projects/Composition/Tests/**`의 아래 명시 파일

**관련 변경 시나리오**: S1(FR-003a 확인 실패)

**통합 검증**: `"$project_build_runner" compile`

### 테스트

- [X] T004 [P] [S1] `sources/Projects/Data/Tests/Shared/Stores/LocalKeyValueStorageTests.swift`에 `LocalKeyValueStorage.verifiedValue(_:forKey:)`가 값이 없으면 `nil`, 저장된 값을 요청 형식으로 해석할 수 없으면 `KeyValueStorageError.unreadable`을 던지고, 정상 값은 그대로 돌려주는 테스트를 추가한다
- [X] T005 [P] [S1] `sources/Projects/Data/Tests/Shared/Factories/StorageFactoryTests.swift`에 저장소를 만들 수 없을 때 받은 `UnavailableKeyValueStorage`의 `verifiedValue`가 `KeyValueStorageError.unavailable`을 던지고 기존 `value`는 `nil`을 유지하는 테스트를 추가한다
- [X] T006 [P] [S1] `sources/Projects/Data/Tests/LearningProject/Stores/LocalPendingGenerationStoreTests.swift`에 `LocalPendingGenerationStore.verifiedState()`가 기록이 없으면 빈 `GenerationStateDTO`를, 기록이 있으면 저장된 값을 돌려주고 저장소의 `KeyValueStorageError`를 그대로 전파하는 테스트를 추가한다

### 구현

- [X] T007 [S1] `sources/Projects/Data/Shared/Errors/KeyValueStorageError.swift`를 신규 작성해 `public enum KeyValueStorageError: Error, Equatable, Sendable { case unavailable, unreadable }`를 정의한다(키 기반 값 저장소를 읽을 수 없는 이유)
- [X] T008 [S1] `sources/Projects/Data/Shared/Contracts/KeyValueStorage.swift`에 `func verifiedValue<Value: Codable & Sendable>(_ type: Value.Type, forKey key: String) async throws(KeyValueStorageError) -> Value?` 요구사항을 추가한다. 기존 `value(_:forKey:)`는 바꾸지 않는다
- [X] T009 [P] [S1] `sources/Projects/Data/Shared/Stores/LocalKeyValueStorage.swift`에 `verifiedValue`를 구현한다(값 없음 `nil`, 디코딩 실패 `unreadable`)
- [X] T010 [P] [S1] `sources/Projects/Data/Shared/Stores/UnavailableKeyValueStorage.swift`에 항상 `unavailable`을 던지는 `verifiedValue`를 구현한다
- [X] T011 [S1] `sources/Projects/Data/LearningProject/Stores/LocalPendingGenerationStore.swift`에 `public func verifiedState() async throws(KeyValueStorageError) -> GenerationStateDTO`를 추가한다. 다른 연산과 같은 직렬 실행(`exclusively`) 안에서 `verifiedValue`로 읽고, 값이 없으면 빈 상태를 돌려준다
- [X] T012 [P] [S1] `sources/Projects/Data/Tests/Authentication/TestDoubles/InMemoryKeyValueStorage.swift`에 `verifiedValue`를 구현한다
- [X] T013 [P] [S1] `sources/Projects/Data/Tests/LegalConsent/TestDoubles/InMemoryKeyValueStorage.swift`에 `verifiedValue`를 구현한다
- [X] T014 [P] [S1] `sources/Projects/Data/Tests/LearningProject/TestDoubles/InMemoryKeyValueStorage.swift`에 `verifiedValue`를 구현하고, T006의 오류 전파 검증을 위해 initializer로 판독 실패를 설정할 수 있게 한다
- [X] T015 [P] [S1] `sources/Projects/Composition/Tests/Authentication/TestDoubles/InMemoryKeyValueStorage.swift`에 `verifiedValue`를 구현한다
- [X] T016 [P] [S1] `sources/Projects/Composition/Tests/ShareExtension/TestDoubles/InMemoryKeyValueStorage.swift`에 `verifiedValue`를 구현한다
- [X] T017 [P] [S1] `sources/Projects/Composition/Tests/LearningProject/TestDoubles/InMemoryKeyValueStorage.swift`에 `verifiedValue`를 구현하고, 실행 단위 2의 Adapter 오류 변환 검증을 위해 initializer로 판독 실패(`unavailable`, `unreadable`)를 설정할 수 있게 한다

### 정리와 단위 검증

- [X] T018 [no-write] `"$project_build_runner" compile`로 Data·Composition 테스트 target을 포함한 build-for-testing이 통과하는지 확인한다

**진행 점검**: T004~T018의 변경 파일과 검증 결과를 보고하고 실행 단위 2로 진행한다.

---

## 실행 단위 2: 생성 상태 일회 조회 (integration unit: Domain, Composition, Feature 테스트, App)

**목표**: "생성 중" 판정 규칙을 `ProjectGenerationState.hasRequestInProgress` 한 곳에 두고, 관찰 없이 현재 생성 상태를 한 번 읽는
`ProjectGenerationUseCase.currentState()`와 Adapter가 Data 오류를 `ProjectGenerationError.stateUnavailable`로 바꿔 전달하는 경로를 만든다.

**분리 불가 근거**: `PendingGenerationRepository.confirmedPendingState()`와 `ProjectGenerationUseCase.currentState()` 요구사항을 추가하면
Composition Adapter, Domain 테스트 더블, Feature 테스트 더블 2개, App 테스트 더블과 App 프리뷰 `NoopProjectGeneration`이 같은
커밋에서 새 연산을 구현해야 compile된다.

**소유 경로**: `sources/Projects/Domain/ProjectGeneration/**`, `sources/Projects/Domain/Tests/ProjectGeneration/**`,
`sources/Projects/Composition/LearningProject/Adapters/PendingGenerationRepositoryAdapter.swift`, 아래 명시한 Composition·Feature·App 파일

**관련 변경 시나리오**: S1(FR-003a), S2(FR-008, FR-011, SC-004)

**통합 검증**: `"$project_build_runner" compile`

### 테스트

- [X] T019 [P] [S2] `sources/Projects/Domain/Tests/ProjectGeneration/Models/ProjectGenerationStateTests.swift`를 신규 작성해 `hasRequestInProgress`가 진행 중 요청이 하나라도 있으면 참이고, 완료만·실패만·빈 요청 목록이면 거짓이며, 프로젝트 식별자가 없는 진행 중 요청도 참인지 검증한다
- [X] T020 [P] [S1] `sources/Projects/Domain/Tests/ProjectGeneration/UseCases/ProjectGenerationTests.swift`에 `currentState()`가 `states()`와 같은 투영(보관 기한 경과 기록 제외, 기록 상태→단계 변환)을 돌려주고, 결과·로그아웃·저장소 변경 관찰과 만료 타이머를 시작하지 않으며, 저장소 계약이 던진 `ProjectGenerationError.stateUnavailable`을 그대로 전달하고 그 밖의 오류도 `stateUnavailable`로 보는 테스트를 추가한다
- [X] T021 [P] [S1] `sources/Projects/Composition/Tests/LearningProject/Adapters/PendingGenerationRepositoryAdapterTests.swift`에 `confirmedPendingState()`가 저장된 기록을 Domain `GenerationState`로 바꾸며 `pendingState()`와 같은 보관 기한 정리를 적용하고, 저장소 판독 실패(`unavailable`, `unreadable`) 각각을 `ProjectGenerationError.stateUnavailable`로 바꿔 던지는 테스트를 추가한다

### 구현

- [X] T022 [S2] `sources/Projects/Domain/ProjectGeneration/Models/ProjectGenerationState.swift`에 계산 프로퍼티 `public var hasRequestInProgress: Bool`(요청 중 `.inProgress` 단계가 하나라도 있으면 참)을 추가한다. 이 프로퍼티가 "생성 중" 판정 규칙의 유일한 정의다
- [X] T023 [P] [S1] `sources/Projects/Domain/ProjectGeneration/Errors/ProjectGenerationError.swift`에 `case stateUnavailable`(생성 상태를 확인할 수 없음)을 추가한다
- [X] T024 [P] [S1] `sources/Projects/Domain/ProjectGeneration/Contracts/PendingGenerationRepository.swift`에 `func confirmedPendingState() async throws -> GenerationState` 요구사항을 추가한다(기존 계약과 같은 untyped `throws`, 던지는 오류는 `ProjectGenerationError`)
- [X] T025 [S1] `sources/Projects/Domain/ProjectGeneration/UseCases/ProjectGenerationUseCase.swift`에 `func currentState() async throws(ProjectGenerationError) -> ProjectGenerationState` 요구사항을 추가한다
- [X] T026 [S1] `sources/Projects/Domain/ProjectGeneration/UseCases/ProjectGeneration.swift`에 `currentState()`를 구현한다. `confirmedPendingState()`로 한 번 읽어 `states()`와 같은 투영 규칙으로 변환하고(actor 저장 상태가 아닌 읽은 값을 입력으로 받는 투영 함수를 두 연산이 공유), actor 상태 변경·관찰 시작 없이 `ProjectGenerationError`는 그대로, 그 밖의 오류는 `stateUnavailable`로 던진다
- [X] T027 [S1] `sources/Projects/Domain/Tests/ProjectGeneration/TestDoubles/InMemoryPendingGenerationRepository.swift`에 `confirmedPendingState()`를 구현하고 initializer로 판독 실패(던질 오류)를 설정할 수 있게 한다
- [X] T028 [S1] `sources/Projects/Composition/LearningProject/Adapters/PendingGenerationRepositoryAdapter.swift`에 `confirmedPendingState()`를 구현한다. `store.verifiedState()`를 Domain `GenerationState`로 바꾸고 `pendingState()`와 같은 `purged` 정리를 적용하며, `KeyValueStorageError`의 모든 사례를 `ProjectGenerationError.stateUnavailable`로 바꿔 던진다. Data 오류 타입을 Domain 계약 밖으로 내보내지 않고 비즈니스 판정은 두지 않는다
- [X] T029 [P] `sources/Projects/Feature/Tests/ProjectRegistration/TestDoubles/ProjectGenerationUseCaseStub.swift`에 `currentState()`를 구현한다
- [X] T030 [P] `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistration/TestDoubles/ProjectGenerationUseCaseSpy.swift`에 `currentState()`를 구현한다(기본값은 진행 중 요청이 없는 빈 상태)
- [X] T031 [P] `sources/Projects/App/GitIt/Screens/AppRootView.swift`의 프리뷰 전용 `NoopProjectGeneration`에 `currentState()`를 구현한다(빈 상태 반환)
- [X] T032 [P] `sources/Projects/App/Tests/GitIt/TestDoubles/ProjectGenerationUseCaseMock.swift`에 `currentState()`를 구현한다

### 정리와 단위 검증

- [X] T033 [no-write] `"$project_build_runner" compile`로 Domain·Composition·Feature·App 테스트 target을 포함한 build-for-testing이 통과하는지 확인한다

**진행 점검**: T019~T033의 변경 파일과 검증 결과를 보고하고 실행 단위 3으로 진행한다.

---

## 실행 단위 3: 공유 확장 생성 판정 (integration unit: Feature, App)

**목표**: 하위 등록 Feature가 UseCase 전체 대신 쓰는 동작 클로저 3개만 받고, 저장소 조회 전과 등록 요청 직전에 생성 진행 여부를
판정해 생성 중이면 생성 중 안내(닫기만), 확인 실패면 확인 실패 안내(재시도·닫기)로 전환하며 조회·등록 요청을 보내지 않는다.

**분리 불가 근거**: `ShareRegistrationDiagnosticEvent`에 사례를 추가하면 App `ShareRegistrationDiagnosticLog`의 exhaustive switch가
같은 커밋에서 새 사례를 처리해야 compile된다.

**소유 경로**: `sources/Projects/Feature/ShareRegistration/ShareRegistration/**`의 아래 명시 파일, `sources/Projects/Feature/Shared/Localization/Localizable.xcstrings`,
`sources/Projects/Feature/Shared/Localization/LocalizedText+ShareRegistration.swift`, `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistration/**`의 아래 명시 파일,
`sources/Projects/App/ShareExtension/ShareRegistrationDiagnosticLog.swift`

**관련 변경 시나리오**: S1(FR-001~FR-007), S2(FR-009, SC-004)

**통합 검증**: `"$project_build_runner" compile`

### 준비

- [X] T034 [no-write] [S1] `.agents/skills/implement-figma-ui`의 [Figma 노드 인덱스](../../.agents/skills/implement-figma-ui/references/figma-index.md)에서 공유 확장 생성 중·확인 실패 안내 노드 유무를 확인한다. 노드가 없으면 기존 `GuidanceView` 구성(제목·설명·닫기)을 그대로 쓰고, 노드가 있으면 그 노드 값을 T044·T045에 적용한다

### 테스트

- [X] T035 [S1] `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistration/TestDoubles/ProjectGenerationUseCaseSpy.swift`를 확장해 루트 Feature 테스트가 `currentState()`의 호출 순서별 결과(상태 또는 오류)를 initializer 기본값 인자로 설정하고 호출 횟수를 확인할 수 있게 한다. 기존 호출 지점은 바꾸지 않는다
- [X] T036 [S2] `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistration/SharedRepositoryRegistrationFeatureTests.swift`의 테스트 지원 함수(`makeStore`)가 `lookUpRepository`·`requestGeneration`·`currentGenerationState` 클로저 대역을 주입하도록 바꾸고(조회·요청 호출은 기존처럼 기록해 검증), `currentGenerationState` 대역이 진행 중 요청 있음을 돌려주면 `generationInProgress`, 완료(`.ready`)만·실패만·빈 상태면 기존 조회 흐름, 오류를 던지면 `generationUnverified(retry: .lookup)`로 분기하는지 검증한다(SC-004 공유 확장 쪽, 시나리오 2 수용 3)
- [X] T037 [S1] `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistration/SharedRepositoryRegistrationFeatureTests.swift`에 같은 저장소의 진행 중 기록도 `generationInProgress`인지, 등록 직전 조회가 생성 중이면 `generationInProgress`, 오류면 `generationUnverified(retry: .registration)`인지, 차단 결과가 기존 `effect(.validationFinished(_:))`로 수신되는지, 각 차단 경우 저장소 조회·등록 요청이 0회인지, URL 오류·로그인 필요·앱 실행 필요 상태에서는 상태를 조회하지 않는지, 조회 실패 후 재시도와 `generationUnverified` 재시도가 상태 조회부터 다시 하는지, 차단 사유별 진단 사례(`generationInProgressBlocked`, `generationStateUnverified`)가 기록되는지 검증하는 테스트를 추가한다
- [X] T038 [P] [S1] `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistration/ShareRegistrationFeatureFailureTests.swift`에 루트 `ShareRegistrationFeature`가 주입받은 `projectGeneration.currentState()`로 판정하고, `canRetry`가 `generationUnverified`에서 참·`generationInProgress`에서 거짓이며, `generationUnverified`에서 재시도하면 상태 조회부터 다시 수행되는지 검증하는 테스트를 추가한다

### 구현

- [X] T039 [P] [S1] `sources/Projects/Feature/ShareRegistration/ShareRegistration/ShareRegistrationDiagnosticEvent.swift`에 `generationInProgressBlocked`, `generationStateUnverified` 사례를 추가한다
- [X] T040 [P] [S1] `sources/Projects/Feature/Shared/Localization/Localizable.xcstrings`에 `ShareRegistration.GenerationInProgress.title`, `ShareRegistration.GenerationInProgress.message`(본 앱의 "문제 생성 중"과 같은 의미 + 앱을 열면 최신 생성 상태가 반영된다는 복구 안내, 앱 실행 동작 없음), `ShareRegistration.GenerationUnverified.title`, `ShareRegistration.GenerationUnverified.reason`(생성 상태를 확인하지 못함) 키 4개를 기존 공유 확장 키와 같은 원본 언어·상태로 추가한다
- [X] T041 [S1] `sources/Projects/Feature/Shared/Localization/LocalizedText+ShareRegistration.swift`에 `LocalizedText.ShareRegistration.GenerationInProgress`(`title`, `message`)와 `GenerationUnverified`(`title`, `reason`)를 추가해 T040 키를 조회한다
- [X] T042 [S1] `sources/Projects/Feature/ShareRegistration/ShareRegistration/SharedRepositoryRegistrationFeature.swift`의 `init`에서 `externalRepository`·`projectGeneration` 인자와 프로퍼티를 제거하고 `lookUpRepository: @escaping @Sendable (ExternalRepositoryURL) async throws -> ExternalRepository`, `requestGeneration: @escaping @Sendable (ProjectGenerationRequest) async throws -> ProjectGenerationReceipt`, `currentGenerationState: @escaping @Sendable () async throws -> ProjectGenerationState`(모두 기본값 없음, private 불변 프로퍼티로 보존)를 받게 한다. `State.Phase`에 `generationInProgress`, `generationUnverified(retry: RetryTarget)`를 추가하고, 기존 `validate`·`submit` Effect 안에서 로그인 판정 뒤 상태를 조회해 `hasRequestInProgress`가 참이면 `generationInProgress`, 오류면 `generationUnverified`를 기존 `effect(.validationFinished(_:))`로 보내고, 그 밖에는 `lookUpRepository` 또는 `requestGeneration`으로 진행한다. `retry`가 `generationUnverified`에서도 대상(`lookup`→검증 흐름, `registration`→등록 흐름)을 상태 조회부터 다시 실행하며, 차단 시 새 진단 사례를 기록하게 한다. 새 Action case, 판정 전용 타입, 별도 판정 규칙을 두지 않고 Effect 취소 ID는 기존 `validation`·`registration`을 쓴다
- [X] T043 [S1] `sources/Projects/Feature/ShareRegistration/ShareRegistration/ShareRegistrationFeature.swift`에서 공개 initializer를 유지한 채 주입받은 UseCase로 `{ try await externalRepository.repository(at: $0) }`, `{ try await projectGeneration.request($0) }`, `{ try await projectGeneration.currentState() }`를 만들어 `SharedRepositoryRegistrationFeature`의 세 클로저로 전달하고, `canRetry`가 `generationUnverified`에서 참·`generationInProgress`에서 거짓이 되게 한다
- [X] T044 [S1] `sources/Projects/Feature/ShareRegistration/ShareRegistration/ShareRegistrationScreen.swift`의 `registration.phase` switch에 두 상태를 추가해 기존 `GuidanceView`로 `LocalizedText.ShareRegistration.GenerationInProgress`(닫기만)와 `GenerationUnverified`(재시도·닫기)를 표시한다
- [X] T045 [P] [S1] `sources/Projects/Feature/ShareRegistration/ShareRegistration/Previews/ShareRegistrationScreenPreviews.swift`에 `generationInProgress`, `generationUnverified` 상태 프리뷰를 추가한다
- [X] T046 [P] [S1] `sources/Projects/App/ShareExtension/ShareRegistrationDiagnosticLog.swift`의 진단 사례 switch에 두 새 사례를 기존 로컬 진단 로그 방식으로 기록하도록 추가한다. 토큰·개인정보·저장소 URL은 기록하지 않는다

### 정리와 단위 검증

- [X] T047 [no-write] `"$project_build_runner" compile`로 Feature·App 테스트 target을 포함한 build-for-testing이 통과하는지 확인하고, `git status --porcelain`으로 `sources/Projects/Feature/ShareRegistration/`에 새 파일이 추가되지 않았는지와 `SharedRepositoryRegistrationFeature.swift`에 `ExternalRepositoryUseCase`·`ProjectGenerationUseCase` 참조가 남지 않았는지 확인한다

**진행 점검**: T034~T047의 변경 파일과 검증 결과를 보고하고 실행 단위 4로 진행한다.

---

## 실행 단위 4: 앱 홈 잠금 판정 규칙 통일 (단일 패키지: App)

**목표**: 앱 홈 잠금이 Domain `hasRequestInProgress`를 사용해 공유 확장과 같은 규칙 정의를 공유한다. 판정 결과는 바뀌지 않는다(FR-010).

**소유 경로**: `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`, `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`

**관련 변경 시나리오**: S2(FR-010, FR-011, SC-004)

**독립 검증**: `"$project_build_runner" compile`

### 테스트

- [ ] T048 [S2] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`에 진행 중 요청 있음·완료(`.ready`)만·실패만·요청 없음 생성 상태에서 홈 잠금 여부가 그 상태의 `hasRequestInProgress`와 같은지(T036과 같은 입력 집합) 검증하는 테스트를 추가한다. 기존 홈 잠금 테스트는 그대로 통과해야 한다

### 구현

- [ ] T049 [S2] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`의 `applyGenerationState`가 `requests`의 `.inProgress` 직접 검사 대신 `ProjectGenerationState.hasRequestInProgress`를 쓰게 바꾼다

### 정리와 단위 검증

- [ ] T050 [no-write] `"$project_build_runner" compile`로 App 테스트 target을 포함한 build-for-testing이 통과하는지 확인한다

**진행 점검**: T048~T050의 변경 파일과 검증 결과를 보고하고 전체 완료 검증으로 진행한다.

---

## 전체 완료 검증

**선행 조건**: 실행 단위 4의 파일 변경 작업을 완료하고, 전체 검증과 hook 결과를 포함할 마지막 커밋 단위를 아직 commit하지 않은 상태여야 한다.

**커밋 경계**: 아래 `[no-write]` 작업은 실행 단위 4의 마지막 커밋 단위에 배정한다. 모든 검증과 필수 `after_implement` hook
(`speckit.swift-format.run`)을 마친 뒤 그 단위를 최종 commit한다. 이미 파일 변경 단위가 모두 commit된 단순 재개에서는
`tasks.md` 완료 표시를 위한 별도 최종 검증 단위를 둔다.

- [ ] T051 [no-write] `"$project_build_runner" build`, `"$project_build_runner" compile`, `"$project_build_runner" test`를 순서대로 실행하고, 기존 공유 확장·생성 요청·앱 루트 테스트를 포함한 결과를 기록한다(SC-001~SC-005, FR-012)
- [ ] T052 [no-write] [S2] `sources/Projects`에서 `.inProgress`와 `hasRequestInProgress`를 검색해 요청 목록 전체의 진행 중 존재 판정이 `ProjectGenerationState.hasRequestInProgress` 한 곳에만 정의되고 `AppRootFeature`와 `SharedRepositoryRegistrationFeature`가 그 프로퍼티만 쓰는지 확인한다. [research R8](./research.md#r8-테스트-설계)에 따라 단일 요청 단계 분기(`QuizGenerationProgressFeature`), 기록 상태↔단계 매핑(`PendingGenerationRepositoryAdapter`, `ProjectGeneration.phase(of:)`), 같은 저장소 중복 검사(`GenerationState`)는 판정 규칙 정의에서 제외한다(SC-004, FR-009, FR-011)
- [ ] T053 [no-write] [S1] 개발 빌드를 설치한 실기기에서 [quickstart.md](./quickstart.md) "3. 실기기 검증" 1~5단계와 Console.app의 `generationInProgressBlocked` 진단 로그를 확인한다(SC-006). 실기기를 쓸 수 없으면 미검증으로 기록하고, 확인 실패 안내(`generationUnverified`)는 자동 테스트로만 검증했다는 사실과 함께 PR 미검증 범위에 적는다
- [ ] T054 [no-write] 실행 전후 `git status --porcelain`을 비교해 검증 작업이 추적 파일을 바꾸지 않았는지 확인한다

## 의존성과 실행 순서

### 실행 단위 순서와 위험 기반 승인

- 채택 순서: 실행 단위 0(Feature 배치 이동) → 1(Data) → 2(Domain·Composition) → 3(Feature) → 4(App) → 전체 완료 검증.
  근거: [아키텍처 문서](../../docs/architecture.md)의 위상 순서 Infrastructure → Data → Domain → Composition → Feature → App.
  단위 0은 단위 1·2와 빌드 의존이 없으므로 위상 순서를 깨지 않으며, 단위 2·3이 이동 후 경로만 참조하도록 기능 변경보다 먼저 둔다
  ([research R9](./research.md#r9-공유-확장-흐름-배치-정리-fr-012-명확화-2026-09-29)). 단위 2의 Composition Adapter는 단위 1의
  `LocalPendingGenerationStore.verifiedState()`를, 단위 3은 단위 2의 `currentState()`·`hasRequestInProgress`를, 단위 4는 단위 2의
  `hasRequestInProgress`를 사용한다.
- 단위 4는 단위 3에 빌드 의존하지 않지만 T048이 T036과 같은 입력 집합으로 결론 일치를 검증하므로 단위 3 뒤에 둔다.
- 각 단위의 변경 파일과 검증 결과를 보고하되 같은 기능 범위에서는 반복 승인을 요구하지 않는다.
- 승인이 필요한 경우: 적합 타입·exhaustive switch·생성 지점 검색 결과가 이 문서 목록과 달라 새 파일이 필요할 때, Figma에 공유 확장 전용
  노드가 있어 기존 `GuidanceView` 구성과 다른 레이아웃이 필요할 때, 기존 `value(_:forKey:)` 동작 변경이 필요해질 때, 실행 단위 0에서
  파일 내용 수정이 필요해질 때, `ShareRegistration` 화면 폴더에 새 파일이 필요해질 때.

### 변경 시나리오 추적성

| 요구사항 | 작업 |
|---|---|
| FR-001 조회 전 판정 | T036, T037, T042, T043 |
| FR-002 생성 중 안내·닫기만 | T036~T038, T042~T044 |
| FR-003 등록 직전 재판정 | T037, T042 |
| FR-003a 확인 실패·재시도 | T004~T017, T020, T021, T023~T028, T036~T038, T042~T044 |
| FR-004 URL 미보관 | T037(차단 시 등록 요청 0회), T042 |
| FR-005 기존 흐름 유지 | T036(생성 중 아님 경로), T051 |
| FR-006 문구·복구 안내 | T040, T041, T044, T045 |
| FR-007 진단 로그 | T037, T039, T042, T046 |
| FR-008 새 Domain 상태 모델 없음 | T022(기존 모델 계산 프로퍼티), T052 |
| FR-009 Feature 단순 경계·클로저 3개 | T036, T042, T043, T047, T052 |
| FR-010 홈 잠금·저장 규칙·API 불변 | T008(기존 `value` 유지), T048, T049, T051 |
| FR-011 같은 UseCase·규칙 한 곳 | T019, T022, T025, T026, T049, T052 |
| FR-012 흐름 배치 정리 | T001~T003, T051 |
| SC-006 실기기 | T053 |

- 시나리오 1(S1)과 시나리오 2(S2)는 실행 단위 0~4가 모두 완료된 뒤 T051~T053으로 독립 수용 기준을 검증한다.

### 실행 단위 내부 실행

- 테스트 작업을 같은 단위의 구현 전에 작성하고 컴파일 실패 또는 기대한 단언 실패로 Red를 확인한다.
- 단위 0: T001 → T002 → T003.
- 단위 1: T004~T006 병렬 → T007 → T008 → T009·T010·T012~T017 병렬, T011은 T008 뒤 → T018.
- 단위 2: T019~T021 병렬 → T022·T023·T024 → T025 → T026·T027·T028 → T029~T032 병렬 → T033.
- 단위 3: T034 → T035 → T036 → T037(같은 파일), T038은 T035 뒤 병렬 → T039·T040 병렬 → T041 → T042 → T043 → T044·T045·T046 → T047.
- 단위 4: T048 → T049 → T050.
- 같은 파일을 바꾸는 T030과 T035는 서로 다른 단위이므로 순차 실행한다.
- 서로 다른 실행 단위의 Git index·같은 파일 변경은 병렬 실행하지 않는다.

### 병렬 실행 예시

```text
실행 단위 1 적합 타입 갱신(T008 완료 후):
  T009 LocalKeyValueStorage.swift
  T010 UnavailableKeyValueStorage.swift
  T012~T017 InMemoryKeyValueStorage.swift 6개

실행 단위 2 테스트 더블·프리뷰 갱신(T025 완료 후):
  T029 ProjectGenerationUseCaseStub.swift
  T030 ProjectGenerationUseCaseSpy.swift
  T031 AppRootView.swift
  T032 ProjectGenerationUseCaseMock.swift

실행 단위 3 선언 추가:
  T039 ShareRegistrationDiagnosticEvent.swift
  T040 Localizable.xcstrings
```

## 구현 전략

1. 이 tasks.md의 blob hash와 전체 diff를 기준선으로 고정하고 첫 미완료 실행 단위를 선택한다.
2. 실행 단위의 미완료 작업을 논리적 커밋 단위로 설계한다. 실행 단위 0은 이동만 담은 독립 커밋 단위로 두고, 구현과 직접 관련된
   테스트는 같은 커밋 단위에 둘 수 있다.
3. 각 커밋 단위의 구현·검증·완료 표시·커밋을 순서대로 완료한다. 실행 단위 4의 마지막 커밋 단위는 전체 완료 검증과
   필수 `after_implement` hook까지 열린 상태로 유지한다.
4. 최소 가치 범위는 시나리오 1이며 실행 단위 0~3이 필요하다. 새 권한이 필요하지 않으므로 실행 단위 4와 전체 검증까지 연속 진행한다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 문제 해결과 암묵지 기록을 구현 작업 ID로 생성하지 않는다.
