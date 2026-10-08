# 0단계 조사: Onboarding Router 리팩토링

## 1. 세션 복원 UI를 어느 패키지가 소유하는가

- **결정**: 세션 복원 Effect 호출, 재시도 UI, "온보딩 진입이 필요한가" 판단은 App
  패키지의 `AppRootFeature`가 아니라 **Feature 패키지에 새로 만드는 `AppEntryFeature`**가
  소유한다. `AppRootFeature`는 `AppEntryFeature`를 Child로 조합하고 그 `delegate`
  (목적지 결정 결과)만 받아 자신의 `route`를 전환한다.
- **근거**: `docs/architecture.md` 3.1 의존성 표에서 `App`의 허용 의존성은
  `Feature, Composition, Domain`이며 `UI`는 포함되지 않는다. 그런데 기존
  `SplashScreen.swift`(현재 `Feature/Onboarding/Screens/`)는 `DesignSystem`·
  `UIComponent`(UI 패키지)를 직접 사용하는 실제 화면이다. App 패키지 안에 이 화면을
  그대로 옮기면 App이 UI에 의존하게 되어 아키텍처 위반이 된다. Feature 패키지는 이미
  `UI`에 의존이 허용되어 있으므로(`Feature → Domain, UI`), 세션 복원 판단과 그 화면을
  Feature 패키지의 새 형제 Feature로 두면 위반 없이 명세의 요구(FR-001·FR-002: 세션
  복원 책임을 Onboarding에서 분리해 App Route가 목적지를 결정)를 만족할 수 있다. 이
  방식은 이미 `AppRootFeature`가 `onboarding`·`mainShell` Child의 `delegate`로 자신의
  `route`를 바꾸는 것과 동일한 패턴이라 새 메커니즘을 추가하지 않는다.
- **검토한 대안**:
  - **A. `AppRootFeature`가 직접 `restoreSession`을 호출하고, App 패키지 안에 UI
    패키지 없이 순수 SwiftUI(`ProgressView`, `Text`)로 재시도 화면을 새로 만든다.**
    기각 — 기존 `SplashScreen`이 이미 `ScreenContainer`·`StyledText`·`ActionButton`
    같은 DesignSystem/UIComponent를 사용해 완성돼 있는데, 이를 두고 App 패키지에 별도
    디자인 시스템 미적용 화면을 새로 만드는 것은 중복 구현이며 FR-010(사용자에게
    보이는 화면 동작 무변경)과도 어긋날 위험이 있다.
  - **B. 아키텍처 의존성 표를 바꿔 App이 UI에 의존하도록 허용한다.** 기각 —
    아키텍처 문서 변경은 이 기능의 범위(Constitution 원칙 4: 아키텍처 문서는 구조
    결정이 바뀔 때만 갱신)를 벗어나는 더 큰 결정이며, 이번 리팩토링 목표(Onboarding
    책임 분리)와 무관한 전역 정책 변경이라 최소 변경 원칙에도 맞지 않는다.
  - **C. `SplashScreen`을 UI 패키지로 옮겨 App이 UI 대신 그 컴포넌트를 직접 참조한다.**
    기각 — UI 패키지는 "여러 Feature가 공유하는 디자인 시스템과 재사용 가능한 UI
    구성요소"(`docs/architecture.md`)를 위한 곳이지, 특정 화면 전체(세션 확인 문구,
    재시도 버튼 배치 등 Presentation 흐름)를 담는 곳이 아니다. Feature 패키지 규칙도
    "화면 파일 안에 별도 View 타입을 정의해서는 안 된다"·"재사용 UI는 UI가 제공하는
    공개 API로 사용한다"고 명시해, 화면 자체는 Feature가 소유해야 한다.

## 2. Onboarding Router의 화면 조합 메커니즘

- **결정**: `OnboardingRouterFeature.State`는 온보딩 안내(`OnboardingGuideFeature.State`)와
  큐레이션(`CurationFeature.State`) 두 Child State를 **항상 함께 보유**하고, 어느 쪽이
  현재 활성 상태인지는 별도 `activeScreen` enum(연관값으로 각 Child의 세부 화면을
  포함하는 계층형 값, FR-006)으로 표현한다. Router의 `body`는 두 Child를 항상
  `Scope`로 조합하고, `Reduce`에서 `activeScreen` 전환과 이동 이벤트 기록을 처리한다.
- **근거**: 이 프로젝트에 이미 있는 `AppRootFeature`가 정확히 같은 패턴(`onboarding`·
  `mainShell` Child State를 항상 갖고 `route`로 활성 화면만 표시)을 쓰고 있어 검증된
  선례다. TCA 컨벤션 문서(`docs/conventions/tca.md` 7.1)의 `Destination`/`@Presents`는
  "현재 Feature 수명 안에서 완결되는 sheet·alert·내부 화면"을 위한 것으로, presented/
  dismissed 성격의 화면(모달 등)에 적합하다. Onboarding Router의 화면 전환은 sheet가
  아니라 순차적인 phase 전환(원본 `Phase` enum과 동일한 성격)이므로 `@Presents`보다
  "항상 존재하는 Child + 활성 enum" 쪽이 기존 코드베이스 관례와 더 일치한다.
- **검토한 대안**:
  - **`@Presents` + `Destination` enum으로 두 화면을 presented/dismissed로 표현.**
    기각 — 온보딩 안내 → 큐레이션 전환은 명시적으로 dismiss되는 관계가 아니라
    순차적으로 이어지는 여정이며, "완료" case를 두지 않고 별도 `OnboardingExitFeature`가
    전환 여부만 판단하는 명세(FR-005)와 결합했을 때 `@Presents`의 존재/부재 의미론이
    오히려 불필요한 복잡성을 만든다.
  - **단일 Reducer에 원본처럼 `Phase` enum 하나로 모든 화면을 표현(현행 유지).**
    기각 — 명세 FR-003·FR-004가 요구하는 "다른 화면 Feature의 State·Action을
    import하지 않고 독립 컴파일·테스트"를 만족할 수 없다.

## 3. Router의 "전환 여부" 판단을 별도 Feature로 둘 때의 구현 형태

- **결정**: `OnboardingExitFeature`는 자체 화면이 없는 얇은 Feature로, `State`는 관찰
  대상 조건(예: 큐레이션 제출 성공 여부)의 최소 정본만 갖고 `Action`은 그 조건 변화를
  받는 `input`과 판단 결과를 알리는 `delegate`만 갖는다. Router는 `CurationFeature`의
  `delegate(.curationSucceeded)`를 받으면 `OnboardingExitFeature`에 `input`으로 전달하고,
  `OnboardingExitFeature`의 `delegate(.shouldExit)`를 받아 자신의 `delegate
  (.mainShellRequested)`를 상위로 올린다.
- **근거**: TCA 컨벤션 문서(5.1)의 Action 분류표에 "부모의 외부 조정 신호가 실제로
  필요할 때만 `input`을 추가한다"는 규칙이 있고, 이 Feature는 정확히 그 경우(Router가
  하위 조건 변화를 전달해야 판단이 가능)에 해당한다. 이 형태는 명세가 요구한 "완료
  여부가 아니라 Router 전환 여부를 판단하는 책임"(FR-005, 명확화 세션)을 코드 구조로
  그대로 드러낸다.
- **검토한 대안**:
  - **Router의 `Reduce` 안에 조건문으로 직접 판단(별도 Feature 없이).** 기각 —
    명세가 명시적으로 "별도 하위 Feature가 판단해야 한다"고 요구했고(사용자와의 논의로
    확정), 향후 전환 조건이 늘어날 때(예: 다른 이탈 조건) 이 판단 로직이 Router의
    화면 조합 책임과 뒤섞이는 것을 막는다.

## 4. `AppComposition`(Composition 패키지) 변경 필요 여부

- **결정**: `sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`는
  **변경하지 않는다**. 이 기능이 실제로 갱신해야 하는 배선 코드는 Composition이 아니라
  App 패키지의 `sources/Projects/App/GitIt/GitItApp.swift`(`AppRootFeature(...)` 생성
  호출부)와 `AppRootFeature.swift`(내부 `Scope` 구성)다.
- **근거**: `AppComposition.swift`를 직접 읽어 확인한 결과, 이 타입은 Feature 타입을
  전혀 참조하지 않고 `restoreSession`·`fetchMemberProfile`·`signIn`·`signOut`·
  `completeCuration`·`policyConsent` 등 개별 UseCase 프로퍼티만 평평하게(flat) 노출한다.
  실제로 `AppRootFeature(...)`를 특정 UseCase 인자 목록으로 생성하는 코드는
  `GitItApp.swift`에 있다. 즉 "어떤 UseCase를 어떤 Feature initializer에 나눠 넣을지"는
  전적으로 App 패키지의 조립 책임이며, Composition은 이미 필요한 UseCase를 전부 제공하고
  있어 추가·변경할 것이 없다. 이 발견은 계획 초안에서 "Composition 배선 갱신"을
  가정했던 것을 수정한 것이다 — 실제 코드를 읽지 않고 세웠던 가정이 실제 구조와 달랐다.
- **검토한 대안**: 검토할 실질적 대안 없음 — 파일을 직접 읽어 확인한 사실 관계 정정이다.
