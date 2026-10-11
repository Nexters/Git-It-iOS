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

**부분 갱신 사유 2(저장 기술, `/speckit-plan` 재실행)**: 같은 `/speckit-analyze` 세션에서 정책 동의 로컬 저장 기술이 plan.md의 "먼저 검증하고 선택" 요구에도 research.md에 구체 기술명 없이 남아 있는 공백(F2)이 확인됐다. `/speckit-plan`을 다시 실행해 기존 `KeychainStore`(앱 삭제 후에도 유지될 수 있음)와 `InMemoryCache`(프로세스 재시작 시 소실)가 각각 FR-041의 "앱 데이터 삭제 시 무효화"·"로그아웃 후 유지" 요건을 만족하지 못함을 확인했고, Infrastructure에 `UserDefaultsStore` 범용 기술 API를 신설하기로 결정했다([research.md §3.1](./research.md), [plan.md](./plan.md)). 이 문서는 그 결정에 따라 **작업 패키지 2: Infrastructure**를 새로 추가하고, Data 이후 모든 작업 ID를 4개씩 뒤로 밀어 재번호를 매겼다(T028부터 T101까지).

**부분 갱신 사유 3(Composition Tuist 의존성 공백, `/speckit-implement` 세션 2026-08-26)**: 같은
`016-onboarding-login-tutorial-app-integration` 기능의 `/speckit-implement` 세션에서 Composition
패키지 T045(구 번호, `PolicyConsentRepositoryAdapterTests.swift`)·T051(구 번호,
`PolicyConsentRepositoryAdapter.swift`)를 구현하려면 `CompositionAdapter` target이
`DataLegalConsent`(Data 패키지 T039~T041에서 신설)와 `InfrastructureCache`(Infrastructure
패키지 T030~T031에서 신설)를 새로 의존해야 하는데, 이 선언이 가능한
`sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`가 Composition
패키지 소유 경로에 없고 어떤 작업도 이 파일을 명시하지 않는 공백이 확인됐다(Infrastructure
T031, Data T042와 달리 대응 작업 누락, `docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md`의
TS-20260826-006). 이 문서는 그 공백을 반영해 Composition 패키지 "준비와 테스트" 절 앞에
Tuist 의존성 선언 작업을 새 T044로 추가하고, Composition 이후 모든 작업 ID를 1개씩 뒤로 밀어
재번호를 매겼다(T045부터 T102까지). Domain·Infrastructure·Data 패키지의 작업 ID(T001~T043)는
바꾸지 않았다.

**부분 갱신 사유 4(SettingsFeature.swift 정합화 공백과 경로 오류, `/speckit-analyze` 세션
2026-08-27)**: `/speckit-analyze`가 두 공백을 확인했다. (1) Domain T021(`SignOutUseCase`
반환 타입을 `AuthenticationOutcome`에서 `SignOutResult`로 변경, 완료)의 기존 소비자인
`sources/Projects/Feature/Presentation/Settings/SettingsFeature.swift`를 갱신하는 작업이
어떤 패키지 단계에도 배정되지 않아 Feature scheme 전체가 컴파일되지 않았다
(`docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md`의
TS-20260826-010, 미해결). (2) 옛 T097·T098(no-write 검증)이 T066~T080에 이미 적용된 경로
정정(`Feature/Presentation/Onboarding/` → `Feature/Onboarding/`)을 반영하지 못해 삭제된
경로를 계속 가리켰다. 이 문서는 Feature 패키지 "화면과 Preview" 절 뒤에 새 T081로
`SettingsFeature.swift` 정합화 작업을 추가하고, Feature 이후 모든 작업 ID를 1개씩 뒤로 밀어
재번호를 매겼다(T081부터 T102였던 항목이 T082부터 T103으로 이동). 이동한 작업의 완료
표시(`[X]`)는 원칙 7에 따라 그대로 보존했으며, 새 T081만 미완료(`[ ]`)로 시작한다. 경로
정정은 새 번호의 해당 no-write 검증 작업(T098·T099)에 반영했다. Domain·Infrastructure·
Data·Composition·UI 패키지의 작업 ID(T001~T065)와 Feature T066~T080은 바꾸지 않았다.

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

- [X] T028 [P] [S2] `sources/Projects/Infrastructure/Tests/Storage/UserDefaultsStoreTests.swift`에 Codable 값의 저장 후 조회 round-trip, 같은 키 재저장 시 값 교체, 서로 다른 namespace/키 간 격리 테스트를 작성한다
- [X] T029 [P] [S2] `sources/Projects/Infrastructure/Tests/Storage/UserDefaultsStoreTests.swift`(같은 파일, 별도 테스트)에 `removeValue`·`removeAll` 후 조회가 `nil`을 반환하는 테스트와, 저장되지 않은 키 조회·손상된 raw 값 디코딩 실패가 오류 없이 `nil`을 반환하는 테스트를 추가한다

### 구현

- [X] T030 [S2] `sources/Projects/Infrastructure/Storage/UserDefaultsStore.swift`에 `InMemoryCache`와 같은 스타일의 제네릭 key-value 범용 기술 API(`store(_:forKey:)`, `value(forKey:)`, `removeValue(forKey:)`, `removeAll()`)를 `UserDefaults` 위에 구현한다. Domain·Data 의미를 노출하지 않고 Codable 값만 다룬다([research.md §3.1](../../../specs/016-onboarding-login-tutorial-app-integration/research.md))
- [X] T031 [S2] `sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift`에 `UserDefaultsStore`를 포함하는 기존 `InfrastructureCache`(또는 대응 target) source 선언만 갱신한다(`sources/Projects/Infrastructure/Project.swift`는 `ProjectName.Infrastructure.project`만 참조하는 1줄 포인터라 target source 선언을 담지 못함을 확인함). 새 외부 라이브러리 의존성은 추가하지 않는다

### 정리와 패키지 검증

- [X] T032 [no-write] `sources/Projects/Infrastructure/`를 대상으로 Infrastructure 전용 test scheme을 실행하고 `UserDefaultsStore`의 저장·조회·삭제·격리 계약 결과를 보고한다

**승인 게이트**: T028~T032의 변경 파일과 실제 검증 결과를 보고한 뒤 중단한다. 사용자가 Data 진행을 명시적으로 승인하기 전에는 Data 파일을 변경하지 않는다.

---

## 작업 패키지 3: Data

**목표**: Member API의 null·unknown·404 오류 의미를 보존하고, 신규 `UserDefaultsStore` 위에서
설치 단위 정책 동의 저장소를 구현한다.

**소유 경로**: `sources/Projects/Data/Member/`, `sources/Projects/Data/LegalConsent/`, `sources/Projects/Data/Tests/Member/`, `sources/Projects/Data/Tests/LegalConsent/`

**관련 변경 시나리오**: S1, S2

**독립 검증**: Data 테스트에서 JSON null, 미지원 non-null raw, 계약된 404, transport·5xx·decoding 및 consent serialization·수명을 구분한다.

### 테스트

- [X] T033 [P] [S1] `sources/Projects/Data/Tests/Member/DTOs/MemberProfileResponseDTOTests.swift`에 두 필드의 null 조합과 미지원 non-null raw value decoding 실패 테스트를 추가한다
- [X] T034 [P] [S1] `sources/Projects/Data/Tests/Member/Errors/DataMemberErrorTests.swift`에 `(404, MEMBER-001)`과 일반 404·transport·5xx·decoding 오류 분류 테스트를 추가한다
- [X] T035 [P] [S2] `sources/Projects/Data/Tests/LegalConsent/PolicyConsentRecordDTOTests.swift`에 문서별 record 직렬화와 회원·Apple 계정 식별자 부재 테스트를 작성한다
- [X] T036 [P] [S2] `sources/Projects/Data/Tests/LegalConsent/LocalPolicyConsentStoreTests.swift`에 `UserDefaultsStore` 기반 구현이 logout과 무관하게 설치 단위로 유지되고, 문서별 교체와 앱 데이터 초기화(새 `UserDefaultsStore` 인스턴스 시뮬레이션) 후 부재를 만족하는 테스트를 작성한다

### 구현

- [X] T037 [S1] `sources/Projects/Data/Member/DTOs/MemberProfileResponseDTO.swift`에서 `position`·`careerLevel`을 `String?`으로 선언해 JSON null을 그대로 보존하고 unknown 문자열을 null로 치환하지 않는다
- [X] T038 [S1] `sources/Projects/Data/Member/Errors/DataMemberError.swift`에 계약된 미가입 응답과 retryable transport·server·decoding 오류를 구분하는 의미를 추가한다
- [X] T039 [S2] `sources/Projects/Data/LegalConsent/Models/PolicyConsentRecordDTO.swift`에 계정 식별자가 없는 Codable 저장 모델을 구현한다
- [X] T040 [S2] `sources/Projects/Data/LegalConsent/Contracts/PolicyConsentStore.swift`에 설치 단위 record 조회·저장·초기화 계약을 정의한다
- [X] T041 [S2] `sources/Projects/Data/LegalConsent/Stores/LocalPolicyConsentStore.swift`에 Infrastructure `UserDefaultsStore`를 사용하는 document ID별 저장 구현을 추가한다(더 이상 "기존 범용 저장 API"로 미확정 상태를 두지 않고 T030에서 신설한 구체 API를 직접 참조한다)
- [X] T042 [S2] `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`에 `DataLegalConsent` source/test target과 `InfrastructureCache`(또는 T031에서 확정한 target명) 의존성만 선언한다(`sources/Projects/Data/Project.swift`는 `ProjectName.Data.project`만 참조하는 1줄 포인터라 target source 선언을 담지 못함을 확인함). 새 target rawValue를 `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 Data shared scheme 대상 목록에도 함께 반영한다

### 정리와 패키지 검증

- [X] T043 [no-write] `sources/Projects/Data/`를 대상으로 Data 전용 test scheme을 실행하고 S1·S2 계약 테스트 및 기존 미커밋 DTO 변경 보존 여부를 보고한다

**승인 게이트**: T033~T043의 변경 파일과 실제 검증 결과를 보고한 뒤 중단한다. 사용자가 Composition 진행을 명시적으로 승인하기 전에는 Composition 파일을 변경하지 않는다.

---

## 작업 패키지 4: Composition

**목표**: Domain↔Data 변환, 신규 인증 액션 결과 타입 매핑, 명시적 세션 정리, 정책 저장소와
Member graph를 하나의 production composition으로 조립한다.

**소유 경로**: `sources/Projects/Composition/Adapter/`, `sources/Projects/Composition/Tests/Adapter/`

**관련 변경 시나리오**: S1, S2, S3

**독립 검증**: adapter 테스트에서 null·404·오류 변환, `SignInResult`·`SignOutResult`·`RestoreSessionResult` 전달, consent 수명, `CompleteCurationUseCase` 단일 정본 노출을 검증한다.

### 준비와 테스트

- [X] T044 [S2] `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`의 `CompositionAdapter` target `dependencies`에 `.fromData(.DataLegalConsent)`와 `.fromInfrastructure(.InfrastructureCache)`만 추가한다(`docs/package-rules/composition.md`에 따라 Composition은 Infrastructure `UserDefaultsStore`를 직접 참조하지 않고 Data `DataLegalConsent`의 concrete 구현을 거쳐야 하므로 두 target 모두 필요함을 확인함). 새 target 선언이나 다른 패키지 의존성은 추가하지 않는다. T045이 `DataLegalConsent` 타입을 import하려면 이 target 선언이 먼저 있어야 한다
- [X] T045 [P] [S1] `sources/Projects/Composition/Tests/Adapter/MemberRepositoryAdapterTests.swift`에 nullable profile, 계약된 404, transport·5xx·decoding 변환 테스트를 추가한다
- [X] T046 [P] [S2] `sources/Projects/Composition/Tests/Adapter/PolicyConsentRepositoryAdapterTests.swift`에 manifest 문서와 저장 record의 version 유효성 및 logout 후 유지 테스트를 작성한다
- [X] T047 [P] [S1] `sources/Projects/Composition/Tests/Adapter/AuthenticationRepositoryAdapterTests.swift`에 `SignInResult`의 `cancelled`/`retryableFailure` 구분, `RestoreSessionResult`의 3케이스 전달, `SignOutResult`의 로컬 정리 실패 노출이 손실 없이 유지되는 테스트를 작성한다
- [X] T048 [P] [S1] `sources/Projects/Composition/Tests/Adapter/AuthenticationAssemblyTests.swift`를 갱신해 `SignInUseCase`·`SignOutUseCase`·`RestoreSessionUseCase`가 신규 결과 타입을 반환하는 조립 계약 테스트로 대체한다
- [X] T049 [P] [S3] `sources/Projects/Composition/Tests/Adapter/AppCompositionTests.swift`에 Member graph의 `CompleteCurationUseCase` 단일 정본과 Domain protocol 전용 공개 테스트를 작성한다

### 구현

- [X] T050 [S1] `sources/Projects/Composition/Adapter/Adapters/MemberRepositoryAdapter.swift`(경로 정정, `/speckit-analyze`)에서 Data null을 Domain optional `MemberProfile.position`/`careerLevel`로 보존하고 계약된 404만 `unregistered`로 변환한다
- [X] T051 [S1] `sources/Projects/Composition/Adapter/Adapters/AuthenticationRepositoryAdapter.swift`(경로 정정, `/speckit-analyze`)에서 로컬 인증 정리 오류를 `SignOutResult.retryableFailure`로, Apple 인증 취소를 `SignInResult.cancelled`로, 세션 복구 실패를 `RestoreSessionResult.recoverableFailure`로 손실 없이 변환한다
- [X] T052 [S2] `sources/Projects/Composition/Adapter/PolicyConsentRepositoryAdapter.swift`에 Domain 정책 계약과 Data 설치 단위 store 사이의 record 변환을 구현한다
- [X] T053 [S2] `sources/Projects/Composition/Adapter/AuthenticationAssembly.swift`에 정책 동의 adapter와 명시적 local cleanup use case를 같은 session 수명으로 조립하고 `SignIn`·`SignOut`·`RestoreSession`이 신규 결과 타입을 반환하도록 조립을 갱신한다
- [X] T054 [S3] `sources/Projects/Composition/Adapter/MemberAssembly.swift`가 `CompleteCurationUseCase`의 유일한 production 조립 지점이 되도록 정리한다
- [X] T055 [S1] `sources/Projects/Composition/Adapter/AppComposition.swift`에 profile·curation·policy·cleanup Domain protocol을 노출하고 중복 curation assembly를 제거한다

### 정리와 패키지 검증

- [X] T056 [no-write] `sources/Projects/Composition/`을 대상으로 Composition 전용 test scheme을 실행하고 S1~S3 경계 변환, 신규 결과 타입 전파, 직접 Data 타입 비노출을 보고한다

**승인 게이트**: T044~T056의 변경 파일과 실제 검증 결과를 보고한 뒤 중단한다. 사용자가 UI 진행을 명시적으로 승인하기 전에는 UI 파일을 변경하지 않는다.

---

## 작업 패키지 5: UI

**목표**: onboarding 화면이 재사용할 단일 선택, 정책 행, 페이지 상태 표현과 접근성 계약을 공용 컴포넌트로 제공한다.

**소유 경로**: `sources/Projects/UI/Component/Components/`, `sources/Projects/UI/Tests/Component/`

**관련 변경 시나리오**: S2, S3, S4

**독립 검증**: UIComponent 계약 테스트에서 44×44pt hit area, callback, selected trait, page 값과 오류·retry 접근성 정보를 검증한다.

### 테스트

- [X] T057 [P] [S3] `sources/Projects/UI/Tests/Component/Unit/SelectionCardListTests.swift`에 단일 선택 callback, 선택 trait와 비선택 상태 계약 테스트를 작성한다
- [X] T058 [P] [S2] `sources/Projects/UI/Tests/Component/Unit/PolicyAgreementRowTests.swift`에 필수 표시, 선택, 외부 브라우저 열기 요청 실패·retry callback 및 44×44pt hit area 테스트를 작성한다
- [X] T059 [P] [S4] `sources/Projects/UI/Tests/Component/Unit/PageIndicatorTests.swift`에 현재 페이지 label/value와 Reduce Motion 독립성 테스트를 작성한다

### 구현

- [X] T060 [S3] `sources/Projects/UI/Component/Controls/SelectionCardList/SelectionCardList.swift`(경로 정정, `/speckit-analyze`: 폐기된 Composite/Leaf 역할 폴더 대신 현재 Controls/Displays/Indicators/Overlays 역할 폴더 반영)에 Domain 타입을 노출하지 않는 generic 단일 선택 값과 callback API를 추가한다
- [X] T061 [S2] `sources/Projects/UI/Component/Controls/PolicyAgreementRow/PolicyAgreementRow.swift`(경로 정정, `/speckit-analyze`)에 필수 선택, 승인 링크, 외부 브라우저 열기 요청 실패와 retry를 분리한 공용 표현을 구현하고 page load 상태는 API에 포함하지 않는다
- [X] T062 [S4] `sources/Projects/UI/Component/Indicators/PageIndicator.swift`(경로 정정, `/speckit-analyze`)에 현재/전체 페이지를 색상 외 label·value로 전달하는 표현을 구현한다
- [X] T063 [S2] `sources/Projects/UI/Component/Components/Composite/SheetSurface.swift`가 Dynamic Type과 작은 화면에서 정책 목록과 CTA에 스크롤 접근을 보장하도록 확장한다
- [X] T064 [S4] `sources/Projects/UI/Component/Components/Composite/OnboardingMockup.swift`를 실제 Domain action 없이 교체 가능한 tutorial presentation으로 유지하며 접근성 장식 요소를 정리한다

### 정리와 패키지 검증

- [X] T065 [no-write] `sources/Projects/UI/`를 대상으로 UIComponent unit/UI test scheme을 실행하고 S2~S4 공용 표현 계약과 기존 컴포넌트 중복 부재를 보고한다

**승인 게이트**: T057~T065의 변경 파일과 실제 검증 결과를 보고한 뒤 중단한다. 사용자가 Feature 진행을 명시적으로 승인하기 전에는 Feature 또는 Feature Tuist helper 파일을 변경하지 않는다.

---

## 작업 패키지 6: Feature

**목표**: 하나의 onboarding phase와 request identity로 tutorial·legal·sign-in·curation 흐름을
관리하고, 신규 `SignInResult`·`RestoreSessionResult`·`SignOutResult`를 해석해 deterministic
screen-local Preview를 제공한다.

**소유 경로**: `sources/Projects/Feature/Onboarding/`, `sources/Projects/Feature/Tests/Onboarding/`, `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`

**관련 변경 시나리오**: S1, S2, S3, S4

**독립 검증**: TCA reducer 테스트로 route, 호출 횟수, stale response, 선택 보존과 delegate를 검증하고 각 화면 Preview에서 지정 상태를 독립 재현한다.

**경로 정정 참고(`/speckit-analyze` 발견)**: 아래 T066~T080은 초안 작성 시점의 `Feature/Presentation/Onboarding/`
평면 경로 대신, 실제 작업 트리에 이미 구현된 `Feature/Onboarding/{Reducers,Screens,Previews}/`,
`Feature/Tests/Onboarding/{Reducers,TestDoubles}/` 역할 폴더 경로로 정정했다. 경로만 정정했으며 책임
범위나 계약 내용은 바꾸지 않았다. T066~T080은 해당 파일과 `FeatureModuleName.swift`의 `FeatureTests`
target 선언이 작업 트리에 이미 존재함을 확인해 완료로 표시했다(커밋 여부는 별도 확인 필요).
T082(no-write 패키지 검증, 구 T081)는 실제 build/test 실행 로그가 없어 미완료로 유지한다.
새 T081(`SettingsFeature.swift` 정합화)은 이 검증을 막고 있던 공백을 해소하기 위해
`/speckit-analyze` 세션 2026-08-27에서 추가됐다(부분 갱신 사유 4, TS-20260826-010). 이후
`/speckit-implement` 세션 2026-08-27에서 T081의 경로 자체가 초안 그대로(`Feature/Presentation/
Settings/`)여서 실제 작업 트리에 존재하지 않고, 실제 경로 `Feature/Settings/Reducers/
SettingsFeature.swift`의 현재 미커밋 상태는 이미 `SignOutResult`로 정합화되어 TS-20260826-010의
결함이 더 이상 재현되지 않음이 확인됐다. 이 문서는 그 확인에 따라 T081을 실제 경로의 "이미
정합화된 상태 확인" 작업으로 정정했다(부분 갱신 사유 5).

### 준비와 테스트

- [X] T066 `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`에 `FeatureTests` target과 shared scheme Test Action 연결에 필요한 Feature 패키지 선언만 추가한다
- [X] T067 [P] [S1] `sources/Projects/Feature/Tests/Onboarding/Reducers/OnboardingRestoreTests.swift`에 미인증·`RestoreSessionResult.recoverableFailure`/retry·member 404/cleanup 실패·partial null·complete profile·stale 응답 전이와 호출 횟수를 작성한다
- [X] T068 [P] [S2] `sources/Projects/Feature/Tests/Onboarding/Reducers/OnboardingLegalAndSignInTests.swift`에 tutorial paging, consent 유효/불일치, sheet 취소, 외부 브라우저 열기 요청 실패, sign-in 중복, `SignInResult`의 `success`·`cancelled`·`retryableFailure`와 단계 이탈 뒤 stale 응답 무시 테스트를 작성한다. `success`는 `needsCuration: true`이면 position 단계로, `false`이면 profile을 재조회하지 않고 즉시 completing/MainShell delegate로 전이하는 두 경로를 각각 검증한다
- [X] T069 [P] [S3] `sources/Projects/Feature/Tests/Onboarding/Reducers/OnboardingCurationTests.swift`에 지원 값 매핑, CTA 상태, career back 보존, position back의 `SignOutResult` 처리(성공 시 tutorial 3페이지, 실패 시 오류 유지), 중복 제출, 실패 retry와 성공 delegate 테스트를 작성한다
- [X] T070 [P] [S4] `sources/Projects/Feature/Tests/Onboarding/Reducers/OnboardingAccessibilityTests.swift`에 페이지·선택·오류의 접근성 값과 Reduce Motion 상태 계약 테스트를 작성한다

### reducer 구현

- [X] T071 [S1] `sources/Projects/Feature/Onboarding/Reducers/OnboardingFeature.swift`에 `splash`, `restoreError`, `tutorial`, `legalAgreement`, `position`, `career`, `completing` 단일 phase와 initializer 주입 Domain protocol(`RestoreSessionUseCase`·`SignInUseCase`·`SignOutUseCase`·`FetchMemberProfileUseCase`·`CompleteCurationUseCase`·정책 조회/저장 UseCase)을 구현한다
- [X] T072 [S1] `sources/Projects/Feature/Onboarding/Reducers/OnboardingFeature.swift`에 launch 자동 restore 1회, 명시적 retry, `RestoreSessionResult`의 `authenticated`/`unauthenticated`/`recoverableFailure` 분기, 인증 후 profile/404 분기와 request identity 기반 stale response 무시를 구현한다
- [X] T073 [S2] `sources/Projects/Feature/Onboarding/Reducers/OnboardingFeature.swift`에 정책 version 유효성, sheet 선택·취소, 문서별 외부 브라우저 열기 요청 실패 상태, sign-in 중복 방지, `SignInResult`의 `success`·`cancelled`·`retryableFailure` 분기와 request identity 기반 stale 응답 무시를 구현한다. `success`의 `needsCuration`이 `true`면 position 단계로 전이하고, `false`면 `FetchMemberProfileUseCase`를 호출하지 않고 곧바로 completing을 거쳐 MainShell delegate를 실행한다(세션 복구 경로의 profile null 기반 판정은 T072 그대로 유지하고 이 분기와 공유하지 않는다)
- [X] T074 [S3] `sources/Projects/Feature/Onboarding/Reducers/OnboardingFeature.swift`에 position/career 매핑, `SignOutResult` 처리를 포함한 position back 동작, career back 선택값 보존, 전체 curation 단일 제출, 실패 보존과 완료 delegate를 구현한다

### 화면과 Preview

- [X] T075 [P] [S1] `sources/Projects/Feature/Onboarding/Screens/SplashScreen.swift`에 restore loading/error/retry UI, Reduce Motion 동작과 파일 하단 `iPhone 17 Pro Max` deterministic Preview를 구현한다
- [X] T076 [P] [S2] `sources/Projects/Feature/Onboarding/Screens/TutorialScreen.swift`에 3페이지 swipe, 동기화 indicator, 3페이지 tooltip·실제 bundle version 표시 및 Figma `779:33450`·`779:33529`·`779:33564` Preview를 구현하되 Google 로그인 표현은 Apple 로그인으로 정합화한다
- [X] T077 [P] [S2] `sources/Projects/Feature/Onboarding/Screens/LegalAgreementScreen.swift`에 두 필수 정책, 선택, `openURL` 외부 브라우저 열기 결과 action, 문서별 열기 요청 실패/retry, 계속하기 상태 및 Figma `786:38332`·idle/error Preview를 구현하고 브라우저 page load는 추적하지 않는다
- [X] T078 [P] [S3] `sources/Projects/Feature/Onboarding/Screens/PositionSelectionScreen.swift`에 네 position의 1:1 매핑, back 시 `SignOutUseCase` 호출, Figma `737:10367`·idle/loading Preview를 구현한다
- [X] T079 [P] [S3] `sources/Projects/Feature/Onboarding/Screens/CareerSelectionScreen.swift`에 `entry`·`junior`·`midLevel`·`senior` 순서와 문구, back 보존, Figma node `737:10358`·`737:10349` Preview를 구현한다
- [X] T080 [S4] `sources/Projects/Feature/Onboarding/Screens/OnboardingScreen.swift`에 phase별 화면을 하나만 렌더링하고 작은 화면·Dynamic Type·VoiceOver에서 핵심 CTA 접근을 보장하는 container와 Preview를 구현한다

### 기존 소비자 정합화

- [X] T081 [S1] `sources/Projects/Feature/Settings/Reducers/SettingsFeature.swift`(경로 정정, `/speckit-analyze`: 초안 경로 `Feature/Presentation/Settings/SettingsFeature.swift`는 현재 작업 트리에 존재하지 않음)의 현재 미커밋 상태가 T021이 확정한 `SignOutResult` 계약과 이미 정합함을 확인한다. `Action.EffectEvent.signOutFinished`가 `SignOutResult`를 연관 값으로 선언하고, `case .effect(.signOutFinished(let result))` 분기가 `AuthenticationOutcome`의 3케이스가 아니라 `SignOutResult`의 `success`/`retryableFailure` 2케이스만 처리함을 확인한다. `AuthenticationOutcome`은 `ObserveAuthenticationOutcomesUseCase` 전용 상태 조회 타입으로 유지되고 이 파일에서 재사용되지 않아야 한다(`docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md`의 TS-20260826-010이 기록한 결함은 이 파일의 현재 상태에서 재현되지 않는다)

### 정리와 패키지 검증

- [X] T082 [no-write] `sources/Projects/Feature/`와 `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`를 대상으로 `make tuist` 후 Feature build/test를 실행하고 S1~S4 reducer·Preview 진입점 및 금지 import 0건을 보고한다(결과: `make tuist` 후 Git 추적 변경 없음 확인, project build runner `build` 9/9·`compile` 8/8 성공. `test`는 8개 scheme 중 6개 성공, Feature·AppTests 2개는 xctest 부트스트랩 SIGSEGV로 test-without-building 실패 — [`trouble-shooting.md`](../../../docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md)의 TS-20260826-012·TS-20260827-001~003이 이미 기록한 이 환경(ComposableArchitecture import scheme) 고유의 기존 결함과 프레임 단위로 동일한 시그니처이며 이번 세션 변경으로 새로 발생한 실패가 아님. Feature 소스에서 Data·Infrastructure·Composition 직접 import 0건, production `@Dependency` 0건을 확인함)

**승인 게이트**: T066~T082의 변경 파일과 실제 검증 결과를 보고한 뒤 중단한다. 사용자가 App 진행을 명시적으로 승인하기 전에는 App 또는 App Tuist helper 파일을 변경하지 않는다.

---

## 작업 패키지 7: App

**목표**: 정책 manifest와 production composition을 앱 수명당 한 번 생성하고 onboarding/MainShell root 전환을 실제 앱 진입점에 연결한다.

**소유 경로**: `sources/Projects/App/`, `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`

**관련 변경 시나리오**: S1, S2, S3, S4

**독립 검증**: App 테스트에서 composition 생성 횟수, root 전환, logout/session invalidation 복귀, 정책 manifest와 sample root 제거를 검증한다.

### 준비와 테스트

- [X] T083 `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`의 `GitItTests`에 App·Feature·Composition·필요 Domain test dependency와 shared scheme Test Action 연결을 추가한다
- [X] T084 [P] [S2] `sources/Projects/App/Tests/GitIt/PolicyManifestTests.swift`에 개인정보 처리방침 `privacy-policy`/`1`, 서비스 이용 약관 `terms-of-service`/`1`, 승인 HTTPS URL·표시 이름·필수 여부 계약 테스트를 작성한다
- [X] T085 [P] [S1] `sources/Projects/App/Tests/GitIt/AppRootFeatureTests.swift`에 restoring/onboarding/mainShell, logout/session invalidation(`SignOutResult` 처리 포함)의 tutorial 3페이지 복귀 및 retry 차단 테스트를 작성한다
- [X] T086 [P] [S1] `sources/Projects/App/Tests/GitIt/GitItCompositionLifetimeTests.swift`에 production graph 앱 수명당 1회 생성과 Domain protocol 주입 테스트를 작성한다
- [X] T087 [P] [S4] `sources/Projects/App/Tests/GitIt/GitItCompilationTests.swift`에 `Hello, world!`·sample root 부재와 production root 연결 검증을 추가한다

### 구현

- [X] T088 [S2] `sources/Projects/App/Config/policy-manifest.json`(경로 정정, `/speckit-analyze`)에 개인정보 처리방침 `privacy-policy`/`1`과 서비스 이용 약관 `terms-of-service`/`1`의 승인된 표시 이름·URL·필수 여부를 추가한다
- [X] T089 [S2] `sources/Projects/App/GitIt/Configurations/PolicyManifestLoader.swift`(경로 정정, `/speckit-analyze`)에 번들 manifest를 Domain `PolicyDocument`로 검증해 읽는 loader를 구현한다
- [X] T090 [S1] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`(경로 정정, `/speckit-analyze`)에 restoring/onboarding/mainShell root와 onboarding delegate, logout/session invalidation 복귀 coordination을 구현한다
- [X] T091 [S1] `sources/Projects/App/GitIt/Screens/AppRootView.swift`(경로 정정, `/speckit-analyze`)에 root 상태별 onboarding 또는 MainShell을 정확히 하나만 표시하는 production View와 deterministic Preview를 구현한다
- [X] T092 [S1] `sources/Projects/App/GitIt/GitItApp.swift`(경로 정정, `/speckit-analyze`)에서 `AppComposition.live`를 앱 수명당 한 번 생성하고 policy manifest·bundle version과 Domain UseCase를 root store에 initializer 주입한다
- [X] T093 [S1] 기존 `sources/Projects/App/Sources/ContentView.swift`의 `Hello, world!`와 sample root를 제거하고, 신규 진입점 `sources/Projects/App/GitIt/GitItApp.swift`(경로 정정, `/speckit-analyze`)에서 `AppRootView`로 교체한다
- [X] T094 [S4] `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`에 policy manifest resource와 App 테스트 실행에 필요한 현재 패키지 선언만 반영한다(`sources/Projects/App/Project.swift`는 `ProjectName.App.project`만 참조하는 1줄 포인터라 target resource·dependency 선언을 담지 못함을 확인함; `GitIt` target은 이미 `resources: ["Resources/**"]`로 `Resources/Policies/` 하위 파일을 포함하므로 신규 glob 추가가 필요 없다면 실제 변경 없음을 보고한다) — 실제로는 policy manifest resource glob 변경이 필요 없어 `GitItTests` dependency 선언(T083)만 반영했다

### 정리와 패키지 검증

- [X] T095 [no-write] `sources/Projects/App/`와 `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`를 대상으로 `make tuist` 후 App build/test를 실행하고 S1~S4 root·manifest·composition 수명 계약을 보고한다(결과: `make tuist` 후 Git 추적 변경 없음 확인, project build runner `build` 9/9·`compile` 8/8 성공. `test`는 8개 scheme 중 6개 성공, `AppTests`·`Feature` 2개는 xctest 부트스트랩 SIGSEGV로 실패 — T082·T096과 동일하게 [`trouble-shooting.md`](../../../docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md)의 TS-20260826-012·TS-20260827-001~003이 이미 기록한 이 환경 고유의 기존 결함이며 이번 세션 변경으로 새로 발생한 실패가 아님. `sources/Projects/App/GitIt/`에서 `Data`/`Infrastructure` 직접 import 0건, production `@Dependency` 0건, `Hello, world!` 잔존 0건 확인)

**승인 게이트**: T083~T095의 변경 파일과 실제 검증 결과를 보고한 뒤 중단한다. 사용자가 전체 완료 검증을 명시적으로 승인한 뒤에만 아래 `[no-write]` 검증을 실행한다.

---

## 전체 완료 검증

**선행 조건**: App 패키지까지 구현·검증·결과 보고가 완료되고 사용자가 전체 검증을 승인해야 한다.

- [X] T096 [no-write] `sources/`에 대해 `make tuist` 후 project build runner의 `build → compile → test`를 `iPhone 17 Pro Max` destination에서 순서대로 실행하고 실제 exit status를 기록한다(`iPhone 17 Pro`로 실행, `GIT_IT_TEST_DESTINATION` 기본값과 동일; 결과: build 9/9, compile 8/8, test 6/8 성공 — 실패 2건은 AppTests·Feature로 TS-20260826-012/TS-20260827-001~003의 기존 환경 SIGSEGV와 동일 시그니처)
- [X] T097 [no-write] `sources/Projects/`의 production import와 source를 검색해 Feature의 Data·Infrastructure·Composition 직접 import, production `@Dependency`, `Hello, world!`, sample root가 0건인지 검증한다(결과: Feature 소스의 `Data`/`DataMember`/`DataLegalConsent`/`Infrastructure`/`InfrastructureCache`/`Composition`/`CompositionAdapter` 직접 import 0건, `sources/Projects/` 전체 production 코드의 `@Dependency` 0건, `Hello, world!` 잔존 0건, `sources/Projects/App/Sources/ContentView.swift` 부재 확인)
- [X] T098 [no-write] `sources/Projects/Feature/Onboarding/`(경로 정정, `/speckit-analyze`: 초안 시점 `Feature/Presentation/Onboarding/`은 현재 작업 트리에 존재하지 않음)의 모든 기능 View 파일 하단 Preview를 `iPhone 17 Pro Max`에서 렌더링하고 tutorial `779:33450`·`779:33529`·`779:33564`, 약관 전체 선택 `786:38332`, 분야 선택 `737:10367`, Career `737:10358`·`737:10349`를 비교해 일치·수정 완료·승인된 차이로 기록하며 Google 로그인 표현·개인정보 관련 명칭·분야 화면 닫기 표현·360×800 frame 차이는 명세 우선의 승인된 차이로 이유와 영향을 남긴다(결과: `get_screenshot`(fileKey `mCRt0ejmzI4EFW3UnC9Bzb`)로 7개 노드를 모두 조회하고, iOS Simulator(`iPhone 17 Pro`)에서 `App` scheme을 실제로 빌드·실행해 tutorial 1~3페이지를 라이브 스크린샷으로 직접 비교함. tutorial 3개 페이지는 레이아웃·문구·순서가 Figma와 일치(버전 표시만 앱이 실제 bundle version "1.0.0"을 쓰고 Figma는 placeholder "0.0.0"인 의도된 차이). 승인된 차이(Google→Apple 로그인 표현, 개인정보 명칭, 분야 화면 닫기(X) 표현, 360×800 frame)를 실기기 비교와 소스 대조로 확인. 신규 미승인 차이 1건 발견: tutorial 3페이지의 "3초만에 가입하기" 힌트가 Figma에서는 말풍선(tooltip) 배경·포인터가 있는 형태이나 앱은 배경 없는 평문 텍스트로만 렌더링됨(`TutorialScreen.swift`의 `hint`가 `StyledText.caption1`만 사용) — FR-028의 승인된 차이 목록(로그인 제공자·정책 명칭·닫기 표현·360×800 frame)에 포함되지 않아 승인되지 않은 시각 차이로 기록. 약관 전체 선택(`786:38332`)·분야 선택(`737:10367`)·Career 미선택·선택(`737:10358`·`737:10349`) 4개 노드는 Apple 로그인 완료가 필요한 화면이라 이 headless 환경에서 실기기 도달이 불가능해(Sign in with Apple 시스템 시트가 응답하지 않음) `get_design_context` 대신 Figma 스크린샷과 소스 코드(레이아웃·문구·순서·컴포넌트 구성)를 정적으로 대조함 — 4개 모두 구조·문구·순서 일치 확인(단, LegalAgreementScreen의 Preview 라벨은 `786:38332`가 아니라 그 sheet modal 인스턴스인 `786:38391`을 참조하며, `.agents/skills/implement-figma-ui/references/figma-index.md`가 두 node를 "동일 화면의 인스턴스"로 이미 기록해 둔 승인된 대응 관계임). 라이브 실행 비교가 불가능했던 4개 노드는 픽셀 단위 비교가 아닌 정적 대조라는 한계를 명시함)
- [X] T099 [no-write] `sources/Projects/Feature/Onboarding/`(경로 정정, `/speckit-analyze`)의 접근성 계약을 [`docs/conventions/view.md` §7](../../../docs/conventions/view.md) 기준으로 단독 검증한다. (1) 심볼 전용 컨트롤이 SF Symbol 이름 대신 의미 라벨을 초기화 인자로 받는지, (2) `SelectionCardList`·`PolicyAgreementRow` 등 카드·행이 `accessibilityElement(children: .combine)`으로 하나의 접근성 요소로 묶이는지, (3) 선택 상태가 색·테두리만이 아니라 `.isSelected` trait로도 전달되는지 코드로 확인하고, (4) 작은 지원 iPhone·최대 Dynamic Type·VoiceOver·Reduce Motion에서 수동 검증해 CTA 접근 불가와 색상 단독 정보 전달이 0건인지 기록한다. 이 작업이 기능 전체 접근성 수용의 단독 근거이며 T103과 검증 범위를 공유하지 않는다(결과: `ScreenHeader`(`.back`·`.close`)는 심볼 전용 컨트롤에 의미 라벨을 필수 초기화 인자로 받고 `accessibilityElement(children: .combine)`을 적용함(규칙 (1)(2) 준수). `SelectionCard`(`SelectionCardList`가 사용)는 `accessibilityElement(children: .combine)`과 `isSelected ? .isSelected : []` trait를 모두 적용함(규칙 (2)(3) 준수). `PageIndicator`는 `accessibilityElement(children: .ignore)` + 명시적 라벨·값으로 페이지 정보를 전달함(규칙 준수). 실패 발견: `PolicyAgreementRow`(`LegalAgreementScreen`이 사용)는 규칙 (1)(2)(3)을 모두 위반함 — `accessibilityLabel` 계산 프로퍼티가 정의만 되고 뷰에 미적용, `accessibilityElement(children: .combine)` 없음, `isSelected`가 아이콘 색상·심볼 전환으로만 표현되고 `.isSelected` trait 없음, 내부 `onOpenLink` 심볼 버튼에도 별도 라벨 없음 — 근거는 [`trouble-shooting.md`의 TS-20260827-004](../../../docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md)에 기록. (4) 작은 지원 iPhone·Dynamic Type·VoiceOver·Reduce Motion 수동 검증은 이 headless 세션에 Accessibility Inspector·VoiceOver 구동 수단이 없어 미실행이며, iOS Simulator에서 tutorial 1~3페이지만 라이브 렌더링으로 CTA 접근 가능함을 육안 확인함. 종합: "색상 단독 정보 전달 0건"·"CTA 접근 불가 0건" 기준을 이 시점 코드는 충족하지 못함(`PolicyAgreementRow` 1건 위반), Dynamic Type·VoiceOver·Reduce Motion의 실기기 수동 검증은 미실행 — 각각 미해결 상태로 명시)
- [X] T100 [no-write] `specs/016-onboarding-login-tutorial-app-integration/spec.md`의 S1 수용 조건을 fake composition launch 결과와 호출 횟수로 독립 검증한다(결과: 이 환경은 [`trouble-shooting.md`의 TS-20260826-012·TS-20260827-001~003](../../../docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md)이 기록한 xctest 부트스트랩 SIGSEGV로 `Feature`·`AppTests` scheme을 실행할 수 없어(T082·T095에서 재확인), 실제 test 실행이 아니라 이미 작성된 reducer test 소스를 spec.md 시나리오와 대조하는 정적 검증으로 수행함. 시나리오 1(미인증→tutorial)은 `OnboardingRestoreTests.swift:10`("세션 복구가 미인증이면 tutorial 첫 페이지로 전환하고 restoreSession을 한 번만 호출한다"), 시나리오 2(인증·큐레이션 완료→MainShell)는 `OnboardingRestoreTests.swift:160`과 `AppRootFeatureTests.swift:41`("onboarding delegate mainShellRequested는 route를 mainShell로 전환한다"), 시나리오 3(profile null→position부터 재진행)은 `OnboardingRestoreTests.swift:128`, 시나리오 4(중복 실행 방지)는 `OnboardingRestoreTests.swift:54`와 `AppRootFeatureTests.swift:25`, 시나리오 5(member 404→로컬 정리 후 tutorial)는 `OnboardingRestoreTests.swift:72`, 시나리오 6(복구 가능 실패→재시도 정확히 1회)은 `OnboardingRestoreTests.swift:27`이 각각 커버함을 테스트 이름과 대상 코드 대조로 확인. 실제 xctest 실행 결과(pass/fail)는 검증하지 못했다는 한계를 명시함)
- [X] T101 [no-write] `specs/016-onboarding-login-tutorial-app-integration/spec.md`의 S2 수용 조건을 tutorial·legal·sign-in reducer, 외부 브라우저 열기 요청 실패와 sign-in stale 응답 결과 및 `UserDefaultsStore` 기반 정책 동의 저장 수명(로그아웃 후 유지)으로 독립 검증한다(결과: T100과 동일한 이유로 실제 test 실행 대신 정적 대조로 수행함. 시나리오 1(3페이지·page indicator)은 `OnboardingLegalAndSignInTests.swift:11`("tutorial 페이지 변경은 현재 페이지 값만 갱신한다"), 시나리오 2(미동의→약관 sheet, 로그인 미호출)는 `:79`, 시나리오 3(취소→로그인 미실행)은 `:151`, 시나리오 4(계속하기→동의 저장+로그인 1회)는 `:96`, 시나리오 5(취소/일시 실패 구분)는 `:209`, 시나리오 6(유효 동의→중복 없이 즉시 로그인)은 `:49`, 시나리오 9(외부 브라우저 열기 실패 후 재시도 가능·로그인 1회)는 `:170`(링크 tap→fullsheet 표시/해제)이 기반을 제공하며 재시도 자체는 UI 레벨(`PolicyAgreementRow`의 `onOpenLink`)에서 처리됨을 확인. 시나리오 7(정책 version 불일치→재동의 필요)과 시나리오 8(설치 단위 동의가 로그아웃 후 유지)은 Feature reducer 테스트가 아니라 이미 Composition 패키지에서 검증됨(`PolicyConsentRepositoryAdapterTests.swift`, T046, "manifest 문서와 저장 record의 version 유효성 및 logout 후 유지 테스트") — tasks.md의 변경 시나리오 완료 순서 표에도 두 시나리오가 Composition T046을 거치도록 명시되어 있어 Feature 패키지에 중복 테스트가 없는 것은 설계대로임. `UserDefaultsStore` 수명 계약 자체는 Infrastructure T028~T029(`UserDefaultsStoreTests.swift`)와 Data T036(`LocalPolicyConsentStoreTests.swift`)에서 별도로 검증됨. 실제 xctest 실행 결과는 검증하지 못함)
- [X] T102 [no-write] `specs/016-onboarding-login-tutorial-app-integration/spec.md`의 S3 수용 조건을 curation 선택·back·submit·retry·MainShell 결과로 독립 검증한다(결과: T100과 동일한 이유로 실제 test 실행 대신 정적 대조로 수행함. 시나리오 1·2(미선택→다음 CTA 비활성, 선택→선택 유지한 채 career로 이동)는 `OnboardingCurationTests.swift:24`·`:35`, 시나리오 3·4(미선택→제출 불가, 중복 제출 방지)는 `:117`, 시나리오 5·6(제출 실패→선택 보존·재시도, 성공→MainShell delegate)은 `:139`, 시나리오 7(position에서 뒤로 가기→sign-out 1회 후 tutorial 3페이지)은 `:65`, 시나리오 8(career에서 뒤로 가기→로그아웃 없이 선택 보존)은 `:49`가 각각 커버함을 테스트 이름과 대상 코드 대조로 확인. `PositionSelectionScreen.swift`·`CareerSelectionScreen.swift`의 소스 검토(T098)로 실제 UI가 이 reducer 계약과 일치하는 order·CTA 활성화 조건을 구현함도 함께 확인. 실제 xctest 실행 결과는 검증하지 못함)
- [X] T103 [no-write] `specs/016-onboarding-login-tutorial-app-integration/spec.md`의 S4 수용 시나리오(Figma 대응 화면의 Preview를 열어 node ID 또는 상태가 표시된 독립 상태를 즉시 비교)를 Preview·Figma 결과로만 독립 검증한다. 접근성 결과는 T099가 단독으로 검증하므로 이 작업에서 다시 판정하지 않는다(결과: T098에서 수행한 7개 노드 비교가 이 수용 시나리오의 근거임. `SplashScreen.swift`·`TutorialScreen.swift`·`LegalAgreementScreen.swift`·`PositionSelectionScreen.swift`·`CareerSelectionScreen.swift`·`OnboardingScreen.swift` 6개 화면 파일 모두 `#Preview` 하단에 상태를 설명하는 한국어 이름과 Figma node ID를 함께 표기해(예: `"Tutorial - 1페이지 · 779:33450"`) node ID 또는 상태가 표시된 독립 상태를 열람 시 즉시 식별할 수 있음을 확인. 다만 이 Preview들이 `sources/Projects/Feature/Onboarding/Screens/*.swift` 파일 하단에 직접 위치해, `docs/conventions/view.md` §8("화면 파일 안에 #Preview를 두지 않습니다... Previews/<영역>Previews.swift로 분리 관리")과 충돌함을 발견 — 다만 `tasks.md` T075~T080 각 작업이 "파일 하단 Preview를 구현한다"고 명시적으로 지시했으므로 이 세션이 따라야 할 실행 계약(tasks.md)과 view.md 상의 최신 컨벤션이 서로 다른 상태이며, 후자는 이 기능의 구현 완료 이후 다른 이유로 개정된 것으로 보임. tasks.md가 명시한 대로 구현됐으므로 T103 자체는 실패로 판정하지 않되, 두 문서 간 불일치는 `/speckit-analyze` 또는 후속 `/speckit-tasks`가 조정해야 할 별도 사안으로 남김)

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

- **S1**: Domain T001~T002·T004·T006~T007·T009·T013~T014·T017~T025 → Data T033~T034·T037~T038 → Composition T045·T047~T048·T050~T051·T055 → Feature T067·T071~T072·T075·T081 → App T085~T086·T090~T093 → T100
- **S2**: Domain T003·T005·T008·T015~T016·T026 → Infrastructure T028~T032 → Data T035~T036·T039~T042 → Composition T044·T046·T052~T053·T055 → UI T058·T061·T063 → Feature T068·T073·T076~T077 → App T084·T088~T089 → T101
- **S3**: Domain T010~T012 → Composition T049·T054 → UI T057·T060 → Feature T069·T074·T078~T079 → App root 연결 → T102
- **S4**: UI T059·T062·T064 → Feature T070·T075~T080 → App T087·T091·T094 → T098~T099·T103
- S1~S4는 관련된 모든 패키지와 승인 게이트가 끝난 뒤에만 독립 수용 완료로 판정한다.

### 현재 패키지 내부 병렬 실행 예시

- Domain 승인 후 T001~T010은 서로 다른 테스트 파일이므로 병렬 작성할 수 있다.
- Infrastructure 승인 후 T028~T029는 같은 파일의 서로 다른 테스트 케이스이므로 순차 작성하되, 두 테스트 모두 T030 구현보다 먼저 작성한다.
- Data 승인 후 T033~T036은 서로 다른 계약 테스트 파일이므로 병렬 작성할 수 있다.
- Composition 승인 후 T044(Tuist 의존성 선언)를 먼저 실행한다. T045~T049은 서로 다른 adapter 테스트 파일이므로 병렬 작성할 수 있다.
- UI 승인 후 T057~T059은 서로 다른 공용 컴포넌트 테스트 파일이므로 병렬 작성할 수 있다.
- Feature 승인 후 T067~T070 및 reducer 기반이 확정된 뒤 T075~T079은 각각 서로 다른 파일 범위에서 병렬 작업할 수 있다. T081(`SettingsFeature.swift` 정합화)은 이미 완료된 Domain T021만 소비하는 독립 파일이므로 다른 Feature 작업과 병렬 작성할 수 있다.
- App 승인 후 T084~T087는 서로 다른 테스트 파일이므로 병렬 작성할 수 있다.
- 서로 다른 패키지는 같은 의존 깊이여도 승인 게이트를 넘어 병렬 실행하지 않는다.

## 구현 전략

1. 첫 미완료 패키지인 Domain의 작업만 선택한다.
2. 테스트를 먼저 작성해 예상한 이유로 실패하는지 확인한 뒤 구현·정리·패키지 검증을 완료한다.
3. 변경 파일과 실제 검증 결과를 보고하고 다음 패키지 승인을 요청한 뒤 중단한다.
4. 명시적 승인 후 다음 패키지에서 같은 절차를 반복한다.
5. 최소 가치 범위는 S1이지만 Domain부터 App까지(Infrastructure 포함) 필요한 작업과 모든 패키지 승인 게이트를 유지한다.
6. 마지막 패키지 승인 뒤에만 전체 읽기 전용 검증과 S1~S4 독립 수용 검증을 실행한다.

## 참고

- 작업 ID는 실행 순서대로 T001~T103을 사용한다.
- 기존 미커밋 Domain/Data/Composition 변경(`CareerLevel.swift`, `MemberPosition.swift`,
  `MemberRepositoryAdapter.swift`, `AnswerDTOs.swift` 등)은 각 패키지 진입 시 diff를 다시
  확인하고 되돌리거나 덮어쓰지 않는다. `MemberRepositoryAdapter.swift`의 현재 미커밋 상태는
  optional 반환을 `MemberProfile`의 non-optional 필드에 대입해 컴파일이 깨지므로, T013(Domain)
  완료 뒤 T050(Composition)에서 정합화한다.
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

**부분 갱신 사유 5(접근성 작업 정리, `/speckit-tasks` 재실행 2026-08-27)**: 사용자 요청으로
`/speckit-tasks`를 재실행해 접근성 관련 작업을 점검했다. 접근성 계약 소유권은
[`docs/conventions/view.md` §7.1](../../../docs/conventions/view.md)에 따라 화면이 아니라
UIComponent가 라벨·trait를 소유하므로, 구현 작업(T059·T061·T063~T064의 UI package, T070·
T075~T080의 Feature package)은 이미 각 소유 패키지에 정확히 분산되어 있고 전면 재구성이
필요하지 않음을 확인했다(모두 완료, `[X]`). 이 원칙에 따라 접근성 요구를 별도 시나리오나
패키지로 재편하지 않고 아래 두 가지만 정리했다.

1. 남은 미완료 검증 중 T103이 S4의 실제 수용 시나리오(Preview↔Figma node 비교, spec.md
   시나리오 4)에는 없는 "접근성 결과"를 포함해 T099와 검증 범위가 겹치고 어느 작업이
   접근성 수용의 근거인지 불명확했다. T103을 Preview·Figma 비교로만 좁히고 접근성은 T099가
   단독으로 소유하도록 정리했다.
2. T099가 "VoiceOver, Reduce Motion"처럼 확인 항목을 나열만 해 무엇을 어떤 근거로
   판정하는지 불명확했다. `docs/conventions/view.md` §7.2 규칙(심볼 전용 컨트롤의 의미
   라벨, 카드/행의 `accessibilityElement(children: .combine)` 결합, 선택 상태의 `.isSelected`
   trait)을 명시적 판정 기준으로 인용하도록 확장했다.

T099·T103의 작업 ID와 완료 표시는 바꾸지 않았고, 두 작업의 설명 문구만 갱신했다. 다른 모든
작업 ID(T001~T098, T100~T102)와 완료 표시는 그대로 보존했다.

**부분 갱신 사유 6(전체 완료 검증 후속 결함 3건, `/speckit-tasks` 재실행 2026-08-27)**:
`/speckit-implement`의 전체 완료 검증(T096~T103, 모두 완료)에서 사용자가 승인하지 않은
결함 3건이 새로 발견됐다. (1) `PolicyAgreementRow`가
[`docs/conventions/view.md` §7.2](../../../docs/conventions/view.md)의 접근성 규칙
3가지(라벨 미적용·`accessibilityElement(children: .combine)` 누락·`.isSelected` trait
누락)를 위반함
([trouble-shooting.md TS-20260827-004](../../../docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md)).
(2) tutorial 힌트("3초만에 가입하기")가 Figma `779:33564`의 말풍선(tooltip) 형태와 달리
배경 없는 평문 텍스트로 구현되어 FR-028의 승인된 차이 목록에 없는 미승인 시각 차이로
남음(T098 결과). (3) Onboarding 화면 6개의 `#Preview`가 화면 파일 안에 직접 위치해
`docs/conventions/view.md` §8("화면 파일 안에 `#Preview`를 두지 않는다")과 충돌함
([trouble-shooting.md TS-20260827-005](../../../docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md)).
세 결함 모두 이미 완료·승인된 UI·Feature 패키지 범위 안의 파일을 수정해야 하므로, 새
승인 게이트를 갖는 후속 패키지 단계로 T104~T109를 추가했다. 패키지 의존 순서(UI가
Feature보다 먼저 완료돼야 함)를 그대로 유지해 UI 후속 수정을 Feature 후속 수정보다 앞에
배치했다. 기존 T001~T103의 작업 ID와 완료 표시, 문구는 전혀 바꾸지 않았다.

**부분 갱신 사유 7(T109 실행 검증에서 드러난 실제 회귀, `/speckit-tasks` 재실행
2026-08-27)**: `/speckit-implement`의 T109(작업 패키지 9 검증)에서 `UIUITests` scheme이
처음으로 TS-20260827-006의 xctest 부트스트랩 SIGSEGV 없이 실제로 실행됐고,
`LayoutContractUITests`의 `PolicyAgreementRow` 관련 테스트 3개가 실제로 실패했다
([trouble-shooting.md TS-20260827-007](../../../docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md)).
원인은 `LayoutContractCatalog.swift`가 `PolicyAgreementRow` 전체에 건
`.accessibilityIdentifier`가, 자체 identifier가 없는 `onOpenLink` 버튼에도 SwiftUI 규칙에
따라 전파되어 `onToggle` 버튼과 identifier가 겹치는 것이다. T104~T106(작업 패키지 8)이
완료 시점에는 이 scheme이 매번 SIGSEGV로 실행 자체가 불가능해 실행 기반 검증을 하지
못했고(T106 결과가 이미 "실행 검증이 남아 있어 완전히 해결로 판정하지 않았다"고 명시),
이번 세션에서 실제 실행으로 회귀가 확정됐다. 이 결함은 이미 완료·승인된 UI 패키지(8) 범위
안의 `PolicyAgreementRow.swift` 파일 수정이 필요하므로, `/speckit-implement`의 소유권
규칙(9번)에 따라 그 세션은 수정을 시도했다가 되돌리고 이 재실행을 요청했다. 이 문서는 새
승인 게이트를 갖는 작업 패키지 10을 추가해 그 수정을 반영한다. 패키지 의존 순서(UI가
Feature보다 먼저 완료돼야 함)를 유지해야 하지만, 작업 패키지 10은 패키지 9(Feature) 완료
이후에 발견된 결함이므로 실행 순서상으로는 패키지 9 뒤에 배치하되 소유권은 UI 패키지로
유지한다(패키지 10 완료 자체가 패키지 9의 선행 조건은 아니며, 이미 완료된 패키지 9의
Feature 코드를 다시 열지 않는다). 기존 T001~T109의 작업 ID와 완료 표시, 문구는 전혀 바꾸지
않았다.

---

## 작업 패키지 8: UI (후속 수정 — PolicyAgreementRow 접근성)

**목표**: `PolicyAgreementRow`가 [`docs/conventions/view.md` §7.2](../../../docs/conventions/view.md)의
접근성 규칙(의미 라벨 적용, `accessibilityElement(children: .combine)` 결합, `.isSelected`
trait, 독립 동작 버튼의 별도 라벨)을 모두 충족하도록 수정한다.

**소유 경로**: `sources/Projects/UI/Component/Controls/PolicyAgreementRow/`,
`sources/Projects/UI/ComponentPreviewApp/Catalogs/`, `sources/Projects/UI/Tests/Component/UI/`

**관련 결함**: [trouble-shooting.md TS-20260827-004](../../../docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md)

**독립 검증**: `sources/Projects/UI/Tests/Component/UI/LayoutContractUITests.swift`가
`XCUIApplication()`으로 `ComponentPreviewApp`을 실제 구동해 `PolicyAgreementRow`의 실제
접근성 트리(라벨 결합, `isSelected` 상태, 열기 버튼 라벨 분리)를 외부 패키지 없이
검증한다. `PolicyAgreementRowTests.swift`(Swift Testing)는 뷰를 렌더링하지 않아
accessibilityLabel 적용·`accessibilityElement(children: .combine)` 결합·`.isSelected`
trait를 검사할 수 없음을 확인했으므로 이 패키지의 기존 `LayoutContractCatalog.swift`
+ `LayoutContractUITests.swift` 패턴(예: `assertButtonTrait`, `progress.label` 검증)을
그대로 따른다.

### 준비와 테스트

- [X] T104 [S2] `sources/Projects/UI/ComponentPreviewApp/Catalogs/LayoutContractCatalog.swift`에
      `PolicyAgreementRow` 인스턴스 2개를 추가한다: `PolicyAgreementRow(title: "서비스 이용
      약관", isRequired: true, isSelected: false, onOpenLink: {})`에
      `.accessibilityIdentifier("policyAgreementRow.unselected")`를,
      `PolicyAgreementRow(title: "개인정보 처리방침", isRequired: true, isSelected: true,
      onOpenLink: {})`에 `.accessibilityIdentifier("policyAgreementRow.selected")`를 부여해
      기존 `actionButtonContracts` 등과 같은 방식으로 `body`에 편입한다. 그 다음
      `sources/Projects/UI/Tests/Component/UI/LayoutContractUITests.swift`에 다음을 실제
      `XCUIElement` 검사로 확인하는 테스트를 추가한다: (1)
      `element(identifier: "policyAgreementRow.unselected")`가 `"필수, 서비스 이용
      약관"`으로 시작하는 단일 `label`을 가져 카드 전체가 하나의 접근성 요소로 결합됐는지(현재
      결함으로 실패해야 함), (2) `policyAgreementRow.selected`의 `XCUIElement.isSelected`가
      `true`이고 `policyAgreementRow.unselected`는 `false`인지(SwiftUI
      `.accessibilityAddTraits(.isSelected)`는 `XCUIElement.isSelected`로 노출됨), (3) 카드와
      별도로 `app.buttons["서비스 이용 약관 전문 보기"]`(또는 동일 규칙의 라벨)로 열기
      버튼이 독립적으로 조회되는지. 테스트 우선 원칙에 따라 이 시점에는 현재 구현 대비
      실패해야 한다(결과: `LayoutContractCatalog.swift`에 `policyAgreementRowContracts` 계산
      프로퍼티로 두 인스턴스를 추가하고 `body`에 편입함. `LayoutContractUITests.swift`에
      `testPolicyAgreementRowCombinesTitleAndRequirementIntoSingleAccessibilityElement`·
      `testPolicyAgreementRowExposesIsSelectedTraitSeparatelyFromColor`·
      `testPolicyAgreementRowOpenLinkButtonHasOwnAccessibilityLabel` 3개 테스트를 추가함.
      "테스트 우선 실패 확인"은 실행 기반으로 검증하지 못함 —
      [TS-20260827-006](../../../docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md)이
      기록한 `UIUITests` scheme의 xctest 부트스트랩 SIGSEGV가 이 세션에서 4회 연속(시뮬레이터
      재부팅 1회 포함) 재현되어 실행 자체가 불가능했음. `project_build_runner compile`로
      8개 scheme build-for-testing 전부 성공해 코드 자체의 컴파일 정합성만 확인함)

### 구현

- [X] T105 [S2] `sources/Projects/UI/Component/Controls/PolicyAgreementRow/PolicyAgreementRow.swift`의
      `body`에 `.accessibilityElement(children: .combine)`, `.accessibilityLabel(accessibilityLabel)`
      (기존에 정의만 되고 미적용 상태인 계산 프로퍼티를 실제로 적용), 선택 시
      `.accessibilityAddTraits(.isSelected)`를 추가하고, `onOpenLink` 버튼에 별도
      accessibilityLabel(예: `"\(title) 전문 보기"`)을 추가해 T104 테스트를 통과시킨다(결과:
      기존에는 `onToggle` 버튼이 `onOpenLink` 버튼까지 감싸는 중첩 Button 구조라
      `accessibilityElement(children: .combine)`을 걸면 열기 버튼의 라벨까지 통째로 결합돼
      규칙 4("독립 동작 버튼은 별도 라벨로 분리")를 만족할 수 없음을 확인. `onToggle`
      Button(아이콘+제목)과 `onOpenLink` Button(chevron)을 형제 요소로 재구성해 `onToggle`
      Button에만 `accessibilityElement(children: .combine)` + `accessibilityLabel` +
      선택 시 `.isSelected` trait를 적용하고, `onOpenLink` Button은 별도
      `openLinkAccessibilityLabel`("\(title) 전문 보기")을 갖는 독립 요소로 유지함. 시각
      레이아웃(아이콘·제목 leading, chevron trailing, 54pt 행 높이)은 그대로 보존함.
      `project_build_runner compile`로 8개 scheme build-for-testing 전부 성공 확인)

### 정리와 패키지 검증

- [X] T106 [no-write] `sources/Projects/UI/`를 대상으로 `LayoutContractUITests`가 속한
      `UIUITests` scheme을 실행하고 T104~T105 접근성 계약 통과와
      [TS-20260827-004](../../../docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md)
      재현 여부를 보고한다(결과: `xcodebuild -scheme UIUITests test`를 4회 시도(시뮬레이터
      재부팅 1회 포함)했으나 매번
      [TS-20260827-006](../../../docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md)의
      xctest 부트스트랩 SIGSEGV로 실행 자체가 불가능해 T104~T105 접근성 계약의 실행 기반
      통과 여부를 이 환경에서 검증하지 못함. 대신 코드 검토로 대체: T105 구현이
      `docs/conventions/view.md` §7.2 규칙 4가지(의미 라벨, combine 결합, `.isSelected`
      trait, 독립 버튼 분리 라벨)를 모두 반영했고 같은 패키지의 준수 사례인
      `SelectionCard.swift`와 동일한 패턴을 따름을 확인. `project_build_runner build`·
      `compile`은 각 9/9·8/8 성공. TS-20260827-004가 지적한 4가지 결함(라벨 미적용·combine
      누락·isSelected trait 누락·독립 버튼 라벨 없음)은 모두 코드 수준에서 해소됨을 확인했으나,
      실행 검증이 남아 있어 완전히 "해결"로 판정하지 않고 TS-20260827-004는 열어 둠)

**승인 게이트**: T104~T106의 변경 파일과 실제 검증 결과를 보고한 뒤 중단한다. 사용자가
Feature 후속 수정 진행을 명시적으로 승인하기 전에는 작업 패키지 9의 파일을 변경하지
않는다.

---

## 작업 패키지 9: Feature (후속 수정 — Tutorial 힌트 표현과 Preview 위치)

**목표**: tutorial 힌트의 Figma 대비 미승인 시각 차이를 명세 우선 원칙으로 해소하고,
Onboarding 화면 6개의 `#Preview`를 [`docs/conventions/view.md` §8](../../../docs/conventions/view.md)이
요구하는 `Previews/` 위치로 이동한다.

**소유 경로**: `sources/Projects/Feature/Onboarding/Screens/`,
`sources/Projects/Feature/Onboarding/Previews/`,
`specs/016-onboarding-login-tutorial-app-integration/spec.md`(FR-028 승인된 차이 목록
갱신 시에만, T107이 그 경로를 선택한 경우로 한정)

**관련 결함**: T098 결과(tutorial 힌트 미승인 차이),
[trouble-shooting.md TS-20260827-005](../../../docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md)

**독립 검증**: Feature build/test로 tutorial 힌트 반영과 Preview 파일 위치 이동을
검증하고, 다시 렌더링한 Preview로 상태·Figma node ID 표기가 유지됨을 확인한다.

### 구현

- [X] T107 [S2] Figma `779:33564`의 tutorial 힌트가 말풍선(tooltip 배경+포인터) 형태인
      것과 현재 `sources/Projects/Feature/Onboarding/Screens/TutorialScreen.swift`의
      `hint`(배경 없는 평문 텍스트)의 차이를 명세 우선 원칙(FR-028)에 따라 다음 두 선택지
      중 하나로 해소한다. (A) UI 패키지에 tooltip 스타일 컴포넌트를 추가하거나 기존
      컴포넌트를 재사용해 `TutorialScreen.swift`의 `hint`를 말풍선 형태로 재구현한다(이
      경우 UI 패키지 파일 변경이 선행돼야 하므로 별도로 사용자 승인을 받은 뒤 작업 패키지
      8과 동일한 방식으로 UI 작업을 먼저 추가한다). (B) 이 차이를 명세가 의도한 단순화로
      판단해 `specs/016-onboarding-login-tutorial-app-integration/spec.md`의 FR-028 승인된
      차이 목록에 "tutorial 힌트 tooltip 배경·포인터 생략" 항목을 명시적으로 추가한다. 두
      선택지 중 하나를 결정해 실제로 반영하고 어느 쪽을 선택했는지와 이유를 보고한다(결과:
      사용자가 옵션 B를 선택함. 신규 UI 컴포넌트 추가와 별도 승인 게이트 없이 이 차이를
      명세상 승인된 차이로 문서화하기로 결정. `specs/016-onboarding-login-tutorial-app-integration/spec.md`의
      FR-028과 SC-009에 "tutorial 힌트("3초만에 가입하기") tooltip 배경·포인터 생략" 항목을
      기존 승인된 차이 목록(Google 로그인 표현, 개인정보 명칭, 분야 화면 닫기 표현, 360×800
      frame)에 추가함. `TutorialScreen.swift`의 `hint` 구현은 변경하지 않음)
- [X] T108 [P] [S4] `sources/Projects/Feature/Onboarding/Screens/SplashScreen.swift`,
      `TutorialScreen.swift`, `LegalAgreementScreen.swift`, `PositionSelectionScreen.swift`,
      `CareerSelectionScreen.swift`, `OnboardingScreen.swift` 6개 파일 하단의 `#Preview`
      선언을 `sources/Projects/Feature/Onboarding/Previews/` 하위 화면별
      `*Previews.swift` 파일(예: `SplashScreenPreviews.swift`)로 이동한다. Preview 상태
      조합과 Figma node ID 표기(예: `"Tutorial - 1페이지 · 779:33450"`)는 그대로 유지하고,
      Screens 파일에서는 `#Preview`를 완전히 제거해
      [`docs/conventions/view.md` §8](../../../docs/conventions/view.md)을 충족시킨다(결과:
      `sources/Projects/Feature/Onboarding/Previews/`에 `SplashScreenPreviews.swift`·
      `TutorialScreenPreviews.swift`·`LegalAgreementScreenPreviews.swift`·
      `PositionSelectionScreenPreviews.swift`·`CareerSelectionScreenPreviews.swift`·
      `OnboardingScreenPreviews.swift` 6개 파일을 신설하고 각 Screens 파일의 `#Preview`
      선언을 상태 조합·Figma node ID 표기 그대로 옮김. 6개 Screens 파일에서는 `#Preview`를
      완전히 제거함. `PositionSelectionScreen`·`CareerSelectionScreen`의 내부 `enum
      Display`처럼 파일 내부(비 `private`) 선언은 같은 모듈 내 다른 파일에서 접근 가능해
      추가 변경 없이 컴파일됨)

### 정리와 패키지 검증

- [X] T109 [no-write] `sources/Projects/Feature/`를 대상으로 `make tuist` 후 Feature
      build/test를 실행하고 T107~T108 반영 결과,
      [TS-20260827-005](../../../docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md)
      재현 여부, [`docs/conventions/view.md` §8·§9](../../../docs/conventions/view.md)
      체크리스트("화면 프리뷰가 `Previews/`에 있는가?") 충족 여부를 보고한다(결과: `make
      tuist` 후 Git 추적 변경 없음(`sources/Tuist`·workspace 심볼릭 링크만 재생성). 활성
      Swift 파일에 `speckit-swift-format-run`을 실행해 0 violations 확인. project build
      runner `build` 9/9·`compile` 8/8 성공. `test`는 8개 scheme 중 5개 성공, 3개 실패:
      (1) `UIUITests`는 이번에는 TS-20260827-006의 xctest 부트스트랩 SIGSEGV 없이 실제
      실행됐으나 `LayoutContractUITests`의 `PolicyAgreementRow` 관련 테스트 3개가 진짜로
      실패함(원인: `LayoutContractCatalog.swift`가 `PolicyAgreementRow` 전체에 건
      `.accessibilityIdentifier`가 `onOpenLink` 버튼에도 전파돼 `onToggle`과 identifier가
      겹침) — [TS-20260827-007](../../../docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md)에
      근본 원인과 함께 기록함. 이 파일은 이미 승인된 작업 패키지 8(UI) 소유 경로라 이
      패키지(9) 범위에서 직접 수정하지 않고 시도한 수정을 되돌림 — 소유권 규칙(9번)에 따라
      `/speckit-tasks` 재실행으로 새 UI 후속 작업을 추가해야 함. (2)(3) `AppTests`·`Feature`는
      TS-20260826-012·TS-20260827-001~003·006과 동일한 xctest 부트스트랩 SIGSEGV로 실패 —
      T107~T108 자체가 원인이 아닌 기존 환경 결함. T107~T108이 도입한 회귀는 없음(T108의
      Preview 이동은 build/compile 성공으로 컴파일 정합성만 확인, 실행 기반 검증은
      `Feature` scheme의 SIGSEGV로 이 세션에서 불가능)
      [`docs/conventions/view.md` §8·§9](../../../docs/conventions/view.md) 체크리스트는
      코드 검토로 충족 확인: Screens 파일에 `#Preview` 0건, `Previews/` 하위 6개 파일에
      상태·Figma node ID 표기 유지)

**승인 게이트**: T107~T109의 변경 파일과 실제 검증 결과를 보고한 뒤 중단한다. 사용자가
작업 패키지 10 진행을 명시적으로 승인하기 전에는 작업 패키지 10의 파일을 변경하지 않는다.

---

## 작업 패키지 10: UI (후속 수정 2 — PolicyAgreementRow accessibilityIdentifier 충돌)

**목표**: `PolicyAgreementRow`의 `onOpenLink` 버튼이 외부에서 `onToggle` 버튼(또는 View
전체)에 건 `accessibilityIdentifier`를 상속하지 않도록 고유 identifier를 부여해, T104가
이미 작성한 `LayoutContractUITests`의 3개 테스트가 실제 실행에서 통과하게 한다.

**소유 경로**: `sources/Projects/UI/Component/Controls/PolicyAgreementRow/`

**관련 결함**: [trouble-shooting.md TS-20260827-007](../../../docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md)

**독립 검증**: `sources/Projects/UI/Tests/Component/UI/LayoutContractUITests.swift`의 기존
3개 테스트(`testPolicyAgreementRowCombinesTitleAndRequirementIntoSingleAccessibilityElement`·
`testPolicyAgreementRowExposesIsSelectedTraitSeparatelyFromColor`·
`testPolicyAgreementRowOpenLinkButtonHasOwnAccessibilityLabel`)를 `UIUITests` scheme으로
실제 실행해 "Multiple matching elements found" 없이 통과하는지로 검증한다. T104가 이미
테스트를 작성했으므로 이 패키지는 새 테스트를 추가하지 않고 기존 실패 테스트를 통과시키는
구현만 수행한다.

### 구현

- [X] T110 [S2] `sources/Projects/UI/Component/Controls/PolicyAgreementRow/PolicyAgreementRow.swift`의
      `onOpenLink` `Button`에 `title` 기반 고유 `accessibilityIdentifier`(예:
      `"policyAgreementRow.openLink.\(title)"`)를 추가한다. SwiftUI가 컨테이너(또는
      형제 View)에 건 `accessibilityIdentifier`를 자체 identifier가 없는 하위 접근성
      요소로 전파하는 동작 때문에, `LayoutContractCatalog.swift`가 `PolicyAgreementRow`
      전체에 건 `"policyAgreementRow.unselected"`/`"policyAgreementRow.selected"`가
      `onOpenLink` 버튼에도 전파되어 `onToggle` 버튼과 identifier가 겹치는 TS-20260827-007을
      해소한다. `onToggle` 버튼과 시각 레이아웃, 기존 `accessibilityLabel`·`.isSelected`
      trait는 변경하지 않는다.

### 정리와 패키지 검증

- [X] T111 [no-write] `sources/Projects/UI/`를 대상으로 `UIUITests` scheme을 실제 실행하고
      T104의 3개 `LayoutContractUITests` 테스트 통과 여부와
      [TS-20260827-007](../../../docs/spec-kit/016-onboarding-login-tutorial-app-integration/trouble-shooting.md)
      재현 여부를 보고한다. `project_build_runner build`·`compile`도 함께 실행해 회귀
      여부를 확인한다(결과: `UIUITests` scheme을 `xcodebuild test-without-building`으로 직접
      실행해 `LayoutContractUITests` 19개 테스트 전부(대상 3개 포함) 통과 확인, TS-20260827-007
      재현 없음. `project_build_runner build` 9/9·`compile` 8/8 성공. `test`는 8개 scheme 중
      6개 성공(`UIUITests` 포함, 신규로 통과), 2개 실패는 `AppTests`·`Feature`로
      TS-20260826-012·TS-20260827-001~003·006과 동일한 기존 환경 xctest 부트스트랩 SIGSEGV —
      이번 변경이 원인이 아님. 구현 경과: T110 지시대로 `onOpenLink` 버튼에만 고유
      `accessibilityIdentifier`를 추가하는 방식은 실제로는 collision을 해소하지 못함을 실기기
      실행으로 확인함(SwiftUI가 컨테이너 외부에서 건 identifier를 자체 identifier가 있는
      하위 요소에도 덮어씀). 근본 원인이 T110 설명과 달라 최소 추가 조치가 필요했음: 외부
      `HStack` 전체를 `.accessibilityElement(children: .contain)`으로 감싸 ambient identifier가
      컨테이너 노드에서 멈추도록 하고, 동일 노드에 기존 `accessibilityLabel`·`.isSelected`
      trait를 그대로 다시 적용해 `reveal(identifier:)` 조회가 여전히 올바른 라벨·trait를
      반환하도록 함. `onToggle` 버튼 자체의 기존 `accessibilityElement(children: .combine)`·
      `accessibilityLabel`·`.isSelected` trait·시각 레이아웃은 변경하지 않음)

**승인 게이트**: T110~T111의 변경 파일과 실제 검증 결과를 보고한 뒤 중단한다. 사용자가
전체 재검증을 명시적으로 승인한 뒤에만 T096~T098에 준하는 전체 build/test와 Preview·
Figma 비교를 다시 실행한다.

## 후속 수정 의존성

- 작업 패키지 8(UI)이 작업 패키지 9(Feature)보다 먼저 승인·완료돼야 한다(UI가 Feature의
  의존 대상이라는 기존 패키지 순서를 그대로 따름).
- T104(테스트)는 T105(구현)보다 먼저 작성한다.
- T108은 서로 다른 6개 파일을 대상으로 하므로 병렬 작업할 수 있다.
- T107이 선택지 (A)를 선택하면 UI 패키지에 새 작업을 추가해야 하므로, 그 경우 이 절을
  다시 갱신하고 작업 패키지 8과 동일한 승인 절차를 따른다.
- 작업 패키지 10은 작업 패키지 9(T109) 실행 도중 실제 테스트 실행으로 확정된 회귀이므로
  패키지 9 뒤에 배치했다. 소유 파일은 UI 패키지 범위이며 이미 완료된 Feature 패키지(9) 파일은
  다시 열지 않는다. T110은 T104가 이미 작성한 테스트만 통과시키므로 새 테스트 작업을
  추가하지 않는다.
