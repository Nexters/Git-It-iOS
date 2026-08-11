# 작업 목록: Apple 소셜 로그인

**입력**: `specs/001-apple-social-login/`의 설계 문서

**선행 조건**: plan.md, spec.md, research.md, data-model.md,
contracts/authentication-boundary.md, quickstart.md

**사용자 요청 반영**: 기존 작업을 구현 에이전트가 추가 판단 없이 순서대로 수행할 수 있는
하위 태스크로 재정의한다.

**테스트 접근**: TDD(Red → Green → Refactor). 테스트 태스크에서 먼저 실패를 확인한 뒤
대응 구현 태스크로 통과시키고, 같은 책임 안의 중복을 정리한 후 다시 테스트한다.

**구성**: 공통 기반과 사용자 스토리 단계를 유지하되, 한 태스크는 원칙적으로 하나의 정확한
파일과 하나의 구현 또는 검증 책임만 다룬다.

## 형식: `[ID] [P?] [스토리] 설명`

- **[P]**: 선행 태스크가 완료된 뒤 서로 다른 파일에서 병렬 실행 가능
- **[스토리]**: 작업이 속한 사용자 스토리(US1, US2, US3)
- **[no-write]**: 추적 파일을 변경하지 않는 명령 실행 또는 수동 검증
- 파일을 변경하는 태스크는 `/speckit-implement`의 허용 목록이 되도록 정확한 저장소 상대
  경로 하나를 명시한다.

## 공통 검증 명령

저장소 루트에서 build runner를 해석한 뒤 `build` → `compile` → `test` 순서를 유지한다.

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

---

## 단계 1: 준비(공통 기반)

**목적**: 인증 모듈과 독립 테스트 타겟을 Tuist graph에 등록하고 빈 타겟의 생성·빌드를
검증한다.

- [ ] T001 `sources/Tuist/ProjectDescriptionHelpers/Target+Module.swift`에 명시적인 테스트 타겟 이름, production 타겟 의존성, 추가 의존성을 받는 `testModule` factory를 추가한다
- [ ] T002 [P] `sources/Tuist/ProjectDescriptionHelpers/Projects/CoreModuleName.swift`에 `CoreAuthentication`과 `CoreAuthenticationTests` 타겟을 등록하고 production 타겟에 `AuthenticationServices`·`Security` SDK 의존성, 테스트 타겟에 production 타겟 의존성을 선언한다
- [ ] T003 [P] `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`에 프로젝트 내부 의존성이 없는 `DataAuthentication`과 이를 검증하는 `DataAuthenticationTests` 타겟을 등록한다
- [ ] T004 [P] `sources/Tuist/ProjectDescriptionHelpers/Projects/DomainModuleName.swift`에 프로젝트 내부 의존성이 없는 `DomainAuthentication`과 이를 검증하는 `DomainAuthenticationTests` 타겟을 등록한다
- [ ] T005 [P] `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`에 `DomainAuthentication`·`UIComponent`·`ComposableArchitecture`에만 의존하는 `FeatureAuthentication`과 해당 테스트 타겟을 등록한다
- [ ] T006 [P] `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`에서 `Composition` 타겟에 `DomainAuthentication`·`DataAuthentication`·`CoreAuthentication` 의존성을 추가하고 같은 경계를 검증하는 `CompositionTests` 타겟을 등록한다
- [ ] T007 `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`의 `GitIt` 타겟에 `FeatureAuthentication`과 `DomainAuthentication` 의존성을 추가하되 기존 `Composition`·`Feature`·Firebase 의존성을 보존한다
- [ ] T008 [P] `sources/Projects/Core/CoreAuthentication/Placeholder.swift`를 생성해 `CoreAuthentication` production 타겟의 초기 소스 glob을 충족한다
- [ ] T009 [P] `sources/Projects/Core/CoreAuthenticationTests/Placeholder.swift`를 생성해 `CoreAuthenticationTests` 타겟의 초기 테스트 소스 glob을 충족한다
- [ ] T010 [P] `sources/Projects/Data/DataAuthentication/Placeholder.swift`를 생성해 `DataAuthentication` production 타겟의 초기 소스 glob을 충족한다
- [ ] T011 [P] `sources/Projects/Data/DataAuthenticationTests/Placeholder.swift`를 생성해 `DataAuthenticationTests` 타겟의 초기 테스트 소스 glob을 충족한다
- [ ] T012 [P] `sources/Projects/Domain/DomainAuthentication/Placeholder.swift`를 생성해 `DomainAuthentication` production 타겟의 초기 소스 glob을 충족한다
- [ ] T013 [P] `sources/Projects/Domain/DomainAuthenticationTests/Placeholder.swift`를 생성해 `DomainAuthenticationTests` 타겟의 초기 테스트 소스 glob을 충족한다
- [ ] T014 [P] `sources/Projects/Feature/FeatureAuthentication/Placeholder.swift`를 생성해 `FeatureAuthentication` production 타겟의 초기 소스 glob을 충족한다
- [ ] T015 [P] `sources/Projects/Feature/FeatureAuthenticationTests/Placeholder.swift`를 생성해 `FeatureAuthenticationTests` 타겟의 초기 테스트 소스 glob을 충족한다
- [ ] T016 [P] `sources/Projects/Composition/CompositionTests/Placeholder.swift`를 생성해 `CompositionTests` 타겟의 초기 테스트 소스 glob을 충족한다
- [ ] T017 [no-write] `sources/`에서 `tuist generate`를 실행한 뒤 저장소 루트에서 `project_build_runner build`와 `project_build_runner compile`을 순서대로 실행해 새 production·test 타겟이 graph와 테스트 scheme에 포함되는지 확인한다

---

## 단계 2: 기반(차단 선행 조건)

**목적**: 모든 사용자 스토리가 공유하는 Domain 언어와 계약, Core 기술 API, Data의 공급자
중립 계약·모델, Composition Adapter·Mock·수명 조정 기반을 TDD로 구축한다.

**중요**: 이 단계가 완료되기 전에는 사용자 스토리 구현을 시작하지 않는다.

### 2-A. Domain 모델과 계약 — Red

- [ ] T018 [P] `sources/Projects/Domain/DomainAuthenticationTests/Models/AuthenticationMethodTests.swift`에 `.apple`이 외부 프레임워크 타입 없이 표현되는 Domain 인증 방식인지 검증하는 실패 테스트를 작성한다
- [ ] T019 [P] `sources/Projects/Domain/DomainAuthenticationTests/Models/AuthenticationGrantTests.swift`에 grant가 불투명 ID와 method만 보유하고 원시 credential·토큰을 노출하지 않는지 검증하는 실패 테스트를 작성한다
- [ ] T020 [P] `sources/Projects/Domain/DomainAuthenticationTests/Models/AuthenticatedUserTests.swift`에 서버 사용자 ID, 이용 가능 상태, 선택적 표시 이름만 표현하는지 검증하는 실패 테스트를 작성한다
- [ ] T021 [P] `sources/Projects/Domain/DomainAuthenticationTests/Models/AuthenticationOutcomeTests.swift`에 `authenticated`·`unauthenticated`·`recoverableFailure` 결과가 토큰과 외부 오류를 포함하지 않는지 검증하는 실패 테스트를 작성한다
- [ ] T022 [P] `sources/Projects/Domain/DomainAuthenticationTests/Models/AuthenticationAuthorizationStatusTests.swift`에 `authorized`·`reauthenticationRequired`·`temporarilyUnavailable`만 공개되는지 검증하는 실패 테스트를 작성한다
- [ ] T023 [P] `sources/Projects/Domain/DomainAuthenticationTests/Models/AuthenticationErrorTests.swift`에 사용자 취소와 복구 가능한 외부 인증 실패가 공급자 중립 의미로 구분되는지 검증하는 실패 테스트를 작성한다
- [ ] T024 [P] `sources/Projects/Domain/DomainAuthenticationTests/Models/SessionErrorTests.swift`에 일시 실패, refresh 거부·만료, 계정 이용 불가가 서로 구분되는지 검증하는 실패 테스트를 작성한다
- [ ] T025 [P] `sources/Projects/Domain/DomainAuthenticationTests/Contracts/AuthenticationRepositoryContractTests.swift`에 인증·grant 발급, generic authorization 상태·변경 stream, 인증 참조 정리만 제공하고 서버 세션 연산을 제공하지 않는 계약 테스트를 작성한다
- [ ] T026 [P] `sources/Projects/Domain/DomainAuthenticationTests/Contracts/SessionRepositoryContractTests.swift`에 grant 기반 시작, 복원·내부 refresh, 로그아웃만 제공하고 외부 인증 연산을 제공하지 않는 계약 테스트를 작성한다

### 2-B. Domain 모델과 계약 — Green

- [ ] T027 [P] `sources/Projects/Domain/DomainAuthentication/Models/AuthenticationMethod.swift`에 공급자 실행 기술을 포함하지 않는 `AuthenticationMethod.apple`을 정의해 T018을 통과시킨다
- [ ] T028 [P] `sources/Projects/Domain/DomainAuthentication/Models/AuthenticationGrant.swift`에 불투명 `id`와 `method`만 가진 단발성 grant 모델을 정의해 T019를 통과시킨다
- [ ] T029 [P] `sources/Projects/Domain/DomainAuthentication/Models/AuthenticatedUser.swift`에 안전한 사용자 표시 정보만 가진 모델을 정의해 T020을 통과시킨다
- [ ] T030 [P] `sources/Projects/Domain/DomainAuthentication/Models/AuthenticationOutcome.swift`에 Feature로 전달할 인증 결과 세 가지를 정의해 T021을 통과시킨다
- [ ] T031 [P] `sources/Projects/Domain/DomainAuthentication/Models/AuthenticationAuthorizationStatus.swift`에 공급자 중립 authorization 상태를 정의해 T022를 통과시킨다
- [ ] T032 [P] `sources/Projects/Domain/DomainAuthentication/Models/AuthenticationError.swift`에 취소와 복구 가능한 인증 오류를 정의하되 Apple 오류 타입과 민감 값을 배제해 T023을 통과시킨다
- [ ] T033 [P] `sources/Projects/Domain/DomainAuthentication/Models/SessionError.swift`에 세션 일시 실패, 명시적 거부·만료, 계정 이용 불가 의미를 정의해 T024를 통과시킨다
- [ ] T034 [P] `sources/Projects/Domain/DomainAuthentication/Contracts/AuthenticationRepository.swift`에 `authenticate(using:)`, `authorizationStatus()`, `authorizationChanges()`, `clearAuthorization()`만 가진 `Sendable` 계약을 정의해 T025를 통과시킨다
- [ ] T035 [P] `sources/Projects/Domain/DomainAuthentication/Contracts/SessionRepository.swift`에 `start(with:)`, `restore()`, `signOut()`만 가진 `Sendable` 계약을 정의해 T026을 통과시킨다

### 2-C. Domain Use Case — Red

- [ ] T036 [P] `sources/Projects/Domain/DomainAuthenticationTests/UseCases/SignInTests.swift`에 선택 방식 전달, 인증→grant→세션 시작 순서, 인증 실패 시 세션 미호출, 세션 시작 실패 시 인증 정리 테스트를 작성하고 실패를 확인한다
- [ ] T037 [P] `sources/Projects/Domain/DomainAuthenticationTests/UseCases/RestoreSessionTests.swift`에 세션 부재 정리, authorization 상태별 복원, refresh 성공·일시 실패·거부 시 두 Repository의 분리된 호출과 결과 테스트를 작성하고 실패를 확인한다
- [ ] T038 [P] `sources/Projects/Domain/DomainAuthenticationTests/UseCases/ObserveAuthorizationChangesTests.swift`에 authorization 변경 stream을 소비해 저장 상태를 정리하고 `AuthenticationOutcome`만 내보내는 테스트를 작성하고 실패를 확인한다
- [ ] T039 [P] `sources/Projects/Domain/DomainAuthenticationTests/UseCases/SignOutTests.swift`에 서버 세션 로컬 삭제를 먼저 요청한 뒤 인증 참조를 정리하고 원격 폐기 실패와 관계없이 로그아웃하는 호출 순서 테스트를 작성하고 실패를 확인한다

### 2-D. Domain Use Case — Green

- [ ] T040 [P] `sources/Projects/Domain/DomainAuthentication/UseCases/SignIn.swift`에 외부 인증과 서버 세션 시작을 순서대로 조정하고 실패 시 임시 인증 상태를 정리하는 `SignIn`을 구현해 T036을 통과시킨다
- [ ] T041 [P] `sources/Projects/Domain/DomainAuthentication/UseCases/RestoreSession.swift`에 공급자 authorization과 Git It 세션을 함께 검증하고 일시 실패와 명시적 무효화를 구분하는 `RestoreSession`을 구현해 T037을 통과시킨다
- [ ] T042 [P] `sources/Projects/Domain/DomainAuthentication/UseCases/ObserveAuthorizationChanges.swift`에 Repository 변경 stream을 `AuthenticationOutcome`으로 수렴시키는 `ObserveAuthorizationChanges`를 구현해 T038을 통과시킨다
- [ ] T043 [P] `sources/Projects/Domain/DomainAuthentication/UseCases/SignOut.swift`에 세션 종료 후 인증 참조를 별도 정리하는 `SignOut`을 구현해 T039를 통과시킨다

### 2-E. Core 기술 API — Red

- [ ] T044 [P] `sources/Projects/Core/CoreAuthenticationTests/AppleAuthentication/AppleAuthorizationProviderTests.swift`에 명시적 시작, 선택 scope, 성공 credential 변환, 취소, state·attempt 불일치, 시도 만료, token/code 누락, 늦은 콜백 무시 테스트를 작성하고 실패를 확인한다
- [ ] T045 [P] `sources/Projects/Core/CoreAuthenticationTests/AppleAuthentication/AppleCredentialStateProviderTests.swift`에 `authorized`·`revoked`·`notFound`·`transferred`와 revoked 알림·조회 오류를 Core 소유 상태로 격리하는 테스트를 작성하고 실패를 확인한다
- [ ] T046 [P] `sources/Projects/Core/CoreAuthenticationTests/Keychain/KeychainStoreTests.swift`에 key namespace 분리, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` 상당 접근성, 원자적 CRUD와 오류 격리 테스트를 작성하고 실패를 확인한다
- [ ] T047 [P] `sources/Projects/Core/CoreAuthenticationTests/RandomGenerator/SecureRandomGeneratorTests.swift`에 nonce·state·attemptID·grantID용 CSPRNG 출력의 길이, 고유성, 실패 전달 테스트를 작성하고 실패를 확인한다

### 2-F. Core 기술 API — Green

- [ ] T048 [P] `sources/Projects/Core/CoreAuthentication/AppleAuthentication/AppleAuthorizationProvider.swift`에 `AuthenticationServices`를 Core 소유 요청·credential·오류 뒤에 격리하고 시도별 nonce·state·attemptID·expiresAt 검증과 취소를 지원하는 API를 구현해 T044를 통과시킨다
- [ ] T049 [P] `sources/Projects/Core/CoreAuthentication/AppleAuthentication/AppleCredentialStateProvider.swift`에 credential state 조회와 revoked 알림을 Core 소유 상태·stream으로 변환하는 API를 구현해 T045를 통과시킨다
- [ ] T050 [P] `sources/Projects/Core/CoreAuthentication/Keychain/KeychainStore.swift`에 namespace별 기기 한정 Keychain CRUD와 원자적 저장·삭제 API를 구현해 T046을 통과시킨다
- [ ] T051 [P] `sources/Projects/Core/CoreAuthentication/RandomGenerator/SecureRandomGenerator.swift`에 CSPRNG 기반 임의 값 생성 API를 구현해 T047을 통과시킨다

### 2-G. Data 계약과 모델 — Red

- [ ] T052 [P] `sources/Projects/Data/DataAuthenticationTests/Contracts/ExternalAuthenticationProviderContractTests.swift`에 method identifier 기반 인증·authorization 조회·변경 stream만 제공하고 Domain/Core/Apple 타입을 공개하지 않는 계약 테스트를 작성한다
- [ ] T053 [P] `sources/Projects/Data/DataAuthenticationTests/Contracts/SessionRemoteContractTests.swift`에 세션 시작, token refresh, refresh token 폐기만 제공하고 공급자별 필드·Domain/Core 타입을 공개하지 않는 계약 테스트를 작성한다
- [ ] T054 [P] `sources/Projects/Data/DataAuthenticationTests/Contracts/SessionStorageContractTests.swift`에 Git It 서버 세션의 원자적 저장·읽기·삭제만 제공하고 인증 참조를 취급하지 않는 계약 테스트를 작성한다
- [ ] T055 [P] `sources/Projects/Data/DataAuthenticationTests/Contracts/AuthenticationAuthorizationStorageContractTests.swift`에 공급자 인증 참조의 저장·읽기·삭제만 제공하고 서버 세션을 취급하지 않는 계약 테스트를 작성한다
- [ ] T056 [P] `sources/Projects/Data/DataAuthenticationTests/Models/ExternalAuthenticationEvidenceTests.swift`에 method identifier, 불투명 subject reference와 payload만 존재하고 payload가 로그·비교에 노출되지 않는지 검증하는 실패 테스트를 작성한다
- [ ] T057 [P] `sources/Projects/Data/DataAuthenticationTests/Models/ExternalAuthorizationStateTests.swift`에 `active`·`inactive`·`temporarilyUnavailable`만 존재하고 Apple credential state case가 없는지 검증하는 실패 테스트를 작성한다
- [ ] T058 [P] `sources/Projects/Data/DataAuthenticationTests/Errors/DataAuthenticationErrorTests.swift`에 취소, 일시 오류, 저장 실패, 세션 시작·refresh 거부·폐기 실패를 공급자 중립 의미로 분류하는 실패 테스트를 작성한다
- [ ] T059 [P] `sources/Projects/Data/DataAuthenticationTests/DTOs/SessionStartRequestDTOTests.swift`에 method identifier와 불투명 단발성 payload만 전송 입력에 포함되고 Apple 필드명이 없는지 검증하는 실패 테스트를 작성한다
- [ ] T060 [P] `sources/Projects/Data/DataAuthenticationTests/DTOs/SessionResponseDTOTests.swift`에 Git It 사용자, access/refresh token, access 만료만 세션 응답에 포함되는지 검증하는 실패 테스트를 작성한다
- [ ] T061 [P] `sources/Projects/Data/DataAuthenticationTests/DTOs/RefreshDTOTests.swift`에 공급자와 무관한 refresh 요청·응답 및 거부·만료 처리 입력을 검증하는 실패 테스트를 작성한다
- [ ] T062 [P] `sources/Projects/Data/DataAuthenticationTests/Models/StoredSessionTests.swift`에 서버 세션 저장 모델이 token·만료·사용자만 가지며 `appleUserID`와 인증 참조를 포함하지 않는지 검증하는 실패 테스트를 작성한다
- [ ] T063 [P] `sources/Projects/Data/DataAuthenticationTests/Models/StoredAuthorizationReferenceTests.swift`에 method identifier와 불투명 subject reference가 서버 세션과 분리되는지 검증하는 실패 테스트를 작성한다

### 2-H. Data 계약과 모델 — Green

- [ ] T064 [P] `sources/Projects/Data/DataAuthentication/Models/ExternalAuthenticationEvidence.swift`에 공급자 중립 method identifier·subject reference·opaque payload 모델을 정의해 T056을 통과시킨다
- [ ] T065 [P] `sources/Projects/Data/DataAuthentication/Models/ExternalAuthorizationState.swift`에 `active`·`inactive`·`temporarilyUnavailable` 상태만 정의해 T057를 통과시킨다
- [ ] T066 [P] `sources/Projects/Data/DataAuthentication/DTOs/SessionStartRequestDTO.swift`에 method identifier와 불투명 일회성 payload만 가진 세션 시작 요청을 정의해 T059을 통과시킨다
- [ ] T067 [P] `sources/Projects/Data/DataAuthentication/DTOs/SessionResponseDTO.swift`에 Git It 사용자와 access/refresh token·만료를 가진 세션 응답을 정의해 T060을 통과시킨다
- [ ] T068 [P] `sources/Projects/Data/DataAuthentication/DTOs/RefreshRequestDTO.swift`에 refresh token만 가진 공급자 중립 갱신 요청을 정의해 T061을 통과시킨다
- [ ] T069 [P] `sources/Projects/Data/DataAuthentication/DTOs/RefreshResponseDTO.swift`에 새 access token·만료와 필요 시 교체 refresh token을 가진 갱신 응답을 정의해 T061을 통과시킨다
- [ ] T070 [P] `sources/Projects/Data/DataAuthentication/Models/StoredSession.swift`에 access/refresh token·만료·사용자만 가진 서버 세션 저장 모델을 정의해 T062를 통과시킨다
- [ ] T071 [P] `sources/Projects/Data/DataAuthentication/Models/StoredAuthorizationReference.swift`에 method identifier와 provider subject reference만 가진 인증 참조 저장 모델을 정의해 T063을 통과시킨다
- [ ] T072 [P] `sources/Projects/Data/DataAuthentication/Errors/DataAuthenticationError.swift`에 외부 인증·저장·세션 시작·refresh·폐기 오류를 공급자 중립 의미로 정의해 T058를 통과시킨다
- [ ] T073 [P] `sources/Projects/Data/DataAuthentication/Contracts/ExternalAuthenticationProvider.swift`에 인증, authorization 상태 조회와 변경 stream을 제공하는 `Sendable` 계약을 정의해 T052를 통과시킨다
- [ ] T074 [P] `sources/Projects/Data/DataAuthentication/Contracts/SessionRemote.swift`에 공급자 중립 `startSession`, token refresh, refresh token 폐기 연산만 정의해 T053을 통과시킨다
- [ ] T075 [P] `sources/Projects/Data/DataAuthentication/Contracts/SessionStorage.swift`에 Git It 서버 세션의 원자적 저장·읽기·삭제 계약만 정의해 T054를 통과시킨다
- [ ] T076 [P] `sources/Projects/Data/DataAuthentication/Contracts/AuthenticationAuthorizationStorage.swift`에 공급자 인증 참조의 저장·읽기·삭제 계약만 정의해 T055를 통과시킨다

### 2-I. Composition 경계 — Red

- [ ] T077 [P] `sources/Projects/Composition/CompositionTests/Authentication/AuthenticationGrantVaultTests.swift`에 결정적 ID 생성기 주입, 첫 소비, 중복·만료·method 불일치 거부, 전체 정리와 payload 미노출 테스트를 작성한다
- [ ] T078 [P] `sources/Projects/Composition/CompositionTests/Authentication/Adapters/DomainAuthenticationRepositoryAdapterTests.swift`에 Domain method/status/error와 Data identifier/state/error 변환, vault 등록, 인증 참조 저장 rollback, Core·서버 미호출 테스트를 작성한다
- [ ] T079 [P] `sources/Projects/Composition/CompositionTests/Authentication/Adapters/DomainSessionRepositoryAdapterTests.swift`에 grant 단발 소비, 세션 시작·원자적 저장, restore·refresh 분류, signOut 로컬 우선 삭제, 실패 rollback과 인증 API 미호출 테스트를 작성한다
- [ ] T080 [P] `sources/Projects/Composition/CompositionTests/Authentication/Adapters/DataCoreExternalAuthenticationProviderAdapterTests.swift`에 Data method identifier의 Core Apple API 선택, Core credential의 불투명 evidence 변환, credential state·알림의 Data 상태 수렴과 오류 변환 테스트를 작성한다
- [ ] T081 [P] `sources/Projects/Composition/CompositionTests/Authentication/Adapters/DataCoreSessionStorageAdapterTests.swift`에 서버 세션 전용 namespace의 Keychain 인코딩·원자적 저장·읽기·삭제 테스트를 작성한다
- [ ] T082 [P] `sources/Projects/Composition/CompositionTests/Authentication/Adapters/DataCoreAuthenticationAuthorizationStorageAdapterTests.swift`에 인증 참조 전용 namespace의 Keychain 인코딩·저장·읽기·삭제와 세션 namespace 비공유 테스트를 작성한다
- [ ] T083 [P] `sources/Projects/Composition/CompositionTests/Authentication/SessionCoordinatorTests.swift`에 세션 세대 캡처·증가와 이전 세대의 시작·복원·refresh 결과 거부 테스트를 작성한다
- [ ] T084 [P] `sources/Projects/Composition/CompositionTests/Authentication/Mocks/AuthenticationMocksTests.swift`에 Domain 인증, Data 외부 인증, Core Apple Mock이 성공·취소·오류·authorization 상태를 결정적으로 재현하고 서버 세션을 만들지 않는지 테스트한다
- [ ] T085 [P] `sources/Projects/Composition/CompositionTests/Authentication/Mocks/SessionMocksTests.swift`에 세션 Remote·Storage Mock이 신규·기존 사용자, 선택 프로필 부재, refresh 성공·일시 실패·거부, 폐기 실패를 결정적으로 재현하는지 테스트한다
- [ ] T086 [P] `sources/Projects/Composition/CompositionTests/Authentication/UnavailableSessionRemoteTests.swift`에 서버 endpoint 미구성 시 세션 성공 대신 안전한 복구 가능 오류를 반환하는 실패 테스트를 작성한다
- [ ] T087 [P] `sources/Projects/Composition/CompositionTests/Authentication/AppCompositionAuthenticationTests.swift`에 live·Mock·unavailable 환경별 구현 선택, vault·세션 조정 actor 공유 수명, 네 Domain use case의 명시적 생성자 조립과 전역 container 부재를 검증하는 실패 테스트를 작성한다

### 2-J. Composition 경계 — Green

- [ ] T088 `sources/Projects/Composition/Composition/Authentication/AuthenticationGrantVault.swift`에 initializer로 ID 생성 closure를 받고 evidence를 메모리에서 단발 소비·만료·전체 정리하는 actor를 구현해 T077를 통과시킨다
- [ ] T089 `sources/Projects/Composition/Composition/Authentication/Adapters/DomainAuthenticationRepositoryAdapter.swift`에 Domain `AuthenticationRepository`와 Data 외부 인증·인증 참조 저장 계약 사이의 변환과 vault rollback을 구현해 T078를 통과시킨다
- [ ] T090 `sources/Projects/Composition/Composition/Authentication/Adapters/DomainSessionRepositoryAdapter.swift`에 Domain `SessionRepository`와 vault·`SessionRemote`·`SessionStorage`·세션 조정 actor 사이의 시작·복원·refresh·로그아웃 흐름을 구현해 T079을 통과시킨다
- [ ] T091 [P] `sources/Projects/Composition/Composition/Authentication/Adapters/DataCoreExternalAuthenticationProviderAdapter.swift`에 Data method identifier·상태·오류와 Core Apple API 사이의 변환을 구현하고 Apple 타입·case를 Adapter 밖으로 내보내지 않아 T080을 통과시킨다
- [ ] T092 [P] `sources/Projects/Composition/Composition/Authentication/Adapters/DataCoreSessionStorageAdapter.swift`에 서버 세션 전용 Keychain namespace Adapter를 구현해 T081을 통과시킨다
- [ ] T093 [P] `sources/Projects/Composition/Composition/Authentication/Adapters/DataCoreAuthenticationAuthorizationStorageAdapter.swift`에 공급자 인증 참조 전용 Keychain namespace Adapter를 구현해 T082를 통과시킨다
- [ ] T094 [P] `sources/Projects/Composition/Composition/Authentication/SessionCoordinator.swift`에 세션 generation 관리와 늦은 비동기 결과 차단 actor를 구현해 T083을 통과시킨다
- [ ] T095 [P] `sources/Projects/Composition/Composition/Authentication/Mocks/MockAuthenticationRepository.swift`에 명시적 개발·통합 테스트용 Domain 인증 Mock을 구현해 T084을 통과시킨다
- [ ] T096 [P] `sources/Projects/Composition/Composition/Authentication/Mocks/MockExternalAuthenticationProvider.swift`에 Data evidence·authorization 상태·오류를 결정적으로 반환하는 Mock을 구현해 T084을 통과시킨다
- [ ] T097 [P] `sources/Projects/Composition/Composition/Authentication/Mocks/MockAppleAuthorizationProvider.swift`에 Core 소유 Apple 인증 API의 성공·취소·오류·상태 변경 Test Double을 구현해 T084을 통과시킨다
- [ ] T098 [P] `sources/Projects/Composition/Composition/Authentication/Mocks/MockSessionRemote.swift`에 신규·기존 계정과 세션 시작·refresh·폐기 결과를 결정적으로 반환하는 Mock을 구현해 T085를 통과시킨다
- [ ] T099 [P] `sources/Projects/Composition/Composition/Authentication/Mocks/MockSessionStorage.swift`에 원자적 저장·읽기·삭제와 호출 기록을 제공하는 서버 세션 저장 Mock을 구현해 T085를 통과시킨다
- [ ] T100 [P] `sources/Projects/Composition/Composition/Authentication/Mocks/MockAuthenticationAuthorizationStorage.swift`에 서버 세션과 분리된 인증 참조 저장 Mock을 구현해 T084과 T085를 통과시킨다
- [ ] T101 [P] `sources/Projects/Composition/Composition/Authentication/UnavailableSessionRemote.swift`에 live endpoint가 없는 구성에서 세션을 열지 않는 실패 구현을 작성해 T086을 통과시킨다
- [ ] T102 `sources/Projects/Composition/Composition/Authentication/AppComposition+Authentication.swift`에 Core CSPRNG closure, 두 저장 Adapter, Data↔Core·Domain↔Data Adapter, 공유 vault·세션 조정 actor를 생성자 주입으로 조립하고 Mock/live/unavailable 환경 선택과 네 Domain use case만 공개해 T087을 통과시킨다
- [ ] T103 [no-write] `sources/`에서 `tuist generate` 후 저장소 루트에서 `project_build_runner build`, `compile`, `test`를 순서대로 실행해 T018~T102의 모든 기반 테스트와 패키지 의존 경계를 검증한다

**점검 지점**: Domain·Data·Core 공개 API가 각 패키지 소유 언어만 사용하고,
`Domain → Data/Core`, `Data → Core/Domain` 의존이 없으며 Composition만 두 Adapter 경계를
연결해야 한다.

---

## 단계 3: 사용자 스토리 1 - Apple 계정으로 처음 로그인 (우선순위: P1) 🎯 MVP

**목표**: 로그아웃 사용자가 명시적으로 Apple 로그인을 선택해 Mock 서버 교환을 거친 뒤
하나의 Git It 계정으로 인증된 첫 화면에 도달한다.

**독립 테스트**: 빈 인증 참조·세션 저장소에서 이름·이메일이 있거나 없는 신규 사용자 결과를
주입하고, 인증→단발 grant→세션 저장→인증 화면 전환과 중복 탭 차단을 검증한다.

### 사용자 스토리 1 — Red

- [ ] T104 [P] [US1] `sources/Projects/Composition/CompositionTests/Authentication/FirstSignInIntegrationTests.swift`에 신규 사용자, 이메일 가리기·이름 부재, grant 한 번 소비, 세션 저장 뒤 성공, 중복 소비 거부를 분리된 인증·세션 Mock으로 검증하는 실패 테스트를 작성한다
- [ ] T105 [P] [US1] `sources/Projects/Feature/FeatureAuthenticationTests/SignInFeatureTests.swift`에 `.apple` 선택 시 주입된 `SignIn`을 한 번 호출하고 unauthenticated → authenticating → establishingSession → authenticated로 전이하며 State·Action에 grant payload·token이 없는지 검증하는 실패 테스트를 작성한다
- [ ] T106 [P] [US1] `sources/Projects/Feature/FeatureAuthenticationTests/SignInDuplicateTapTests.swift`에 authenticating·establishingSession 상태의 반복 선택이 새 Effect를 시작하지 않는지 검증하는 실패 테스트를 작성한다

### 사용자 스토리 1 — Green

- [ ] T107 [US1] `sources/Projects/Feature/FeatureAuthentication/Authentication/AuthenticationFeature.swift`에 생성자로 네 Domain use case를 받고 로그인 상태·action·delegate와 `SignIn` Effect, 중복 선택 차단을 구현해 T105과 T106를 통과시킨다
- [ ] T108 [P] [US1] `sources/Projects/UI/UIComponent/Authentication/AppleSignInButton.swift`에 Apple 디자인 지침과 접근성을 따르며 범용 탭 closure만 노출하는 재사용 가능한 로그인 제어를 구현한다
- [ ] T109 [US1] `sources/Projects/Feature/FeatureAuthentication/Authentication/Views/SignInView.swift`에 `AppleSignInButton`을 조립하고 `AuthenticationMethod.apple` 선택 action만 전달하는 로그인 화면과 진행 상태를 구현한다
- [ ] T110 [US1] `sources/Projects/Feature/FeatureAuthentication/Authentication/Views/AuthenticatedView.swift`에 안전한 사용자 표시 정보와 로그아웃 intent만 노출하는 인증된 첫 화면을 구현한다
- [ ] T111 [US1] `sources/Projects/App/Sources/ContentView.swift`에 `AuthenticationFeature` Store를 받아 checking, unauthenticated, authenticating, establishingSession, authenticated 상태별 root 화면을 선택하는 조정 View를 구현한다
- [ ] T112 [US1] `sources/Projects/App/Sources/GitItApp.swift`에 실행 환경에 맞는 `AppComposition`을 만들고 네 Domain use case를 `AuthenticationFeature` initializer에 명시적으로 주입해 root Store를 구성한다
- [ ] T113 [US1] [no-write] `specs/001-apple-social-login/quickstart.md`의 시나리오 1을 Mock으로 실행해 신규 사용자·선택 프로필 부재·중복 탭에서 계정 하나와 인증된 첫 화면이 만들어지고 민감 값이 출력되지 않는지 확인한다

**점검 지점**: US1만으로 빈 저장소에서 Apple 인증 선택부터 인증된 첫 화면까지 독립적으로
시연하고 테스트할 수 있어야 한다.

---

## 단계 4: 사용자 스토리 2 - 기존 Apple 계정으로 다시 로그인 (우선순위: P2)

**목표**: 기존 사용자가 같은 Apple 계정으로 돌아오고 앱 재실행에서 세션을 복원·갱신하며,
로그아웃으로 로컬 인증 상태를 즉시 종료한다.

**독립 테스트**: 기존 사용자와 분리 저장된 인증 참조·서버 세션을 준비해 프로필 부재 로그인,
유효 세션 복원, refresh, 로그아웃, 재실행과 늦은 refresh 결과를 각각 검증한다.

### 사용자 스토리 2 — Red

- [ ] T114 [P] [US2] `sources/Projects/Composition/CompositionTests/Authentication/ExistingUserSessionIntegrationTests.swift`에 이름·이메일 없는 기존 사용자 로그인, 같은 이메일이지만 연결되지 않은 Apple subject의 자동 병합 금지, 유효 세션 복원, 만료 access token refresh, 로컬 우선 로그아웃과 원격 폐기 실패를 검증하는 실패 테스트를 작성한다
- [ ] T115 [P] [US2] `sources/Projects/Feature/FeatureAuthenticationTests/SessionRestoreFeatureTests.swift`에 앱 시작과 재시도에서 `RestoreSession` 결과만으로 checking → authenticated/unauthenticated/recoverableFailure가 전이하는 실패 테스트를 작성한다
- [ ] T116 [P] [US2] `sources/Projects/Feature/FeatureAuthenticationTests/SignOutFeatureTests.swift`에 인증 상태의 로그아웃이 `SignOut`을 호출하고 진행 Effect를 취소한 뒤 unauthenticated로 전이하며 저장소를 직접 만지지 않는지 검증하는 실패 테스트를 작성한다
- [ ] T117 [P] [US2] `sources/Projects/Composition/CompositionTests/Authentication/SessionCoordinatorRaceTests.swift`에 refresh 진행 중 로그아웃으로 generation이 증가한 뒤 늦은 성공 응답이 Keychain과 화면 상태를 되살리지 않는지 검증하는 실패 테스트를 작성한다

### 사용자 스토리 2 — Green

- [ ] T118 [US2] `sources/Projects/Feature/FeatureAuthentication/Authentication/AuthenticationFeature.swift`에 앱 시작·복구 시 `RestoreSession`을 호출하고 결과를 checking에서 해당 화면 상태로 변환하는 action과 Effect를 추가해 T115을 통과시킨다
- [ ] T119 [US2] `sources/Projects/Feature/FeatureAuthentication/Authentication/AuthenticationFeature.swift`에 인증 상태의 로그아웃 action, 진행 Effect 취소, `SignOut` 완료 후 unauthenticated 전이를 추가해 T116를 통과시킨다
- [ ] T120 [US2] `sources/Projects/Feature/FeatureAuthentication/Authentication/Views/AuthenticatedView.swift`에 접근 가능한 로그아웃 버튼을 연결하고 저장소·네트워크 세부 동작은 action으로 위임한다
- [ ] T121 [US2] `sources/Projects/App/Sources/GitItApp.swift`에 앱 시작 시 세션 복원 action을 한 번 발행하고 앱 생명주기 재진입이 중복 복원을 만들지 않도록 연결한다
- [ ] T122 [US2] [no-write] `specs/001-apple-social-login/quickstart.md`의 시나리오 2·4·5 중 기존 사용자, 복원·refresh, 로그아웃 경쟁·원격 폐기 실패를 Mock으로 실행하고 재실행 후 상태를 확인한다

**점검 지점**: US2 fixture만으로 기존 계정 재사용, 자동 로그인, refresh, 로그아웃과 앱 재실행
후 비인증 상태를 독립적으로 검증할 수 있어야 한다.

---

## 단계 5: 사용자 스토리 3 - 취소 및 오류에서 안전하게 복구 (우선순위: P3)

**목표**: 인증 취소, 일시 오류, 연결 철회, refresh 거부에서도 보호된 콘텐츠를 열지 않고
안정적인 로그인 또는 복구 화면과 재시도를 제공한다.

**독립 테스트**: 취소·일시 네트워크 오류·authorization 조회 오류·연결 철회·refresh 거부를
각각 Mock으로 주입해 저장 정책과 화면 전이를 검증한다.

### 사용자 스토리 3 — Red

- [ ] T123 [P] [US3] `sources/Projects/Composition/CompositionTests/Authentication/AuthenticationRecoveryIntegrationTests.swift`에 취소, 인증 참조 저장 실패, 세션 시작 실패, authorization 일시 오류·철회, refresh 일시 오류·거부, 계정 이용 불가의 저장·정리 정책을 검증하는 실패 테스트를 작성한다
- [ ] T124 [P] [US3] `sources/Projects/Feature/FeatureAuthenticationTests/CancelFeatureTests.swift`에 Domain `cancelled`가 오류 경고·grant·세션 없이 unauthenticated로 돌아가는지 검증하는 실패 테스트를 작성한다
- [ ] T125 [P] [US3] `sources/Projects/Feature/FeatureAuthenticationTests/RecoverableFailureFeatureTests.swift`에 일시 오류의 recoverableFailure 전환, 보호 화면 차단, 재시도 후 성공 또는 비인증 전이를 검증하는 실패 테스트를 작성한다
- [ ] T126 [P] [US3] `sources/Projects/Feature/FeatureAuthenticationTests/AuthorizationInvalidatedFeatureTests.swift`에 `ObserveAuthorizationChanges`가 보낸 outcome만으로 철회·refresh 거부를 처리하고 Feature가 Repository나 Apple 상태를 판단하지 않는지 검증하는 실패 테스트를 작성한다

### 사용자 스토리 3 — Green

- [ ] T127 [US3] `sources/Projects/Feature/FeatureAuthentication/Authentication/Views/RecoveryView.swift`에 민감 정보 없는 오류 안내, 접근 가능한 재시도 버튼, 보호된 콘텐츠 미표시를 구현한다
- [ ] T128 [US3] `sources/Projects/Feature/FeatureAuthentication/Authentication/AuthenticationFeature.swift`에 recoverableFailure의 재시도 action과 `RestoreSession` 재실행 후 상태 전이를 추가해 T125을 통과시킨다
- [ ] T129 [US3] `sources/Projects/Feature/FeatureAuthentication/Authentication/AuthenticationFeature.swift`에 앱 인증 흐름의 수명 동안 주입된 `ObserveAuthorizationChanges` stream을 한 번 구독하고 outcome 기반 상태 전이를 추가해 T126을 통과시킨다
- [ ] T130 [US3] `sources/Projects/App/Sources/ContentView.swift`에 recoverableFailure 상태의 `RecoveryView`와 재시도 action 연결을 추가한다
- [ ] T131 [US3] [no-write] `specs/001-apple-social-login/quickstart.md`의 시나리오 3·4·5에서 취소·일시 오류·철회·refresh 거부를 실행해 토큰 보존·삭제 정책과 3초 이내 안정 화면 전환을 구분해 확인한다

**점검 지점**: US3의 각 오류 fixture가 서로 독립적으로 실행되고 실패 뒤 정상 재시도가 이전
시도의 임시 상태에 영향을 받지 않아야 한다.

---

## 단계 6: 마무리와 횡단 관심사

**목적**: 민감 정보 비노출, 접근성, 전체 빌드·테스트, Mock·실제 Apple 검증과 임시 파일
정리를 완료한다.

- [ ] T132 [P] `sources/Projects/Domain/DomainAuthenticationTests/Security/SensitiveValueExposureTests.swift`에 Domain 모델·오류·결과의 문자열 표현과 실패 출력에 외부 credential·token·nonce·state 필드가 존재하지 않는지 검증하는 테스트를 작성한다
- [ ] T133 [P] `sources/Projects/Data/DataAuthenticationTests/Security/SensitiveValueExposureTests.swift`에 opaque payload와 token DTO가 `CustomStringConvertible`·디버그 출력·오류 메시지로 민감 값을 노출하지 않는지 검증하는 테스트를 작성한다
- [ ] T134 [P] `sources/Projects/Core/CoreAuthenticationTests/Security/SensitiveValueExposureTests.swift`에 Apple 원시 credential, nonce, state와 Keychain 값이 오류·설명 문자열에 포함되지 않는지 검증하는 테스트를 작성한다
- [ ] T135 [P] `sources/Projects/Composition/CompositionTests/Authentication/SensitiveValueExposureTests.swift`에 grant vault·Adapter·Mock 호출 기록과 테스트 실패 메시지가 payload·token·provider subject를 출력하지 않는지 검증하는 테스트를 작성한다
- [ ] T136 [P] `sources/Projects/Feature/FeatureAuthenticationTests/SensitiveValueExposureTests.swift`에 TCA State·Action·delegate·접근성 값이 grant ID, payload, token, provider subject를 보유하지 않는지 검증하는 테스트를 작성한다
- [ ] T137 [P] [no-write] `sources/Projects/Domain/DomainAuthentication/`, `sources/Projects/Data/DataAuthentication/`, `sources/Projects/Feature/FeatureAuthentication/`에서 `AuthenticationServices`, `ASAuthorization`, `identityToken`, `authorizationCode`, `@Dependency`와 Apple 이외의 회원가입·비밀번호 자격 증명 경로를 검색해 계획에서 허용하지 않은 경계 누출이 없는지 확인한다
- [ ] T138 [P] [no-write] `sources/Projects/UI/UIComponent/Authentication/AppleSignInButton.swift`와 `sources/Projects/Feature/FeatureAuthentication/Authentication/Views/`의 로그인, 진행, 로그아웃, 오류, 재시도 제어를 VoiceOver로 식별·조작하고 민감 값이 접근성 출력에 없는지 확인한다
- [ ] T139 [no-write] 저장소 루트에서 `project_build_runner build`, `compile`, `test`를 순서대로 실행해 모든 공유 scheme과 Domain·Data·Core·Composition·Feature·App 테스트를 검증한다
- [ ] T140 [no-write] `specs/001-apple-social-login/quickstart.md`의 Mock 자동화 시나리오 1~5를 모두 실행하고 SC-003·SC-006·SC-007·SC-009~SC-012의 시간·상태 기준을 확인한다
- [ ] T141 [no-write] `specs/001-apple-social-login/quickstart.md`의 실제 Apple 시스템 인증 수동 검증을 capability가 준비된 기기 또는 Simulator에서 실행하고, 준비되지 않았다면 미검증 범위를 명시한다
- [ ] T142 [P] 구현 파일이 존재함을 확인한 뒤 `sources/Projects/Core/CoreAuthentication/Placeholder.swift`를 삭제한다
- [ ] T143 [P] 실제 테스트 파일이 존재함을 확인한 뒤 `sources/Projects/Core/CoreAuthenticationTests/Placeholder.swift`를 삭제한다
- [ ] T144 [P] 구현 파일이 존재함을 확인한 뒤 `sources/Projects/Data/DataAuthentication/Placeholder.swift`를 삭제한다
- [ ] T145 [P] 실제 테스트 파일이 존재함을 확인한 뒤 `sources/Projects/Data/DataAuthenticationTests/Placeholder.swift`를 삭제한다
- [ ] T146 [P] 구현 파일이 존재함을 확인한 뒤 `sources/Projects/Domain/DomainAuthentication/Placeholder.swift`를 삭제한다
- [ ] T147 [P] 실제 테스트 파일이 존재함을 확인한 뒤 `sources/Projects/Domain/DomainAuthenticationTests/Placeholder.swift`를 삭제한다
- [ ] T148 [P] 구현 파일이 존재함을 확인한 뒤 `sources/Projects/Feature/FeatureAuthentication/Placeholder.swift`를 삭제한다
- [ ] T149 [P] 실제 테스트 파일이 존재함을 확인한 뒤 `sources/Projects/Feature/FeatureAuthenticationTests/Placeholder.swift`를 삭제한다
- [ ] T150 [P] 실제 Composition 구현 파일이 존재함을 확인한 뒤 `sources/Projects/Composition/Composition/Placeholder.swift`를 삭제한다
- [ ] T151 [P] 실제 Composition 테스트 파일이 존재함을 확인한 뒤 `sources/Projects/Composition/CompositionTests/Placeholder.swift`를 삭제한다
- [ ] T152 [P] `AppleSignInButton.swift`가 타겟 소스로 포함됨을 확인한 뒤 `sources/Projects/UI/UIComponent/Placeholder.swift`를 삭제한다
- [ ] T153 [no-write] Placeholder 삭제 후 `sources/`에서 `tuist generate`를 다시 실행하고 저장소 루트에서 `project_build_runner build`, `compile`, `test`를 순서대로 재실행해 최종 graph와 전체 회귀 테스트를 확인한다

---

## 의존성과 실행 순서

### 단계 의존성 그래프

```text
단계 1 준비
  └─> 단계 2 기반
        └─> 단계 3 US1(MVP)
              └─> 단계 4 US2
                    └─> 단계 5 US3
                          └─> 단계 6 마무리
```

- **단계 1**은 즉시 시작한다. T001 뒤 T002~T006을 병렬로 수행하고, 타겟 등록 뒤
  T008~T016을 병렬로 수행한 다음 T017로 graph를 검증한다.
- **단계 2**는 단계 1 완료에 의존하며 모든 스토리를 차단한다. 각 Red 그룹을 먼저 실패시킨
  뒤 대응 Green 그룹을 수행한다.
- **US1**은 기반 완료 뒤 시작하며 사용자 가치의 최소 증분이다.
- **US2**의 독립 수용 기준은 별도 fixture로 검증할 수 있지만
  `AuthenticationFeature.swift`, `AuthenticatedView.swift`, `GitItApp.swift`를 확장하므로
  파일 충돌을 피하기 위해 US1 뒤에 수행한다.
- **US3**도 독립 오류 fixture로 검증하지만 `AuthenticationFeature.swift`와
  `ContentView.swift`를 확장하므로 US2 뒤에 수행한다.
- **마무리**는 제공할 모든 스토리 완료 뒤 수행한다.

### 기반 단계 내부 의존성

- T018~T026 Red → T027~T035 Green → T036~T039 Red → T040~T043 Green
- T044~T047 Red → T048~T051 Green
- T052~T063 Red → T064~T072 Green → T073~T076 계약
- Domain·Data·Core Green 완료 → T077~T087 Red → T088~T102 Green
- T103은 기반 단계의 최종 게이트다.

### 사용자 스토리 내부 의존성

- **US1**: T104~T106 Red → T107~T112 Green → T113 독립 검증
- **US2**: T114~T117 Red → T118~T121 Green → T122 독립 검증
- **US3**: T123~T126 Red → T127~T130 Green → T131 독립 검증

---

## 병렬 실행 예시

### 기반 단계

```text
T018~T026  Domain 모델·계약 Red 테스트
T044~T047  Core 기술 API Red 테스트
T052~T063  Data 계약·모델 Red 테스트
```

각 그룹의 선행 타겟이 준비된 뒤 서로 다른 파일을 사용하는 `[P]` 태스크를 병렬로 실행한다.
Green 태스크는 반드시 대응 Red 테스트의 실패를 확인한 뒤 시작한다.

### 사용자 스토리 1

```text
T104  Composition 최초 로그인 통합 테스트
T105  Feature 정상 로그인 상태 전이 테스트
T106  Feature 중복 탭 차단 테스트
```

### 사용자 스토리 2

```text
T114  기존 사용자·세션 통합 테스트
T115  Feature 세션 복원 테스트
T116  Feature 로그아웃 테스트
T117  로그아웃·refresh 경쟁 테스트
```

### 사용자 스토리 3

```text
T123  Composition 복구 정책 통합 테스트
T124  Feature 취소 테스트
T125  Feature 복구 가능 오류 테스트
T126  Feature authorization 무효화 테스트
```

---

## 구현 전략

### MVP 우선

1. 단계 1의 Tuist·테스트 타겟 준비를 완료한다.
2. 단계 2의 공통 경계를 TDD로 완료하고 T103 게이트를 통과한다.
3. 단계 3의 US1 하위 태스크 T104~T113만 완료한다.
4. 빈 저장소와 분리된 인증·세션 Mock으로 최초 로그인을 독립 검증한다.
5. 실제 server endpoint가 없으면 `UnavailableSessionRemote`를 production 기본값으로 유지하고
   Mock은 명시적 개발·테스트 구성에서만 선택한다.

### 점진적 제공

1. 준비 + 기반 → 안전한 인증·세션 경계
2. US1 → 최초 Apple 로그인 MVP
3. US2 → 기존 계정, 자동 로그인, refresh, 로그아웃
4. US3 → 취소·오류·철회 복구
5. 마무리 → 보안·접근성·전체 검증과 임시 파일 정리

---

## 참고

- `[P]`는 선행 조건이 끝난 뒤 서로 다른 파일에서 실행할 수 있다는 뜻이다.
- 사용자 스토리 태스크에는 반드시 `[US1]`, `[US2]`, `[US3]` 라벨을 붙인다.
- Setup, Foundational, 마무리 태스크에는 사용자 스토리 라벨을 붙이지 않는다.
- 실제 서버 URL, HTTP method, 헤더와 JSON 필드는 확정 전까지 만들지 않는다.
- Apple `identityToken`·`authorizationCode`는 서버 교환 입력으로만 메모리에서 다루고 Git It
  세션 토큰으로 사용하거나 영구 저장하지 않는다.
- production 의존성은 생성자 또는 명시적 초기화 인자로만 전달하며 `@Dependency`,
  Service Locator, 전역 mutable container를 사용하지 않는다.
- 각 태스크 완료 시 대응 테스트를 통과시키고, 체크포인트에서는 전체 빌드·테스트를 다시
  확인한다.
