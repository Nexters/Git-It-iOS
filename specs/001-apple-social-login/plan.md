# 구현 계획: Apple 소셜 로그인

**브랜치**: `001-apple-social-login` | **날짜**: 2026-08-10 | **명세**: [spec.md](./spec.md)

**입력**: `specs/001-apple-social-login/spec.md`의 기능 명세

## 요약

사용자가 Apple 계정으로 인증한 결과를 Git It 자체 서버의 로그인 교환 경계로 전달하고,
서버가 발급한 Git It 액세스 토큰·리프레시 토큰으로만 세션을 유지한다. Apple의
`identityToken`과 `authorizationCode`는 서버 검증을 위한 일회성 입력으로만 메모리에
보관하고, 앱의 Keychain이나 진단 로그에 저장하지 않는다.

실제 서버 HTTP 엔드포인트와 요청·응답 형식은 아직 확정되지 않았으므로 이번 구현은
동일한 Domain 계약을 따르는 Mock을 명시적으로 주입한다. Mock은 개발·테스트·미리보기에서
반복 가능한 로그인, 갱신, 폐기 시나리오를 제공하며, 릴리스에서 실제 서버가 준비되지 않은
상태를 성공한 로그인으로 위장하지 않는다. 나중에 실제 서버 Adapter로 교체해도 Feature의
상태·화면과 Domain 계약은 바뀌지 않아야 한다.

## 기술 맥락

**언어/버전**: Swift 5 언어 모드, iOS 26.0 이상

**주요 의존성**: SwiftUI, The Composable Architecture 1.26.0, `AuthenticationServices`,
`Security`/Keychain, Swift Testing

**저장소**: 기기 Keychain에 Git It 액세스 토큰·리프레시 토큰·Apple 사용자 식별자를
보호 저장. Apple 인증 원시 토큰·인증 코드는 영구 저장하지 않음. 실제 서버 데이터베이스와
HTTP 계약은 이번 범위 밖임.

**테스트**: Swift Testing 기반 모듈 단위 테스트, TCA `TestStore`, Composition Adapter와
Mock 통합 테스트, 실제 Apple 계정을 사용하는 수동 기기 검증

**대상 플랫폼**: Apple 로그인을 지원하는 iPhone·iPad의 iOS 26.0 이상

**프로젝트 유형**: Tuist 기반 멀티 모듈 iOS 앱

**성능 목표**: 정상 로그인은 45초 이내, Apple 인증 성공 후 인증된 첫 화면은 3초 이내,
갱신 가능한 세션 복원과 로그아웃 화면 전환은 각각 3초 이내(명세 SC-001, SC-003,
SC-007, SC-009~SC-012)

**제약 조건**: 생성자 주입만 사용, `@Dependency`/Service Locator 금지, Feature는
Domain·UIComponent만 의존, Data는 Core를 직접 참조하지 않음, 민감 정보는 로그·오류
문구·화면 상태에 노출하지 않음, 실제 서버 엔드포인트 연결은 제외

**규모/범위**: Apple 단일 제공자, 로그인·세션 복원·갱신·로그아웃·복구 화면과 교체 가능한
Mock 경계. 계정 삭제, 계정 병합, 다른 로그인 제공자와 실제 서버 HTTP 구현은 제외.

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

### 0단계 조사 전 게이트

| 헌법 원칙 | 계획상 적용 | 결과 |
| --- | --- | --- |
| 명시적인 경계 | Apple 플랫폼 API와 Keychain은 `Core`, DTO·저장 계약은 `Data`, 비즈니스 계약은 `Domain`, Adapter·실행 구현 선택은 `Composition`, 화면은 `Feature`/`UIComponent`, 화면 전환은 `App`에 둔다. | 통과 |
| 상태와 데이터 안전성 | 인증 시도·세션 갱신은 취소와 늦은 완료를 처리하고, Keychain의 세션 세대 값으로 로그아웃 뒤의 재저장을 차단한다. 토큰과 Apple 원시 인증 값은 화면·로그에 노출하지 않는다. | 통과 |
| 검증 가능한 변경 | TCA 상태 전이, Domain 정책, Adapter 변환, Mock의 성공·실패·경쟁 시나리오와 수동 Apple 인증을 분리해 검증한다. | 통과 |
| 스킬별 수정 경로 | 현재 단계는 이 기능의 설계 문서만 수정한다. 구현·테스트·Tuist 변경은 다음 `speckit-tasks`와 `speckit-implement` 단계에만 기록한다. | 통과 |
| 한국어 Spec-Kit 산출물 | 계획, 조사, 데이터 모델, 계약, 빠른 시작의 자연어를 한국어로 작성한다. | 통과 |

### 1단계 설계 후 재점검

| 확인 항목 | 설계 결과 | 결과 |
| --- | --- | --- |
| 금지된 의존성 없음 | `Feature → Domain, UIComponent`, `Composition → Domain, Data, Core`만 사용하며 Domain·Data·Core는 서로의 프로젝트 내부 타입을 노출하지 않는다. | 통과 |
| production 의존성 주입 | `AppComposition`이 생성한 Domain use case를 App이 Feature initializer에 직접 전달한다. Mock/live/unavailable 구현 선택도 Composition에서 한다. | 통과 |
| 비동기 안전성 | 로그인 시도 ID와 세션 세대 값으로 중복 탭, 취소, 앱 시작 갱신, 로그아웃과 늦은 응답을 구분한다. | 통과 |
| 보안 경계 | Apple 자격 증명은 교환 직후 폐기하고, Git It 세션만 Keychain의 기기 한정 접근성으로 보관한다. 서버 연결이 없는 릴리스 구성은 인증 실패로 닫힌다. | 통과 |
| 실제 서버 미확정 | HTTP 형식 대신 안정적인 앱 내부 인증 계약과 Mock을 정의한다. 실제 endpoint Adapter는 같은 계약을 구현하는 후속 작업으로 제한한다. | 통과 |

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`,
`quickstart.md`, `contracts/**`만 수정한다. 이 산출물 밖의 구현 파일은 다음
`tasks.md`에 정확한 경로로 기록하며 계획 단계에서는 수정하지 않는다.

## 조사 결과와 기술 접근

### Apple 인증과 서버 교환

- 사용자의 명시적 탭에서만 `ASAuthorizationAppleIDProvider` 요청을 시작하고,
  `.fullName`·`.email`은 선택 정보로 요청한다.
- 각 시도는 CSPRNG 기반의 단발성 `nonce`, `state`, `attemptID`를 만들고 메모리에서만
  유지한다. 콜백의 `state`와 시도 ID가 일치할 때만 `identityToken`,
  `authorizationCode`, Apple 사용자 식별자를 교환 경계로 전달한다.
- 서버와 Mock은 Apple JWT의 검증과 Apple 사용자 식별자 연결을 담당한다. 앱은 이메일이나
  이름으로 계정을 식별·병합하지 않으며, Apple 결과가 성공했다는 이유만으로 자체 로그인
  상태를 만들지 않는다.
- `ASAuthorizationError.Code.canceled`는 경고 없는 취소로, 그 밖의 오류·누락 값·시도
  불일치는 재시도 가능한 실패로 구분한다.

### 세션 복원, 갱신, 로그아웃

- 앱 시작 시에는 보호된 화면을 먼저 노출하지 않고 Keychain 세션과 Apple credential
  state를 확인한다. `.authorized`일 때만 유효한 액세스 토큰을 사용하거나 리프레시 토큰으로
  갱신한다.
- `.revoked`·`.notFound` 또는 credential revoked 알림, 서버의 리프레시 거부·만료와 계정
  이용 불가는 두 Git It 토큰과 Apple 사용자 식별자를 삭제한 뒤 로그인 상태로 전환한다.
  `.transferred`는 자동 계정 연결을 하지 않고 후속 서버 마이그레이션 기능으로 넘긴다.
- credential state 조회 또는 토큰 갱신의 일시적 통신 실패는 토큰을 보존하되 보호된 화면을
  열지 않고 재시도 화면으로 이동한다.
- 로그아웃은 Keychain 삭제와 세션 세대 증가를 먼저 완료한다. 서버 리프레시 토큰 폐기는
  그 뒤 best-effort로 실행하며 실패해도 로컬 로그아웃을 되돌리지 않는다.

### 패키지 및 타겟 분류 (명시적 경계)

기존 모듈 구조를 명확히 구분하여 `Core`, `Data`, `Domain`, `UI`, `Feature`, `Composition`, `App` 7개의 패키지와 각 패키지 내부의 타겟을 명시적으로 정의한다.

| 패키지 | 내부 타겟 (Target) | 책임 | 구현 방향 |
| --- | --- | --- | --- |
| **Core** | `CoreAuthentication` | `AuthenticationServices`, credential revoked 알림, CSPRNG, Keychain을 프로젝트 소유 기술 API로 변환 | Apple·Security 구체 타입과 오류를 모듈 밖으로 내보내지 않는다. |
| **Data** | `DataAuthentication` | 서버 교환·갱신·폐기 DTO, 세션 저장 계약과 데이터 오류 분류 | URLSession·Keychain을 직접 참조하지 않고 필요한 계약만 정의한다. |
| **Domain** | `DomainAuthentication` | 사용자·세션 모델, 로그인·복원·재시도·로그아웃 use case와 결과 의미 | 토큰 값을 Feature에 반환하지 않으며, 기술 타입 대신 인증 의미로 계약을 표현한다. |
| **UI** | `UIComponent` | Apple 제공 디자인을 따르는 범용 Apple 로그인 제어 | 인증 상태·토큰·서버 호출을 소유하지 않고 탭 동작만 Feature에 전달한다. |
| **Feature** | `FeatureAuthentication` | TCA 상태·효과, 접근성 있는 로그인·진행·복구 화면, 외부 화면 전환 delegate | use case를 initializer로 받고 중복 탭을 막으며 Apple·Keychain·Data 타입을 참조하지 않는다. |
| **Composition**| `Composition` (또는 `AppComposition`) | Domain↔Data, Data↔Core Adapter, 단일 세션 조정 actor, Mock/live/unavailable 구현 선택 | 세션 세대와 저장 write를 직렬화하되 비즈니스 규칙을 재정의하지 않는다. |
| **App** | `GitItApp` | `AppComposition` 구성, Feature dependency 주입, 인증 전후 최상위 화면 전환 | Domain 규칙을 재판단하지 않고 Feature의 delegate만 해석한다. |

### 비동기 경쟁 제어

1. Feature는 `isAuthenticating` 상태에서 새 로그인 시작 action을 무시한다.
2. Composition의 공유 세션 조정 actor는 로그인·복원·갱신마다 현재 세션 세대를 캡처한다.
3. 로그아웃은 세대를 증가시키고 Keychain을 지운 뒤 진행 중 효과를 취소한다.
4. 늦게 도착한 교환·갱신 결과는 시작 세대와 현재 세대가 다르면 저장하거나 화면을
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
│   │   │       ├── Adapters/                   # DomainData·DataCore·Apple Adapter
│   │   │       ├── Mocks/                      # Mock Remote·Storage·AppleClient
│   │   │       ├── SessionCoordinator.swift    # 세션 세대 관리 actor
│   │   │       ├── UnavailableAuthenticationRemote.swift
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
│   │   │   ├── Contracts/                      # AuthenticationRemote·SessionStorage protocol
│   │   │   ├── DTOs/                           # 교환·갱신 요청·응답 DTO
│   │   │   ├── Models/                         # StoredSession
│   │   │   └── Errors/                         # DataAuthenticationError
│   │   └── DataAuthenticationTests/            # DTO·모델 테스트
│   ├── Domain/
│   │   ├── DomainAuthentication/               # Domain 패키지의 내부 타겟
│   │   │   ├── Models/                         # AuthenticatedUser, AuthenticationOutcome, 오류
│   │   │   ├── Contracts/                      # AuthenticationRepository, AppleAuthorizationClient
│   │   │   └── UseCases/                       # SignInWithApple, RestoreSession, SignOut
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

해당 없음. 인증 때문에 새 런타임 의존성·전역 컨테이너를 도입하지 않는다.
기존 계층과 생성자 주입 구조 안에서 플랫폼 Adapter와 Mock을 구성한다.
