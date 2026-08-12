# 작업 목록: Apple 소셜 로그인

**입력**: `specs/001-apple-social-login/`의 설계 문서

**선행 조건**: plan.md, spec.md, research.md, data-model.md,
contracts/authentication-boundary.md, quickstart.md

**사용자 요청 반영**: 이미 완료한 단계 1(T001~T017)은 재실행·재조정 대상에서 제외하고
완료 이력으로 보존한다. 남은 구현은 프로젝트 내부 의존성이 없는 패키지에서 의존성이
가장 큰 패키지로 올라가는 7개 작업 패키지로 나누며, 한 번의 `/speckit-implement`
실행에서는 승인받은 패키지 하나만 구현·검증한다.

**이관 상태**: 헌법 v1.2.1 적용 시 이미 완료된 T001~T047과 기존 작업 트리 변경은
재실행하거나 되돌리지 않고 이력으로 보존한다. 남은 파일 변경은 새 패키지 순서와 소유
단계에 따라서만 수행하며, 승인되지 않은 패키지의 기존 변경에는 추가 수정을 하지 않는다.

**테스트 접근**: TDD(Red → Green → Refactor). 현재 작업 패키지의 테스트에서 먼저 실패를
확인한 뒤 같은 패키지의 구현으로 통과시키고, 패키지 경계를 유지한 채 중복을 정리한 후
다시 테스트한다.

## 형식: `[ID] [P?] [스토리] 설명`

- **[P]**: 같은 작업 패키지 안에서 선행 조건이 끝난 뒤 서로 다른 파일을 병렬 실행 가능
- **[스토리]**: 작업이 속한 사용자 스토리(US1, US2, US3)
- **[no-write]**: 추적 파일을 변경하지 않는 명령 실행 또는 수동 검증
- 파일을 변경하는 태스크는 `/speckit-implement`의 허용 목록이 되도록 정확한 저장소 상대
  경로 하나를 명시한다.
- 서로 다른 작업 패키지는 같은 깊이에 있어도 승인 게이트를 넘어 병렬 실행하지 않는다.

## 공통 검증 명령

전체 완료 검증에서는 저장소 루트에서 build runner를 해석한 뒤
`build` → `compile` → `test` 순서를 유지한다.

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

---

## 단계 1: 준비(완료·재조정 제외)

**목적**: 인증 모듈과 독립 테스트 타겟을 Tuist graph에 등록하고 빈 타겟의 생성·빌드를
검증한다.

**상태**: 2026-08-12 기준 T001~T017 완료. 아래 작업은 패키지별 승인 순서에 포함하지 않고
다시 실행하지 않는다.

- [X] T001 `sources/Tuist/ProjectDescriptionHelpers/Target+Module.swift`에 명시적인 테스트 타겟 이름, production 타겟 의존성, 추가 의존성을 받는 `testModule` factory를 추가한다
- [X] T002 [P] `sources/Tuist/ProjectDescriptionHelpers/Projects/CoreModuleName.swift`에 `CoreAuthentication`과 `CoreAuthenticationTests` 타겟을 등록하고 production 타겟에 `AuthenticationServices`·`Security` SDK 의존성, 테스트 타겟에 production 타겟 의존성을 선언한다
- [X] T003 [P] `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`에 프로젝트 내부 의존성이 없는 `DataAuthentication`과 이를 검증하는 `DataAuthenticationTests` 타겟을 등록한다
- [X] T004 [P] `sources/Tuist/ProjectDescriptionHelpers/Projects/DomainModuleName.swift`에 프로젝트 내부 의존성이 없는 `DomainAuthentication`과 이를 검증하는 `DomainAuthenticationTests` 타겟을 등록한다
- [X] T005 [P] `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`에 `DomainAuthentication`·`UIComponent`·`ComposableArchitecture`에만 의존하는 `FeatureAuthentication`과 해당 테스트 타겟을 등록한다
- [X] T006 [P] `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`에서 `Composition` 타겟에 `DomainAuthentication`·`DataAuthentication`·`CoreAuthentication` 의존성을 추가하고 같은 경계를 검증하는 `CompositionTests` 타겟을 등록한다
- [X] T007 `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`의 `GitIt` 타겟에 `FeatureAuthentication`과 `DomainAuthentication` 의존성을 추가하되 기존 `Composition`·`Feature`·Firebase 의존성을 보존한다
- [X] T008 [P] `sources/Projects/Core/CoreAuthentication/Placeholder.swift`를 생성해 `CoreAuthentication` production 타겟의 초기 소스 glob을 충족한다
- [X] T009 [P] `sources/Projects/Core/CoreAuthenticationTests/Placeholder.swift`를 생성해 `CoreAuthenticationTests` 타겟의 초기 테스트 소스 glob을 충족한다
- [X] T010 [P] `sources/Projects/Data/DataAuthentication/Placeholder.swift`를 생성해 `DataAuthentication` production 타겟의 초기 소스 glob을 충족한다
- [X] T011 [P] `sources/Projects/Data/DataAuthenticationTests/Placeholder.swift`를 생성해 `DataAuthenticationTests` 타겟의 초기 테스트 소스 glob을 충족한다
- [X] T012 [P] `sources/Projects/Domain/DomainAuthentication/Placeholder.swift`를 생성해 `DomainAuthentication` production 타겟의 초기 소스 glob을 충족한다
- [X] T013 [P] `sources/Projects/Domain/DomainAuthenticationTests/Placeholder.swift`를 생성해 `DomainAuthenticationTests` 타겟의 초기 테스트 소스 glob을 충족한다
- [X] T014 [P] `sources/Projects/Feature/FeatureAuthentication/Placeholder.swift`를 생성해 `FeatureAuthentication` production 타겟의 초기 소스 glob을 충족한다
- [X] T015 [P] `sources/Projects/Feature/FeatureAuthenticationTests/Placeholder.swift`를 생성해 `FeatureAuthenticationTests` 타겟의 초기 테스트 소스 glob을 충족한다
- [X] T016 [P] `sources/Projects/Composition/CompositionTests/Placeholder.swift`를 생성해 `CompositionTests` 타겟의 초기 테스트 소스 glob을 충족한다
- [X] T017 [no-write] `sources/`에서 `tuist generate`를 실행한 뒤 저장소 루트에서 `project_build_runner build`와 `project_build_runner compile`을 순서대로 실행해 새 production·test 타겟이 graph와 테스트 scheme에 포함되는지 확인한다

---

## 패키지 구현 순서

`sources/docs/assets/package-dependency-graph.dot`에서 `A → B`이면 `A`가 `B`를 컴파일
의존성으로 참조한다. 이 관계로 각 소비 패키지의 선행 조건을 검증하고, 프로젝트 내부
의존성이 없는 패키지 사이의 상대적 순서를 포함한 전체 실행 순서는 헌법의
`Domain → Data → Core → Composition → UI → Feature → App`을 그대로 따른다.

| 순서 | 작업 패키지 | 헌법·의존성 근거 | 관련 사용자 스토리 | 패키지 검증 |
| --- | --- | --- | --- | --- |
| 1 | Domain | 프로젝트 내부 의존성이 없고 Feature·Composition이 소비하는 비즈니스 계약을 제공한다. | US1, US2, US3 | `DomainAuthentication` scheme test |
| 2 | Data | 프로젝트 내부 의존성이 없고 Composition의 공급자 중립 데이터 계약·모델을 제공한다. | US1, US2, US3 | `DataAuthentication` scheme test |
| 3 | Core | 프로젝트 내부 의존성이 없고 Composition이 사용할 Apple·Keychain 기술 API를 제공한다. | US1, US2, US3 | `CoreAuthentication` scheme test |
| 4 | Composition | 완료된 Domain·Data·Core를 Adapter와 실행 객체로 연결한다. | US1, US2, US3 | `Composition` scheme test |
| 5 | UI | 프로젝트 내부 의존성이 없는 재사용 UI를 제공하며 Feature 전에 완료한다. | US1 | `UIComponent` scheme build와 VoiceOver 확인 |
| 6 | Feature | 완료된 Domain·UI에만 의존해 인증 Presentation을 구현한다. | US1, US2, US3 | `FeatureAuthentication` scheme test |
| 7 | App | Feature·Composition·Domain을 소비하는 최종 조정 루트다. | US1, US2, US3 | `GitIt` scheme build |

> **승인 규칙**: `/speckit-implement`는 위 순서의 첫 미완료 작업 패키지 하나만 처리한다.
> 현재 패키지의 변경 파일과 성공한 검증 결과를 보고한 뒤 중단하며, 사용자가 표에 적힌
> 다음 패키지를 명시적으로 승인하기 전에는 그 패키지 파일을 수정하거나 검증하지 않는다.

> **의존성 검증 규칙**: 각 작업 패키지는 모든 직접 의존 패키지가 이미 완료된 뒤
> 시작하므로 패키지 전용 build 또는 test가 성공해야 승인 게이트를 통과한다. 예상하지 못한
> 컴파일·테스트 실패는 기록만 하고 넘어가지 않으며 현재 패키지 안에서 해결한다.

---

## 작업 패키지 1: Domain

**목표**: 외부 기술 타입 없이 인증·세션 비즈니스 모델, Repository 계약과 네 use case를
정의한다.

**소유 경로**:
`sources/Projects/Domain/DomainAuthentication/`,
`sources/Projects/Domain/DomainAuthenticationTests/`

**관련 사용자 스토리**: US1, US2, US3

**독립 검증**: Domain test target만으로 모델·계약·use case 호출 순서와 오류·상태 수렴을
검증하고 프로젝트 내부 패키지 의존이 없는지 확인한다.

### 모델과 계약 — Red

- [X] T018 [P] `sources/Projects/Domain/DomainAuthenticationTests/Models/AuthenticationMethodTests.swift`에 `.apple`이 외부 프레임워크 타입 없이 표현되는 Domain 인증 방식인지 검증하는 실패 테스트를 작성한다
- [X] T019 [P] `sources/Projects/Domain/DomainAuthenticationTests/Models/AuthenticationGrantTests.swift`에 grant가 불투명 ID와 method만 보유하고 원시 credential·토큰을 노출하지 않는지 검증하는 실패 테스트를 작성한다
- [X] T020 [P] `sources/Projects/Domain/DomainAuthenticationTests/Models/AuthenticatedUserTests.swift`에 서버 사용자 ID, 이용 가능 상태, 선택적 표시 이름만 표현하는지 검증하는 실패 테스트를 작성한다
- [X] T021 [P] `sources/Projects/Domain/DomainAuthenticationTests/Models/AuthenticationOutcomeTests.swift`에 `authenticated`·`unauthenticated`·`recoverableFailure` 결과가 토큰과 외부 오류를 포함하지 않는지 검증하는 실패 테스트를 작성한다
- [X] T022 [P] `sources/Projects/Domain/DomainAuthenticationTests/Models/AuthenticationAuthorizationStatusTests.swift`에 `authorized`·`reauthenticationRequired`·`temporarilyUnavailable`만 공개되는지 검증하는 실패 테스트를 작성한다
- [X] T023 [P] `sources/Projects/Domain/DomainAuthenticationTests/Models/AuthenticationErrorTests.swift`에 사용자 취소와 복구 가능한 외부 인증 실패가 공급자 중립 의미로 구분되는지 검증하는 실패 테스트를 작성한다
- [X] T024 [P] `sources/Projects/Domain/DomainAuthenticationTests/Models/SessionErrorTests.swift`에 일시 실패, refresh 거부·만료, 계정 이용 불가가 서로 구분되는지 검증하는 실패 테스트를 작성한다
- [X] T025 [P] `sources/Projects/Domain/DomainAuthenticationTests/Contracts/AuthenticationRepositoryContractTests.swift`에 인증·grant 발급, generic authorization 상태·변경 stream, 인증 참조 정리만 제공하고 서버 세션 연산을 제공하지 않는 계약 테스트를 작성한다
- [X] T026 [P] `sources/Projects/Domain/DomainAuthenticationTests/Contracts/SessionRepositoryContractTests.swift`에 grant 기반 시작, 복원·내부 refresh, 로그아웃만 제공하고 외부 인증 연산을 제공하지 않는 계약 테스트를 작성한다

### 모델과 계약 — Green

- [X] T027 [P] `sources/Projects/Domain/DomainAuthentication/Models/AuthenticationMethod.swift`에 공급자 실행 기술을 포함하지 않는 `AuthenticationMethod.apple`을 정의해 T018을 통과시킨다
- [X] T028 [P] `sources/Projects/Domain/DomainAuthentication/Models/AuthenticationGrant.swift`에 불투명 `id`와 `method`만 가진 단발성 grant 모델을 정의해 T019를 통과시킨다
- [X] T029 [P] `sources/Projects/Domain/DomainAuthentication/Models/AuthenticatedUser.swift`에 안전한 사용자 표시 정보만 가진 모델을 정의해 T020을 통과시킨다
- [X] T030 [P] `sources/Projects/Domain/DomainAuthentication/Models/AuthenticationOutcome.swift`에 Feature로 전달할 인증 결과 세 가지를 정의해 T021을 통과시킨다
- [X] T031 [P] `sources/Projects/Domain/DomainAuthentication/Models/AuthenticationAuthorizationStatus.swift`에 공급자 중립 authorization 상태를 정의해 T022를 통과시킨다
- [X] T032 [P] `sources/Projects/Domain/DomainAuthentication/Models/AuthenticationError.swift`에 취소와 복구 가능한 인증 오류를 정의하되 Apple 오류 타입과 민감 값을 배제해 T023을 통과시킨다
- [X] T033 [P] `sources/Projects/Domain/DomainAuthentication/Models/SessionError.swift`에 세션 일시 실패, 명시적 거부·만료, 계정 이용 불가 의미를 정의해 T024를 통과시킨다
- [X] T034 [P] `sources/Projects/Domain/DomainAuthentication/Contracts/AuthenticationRepository.swift`에 `authenticate(using:)`, `authorizationStatus()`, `authorizationChanges()`, `clearAuthorization()`만 가진 `Sendable` 계약을 정의해 T025를 통과시킨다
- [X] T035 [P] `sources/Projects/Domain/DomainAuthentication/Contracts/SessionRepository.swift`에 `start(with:)`, `restore()`, `signOut()`만 가진 `Sendable` 계약을 정의해 T026을 통과시킨다

### Use Case — Red

- [X] T036 [P] `sources/Projects/Domain/DomainAuthenticationTests/UseCases/SignInTests.swift`에 선택 방식 전달, 인증→grant→세션 시작 순서, 인증 실패 시 세션 미호출, 세션 시작 실패 시 인증 정리 테스트를 작성하고 실패를 확인한다
- [X] T037 [P] `sources/Projects/Domain/DomainAuthenticationTests/UseCases/RestoreSessionTests.swift`에 세션 부재 정리, authorization 상태별 복원, refresh 성공·일시 실패·거부 시 두 Repository의 분리된 호출과 결과 테스트를 작성하고 실패를 확인한다
- [X] T038 [P] `sources/Projects/Domain/DomainAuthenticationTests/UseCases/ObserveAuthorizationChangesTests.swift`에 authorization 변경 stream을 소비해 저장 상태를 정리하고 `AuthenticationOutcome`만 내보내는 테스트를 작성하고 실패를 확인한다
- [X] T039 [P] `sources/Projects/Domain/DomainAuthenticationTests/UseCases/SignOutTests.swift`에 서버 세션 로컬 삭제를 먼저 요청한 뒤 인증 참조를 정리하고 원격 폐기 실패와 관계없이 로그아웃하는 호출 순서 테스트를 작성하고 실패를 확인한다

### Use Case — Green

- [X] T040 [P] `sources/Projects/Domain/DomainAuthentication/UseCases/SignIn.swift`에 외부 인증과 서버 세션 시작을 순서대로 조정하고 실패 시 임시 인증 상태를 정리하는 `SignIn`을 구현해 T036을 통과시킨다
- [X] T041 [P] `sources/Projects/Domain/DomainAuthentication/UseCases/RestoreSession.swift`에 공급자 authorization과 Git It 세션을 함께 검증하고 일시 실패와 명시적 무효화를 구분하는 `RestoreSession`을 구현해 T037을 통과시킨다
- [X] T042 [P] `sources/Projects/Domain/DomainAuthentication/UseCases/ObserveAuthorizationChanges.swift`에 Repository 변경 stream을 `AuthenticationOutcome`으로 수렴시키는 `ObserveAuthorizationChanges`를 구현해 T038을 통과시킨다
- [X] T043 [P] `sources/Projects/Domain/DomainAuthentication/UseCases/SignOut.swift`에 세션 종료 후 인증 참조를 별도 정리하는 `SignOut`을 구현해 T039를 통과시킨다

### 패키지 횡단 관심사와 정리

- [X] T044 [P] `sources/Projects/Domain/DomainAuthenticationTests/Security/SensitiveValueExposureTests.swift`에 Domain 모델·오류·결과의 문자열 표현과 실패 출력에 외부 credential·token·nonce·state 필드가 존재하지 않는지 검증하는 테스트를 작성한다
- [X] T045 [P] 구현 파일이 존재함을 확인한 뒤 `sources/Projects/Domain/DomainAuthentication/Placeholder.swift`를 삭제한다
- [X] T046 [P] 실제 테스트 파일이 존재함을 확인한 뒤 `sources/Projects/Domain/DomainAuthenticationTests/Placeholder.swift`를 삭제한다

### 패키지 검증

- [X] T047 [no-write] `derived_data_root=$(./tools/repository-paths/bin/repository-paths.sh --absolute GIT_IT_DERIVED_DATA_PATH) && xcodebuild -workspace sources/GitIt.xcworkspace -scheme DomainAuthentication -derivedDataPath "$derived_data_root/TestSchemes/DomainAuthentication" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test`를 실행해 Xcode 전역 Build Location과 격리된 Domain 전체 테스트가 통과하고 `DomainAuthentication` target이 다른 프로젝트 내부 패키지에 의존하지 않는지 확인한다

**승인 게이트**: T018~T047의 변경과 검증 결과를 보고한 뒤 중단한다. 사용자가
`Data` 시작을 승인하기 전에는 작업 패키지 2를 실행하지 않는다.

---

## 작업 패키지 2: Data

**목표**: 공급자 중립 외부 인증·세션·저장 계약, DTO, 저장 모델과 오류 의미를
Swift Standard Library 수준에서 정의한다.

**소유 경로**:
`sources/Projects/Data/DataAuthentication/`,
`sources/Projects/Data/DataAuthenticationTests/`

**관련 사용자 스토리**: US1, US2, US3

**독립 검증**: Data test target만으로 계약·DTO·모델·오류를 검증하고
Domain·Core·Apple 타입과 구현 기술 의존이 없는지 확인한다.

### 계약과 모델 — Red

- [X] T048 [P] `sources/Projects/Data/DataAuthenticationTests/Contracts/ExternalAuthenticationProviderContractTests.swift`에 method identifier 기반 인증·authorization 조회·변경 stream만 제공하고 Domain/Core/Apple 타입을 공개하지 않는 계약 테스트를 작성한다
- [X] T049 [P] `sources/Projects/Data/DataAuthenticationTests/Contracts/SessionRemoteContractTests.swift`에 세션 시작, token refresh, refresh token 폐기만 제공하고 공급자별 필드·Domain/Core 타입을 공개하지 않는 계약 테스트를 작성한다
- [X] T050 [P] `sources/Projects/Data/DataAuthenticationTests/Contracts/SessionStorageContractTests.swift`에 Git It 서버 세션의 원자적 저장·읽기·삭제만 제공하고 인증 참조를 취급하지 않는 계약 테스트를 작성한다
- [X] T051 [P] `sources/Projects/Data/DataAuthenticationTests/Contracts/AuthenticationAuthorizationStorageContractTests.swift`에 공급자 인증 참조의 저장·읽기·삭제만 제공하고 서버 세션을 취급하지 않는 계약 테스트를 작성한다
- [X] T052 [P] `sources/Projects/Data/DataAuthenticationTests/Models/ExternalAuthenticationEvidenceTests.swift`에 method identifier, 불투명 subject reference와 payload만 존재하고 payload가 로그·비교에 노출되지 않는지 검증하는 실패 테스트를 작성한다
- [X] T053 [P] `sources/Projects/Data/DataAuthenticationTests/Models/ExternalAuthorizationStateTests.swift`에 `active`·`inactive`·`temporarilyUnavailable`만 존재하고 Apple credential state case가 없는지 검증하는 실패 테스트를 작성한다
- [X] T054 [P] `sources/Projects/Data/DataAuthenticationTests/Errors/DataAuthenticationErrorTests.swift`에 취소, 일시 오류, 저장 실패, 세션 시작·refresh 거부·폐기 실패를 공급자 중립 의미로 분류하는 실패 테스트를 작성한다
- [X] T055 [P] `sources/Projects/Data/DataAuthenticationTests/DTOs/SessionStartRequestDTOTests.swift`에 method identifier와 불투명 단발성 payload만 전송 입력에 포함되고 Apple 필드명이 없는지 검증하는 실패 테스트를 작성한다
- [X] T056 [P] `sources/Projects/Data/DataAuthenticationTests/DTOs/SessionResponseDTOTests.swift`에 Git It 사용자, access/refresh token, access 만료만 세션 응답에 포함되는지 검증하는 실패 테스트를 작성한다
- [X] T057 [P] `sources/Projects/Data/DataAuthenticationTests/DTOs/RefreshDTOTests.swift`에 공급자와 무관한 refresh 요청·응답 및 거부·만료 처리 입력을 검증하는 실패 테스트를 작성한다
- [X] T058 [P] `sources/Projects/Data/DataAuthenticationTests/Models/StoredSessionTests.swift`에 서버 세션 저장 모델이 token·만료·사용자만 가지며 `appleUserID`와 인증 참조를 포함하지 않는지 검증하는 실패 테스트를 작성한다
- [X] T059 [P] `sources/Projects/Data/DataAuthenticationTests/Models/StoredAuthorizationReferenceTests.swift`에 method identifier와 불투명 subject reference가 서버 세션과 분리되는지 검증하는 실패 테스트를 작성한다

### 계약과 모델 — Green

- [X] T060 [P] `sources/Projects/Data/DataAuthentication/Models/ExternalAuthenticationEvidence.swift`에 공급자 중립 method identifier·subject reference·opaque payload 모델을 정의해 T052을 통과시킨다
- [X] T061 [P] `sources/Projects/Data/DataAuthentication/Models/ExternalAuthorizationState.swift`에 `active`·`inactive`·`temporarilyUnavailable` 상태만 정의해 T053을 통과시킨다
- [X] T062 [P] `sources/Projects/Data/DataAuthentication/DTOs/SessionStartRequestDTO.swift`에 method identifier와 불투명 일회성 payload만 가진 세션 시작 요청을 정의해 T055를 통과시킨다
- [X] T063 [P] `sources/Projects/Data/DataAuthentication/DTOs/SessionResponseDTO.swift`에 Git It 사용자와 access/refresh token·만료를 가진 세션 응답을 정의해 T056을 통과시킨다
- [X] T064 [P] `sources/Projects/Data/DataAuthentication/DTOs/RefreshRequestDTO.swift`에 refresh token만 가진 공급자 중립 갱신 요청을 정의해 T057을 통과시킨다
- [X] T065 [P] `sources/Projects/Data/DataAuthentication/DTOs/RefreshResponseDTO.swift`에 새 access token·만료와 필요 시 교체 refresh token을 가진 갱신 응답을 정의해 T057을 통과시킨다
- [X] T066 [P] `sources/Projects/Data/DataAuthentication/Models/StoredSession.swift`에 access/refresh token·만료·사용자만 가진 서버 세션 저장 모델을 정의해 T058를 통과시킨다
- [X] T067 [P] `sources/Projects/Data/DataAuthentication/Models/StoredAuthorizationReference.swift`에 method identifier와 provider subject reference만 가진 인증 참조 저장 모델을 정의해 T059을 통과시킨다
- [X] T068 [P] `sources/Projects/Data/DataAuthentication/Errors/DataAuthenticationError.swift`에 외부 인증·저장·세션 시작·refresh·폐기 오류를 공급자 중립 의미로 정의해 T054을 통과시킨다
- [X] T069 [P] `sources/Projects/Data/DataAuthentication/Contracts/ExternalAuthenticationProvider.swift`에 인증, authorization 상태 조회와 변경 stream을 제공하는 `Sendable` 계약을 정의해 T048를 통과시킨다
- [X] T070 [P] `sources/Projects/Data/DataAuthentication/Contracts/SessionRemote.swift`에 공급자 중립 `startSession`, token refresh, refresh token 폐기 연산만 정의해 T049을 통과시킨다
- [X] T071 [P] `sources/Projects/Data/DataAuthentication/Contracts/SessionStorage.swift`에 Git It 서버 세션의 원자적 저장·읽기·삭제 계약만 정의해 T050를 통과시킨다
- [X] T072 [P] `sources/Projects/Data/DataAuthentication/Contracts/AuthenticationAuthorizationStorage.swift`에 공급자 인증 참조의 저장·읽기·삭제 계약만 정의해 T051를 통과시킨다

### 패키지 횡단 관심사와 정리

- [X] T073 [P] `sources/Projects/Data/DataAuthenticationTests/Security/SensitiveValueExposureTests.swift`에 opaque payload와 token DTO가 `CustomStringConvertible`·디버그 출력·오류 메시지로 민감 값을 노출하지 않는지 검증하는 테스트를 작성한다
- [X] T074 [P] 구현 파일이 존재함을 확인한 뒤 `sources/Projects/Data/DataAuthentication/Placeholder.swift`를 삭제한다
- [X] T075 [P] 실제 테스트 파일이 존재함을 확인한 뒤 `sources/Projects/Data/DataAuthenticationTests/Placeholder.swift`를 삭제한다

### 패키지 검증

- [X] T076 [no-write] `derived_data_root=$(./tools/repository-paths/bin/repository-paths.sh --absolute GIT_IT_DERIVED_DATA_PATH) && xcodebuild -workspace sources/GitIt.xcworkspace -scheme DataAuthentication -derivedDataPath "$derived_data_root/TestSchemes/DataAuthentication" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test`를 실행해 Xcode 전역 Build Location과 격리된 Data 전체 테스트가 통과하고 `DataAuthentication` target이 다른 프로젝트 내부 패키지에 의존하지 않는지 확인한다

**승인 게이트**: T048~T076의 변경과 검증 결과를 보고한 뒤 중단한다. 사용자가
`Core` 시작을 승인하기 전에는 작업 패키지 3을 실행하지 않는다.

---

## 작업 패키지 3: Core

**목표**: `AuthenticationServices`·credential state·CSPRNG·Keychain을 프로젝트 소유 기술
API 뒤에 격리한다.

**소유 경로**:
`sources/Projects/Core/CoreAuthentication/`,
`sources/Projects/Core/CoreAuthenticationTests/`

**관련 사용자 스토리**: US1, US2, US3

**독립 검증**: Apple 요청·콜백 검증, credential state 변환, Keychain 원자성·접근성과
CSPRNG를 Core test target에서 검증하고 Domain·Data 의미를 소유하지 않는지 확인한다.

### 기술 API — Red

- [X] T077 [P] `sources/Projects/Core/CoreAuthenticationTests/AppleAuthentication/AppleAuthorizationProviderTests.swift`에 명시적 시작, 선택 scope, 성공 credential 변환, 취소, state·attempt 불일치, 시도 만료, token/code 누락, 늦은 콜백 무시 테스트를 작성하고 실패를 확인한다
- [X] T078 [P] `sources/Projects/Core/CoreAuthenticationTests/AppleAuthentication/AppleCredentialStateProviderTests.swift`에 `authorized`·`revoked`·`notFound`·`transferred`와 revoked 알림·조회 오류를 Core 소유 상태로 격리하는 테스트를 작성하고 실패를 확인한다
- [X] T079 [P] `sources/Projects/Core/CoreAuthenticationTests/Keychain/KeychainStoreTests.swift`에 key namespace 분리, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` 상당 접근성, 원자적 CRUD와 오류 격리 테스트를 작성하고 실패를 확인한다
- [X] T080 [P] `sources/Projects/Core/CoreAuthenticationTests/RandomGenerator/SecureRandomGeneratorTests.swift`에 nonce·state·attemptID·grantID용 CSPRNG 출력의 길이, 고유성, 실패 전달 테스트를 작성하고 실패를 확인한다

### 기술 API — Green

- [X] T081 [P] `sources/Projects/Core/CoreAuthentication/AppleAuthentication/AppleAuthorizationProvider.swift`, `sources/Projects/Core/CoreAuthentication/AppleAuthentication/AppleAuthorizationAttempt.swift`, `sources/Projects/Core/CoreAuthentication/AppleAuthentication/AppleCredential.swift`, `sources/Projects/Core/CoreAuthentication/AppleAuthentication/AppleAuthorizationError.swift`로 Apple 인증 provider·시도·credential·오류를 파일별 Core 소유 타입으로 분리하고, `AuthenticationServices`를 provider 뒤에 격리하며 시도별 nonce·state·attemptID·expiresAt 검증과 취소를 유지해 T077을 통과시킨다
- [X] T082 [P] `sources/Projects/Core/CoreAuthentication/AppleAuthentication/AppleCredentialStateProvider.swift`에 credential state 조회와 revoked 알림을 Core 소유 상태·stream으로 변환하는 API를 구현해 T078를 통과시킨다
- [X] T083 [P] `sources/Projects/Core/CoreAuthentication/Keychain/KeychainStore.swift`, `sources/Projects/Core/CoreAuthentication/Keychain/KeychainNamespace.swift`, `sources/Projects/Core/CoreAuthentication/Keychain/KeychainAccessibility.swift`, `sources/Projects/Core/CoreAuthentication/Keychain/KeychainStoreError.swift`로 Keychain store·namespace·접근성·오류를 파일별 Core 소유 타입으로 분리하고, namespace별 기기 한정 Keychain CRUD와 원자적 저장·삭제 API를 유지해 T079을 통과시킨다
- [X] T084 [P] `sources/Projects/Core/CoreAuthentication/RandomGenerator/SecureRandomGenerator.swift`에 CSPRNG 기반 임의 값 생성 API를 구현해 T080를 통과시킨다

### 패키지 횡단 관심사와 정리

- [X] T085 [P] `sources/Projects/Core/CoreAuthenticationTests/Security/SensitiveValueExposureTests.swift`에 Apple 원시 credential, nonce, state와 Keychain 값이 오류·설명 문자열에 포함되지 않는지 검증하는 테스트를 작성한다
- [X] T086 [P] 구현 파일이 존재함을 확인한 뒤 `sources/Projects/Core/CoreAuthentication/Placeholder.swift`를 삭제한다
- [X] T087 [P] 실제 테스트 파일이 존재함을 확인한 뒤 `sources/Projects/Core/CoreAuthenticationTests/Placeholder.swift`를 삭제한다

### 패키지 검증

- [X] T088 [no-write] `derived_data_root=$(./tools/repository-paths/bin/repository-paths.sh --absolute GIT_IT_DERIVED_DATA_PATH) && xcodebuild -workspace sources/GitIt.xcworkspace -scheme CoreAuthentication -derivedDataPath "$derived_data_root/TestSchemes/CoreAuthentication" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test`를 실행해 Xcode 전역 Build Location과 격리된 Core 전체 테스트가 통과하고 `CoreAuthentication` target이 Domain·Data·Feature에 의존하지 않는지 확인한다

**승인 게이트**: T077~T088의 변경과 검증 결과를 보고한 뒤 중단한다. 사용자가
`Composition` 시작을 승인하기 전에는 작업 패키지 4를 실행하지 않는다.

---

## 작업 패키지 4: Composition

**목표**: Domain↔Data·Data↔Core Adapter, grant vault, 세션 generation, Mock과 실행 환경별
조립을 구현한다.

**소유 경로**:
`sources/Projects/Composition/Composition/`,
`sources/Projects/Composition/CompositionTests/`

**관련 사용자 스토리**: US1, US2, US3

**독립 검증**: Adapter 변환·rollback·단발 소비·세션 경쟁과 Mock 경계를 테스트하고,
Composition 밖으로 Apple 원시 값이나 저장 기술이 새지 않는지 확인한다.

### 공통 기반 — Red

- [ ] T089 [P] `sources/Projects/Composition/CompositionTests/Authentication/AuthenticationGrantVaultTests.swift`에 결정적 ID 생성기 주입, 첫 소비, 중복·만료·method 불일치 거부, 전체 정리와 payload 미노출 테스트를 작성한다
- [ ] T090 [P] `sources/Projects/Composition/CompositionTests/Authentication/Adapters/DomainAuthenticationRepositoryAdapterTests.swift`에 Domain method/status/error와 Data identifier/state/error 변환, vault 등록, 인증 참조 저장 rollback, Core·서버 미호출 테스트를 작성한다
- [ ] T091 [P] `sources/Projects/Composition/CompositionTests/Authentication/Adapters/DomainSessionRepositoryAdapterTests.swift`에 grant 단발 소비, 세션 시작·원자적 저장, restore·refresh 분류, signOut 로컬 우선 삭제, 실패 rollback과 인증 API 미호출 테스트를 작성한다
- [ ] T092 [P] `sources/Projects/Composition/CompositionTests/Authentication/Adapters/DataCoreExternalAuthenticationProviderAdapterTests.swift`에 Data method identifier의 Core Apple API 선택, Core credential의 불투명 evidence 변환, credential state·알림의 Data 상태 수렴과 오류 변환 테스트를 작성한다
- [ ] T093 [P] `sources/Projects/Composition/CompositionTests/Authentication/Adapters/DataCoreSessionStorageAdapterTests.swift`에 서버 세션 전용 namespace의 Keychain 인코딩·원자적 저장·읽기·삭제 테스트를 작성한다
- [ ] T094 [P] `sources/Projects/Composition/CompositionTests/Authentication/Adapters/DataCoreAuthenticationAuthorizationStorageAdapterTests.swift`에 인증 참조 전용 namespace의 Keychain 인코딩·저장·읽기·삭제와 세션 namespace 비공유 테스트를 작성한다
- [ ] T095 [P] `sources/Projects/Composition/CompositionTests/Authentication/SessionCoordinatorTests.swift`에 세션 세대 캡처·증가와 이전 세대의 시작·복원·refresh 결과 거부 테스트를 작성한다
- [ ] T096 [P] `sources/Projects/Composition/CompositionTests/Authentication/Mocks/AuthenticationMocksTests.swift`에 Domain 인증, Data 외부 인증, Core Apple Mock이 성공·취소·오류·authorization 상태를 결정적으로 재현하고 서버 세션을 만들지 않는지 테스트한다
- [ ] T097 [P] `sources/Projects/Composition/CompositionTests/Authentication/Mocks/SessionMocksTests.swift`에 세션 Remote·Storage Mock이 신규·기존 사용자, 선택 프로필 부재, refresh 성공·일시 실패·거부, 폐기 실패를 결정적으로 재현하는지 테스트한다
- [ ] T098 [P] `sources/Projects/Composition/CompositionTests/Authentication/UnavailableSessionRemoteTests.swift`에 서버 endpoint 미구성 시 세션 성공 대신 안전한 복구 가능 오류를 반환하는 실패 테스트를 작성한다
- [ ] T099 [P] `sources/Projects/Composition/CompositionTests/Authentication/AppCompositionAuthenticationTests.swift`에 live·Mock·unavailable 환경별 구현 선택, vault·세션 조정 actor 공유 수명, 네 Domain use case의 명시적 생성자 조립과 전역 container 부재를 검증하는 실패 테스트를 작성한다

### 공통 기반 — Green

- [ ] T100 `sources/Projects/Composition/Composition/Authentication/AuthenticationGrantVault.swift`에 initializer로 ID 생성 closure를 받고 evidence를 메모리에서 단발 소비·만료·전체 정리하는 actor를 구현해 T089를 통과시킨다
- [ ] T101 `sources/Projects/Composition/Composition/Authentication/Adapters/DomainAuthenticationRepositoryAdapter.swift`에 Domain `AuthenticationRepository`와 Data 외부 인증·인증 참조 저장 계약 사이의 변환과 vault rollback을 구현해 T090를 통과시킨다
- [ ] T102 `sources/Projects/Composition/Composition/Authentication/Adapters/DomainSessionRepositoryAdapter.swift`에 Domain `SessionRepository`와 vault·`SessionRemote`·`SessionStorage`·세션 조정 actor 사이의 시작·복원·refresh·로그아웃 흐름을 구현해 T091을 통과시킨다
- [ ] T103 [P] `sources/Projects/Composition/Composition/Authentication/Adapters/DataCoreExternalAuthenticationProviderAdapter.swift`에 Data method identifier·상태·오류와 Core Apple API 사이의 변환을 구현하고 Apple 타입·case를 Adapter 밖으로 내보내지 않아 T092을 통과시킨다
- [ ] T104 [P] `sources/Projects/Composition/Composition/Authentication/Adapters/DataCoreSessionStorageAdapter.swift`에 서버 세션 전용 Keychain namespace Adapter를 구현해 T093을 통과시킨다
- [ ] T105 [P] `sources/Projects/Composition/Composition/Authentication/Adapters/DataCoreAuthenticationAuthorizationStorageAdapter.swift`에 공급자 인증 참조 전용 Keychain namespace Adapter를 구현해 T094를 통과시킨다
- [ ] T106 [P] `sources/Projects/Composition/Composition/Authentication/SessionCoordinator.swift`에 세션 generation 관리와 늦은 비동기 결과 차단 actor를 구현해 T095을 통과시킨다
- [ ] T107 [P] `sources/Projects/Composition/Composition/Authentication/Mocks/MockAuthenticationRepository.swift`에 명시적 개발·통합 테스트용 Domain 인증 Mock을 구현해 T096을 통과시킨다
- [ ] T108 [P] `sources/Projects/Composition/Composition/Authentication/Mocks/MockExternalAuthenticationProvider.swift`에 Data evidence·authorization 상태·오류를 결정적으로 반환하는 Mock을 구현해 T096을 통과시킨다
- [ ] T109 [P] `sources/Projects/Composition/Composition/Authentication/Mocks/MockAppleAuthorizationProvider.swift`에 Core 소유 Apple 인증 API의 성공·취소·오류·상태 변경 Test Double을 구현해 T096을 통과시킨다
- [ ] T110 [P] `sources/Projects/Composition/Composition/Authentication/Mocks/MockSessionRemote.swift`에 신규·기존 계정과 세션 시작·refresh·폐기 결과를 결정적으로 반환하는 Mock을 구현해 T097를 통과시킨다
- [ ] T111 [P] `sources/Projects/Composition/Composition/Authentication/Mocks/MockSessionStorage.swift`에 원자적 저장·읽기·삭제와 호출 기록을 제공하는 서버 세션 저장 Mock을 구현해 T097를 통과시킨다
- [ ] T112 [P] `sources/Projects/Composition/Composition/Authentication/Mocks/MockAuthenticationAuthorizationStorage.swift`에 서버 세션과 분리된 인증 참조 저장 Mock을 구현해 T096과 T097를 통과시킨다
- [ ] T113 [P] `sources/Projects/Composition/Composition/Authentication/UnavailableSessionRemote.swift`에 live endpoint가 없는 구성에서 세션을 열지 않는 실패 구현을 작성해 T098을 통과시킨다
- [ ] T114 `sources/Projects/Composition/Composition/Authentication/AppComposition+Authentication.swift`에 Core CSPRNG closure, 두 저장 Adapter, Data↔Core·Domain↔Data Adapter, 공유 vault·세션 조정 actor를 생성자 주입으로 조립하고 Mock/live/unavailable 환경 선택과 네 Domain use case만 공개해 T099를 통과시킨다

### 사용자 스토리 1 — Red

- [ ] T115 [US1] `sources/Projects/Composition/CompositionTests/Authentication/FirstSignInIntegrationTests.swift`에 신규 사용자, 이메일 가리기·이름 부재, grant 한 번 소비, 세션 저장 뒤 성공, 중복 소비 거부를 분리된 인증·세션 Mock으로 검증하는 실패 테스트를 작성한다

### 사용자 스토리 2 — Red

- [ ] T116 [P] [US2] `sources/Projects/Composition/CompositionTests/Authentication/ExistingUserSessionIntegrationTests.swift`에 이름·이메일 없는 기존 사용자 로그인, 같은 이메일이지만 연결되지 않은 Apple subject의 자동 병합 금지, 유효 세션 복원, 만료 access token refresh, 로컬 우선 로그아웃과 원격 폐기 실패를 검증하는 실패 테스트를 작성한다
- [ ] T117 [P] [US2] `sources/Projects/Composition/CompositionTests/Authentication/SessionCoordinatorRaceTests.swift`에 refresh 진행 중 로그아웃으로 generation이 증가한 뒤 늦은 성공 응답이 Keychain과 화면 상태를 되살리지 않는지 검증하는 실패 테스트를 작성한다

### 사용자 스토리 3 — Red

- [ ] T118 [US3] `sources/Projects/Composition/CompositionTests/Authentication/AuthenticationRecoveryIntegrationTests.swift`에 취소, 인증 참조 저장 실패, 세션 시작 실패, authorization 일시 오류·철회, refresh 일시 오류·거부, 계정 이용 불가의 저장·정리 정책을 검증하는 실패 테스트를 작성한다

### 패키지 횡단 관심사와 정리

- [ ] T119 [P] `sources/Projects/Composition/CompositionTests/Authentication/SensitiveValueExposureTests.swift`에 grant vault·Adapter·Mock 호출 기록과 테스트 실패 메시지가 payload·token·provider subject를 출력하지 않는지 검증하는 테스트를 작성한다
- [ ] T120 [P] 실제 Composition 구현 파일이 존재함을 확인한 뒤 `sources/Projects/Composition/Composition/Placeholder.swift`를 삭제한다
- [ ] T121 [P] 실제 Composition 테스트 파일이 존재함을 확인한 뒤 `sources/Projects/Composition/CompositionTests/Placeholder.swift`를 삭제한다

### 패키지 검증

- [ ] T122 [no-write] `xcodebuild -workspace sources/GitIt.xcworkspace -scheme Composition -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test`를 실행해 Composition 전체 테스트가 통과하고 `Composition` target의 프로젝트 내부 의존성이 `DomainAuthentication`·`DataAuthentication`·`CoreAuthentication`으로 제한되는지 확인한다

**승인 게이트**: T089~T122의 변경과 검증 결과를 보고한 뒤 중단한다. 사용자가
`UI` 시작을 승인하기 전에는 작업 패키지 5를 실행하지 않는다.

---

## 작업 패키지 5: UI

**목표**: 특정 Feature 상태를 소유하지 않는 재사용 가능한 Apple 로그인 제어와 접근성
표현을 제공한다.

**소유 경로**: `sources/Projects/UI/UIComponent/Authentication/AppleSignInButton.swift`,
`sources/Projects/UI/UIComponent/Placeholder.swift`

**관련 사용자 스토리**: US1

**독립 검증**: `AppleSignInButton`이 범용 탭 closure와 Apple 디자인·접근성 표현만
노출하는지 확인하고 `UIComponent` scheme을 빌드한다.

### 사용자 스토리 1 구현

- [ ] T123 [US1] `sources/Projects/UI/UIComponent/Authentication/AppleSignInButton.swift`에 Apple 디자인 지침과 접근성을 따르며 범용 탭 closure만 노출하는 재사용 가능한 로그인 제어를 구현한다

### 접근성 및 정리

- [ ] T124 [no-write] `sources/Projects/UI/UIComponent/Authentication/AppleSignInButton.swift`의 로그인 제어를 VoiceOver로 식별·조작하고 민감 값이 접근성 출력에 없는지 확인한다
- [ ] T125 `AppleSignInButton.swift`가 타겟 소스로 포함됨을 확인한 뒤 `sources/Projects/UI/UIComponent/Placeholder.swift`를 삭제한다

### 패키지 검증

- [ ] T126 [no-write] `derived_data_root=$(./tools/repository-paths/bin/repository-paths.sh --absolute GIT_IT_DERIVED_DATA_PATH) && xcodebuild -workspace sources/GitIt.xcworkspace -scheme UIComponent -derivedDataPath "$derived_data_root/BuildSchemes/UIComponent" -destination 'generic/platform=iOS Simulator' build`를 실행해 Xcode 전역 Build Location과 격리된 UIComponent가 Feature·Domain·Data·Core에 의존하지 않고 빌드되는지 확인한다

**승인 게이트**: T123~T126의 변경과 검증 결과를 보고한 뒤 중단한다. 사용자가
`Feature` 시작을 승인하기 전에는 작업 패키지 6을 실행하지 않는다.

---

## 작업 패키지 6: Feature

**목표**: 네 Domain use case만 생성자로 주입받는 TCA 상태·Effect와 로그인·인증·복구 화면을
구현해 사용자 상호작용을 표현한다.

**소유 경로**:
`sources/Projects/Feature/FeatureAuthentication/`,
`sources/Projects/Feature/FeatureAuthenticationTests/`

**관련 사용자 스토리**: US1, US2, US3

**독립 검증**: `TestStore`로 각 스토리 상태 전이와 Effect 취소를 검증하고 Feature가
Repository·Apple·Data·Core 타입을 참조하지 않는지 확인한다.

### 사용자 스토리 1 — Red

- [ ] T127 [P] [US1] `sources/Projects/Feature/FeatureAuthenticationTests/SignInFeatureTests.swift`에 `.apple` 선택 시 주입된 `SignIn`을 한 번 호출하고 unauthenticated → authenticating → establishingSession → authenticated로 전이하며 State·Action에 grant payload·token이 없는지 검증하는 실패 테스트를 작성한다
- [ ] T128 [P] [US1] `sources/Projects/Feature/FeatureAuthenticationTests/SignInDuplicateTapTests.swift`에 authenticating·establishingSession 상태의 반복 선택이 새 Effect를 시작하지 않는지 검증하는 실패 테스트를 작성한다

### 사용자 스토리 1 — Green

- [ ] T129 [US1] `sources/Projects/Feature/FeatureAuthentication/Authentication/AuthenticationFeature.swift`에 생성자로 네 Domain use case를 받고 로그인 상태·action·delegate와 `SignIn` Effect, 중복 선택 차단을 구현해 T127과 T128를 통과시킨다
- [ ] T130 [US1] `sources/Projects/Feature/FeatureAuthentication/Authentication/Views/SignInView.swift`에 `AppleSignInButton`을 조립하고 `AuthenticationMethod.apple` 선택 action만 전달하는 로그인 화면과 진행 상태를 구현한다
- [ ] T131 [US1] `sources/Projects/Feature/FeatureAuthentication/Authentication/Views/AuthenticatedView.swift`에 안전한 사용자 표시 정보와 로그아웃 intent만 노출하는 인증된 첫 화면을 구현한다

### 사용자 스토리 2 — Red

- [ ] T132 [P] [US2] `sources/Projects/Feature/FeatureAuthenticationTests/SessionRestoreFeatureTests.swift`에 앱 시작과 재시도에서 `RestoreSession` 결과만으로 checking → authenticated/unauthenticated/recoverableFailure가 전이하는 실패 테스트를 작성한다
- [ ] T133 [P] [US2] `sources/Projects/Feature/FeatureAuthenticationTests/SignOutFeatureTests.swift`에 인증 상태의 로그아웃이 `SignOut`을 호출하고 진행 Effect를 취소한 뒤 unauthenticated로 전이하며 저장소를 직접 만지지 않는지 검증하는 실패 테스트를 작성한다

### 사용자 스토리 2 — Green

- [ ] T134 [US2] `sources/Projects/Feature/FeatureAuthentication/Authentication/AuthenticationFeature.swift`에 앱 시작·복구 시 `RestoreSession`을 호출하고 결과를 checking에서 해당 화면 상태로 변환하는 action과 Effect를 추가해 T132을 통과시킨다
- [ ] T135 [US2] `sources/Projects/Feature/FeatureAuthentication/Authentication/AuthenticationFeature.swift`에 인증 상태의 로그아웃 action, 진행 Effect 취소, `SignOut` 완료 후 unauthenticated 전이를 추가해 T133를 통과시킨다
- [ ] T136 [US2] `sources/Projects/Feature/FeatureAuthentication/Authentication/Views/AuthenticatedView.swift`에 접근 가능한 로그아웃 버튼을 연결하고 저장소·네트워크 세부 동작은 action으로 위임한다

### 사용자 스토리 3 — Red

- [ ] T137 [P] [US3] `sources/Projects/Feature/FeatureAuthenticationTests/CancelFeatureTests.swift`에 Domain `cancelled`가 오류 경고·grant·세션 없이 unauthenticated로 돌아가는지 검증하는 실패 테스트를 작성한다
- [ ] T138 [P] [US3] `sources/Projects/Feature/FeatureAuthenticationTests/RecoverableFailureFeatureTests.swift`에 일시 오류의 recoverableFailure 전환, 보호 화면 차단, 재시도 후 성공 또는 비인증 전이를 검증하는 실패 테스트를 작성한다
- [ ] T139 [P] [US3] `sources/Projects/Feature/FeatureAuthenticationTests/AuthorizationInvalidatedFeatureTests.swift`에 `ObserveAuthorizationChanges`가 보낸 outcome만으로 철회·refresh 거부를 처리하고 Feature가 Repository나 Apple 상태를 판단하지 않는지 검증하는 실패 테스트를 작성한다

### 사용자 스토리 3 — Green

- [ ] T140 [US3] `sources/Projects/Feature/FeatureAuthentication/Authentication/Views/RecoveryView.swift`에 민감 정보 없는 오류 안내, 접근 가능한 재시도 버튼, 보호된 콘텐츠 미표시를 구현한다
- [ ] T141 [US3] `sources/Projects/Feature/FeatureAuthentication/Authentication/AuthenticationFeature.swift`에 recoverableFailure의 재시도 action과 `RestoreSession` 재실행 후 상태 전이를 추가해 T138를 통과시킨다
- [ ] T142 [US3] `sources/Projects/Feature/FeatureAuthentication/Authentication/AuthenticationFeature.swift`에 앱 인증 흐름의 수명 동안 주입된 `ObserveAuthorizationChanges` stream을 한 번 구독하고 outcome 기반 상태 전이를 추가해 T139를 통과시킨다

### 패키지 횡단 관심사와 정리

- [ ] T143 [P] `sources/Projects/Feature/FeatureAuthenticationTests/SensitiveValueExposureTests.swift`에 TCA State·Action·delegate·접근성 값이 grant ID, payload, token, provider subject를 보유하지 않는지 검증하는 테스트를 작성한다
- [ ] T144 [P] [no-write] `sources/Projects/Feature/FeatureAuthentication/Authentication/Views/`의 로그인, 진행, 로그아웃, 오류, 재시도 제어를 VoiceOver로 식별·조작하고 민감 값이 접근성 출력에 없는지 확인한다
- [ ] T145 [P] 구현 파일이 존재함을 확인한 뒤 `sources/Projects/Feature/FeatureAuthentication/Placeholder.swift`를 삭제한다
- [ ] T146 [P] 실제 테스트 파일이 존재함을 확인한 뒤 `sources/Projects/Feature/FeatureAuthenticationTests/Placeholder.swift`를 삭제한다

### 패키지 검증

- [ ] T147 [no-write] `xcodebuild -workspace sources/GitIt.xcworkspace -scheme FeatureAuthentication -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test`를 실행해 Feature 전체 테스트가 통과하고 `FeatureAuthentication` target이 `DomainAuthentication`·`UIComponent` 이외의 프로젝트 내부 패키지에 의존하지 않는지 확인한다

**승인 게이트**: T127~T147의 변경과 검증 결과를 보고한 뒤 중단한다. 사용자가
`App` 시작을 승인하기 전에는 작업 패키지 7을 실행하지 않는다.

---

## 작업 패키지 7: App

**목표**: `AppComposition`과 `AuthenticationFeature`를 연결하고 인증 상태에 따른 앱 최상위
화면·생명주기 흐름을 조정한다.

**소유 경로**:
`sources/Projects/App/Sources/ContentView.swift`,
`sources/Projects/App/Sources/GitItApp.swift`

**관련 사용자 스토리**: US1, US2, US3

**독립 검증**: App이 Domain 규칙을 재판단하거나 저장소를 직접 다루지 않고
Feature initializer·action·화면만 연결하는지 검토한 뒤 `GitIt` scheme을 빌드한다.

### 사용자 스토리 1 구현

- [ ] T148 [US1] `sources/Projects/App/Sources/ContentView.swift`에 `AuthenticationFeature` Store를 받아 checking, unauthenticated, authenticating, establishingSession, authenticated 상태별 root 화면을 선택하는 조정 View를 구현한다
- [ ] T149 [US1] `sources/Projects/App/Sources/GitItApp.swift`에 실행 환경에 맞는 `AppComposition`을 만들고 네 Domain use case를 `AuthenticationFeature` initializer에 명시적으로 주입해 root Store를 구성한다

### 사용자 스토리 2 구현

- [ ] T150 [US2] `sources/Projects/App/Sources/GitItApp.swift`에 앱 시작 시 세션 복원 action을 한 번 발행하고 앱 생명주기 재진입이 중복 복원을 만들지 않도록 연결한다

### 사용자 스토리 3 구현

- [ ] T151 [US3] `sources/Projects/App/Sources/ContentView.swift`에 recoverableFailure 상태의 `RecoveryView`와 재시도 action 연결을 추가한다

### 패키지 검증

- [ ] T152 [no-write] `xcodebuild -workspace sources/GitIt.xcworkspace -scheme GitIt -destination 'generic/platform=iOS Simulator' build`를 실행해 App 조립이 성공하고 `GitIt` target의 프로젝트 내부 의존성이 계획한 Feature·Composition·Domain 경계로 제한되는지 확인한다

**승인 게이트**: T148~T152의 변경과 검증 결과를 보고한다. 다음 작업 패키지는 없으므로
App 검증이 성공하면 같은 실행에서 T153~T160 전체 완료 검증으로 진행한다.

---

## 전체 완료 검증

마지막 작업 패키지인 App까지 구현·검증한 뒤에만 실행한다. 이 섹션은 새 구현 파일을
수정하지 않고 모든 패키지의 통합 결과가 명세·계획·quickstart를 충족하는지 확인한다.

- [ ] T153 [US1] [no-write] `specs/001-apple-social-login/quickstart.md`의 시나리오 1을 Mock으로 실행해 신규 사용자·선택 프로필 부재·중복 탭에서 계정 하나와 인증된 첫 화면이 만들어지고 민감 값이 출력되지 않는지 확인한다
- [ ] T154 [US2] [no-write] `specs/001-apple-social-login/quickstart.md`의 시나리오 2·4·5 중 기존 사용자, 복원·refresh, 로그아웃 경쟁·원격 폐기 실패를 Mock으로 실행하고 재실행 후 상태를 확인한다
- [ ] T155 [US3] [no-write] `specs/001-apple-social-login/quickstart.md`의 시나리오 3·4·5에서 취소·일시 오류·철회·refresh 거부를 실행해 토큰 보존·삭제 정책과 3초 이내 안정 화면 전환을 구분해 확인한다
- [ ] T156 [P] [no-write] `sources/Projects/Domain/DomainAuthentication/`, `sources/Projects/Data/DataAuthentication/`, `sources/Projects/Feature/FeatureAuthentication/`에서 `AuthenticationServices`, `ASAuthorization`, `identityToken`, `authorizationCode`, `@Dependency`와 Apple 이외의 회원가입·비밀번호 자격 증명 경로를 검색해 계획에서 허용하지 않은 경계 누출이 없는지 확인한다
- [ ] T157 [no-write] 저장소 루트에서 `project_build_runner build`, `compile`, `test`를 순서대로 실행해 모든 공유 scheme과 Domain·Data·Core·Composition·Feature·App 테스트를 검증한다
- [ ] T158 [no-write] `specs/001-apple-social-login/quickstart.md`의 Mock 자동화 시나리오 1~5를 모두 실행하고 SC-003·SC-006·SC-007·SC-009~SC-012의 시간·상태 기준을 확인한다
- [ ] T159 [no-write] `specs/001-apple-social-login/quickstart.md`의 실제 Apple 시스템 인증 수동 검증을 capability가 준비된 기기 또는 Simulator에서 실행하고, 준비되지 않았다면 미검증 범위를 명시한다
- [ ] T160 [no-write] `sources/`에서 `tuist generate`를 다시 실행하고 저장소 루트에서 `project_build_runner build`, `compile`, `test`를 순서대로 재실행해 Placeholder가 제거된 최종 graph와 전체 회귀 테스트를 확인한다

---

## 의존성과 실행 순서

### 패키지 의존성과 승인 순서

```text
프로젝트 내부 무의존 계층: Domain, Data, Core, UI

Domain + Data + Core     ──> Composition
Domain + UI              ──> Feature
Domain + Feature + Composition ──> App

헌법상 선형 승인 순서:
완료된 단계 1 ──> Domain ──> Data ──> Core ──> Composition
              ──> UI ──> Feature ──> App ──> 전체 완료 검증
```

- 이 선형 순서는 각 소비 패키지의 직접 의존성이 먼저 완료되는지 검증하면서 헌법이 고정한
  상대 순서를 그대로 적용하는 **작업·승인 순서**다.
- 앞 작업 패키지의 모든 태스크를 완료하고 패키지 검증 결과를 보고해야 다음 패키지를
  승인 요청할 수 있다.
- 모든 직접 의존 패키지가 먼저 완료되므로 현재 패키지의 build 또는 test가 성공해야
  다음 승인 요청으로 진행한다.
- 후속 패키지 구현 중 선행 패키지 수정이 필요하면 현재 실행을 중단하고
  `/speckit-tasks`로 소유권·의존성을 다시 조정한다.

### 사용자 스토리 추적성

- **US1(P1)**: T115, T123, T127~T131, T148~T149, T153을 통해 최초 로그인 MVP를 추적한다.
- **US2(P2)**: T116~T117, T132~T136, T150, T154를 통해 재로그인·복원·refresh·로그아웃을 추적한다.
- **US3(P3)**: T118, T137~T142, T151, T155를 통해 취소·오류·철회 복구를 추적한다.
- T018~T114, T119~T122, T124~T126, T143~T147, T152의 공통 기반·횡단 검증은
  세 스토리 모두를 지원한다.
- 각 스토리는 관련된 모든 작업 패키지가 완료된 뒤 `quickstart.md` fixture로 독립 검증한다.

### 패키지 내부 TDD 흐름

1. 🔴 **Red**: 현재 패키지의 테스트를 먼저 작성하고 예상한 이유로 실패하는지 확인한다.
2. 🟢 **Green**: 같은 패키지 안에서 테스트를 통과시키는 최소 구현을 작성한다.
3. 🔵 **Refactor**: 패키지 책임·의존 방향을 유지하며 중복을 제거하고 테스트를 다시 실행한다.

---

## 병렬 실행 예시

### Domain 패키지

```text
T018~T026  모델·계약 Red 테스트
T036~T039  Use Case Red 테스트
```

각 그룹 안의 서로 다른 파일은 병렬 실행하되 Green 구현보다 먼저 완료한다.

### Data 패키지

```text
T048~T059  계약·DTO·모델 Red 테스트
T060~T072  대응 Green 구현
```

### Core 패키지

```text
T077~T080  Apple·Keychain·CSPRNG Red 테스트
T081~T084  대응 Green 구현
```

### Composition 패키지

```text
T089~T099  vault·Adapter·세션 조정·Mock Red 테스트
T103~T113  서로 다른 Adapter·Mock Green 구현
```

각 Green 작업은 대응 Red 테스트가 예상한 이유로 실패한 뒤 시작한다.

### UI 패키지

UI 작업은 단일 구현 파일과 그 검증이 순차로 이어지므로 별도 병렬 실행 기회가 없다.

### Feature 패키지

```text
T127  정상 로그인 상태 전이 테스트
T128  중복 탭 차단 테스트
```

T127과 T128은 같은 패키지의 서로 다른 파일이며 T129 전에 병렬 실행할 수 있다.

### App 패키지

App 작업은 `ContentView.swift`와 `GitItApp.swift`의 파일 충돌·조립 의존성을 반영해 작업에
명시된 순서로 실행한다.

---

## 구현 전략

### 패키지별 승인 진행

1. 완료된 단계 1과 Domain은 보존하고 첫 미완료 작업 패키지인 Data만 구현한다.
2. Domain 완료·검증 이력을 보존하고 Data 시작에 대한 명시적 승인을 요청한 뒤 멈춘다.
3. 이후 Data → Core → Composition → UI → Feature → App 순서로 패키지 하나씩 같은
   절차를 반복한다.
4. 각 소비 패키지는 모든 직접 의존 패키지가 완료된 상태에서 시작하며 패키지 전용 검증이
   성공해야 다음 승인을 요청한다.
5. 마지막 App 검증 뒤에만 T153~T160 전체 완료 검증을 실행한다.

### MVP 제공

1. 논리적 MVP 범위는 각 패키지의 공통 기반과 US1 라벨 작업, T153 최초 로그인 검증이다.
2. 실행 단위는 사용자 스토리가 아니라 패키지이므로, 승인받은 현재 패키지에서는 US1·US2·
   US3를 포함한 그 패키지의 모든 태스크와 검증을 완료한 뒤 다음 패키지로 이동한다.
3. 따라서 배포 가능한 MVP 검증은 7개 작업 패키지를 모두 통과한 뒤 T153으로 수행하며,
   이 시점에는 같은 패키지에 속한 US2·US3 구현도 함께 존재할 수 있다.
4. T154·T155로 US2·US3 수용 기준을 각각 독립 검증한다.

## 참고

- 실제 서버 URL, HTTP method, 헤더와 JSON 필드는 확정 전까지 만들지 않는다.
- Apple `identityToken`·`authorizationCode`는 서버 교환 입력으로만 메모리에서 다루고
  Git It 세션 토큰으로 사용하거나 영구 저장하지 않는다.
- production 의존성은 생성자 또는 명시적 초기화 인자로만 전달하며 `@Dependency`,
  Service Locator, 전역 mutable container를 사용하지 않는다.
- 모든 패키지별 검증과 최종 전체 검증은 성공해야 한다.
