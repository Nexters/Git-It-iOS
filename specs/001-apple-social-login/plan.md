# 구현 계획: Apple 소셜 로그인

**브랜치**: `001-apple-social-login` | **날짜**: 2026-08-10 | **명세**: [spec.md](./spec.md)

**입력**: `specs/001-apple-social-login/spec.md`의 기능 명세

## 요약

Domain은 지원하는 인증 방식을 자체 `AuthenticationMethod`로 표현하며 이번 범위에서는
`.apple`을 제공한다. `AuthenticationRepository`는 선택한 방식의 외부 인증만 수행하고
공급자 중립 단발성 `AuthenticationGrant`를 반환한다. `SessionRepository`는 이 grant를
Git It 서버와 교환해 세션을 시작·보호 저장하고, 이후 복원·갱신·로그아웃을 담당한다.
Domain `SignIn` use case가 두 Repository를 순서대로 조정하되 Apple API·credential·토큰
저장 기술은 알지 않는다.

`AuthenticationRepository`의 production Adapter는 Data가 정의한 공급자 중립
`ExternalAuthenticationProvider`에만 의존한다. 별도 Data↔Core Adapter가 method identifier를
Core의 Apple 기술 API로 연결하고 Apple credential state를 Data 소유 상태로 변환한다. 따라서
Domain↔Data Adapter에도 Apple API·타입·상태 분기 논리가 들어가지 않는다.

Apple의 `identityToken`과 `authorizationCode`는 Data↔Core Adapter에서 Apple 필드가 없는
불투명 evidence payload로 변환한 뒤 Composition의 명시적으로 주입된
`AuthenticationGrantVault`에만 잠시 보관하고 grant ID로 한 번만 소비한다. 실제 서버 HTTP
엔드포인트와 요청·응답 형식은 아직 확정되지 않았으므로 `SessionRemote`는 공급자별 필드를
고정하지 않는 앱 내부 세션 경계를 제공한다. 인증 Mock과 세션 Mock을 분리해 주입하며 나중에
실제 서버 Adapter로 교체해도 Feature와 Domain 계약은 바뀌지 않아야 한다.

## 기술 맥락

**언어/버전**: Swift 5 언어 모드, iOS 26.0 이상

**주요 의존성**: SwiftUI, The Composable Architecture 1.26.0, `AuthenticationServices`,
`Security`/Keychain, Swift Testing

**저장소**: 기기 Keychain에 Git It 액세스 토큰·리프레시 토큰과 공급자 중립 인증 참조를
서로 구분해 보호 저장. Apple 인증 원시 토큰·인증 코드는 grant vault의 메모리에만 두고
영구 저장하지 않음. 실제 서버 데이터베이스와 HTTP 계약은 이번 범위 밖임.

**테스트**: Swift Testing 기반 모듈 단위 테스트, TCA `TestStore`, Domain 인증/세션 계약,
grant 단발 소비, Composition Adapter와 분리된 인증·세션 Mock 통합 테스트, 실제 Apple
계정을 사용하는 수동 기기 검증

**대상 플랫폼**: Apple 로그인을 지원하는 iPhone·iPad의 iOS 26.0 이상

**프로젝트 유형**: Tuist 기반 멀티 모듈 iOS 앱

**성능 목표**: 정상 로그인은 45초 이내, Apple 인증 성공 후 인증된 첫 화면은 3초 이내,
갱신 가능한 세션 복원과 로그아웃 화면 전환은 각각 3초 이내(명세 SC-001, SC-003,
SC-007, SC-009~SC-012)

**제약 조건**: 생성자 주입만 사용, `@Dependency`/Service Locator 금지, Feature는
Domain·UIComponent만 의존, Data는 Core를 직접 참조하지 않음, Domain 공개 API는
`AuthenticationMethod.apple` 같은 비즈니스 의미만 허용하고 Apple API·credential·오류·
credential state 논리를 금지, 인증과 서버 세션 책임 분리, 민감 정보는 로그·오류 문구·화면
상태에 노출하지 않음, 실제 서버 엔드포인트 연결은 제외

**규모/범위**: Apple 단일 제공자, 로그인·세션 복원·갱신·로그아웃·복구 화면과 교체 가능한
Mock 경계. 계정 삭제, 계정 병합, 다른 로그인 제공자와 실제 서버 HTTP 구현은 제외.

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

### 0단계 조사 전 게이트

| 헌법 원칙 | 계획상 적용 | 결과 |
| --- | --- | --- |
| 명시적인 경계 | Domain은 `AuthenticationMethod`·`AuthenticationGrant`와 인증/세션 Repository 계약을 소유한다. 외부 인증은 `AuthenticationRepository`, Git It 서버 세션은 `SessionRepository`로 분리한다. Data는 공급자 중립 `ExternalAuthenticationProvider`와 DTO·저장 계약, Core는 Apple 플랫폼 API와 Keychain 래퍼, Composition은 Domain↔Data와 Data↔Core Adapter·실행 구현 선택을 소유한다. | 통과 |
| 상태와 데이터 안전성 | 인증 시도·세션 갱신은 취소와 늦은 완료를 처리하고, Composition 세션 조정 actor의 프로세스 내 세대 값으로 로그아웃 뒤의 재저장을 차단한다. 토큰과 Apple 원시 인증 값은 화면·로그에 노출하지 않는다. | 통과 |
| 검증 가능한 변경 | TCA 상태 전이, Domain 인증→세션 조정, grant 단발 소비, Adapter 변환, 분리된 인증·세션 Mock의 성공·실패·경쟁 시나리오와 수동 Apple 인증을 검증한다. | 통과 |
| 스킬별 수정 경로 | 현재 단계는 이 기능의 설계 문서만 수정한다. 구현·테스트·Tuist 변경은 다음 `speckit-tasks`와 `speckit-implement` 단계에만 기록한다. | 통과 |
| 한국어 Spec-Kit 산출물 | 계획, 조사, 데이터 모델, 계약, 빠른 시작의 자연어를 한국어로 작성한다. | 통과 |

### 1단계 설계 후 재점검

| 확인 항목 | 설계 결과 | 결과 |
| --- | --- | --- |
| 금지된 의존성 없음 | `Feature → Domain, UIComponent`, `Composition → Domain, Data, Core`만 사용한다. Domain은 `.apple`을 도메인 값으로만 소유하고 `AuthenticationServices`, Apple credential, nonce/state, credential state를 공개 API와 use case 논리에서 배제한다. Domain `AuthenticationRepository` Adapter는 Data 계약만 사용하고 Apple 기술 연결은 별도 Data↔Core Adapter에 둔다. | 통과 |
| production 의존성 주입 | `AppComposition`이 생성한 Domain use case를 App이 Feature initializer에 직접 전달한다. Mock/live/unavailable 구현 선택도 Composition에서 한다. | 통과 |
| 비동기 안전성 | 로그인 시도 ID, 단발성 grant ID와 세션 세대 값으로 중복 탭, grant 재사용, 취소, 앱 시작 갱신, 로그아웃과 늦은 응답을 구분한다. | 통과 |
| 보안 경계 | Domain grant에는 ID와 인증 방식만 포함한다. Apple 자격 증명은 Composition vault에서 한 번만 소비하고, Git It 세션과 공급자 인증 참조는 구분된 보호 저장 경계에 보관한다. 서버 연결이 없는 릴리스 구성은 세션 시작 실패로 닫힌다. | 통과 |
| 실제 서버 미확정 | HTTP 형식 대신 공급자 중립 `SessionRemote`와 분리된 인증·세션 Mock을 정의한다. 실제 endpoint Adapter는 같은 계약을 구현하는 후속 작업으로 제한한다. | 통과 |

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`,
`quickstart.md`, `contracts/**`만 수정한다. 이 산출물 밖의 구현 파일은 다음
`tasks.md`에 정확한 경로로 기록하며 계획 단계에서는 수정하지 않는다.

## 조사 결과와 기술 접근

### 인증 방식과 단발성 grant

- Domain `AuthenticationMethod`는 지원하는 소셜 인증 방식을 자체 비즈니스 언어로 정의하고
  이번 기능에서 `.apple`을 제공한다. 이는 Apple API 타입이나 실행 절차에 대한 의존이 아니다.
- `AuthenticationRepository.authenticate(using: .apple)`는 외부 인증까지만 담당하고
  `AuthenticationGrant(id, method)`를 반환한다. 서버 교환·세션 저장은 수행하지 않는다.
- Domain↔Data 인증 Adapter는 `.apple`을 Data의 안정적인 method identifier로만 변환해
  `ExternalAuthenticationProvider`에 전달한다. 이 Adapter는 Core나 Apple 기술 타입을
  참조하지 않는다.
- Data↔Core 인증 Adapter가 method identifier를 Core `AppleAuthorizationProvider`에 연결한다.
  Core는 사용자의 명시적 탭에서만 `ASAuthorizationAppleIDProvider` 요청을 시작하고
  `.fullName`·`.email`은 선택 정보로 요청한다.
- Core의 각 시도는 CSPRNG 기반의 단발성 `nonce`, `state`, `attemptID`를 만들고 메모리에서만
  유지한다. 콜백의 `state`와 시도 ID가 일치할 때만 프로젝트 소유 Core credential을 반환하고,
  Data↔Core Adapter는 이를 Apple 필드가 없는 불투명 `ExternalAuthenticationEvidence`로
  변환한다. Domain↔Data Adapter가 evidence를 grant vault에 보관한다.
- `AuthenticationGrantVault`는 Composition이 소유하는 actor이며 두 Repository Adapter에
  initializer로 주입한다. production grant ID 생성기는 Core CSPRNG를 감싼 closure로 vault
  initializer에 전달하고 테스트에서는 결정적인 생성기를 주입한다. vault는 grant ID별 불투명
  evidence payload를 한 번만 소비하고 완료·취소·만료·실패 때 즉시 폐기하며 전역 container로
  노출하지 않는다.
- Core는 `ASAuthorizationError.Code.canceled`와 그 밖의 Apple 오류를 프로젝트 소유 기술
  오류로 격리한다. Data↔Core Adapter와 Domain↔Data Adapter가 이를 단계별로 변환해 최종적으로
  Domain `AuthenticationError`를 반환한다. Domain에는 Apple 오류나 원시 credential이
  전달되지 않는다.

### 서버 세션 시작, 복원, 갱신, 로그아웃

- Domain `SignIn`은 `AuthenticationRepository`에서 grant를 받은 뒤
  `SessionRepository.start(with:)`를 호출한다. 세션 시작이 실패하면 인증 grant와 임시 인증
  상태를 정리하고 인증 성공을 반환하지 않는다.
- `SessionRepository.start(with:)` 구현은 grant vault에서 불투명 evidence payload를 한 번 소비하고
  공급자 중립 `SessionRemote`로 Git It 서버 세션을 요청한다. 서버 응답과 보호 저장이 모두
  성공한 뒤에만 `AuthenticatedUser`를 반환한다.
- `AuthenticationRepository`는 공급자 인증 참조와 generic authorization status 조회·변경
  stream을, `SessionRepository`는 Git It access/refresh token과 서버 세션 상태를 각각
  소유한다. `RestoreSession`과 `ObserveAuthorizationChanges` use case는 두 상태를 조정해
  `AuthenticationOutcome`을 만들며 Feature는 authorization status 자체를 판단하지 않는다.
  두 use case 모두 Apple credential state나 알림 타입을 직접 알지 않는다.
- Apple `.revoked`·`.notFound`·`.transferred`와 revoked 알림은 Data↔Core Adapter 내부에서
  Data `.inactive`로 수렴시킨다. Domain↔Data Adapter는 이를
  `.reauthenticationRequired`로 변환한다. `.authorized`는 Data `.active`를 거쳐 Domain
  `.authorized`로, 조회 일시 오류는 Data와 Domain의 `.temporarilyUnavailable`로 변환한다.
  Domain과 Data는 Apple 상태 case를 복제하지 않는다. 재인증 필요·서버 거부·계정 이용 불가가
  확인되면 Domain 흐름이 서버 세션과 인증 참조를 각각 정리한다.
- `SessionRepository`는 access token이 만료되면 내부적으로 refresh를 수행한다. 일시적 통신
  실패는 토큰을 보존하고, refresh 거부·만료만 서버 세션을 삭제한다. refresh는 Domain 공개
  use case로 노출하지 않는다.
- `SignOut` use case는 `SessionRepository.signOut()`으로 로컬 서버 세션 삭제와 세대 증가를
  먼저 완료한 뒤 `AuthenticationRepository.clearAuthorization()`으로 공급자 인증 참조를
  정리한다. 서버 리프레시 토큰 폐기는 best-effort이며 실패해도 로컬 로그아웃을 되돌리지 않는다.

### 패키지 및 타겟 분류 (명시적 경계)

기존 모듈 구조를 명확히 구분하여 `Core`, `Data`, `Domain`, `UI`, `Feature`, `Composition`, `App` 7개의 패키지와 각 패키지 내부의 타겟을 명시적으로 정의한다.

| 패키지 | 내부 타겟 (Target) | 책임 | 구현 방향 |
| --- | --- | --- | --- |
| **Core** | `CoreAuthentication` | `AuthenticationServices`, credential revoked 알림, CSPRNG, Keychain을 프로젝트 소유 기술 API로 변환 | Apple·Security 구체 타입과 오류를 Core 밖의 Domain/Data API로 내보내지 않는다. |
| **Data** | `DataAuthentication` | 공급자 중립 외부 인증 획득·상태 계약, 세션 시작·갱신·폐기 계약, 서버 세션/인증 참조 저장 계약과 Data 모델·오류 분류 | `ExternalAuthenticationProvider`와 `SessionRemote`는 Apple 필드나 상태 case·분기 논리를 갖지 않고 method identifier와 불투명한 evidence만 취급한다. Core·URLSession·Keychain을 직접 참조하지 않는다. |
| **Domain** | `DomainAuthentication` | `AuthenticationMethod`, `AuthenticationGrant`, 사용자·결과·오류, 분리된 `AuthenticationRepository`/`SessionRepository`, `SignIn`·복원·authorization 변경 관찰·로그아웃 use case | `.apple`은 지원 방식이라는 비즈니스 값으로 허용하되 Apple API·credential·nonce/state·credential state를 계약과 use case에서 배제한다. `SignIn`이 인증→세션 시작을 조정하고 Feature에는 Repository 대신 use case를 제공한다. |
| **UI** | `UIComponent` | Apple 제공 디자인을 따르는 범용 Apple 로그인 제어 | 인증 상태·토큰·서버 호출을 소유하지 않고 탭 동작만 Feature에 전달한다. |
| **Feature** | `FeatureAuthentication` | TCA 상태·효과, 인증 방식 선택, 접근성 있는 로그인·진행·복구 화면, 외부 화면 전환 delegate | `.apple` 선택을 Domain `AuthenticationMethod`로 전달하고 `SignIn`·`RestoreSession`·`ObserveAuthorizationChanges`·`SignOut` use case만 호출한다. Repository, authorization 상태 판단, Apple 결과·Keychain·Data 타입을 참조하지 않는다. |
| **Composition**| `Composition` (또는 `AppComposition`) | Authentication/Session Domain↔Data Adapter, 외부 인증/저장 Data↔Core Adapter, 단발성 grant vault, 세션 조정 actor, 인증·세션 Mock/live/unavailable 구현 선택 | Domain 인증 Adapter는 Data 계약만, Data 외부 인증 Adapter는 Core 기술 API만 사용한다. 두 Repository 구현을 분리하고 vault와 세션 세대를 직렬화하되 Domain 비즈니스 규칙을 재정의하지 않는다. |
| **App** | `GitItApp` | `AppComposition` 구성, Feature dependency 주입, 인증 전후 최상위 화면 전환 | Domain 규칙을 재판단하지 않고 Feature의 delegate만 해석한다. |

### 비동기 경쟁 제어

1. Feature는 `isAuthenticating` 상태에서 새 인증 방식 선택 action을 무시한다.
2. 인증 Adapter는 성공한 외부 인증마다 새 grant ID를 만들고 vault에 한 번만 등록한다.
3. 세션 Adapter는 grant를 원자적으로 소비한다. 이미 소비·만료·삭제된 grant는 서버 세션을
   시작할 수 없다.
4. Composition의 공유 세션 조정 actor는 세션 시작·복원·갱신마다 현재 세션 세대를 캡처한다.
5. 로그아웃은 세대를 증가시키고 서버 세션을 지운 뒤 진행 중 효과를 취소하며 인증 참조와
   남은 grant를 별도로 정리한다.
6. 늦게 도착한 세션 시작·갱신 결과는 시작 세대와 현재 세대가 다르면 저장하거나 화면을
   인증 상태로 되돌리지 않는다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/001-apple-social-login/
├── plan.md                         # 이 파일(/speckit-plan 산출물)
├── research.md                     # 0단계 조사 결과
├── data-model.md                   # 1단계 데이터·상태 모델
├── quickstart.md                   # 1단계 검증 안내
├── contracts/
│   └── authentication-boundary.md  # 앱 내부 인증 경계 계약
└── tasks.md                        # 2단계 산출물(/speckit-tasks가 생성)
```

### 소스 코드(구현 시 추가·수정 예정)

각 패키지 내부 타겟을 기반으로 한 구조:

```text
sources/
├── Projects/
│   ├── App/
│   │   ├── Sources/
│   │   │   ├── GitItApp.swift                  # Composition 생성과 최상위 흐름 연결
│   │   │   └── ContentView.swift               # 인증 상태별 root 화면
│   │   └── Tests/                              # App 흐름 검증
│   ├── Composition/
│   │   ├── Composition/                        # Composition 패키지의 내부 타겟
│   │   │   └── Authentication/
│   │   │       ├── Adapters/                   # Domain↔Data 인증·세션, Data↔Core 외부 인증·저장
│   │   │       ├── Mocks/                      # 인증·세션 Remote·저장소 Mock
│   │   │       ├── AuthenticationGrantVault.swift # 불투명 evidence 단발 소비 actor
│   │   │       ├── SessionCoordinator.swift    # 세션 세대 관리 actor
│   │   │       ├── UnavailableSessionRemote.swift
│   │   │       └── AppComposition+Authentication.swift
│   │   └── CompositionTests/                   # Adapter·세션 조정 테스트
│   │       └── Authentication/
│   ├── Core/
│   │   ├── CoreAuthentication/                 # Core 패키지의 내부 타겟
│   │   │   ├── AppleAuthentication/            # ASAuthorization 래퍼, credential state 조회
│   │   │   ├── Keychain/                       # Keychain CRUD API
│   │   │   └── RandomGenerator/                # CSPRNG nonce·state·attemptID 생성
│   │   └── CoreAuthenticationTests/            # Keychain·난수 생성 테스트
│   ├── Data/
│   │   ├── DataAuthentication/                 # Data 패키지의 내부 타겟
│   │   │   ├── Contracts/                      # ExternalAuthenticationProvider·SessionRemote·저장 계약
│   │   │   ├── DTOs/                           # 공급자 중립 세션 시작·갱신 요청·응답
│   │   │   ├── Models/                         # ExternalAuthenticationEvidence·상태·저장 모델
│   │   │   └── Errors/                         # DataAuthenticationError
│   │   └── DataAuthenticationTests/            # DTO·모델 테스트
│   ├── Domain/
│   │   ├── DomainAuthentication/               # Domain 패키지의 내부 타겟
│   │   │   ├── Models/                         # AuthenticationMethod·Grant·User·Outcome·오류
│   │   │   ├── Contracts/                      # AuthenticationRepository·SessionRepository
│   │   │   └── UseCases/                       # SignIn·RestoreSession·ObserveAuthorizationChanges·SignOut
│   │   └── DomainAuthenticationTests/          # 모델·use case 테스트
│   ├── Feature/
│   │   ├── FeatureAuthentication/              # Feature 패키지의 내부 타겟
│   │   │   └── Authentication/
│   │   │       ├── AuthenticationFeature.swift  # TCA Reducer
│   │   │       └── Views/                      # SignInView, AuthenticatedView, RecoveryView
│   │   └── FeatureAuthenticationTests/         # TCA TestStore 테스트
│   └── UI/
│       └── UIComponent/                        # UI 패키지의 내부 타겟
│           └── Authentication/                 # Apple 로그인 제어
└── Tuist/ProjectDescriptionHelpers/
    ├── Target+Module.swift                     # 모듈·테스트 target 공통 구성
    └── Projects/
        ├── AppModuleName.swift
        ├── CompositionModuleName.swift
        ├── CoreModuleName.swift
        ├── DataModuleName.swift
        ├── DomainModuleName.swift
        └── FeatureModuleName.swift             # production·test target 의존성
```

**구조 결정**: 기존 Tuist 멀티 모듈 iOS 구조를 유지한다. `Core`, `Data`, `Domain`, `UI`, `Feature`, `Composition`, `App` 7개의 패키지 경계를 명확히 하고 각 패키지 하위의 타겟을 명시적으로 구분하여 인증 기능을 배치한다. 생성된 Xcode 프로젝트를 직접 수정하지 않고 Tuist 원본을 변경한 뒤 재생성한다.

## 복잡성 추적

| 추가 복잡성 | 필요한 이유 | 제한 방법 |
| --- | --- | --- |
| Composition `AuthenticationGrantVault` actor | 분리된 인증/세션 Repository 사이에서 불투명 외부 인증 evidence를 Domain에 노출하지 않고 한 번만 전달해야 한다. | initializer로 두 Adapter와 grant ID 생성 closure를 명시적으로 주입하고, grant ID별 단발 소비·만료·전체 정리만 제공한다. 전역 접근과 영구 저장을 금지한다. |
| 인증 참조 저장소와 서버 세션 저장소 분리 | Apple authorization 상태와 Git It 토큰 세션은 수명·폐기 조건이 다른 책임이다. | 둘 다 Core의 범용 Keychain API를 Adapter로 사용하되 Data 계약과 저장 key namespace를 분리한다. |
