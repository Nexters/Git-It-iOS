# 구현 계획: Onboarding Router 리팩토링

**Git-flow 유형**: `feature`

**브랜치**: `미생성 (예정: feature/onboarding-router-refactor)`

**날짜**: 2026-08-28 | **명세**: [spec.md](./spec.md)

**입력**: `specs/017-onboarding-router-refactor/spec.md`의 기능 명세

**참고**: 이 템플릿은 `/speckit-plan`이 채운다. 스킬 정의에는 실행 흐름이 설명되어 있다.

## 요약

`OnboardingFeature` 하나(약 500줄)가 세션 복원(인증)과 온보딩 화면 로직을 모두 갖고
있던 것을, 두 가지 축으로 나눈다. 첫째, 세션 복원·"온보딩 진입이 필요한가" 판단은
Onboarding의 책임이 아니므로 App 최상위 Route(`AppRootFeature`)가 진입 목적지를 결정하는
쪽으로 옮긴다. 다만 그 판단에 필요한 실제 세션 복원 Effect 실행과 스플래시/재시도 화면은
`AppRootFeature`(App 패키지)가 아니라 **새로 만드는 Feature 패키지의 `AppEntryFeature`**가
소유한다 — App 패키지는 아키텍처상 UI 패키지(DesignSystem·UIComponent)에 의존할 수 없어
스플래시 화면을 직접 그릴 수 없기 때문이다. `AppRootFeature`는 `AppEntryFeature`를 Child로
조합하고 그 `delegate`(목적지 결정)만 받아 자신의 `route`를 전환한다 — 지금
`AppRootFeature`가 `onboarding`/`mainShell` Child의 delegate로 `route`를 전환하는 것과
동일한 패턴이다.

둘째, 온보딩 진입이 이미 확정된 뒤의 흐름은 `OnboardingRouterFeature`(기존
`OnboardingFeature`를 대체)가 온보딩 안내(튜토리얼·약관 동의·로그인)와 큐레이션
(포지션·경력 선택) 2개 화면 Feature를 조합한다. Router의 화면 값에는 "완료" case를 두지
않고, 큐레이션 제출 성공 등 조건을 관찰해 "Router가 상위로 나가야 하는가"만 판단하는
별도 하위 `OnboardingExitFeature`를 둔다. Router는 화면이 실제로 전환될 때마다 테스트로
조회 가능한 이동 이벤트를 기록한다.

세 구조(`AppEntryFeature`→`AppRootFeature`, 화면 Feature→`OnboardingRouterFeature`)
모두 `delegate` Action과 생성자 주입만으로 상태를 전달하며, TCA `@Shared`·`Binding`·
`inout` 기반 공유는 도입하지 않는다. Router 패턴 자체는 이 프로젝트에 처음 도입되므로
`docs/conventions/tca.md`에 정식 섹션을 추가한다.

## 기술 맥락

**언어/버전**: Swift (iOS 26.0+, `AGENTS.md` 기준)

**주요 의존성**: The Composable Architecture(TCA) 1.26.0(고정, `Package.resolved` 확인),
SwiftUI, 기존 `DomainAuthentication`·`DomainMember` UseCase protocol

**저장소**: 해당 없음 — Feature/App 계층의 in-memory TCA State만 다루며, 세션 정본은
Keychain(Infrastructure), 회원 프로필 정본은 서버(Data)로 리팩토링 전후 변경 없음

**테스트**: Swift Testing 기반 `TestStore` (`docs/conventions/test.md`), UI 자동화 등
플랫폼 제약이 있는 경우로 한정해 XCTest

**대상 플랫폼**: iOS 26.0+ (iOS Simulator, iPhone 17 Pro 기준 테스트)

**프로젝트 유형**: 모바일 앱 — Tuist 멀티 패키지(App/Composition/Feature/Domain/Data/
Infrastructure/UI), TCA 기반

**성능 목표**: 해당 없음 — 내부 구조 리팩토링이며 사용자 체감 성능 목표에 새 요구를
추가하지 않는다(SC-005: 화면 순서·동작 무변경).

**제약 조건**:
- FR-010: 리팩토링으로 최종 사용자에게 보이는 화면 동작·앱 시작 흐름이 달라지지 않는다.
- 아키텍처 의존성 표(`docs/architecture.md` 3.1): App은 Feature·Composition·Domain에만
  의존할 수 있고 UI에는 의존할 수 없다. 이 제약이 이번 계획에서 `AppEntryFeature`를
  Feature 패키지에 두는 핵심 근거다.
- FR-012: Router보다 긴 생명주기 상태 공유에 `@Shared`·`Binding`·`inout`을 쓰지 않는다.

**규모/범위**: Feature 패키지 Onboarding 하위 재구성(화면 Feature 2개 + Router + Exit
판단 Feature 1개) + Feature 패키지 신규 `AppEntry` 폴더(1개 Feature) + App 패키지
`AppRootFeature`/`AppRootView`/`GitItApp.swift` 갱신 + `docs/conventions/tca.md` Router
섹션 추가. Domain/Data/Infrastructure/UI 패키지는 변경하지 않는다(기존 UseCase
protocol과 UI 컴포넌트를 그대로 재사용). **Composition 패키지도 변경하지 않는다** —
`research.md` 4절에서 확인했듯 `AppComposition`은 이미 필요한 UseCase를 전부 개별
프로퍼티로 노출하고 있어, 그 UseCase를 어떤 Feature initializer에 나눠 넣을지는 App
패키지(`GitItApp.swift`)의 조립 책임이다.

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

- **브랜치 네임스페이스**: `before_specify` 훅이 실행되지 않아 브랜치가 아직 생성되지
  않았다(`미생성 (예정: feature/onboarding-router-refactor)`). 향후 실제 생성 시
  `feature/` 네임스페이스를 사용해야 하며, 이 계획은 브랜치가 생성된 것처럼 기록하지
  않는다. **PASS**.
- **허용 수정 경로**: 이 계획 단계는 `plan.md`, `research.md`, `data-model.md`,
  `quickstart.md`, `contracts/**`만 수정한다. 구현 파일 경로는 아래 프로젝트 구조와
  `tasks.md`(추후 `/speckit-tasks`)에 기록하고 여기서 직접 수정하지 않는다. **PASS**.
- **세션 지식 기록**: 이 계획 실행 중 실제 오류나 복구가 필요한 사건은 없었다. 다만
  App↔Feature 경계와 관련해 `docs/architecture.md`(App은 UI에 의존할 수 없음)라는
  기존 문서 근거로 `AppEntryFeature`를 Feature 패키지에 두는 결정을 내렸으므로, 이는
  문서에 이미 명시된 근거의 적용이지 암묵적 판단 기준의 해석이 아니다. 기록 스킬
  대상 아님. **PASS**.
- **Git 실행 직렬화**: 계획 단계는 Git index나 작업 파일을 변경하지 않는 문서 작성만
  수행한다. **N/A (해당 없음)**.
- **책임 기반 네이밍**: 신규 타입 이름(`AppEntryFeature`, `OnboardingRouterFeature`,
  `OnboardingGuideFeature`, `CurationFeature`, `OnboardingExitFeature`)은 각자의 책임
  (진입 판단, Router 조합, 온보딩 안내, 큐레이션, Router 전환 판단)을 그대로 드러내며
  공통 접두어·접미어를 형식적으로 반복하지 않는다. `docs/conventions/naming.md`가 아직
  없어 Constitution 원칙 10을 직접 적용했다. **PASS**.
- **패키지 진행**: 아래 "패키지 진행 순서" 절 참고. Feature → App 순서로 진행하며
  (Composition은 변경 없음) 각 패키지는 구현·검증·보고·사용자 승인 후에만 다음
  패키지로 진행한다. **PASS**.

**위반 없음** — "복잡성 추적" 절은 작성하지 않는다. 새 Feature(`AppEntryFeature`,
`OnboardingExitFeature`)는 기존에 `AppRootFeature`가 이미 쓰고 있는 Child Feature
조합·delegate 패턴을 그대로 재사용하며, 새 아키텍처 예외나 4번째 프로젝트, 새 외부
의존성을 추가하지 않는다.

**설계 후 재점검**: `research.md`·`data-model.md`·`contracts/onboarding-router-flow.md`
작성을 마친 뒤 다시 점검했다. `AppEntryFeature`를 Feature 패키지에 둔 결정이
`App → Feature, Composition, Domain`(UI 제외) 의존성 표를 그대로 지키고, 화면 조합은
`AppRootFeature`의 기존 Child 조합 패턴을 재사용하며, 상태 공유는 FR-012대로
`@Shared`/`Binding`/`inout` 없이 `delegate`와 재조회로만 이루어진다. 패키지 진행
순서(Feature → App, Composition 변경 없음)도 설계 산출물과 일치한다. 새로 발견된 위반 없음 —
**PASS 유지**.

### 패키지 진행 순서

아키텍처 의존성 표(`docs/architecture.md` 3.1: `App → Feature, Composition, Domain`;
`Feature → Domain, UI`)를 근거로 순서를 정한다.

1. **Feature** — Onboarding 하위 화면 Feature 재구성과 신규 `AppEntryFeature`는 App이
   의존하는 대상이므로 먼저 구현한다. Feature는 App에 의존하지 않으므로 독립적으로
   구현·검증할 수 있다.
2. **App** — `AppRootFeature`/`AppRootView`/`GitItApp.swift`는 Feature의 새 Reducer
   타입을 조합·생성해야 하므로 Feature 완료 뒤에 진행한다.

**Composition 패키지는 이 기능에서 변경하지 않는다.** `research.md` 4절에서 확인했듯
`AppComposition`은 Feature 타입을 참조하지 않고 개별 UseCase만 평평하게 노출하며, 그
UseCase를 어떤 Feature initializer에 나눠 넣을지는 App 패키지(`GitItApp.swift`)의
조립 코드가 결정한다. Domain·Data·Infrastructure·UI 패키지도 이 기능이 변경하지
않으므로 건너뛴다(기존 UseCase protocol과 UI 컴포넌트를 그대로 재사용).

각 패키지 단계는 구현 → 테스트 실행 → 결과 보고 → 사용자 승인 완료 후에만 다음
패키지의 파일을 변경한다. `docs/conventions/tca.md` 문서 갱신(FR-011)은 특정 패키지
소스가 아니므로 Feature 단계 완료 시점에 함께 반영한다(설계가 코드로 확정된 직후가
문서와 실제 구현의 괴리를 가장 줄이는 시점).

## 프로젝트 구조

### 문서(이 기능)

```text
specs/017-onboarding-router-refactor/
├── plan.md              # 이 파일(/speckit-plan 산출물)
├── research.md          # 0단계 산출물(/speckit-plan)
├── data-model.md         # 1단계 산출물(/speckit-plan)
├── quickstart.md         # 1단계 산출물(/speckit-plan)
├── contracts/            # 1단계 산출물(/speckit-plan)
│   └── onboarding-router-flow.md
└── tasks.md              # 2단계 산출물(/speckit-tasks, /speckit-plan이 생성하지 않음)
```

### 소스 코드(저장소 루트)

```text
sources/Projects/Feature/
├── AppEntry/                              # 신규
│   ├── Reducers/
│   │   └── AppEntryFeature.swift          # 세션 복원 호출, 목적지 판단, delegate
│   ├── Screens/
│   │   └── AppEntryScreen.swift           # 기존 SplashScreen을 대체(UI 패키지 사용)
│   ├── Previews/
│   └── Tests/                             # sources/Projects/Feature/Tests/AppEntry/
└── Onboarding/
    ├── Reducers/
    │   ├── OnboardingRouterFeature.swift    # 기존 OnboardingFeature.swift 대체
    │   ├── OnboardingGuideFeature.swift     # 신규 — 튜토리얼·약관 동의·로그인
    │   ├── CurationFeature.swift            # 신규 — 포지션·경력 선택
    │   └── OnboardingExitFeature.swift      # 신규 — Router 전환 여부 판단
    ├── Screens/
    │   ├── OnboardingGuideScreen 하위(TutorialScreen, LegalAgreementScreen 등 이동)
    │   └── CurationScreen 하위(PositionSelectionScreen, CareerSelectionScreen 이동)
    ├── Previews/                            # 화면 Feature 재구성에 맞춰 갱신
    └── Tests/                               # 화면 Feature·Router·Exit Feature별 재구성

sources/Projects/App/GitIt/
├── GitItApp.swift                           # AppRootFeature(...) 생성 인자 재배선
├── Reducers/AppRootFeature.swift            # AppEntryFeature Child 추가, restoring 로직 위임
├── Screens/AppRootView.swift                # restoringContent를 AppEntryScreen으로 교체
└── Tests/GitIt/                             # AppRootFeature route 전이 테스트 갱신

docs/conventions/tca.md                      # Router 패턴 정식 섹션 추가(FR-011)
```

Composition 패키지(`sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`)는
이번 기능에서 변경하지 않는다(research.md 4절 참고).

**구조 결정**: 기존 `sources/Projects/Feature/Onboarding/`은 유지하되 내부를 화면
Feature 단위로 재구성하고, 세션 복원 책임은 같은 Feature 패키지 안의 새 형제 폴더
`sources/Projects/Feature/AppEntry/`로 분리한다. `AppEntry`를 App 패키지가 아니라
Feature 패키지에 두는 이유는 위 "요약"과 기술 맥락의 제약 조건에서 설명한 아키텍처
의존성 제약(App ∌ UI) 때문이다. App 패키지의 `AppRootFeature`/`AppRootView`는 두 Feature
(`AppEntryFeature`, `OnboardingRouterFeature`)를 Child로 조합하는 얇은 Route 소유자
역할만 유지한다.
