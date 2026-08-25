---

description: "온보딩·로그인·튜토리얼 App 통합 구현 작업 목록"
---

# 작업 목록: 온보딩·로그인·튜토리얼 App 통합

**입력**: `/specs/016-onboarding-login-tutorial-app-integration/`의 설계 문서

**선행 조건**: plan.md, spec.md, research.md, data-model.md, contracts/onboarding-flow.md, quickstart.md

**테스트**: 명세가 Domain/Data/Composition/Feature/App 계약 테스트와 UI 접근성 검증을 명시하므로 각 책임 패키지에서 테스트를 구현보다 먼저 작성한다.

**패키지 순서**: `Domain → Infrastructure → Data → Composition → UI → Feature → App`. `App → Feature, Composition, Domain`, `Feature → Domain, UI`, `Composition → Domain, Data, Infrastructure`, `Data → Infrastructure` 의존성에서 피의존 패키지를 먼저 배치했다. Domain과 Infrastructure는 서로 의존하지 않지만 Data가 신규 `UserDefaultsStore`를 소비하려면 Infrastructure가 먼저 완료돼야 하므로 Data 직전에 배치했고, 이미 확정된 Domain 우선 순서는 바꾸지 않았다([plan.md](./plan.md)). UI는 Domain·Data·Composition과 독립이지만 Feature의 두 기반이 모두 안정화된 뒤 Feature를 구현하도록 상대 순서를 고정한다.

**재생성 사유**: 이전 버전은 `AuthenticationOutcome`을 `SignInUseCase`·`SignOutUseCase`·`RestoreSessionUseCase`가 공유하는 전제로 작성됐다. `/speckit-analyze` 세션 2026-08-26에서 이 재사용이 `SignInResult.cancelled`를 표현하지 못하는 계약 공백으로 확인됐고, plan.md·data-model.md·contracts/onboarding-flow.md가 상태 조회 타입(`AuthenticationOutcome`, `ObserveAuthenticationOutcomesUseCase` 전용)과 액션 결과 타입(`SignInResult`·`SignOutResult`·`RestoreSessionResult`)을 분리하도록 갱신됐다. 이 문서는 그 분리를 반영해 Domain 작업을 전면 재작성하고 하위 패키지의 관련 작업을 갱신했다.

**부분 갱신 사유 1(같은 세션, needsCuration)**: 같은 `/speckit-analyze` 세션에서 research.md §10·data-model.md("LoginResponse")·contracts/onboarding-flow.md(Phase 계약, 로그인 직후 curation 판정)가 이미 `LoginResponse.needsCuration`으로 로그인 직후 curation 필요 여부를 판정하도록 결정했지만, 이 결정이 Domain·Feature 작업에 반영되지 않은 공백이 확인됐다. 저장소의 현재 미커밋 상태(`LoginResponseDTO.needsCuration`, `LocalOnboardingState.needsCuration`, `LoginSessionRepositoryAdapter.start(with:)`가 로그인 성공 시 `needsCuration`을 세션 record에 저장하는 동작)는 이미 이 값을 세션 정본에 보존하고 있어 Data·Composition 작업은 추가 변경이 필요하지 않다. Domain(SignInResult·SignIn.swift)과 Feature(reducer) 작업을 이 값이 `SignInResult.success`를 통해 Feature까지 손실 없이 전달되도록 갱신했다.

**부분 갱신 사유 2(저장 기술, `/speckit-plan` 재실행)**: 같은 `/speckit-analyze` 세션에서 정책 동의 로컬 저장 기술이 plan.md의 "먼저 검증하고 선택" 요구에도 research.md에 구체 기술명 없이 남아 있는 공백(F2)이 확인됐다. `/speckit-plan`을 다시 실행해 기존 `KeychainStore`(앱 삭제 후에도 유지될 수 있음)와 `InMemoryCache`(프로세스 재시작 시 소실)가 각각 FR-041의 "앱 데이터 삭제 시 무효화"·"로그아웃 후 유지" 요건을 만족하지 못함을 확인했고, Infrastructure에 `UserDefaultsStore` 범용 기술 API를 신설하기로 결정했다([research.md §3.1](./research.md), [plan.md](./plan.md)). 이 문서는 그 결정에 따라 **작업 패키지 2: Infrastructure**를 새로 추가하고, Data 이후 모든 작업 ID를 4개씩 뒤로 밀어 재번호를 매겼다(T028부터 T100까지).

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 승인된 현재 패키지 안에서만 병렬 실행 가능
- **[S1]~[S4]**: `spec.md`의 변경 시나리오 추적 라벨
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 또는 수동 검증.
  `make tuist`의 파생 workspace·project·심볼릭 링크·cache 갱신은 허용하되 실행 전후 Git 상태를
  비교하고 추적 파일 변경이 생기면 완료로 처리하지 않는다.
- 파일 변경 작업은 정확한 저장소 상대 경로 하나와 하나의 책임 패키지만 가진다.

## 작업 패키지 1: Domain

**목표**: nullable 멤버 프로필, 오류 분류, 상태 조회와 분리된 인증 액션 결과 타입, 명시적 세션
정리, 정책 문서·동의 유효성의 공급자 중립 계약을 확립한다.

**소유 경로**: `sources/Projects/Domain/Authentication/`, `sources/Projects/Domain/Member/`,
`sources/Projects/Domain/Tests/Authentication/`, `sources/Projects/Domain/Tests/Member/`

**관련 변경 시나리오**: S1, S2, S3

**독립 검증**: Domain 전용 테스트에서 null과 unknown raw value, 인증 액션 결과 3타입의 케이스
분리, 동의 버전 정책, sign-out 실패, 전체 큐레이션 제출 계약을 외부 패키지 없이 검증한다.

### 테스트

- [X] T001 [P] [S1] `sources/Projects/Domain/Tests/Member/Models/MemberProfileTests.swift`에 `position`·`careerLevel`의 개별 null 보존과 둘 중 하나가 null이면 전체 큐레이션이 필요하다는 테스트를 작성한다
- [X] T002 [P] [S1] `sources/Projects/Domain/Tests/Member/Models/MemberRegistrationStatusTests.swift`에 등록 완료·미가입·재시도 오류가 서로 합쳐지지 않는 테스트를 작성한다
- [X] T003 [P] [S2] `sources/Projects/Domain/Tests/Authentication/Models/PolicyConsentTests.swift`에 필수 문서별 ID·version 일치, 한 문서 버전 변경, 계정 식별자 부재를 검증하는 테스트를 작성한다
- [X] T004 [P] [S1] `sources/Projects/Domain/Tests/Authentication/Models/SignOutResultTests.swift`에 `success`·`retryableFailure` 2케이스만 존재하고 `AuthenticationOutcome`과 케이스 집합이 다름을 검증하는 테스트를 작성한다
- [X] T005 [P] [S2] `sources/Projects/Domain/Tests/Authentication/Models/SignInResultTests.swift`에 `success(AuthenticatedUser, needsCuration: Bool)`·`cancelled`·`retryableFailure` 3케이스가 서로 구분되고 `cancelled`가 `retryableFailure`로 병합되지 않으며 `needsCuration`이 `true`/`false` 각각 손실 없이 보존되는 테스트를 작성한다
- [X] T006 [P] [S1] `sources/Projects/Domain/Tests/Authentication/Models/RestoreSessionResultTests.swift`에 `authenticated(AuthenticatedUser)`·`unauthenticated`·`recoverableFailure` 3케이스가 `AuthenticationOutcome`과 별개 타입임을 검증하는 테스트를 작성한다
- [X] T007 [P] [S1] `sources/Projects/Domain/Tests/Authentication/UseCases/SignOutTests.swift`를 갱신해 로컬 인증 정리 성공·실패가 `SignOutResult.success`·`.retryableFailure`로 손실 없이 반환되는 테스트로 대체한다
- [X] T008 [P] [S2] `sources/Projects/Domain/Tests/Authentication/UseCases/SignInTests.swift`를 갱신해 Apple 인증 취소(`AuthenticationError.cancelled`)가 `SignInResult.cancelled`로, 그 외 일시적 실패가 `.retryableFailure`로 분리 반환되는 테스트와, 로그인 성공 시 `loginSessionRepository.currentSession()`이 반환한 `LocalOnboardingState.needsCuration`이 `SignInResult.success`의 `needsCuration`으로 그대로 전달되는 테스트(true/false 각각)로 대체한다
- [X] T009 [P] [S1] `sources/Projects/Domain/Tests/Authentication/UseCases/RestoreSessionTests.swift`를 갱신해 `RestoreSessionResult`의 3케이스 반환과 `LoginSessionError`/`AuthorizationStatus` 분기가 유지되는 테스트로 대체한다
- [X] T010 [P] [S3] `sources/Projects/Domain/Tests/Member/UseCases/CompleteCurationTests.swift`에 지원 position과 `CareerLevel.allCases`가 `entry`·`junior`·`midLevel`·`senior` 4개뿐인 계약, 단일 전체 제출 및 미완성 선택 거부 테스트를 추가한다

### 구현

- [X] T011 [S3] `sources/Projects/Domain/Member/Models/CareerLevel.swift`의 현재 미커밋 상태(`entry`·`junior`·`midLevel`·`senior`, `.unknown` 없음)를 유지하며 T010 계약과 정합함을 확인한다
- [X] T012 [S3] `sources/Projects/Domain/Member/Models/MemberPosition.swift`의 현재 미커밋 상태(`ios`·`android`·`backend`·`frontend`, `.web`·`.unknown` 없음)를 유지하며 FR-011 노출 정책과 정합함을 확인한다
- [X] T013 [S1] `sources/Projects/Domain/Member/Models/MemberProfile.swift`의 `position`과 `careerLevel`을 optional로 바꾸고 서버 null을 그대로 보존하는 initializer를 제공한다
- [X] T014 [S1] `sources/Projects/Domain/Member/Models/MemberRegistrationStatus.swift`에 `registered(profile:)`, `unregistered`, `retryableFailure` 상태를 정의한다
- [X] T015 [S2] `sources/Projects/Domain/Authentication/Models/PolicyDocument.swift`에 안정적 ID, 표시 이름, 명시적 version, HTTPS URL, 필수 여부 계약을 정의한다
- [X] T016 [S2] `sources/Projects/Domain/Authentication/Models/PolicyConsentRecord.swift`에 문서 ID·version·문서별 동의 시각만 포함하는 설치 단위 기록을 정의한다
- [X] T017 [S1] `sources/Projects/Domain/Authentication/Models/SignInResult.swift`에 `success(AuthenticatedUser, needsCuration: Bool)`·`cancelled`·`retryableFailure` 3케이스의 신규 액션 결과 타입을 정의하고 `AuthenticationOutcome`을 재사용하지 않는다. `needsCuration`은 로그인 직후 curation 필요 여부(contracts/onboarding-flow.md Phase 계약)를 나타내며 세션 복구 경로의 profile null 판정과는 별개다
- [X] T018 [S1] `sources/Projects/Domain/Authentication/Models/SignOutResult.swift`에 `success`·`retryableFailure` 2케이스의 신규 액션 결과 타입을 정의한다
- [X] T019 [S1] `sources/Projects/Domain/Authentication/Models/RestoreSessionResult.swift`에 `authenticated(AuthenticatedUser)`·`unauthenticated`·`recoverableFailure` 3케이스의 신규 액션 결과 타입을 정의하고 `AuthenticationOutcome`을 재사용하지 않는다
- [X] T020 [S1] `sources/Projects/Domain/Authentication/UseCases/Protocols/SignInUseCase.swift`의 `callAsFunction` 반환 타입을 `AuthenticationOutcome`에서 `SignInResult`로 변경한다
- [X] T021 [S1] `sources/Projects/Domain/Authentication/UseCases/Protocols/SignOutUseCase.swift`의 `callAsFunction` 반환 타입을 `AuthenticationOutcome`에서 `SignOutResult`로 변경한다
- [X] T022 [S1] `sources/Projects/Domain/Authentication/UseCases/Protocols/RestoreSessionUseCase.swift`의 `callAsFunction` 반환 타입을 `AuthenticationOutcome`에서 `RestoreSessionResult`로 변경한다
- [X] T023 [S1] `sources/Projects/Domain/Authentication/UseCases/SignIn.swift`를 `SignInResult`를 반환하도록 갱신하고 `AuthenticationError.cancelled`를 `.cancelled`로, 그 외 오류를 `.retryableFailure`로 매핑한다. `loginSessionRepository.start(with:)` 성공 뒤 같은 repository의 `currentSession()`이 반환하는 `LocalOnboardingState.needsCuration`을 조회해 `SignInResult.success(user, needsCuration:)`에 손실 없이 포함한다(현재 미커밋 `LoginSessionRepositoryAdapter.start(with:)`가 이미 로그인 응답의 `needsCuration`을 세션 record에 저장하므로 Composition 변경은 불필요하다)
- [X] T024 [S1] `sources/Projects/Domain/Authentication/UseCases/SignOut.swift`를 `SignOutResult`를 반환하도록 갱신하고 로컬 인증 정리 실패를 삼키지 않고 `.retryableFailure`로 반환한다
- [X] T025 [S1] `sources/Projects/Domain/Authentication/UseCases/RestoreSession.swift`를 `RestoreSessionResult`를 반환하도록 갱신하고 기존 `LoginSessionError`/`AuthorizationStatus` 분기 의미를 유지한다
- [X] T026 [S2] `sources/Projects/Domain/Authentication/UseCases/Protocols/PolicyConsentUseCase.swift`에 현재 필수 문서 조회, 저장 기록 조회·저장, 문서별 version 유효성 판정 계약을 정의한다

### 정리와 패키지 검증

- [X] T027 [no-write] `sources/Projects/Domain/`을 대상으로 Domain 전용 test scheme을 실행하고 S1~S3 계약 테스트 결과, `ObserveAuthenticationOutcomesUseCase`의 `AuthenticationOutcome` 3케이스 불변, 미커밋 변경 보존 여부를 보고한다

**승인 게이트**: T001~T027의 변경 파일과 실제 검증 결과를 보고한 뒤 중단한다. 사용자가 Infrastructure 진행을 명시적으로 승인하기 전에는 Infrastructure 파일을 변경하지 않는다.

---

## 작업 패키지 2: Infrastructure

**목표**: 정책 동의 로컬 저장이 "로그아웃 후 유지 + 앱 데이터 삭제 시 무효화" 수명(FR-041)을
만족하도록 신규 범용 기술 API `UserDefaultsStore`를 제공한다.

**소유 경로**: `sources/Projects/Infrastructure/Storage/`, `sources/Projects/Infrastructure/Tests/Storage/`

**관련 변경 시나리오**: S2

**독립 검증**: Infrastructure 전용 테스트에서 Codable 값의 저장·조회·삭제, 키 격리, 손상된
저장값 처리를 외부 패키지 없이 검증한다.

### 테스트

- [ ] T028 [P] [S2] `sources/Projects/Infrastructure/Tests/Storage/UserDefaultsStoreTests.swift`에 Codable 값의 저장 후 조회 round-trip, 같은 키 재저장 시 값 교체, 서로 다른 namespace/키 간 격리 테스트를 작성한다
- [ ] T029 [P] [S2] `sources/Projects/Infrastructure/Tests/Storage/UserDefaultsStoreTests.swift`(같은 파일, 별도 테스트)에 `removeValue`·`removeAll` 후 조회가 `nil`을 반환하는 테스트와, 저장되지 않은 키 조회·손상된 raw 값 디코딩 실패가 오류 없이 `nil`을 반환하는 테스트를 추가한다

### 구현

- [ ] T030 [S2] `sources/Projects/Infrastructure/Storage/UserDefaultsStore.swift`에 `InMemoryCache`와 같은 스타일의 제네릭 key-value 범용 기술 API(`store(_:forKey:)`, `value(forKey:)`, `removeValue(forKey:)`, `removeAll()`)를 `UserDefaults` 위에 구현한다. Domain·Data 의미를 노출하지 않고 Codable 값만 다룬다([research.md §3.1](../../../specs/016-onboarding-login-tutorial-app-integration/research.md))
- [ ] T031 [S2] `sources/Projects/Infrastructure/Project.swift`에 `UserDefaultsStore`를 포함하는 기존 `InfrastructureCache`(또는 대응 target) source 선언만 갱신한다. 새 외부 라이브러리 의존성은 추가하지 않는다

### 정리와 패키지 검증

- [ ] T032 [no-write] `sources/Projects/Infrastructure/`를 대상으로 Infrastructure 전용 test scheme을 실행하고 `UserDefaultsStore`의 저장·조회·삭제·격리 계약 결과를 보고한다

**승인 게이트**: T028~T032의 변경 파일과 실제 검증 결과를 보고한 뒤 중단한다. 사용자가 Data 진행을 명시적으로 승인하기 전에는 Data 파일을 변경하지 않는다.

---

## 작업 패키지 3: Data

**목표**: Member API의 null·unknown·404 오류 의미를 보존하고, 신규 `UserDefaultsStore` 위에서
설치 단위 정책 동의 저장소를 구현한다.

**소유 경로**: `sources/Projects/Data/Member/`, `sources/Projects/Data/LegalConsent/`, `sources/Projects/Data/Tests/Member/`, `sources/Projects/Data/Tests/LegalConsent/`

**관련 변경 시나리오**: S1, S2

**독립 검증**: Data 테스트에서 JSON null, 미지원 non-null raw, 계약된 404, transport·5xx·decoding 및 consent serialization·수명을 구분한다.

### 테스트

- [ ] T033 [P] [S1] `sources/Projects/Data/Tests/Member/DTOs/MemberProfileResponseDTOTests.swift`에 두 필드의 null 조합과 미지원 non-null raw value decoding 실패 테스트를 추가한다
- [ ] T034 [P] [S1] `sources/Projects/Data/Tests/Member/Errors/DataMemberErrorTests.swift`에 `(404, MEMBER-001)`과 일반 404·transport·5xx·decoding 오류 분류 테스트를 추가한다
- [ ] T035 [P] [S2] `sources/Projects/Data/Tests/LegalConsent/PolicyConsentRecordDTOTests.swift`에 문서별 record 직렬화와 회원·Apple 계정 식별자 부재 테스트를 작성한다
- [ ] T036 [P] [S2] `sources/Projects/Data/Tests/LegalConsent/LocalPolicyConsentStoreTests.swift`에 `UserDefaultsStore` 기반 구현이 logout과 무관하게 설치 단위로 유지되고, 문서별 교체와 앱 데이터 초기화(새 `UserDefaultsStore` 인스턴스 시뮬레이션) 후 부재를 만족하는 테스트를 작성한다

### 구현

- [ ] T037 [S1] `sources/Projects/Data/Member/DTOs/MemberProfileResponseDTO.swift`에서 `position`·`careerLevel`을 `String?`으로 선언해 JSON null을 그대로 보존하고 unknown 문자열을 null로 치환하지 않는다
- [ ] T038 [S1] `sources/Projects/Data/Member/Errors/DataMemberError.swift`에 계약된 미가입 응답과 retryable transport·server·decoding 오류를 구분하는 의미를 추가한다
- [ ] T039 [S2] `sources/Projects/Data/LegalConsent/Models/PolicyConsentRecordDTO.swift`에 계정 식별자가 없는 Codable 저장 모델을 구현한다
- [ ] T040 [S2] `sources/Projects/Data/LegalConsent/Contracts/PolicyConsentStore.swift`에 설치 단위 record 조회·저장·초기화 계약을 정의한다
- [ ] T041 [S2] `sources/Projects/Data/LegalConsent/Stores/LocalPolicyConsentStore.swift`에 Infrastructure `UserDefaultsStore`를 사용하는 document ID별 저장 구현을 추가한다(더 이상 "기존 범용 저장 API"로 미확정 상태를 두지 않고 T030에서 신설한 구체 API를 직접 참조한다)
- [ ] T042 [S2] `sources/Projects/Data/Project.swift`에 `DataLegalConsent` source/test target과 `InfrastructureCache`(또는 T031에서 확정한 target명) 의존성만 선언한다

### 정리와 패키지 검증

- [ ] T043 [no-write] `sources/Projects/Data/`를 대상으로 Data 전용 test scheme을 실행하고 S1·S2 계약 테스트 및 기존 미커밋 DTO 변경 보존 여부를 보고한다

**승인 게이트**: T033~T043의 변경 파일과 실제 검증 결과를 보고한 뒤 중단한다. 사용자가 Composition 진행을 명시적으로 승인하기 전에는 Composition 파일을 변경하지 않는다.

---

## 작업 패키지 4: Composition

**목표**: Domain↔Data 변환, 신규 인증 액션 결과 타입 매핑, 명시적 세션 정리, 정책 저장소와
Member graph를 하나의 production composition으로 조립한다.

**소유 경로**: `sources/Projects/Composition/Adapter/`, `sources/Projects/Composition/Tests/Adapter/`

**관련 변경 시나리오**: S1, S2, S3

**독립 검증**: adapter 테스트에서 null·404·오류 변환, `SignInResult`·`SignOutResult`·`RestoreSessionResult` 전달, consent 수명, `CompleteCurationUseCase` 단일 정본 노출을 검증한다.

### 테스트

- [ ] T044 [P] [S1] `sources/Projects/Composition/Tests/Adapter/MemberRepositoryAdapterTests.swift`에 nullable profile, 계약된 404, transport·5xx·decoding 변환 테스트를 추가한다
- [ ] T045 [P] [S2] `sources/Projects/Composition/Tests/Adapter/PolicyConsentRepositoryAdapterTests.swift`에 manifest 문서와 저장 record의 version 유효성 및 logout 후 유지 테스트를 작성한다
- [ ] T046 [P] [S1] `sources/Projects/Composition/Tests/Adapter/AuthenticationRepositoryAdapterTests.swift`에 `SignInResult`의 `cancelled`/`retryableFailure` 구분, `RestoreSessionResult`의 3케이스 전달, `SignOutResult`의 로컬 정리 실패 노출이 손실 없이 유지되는 테스트를 작성한다
- [ ] T047 [P] [S1] `sources/Projects/Composition/Tests/Adapter/AuthenticationAssemblyTests.swift`를 갱신해 `SignInUseCase`·`SignOutUseCase`·`RestoreSessionUseCase`가 신규 결과 타입을 반환하는 조립 계약 테스트로 대체한다
- [ ] T048 [P] [S3] `sources/Projects/Composition/Tests/Adapter/AppCompositionTests.swift`에 Member graph의 `CompleteCurationUseCase` 단일 정본과 Domain protocol 전용 공개 테스트를 작성한다

### 구현

- [ ] T049 [S1] `sources/Projects/Composition/Adapter/MemberRepositoryAdapter.swift`에서 Data null을 Domain optional `MemberProfile.position`/`careerLevel`로 보존하고 계약된 404만 `unregistered`로 변환한다
- [ ] T050 [S1] `sources/Projects/Composition/Adapter/AuthenticationRepositoryAdapter.swift`에서 로컬 인증 정리 오류를 `SignOutResult.retryableFailure`로, Apple 인증 취소를 `SignInResult.cancelled`로, 세션 복구 실패를 `RestoreSessionResult.recoverableFailure`로 손실 없이 변환한다
- [ ] T051 [S2] `sources/Projects/Composition/Adapter/PolicyConsentRepositoryAdapter.swift`에 Domain 정책 계약과 Data 설치 단위 store 사이의 record 변환을 구현한다
- [ ] T052 [S2] `sources/Projects/Composition/Adapter/AuthenticationAssembly.swift`에 정책 동의 adapter와 명시적 local cleanup use case를 같은 session 수명으로 조립하고 `SignIn`·`SignOut`·`RestoreSession`이 신규 결과 타입을 반환하도록 조립을 갱신한다
- [ ] T053 [S3] `sources/Projects/Composition/Adapter/MemberAssembly.swift`가 `CompleteCurationUseCase`의 유일한 production 조립 지점이 되도록 정리한다
- [ ] T054 [S1] `sources/Projects/Composition/Adapter/AppComposition.swift`에 profile·curation·policy·cleanup Domain protocol을 노출하고 중복 curation assembly를 제거한다

### 정리와 패키지 검증

- [ ] T055 [no-write] `sources/Projects/Composition/`을 대상으로 Composition 전용 test scheme을 실행하고 S1~S3 경계 변환, 신규 결과 타입 전파, 직접 Data 타입 비노출을 보고한다

**승인 게이트**: T044~T055의 변경 파일과 실제 검증 결과를 보고한 뒤 중단한다. 사용자가 UI 진행을 명시적으로 승인하기 전에는 UI 파일을 변경하지 않는다.

---

## 작업 패키지 5: UI

**목표**: onboarding 화면이 재사용할 단일 선택, 정책 행, 페이지 상태 표현과 접근성 계약을 공용 컴포넌트로 제공한다.

**소유 경로**: `sources/Projects/UI/Component/Components/`, `sources/Projects/UI/Tests/Component/`

**관련 변경 시나리오**: S2, S3, S4

**독립 검증**: UIComponent 계약 테스트에서 44×44pt hit area, callback, selected trait, page 값과 오류·retry 접근성 정보를 검증한다.

### 테스트

- [ ] T056 [P] [S3] `sources/Projects/UI/Tests/Component/Unit/SelectionCardListTests.swift`에 단일 선택 callback, 선택 trait와 비선택 상태 계약 테스트를 작성한다
- [ ] T057 [P] [S2] `sources/Projects/UI/Tests/Component/Unit/PolicyAgreementRowTests.swift`에 필수 표시, 선택, 외부 브라우저 열기 요청 실패·retry callback 및 44×44pt hit area 테스트를 작성한다
- [ ] T058 [P] [S4] `sources/Projects/UI/Tests/Component/Unit/PageIndicatorTests.swift`에 현재 페이지 label/value와 Reduce Motion 독립성 테스트를 작성한다

### 구현

- [ ] T059 [S3] `sources/Projects/UI/Component/Components/Composite/SelectionCardList.swift`에 Domain 타입을 노출하지 않는 generic 단일 선택 값과 callback API를 추가한다
- [ ] T060 [S2] `sources/Projects/UI/Component/Components/Composite/PolicyAgreementRow.swift`에 필수 선택, 승인 링크, 외부 브라우저 열기 요청 실패와 retry를 분리한 공용 표현을 구현하고 page load 상태는 API에 포함하지 않는다
- [ ] T061 [S4] `sources/Projects/UI/Component/Components/Leaf/PageIndicator.swift`에 현재/전체 페이지를 색상 외 label·value로 전달하는 표현을 구현한다
- [ ] T062 [S2] `sources/Projects/UI/Component/Components/Composite/SheetSurface.swift`가 Dynamic Type과 작은 화면에서 정책 목록과 CTA에 스크롤 접근을 보장하도록 확장한다
- [ ] T063 [S4] `sources/Projects/UI/Component/Components/Composite/OnboardingMockup.swift`를 실제 Domain action 없이 교체 가능한 tutorial presentation으로 유지하며 접근성 장식 요소를 정리한다

### 정리와 패키지 검증

- [ ] T064 [no-write] `sources/Projects/UI/`를 대상으로 UIComponent unit/UI test scheme을 실행하고 S2~S4 공용 표현 계약과 기존 컴포넌트 중복 부재를 보고한다

**승인 게이트**: T056~T064의 변경 파일과 실제 검증 결과를 보고한 뒤 중단한다. 사용자가 Feature 진행을 명시적으로 승인하기 전에는 Feature 또는 Feature Tuist helper 파일을 변경하지 않는다.

---

## 작업 패키지 6: Feature

**목표**: 하나의 onboarding phase와 request identity로 tutorial·legal·sign-in·curation 흐름을
관리하고, 신규 `SignInResult`·`RestoreSessionResult`·`SignOutResult`를 해석해 deterministic
screen-local Preview를 제공한다.

**소유 경로**: `sources/Projects/Feature/Presentation/Onboarding/`, `sources/Projects/Feature/Tests/Onboarding/`, `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`

**관련 변경 시나리오**: S1, S2, S3, S4

**독립 검증**: TCA reducer 테스트로 route, 호출 횟수, stale response, 선택 보존과 delegate를 검증하고 각 화면 Preview에서 지정 상태를 독립 재현한다.

### 준비와 테스트

- [ ] T065 `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`에 `FeatureTests` target과 shared scheme Test Action 연결에 필요한 Feature 패키지 선언만 추가한다
- [ ] T066 [P] [S1] `sources/Projects/Feature/Tests/Onboarding/OnboardingRestoreTests.swift`에 미인증·`RestoreSessionResult.recoverableFailure`/retry·member 404/cleanup 실패·partial null·complete profile·stale 응답 전이와 호출 횟수를 작성한다
- [ ] T067 [P] [S2] `sources/Projects/Feature/Tests/Onboarding/OnboardingLegalAndSignInTests.swift`에 tutorial paging, consent 유효/불일치, sheet 취소, 외부 브라우저 열기 요청 실패, sign-in 중복, `SignInResult`의 `success`·`cancelled`·`retryableFailure`와 단계 이탈 뒤 stale 응답 무시 테스트를 작성한다. `success`는 `needsCuration: true`이면 position 단계로, `false`이면 profile을 재조회하지 않고 즉시 completing/MainShell delegate로 전이하는 두 경로를 각각 검증한다
- [ ] T068 [P] [S3] `sources/Projects/Feature/Tests/Onboarding/OnboardingCurationTests.swift`에 지원 값 매핑, CTA 상태, career back 보존, position back의 `SignOutResult` 처리(성공 시 tutorial 3페이지, 실패 시 오류 유지), 중복 제출, 실패 retry와 성공 delegate 테스트를 작성한다
- [ ] T069 [P] [S4] `sources/Projects/Feature/Tests/Onboarding/OnboardingAccessibilityTests.swift`에 페이지·선택·오류의 접근성 값과 Reduce Motion 상태 계약 테스트를 작성한다

### reducer 구현

- [ ] T070 [S1] `sources/Projects/Feature/Presentation/Onboarding/OnboardingFeature.swift`에 `splash`, `restoreError`, `tutorial`, `legalAgreement`, `position`, `career`, `completing` 단일 phase와 initializer 주입 Domain protocol(`RestoreSessionUseCase`·`SignInUseCase`·`SignOutUseCase`·`FetchMemberProfileUseCase`·`CompleteCurationUseCase`·정책 조회/저장 UseCase)을 구현한다
- [ ] T071 [S1] `sources/Projects/Feature/Presentation/Onboarding/OnboardingFeature.swift`에 launch 자동 restore 1회, 명시적 retry, `RestoreSessionResult`의 `authenticated`/`unauthenticated`/`recoverableFailure` 분기, 인증 후 profile/404 분기와 request identity 기반 stale response 무시를 구현한다
- [ ] T072 [S2] `sources/Projects/Feature/Presentation/Onboarding/OnboardingFeature.swift`에 정책 version 유효성, sheet 선택·취소, 문서별 외부 브라우저 열기 요청 실패 상태, sign-in 중복 방지, `SignInResult`의 `success`·`cancelled`·`retryableFailure` 분기와 request identity 기반 stale 응답 무시를 구현한다. `success`의 `needsCuration`이 `true`면 position 단계로 전이하고, `false`면 `FetchMemberProfileUseCase`를 호출하지 않고 곧바로 completing을 거쳐 MainShell delegate를 실행한다(세션 복구 경로의 profile null 기반 판정은 T071 그대로 유지하고 이 분기와 공유하지 않는다)
- [ ] T073 [S3] `sources/Projects/Feature/Presentation/Onboarding/OnboardingFeature.swift`에 position/career 매핑, `SignOutResult` 처리를 포함한 position back 동작, career back 선택값 보존, 전체 curation 단일 제출, 실패 보존과 완료 delegate를 구현한다

### 화면과 Preview

- [ ] T074 [P] [S1] `sources/Projects/Feature/Presentation/Onboarding/SplashScreen.swift`에 restore loading/error/retry UI, Reduce Motion 동작과 파일 하단 `iPhone 17 Pro Max` deterministic Preview를 구현한다
- [ ] T075 [P] [S2] `sources/Projects/Feature/Presentation/Onboarding/TutorialScreen.swift`에 3페이지 swipe, 동기화 indicator, 3페이지 tooltip·실제 bundle version 표시 및 Figma `779:33450`·`779:33529`·`779:33564` Preview를 구현하되 Google 로그인 표현은 Apple 로그인으로 정합화한다
- [ ] T076 [P] [S2] `sources/Projects/Feature/Presentation/Onboarding/LegalAgreementScreen.swift`에 두 필수 정책, 선택, `openURL` 외부 브라우저 열기 결과 action, 문서별 열기 요청 실패/retry, 계속하기 상태 및 Figma `786:38332`·idle/error Preview를 구현하고 브라우저 page load는 추적하지 않는다
- [ ] T077 [P] [S3] `sources/Projects/Feature/Presentation/Onboarding/PositionSelectionScreen.swift`에 네 position의 1:1 매핑, back 시 `SignOutUseCase` 호출, Figma `737:10367`·idle/loading Preview를 구현한다
- [ ] T078 [P] [S3] `sources/Projects/Feature/Presentation/Onboarding/CareerSelectionScreen.swift`에 `entry`·`junior`·`midLevel`·`senior` 순서와 문구, back 보존, Figma node `737:10358`·`737:10349` Preview를 구현한다
- [ ] T079 [S4] `sources/Projects/Feature/Presentation/Onboarding/OnboardingScreen.swift`에 phase별 화면을 하나만 렌더링하고 작은 화면·Dynamic Type·VoiceOver에서 핵심 CTA 접근을 보장하는 container와 Preview를 구현한다

### 정리와 패키지 검증

- [ ] T080 [no-write] `sources/Projects/Feature/`와 `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`를 대상으로 `make tuist` 후 Feature build/test를 실행하고 S1~S4 reducer·Preview 진입점 및 금지 import 0건을 보고한다

**승인 게이트**: T065~T080의 변경 파일과 실제 검증 결과를 보고한 뒤 중단한다. 사용자가 App 진행을 명시적으로 승인하기 전에는 App 또는 App Tuist helper 파일을 변경하지 않는다.

---

## 작업 패키지 7: App

**목표**: 정책 manifest와 production composition을 앱 수명당 한 번 생성하고 onboarding/MainShell root 전환을 실제 앱 진입점에 연결한다.

**소유 경로**: `sources/Projects/App/`, `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`

**관련 변경 시나리오**: S1, S2, S3, S4

**독립 검증**: App 테스트에서 composition 생성 횟수, root 전환, logout/session invalidation 복귀, 정책 manifest와 sample root 제거를 검증한다.

### 준비와 테스트

- [ ] T081 `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`의 `GitItTests`에 App·Feature·Composition·필요 Domain test dependency와 shared scheme Test Action 연결을 추가한다
- [ ] T082 [P] [S2] `sources/Projects/App/Tests/GitIt/PolicyManifestTests.swift`에 개인정보 처리방침 `privacy-policy`/`1`, 서비스 이용 약관 `terms-of-service`/`1`, 승인 HTTPS URL·표시 이름·필수 여부 계약 테스트를 작성한다
- [ ] T083 [P] [S1] `sources/Projects/App/Tests/GitIt/AppRootFeatureTests.swift`에 restoring/onboarding/mainShell, logout/session invalidation(`SignOutResult` 처리 포함)의 tutorial 3페이지 복귀 및 retry 차단 테스트를 작성한다
- [ ] T084 [P] [S1] `sources/Projects/App/Tests/GitIt/GitItCompositionLifetimeTests.swift`에 production graph 앱 수명당 1회 생성과 Domain protocol 주입 테스트를 작성한다
- [ ] T085 [P] [S4] `sources/Projects/App/Tests/GitIt/GitItCompilationTests.swift`에 `Hello, world!`·sample root 부재와 production root 연결 검증을 추가한다

### 구현

- [ ] T086 [S2] `sources/Projects/App/Resources/Policies/policy-manifest.json`에 개인정보 처리방침 `privacy-policy`/`1`과 서비스 이용 약관 `terms-of-service`/`1`의 승인된 표시 이름·URL·필수 여부를 추가한다
- [ ] T087 [S2] `sources/Projects/App/Sources/PolicyManifestLoader.swift`에 번들 manifest를 Domain `PolicyDocument`로 검증해 읽는 loader를 구현한다
- [ ] T088 [S1] `sources/Projects/App/Sources/AppRootFeature.swift`에 restoring/onboarding/mainShell root와 onboarding delegate, logout/session invalidation 복귀 coordination을 구현한다
- [ ] T089 [S1] `sources/Projects/App/Sources/AppRootView.swift`에 root 상태별 onboarding 또는 MainShell을 정확히 하나만 표시하는 production View와 deterministic Preview를 구현한다
- [ ] T090 [S1] `sources/Projects/App/Sources/GitItApp.swift`에서 `AppComposition.live`를 앱 수명당 한 번 생성하고 policy manifest·bundle version과 Domain UseCase를 root store에 initializer 주입한다
- [ ] T091 [S1] `sources/Projects/App/Sources/ContentView.swift`의 `Hello, world!`와 sample root를 제거하고 `AppRootView` 진입점으로 교체한다
- [ ] T092 [S4] `sources/Projects/App/Project.swift`에 policy manifest resource와 App 테스트 실행에 필요한 현재 패키지 선언만 반영한다

### 정리와 패키지 검증

- [ ] T093 [no-write] `sources/Projects/App/`와 `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`를 대상으로 `make tuist` 후 App build/test를 실행하고 S1~S4 root·manifest·composition 수명 계약을 보고한다

**승인 게이트**: T081~T093의 변경 파일과 실제 검증 결과를 보고한 뒤 중단한다. 사용자가 전체 완료 검증을 명시적으로 승인한 뒤에만 아래 `[no-write]` 검증을 실행한다.

---

## 전체 완료 검증

**선행 조건**: App 패키지까지 구현·검증·결과 보고가 완료되고 사용자가 전체 검증을 승인해야 한다.

- [ ] T094 [no-write] `sources/`에 대해 `make tuist` 후 project build runner의 `build → compile → test`를 `iPhone 17 Pro Max` destination에서 순서대로 실행하고 실제 exit status를 기록한다
- [ ] T095 [no-write] `sources/Projects/`의 production import와 source를 검색해 Feature의 Data·Infrastructure·Composition 직접 import, production `@Dependency`, `Hello, world!`, sample root가 0건인지 검증한다
- [ ] T096 [no-write] `sources/Projects/Feature/Presentation/Onboarding/`의 모든 기능 View 파일 하단 Preview를 `iPhone 17 Pro Max`에서 렌더링하고 tutorial `779:33450`·`779:33529`·`779:33564`, 약관 전체 선택 `786:38332`, 분야 선택 `737:10367`, Career `737:10358`·`737:10349`를 비교해 일치·수정 완료·승인된 차이로 기록하며 Google 로그인 표현·개인정보 관련 명칭·분야 화면 닫기 표현·360×800 frame 차이는 명세 우선의 승인된 차이로 이유와 영향을 남긴다
- [ ] T097 [no-write] `sources/Projects/Feature/Presentation/Onboarding/`을 작은 지원 iPhone, 최대 Dynamic Type, VoiceOver, Reduce Motion에서 수동 검증하고 CTA 접근 불가와 색상 단독 정보 전달이 0건인지 기록한다
- [ ] T098 [no-write] `specs/016-onboarding-login-tutorial-app-integration/spec.md`의 S1 수용 조건을 fake composition launch 결과와 호출 횟수로 독립 검증한다
- [ ] T099 [no-write] `specs/016-onboarding-login-tutorial-app-integration/spec.md`의 S2 수용 조건을 tutorial·legal·sign-in reducer, 외부 브라우저 열기 요청 실패와 sign-in stale 응답 결과 및 `UserDefaultsStore` 기반 정책 동의 저장 수명(로그아웃 후 유지)으로 독립 검증한다
- [ ] T100 [no-write] `specs/016-onboarding-login-tutorial-app-integration/spec.md`의 S3 수용 조건을 curation 선택·back·submit·retry·MainShell 결과로 독립 검증한다
- [ ] T101 [no-write] `specs/016-onboarding-login-tutorial-app-integration/spec.md`의 S4 수용 조건을 Preview·Figma·접근성 결과로 독립 검증한다

## 의존성과 실행 순서

### 패키지 순서와 승인 게이트

1. Domain은 다른 프로젝트 내부 패키지에 의존하지 않으며 모든 기능 의미의 기반이다. 상태 조회
   타입(`AuthenticationOutcome`)과 액션 결과 타입(`SignInResult`·`SignOutResult`·
   `RestoreSessionResult`)의 분리도 이 단계에서 확정한다.
2. Infrastructure는 다른 프로젝트 내부 패키지에 의존하지 않으며 Domain과도 서로 의존하지
   않는다. 정책 동의 저장 수명 요건(FR-041)을 만족하는 `UserDefaultsStore`를 이 단계에서
   확정한다([research.md §3.1](./research.md)). 이미 확정된 Domain 우선 순서를 유지하기 위해
   그다음 단계로 배치했다.
3. Data는 Domain과 직접 의존하지 않지만 Composition이 두 경계를 변환하고 정책 동의 store가
   `UserDefaultsStore`를 소비하므로 Domain·Infrastructure 완료 뒤 구현한다.
4. Composition은 Domain·Data·Infrastructure를 소비하므로 세 패키지 완료 뒤 구현한다. 신규
   액션 결과 타입 매핑은 `AuthenticationRepositoryAdapter`와 `AuthenticationAssembly`에 반영한다.
5. UI는 앞선 패키지들과 독립이지만 Feature가 Domain과 UI를 함께 소비하므로 Feature 직전 기반으로 순서를 고정한다.
6. Feature는 Domain·UI를 소비하며 production 조립은 소비하지 않으므로 두 기반 완료 뒤 구현한다.
7. App은 Domain·Composition·Feature를 소비하므로 마지막 구현 패키지다.
8. 각 패키지 끝에서 변경 파일과 실제 검증 결과를 보고하고 사용자의 명시적 승인을 받은 뒤에만 다음 번호의 패키지로 진행한다.
9. 후속 패키지에서 선행 패키지 수정이 필요하면 구현을 중단하고 이 작업 목록의 소유권과 순서를 재생성한다.

### 변경 시나리오 완료 순서

- **S1**: Domain T001~T002·T004·T006~T007·T009·T013~T014·T017~T025 → Data T033~T034·T037~T038 → Composition T044·T046~T047·T049~T050·T054 → Feature T066·T070~T071·T074 → App T083~T084·T088~T091 → T098
- **S2**: Domain T003·T005·T008·T015~T016·T026 → Infrastructure T028~T032 → Data T035~T036·T039~T042 → Composition T045·T051~T052·T054 → UI T057·T060·T062 → Feature T067·T072·T075~T076 → App T082·T086~T087 → T099
- **S3**: Domain T010~T012 → Composition T048·T053 → UI T056·T059 → Feature T068·T073·T077~T078 → App root 연결 → T100
- **S4**: UI T058·T061·T063 → Feature T069·T074~T079 → App T085·T089·T092 → T096~T097·T101
- S1~S4는 관련된 모든 패키지와 승인 게이트가 끝난 뒤에만 독립 수용 완료로 판정한다.

### 현재 패키지 내부 병렬 실행 예시

- Domain 승인 후 T001~T010은 서로 다른 테스트 파일이므로 병렬 작성할 수 있다.
- Infrastructure 승인 후 T028~T029는 같은 파일의 서로 다른 테스트 케이스이므로 순차 작성하되, 두 테스트 모두 T030 구현보다 먼저 작성한다.
- Data 승인 후 T033~T036은 서로 다른 계약 테스트 파일이므로 병렬 작성할 수 있다.
- Composition 승인 후 T044~T048은 서로 다른 adapter 테스트 파일이므로 병렬 작성할 수 있다.
- UI 승인 후 T056~T058은 서로 다른 공용 컴포넌트 테스트 파일이므로 병렬 작성할 수 있다.
- Feature 승인 후 T066~T069 및 reducer 기반이 확정된 뒤 T074~T078은 각각 서로 다른 파일 범위에서 병렬 작업할 수 있다.
- App 승인 후 T082~T085는 서로 다른 테스트 파일이므로 병렬 작성할 수 있다.
- 서로 다른 패키지는 같은 의존 깊이여도 승인 게이트를 넘어 병렬 실행하지 않는다.

## 구현 전략

1. 첫 미완료 패키지인 Domain의 작업만 선택한다.
2. 테스트를 먼저 작성해 예상한 이유로 실패하는지 확인한 뒤 구현·정리·패키지 검증을 완료한다.
3. 변경 파일과 실제 검증 결과를 보고하고 다음 패키지 승인을 요청한 뒤 중단한다.
4. 명시적 승인 후 다음 패키지에서 같은 절차를 반복한다.
5. 최소 가치 범위는 S1이지만 Domain부터 App까지(Infrastructure 포함) 필요한 작업과 모든 패키지 승인 게이트를 유지한다.
6. 마지막 패키지 승인 뒤에만 전체 읽기 전용 검증과 S1~S4 독립 수용 검증을 실행한다.

## 참고

- 작업 ID는 실행 순서대로 T001~T101을 사용한다.
- 기존 미커밋 Domain/Data/Composition 변경(`CareerLevel.swift`, `MemberPosition.swift`,
  `MemberRepositoryAdapter.swift`, `AnswerDTOs.swift` 등)은 각 패키지 진입 시 diff를 다시
  확인하고 되돌리거나 덮어쓰지 않는다. `MemberRepositoryAdapter.swift`의 현재 미커밋 상태는
  optional 반환을 `MemberProfile`의 non-optional 필드에 대입해 컴파일이 깨지므로, T013(Domain)
  완료 뒤 T049(Composition)에서 정합화한다.
- `LoginResponseDTO.swift`(Data), `LocalOnboardingState.swift`(Domain),
  `LoginSessionRepositoryAdapter.swift`(Composition)의 현재 미커밋 상태는 이미 로그인 응답의
  `needsCuration`을 세션 record에 저장한다. T017·T023(Domain)은 이 기존 배관을 되돌리지 않고
  `SignInResult.success`가 이 값을 노출하도록만 확장하며, 별도 Data·Composition 작업을 새로
  추가하지 않는다.
- Infrastructure `UserDefaultsStore`(T030)는 완전히 새로운 파일이며 되돌리거나 보존해야 할
  기존 미커밋 상태가 없다. `sources/Projects/Infrastructure/Cache/InMemoryCache.swift`의
  제네릭 key-value API 스타일을 참고하되 영속 저장을 위해 `UserDefaults`를 사용한다.
- `docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md`와
  `tacit-knowledge.md`는 구현 작업이 아니며 전용 기록 스킬의 조건이 실제로 발생한 세션에서만
  별도로 추가한다.
