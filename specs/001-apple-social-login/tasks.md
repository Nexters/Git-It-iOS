# 작업 목록: Apple 소셜 로그인

**입력**: `specs/001-apple-social-login/`의 설계 문서

**선행 조건**: plan.md, spec.md, research.md, data-model.md, contracts/authentication-boundary.md

**테스트 접근**: TDD (Red → Green → Refactor). 모든 사용자 스토리와 기반 작업에서 테스트를
먼저 작성하고 실패를 확인한 뒤 구현으로 통과시킨다.

**구성**: 각 스토리를 독립적으로 구현하고 검증할 수 있도록 사용자 스토리별로 작업을 묶는다.

## 형식: `[ID] [P?] [스토리] 설명`

- **[P]**: 병렬 실행 가능(서로 다른 파일, 의존성 없음)
- **[스토리]**: 작업이 속한 사용자 스토리(예: US1, US2, US3)
- 설명에는 정확한 파일 경로를 포함한다.

---

## 단계 1: 준비(공통 기반)

**목적**: Tuist 타겟 등록, 테스트 타겟 등록과 프로젝트 구조 생성

- [ ] T001 `sources/Tuist/ProjectDescriptionHelpers/Projects/CoreModuleName.swift`에 `CoreAuthentication` case를 추가하고 `AuthenticationServices`, `Security` 프레임워크 의존성과 함께 production·test 타겟을 등록한다
- [ ] T002 `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`에 `DataAuthentication` case를 추가하고 production·test 타겟을 등록한다
- [ ] T003 `sources/Tuist/ProjectDescriptionHelpers/Projects/DomainModuleName.swift`에 `DomainAuthentication` case를 추가하고 production·test 타겟을 등록한다
- [ ] T004 `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`에 `FeatureAuthentication` case를 추가하고 `DomainAuthentication`, `UIComponent`, `ComposableArchitecture` 의존성으로 production·test 타겟을 등록한다
- [ ] T005 `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`에 `Composition` 타겟의 의존성에 `DomainAuthentication`, `DataAuthentication`, `CoreAuthentication`을 추가하고 test 타겟 의존성도 갱신한다
- [ ] T006 `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`에 `GitIt` 타겟의 의존성에 `FeatureAuthentication`, `DomainAuthentication`을 추가한다
- [ ] T007 각 새 타겟의 소스·테스트 디렉터리와 Placeholder를 생성한다: `sources/Projects/Core/CoreAuthentication/Placeholder.swift`, `sources/Projects/Core/CoreAuthenticationTests/Placeholder.swift`, `sources/Projects/Data/DataAuthentication/Placeholder.swift`, `sources/Projects/Data/DataAuthenticationTests/Placeholder.swift`, `sources/Projects/Domain/DomainAuthentication/Placeholder.swift`, `sources/Projects/Domain/DomainAuthenticationTests/Placeholder.swift`, `sources/Projects/Feature/FeatureAuthentication/Placeholder.swift`, `sources/Projects/Feature/FeatureAuthenticationTests/Placeholder.swift`
- [ ] T008 `sources/` 디렉터리에서 `tuist generate`를 실행해 workspace를 재생성하고 빌드와 빈 테스트가 성공하는지 확인한다

---

## 단계 2: 기반(차단 선행 조건)

**목적**: 모든 사용자 스토리가 공유하는 Domain 모델, 계약, Core 기술 API, Data 계약과 Composition Adapter. TDD 흐름에 따라 각 계층별로 테스트를 먼저 작성한다.

**⚠️ 중요**: 이 단계가 완료되기 전에는 사용자 스토리 작업을 시작할 수 없다.

### 2-A. Domain 모델과 계약 — 🔴 Red: 테스트 먼저

- [ ] T009 [P] `sources/Projects/Domain/DomainAuthenticationTests/Models/AuthenticatedUserTests.swift`에 `AuthenticatedUser` 모델의 생성, Equatable, 표시 정보 안전성(토큰 미포함) 테스트를 작성한다
- [ ] T010 [P] `sources/Projects/Domain/DomainAuthenticationTests/Models/AuthenticationOutcomeTests.swift`에 `AuthenticationOutcome` enum의 case 분기와 associated value 접근 테스트를 작성한다
- [ ] T011 [P] `sources/Projects/Domain/DomainAuthenticationTests/Models/AuthenticationErrorTests.swift`에 Domain 인증 오류 타입의 분류(취소, 일시 실패, 리프레시 거부, 계정 이용 불가, 시도 불일치) 테스트를 작성한다

### 2-B. Domain 모델과 계약 — 🟢 Green: 구현으로 통과

- [ ] T012 [P] `sources/Projects/Domain/DomainAuthentication/Models/AuthenticatedUser.swift`에 `AuthenticatedUser` 모델을 정의한다 (id, availability, displayName). T009 테스트를 통과시킨다
- [ ] T013 [P] `sources/Projects/Domain/DomainAuthentication/Models/AuthenticationOutcome.swift`에 `AuthenticationOutcome` enum을 정의한다 (`authenticated(AuthenticatedUser)`, `unauthenticated`, `recoverableFailure`). T010 테스트를 통과시킨다
- [ ] T014 [P] `sources/Projects/Domain/DomainAuthentication/Models/AuthenticationError.swift`에 Domain 인증 오류 타입을 정의한다. T011 테스트를 통과시킨다
- [ ] T015 [P] `sources/Projects/Domain/DomainAuthentication/Contracts/AuthenticationRepository.swift`에 `AuthenticationRepository` protocol을 정의한다 (로그인, 세션 복원, 토큰 갱신, 로그아웃)
- [ ] T016 [P] `sources/Projects/Domain/DomainAuthentication/Contracts/AppleAuthorizationClient.swift`에 `AppleAuthorizationClient` protocol을 정의한다 (Apple 인증 시작, credential state 조회)

### 2-C. Domain Use Case — 🔴 Red: 테스트 먼저

- [ ] T017 [P] `sources/Projects/Domain/DomainAuthenticationTests/UseCases/SignInWithAppleTests.swift`에 `SignInWithApple` use case의 성공 경로, 교환 결과 반환, 토큰 미노출, 시도 불일치 무시 테스트를 작성한다
- [ ] T018 [P] `sources/Projects/Domain/DomainAuthenticationTests/UseCases/RestoreSessionTests.swift`에 `RestoreSession` use case의 저장 세션 없음, 유효 세션, 갱신 성공, 일시 오류, 거부 경로 테스트를 작성한다
- [ ] T019 [P] `sources/Projects/Domain/DomainAuthenticationTests/UseCases/SignOutTests.swift`에 `SignOut` use case의 세션 삭제, best-effort 서버 폐기, unauthenticated 반환 테스트를 작성한다

### 2-D. Domain Use Case — 🟢 Green: 구현으로 통과

- [ ] T020 `sources/Projects/Domain/DomainAuthentication/UseCases/SignInWithApple.swift`에 `SignInWithApple` use case를 구현한다. T017 테스트를 통과시킨다
- [ ] T021 `sources/Projects/Domain/DomainAuthentication/UseCases/RestoreSession.swift`에 `RestoreSession` use case를 구현한다. T018 테스트를 통과시킨다
- [ ] T022 `sources/Projects/Domain/DomainAuthentication/UseCases/SignOut.swift`에 `SignOut` use case를 구현한다. T019 테스트를 통과시킨다

### 2-E. Core 기술 API — 🔴 Red: 테스트 먼저

- [ ] T023 [P] `sources/Projects/Core/CoreAuthenticationTests/Keychain/KeychainStoreTests.swift`에 Keychain CRUD, 접근성 설정, 원자적 저장·삭제 테스트를 작성한다
- [ ] T024 [P] `sources/Projects/Core/CoreAuthenticationTests/RandomGenerator/SecureRandomGeneratorTests.swift`에 nonce·state·attemptID 생성의 고유성과 길이 테스트를 작성한다

### 2-F. Core 기술 API — 🟢 Green: 구현으로 통과

- [ ] T025 [P] `sources/Projects/Core/CoreAuthentication/AppleAuthentication/AppleAuthorizationProvider.swift`에 `ASAuthorizationAppleIDProvider`·`ASAuthorizationController` 래퍼를 구현한다 (nonce/state 생성, 시스템 인증 UI 연결, 콜백 변환)
- [ ] T026 [P] `sources/Projects/Core/CoreAuthentication/AppleAuthentication/AppleCredentialStateProvider.swift`에 Apple credential state 조회 래퍼를 구현한다
- [ ] T027 [P] `sources/Projects/Core/CoreAuthentication/Keychain/KeychainStore.swift`에 Keychain CRUD API를 구현한다 (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, 원자적 저장·삭제). T023 테스트를 통과시킨다
- [ ] T028 [P] `sources/Projects/Core/CoreAuthentication/RandomGenerator/SecureRandomGenerator.swift`에 CSPRNG 기반 nonce·state·attemptID 생성 API를 구현한다. T024 테스트를 통과시킨다

### 2-G. Data 계약과 DTO — 🔴 Red: 테스트 먼저

- [ ] T029 [P] `sources/Projects/Data/DataAuthenticationTests/DTOs/AuthenticationDTOTests.swift`에 교환 요청·응답 DTO의 생성과 필드 매핑 테스트를 작성한다
- [ ] T030 [P] `sources/Projects/Data/DataAuthenticationTests/Models/StoredSessionTests.swift`에 `StoredSession` 모델의 생성과 민감 값 미노출 테스트를 작성한다

### 2-H. Data 계약과 DTO — 🟢 Green: 구현으로 통과

- [ ] T031 [P] `sources/Projects/Data/DataAuthentication/Contracts/AuthenticationRemote.swift`에 `AuthenticationRemote` protocol을 정의한다 (Apple credential 교환, 토큰 갱신, 리프레시 폐기)
- [ ] T032 [P] `sources/Projects/Data/DataAuthentication/Contracts/SessionStorage.swift`에 `SessionStorage` protocol을 정의한다 (세션 저장·읽기·삭제)
- [ ] T033 [P] `sources/Projects/Data/DataAuthentication/DTOs/AuthenticationRequestDTO.swift`에 서버 교환 요청 DTO를 정의한다 (identityToken, authorizationCode, appleUserID, nonce). T029 테스트를 통과시킨다
- [ ] T034 [P] `sources/Projects/Data/DataAuthentication/DTOs/AuthenticationResponseDTO.swift`에 서버 교환 응답 DTO를 정의한다 (accessToken, refreshToken, accessExpiresAt, user). T029 테스트를 통과시킨다
- [ ] T035 [P] `sources/Projects/Data/DataAuthentication/DTOs/RefreshRequestDTO.swift`에 토큰 갱신 요청 DTO를 정의한다
- [ ] T036 [P] `sources/Projects/Data/DataAuthentication/DTOs/RefreshResponseDTO.swift`에 토큰 갱신 응답 DTO를 정의한다
- [ ] T037 [P] `sources/Projects/Data/DataAuthentication/Models/StoredSession.swift`에 Keychain에 보관하는 세션 모델을 정의한다 (accessToken, refreshToken, appleUserID, accessExpiresAt). T030 테스트를 통과시킨다
- [ ] T038 [P] `sources/Projects/Data/DataAuthentication/Errors/DataAuthenticationError.swift`에 Data 계층 오류 분류를 정의한다 (일시 네트워크 오류, 리프레시 거부, 계정 이용 불가)

### 2-I. Composition Adapter와 Mock — 🔴 Red: 테스트 먼저

- [ ] T039 [P] `sources/Projects/Composition/CompositionTests/Authentication/Adapters/DomainDataAuthenticationAdapterTests.swift`에 Domain↔Data Adapter의 교환·갱신·폐기 변환 테스트를 작성한다
- [ ] T040 [P] `sources/Projects/Composition/CompositionTests/Authentication/Adapters/DataCoreAuthenticationAdapterTests.swift`에 Data↔Core Adapter의 세션 저장·읽기·삭제 변환 테스트를 작성한다
- [ ] T041 [P] `sources/Projects/Composition/CompositionTests/Authentication/SessionCoordinatorTests.swift`에 세션 세대 관리, 증가, 이전 세대 결과 거부 테스트를 작성한다

### 2-J. Composition Adapter와 Mock — 🟢 Green: 구현으로 통과

- [ ] T042 `sources/Projects/Composition/Composition/Authentication/Adapters/DomainDataAuthenticationAdapter.swift`에 Domain `AuthenticationRepository` ↔ Data `AuthenticationRemote`·`SessionStorage` Adapter를 구현한다. T039 테스트를 통과시킨다
- [ ] T043 `sources/Projects/Composition/Composition/Authentication/Adapters/DataCoreAuthenticationAdapter.swift`에 Data `SessionStorage` ↔ Core `KeychainStore` Adapter를 구현한다. T040 테스트를 통과시킨다
- [ ] T044 `sources/Projects/Composition/Composition/Authentication/Adapters/AppleAuthorizationAdapter.swift`에 Domain `AppleAuthorizationClient` ↔ Core Apple 래퍼 Adapter를 구현한다
- [ ] T045 `sources/Projects/Composition/Composition/Authentication/SessionCoordinator.swift`에 세션 세대 관리와 비동기 경쟁 제어를 담당하는 공유 actor를 구현한다. T041 테스트를 통과시킨다
- [ ] T046 [P] `sources/Projects/Composition/Composition/Authentication/Mocks/MockAuthenticationRemote.swift`에 `AuthenticationRemote` Mock을 구현한다 (신규·기존 사용자, 프로필 부재, 갱신, 일시 오류, 거부, 폐기 실패를 결정적으로 재현)
- [ ] T047 [P] `sources/Projects/Composition/Composition/Authentication/Mocks/MockSessionStorage.swift`에 `SessionStorage` Mock을 구현한다
- [ ] T048 [P] `sources/Projects/Composition/Composition/Authentication/Mocks/MockAppleAuthorizationClient.swift`에 `AppleAuthorizationClient` Mock을 구현한다 (성공, 취소, 오류, state 불일치, 값 누락 시나리오)
- [ ] T049 `sources/Projects/Composition/Composition/Authentication/UnavailableAuthenticationRemote.swift`에 live endpoint가 없는 릴리스용 unavailable 구현을 작성한다
- [ ] T050 `sources/Projects/Composition/Composition/Authentication/AppComposition+Authentication.swift`에 `AppComposition`의 인증 의존성 조립을 구현한다 (Mock/live/unavailable 선택, use case 생성, Adapter 연결)

### 2-K. UI 구성요소

- [ ] T051 `sources/Projects/UI/UIComponent/Authentication/AppleSignInButton.swift`에 Apple 디자인 가이드를 따르는 `SignInWithAppleButton` 래퍼 뷰를 구현한다 (탭 동작만 외부에 전달, 접근성 지원)

**점검 지점**: `tuist generate`로 workspace를 재생성하고 전체 빌드와 모든 기반 테스트(T009~T011, T017~T019, T023~T024, T029~T030, T039~T041)가 통과하는지 확인한다.

---

## 단계 3: 사용자 스토리 1 - Apple 계정으로 처음 로그인 (우선순위: P1) 🎯 MVP

**목표**: 로그아웃 상태의 사용자가 Apple 로그인을 선택하고 인증하여 Git It 사용을 시작한다

**독립 테스트**: 빈 세션 저장소에서 Mock Apple 인증과 Mock 서버 교환을 거쳐 인증된 첫 화면에 도달하고, 중복 탭이 차단되며, Feature/App 상태에 토큰이 노출되지 않는지 검증한다

### 🔴 Red: 테스트 먼저

> **구현 전에 이 테스트를 먼저 작성하고 실패하는지 확인한다.**

- [ ] T052 [P] [US1] `sources/Projects/Feature/FeatureAuthenticationTests/SignInFeatureTests.swift`에 TCA `TestStore` 기반 로그인 성공 상태 전이 테스트를 작성한다 (unauthenticated → authenticating → authenticated)
- [ ] T053 [P] [US1] `sources/Projects/Feature/FeatureAuthenticationTests/SignInDuplicateTapTests.swift`에 `authenticating` 상태에서 중복 로그인 시작 action이 무시되는지 테스트한다

### 🟢 Green: 구현으로 통과

- [ ] T054 [US1] `sources/Projects/Feature/FeatureAuthentication/Authentication/AuthenticationFeature.swift`에 TCA Reducer를 구현한다 (State: `checking`/`unauthenticated`/`authenticating`/`authenticated`/`recoverableFailure`, Action: 로그인 시작·Apple 결과 수신·교환 완료·실패, 중복 탭 차단). T052, T053 테스트를 통과시킨다
- [ ] T055 [US1] `sources/Projects/Feature/FeatureAuthentication/Authentication/Views/SignInView.swift`에 로그인 화면을 구현한다 (Apple 로그인 버튼, 진행 상태 표시, 접근성 지원)
- [ ] T056 [US1] `sources/Projects/Feature/FeatureAuthentication/Authentication/Views/AuthenticatedView.swift`에 인증된 첫 화면을 구현한다 (사용자 표시 정보, 로그아웃 동작)
- [ ] T057 [US1] `sources/Projects/App/Sources/ContentView.swift`를 수정해 `AuthenticationFeature`의 상태에 따른 root 화면 전환을 연결한다 (checking → splash, unauthenticated → SignInView, authenticated → AuthenticatedView, recoverableFailure → RecoveryView)
- [ ] T058 [US1] `sources/Projects/App/Sources/GitItApp.swift`를 수정해 `AppComposition`에서 인증 use case를 받아 `AuthenticationFeature` initializer에 전달한다

**점검 지점**: Mock 기반으로 빈 세션에서 Apple 로그인 → 인증된 첫 화면 전환이 동작하고, 중복 탭이 차단되며, TCA 상태 테스트(T052~T053)가 통과한다.

---

## 단계 4: 사용자 스토리 2 - 기존 Apple 계정으로 다시 로그인 (우선순위: P2)

**목표**: 이전에 로그인한 사용자가 같은 Apple 계정으로 기존 Git It 계정에 진입하고, 앱 재실행 시 자동 로그인하며, 로그아웃으로 세션을 종료한다

**독립 테스트**: 저장 세션이 있는 상태에서 세션 복원·토큰 갱신·로그아웃·앱 재실행 후 자동 로그인 해제를 각각 Mock으로 검증한다

### 🔴 Red: 테스트 먼저

> **구현 전에 이 테스트를 먼저 작성하고 실패하는지 확인한다.**

- [ ] T059 [P] [US2] `sources/Projects/Feature/FeatureAuthenticationTests/SessionRestoreFeatureTests.swift`에 TCA `TestStore` 기반 세션 복원 상태 전이 테스트를 작성한다 (checking → authenticated, checking → unauthenticated)
- [ ] T060 [P] [US2] `sources/Projects/Feature/FeatureAuthenticationTests/SignOutFeatureTests.swift`에 로그아웃 후 unauthenticated 전환과 진행 중 효과 취소를 테스트한다
- [ ] T061 [P] [US2] `sources/Projects/Composition/CompositionTests/Authentication/SessionCoordinatorRaceTests.swift`에 갱신 중 로그아웃 경쟁 시 세션 세대 증가와 늦은 응답 무시를 테스트한다

### 🟢 Green: 구현으로 통과

- [ ] T062 [US2] `sources/Projects/Feature/FeatureAuthentication/Authentication/AuthenticationFeature.swift`에 앱 시작 시 자동 세션 복원 action을 추가한다 (checking → RestoreSession 호출 → 결과에 따른 상태 전이). T059 테스트를 통과시킨다
- [ ] T063 [US2] `sources/Projects/Feature/FeatureAuthentication/Authentication/AuthenticationFeature.swift`에 로그아웃 action을 추가한다 (authenticated → SignOut 호출 → 세대 증가 → unauthenticated, 진행 중 효과 취소). T060 테스트를 통과시킨다
- [ ] T064 [US2] `sources/Projects/Feature/FeatureAuthentication/Authentication/Views/AuthenticatedView.swift`에 로그아웃 버튼과 동작을 연결한다
- [ ] T065 [US2] `sources/Projects/App/Sources/GitItApp.swift`에서 앱 시작 시 세션 복원 action을 발행하도록 연결한다

**점검 지점**: Mock 기반 세션 복원·갱신·로그아웃·재시작 후 자동 로그인 해제가 동작하고, 세션 세대 경쟁 테스트(T061)가 통과한다.

---

## 단계 5: 사용자 스토리 3 - 취소 및 오류에서 안전하게 복구 (우선순위: P3)

**목표**: Apple 인증 취소, 연결 문제, 외부 오류에서 잘못 로그인되거나 멈추지 않고 재시도할 수 있다

**독립 테스트**: Mock으로 취소·네트워크 오류·리프레시 거부·credential 철회를 각각 재현해 보호된 화면이 열리지 않고 안정적인 로그인/복구 화면을 제공하는지 검증한다

### 🔴 Red: 테스트 먼저

> **구현 전에 이 테스트를 먼저 작성하고 실패하는지 확인한다.**

- [ ] T066 [P] [US3] `sources/Projects/Feature/FeatureAuthenticationTests/CancelFeatureTests.swift`에 Apple 인증 취소 시 경고 없이 unauthenticated로 돌아가는지 테스트한다
- [ ] T067 [P] [US3] `sources/Projects/Feature/FeatureAuthenticationTests/RecoverableFailureFeatureTests.swift`에 일시 오류 시 recoverableFailure 전환과 재시도 → authenticated 또는 거부 확인 → unauthenticated 전이를 테스트한다
- [ ] T068 [P] [US3] `sources/Projects/Feature/FeatureAuthenticationTests/CredentialRevokedFeatureTests.swift`에 credential 철회·리프레시 거부 시 세션 삭제와 unauthenticated 전환을 테스트한다

### 🟢 Green: 구현으로 통과

- [ ] T069 [US3] `sources/Projects/Feature/FeatureAuthentication/Authentication/Views/RecoveryView.swift`에 복구 화면을 구현한다 (재시도 버튼, 사용자가 이해 가능한 실패 안내, 접근성 지원, 보호된 콘텐츠 미표시). T067 테스트를 통과시킨다
- [ ] T070 [US3] `sources/Projects/Feature/FeatureAuthentication/Authentication/AuthenticationFeature.swift`에 recoverableFailure 상태의 재시도 action을 추가한다 (재시도 → checking → 결과에 따른 상태 전이)
- [ ] T071 [US3] `sources/Projects/Feature/FeatureAuthentication/Authentication/AuthenticationFeature.swift`에 Apple credential revoked 알림 수신과 세션 무효화 처리를 추가한다. T068 테스트를 통과시킨다
- [ ] T072 [US3] `sources/Projects/App/Sources/ContentView.swift`에 recoverableFailure 상태의 RecoveryView 연결을 추가한다

**점검 지점**: 취소·일시 오류·리프레시 거부·credential 철회 Mock 시나리오에서 보호된 콘텐츠가 열리지 않고 안정적인 복구/로그인 화면을 제공한다. T066~T068 테스트가 통과한다.

---

## 단계 6: 마무리와 횡단 관심사

**목적**: 보안 강화, 접근성 점검, 빌드·테스트 실행과 quickstart 검증

- [ ] T073 [P] 모든 타겟의 민감 값(`identityToken`, `authorizationCode`, access/refresh token, nonce, state)이 `CustomStringConvertible`, 오류 메시지, 테스트 실패 덤프, 접근성 값에 노출되지 않는지 점검한다
- [ ] T074 [P] VoiceOver로 SignInView, AuthenticatedView, RecoveryView의 로그인 버튼, 진행 상태, 재시도 동작을 식별하고 조작할 수 있는지 점검한다
- [ ] T075 저장소 루트에서 `project_build_runner build`, `compile`, `test`를 순서대로 실행하고 결과를 기록한다
- [ ] T076 quickstart.md의 자동화 검증 시나리오(1~5)를 Mock 기반으로 실행하고 결과를 기록한다
- [ ] T077 기존 Placeholder.swift 파일에서 더 이상 필요하지 않은 것을 정리한다

---

## 의존성과 실행 순서

### 단계 의존성

- **준비(단계 1)**: 의존성이 없으므로 즉시 시작할 수 있다.
- **기반(단계 2)**: 준비 완료에 의존하며 모든 사용자 스토리를 차단한다.
- **사용자 스토리(단계 3+)**: 모두 기반 단계 완료에 의존한다.
  - 인력이 있으면 사용자 스토리를 병렬로 진행할 수 있다.
  - 또는 우선순위(P1 → P2 → P3) 순서로 순차 진행한다.
- **마무리(단계 6)**: 모든 사용자 스토리가 완료된 뒤 진행한다.

### 사용자 스토리 의존성

- **사용자 스토리 1(P1)**: 기반(단계 2) 후 시작하며 다른 스토리에 의존하지 않는다. 로그인 화면과 인증된 첫 화면을 새로 생성한다.
- **사용자 스토리 2(P2)**: 기반(단계 2) 후 시작할 수 있지만 US1이 만든 `AuthenticationFeature` Reducer를 확장하므로 US1 완료 후 진행을 권장한다.
- **사용자 스토리 3(P3)**: 기반(단계 2) 후 시작할 수 있지만 US1·US2가 만든 `AuthenticationFeature`를 확장하므로 US2 완료 후 진행을 권장한다.

### TDD 흐름 (각 계층·스토리 공통)

1. 🔴 **Red**: 테스트를 먼저 작성하고 실패를 확인한다.
2. 🟢 **Green**: 테스트를 통과시키는 최소 구현을 작성한다.
3. 🔵 **Refactor**: 중복 제거와 명확성 개선을 적용하고 테스트가 여전히 통과하는지 확인한다.

### 각 사용자 스토리 내부

- **반드시 테스트를 먼저 작성하고 실패를 확인한 뒤 구현한다.**
- Domain 모델·계약을 먼저, 그 다음 use case, Feature Reducer, View 순서로 작성한다.
- 핵심 구현을 App 연결보다 먼저 완료한다.
- 다음 우선순위로 넘어가기 전에 스토리를 완료한다.

### 병렬 실행 기회

- [P]가 붙은 모든 준비 작업(T001~T007)은 병렬로 실행할 수 있다.
- 기반 단계의 Domain 테스트(T009~T011)와 모델 구현(T012~T016)은 병렬로 실행할 수 있다.
- 기반 단계의 Core 테스트(T023~T024)와 Data 테스트(T029~T030)는 병렬로 실행할 수 있다.
- 각 스토리의 [P] 테스트는 모두 병렬로 실행할 수 있다.

---

## 병렬 실행 예시: 기반 단계 TDD

```text
# 1️⃣ 🔴 Domain 테스트를 모두 병렬로 시작:
작업: T009 "DomainAuthenticationTests/Models/AuthenticatedUserTests.swift"
작업: T010 "DomainAuthenticationTests/Models/AuthenticationOutcomeTests.swift"
작업: T011 "DomainAuthenticationTests/Models/AuthenticationErrorTests.swift"

# 2️⃣ 🟢 Domain 모델 구현을 병렬로 시작 (테스트 통과):
작업: T012 "DomainAuthentication/Models/AuthenticatedUser.swift"
작업: T013 "DomainAuthentication/Models/AuthenticationOutcome.swift"
작업: T014 "DomainAuthentication/Models/AuthenticationError.swift"

# 3️⃣ 🔴 Core·Data 테스트를 병렬로 시작:
작업: T023~T024 (Core 테스트)
작업: T029~T030 (Data 테스트)

# 4️⃣ 🟢 Core·Data 구현을 병렬로 시작 (테스트 통과):
작업: T025~T028 (Core 구현)
작업: T031~T038 (Data 구현)
```

---

## 구현 전략

### MVP 우선(사용자 스토리 1만)

1. 단계 1: 준비를 완료한다.
2. 단계 2: 기반을 TDD로 완료한다(중요 — 모든 스토리를 차단).
3. 단계 3: 사용자 스토리 1을 TDD로 완료한다.
4. **중단 후 검증**: Mock 기반으로 빈 세션 → Apple 로그인 → 인증된 첫 화면을 독립적으로 테스트한다.
5. 준비되었으면 시연한다.

### 점진적 제공

1. 준비 + 기반 완료 → 기반 준비 완료
2. 사용자 스토리 1 추가 → 독립 테스트 → 시연(MVP)
3. 사용자 스토리 2 추가 → 독립 테스트 → 시연 (세션 복원·갱신·로그아웃)
4. 사용자 스토리 3 추가 → 독립 테스트 → 시연 (취소·오류 복구)
5. 마무리 → quickstart 검증 실행
6. 각 스토리는 이전 스토리를 손상하지 않고 가치를 더한다.

---

## 참고

- [P] 작업 = 서로 다른 파일, 의존성 없음
- [스토리] 라벨은 추적성을 위해 작업을 특정 사용자 스토리에 연결한다.
- 각 사용자 스토리는 독립적으로 완료하고 테스트할 수 있어야 한다.
- **반드시 테스트를 먼저 작성하고 실패를 확인한 뒤 구현한다.**
- 각 작업 또는 논리적 작업 묶음 뒤에 커밋한다.
- 각 점검 지점에서 멈춰 스토리를 독립적으로 검증한다.
- 모호한 작업, 같은 파일 충돌, 독립성을 깨는 스토리 간 의존성을 피한다.
- 파일을 변경하는 모든 작업은 정확한 저장소 상대 경로를 포함한다. 이 경로가 `/speckit-implement`의 허용 수정 집합을 정의한다.
