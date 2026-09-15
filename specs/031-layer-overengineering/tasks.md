# 작업 목록: 값을 더하지 않는 계층과 간접 참조 제거

**입력**: `/specs/031-layer-overengineering/`의 설계 문서

**선행 조건**: [plan.md](./plan.md)(필수), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/README.md](./contracts/README.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를 실행 기준선으로 고정한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 필요한 경우에만 만든다.

**테스트**: 명세 [spec.md](./spec.md)의 SC-003·SC-004·SC-008이 자동화 테스트 증명을 요구하므로 테스트 작업을 포함한다.

**구성**: [plan.md](./plan.md)의 실행 단위 U1, I1~I5, U2를 최상위 구조로 사용하고, 변경 시나리오는 각 단위 안에서 `[S1]`~`[S3]` 라벨로 추적한다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- `[P]` — 같은 실행 단위 안에서 서로 다른 파일을 다루고 미완료 작업에 의존하지 않는 작업
- `[S1]` 프로토콜 생성 기준 확정 / `[S2]` 단일 구현 Data 계약 제거 / `[S3]` 오류 case 중복 정리
- `[no-write]` — 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 검증. `make tuist`의 파생 workspace·project·심볼릭 링크·cache 갱신은 허용하되 실행 전후 Git 상태를 비교하고 추적 파일 변경이 생기면 완료로 처리하지 않는다

## 실행 단위 소유권 규칙

- 파일 변경 작업은 책임 패키지 단계에 배치한다.
- 위상 순서의 근거는 [아키텍처 3.1](../../docs/architecture.md)의 패키지 의존성 표다. `Data`는 `Infrastructure` 뒤, `Composition`은 `Domain`·`Data`·`Infrastructure` 뒤에 온다. 이 명세에서 `Domain`·`Infrastructure`·`Feature`·`App`·`UI`는 바뀌지 않는다.
- Data가 계약을 제거하면 그 계약을 초기화 인자 타입으로 쓰는 Composition 어댑터가 같은 순간 컴파일 실패하므로, 모듈별 계약 제거를 불가분한 integration unit I1~I4로 묶는다. Data 오류 case 제거도 Composition의 `switch` 완전성 검사에 걸리므로 I5로 묶는다. 근거는 [plan.md](./plan.md)의 "I1~I4를 다중 패키지 단위로 두는 근거"와 "I5를 다중 패키지 단위로 두는 근거"에 있다.
- U1(문서)은 코드에 의존하지 않으므로 맨 앞에 둔다. 기준이 먼저 서야 I1~I5의 판단 근거가 문서에 존재한다.
- U2(기준선 기록)는 모든 코드 단위가 끝난 뒤의 수치를 필요로 하므로 맨 뒤에 둔다.

---

## 작업 단위 1 (U1): 문서 — 프로토콜 생성 기준

**목표**: 프로토콜을 두는 근거를 두 가지로 한정해 공통 컨벤션에 기록한다.

**관련 변경 시나리오**: S1

**독립 테스트**: 공통 컨벤션 README의 표에서 항목을 찾아 링크를 따라가고, 근거 A·B와 배제 규칙, 배제 시 대안이 모두 적혀 있는지 확인한다.

### 구현

- [X] T001 [S1] `docs/conventions/abstraction.md`를 인덱스로 만든다. `##`에 추상 원칙을 서술하고 `###` 아래에는 구체 명시 문서 링크만 둔다. 구조 규칙은 [컨벤션 공통 원칙](../../docs/conventions/common/document-structure.md)을 따른다
- [X] T002 [S1] `docs/conventions/abstraction/protocol-criteria.md`에 프로토콜 생성 기준을 작성한다 — 근거 A(패키지 경계를 넘는 계약), 근거 B(경계를 넘지 않더라도 구현을 교체하는 지점이 프로덕션에 실재), 두 근거 중 어느 것도 아니면 구체 타입 하나만 둔다는 판정 규칙
- [X] T003 [S1] `docs/conventions/abstraction/test-double-injection.md`에 테스트 더블 배제 규칙을 작성한다 — 테스트 더블 제공만을 근거로 프로토콜을 두지 않으며, 그 타입이 의존하는 경계 계약에 더블을 주입한다. `StubHTTPTransport`를 실례로 인용한다
- [X] T004 [S1] `docs/conventions/README.md`의 문서 표에 프로토콜 생성 기준 항목을 추가하고, 문서 구조 예시 블록에 `abstraction.md`와 `abstraction/`을 반영한다

### 단위 검증

- [X] T005 [no-write] [S1] `docs/conventions/README.md`에서 시작해 링크만 따라가 근거 A·B·배제 규칙·대안에 모두 도달할 수 있는지 확인한다

**진행 점검**: T001~T005의 변경 파일을 보고하고 다음 실행 단위로 계속한다.

---

## 통합 단위 1 (I1): Data + Composition — Authentication·LegalConsent 계약 제거

**분리 불가 근거**: `AuthenticationRemote`를 제거하면 그 타입을 초기화 인자로 받는 `LoginSessionRepositoryAdapter`·`AuthenticationRepositoryAdapter`가 같은 순간 컴파일 실패한다. `PolicyConsentStore`도 `PolicyConsentRepositoryAdapter`와 `AuthenticationAssembly`에 같은 관계다. 어느 쪽만 먼저 바꿔도 중간 상태가 빌드되지 않는다.

**LegalConsent를 함께 두는 근거**: `PolicyConsentStore`는 `AuthenticationAssembly`가 조립한다. 같은 조립 파일을 두 단위가 나눠 건드리면 충돌 지점이 생긴다.

**소유 경로**: `sources/Projects/Data/Authentication/**`, `sources/Projects/Data/LegalConsent/**`, `sources/Projects/Composition/Adapter/Adapters/{LoginSessionRepositoryAdapter,AuthenticationRepositoryAdapter,PolicyConsentRepositoryAdapter}.swift`, `sources/Projects/Composition/Adapter/Assemblies/AuthenticationAssembly.swift`, 대응 테스트

**관련 변경 시나리오**: S2

**독립 테스트**: 두 계약 파일이 사라지고 `Data`·`Composition` 테스트 scheme이 통과하며, Data 테스트 검증 항목 수가 줄지 않았는지 확인한다.

**통합 검증**: `Data`와 `Composition` 테스트 scheme을 함께 실행한다. 한쪽만으로는 계약 제거가 조립까지 도달했는지 알 수 없다.

### 준비

- [X] T006 [no-write] [S2] Data 테스트의 검증 항목 수 기준선을 측정한다 — `find sources/Projects/Data -path "*/Tests/*" -name "*.swift" -print0 | xargs -0 grep -hE "#expect|#require" | wc -l`. 값을 이 파일의 "기준선 기록" 절에 적는다

### 테스트

- [X] T007 [S2] `sources/Projects/Data/Tests/Authentication/Remotes/HTTPAuthenticationRemoteTests.swift`에 `AuthenticationRemoteContractTests.swift`가 보장하던 항목 중 구현 테스트에 없는 것을 추가한다
- [X] T008 [P] [S2] `sources/Projects/Data/Tests/LegalConsent/Stores/LocalPolicyConsentStoreTests.swift`에 `PolicyConsentStore` 계약이 보장하던 항목 중 구현 테스트에 없는 것을 추가한다
- [X] T009 [S2] `sources/Projects/Composition/Tests/Adapter/Adapters/AuthenticationRepositoryAdapterTests.swift`를 `HTTPAuthenticationRemote` + `StubHTTPTransport` 구성으로 바꾼다
- [X] T010 [S2] `sources/Projects/Composition/Tests/Adapter/Adapters/LoginSessionRepositoryAdapterTests.swift`를 `HTTPAuthenticationRemote` + `StubHTTPTransport` 구성으로 바꾼다
- [X] T011 [S2] `sources/Projects/Composition/Tests/Adapter/Adapters/PolicyConsentRepositoryAdapterTests.swift`를 `LocalPolicyConsentStore` + 격리된 `UserDefaults` suite 구성으로 바꾼다
- [X] T012 [S2] `sources/Projects/Composition/Tests/App/SharedLifetimeTests.swift`에서 `AuthenticationRemote` 참조를 구체 타입 기준으로 바꾸고, 같은 target에서 쓸 전송 계층 더블 `sources/Projects/Composition/Tests/App/TestDoubles/RecordingHTTPTransport.swift`를 추가한다. 경로 추가 근거: `CompositionAppTests`의 소스 범위는 `Tests/App/**`이라 `Tests/Adapter/TestDoubles`의 같은 이름 더블이 보이지 않는다

### 구현

- [X] T013 [S2] `sources/Projects/Data/Authentication/Remotes/HTTPAuthenticationRemote.swift`가 `AuthenticationRemote` 채택을 떼고, Composition이 받을 수 있도록 타입과 메서드의 공개 범위를 확인한다
- [X] T014 [P] [S2] `sources/Projects/Data/LegalConsent/Stores/LocalPolicyConsentStore.swift`가 `PolicyConsentStore` 채택을 떼고 공개 범위를 확인한다
- [X] T015 [S2] `sources/Projects/Composition/Adapter/Adapters/AuthenticationRepositoryAdapter.swift`의 초기화 인자와 저장 프로퍼티 타입을 `HTTPAuthenticationRemote`로 바꾼다
- [X] T016 [S2] `sources/Projects/Composition/Adapter/Adapters/LoginSessionRepositoryAdapter.swift`의 초기화 인자와 저장 프로퍼티 타입을 `HTTPAuthenticationRemote`로 바꾼다
- [X] T017 [S2] `sources/Projects/Composition/Adapter/Adapters/PolicyConsentRepositoryAdapter.swift`의 초기화 인자와 저장 프로퍼티 타입을 `LocalPolicyConsentStore`로 바꾼다
- [X] T018 [S2] `sources/Projects/Composition/Adapter/Assemblies/AuthenticationAssembly.swift`의 `policyConsentStore` 인자 타입을 `LocalPolicyConsentStore`로 바꾼다

### 정리

- [X] T019 [S2] `sources/Projects/Data/Authentication/Contracts/AuthenticationRemote.swift`와 `sources/Projects/Data/LegalConsent/Contracts/PolicyConsentStore.swift`를 제거한다
- [X] T020 [S2] `sources/Projects/Data/Tests/Authentication/Contracts/AuthenticationRemoteContractTests.swift`를 제거하고, 보장 항목의 이관처 또는 제거 근거를 이 파일의 "보장 항목 대조표" 절에 기록한다

### 단위 검증

- [X] T021 [no-write] [S2] `DataAuthenticationTests`·`DataLegalConsentTests`와 `CompositionAdapterTests`·`CompositionAppTests`를 실행해 I1을 검증한다

**범위 보정**: `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionPublicSurfaceTests.swift`의 기대 목록이 commit `c32373e`(명세 030)의 `AppComposition` 공개 프로퍼티 변경을 반영하지 못해 실패 상태로 남아 있었다. I1의 통합 검증을 통과시키기 위해 `authenticationOutcomes`→`verifyAuthorization`, `trackGenerationProgress`→`trackGeneration`으로 고치고 `observeGenerationOutcomes`를 지웠다.

**진행 점검**: T006~T021의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 통합 단위 2 (I2): Data + Composition — ExternalRepository 계약 제거

**분리 불가 근거**: I1과 같다. `ExternalRepositoryRemote`를 제거하면 `ExternalRepositoryLookupAdapter`가 같은 순간 컴파일 실패한다.

**소유 경로**: `sources/Projects/Data/ExternalRepository/**`, `sources/Projects/Composition/Adapter/Adapters/ExternalRepositoryLookupAdapter.swift`, 대응 테스트

**관련 변경 시나리오**: S2

**독립 테스트**: 계약 파일이 사라지고 `Data`·`Composition` 테스트 scheme이 통과하는지 확인한다.

**통합 검증**: `Data`와 `Composition` 테스트 scheme을 함께 실행한다.

### 테스트

- [X] T022 [S2] `sources/Projects/Data/Tests/ExternalRepository/Remotes/HTTPExternalRepositoryRemoteTests.swift`에 `ExternalRepositoryRemoteContractTests.swift`가 보장하던 항목 중 구현 테스트에 없는 것을 추가한다
- [X] T023 [S2] `sources/Projects/Composition/Tests/Adapter/Adapters/ExternalRepositoryLookupAdapterTests.swift`를 `HTTPExternalRepositoryRemote` + `StubHTTPTransport` 구성으로 바꾸고, 파일 안의 `StubExternalRepositoryRemote`를 제거한다

### 구현

- [X] T024 [S2] `sources/Projects/Data/ExternalRepository/Remotes/HTTPExternalRepositoryRemote.swift`가 `ExternalRepositoryRemote` 채택을 떼고 공개 범위를 확인한다
- [X] T025 [S2] `sources/Projects/Composition/Adapter/Adapters/ExternalRepositoryLookupAdapter.swift`의 초기화 인자와 저장 프로퍼티 타입을 `HTTPExternalRepositoryRemote`로 바꾼다

### 정리

- [X] T026 [S2] `sources/Projects/Data/ExternalRepository/Contracts/ExternalRepositoryRemote.swift`를 제거한다
- [X] T027 [S2] `sources/Projects/Data/Tests/ExternalRepository/Contracts/ExternalRepositoryRemoteContractTests.swift`를 제거하고, 보장 항목의 이관처 또는 제거 근거를 이 파일의 "보장 항목 대조표" 절에 기록한다

### 단위 검증

- [X] T028 [no-write] [S2] `DataExternalRepositoryTests`와 `CompositionAdapterTests`를 실행해 I2를 검증한다

**진행 점검**: T022~T028의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 통합 단위 3 (I3): Data + Composition — Member 계약 제거

**분리 불가 근거**: I1과 같다. `MemberRemote`를 제거하면 `MemberRepositoryAdapter`가 같은 순간 컴파일 실패한다.

**소유 경로**: `sources/Projects/Data/Member/**`, `sources/Projects/Composition/Adapter/Adapters/MemberRepositoryAdapter.swift`, 대응 테스트

**관련 변경 시나리오**: S2

**독립 테스트**: 계약 파일과 `MemberRemoteProbe`가 사라지고 `Data`·`Composition` 테스트 scheme이 통과하는지 확인한다.

**통합 검증**: `Data`와 `Composition` 테스트 scheme을 함께 실행한다.

### 테스트

- [ ] T029 [S2] `sources/Projects/Data/Tests/Member/Remotes/HTTPMemberRemoteTests.swift`에 `MemberRemoteContractTests.swift`·`MemberDeviceContractTests.swift`·`MemberPreferenceContractTests.swift`가 보장하던 항목 중 구현 테스트에 없는 것을 추가한다
- [ ] T030 [S2] `sources/Projects/Composition/Tests/Adapter/Adapters/MemberRepositoryAdapterTests.swift`를 `HTTPMemberRemote` + `StubHTTPTransport` 구성으로 바꾼다

### 구현

- [ ] T031 [S2] `sources/Projects/Data/Member/Remotes/HTTPMemberRemote.swift`가 `MemberRemote` 채택을 떼고 공개 범위를 확인한다
- [ ] T032 [S2] `sources/Projects/Composition/Adapter/Adapters/MemberRepositoryAdapter.swift`의 초기화 인자와 저장 프로퍼티 타입을 `HTTPMemberRemote`로 바꾼다

### 정리

- [ ] T033 [S2] `sources/Projects/Data/Member/Contracts/MemberRemote.swift`를 제거한다
- [ ] T034 [S2] `sources/Projects/Data/Tests/Member/TestDoubles/MemberRemoteProbe.swift`를 제거한다
- [ ] T035 [S2] `sources/Projects/Data/Tests/Member/Contracts/MemberRemoteContractTests.swift`, `sources/Projects/Data/Tests/Member/Contracts/MemberDeviceContractTests.swift`, `sources/Projects/Data/Tests/Member/Contracts/MemberPreferenceContractTests.swift`를 제거하고, 각 보장 항목의 이관처 또는 제거 근거를 이 파일의 "보장 항목 대조표" 절에 기록한다

### 단위 검증

- [ ] T036 [no-write] [S2] `DataMemberTests`와 `CompositionAdapterTests`를 실행해 I3을 검증한다

**진행 점검**: T029~T036의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 통합 단위 4 (I4): Data + Composition — LearningProject 계약 5개 제거

**분리 불가 근거**: I1과 같다. `ProjectRemote`·`AnswerRemote`·`BookmarkRemote`·`LearningSetRemote`를 제거하면 대응 어댑터 4개가 같은 순간 컴파일 실패한다. `QuizGenerationRemote`는 프로덕션 구현이 없지만 `LearningProjectRemoteProbe`가 다섯 계약을 한 타입으로 채택하고 있어, 그 더블을 정리하려면 다섯 계약을 함께 다뤄야 한다.

**소유 경로**: `sources/Projects/Data/LearningProject/**`(단 `Contracts/GenerationStateStore.swift`와 `Contracts/QuizGenerationOutcomeSource.swift` 제외), `sources/Projects/Composition/Adapter/Adapters/{LearningProjectRepositoryAdapter,AnswerRepositoryAdapter,BookmarkRepositoryAdapter,LearningSetRepositoryAdapter}.swift`, 대응 테스트

**관련 변경 시나리오**: S2

**독립 테스트**: 계약 5개와 `LearningProjectRemoteProbe`가 사라지고 전체 빌드·테스트가 통과하는지 확인한다.

**통합 검증**: `Data`와 `Composition` 테스트 scheme에 더해 전체 `build` → `compile` → `test`를 실행한다. LearningProject는 참조 지점이 가장 많아 여기서 전체를 한 번 확인한다.

### 테스트

- [ ] T037 [P] [S2] `sources/Projects/Data/Tests/LearningProject/Remotes/HTTPProjectRemoteTests.swift`에 `ProjectRemoteContractTests.swift`가 보장하던 항목 중 구현 테스트에 없는 것을 추가한다
- [ ] T038 [P] [S2] `sources/Projects/Data/Tests/LearningProject/Remotes/HTTPAnswerRemoteTests.swift`에 `AnswerRemoteContractTests.swift`가 보장하던 항목 중 구현 테스트에 없는 것을 추가한다
- [ ] T039 [P] [S2] `sources/Projects/Data/Tests/LearningProject/Remotes/HTTPBookmarkRemoteTests.swift`에 `BookmarkRemoteContractTests.swift`가 보장하던 항목 중 구현 테스트에 없는 것을 추가한다
- [ ] T040 [P] [S2] `sources/Projects/Data/Tests/LearningProject/Remotes/HTTPLearningSetRemoteTests.swift`에 `LearningSetRemoteContractTests.swift`가 보장하던 항목 중 구현 테스트에 없는 것을 추가한다
- [ ] T041 [P] [S2] `sources/Projects/Composition/Tests/Adapter/Adapters/LearningProjectRepositoryAdapterTests.swift`를 `HTTPProjectRemote` + `StubHTTPTransport` 구성으로 바꾼다
- [ ] T042 [P] [S2] `sources/Projects/Composition/Tests/Adapter/Adapters/AnswerRepositoryAdapterTests.swift`를 `HTTPAnswerRemote` + `StubHTTPTransport` 구성으로 바꾼다
- [ ] T043 [P] [S2] `sources/Projects/Composition/Tests/Adapter/Adapters/BookmarkRepositoryAdapterTests.swift`를 `HTTPBookmarkRemote` + `StubHTTPTransport` 구성으로 바꾼다
- [ ] T044 [P] [S2] `sources/Projects/Composition/Tests/Adapter/Adapters/LearningSetRepositoryAdapterTests.swift`를 `HTTPLearningSetRemote` + `StubHTTPTransport` 구성으로 바꾼다

### 구현

- [ ] T045 [P] [S2] `sources/Projects/Data/LearningProject/Remotes/HTTPProjectRemote.swift`가 `ProjectRemote` 채택을 떼고 공개 범위를 확인한다
- [ ] T046 [P] [S2] `sources/Projects/Data/LearningProject/Remotes/HTTPAnswerRemote.swift`가 `AnswerRemote` 채택을 떼고 공개 범위를 확인한다
- [ ] T047 [P] [S2] `sources/Projects/Data/LearningProject/Remotes/HTTPBookmarkRemote.swift`가 `BookmarkRemote` 채택을 떼고 공개 범위를 확인한다
- [ ] T048 [P] [S2] `sources/Projects/Data/LearningProject/Remotes/HTTPLearningSetRemote.swift`가 `LearningSetRemote` 채택을 떼고 공개 범위를 확인한다
- [ ] T049 [S2] `sources/Projects/Composition/Adapter/Adapters/LearningProjectRepositoryAdapter.swift`의 초기화 인자와 저장 프로퍼티 타입을 `HTTPProjectRemote`로 바꾼다
- [ ] T050 [S2] `sources/Projects/Composition/Adapter/Adapters/AnswerRepositoryAdapter.swift`의 초기화 인자와 저장 프로퍼티 타입을 `HTTPAnswerRemote`로 바꾼다
- [ ] T051 [S2] `sources/Projects/Composition/Adapter/Adapters/BookmarkRepositoryAdapter.swift`의 초기화 인자와 저장 프로퍼티 타입을 `HTTPBookmarkRemote`로 바꾼다
- [ ] T052 [S2] `sources/Projects/Composition/Adapter/Adapters/LearningSetRepositoryAdapter.swift`의 초기화 인자와 저장 프로퍼티 타입을 `HTTPLearningSetRemote`로 바꾼다

### 정리

- [ ] T053 [S2] `sources/Projects/Data/LearningProject/Contracts/ProjectRemote.swift`, `sources/Projects/Data/LearningProject/Contracts/AnswerRemote.swift`, `sources/Projects/Data/LearningProject/Contracts/BookmarkRemote.swift`, `sources/Projects/Data/LearningProject/Contracts/LearningSetRemote.swift`, `sources/Projects/Data/LearningProject/Contracts/QuizGenerationRemote.swift`를 제거한다. `Contracts/GenerationStateStore.swift`와 `Contracts/QuizGenerationOutcomeSource.swift`는 그대로 둔다
- [ ] T054 [S2] `sources/Projects/Data/Tests/LearningProject/TestDoubles/LearningProjectRemoteProbe.swift`를 제거한다
- [ ] T055 [S2] `sources/Projects/Data/Tests/LearningProject/Contracts/ProjectRemoteContractTests.swift`, `sources/Projects/Data/Tests/LearningProject/Contracts/AnswerRemoteContractTests.swift`, `sources/Projects/Data/Tests/LearningProject/Contracts/BookmarkRemoteContractTests.swift`, `sources/Projects/Data/Tests/LearningProject/Contracts/LearningSetRemoteContractTests.swift`, `sources/Projects/Data/Tests/LearningProject/Contracts/QuizGenerationRemoteContractTests.swift`를 제거하고, 각 보장 항목의 이관처 또는 제거 근거를 이 파일의 "보장 항목 대조표" 절에 기록한다

### 단위 검증

- [ ] T056 [no-write] [S2] `DataLearningProjectTests`와 `CompositionAdapterTests`를 실행해 I4의 패키지 범위를 검증한다
- [ ] T057 [no-write] [S2] 전체 `build` → `compile` → `test`를 순차 실행하고 결과를 기록한다
- [ ] T058 [no-write] [S2] Data 테스트의 검증 항목 수를 다시 측정해 T006의 기준선 이상인지 확인하고 값을 이 파일의 "기준선 기록" 절에 적는다

**진행 점검**: T037~T058의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 통합 단위 5 (I5): Data + Composition — 오류 case 중복 정리

**분리 불가 근거**: Data 오류의 case를 지우면 그 case를 `switch`하는 Composition 어댑터가 즉시 컴파일 실패한다. Swift의 `switch` 완전성 검사가 두 변경을 같은 커밋에 묶는다.

**소유 경로**: `sources/Projects/Data/*/Errors/**`, `sources/Projects/Composition/Adapter/Adapters/**`, 대응 테스트

**관련 변경 시나리오**: S3

**독립 테스트**: 어댑터의 `case` 분기 총수가 줄고, 같은 입력에 대해 어댑터가 던지는 Domain 오류가 변경 전후 같은지 확인한다.

**통합 검증**: `Data`와 `Composition` 테스트 scheme을 함께 실행한다.

### 준비

- [ ] T059 [no-write] [S3] 어댑터의 `case` 분기 기준선을 측정한다 — `grep -rhoE "case \.[a-zA-Z]+" sources/Projects/Composition/Adapter/Adapters/*.swift | wc -l`. 값을 이 파일의 "기준선 기록" 절에 적는다
- [ ] T060 [no-write] [S3] 각 Data 오류 타입과 대응 Domain 오류 타입의 case를 [data-model.md](./data-model.md) 5절의 기준(항등 / 접힘 / 실제 변환 / 대응 없음)으로 분류하고, 분류 결과를 이 파일의 "오류 case 분류" 절에 기록한다. `generationRetryUnavailable`처럼 대응이 없는 case는 프로덕션 사용처를 확인해 판단한다

### 구현

- [ ] T061 [S3] `sources/Projects/Data/LearningProject/Errors/DataLearningProjectError.swift`에서 T060이 항등으로 분류한 case 구간을 정리한다. 서버 HTTP 상태·오류 코드에서 Data 오류로 가는 매핑은 바꾸지 않는다
- [ ] T062 [P] [S3] `sources/Projects/Data/Authentication/Errors/DataAuthenticationError.swift`에서 T060이 항등으로 분류한 case 구간을 정리한다
- [ ] T063 [P] [S3] `sources/Projects/Data/Member/Errors/DataMemberError.swift`에서 T060이 항등으로 분류한 case 구간을 정리한다
- [ ] T064 [P] [S3] `sources/Projects/Data/ExternalRepository/Errors/DataExternalRepositoryError.swift`에서 T060이 항등으로 분류한 case 구간을 정리한다
- [ ] T065 [S3] `sources/Projects/Composition/Adapter/Adapters/LearningProjectRepositoryAdapter.swift`, `sources/Projects/Composition/Adapter/Adapters/AnswerRepositoryAdapter.swift`, `sources/Projects/Composition/Adapter/Adapters/BookmarkRepositoryAdapter.swift`, `sources/Projects/Composition/Adapter/Adapters/LearningSetRepositoryAdapter.swift`의 오류 재매핑을 T061 결과에 맞춰 줄인다
- [ ] T066 [S3] `sources/Projects/Composition/Adapter/Adapters/AuthenticationRepositoryAdapter.swift`, `sources/Projects/Composition/Adapter/Adapters/LoginSessionRepositoryAdapter.swift`, `sources/Projects/Composition/Adapter/Adapters/MemberRepositoryAdapter.swift`, `sources/Projects/Composition/Adapter/Adapters/ExternalRepositoryLookupAdapter.swift`의 오류 재매핑을 T062~T064 결과에 맞춰 줄인다

### 정리

- [ ] T067 [S3] Data 오류 타입의 case 집합이 바뀐 만큼 `sources/Projects/Data/Tests/**`의 오류 관련 검증을 갱신한다. 서버 응답에서 Data 오류로 가는 매핑 검증은 그대로 유지한다

### 단위 검증

- [ ] T068 [no-write] [S3] `DataAuthenticationTests`·`DataLearningProjectTests`·`DataMemberTests`·`DataExternalRepositoryTests`와 `CompositionAdapterTests`를 실행해 I5를 검증한다
- [ ] T069 [no-write] [S3] 어댑터의 `case` 분기 총수를 다시 측정해 T059의 기준선보다 작은지 확인하고 값을 이 파일의 "기준선 기록" 절에 적는다
- [ ] T070 [no-write] [S3] `grep -rn "DataAuthenticationError\|DataLearningProjectError\|DataMemberError\|DataExternalRepositoryError" sources/Projects/Domain --include="*.swift"` 결과가 비어 있는지 확인한다

**진행 점검**: T059~T070의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 작업 단위 2 (U2): 문서 — 구조 기준선 기록

**목표**: 적용 전후 수치와 남은 프로토콜별 존치 근거를 기록해 이후 PR이 같은 기준으로 확인할 수 있게 한다.

**선행 조건**: I1~I5의 파일 변경 작업을 모두 완료했다.

**관련 변경 시나리오**: S1

**독립 테스트**: 기준선 문서의 프로토콜 목록과 `find` + `grep`으로 얻은 실제 목록이 일치하고, 각 항목에 근거 A 또는 B가 적혀 있는지 확인한다.

### 구현

- [ ] T071 [S1] `docs/conventions/abstraction/structure-baseline.md`에 프로덕션 Swift 파일 수, 프로덕션 프로토콜 수, Data 프로덕션 Contracts 파일 수의 적용 전후 값과 세는 명령을 기록한다
- [ ] T072 [S1] `docs/conventions/abstraction/structure-baseline.md`에 남은 프로덕션 프로토콜 전부를 나열하고 각각을 근거 A 또는 B에 대응시킨다
- [ ] T073 [S1] `docs/conventions/abstraction.md`에 구조 기준선 절(`##` + `###` 링크)과 기준선 갱신 체크리스트 항목을 추가한다. U1에서는 대상 문서가 없어 링크를 만들지 않았다

### 단위 검증

- [ ] T074 [no-write] [S1] 기준선 문서의 프로토콜 목록이 `find sources/Projects -name "*.swift" -not -path "*/Tests/*" -print0 | xargs -0 grep -nE "^[[:space:]]*(public )?protocol "` 결과와 일치하고, 근거에 대응되지 않는 항목이 없는지 확인한다

**진행 점검**: T071~T074의 변경 파일과 검증 결과를 보고한다.

---

## 전체 완료 검증

**선행 조건**: U1, I1~I5, U2의 파일 변경 작업을 모두 완료했다.

**커밋 경계**: 아래 `[no-write]` 작업은 U2의 마지막 커밋 단위에 배정한다.

- [ ] T075 [no-write] `make tuist`로 workspace를 갱신하고 실행 전후 Git 상태를 비교해 추적 파일 변경이 없는지 확인한다
- [ ] T076 [no-write] 전체 `build` → `compile` → `test`를 실행하고 결과를 기록한다
- [ ] T077 [no-write] [S1] [S2] [S3] [quickstart.md](./quickstart.md)의 시나리오별 검증을 모두 확인한다
- [ ] T078 [no-write] 이 파일의 "보장 항목 대조표"가 제거된 모든 계약 테스트의 이관처 또는 제거 근거를 담고 있는지 확인한다

---

## 기준선 기록

> T006, T058, T059, T069에서 채운다.

| 항목 | 적용 전 | 적용 후 |
| --- | --- | --- |
| 프로덕션 Swift 파일 수 | 497 | (T071에서 기록) |
| 프로덕션 프로토콜 수 | 56 | (T071에서 기록) |
| Data 프로덕션 Contracts 파일 수 | 11 | (T071에서 기록) |
| Data 테스트 검증 항목 수 | 322 | (T058에서 기록) |
| Composition 어댑터 `case` 분기 총수 | (T059에서 기록) | (T069에서 기록) |

---

## 오류 case 분류

> T060에서 채운다. Data 오류 case를 항등 / 접힘 / 실제 변환 / 대응 없음으로 분류하고, 정리 대상인 항등 구간을 표시한다.

| Data 오류 타입 | case | Domain case | 분류 | 정리 대상 |
| --- | --- | --- | --- | --- |
| (T060에서 작성) | | | | |

---

## 보장 항목 대조표

> T020, T027, T035, T055에서 채운다. 제거한 계약 테스트가 보장하던 항목을 왼쪽에, 그 보장을 이어받은 구현 테스트를 오른쪽에 적는다. 이어받을 곳이 없으면 제거 근거를 적는다.

| 제거한 보장 | 이관처 또는 제거 근거 |
| --- | --- |
| `AuthenticationRemote`가 Apple 로그인과 Access Token 확인 두 가지만 노출한다 | 제거. 프로브가 스스로 채택한 프로토콜의 형태만 확인했고, 구체 타입 `HTTPAuthenticationRemote`의 공개 메서드가 그 두 가지라는 사실을 컴파일러가 보장한다 |
| `appleLogin`이 accessToken·refreshToken·needsCuration을 담은 응답을 돌려준다 | `sources/Projects/Data/Tests/Authentication/Remotes/HTTPAuthenticationRemoteTests.swift` — `Apple 로그인 요청을 idToken 본문으로 구성하고 응답을 반환한다`(needsCuration 거짓)와 `큐레이션이 필요한 응답의 needsCuration을 참으로 해석한다`(참) |
| `verifyAccessToken`이 호출 가능한 연산이다 | `sources/Projects/Data/Tests/Authentication/Remotes/HTTPAuthenticationRemoteTests.swift` — `Access Token 확인 요청에 Bearer 헤더를 포함한다` |
| `PolicyConsentStore`의 `removeAll`이 저장된 기록을 모두 지운다 (계약 테스트 파일은 없었고 프로토콜 선언만 있었다) | `sources/Projects/Data/Tests/LegalConsent/Stores/LocalPolicyConsentStoreTests.swift` — `removeAll은 저장된 모든 문서 기록을 지운다` |
| `ExternalRepositoryRemote`가 요청을 정확히 한 번 기록하고 DTO를 손실 없이 반환한다 | `sources/Projects/Data/Tests/ExternalRepository/Remotes/HTTPExternalRepositoryRemoteTests.swift` — `GitHub Repository 요청 경로와 헤더를 그대로 전달한다`에서 DTO 전체 동등성과 요청 수 1을 확인한다 |
| `offline`·`other` 실패를 성공 DTO 없이 그대로 전달한다 | `sources/Projects/Data/Tests/ExternalRepository/Remotes/HTTPExternalRepositoryRemoteTests.swift` — `오프라인 상태를 offline 오류로 변환한다`와 `그 외 실패를 other 오류로 변환한다`. 프로브가 되돌려주던 값을 실제 전송 실패와 404 응답에서 만든다 |

---

## 의존성과 실행 순서

### 실행 단위 순서와 위험 기반 승인

1. **U1 (문서)** — 코드에 의존하지 않는다. 기준이 먼저 서야 이후 단위의 판단 근거가 문서에 존재한다.
2. **I1 (Authentication·LegalConsent)** — 근거 문서의 작업 순서 제안을 따른다.
3. **I2 (ExternalRepository)** — I1과 독립이지만 순서를 고정해 리뷰 흐름을 단순히 한다.
4. **I3 (Member)** — I1·I2와 독립.
5. **I4 (LearningProject)** — 참조 지점이 가장 많다. 앞의 세 단위에서 확립한 패턴을 마지막에 가장 넓은 범위에 적용한다.
6. **I5 (오류 정리)** — I1~I4가 어댑터 인자 타입을 모두 바꾼 뒤에 오류 분기를 손대야 같은 파일을 두 번 흔들지 않는다.
7. **U2 (기준선)** — 모든 코드 단위 완료 후의 수치를 기록한다.

새 범위·파괴적 작업·외부 상태 변경·새 제품 결정이 없으므로 단위 사이에 승인 게이트를 두지 않는다. 각 단위 끝에서 변경 파일과 검증 결과만 보고하고 연속 진행한다.

### 변경 시나리오 추적성

| 시나리오 | 작업 |
| --- | --- |
| S1 프로토콜 생성 기준 확정 | T001~T005, T071~T074 |
| S2 단일 구현 Data 계약 제거 | T006~T058 |
| S3 오류 case 중복 정리 | T059~T070 |

### 실행 단위 내부 병렬 실행

- U1: T001~T003은 서로 다른 파일이라 병렬 가능하다. T004는 T001이 만든 파일을 참조하므로 뒤에 온다.
- I1: T008은 T007과 병렬 가능하다. T014는 T013과 병렬 가능하다.
- I4: T037~T044는 모두 다른 파일이라 병렬 가능하다. T045~T048도 마찬가지다. T049~T052는 각각 T045~T048에 의존하므로 대응 쌍이 끝난 뒤에 실행한다.
- I5: T062~T064는 서로 다른 파일이라 병렬 가능하다. T065·T066은 T061~T064 결과에 의존한다.
- 서로 다른 실행 단위 사이에는 병렬 실행을 두지 않는다.

---

## 구현 전략

최소 가치 범위는 **U1**이다. 기준 문서화만으로도 이후 PR에서 불필요한 프로토콜 추가를 막을 수 있다. 새 권한이 필요하지 않으므로 U1 이후 I1~I5, U2까지 연속 진행한다.

I1~I4는 같은 형태의 변경을 모듈만 바꿔 반복한다. I1에서 확립한 패턴(구현 테스트 보강 → 채택 제거 → 어댑터 인자 교체 → 계약·계약 테스트 제거 → 대조표 기록)을 이후 단위에서 그대로 적용한다.

## 참고

- [아키텍처](../../docs/architecture.md)
- [Data 패키지 규칙](../../docs/package-rules/data.md)
- [Composition 패키지 규칙](../../docs/package-rules/composition.md)
- [테스트 컨벤션](../../docs/conventions/test.md)
- [계층 과잉 축소 요구사항](../../docs/review/layer-overengineering-requirements.md)
