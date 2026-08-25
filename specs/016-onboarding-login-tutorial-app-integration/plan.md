# 구현 계획: 온보딩·로그인·튜토리얼 App 통합

**Git-flow 유형**: `feature`

**브랜치**: `feature/onboarding-login-tutorial-app-integration`

**날짜**: 2026-08-25 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/016-onboarding-login-tutorial-app-integration/spec.md`의 기능 명세

## 요약

앱 시작 시 단 한 번 세션을 복구하고 멤버 프로필의 404와 nullable 큐레이션 필드를 구분해
복구 오류, tutorial, curation, MainShell 중 하나의 root로 이동한다. Domain에는 nullable
프로필과 설치 단위 정책 동의·세션 정리 결과 계약을 확립하고, Data와 Composition에서 서버
응답 및 로컬 저장을 연결한다. UI 공용 표현을 보강한 뒤 Feature가 tutorial·정책 동의·Apple
로그인·curation의 단일 phase를 관리하고, App이 production composition graph를 수명당 한 번
생성해 onboarding과 MainShell 전환을 조정한다.

## 기술 맥락

**언어/버전**: Swift 5 language mode, iOS 26.0+

**주요 의존성**: SwiftUI, The Composable Architecture, Tuist, AuthenticationServices,
기존 `InfrastructureAuthentication`·`InfrastructureNetworkClient`·`KeychainStore`

**저장소**: 서버 Member API, 앱 번들 정책 manifest, 계정 식별자와 분리된 설치 단위 로컬
정책 동의 저장소. 기존 범용 저장 API(`KeychainStore`, `InMemoryCache`)를 검증한 결과 둘 다
"로그아웃 후 유지 + 앱 데이터 삭제 시 무효화" 수명을 동시에 만족하지 못해([research.md
§3.1](./research.md)), Infrastructure에 `UserDefaultsStore` API를 신설해 사용한다.

**테스트**: Swift Testing 기반 Domain/Data/Composition/Feature/App 단위·계약 테스트,
UIComponent 계약 및 UI 테스트, Tuist shared scheme, project build runner, SwiftUI Preview와
Simulator 수동 접근성·Figma 비교

**대상 플랫폼**: iPhone/iPad, iOS 26.0 이상. 시각 기준은 `iPhone 17 Pro Max`.

**프로젝트 유형**: Tuist 기반 멀티 패키지 iOS 모바일 앱

**성능 목표**: launch 자동 복구 1회, 사용자 재시도당 네트워크·mutation 최대 1회, 앱 수명당
production composition graph 생성 1회, route 전환 중 stale 응답 반영 0회

**제약 조건**: 생성자 주입, Feature의 Domain protocol 전용 소비, 44×44pt 최소 hit area,
Dynamic Type·VoiceOver·Reduce Motion 지원, 정책 링크 열기 요청과 동의/로그인 조건의 분리, nullable과
unknown raw value의 비혼합, 기존 미커밋 작업 보존

정책 링크는 외부 브라우저로 열고 시스템의 열기 요청 성공·실패만 Feature에 전달한다. 브라우저가
열린 뒤의 페이지 load 결과는 앱 상태나 동의 유효성으로 추적하지 않는다. 정책 manifest는
`privacy-policy`/`1`, `terms-of-service`/`1`을 최초 계약으로 사용한다.

**규모/범위**: 7개 패키지 Domain·Infrastructure·Data·Composition·UI·Feature·App 전체. 정책
동의 저장 수명 검증 결과 기존 Infrastructure 저장 API로 FR-041을 충족하지 못해 Infrastructure가
적용 대상에 추가됐다([research.md §3.1](./research.md)). root 4상태, onboarding 6단계, tutorial
3페이지, 필수 정책 2개, curation 선택 2종, Figma 지정 상태 7종

## 헌법 점검

*게이트: 0단계 조사 전에 통과했으며 1단계 설계 후 아래 기준으로 다시 통과했다.*

- **브랜치**: 실제 브랜치는 허용된 `feature/` 네임스페이스를 사용한다.
- **경계**: Domain은 모델·정책·UseCase 계약, Infrastructure는 `UserDefaultsStore` 범용 기술
  API, Data는 Member DTO와 로컬 저장 concrete, Composition은 adapter와 수명 조립, UI는 공용
  표현, Feature는 TCA presentation, App은 root coordination과 번들 resource를 소유한다.
- **주입**: Feature는 `RestoreSessionUseCase`, `SignInUseCase`, `SignOutUseCase`,
  `FetchMemberProfileUseCase`, `CompleteCurationUseCase`, 정책 동의 UseCase를 initializer로 받는다.
  production `@Dependency`, Service Locator, Data/Composition 직접 참조를 사용하지 않는다.
- **오류 의미**: 멤버 404만 미가입으로 분기하며 transport·5xx·decoding·unknown raw value는
  재시도 오류로 보존한다. 서버 null과 `.unknown` 또는 임의 기본값을 합치지 않는다.
- **비동기 상태**: App root는 `restoring`, `onboarding`, `mainShell`만 소유하고 `restoreError`는
  onboarding 내부 phase로 둔다. restore와 sign-in은 request identity로 현재 단계에서 떠난 stale
  응답을 무시한다. 상태 조회 타입 `AuthenticationOutcome`은 `ObserveAuthenticationOutcomesUseCase`
  전용으로 유지하고, `SignInUseCase`·`SignOutUseCase`·`RestoreSessionUseCase`는 이를 재사용하지
  않는 전용 액션 결과 타입 `SignInResult`(`success`/`cancelled`/`retryableFailure`)·
  `SignOutResult`(`success`/`retryableFailure`)·`RestoreSessionResult`(`authenticated`/
  `unauthenticated`/`recoverableFailure`)를 반환한다.
- **테스트 진입점**: FeatureTests target과 shared scheme Test Action, AppTests dependency를
  각 책임 패키지 단계에서 구성한 뒤 production 변경과 함께 검증한다.
- **작업 트리 보존**: 현재 `MemberPosition`, `CareerLevel`, Member DTO/adapter 등에 사용자의
  미커밋 변경이 있다. 구현 단계는 이를 되돌리거나 덮어쓰지 않고 패키지별 diff를 다시 확인해
  명세와 정합화한다.
- **Preview 제한 예외**: FR-024와 SC-008은 화면 파일 하단의 추적 가능한 Preview를 명시하지만
  `docs/conventions/view.md`는 `Screens/Previews/` 분리를 요구한다. 이 기능에서는 사용자 승인된
  수용 기준과 node 추적성을 위해 기능 대상 화면에 한해 screen-local `#Preview`를 적용한다.
  영향은 화면 파일 크기 증가와 Preview 목록 분산이며, 상태별 deterministic sample과 실행 가능한
  scheme으로 검증한다. 이유·영향·검증 범위를 PR에 기록한다.
- **게이트 결과**: 위 Preview 예외 외 위반 없음. 예외는 Constitution 원칙 3의 기록·검증 요건으로
  정당화되며 unresolved `NEEDS CLARIFICATION`은 없다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/016-onboarding-login-tutorial-app-integration/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── onboarding-flow.md
└── tasks.md                 # /speckit-tasks 산출물
```

### 소스 코드(계획된 구현 경로)

```text
sources/Projects/
├── Domain/
│   ├── Authentication/{Models,Contracts,UseCases}/
│   ├── Member/{Models,Errors}/
│   └── Tests/{Authentication,Member}/
├── Infrastructure/
│   ├── Storage/UserDefaultsStore.swift
│   └── Tests/Storage/
├── Data/
│   ├── Member/{DTOs,Errors,Remotes}/
│   ├── LegalConsent/{Contracts,Models,Stores}/
│   └── Tests/{Member,LegalConsent}/
├── Composition/
│   ├── Adapter/{AppComposition,AuthenticationAssembly,MemberAssembly,...}.swift
│   └── Tests/Adapter/
├── UI/
│   ├── Component/Components/{Leaf,Composite}/
│   ├── Component/Resources/
│   └── Tests/Component/
├── Feature/
│   ├── Presentation/Onboarding/{OnboardingFeature,*Screen}.swift
│   ├── Presentation/MainShell/
│   └── Tests/Onboarding/
└── App/
    ├── Sources/{GitItApp,ContentView,AppRootFeature,AppRootView}.swift
    ├── Resources/Policies/
    └── Tests/GitIt/

sources/Tuist/ProjectDescriptionHelpers/Projects/
├── FeatureModuleName.swift
└── AppModuleName.swift
```

**구조 결정**: 기존 7패키지 구조를 유지한다. 기존 저장 API(`KeychainStore`, `InMemoryCache`)가
설치 단위 정책 동의의 수명 요건(FR-041)을 충족하지 못함을 검증했으므로([research.md
§3.1](./research.md)) Infrastructure에 `UserDefaultsStore` 범용 기술 API를 신설하는 단계를
적용 대상에 포함한다.

## 패키지 구현 경계와 승인 순서

아키텍처 의존성 표에서 `App → Feature, Composition, Domain`, `Feature → Domain, UI`,
`Composition → Domain, Data, Infrastructure`, `Data → Infrastructure`를 적용한다. 적용 대상의
위상 순서는 `Domain → Infrastructure → Data → Composition → UI → Feature → App`으로 고정한다.
Domain과 Infrastructure는 서로 의존하지 않지만 Data가 신규 `UserDefaultsStore`를 소비하려면
Infrastructure가 먼저 완료돼야 하므로 Data 직전에 배치했고, 이미 확정된 Domain 우선 순서는
바꾸지 않았다. UI는 Domain·Data·Composition과 독립이지만 Feature가 UI와 Domain을 함께
소비하므로 기반 계약을 먼저 안정화하고 UI 이후 Feature로 넘어가도록 상대 순서를 정했다.

각 단계는 구현, 해당 패키지 검증, 변경·결과 보고, 사용자의 명시적 다음 단계 승인까지 완료한
뒤에만 다음 패키지 파일을 수정한다.

1. **Domain**: nullable `MemberProfile`, unknown raw value 오류 의미, 세션 정리 결과, 정책 문서·
   동의 기록·유효성 정책과 저장 UseCase protocol을 정의한다. 기존 `CareerLevel.beginner`를
   최종 공개 이름 `CareerLevel.entry`로 변경하고 `CareerLevel.unknown`은 추가하거나 지원하지 않는다.
   `SignInUseCase`·`SignOutUseCase`·`RestoreSessionUseCase`는 상태 조회 타입 `AuthenticationOutcome`을
   재사용하지 않고 각각 전용 `SignInResult`·`SignOutResult`·`RestoreSessionResult` 액션 결과
   타입을 반환하도록 계약과 구현(`SignIn.swift` 등)을 분리한다.
2. **Infrastructure**: `UserDefaultsStore` 범용 기술 API를 신설한다. `InMemoryCache`와 같은
   제네릭 key-value 형태로 `UserDefaults` 위에 Codable 값을 저장·조회·삭제하는 프로젝트 내부
   기술 타입만 제공하며 Domain·Data 의미는 노출하지 않는다([research.md §3.1](./research.md)).
3. **Data**: Member DTO의 null 보존과 unknown raw value 구분을 검증하고, 계정 식별자가 없는
   설치 단위 정책 동의 record의 serialization과 `UserDefaultsStore` 기반 local store를 구현한다.
4. **Composition**: Domain↔Data adapter, 정책 동의 저장 수명, 404 후 명시적 세션 정리, member
   graph의 `CompleteCurationUseCase` 단일 정본을 조립해 Domain protocol만 공개한다.
5. **UI**: 기존 `ActionButton`, `SelectionCard`, `SelectionCardList`, `SheetSurface`,
   `ProgressSegments`, `OnboardingMockup`을 우선 재사용하고 단일 선택 callback·접근성, 정책 행,
   page indicator/tooltip 중 여러 Feature에 재사용 가능한 표현만 확장한다.
6. **Feature**: 단일 onboarding phase와 request identity를 가진 reducer, 화면별 `*Screen.swift`,
   파일 하단 deterministic Preview, reducer tests를 구현한다. `FeatureModuleName.swift`의 FeatureTests
   선언과 scheme 연결은 Feature 패키지 단계에 배정한다.
7. **App**: 번들 정책 manifest, production graph 1회 생성, onboarding/MainShell root coordination,
   logout/session invalidation 복귀, App tests를 구현한다. `AppModuleName.swift`의 AppTests dependency는
   App 단계에 배정한다.

전체 저장소 build/compile/test와 수동 시각·접근성 검증은 App 단계 승인 후 `[no-write]` 최종
검증으로 실행한다. `[no-write]`에서 `make tuist`의 파생 workspace·project·심볼릭 링크·cache
갱신은 허용하되 실행 전후 Git 상태를 비교하고 추적 대상 소스·문서나 Git index 변경이 생기면
완료로 처리하지 않는다. Tuist 공용 helper 변경은 각 파일을 최초로 필요로 하는 Feature 또는 App
단계에 각각 분리해 배정한다.

## 설계 후 헌법 재점검

- 모든 구현 파일이 정확히 한 책임 패키지에 배정되었고 다중 패키지 준비/마무리 단계가 없다.
- 정책 manifest 파일은 최초 소비자이자 번들 소유자인 App에, 유효성 정책은 Domain에 배정됐다.
- UI와 Feature가 업무 모델을 공유하지 않고 표시 값·Binding·callback 경계를 유지한다.
- App은 상태 판정 로직을 재구현하지 않고 Feature delegate와 Domain 결과만 조정한다.
- 상태 조회(`AuthenticationOutcome`)와 액션 결과(`SignInResult`/`SignOutResult`/
  `RestoreSessionResult`)를 분리해 FR-009·FR-033의 취소/실패 구분이 Domain 타입 수준에서
  표현된다(`/speckit-analyze` 세션 2026-08-26에서 확인된 계약 공백을 해소).
- 정책 동의 저장 기술은 추정이 아니라 기존 Infrastructure API 두 종의 수명을 직접 확인한
  뒤 결정했다(`/speckit-analyze` 세션 2026-08-26 F2 보완). `UserDefaultsStore`는 `Data →
  Infrastructure` 의존만 추가하며 Domain·Composition·UI·Feature·App의 경계와 승인 순서는
  바꾸지 않는다.
- Preview 예외는 기능 화면으로 한정되며 공용 UIComponent Preview 규칙은 변경하지 않는다.
- Figma 비교는 tutorial `779:33450`·`779:33529`·`779:33564`, 약관 전체 선택 `786:38332`,
  분야 선택 `737:10367`, Career `737:10358`·`737:10349`로 고정한다. Google 로그인 표현,
  개인정보 관련 명칭, 분야 화면 닫기 표현과 360×800 frame은 명세를 우선하는 승인된 차이다.

## 복잡성 추적

| 위반 | 필요한 이유 | 더 단순한 대안을 기각한 이유 |
|---|---|---|
| Feature 화면 파일 하단 `#Preview` | FR-024/SC-008의 파일별 추적성과 사용자가 지정한 screen-local 비교 진입점을 충족 | `Screens/Previews/` 분리는 공통 컨벤션에는 부합하지만 해당 기능의 파일별 수용 기준과 node 상태 추적을 충족하지 못함 |
