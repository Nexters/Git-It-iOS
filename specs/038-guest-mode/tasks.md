---

description: "비로그인(게스트) 모드 구현 작업 목록"
---

# 작업 목록: 비로그인(게스트) 모드

**입력**: `/specs/038-guest-mode/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md),
[contracts/feature-actions.md](./contracts/feature-actions.md), [contracts/ui-tab-shell.md](./contracts/ui-tab-shell.md),
[quickstart.md](./quickstart.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를 snapshot한다. 별도 기준선 commit은
사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만 선택한다.

**테스트**: 명세 SC-002·SC-005와 [quickstart.md](./quickstart.md)의 자동 검증 목록이 Reducer 테스트를 요구하므로 테스트
작업을 포함한다. 각 단위에서 테스트를 구현보다 먼저 작성한다.

**구성**: 실행 단위를 최상위 구조로 사용하고 변경 시나리오는 각 단위 안에서 추적한다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[S#]**: 명세의 변경 시나리오 1–4
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 검증. `make tuist`의 파생 workspace·project·심볼릭
  링크·cache 갱신은 허용하되 실행 전후 `git status --porcelain`을 비교하고 추적 파일 변경이 생기면 완료로 처리하지 않는다.
- 모든 경로는 저장소 루트 기준이다. 새 Swift 파일은 파일당 타입 1개, 주석은 `// MARK:`만 쓰며, 테스트 함수 이름은 한국어
  동작 문장, 테스트 프레임워크는 Swift Testing이다.
- 선언 모양은 [contracts/feature-actions.md](./contracts/feature-actions.md)·[contracts/ui-tab-shell.md](./contracts/ui-tab-shell.md),
  상태 전환은 [data-model.md](./data-model.md), 문구와 배치는 [research.md R7](./research.md#r7-figma-근거와-문구)이 정본이다.
  작업 설명은 그 정본을 따르는 대상 파일만 지정한다.
- 프로젝트 `build`·`compile`·`test` 실행기는 사용자 지시에 따라 에이전트가 실행하지 않는다. 각 단위 검증은 정적 검사로
  수행하고, 실행기 검증은 사용자 확인 항목으로 보고한다. 현재 pre-commit의 `build`·`compile` 단계도 비활성화되어 있으므로
  U1~U5 커밋은 컴파일 근거 없이 만들어진다. 이는 Constitution 원칙 3의 예외이며 T039에서 PR 기록 내용을 준비한다.

## 실행 단위 순서와 근거

아키텍처 문서의 의존 방향(App → Feature → UI)을 따른다. 모든 단위는 단일 패키지이며, 새 공개 API에 기본값을 두어
상위 패키지가 다음 단위 전까지 그대로 컴파일되므로 integration unit이 필요 없다.

1. **U1 UI** — `TabShell`의 `isEnabled` 입력. U4의 MainShellRouter 화면이 사용한다.
2. **U2 Feature: 온보딩** — 튜토리얼 비로그인 진입, 직군·연차 중단 목적지. U5의 App이 사용한다.
3. **U3 Feature: 홈** — `MainShellAccess`와 홈 비로그인 표시. U4가 Home의 새 입력·delegate를 사용하므로 U4보다 먼저 둔다.
   U2와는 서로 의존하지 않으며, 파일이 겹치지 않는다.
4. **U4 Feature: 메인 화면** — `GuestSignInFeature`, 탭 제한, 마이 탭 로그인 화면, 로그인 후 접근 전환.
5. **U5 App** — 비로그인 route 연결과 App 가드.
6. **전체 완료 검증** — `[no-write]`만.

---

## U1: TabShell 비활성 탭 (UI)

**목표**: 호출자가 탭별 사용 가능 여부를 지정하면 비활성 탭을 시스템 비활성 상태로 표시한다.

**소유 경로**: `sources/Projects/UI/Component/Scaffolds/TabShell/TabShell.swift`,
`sources/Projects/UI/Tests/Component/Unit/Scaffolds/TabShellContractTests.swift`

**관련 변경 시나리오**: S3

**독립 검증**: 기존 `TabShell(selected:content:)` 호출이 수정 없이 컴파일되고, 계약 테스트가 기본 활성 규칙을 확인한다.

### 테스트

- [X] T001 [S3] `sources/Projects/UI/Tests/Component/Unit/Scaffolds/TabShellContractTests.swift`를 만들고 `@testable import UIComponent`로 `TabShell`의 `internal let isEnabled`를 읽어, `isEnabled`를 지정하지 않은 `TabShell`은 `TabShellPreviewItem`의 모든 항목을 활성으로 판정하고, 지정한 판정 함수는 항목별 결과를 그대로 따른다는 계약을 검증한다(기존 `ScreenContainerContractTests.swift`의 계약 테스트 형식을 따른다)

### 구현

- [X] T002 [S3] `sources/Projects/UI/Component/Scaffolds/TabShell/TabShell.swift`에 `isEnabled: @escaping (Item) -> Bool = { _ in true }` 입력을 `selected`와 `content` 사이에 추가하고 `internal let isEnabled`로 저장한다. `TabView` 내용을 `ForEach(Item.allCases)` + `Tab(value:)` 구성으로 바꿔 `TabContent.disabled(!isEnabled(item))`를 적용한다. 기존 아이콘·제목·tint·`unselectedItemTintColor` 설정은 유지한다. 다음 중 하나라도 해당하면 `Tab(value:)` 전환을 하지 않고 기존 `.tabItem` 구성을 유지한 채 research R5의 대체안(비활성 항목 아이콘·제목 `grey400`)으로 구현하고 그 사실과 이유를 단위 보고에 남긴다: (a) `TabContent.disabled(_:)`가 컴파일되지 않는다, (b) `Tab` label 안에서 기존 아이콘 아래 `padding(.bottom, LayoutToken.tightSpacing)` 또는 `Text.designSystemStyled(_:style: .tabItem)` 제목 스타일을 그대로 적용할 수 없다. 같은 파일에 한 항목을 비활성화한 `#Preview("Tab Shell - disabled item")`를 추가한다

### 패키지 검증

- [X] T003 [no-write] `rg -n "TabShell\(" sources/Projects`로 기존 호출부가 새 입력 없이도 유효한 형태인지 확인하고, 사용자에게 `UI` scheme `compile`·`test` 실행을 확인 항목으로 보고한다

**진행 점검**: T001~T003의 변경 파일과 검증 결과를 보고하고 U2로 진행한다.

---

## U2: 튜토리얼 비로그인 진입과 직군·연차 중단 목적지 (Feature)

**목표**: 튜토리얼 마지막 면에서 비로그인 진입을 요청하고, 호출자가 지정하면 직군·연차 중단 시 튜토리얼 대신 호출자에게
돌려준다.

**소유 경로**: `sources/Projects/Feature/Onboarding/Tutorial/TutorialFeature.swift`,
`sources/Projects/Feature/Onboarding/Tutorial/TutorialScreen.swift`,
`sources/Projects/Feature/Onboarding/Tutorial/SubViews/TutorialScreen+SignInSection.swift`,
`sources/Projects/Feature/Onboarding/Tutorial/Previews/TutorialScreenPreviews.swift`,
`sources/Projects/Feature/Onboarding/Router/OnboardingRouterFeature.swift`,
`sources/Projects/Feature/Onboarding/Router/OnboardingRouterFeature+CurationExit.swift`,
`sources/Projects/Feature/Tests/Onboarding/Tutorial/TutorialFeatureTests.swift`,
`sources/Projects/Feature/Tests/Onboarding/Router/OnboardingRouterFeatureTests.swift`

**관련 변경 시나리오**: S1, S4

**독립 검증**: Tutorial·OnboardingRouter 테스트에서 비로그인 진입 delegate와 중단 목적지 분기가 검증되고, 기존 온보딩 테스트가
그대로 통과한다.

### 테스트

- [X] T004 [P] [S1] `sources/Projects/Feature/Tests/Onboarding/Tutorial/TutorialFeatureTests.swift`에 테스트를 추가한다: 비로그인 진입을 누르면 `delegate(.guestAccessRequested)`를 보낸다, 로그인 진행 중(`authentication == .signingIn`)에는 비로그인 진입을 무시한다
- [X] T005 [P] [S1] [S4] `sources/Projects/Feature/Tests/Onboarding/Router/OnboardingRouterFeatureTests.swift`에 테스트를 추가한다: 튜토리얼의 비로그인 진입 요청을 `delegate(.guestAccessRequested)`로 전달하고 약관 화면으로 이동하지 않는다, `curationExit`가 `.returnToCaller`이면 직군 선택 종료 시 튜토리얼로 가지 않고 `delegate(.curationAbandoned)`를 보낸다, 기본값(`.returnToTutorial`)이면 기존과 같이 튜토리얼 마지막 면으로 돌아간다

### 구현

- [X] T006 [S4] `sources/Projects/Feature/Onboarding/Router/OnboardingRouterFeature+CurationExit.swift`를 만들어 `extension OnboardingRouterFeature { public enum CurationExit: Equatable, Sendable { case returnToTutorial, returnToCaller } }`를 선언한다([data-model §2](./data-model.md#2-onboardingrouterfeaturecurationexit-feature-새-공개-enum))
- [X] T007 [S1] `sources/Projects/Feature/Onboarding/Tutorial/TutorialFeature.swift`에 `Action.View.guestAccessTapped`와 `Action.Delegate.guestAccessRequested`를 추가하고, `authentication != .signingIn`일 때만 delegate를 보내도록 구현한다
- [X] T008 [S1] `sources/Projects/Feature/Onboarding/Router/OnboardingRouterFeature.swift`에 `State.init(startingAt:bundleVersion:curationExit: CurationExit = .returnToTutorial)`와 `public let curationExit`를 추가하고, `Delegate`에 `guestAccessRequested`·`curationAbandoned`를 추가한다. `tutorial(.delegate(.guestAccessRequested))`를 전달하고, `positionSelection(.delegate(.exitRequested))`는 `curationExit == .returnToCaller`일 때 직군·연차 상태만 초기화한 뒤 `delegate(.curationAbandoned)`를 보낸다
- [X] T009 [S1] `sources/Projects/Feature/Onboarding/Tutorial/SubViews/TutorialScreen+SignInSection.swift`에 `onGuestAccess: () -> Void` 입력을 추가하고 `AppleSignInButton` 아래에 `ActionButton` Text 스타일 `로그인 없이 둘러보기` 버튼을 `isHintVisible`일 때만 표시·접근 가능하게 둔다(마지막 면 외에는 `opacity(0)`·`accessibilityHidden`·`disabled`, 기존 힌트 문구와 같은 방식). 새 간격은 `LayoutToken`만 사용한다
- [X] T010 [S1] `sources/Projects/Feature/Onboarding/Tutorial/TutorialScreen.swift`의 `SignInSection` 생성에 `onGuestAccess: { send(.guestAccessTapped) }`를 연결한다
- [X] T011 [P] [S1] `sources/Projects/Feature/Onboarding/Tutorial/Previews/TutorialScreenPreviews.swift`의 마지막 면 프리뷰가 비로그인 진입 버튼을 보여 주는지 확인하고, 없으면 마지막 면 프리뷰를 추가한다

### 패키지 검증

- [X] T012 [no-write] `rg -n "SignInSection\(|OnboardingRouterFeature.State\(" sources/Projects`로 변경한 생성자 호출부가 모두 새 인자 또는 기본값과 맞는지 확인하고, 사용자에게 `Feature` scheme의 Onboarding 테스트 실행을 확인 항목으로 보고한다

**진행 점검**: T004~T012의 변경 파일과 검증 결과를 보고하고 U3으로 진행한다.

---

## U3: 홈 비로그인 표시 (Feature)

**목표**: 홈이 접근 수준에 따라 계정 영역을 로그인 안내로 대체하고 계정 요청을 만들지 않는다.

**소유 경로**: `sources/Projects/Feature/MainShell/Router/MainShellAccess.swift`,
`sources/Projects/Feature/Home/HomeFeature.swift`, `sources/Projects/Feature/Home/HomeScreen.swift`,
`sources/Projects/Feature/Home/SubViews/HomeScreen+SignInSectionView.swift`,
`sources/Projects/Feature/Home/SubViews/HomeScreen+ProjectSection.swift`,
`sources/Projects/Feature/Home/ViewModels/HomeProjectSectionState.swift`,
`sources/Projects/Feature/Home/Previews/HomeScreenPreviews.swift`,
`sources/Projects/Feature/Tests/Home/Home/HomeFeatureGuestAccessTests.swift`,
`sources/Projects/Feature/Tests/Home/Home/HomeFeatureNavigationTests.swift`,
`sources/Projects/Feature/Tests/Home/Home/HomeFeatureGenerationProgressTests.swift`,
`sources/Projects/Feature/Tests/Home/Home/ViewModels/HomeProjectSectionStateTests.swift`

**관련 변경 시나리오**: S2, S4

**독립 검증**: `HomeFeatureGuestAccessTests`가 비로그인 시 요청 0건·알럿·delegate를, `HomeProjectSectionStateTests`가
`signInRequired` 판정을, 기존 Home 테스트가 로그인 사용자 동작
무변경을 확인한다.

### 테스트

- [X] T013 [S2] [S4] `sources/Projects/Feature/Tests/Home/Home/HomeFeatureGuestAccessTests.swift`를 만들고 `sources/Projects/Feature/Tests/Home/TestDoubles/`의 기존 대역으로 다음을 검증한다: 비로그인 `task`는 프로필·프로젝트 요청을 보내지 않는다, 비로그인 재조회 입력은 요청을 보내지 않는다, 비로그인에서 등록을 누르면 로그인 필요 알럿을 띄우고 등록 delegate를 보내지 않는다, 알럿의 로그인을 누르면 알럿을 닫고 `delegate(.signInRequested)`를 보낸다, 알럿 닫기는 알럿만 닫는다, 로그인 섹션의 로그인은 `delegate(.signInRequested)`를 보낸다, `accessChanged(.member)`를 받으면 프로필과 프로젝트 적재를 시작한다, 비로그인에서 전체 보기를 누르면 `delegate(.allProjectsRequested)`를 보내지 않는다
- [X] T014 [S2] `sources/Projects/Feature/Tests/Home/Home/HomeFeatureNavigationTests.swift`의 `전체 보기와 카드 본문은 실제 destination 없이 intent만 전달한다`와 `sources/Projects/Feature/Tests/Home/Home/HomeFeatureGenerationProgressTests.swift`의 `진행 중에도 카드 본문과 전체 보기 동작은 달라지지 않는다`에서 `view(.showAllProjectsTapped)` 뒤에 `delegate(.allProjectsRequested)` 수신을 단언하도록 고친다([contracts HomeFeature](./contracts/feature-actions.md#homefeature))
- [X] T015 [S2] `sources/Projects/Feature/Tests/Home/Home/ViewModels/HomeProjectSectionStateTests.swift`의 기존 `HomeProjectSectionState(_:)` 호출을 모두 `HomeProjectSectionState(_:access: .member)`로 바꾸고, `access: .guest`이면 `projectLoad`(`.idle`·`.loading`·`.loaded`·`.failed`)와 무관하게 `signInRequired`를 반환한다는 테스트를 추가한다

### 구현

- [X] T016 [S2] `sources/Projects/Feature/MainShell/Router/MainShellAccess.swift`를 만들어 `public enum MainShellAccess: Equatable, Sendable { case member, guest }`를 선언한다([data-model §1](./data-model.md#1-mainshellaccess-feature-새-공개-enum))
- [X] T017 [S2] [S4] `sources/Projects/Feature/Home/HomeFeature.swift`에 `State.access`(기본 `.member`)·`isSignInRequiredAlertPresented`, `View.signInTapped`·`signInRequiredAlertSignInTapped`·`signInRequiredAlertDismissed`, `Input.accessChanged(MainShellAccess)`, `Delegate.signInRequested`·`allProjectsRequested`를 추가하고, `view(.showAllProjectsTapped)`가 `access == .member`일 때 `delegate(.allProjectsRequested)`를 보내도록 바꾸고, [contracts/feature-actions.md HomeFeature](./contracts/feature-actions.md#homefeature)의 비로그인 동작 표대로 기존 case에 `access == .guest` 가드를 넣는다. `accessChanged(.member)`는 `view(.task)`와 같은 적재 Effect를 시작한다
- [X] T018 [S2] `sources/Projects/Feature/Home/ViewModels/HomeProjectSectionState.swift`에 `signInRequired` case를 추가하고 `init(_ projectLoad:access:)`가 `access == .guest`이면 `signInRequired`를 반환하도록 바꾼다
- [X] T019 [S2] `sources/Projects/Feature/Home/SubViews/HomeScreen+SignInSectionView.swift`를 만들어 `extension HomeScreen { struct SignInSectionView: View }`로 `ProfileHeaderView` 실패 상태와 같은 배치(제목 `StyledText.subtitle3`·캡션 `StyledText.caption1` grey400 + `ActionButton.secondary(size: .small)`, 같은 `minHeight`)에 R7 문구 `로그인이 필요해요`·`로그인하고 나만의 학습을 시작해 보세요.`·`로그인`을 표시하고 `onSignIn` 콜백을 받는다
- [X] T020 [S2] `sources/Projects/Feature/Home/SubViews/HomeScreen+ProjectSection.swift`에 `isShowAllEnabled: Bool` 입력을 추가해 전체 보기 버튼에 `.disabled(!isShowAllEnabled)`와 비활성 시 `grey400` 색을 적용하고, `signInRequired` case를 `emptyProjects` 배치로 `로그인하면 학습 중인 레포지토리를 볼 수 있어요.`(`StyledText.body2`, `purple200`)를 표시한다
- [X] T021 [S2] `sources/Projects/Feature/Home/HomeScreen.swift`에서 `store.access == .guest`이면 `ProfileHeaderView` 대신 `SignInSectionView(onSignIn: { send(.signInTapped) })`를 표시하고, `ProjectSection`에 `HomeProjectSectionState(store.projectLoad, access: store.access)`와 `isShowAllEnabled: store.access == .member`를 전달하며, `isSignInRequiredAlertPresented` 바인딩으로 R7의 시스템 알럿(`로그인이 필요해요` / `프로젝트를 만들려면 로그인해 주세요.` / `로그인`, `닫기`)을 붙인다
- [X] T022 [P] [S2] `sources/Projects/Feature/Home/Previews/HomeScreenPreviews.swift`에 `access: .guest` 상태를 직접 구성한 `#Preview("Home - guest")`를 추가한다

### 패키지 검증

- [X] T023 [no-write] `rg -n "HomeProjectSectionState\(|ProjectSection\(" sources/Projects`로 변경한 생성자 호출부가 모두 새 인자를 전달하는지 확인하고, 사용자에게 `Feature` scheme의 Home 테스트 실행을 확인 항목으로 보고한다

**진행 점검**: T013~T023의 변경 파일과 검증 결과를 보고하고 U4로 진행한다.

---

## U4: 비로그인 로그인 흐름과 탭 제한 (Feature)

**목표**: 메인 화면이 접근 수준을 소유해 탭을 제한하고 마이 탭에 로그인 화면을 표시하며, 메인 화면 위에서 약관 동의와
Apple 로그인을 진행한다.

**소유 경로**: `sources/Projects/Feature/MainShell/Router/GuestSignInFeature.swift`,
`sources/Projects/Feature/MainShell/Router/GuestSignInFeature+Phase.swift`,
`sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift`,
`sources/Projects/Feature/MainShell/Router/MainShellRouter.swift`,
`sources/Projects/Feature/MainShell/Router/SubViews/MainShellRouter+SignInPromptView.swift`,
`sources/Projects/Feature/Tests/MainShell/Router/GuestSignInFeatureTests.swift`,
`sources/Projects/Feature/Tests/MainShell/TestDoubles/MainShellAccountUseCaseStub.swift`,
`sources/Projects/Feature/Tests/MainShell/Router/MainShellRouterFeatureGuestAccessTests.swift`,
`sources/Projects/Feature/Tests/MainShell/Router/MainShellRouterFeatureTests.swift`

**관련 변경 시나리오**: S2, S3, S4

**독립 검증**: `GuestSignInFeatureTests`가 [data-model §3](./data-model.md#3-guestsigninfeaturestate-feature-새-reducer)의 모든 전환을,
`MainShellRouterFeatureGuestAccessTests`가 탭 제한·요청 차단·로그인 후 탭 유지를 검증하고, 기존 `MainShellRouterFeatureTests`가
그대로 통과한다.

### 테스트

- [X] T024 [S3] [S4] `sources/Projects/Feature/Tests/MainShell/Router/MainShellRouterFeatureTests.swift`의 private `MainShellAccountUseCaseStub`을 `sources/Projects/Feature/Tests/MainShell/TestDoubles/MainShellAccountUseCaseStub.swift`로 옮기고(기존 테스트의 기본 동작은 그대로 유지), 설정한 `SignInResult`와 약관 충족 여부를 돌려주고 로그인 호출 수를 기록하도록 확장한다. 동시 접근되는 호출 기록은 actor 등 데이터 경쟁을 막는 소유자에 두고 snapshot으로 검증한다. 새 `AccountUseCase` 구현 타입은 추가하지 않는다([research R9](./research.md#r9-mainshell-테스트의-accountusecase-대역) — 기존 부채 유지 예외)
- [X] T025 [P] [S4] `sources/Projects/Feature/Tests/MainShell/Router/GuestSignInFeatureTests.swift`를 만들고 T024의 `MainShellAccountUseCaseStub` 메서드를 생성자 클로저로 넘겨 다음을 검증한다: 약관 동의가 충족되면 바로 Apple 로그인을 시작한다, 미충족이면 약관 동의 단계로 가고 동의 완료 후 로그인한다, 약관 취소는 로그인 없이 `idle`로 돌아간다, 로그인 성공은 `delegate(.signedIn(needsCuration:))`를 보낸다, 로그인 취소는 알럿 없이 `idle`로 돌아간다, 재시도 가능한 실패는 실패 알럿 상태가 되고 닫으면 `idle`이다, 진행 중 `start` 재입력은 로그인 요청을 한 번만 보낸다
- [X] T026 [P] [S3] [S4] `sources/Projects/Feature/Tests/MainShell/Router/MainShellRouterFeatureGuestAccessTests.swift`를 만들고 T024 대역과 `sources/Projects/Feature/Tests/Home/TestDoubles/`의 프로젝트·사용자 대역으로 다음을 검증한다: 비로그인이면 프로젝트·저장 탭 선택을 무시하고 재조회를 보내지 않는다, 비로그인에서 홈·마이 탭 선택은 반영되지만 재조회를 보내지 않는다, 비로그인에서 재조회 입력을 무시한다, 홈의 로그인 요청과 마이 탭 로그인은 로그인 흐름을 시작한다, 로그인 성공은 `delegate(.signInSucceeded(needsCuration:))`를 보낸다, `memberAccessGranted`는 선택 탭을 유지한 채 접근 수준을 `member`로 바꾸고 홈 적재와 재조회를 시작한다
- [X] T027 [S2] `sources/Projects/Feature/Tests/MainShell/Router/MainShellRouterFeatureTests.swift`의 `Home 전체 보기는 프로젝트 탭을 선택한다`가 `home(.view(.showAllProjectsTapped))` 대신 `home(.delegate(.allProjectsRequested))`를 보내 프로젝트 탭 선택을 검증하도록 고친다

### 구현

- [X] T028 [S4] `sources/Projects/Feature/MainShell/Router/GuestSignInFeature+Phase.swift`를 만들어 `extension GuestSignInFeature { public enum Phase: Equatable, Sendable { case idle, checkingConsent, agreeingToPolicies, signingIn, failed } }`를 선언한다
- [X] T029 [S4] `sources/Projects/Feature/MainShell/Router/GuestSignInFeature.swift`를 만들어 [contracts/feature-actions.md GuestSignInFeature](./contracts/feature-actions.md#guestsigninfeature-새-reducer)의 생성자 의존성·Action과 [data-model §3](./data-model.md#3-guestsigninfeaturestate-feature-새-reducer)의 상태 전환을 구현한다. 약관 단계는 항상 보유하는 `legalAgreement`에 `Scope(state: \.legalAgreement, action: \.legalAgreement) { LegalAgreementFeature(...) }`로 기존 Reducer를 재사용하고, 표시 여부는 `phase`로만 판단한다([research R3](./research.md#r3-비로그인-상태의-로그인-흐름그-자리에서-apple-로그인) 예외). 동의 확인은 온보딩 라우터와 같은 순서로 한다: `start`에서 `phase = .checkingConsent`로 두고 `legalAgreement(.input(.load))`를 보낸다(문서 목록과 `isStoredConsentValid`를 채움. 이미 문서가 있으면 기존 값 사용), `legalAgreement(.effect(.statusLoaded))` 이후 또는 문서가 이미 있으면 즉시 `legalAgreement.isStoredConsentValid`로 분기한다. 미충족이면 `legalAgreement(.input(.prepare))`로 선택을 초기화한 뒤 `phase = .agreeingToPolicies`, 충족이면 로그인을 시작한다. `legalAgreement(.delegate(.consentCompleted))`는 로그인 시작, `.cancelled`는 `idle`이다. 약관 판정은 [contracts/feature-actions.md GuestSignInFeature](./contracts/feature-actions.md#guestsigninfeature-새-reducer)대로 `legalAgreement`의 기존 Action으로 하며 별도 `policyConsentStatus` 호출 Effect를 만들지 않는다. 로그인 Effect는 `requestID`와 `cancellable(id:cancelInFlight:)`로 최신 결과만 반영한다
- [X] T030 [S3] [S4] `sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift`에 `State.init(access: MainShellAccess = .member)`(`home.access`도 같은 값), `State.access`, `State.guestSignIn`, `View.signInTapped`, `Input.memberAccessGranted`, `Delegate.signInSucceeded(needsCuration:)`, `guestSignIn` child Action과 `Scope`(주입된 `account`의 `signIn`·`policyConsentStatus`·`consent`만 전달)를 추가하고 [contracts/feature-actions.md MainShellRouterFeature](./contracts/feature-actions.md#mainshellrouterfeature)의 비로그인 동작 표대로 기존 case에 가드를 넣고, `home(.view(.showAllProjectsTapped))` 처리를 `home(.delegate(.allProjectsRequested))` 처리로 교체한다(동작은 그대로). 로그아웃·계정 삭제의 `state = MainShellRouterFeature.State()` 초기화는 그대로 둔다
- [X] T031 [S3] `sources/Projects/Feature/MainShell/Router/SubViews/MainShellRouter+SignInPromptView.swift`를 만들어 `extension MainShellRouter { struct SignInPromptView: View }`로 `ScreenContainer` 안에 R7 문구(`StyledText.subtitle1` `로그인이 필요해요`, `StyledText.body2` `로그인하면 학습 현황과 설정을 확인할 수 있어요.`)와 `AppleSignInButton(action: onSignIn)`을 `LayoutToken` 간격으로 배치한다
- [X] T032 [S3] [S4] `sources/Projects/Feature/MainShell/Router/MainShellRouter.swift`에서 `TabShell`에 `isEnabled: { store.access == .member || ($0 != .projects && $0 != .saved) }`를 전달하고, `store.access == .guest`이면 마이 탭은 `SignInPromptView(onSignIn: { send(.signInTapped) })`를 그리고 프로젝트·저장 탭 자리에는 `ProjectListScreen`·`SavedScreen` 대신 Store·`task`가 없는 빈 배경(`ScreenContainer { EmptyView() }`)을 그려 계정 요청 Effect가 구조적으로 시작되지 않게 한다(SC-002). 온보딩 라우터와 같은 방식으로 `ModalOverlay` + `LegalAgreementScreen` + `WebSheet`를 `guestSignIn` 상태에 연결하고, R7의 로그인 실패 알럿(`로그인하지 못했어요` / `잠시 후 다시 시도해 주세요.` / `확인`)을 `guestSignIn.phase == .failed` 바인딩으로 붙인다

### 패키지 검증

- [X] T033 [no-write] `rg -n "MainShellRouterFeature.State\(|TabShell\(" sources/Projects`로 생성자 호출부를 확인하고 `rg -n "@Dependency" sources/Projects/Feature/MainShell`이 결과 없음임을 확인한 뒤, 사용자에게 `Feature` scheme `compile`·`test` 실행을 확인 항목으로 보고한다

**진행 점검**: T024~T033의 변경 파일과 검증 결과를 보고하고 U5로 진행한다.

---

## U5: App 비로그인 route 연결 (App)

**목표**: App이 비로그인 진입·로그인 성공·직군 중단을 route로 연결하고, 비로그인 상태의 로그인 검증·기기 등록을 막는다.

**소유 경로**: `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`,
`sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureGuestAccessTests.swift`

**관련 변경 시나리오**: S1, S3, S4

**독립 검증**: `AppRootFeatureGuestAccessTests`가 비로그인 route 전환과 가드를, 기존 `AppRootFeatureTests`가 로그인 사용자
동작 무변경(FR-015)을 확인한다.

### 테스트

- [X] T034 [S1] [S4] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureGuestAccessTests.swift`를 만들고 `sources/Projects/App/Tests/GitIt/TestDoubles/AppRootTestSupport.swift`의 `makeAppRootStore`와 기존 대역으로 다음을 검증한다: 온보딩의 비로그인 진입 요청은 비로그인 메인 화면으로 이동하고 기기 등록을 하지 않는다, 비로그인에서 앱이 다시 활성화되면 로그인 검증·재조회·기기 등록을 하지 않고 메인 화면을 유지한다, 비로그인에서 재인증 필요 결과를 받아도 온보딩으로 돌아가지 않는다, 비로그인에서 기기 토큰 갱신을 무시한다, 추가 입력이 필요 없는 로그인 성공은 선택 탭을 유지한 채 로그인 사용자 메인 화면으로 바꾸고 기기를 등록한다, 직군·연차가 필요한 로그인 성공은 호출자 복귀 모드의 직군 선택 온보딩으로 이동하고 메인 화면 상태를 유지한다, 직군 선택을 중단하면 비로그인 메인 화면으로 돌아간다, 직군·연차 완료 후 메인 화면은 로그인 사용자로 바뀌고 선택 탭을 유지한다, 로그인 사용자의 로그아웃은 기존대로 튜토리얼 첫 면으로 이동한다
- [X] T035 [S1] [S4] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`에 [contracts/feature-actions.md AppRootFeature](./contracts/feature-actions.md#approotfeature-app-내부) 표의 처리를 구현한다: `onboarding(.delegate(.guestAccessRequested))`, `onboarding(.delegate(.curationAbandoned))`, `mainShell(.delegate(.signInSucceeded(needsCuration:)))`, `onboarding(.delegate(.mainShellRequested))`의 비로그인 분기, `applicationBecameActive`·`signInVerified(.reauthenticationRequired)`·`deviceTokenRefreshed`의 `state.mainShell.access == .guest` 가드. 기존 로그인 사용자 분기와 `returnToOnboarding`은 변경하지 않는다

### 패키지 검증

- [X] T036 [no-write] `rg -n "guestAccessRequested|curationAbandoned|signInSucceeded|memberAccessGranted" sources/Projects/App sources/Projects/Feature`로 Feature의 새 delegate가 App에서 모두 처리되는지 확인하고, 사용자에게 `AppTests` scheme 실행을 확인 항목으로 보고한다

**진행 점검**: T034~T036의 변경 파일과 검증 결과를 보고하고 전체 완료 검증으로 진행한다.

---

## 전체 완료 검증

**선행 조건**: U5의 파일 변경 작업을 완료하고, 전체 검증과 hook 결과를 포함할 마지막 커밋 단위를 아직 commit하지 않은
상태여야 한다.

**커밋 경계**: 아래 `[no-write]` 작업은 U5의 마지막 커밋 단위에 배정한다(T037~T039). 모든 검증과 필수 `after_implement` hook
(`speckit.swift-format.run`)을 마친 뒤 그 단위를 최종 commit한다. 이미 파일 변경 단위가 모두 commit된 단순 재개에서는
`tasks.md` 완료 표시를 위한 별도 최종 검증 단위를 둔다.

- [X] T037 [no-write] 사용자에게 `"$project_build_runner" build`, `compile`, `test`(7개 scheme) 실행을 요청하고 받은 결과를 기록한다. 실패가 있으면 원인 단위로 되돌아가 수정한다
- [X] T038 [no-write] [S1] [S2] [S3] [S4] [quickstart.md](./quickstart.md)의 수동 검증 1~10을 기준으로 시나리오별 수용 기준 충족 여부를 정리해 보고하고, 사용자가 시뮬레이터에서 확인할 항목(특히 SC-002 네트워크 요청 0건)을 명시한다
- [X] T039 [no-write] Constitution 원칙 3의 예외 기록을 PR 본문 초안으로 보고한다: 이유(실행기를 사용자가 직접 실행하는 운영 방침, pre-commit `build`·`compile` 비활성), 영향(U1~U5 개별 커밋은 컴파일·테스트 근거가 없어 중간 커밋 단독 checkout이 깨질 수 있음), 검증하지 못한 범위(T037에서 사용자가 보고하지 않은 scheme·단계, T038의 미확인 수동 항목)를 구분해 적는다. 같은 초안에 plan.md 복잡성 추적의 컨벤션 예외 2건(`legalAgreement` 항상 보유, `AccountUseCase` 스텁 승격)의 이유·영향, T002에서 research R5 대체안을 적용했다면 그 조건과 [ui-tab-shell 계약](./contracts/ui-tab-shell.md#대체안-적용-시-보장-범위)의 줄어든 보장, research R7의 Figma 근거 없는 배치(특히 튜토리얼 3면 `로그인 없이 둘러보기`)를 디자인 확인 대상으로 함께 적는다

## 의존성과 실행 순서

### 실행 단위 순서와 위험 기반 승인

- U1 → U2 → U3 → U4 → U5 → 전체 완료 검증 순서로 실행한다. U2와 U3은 서로 의존하지 않지만 이 순서로 고정한다.
  근거: U2는 변경 파일이 적고 목적(비로그인 진입 경로)이 독립적이어서 먼저 커밋하면 U3·U4의 홈·메인 화면 변경과
  리뷰·되돌리기 범위가 섞이지 않는다. U3은 U4가 소비하므로 U4 직전에 둔다.
- 각 단위의 변경 파일과 검증 결과를 보고하되 같은 기능 범위에서는 반복 승인을 요구하지 않는다.
- 새 권한이 필요한 경우: R7의 문구·배치와 다른 Figma 시안이 제시되면 해당 화면 작업(T009, T019~T021, T031, T032)을
  시작하기 전에 중단하고 사용자 확인을 받는다. `TabContent.disabled(_:)` 대체안 적용은 R5에 이미 결정되어 있어 승인 대상이
  아니다.

### 변경 시나리오 추적성

| 시나리오 | 작업 |
| --- | --- |
| S1 로그인 없이 메인 화면 진입 | T004, T005, T007~T011, T034, T035 |
| S2 홈 계정 기능 대체 표시 | T013~T022, T027, T030 |
| S3 계정 전용 탭 제한 | T001, T002, T024, T026, T030~T032 |
| S4 비로그인 → 로그인 전환 | T005, T006, T013, T017, T024~T026, T028~T030, T032, T034, T035 |

변경 시나리오는 U5까지 완료된 뒤 T038에서 독립 수용 기준으로 검증한다.

### 실행 단위 내부 실행

- 각 단위에서 테스트 작업을 구현보다 먼저 작성한다.
- `[P]`는 현재 단위 안의 서로 다른 파일에만 붙였다. 같은 파일을 바꾸는 작업(예: T030과 T032는 서로 다른 파일이지만 T032가
  T030의 State·Action을 사용)은 순차 실행한다.
- 서로 다른 실행 단위는 Git index·같은 파일을 공유하므로 병렬 실행하지 않는다.

### 병렬 실행 예시

- U2: T004와 T005(서로 다른 테스트 파일), 구현 후 T011은 T009·T010과 독립
- U3: T022은 T017~T021 완료 후 다른 파일로 병행 가능
- U4: T024(대역 승격) 완료 후 T025와 T026(서로 다른 파일, T024 대역만 의존). T027은 T024와 같은 파일이므로 T024 뒤에 순차 실행

## 구현 전략

1. 이 tasks.md의 blob hash와 전체 diff를 기준선으로 고정하고 첫 미완료 단위(U1)부터 시작한다.
2. 각 단위의 미완료 작업을 논리적 커밋 단위로 설계하고 구현·정적 검증·완료 표시·커밋을 순서대로 마친다.
3. 단위마다 변경 파일, 검증 결과, 사용자 확인이 필요한 실행기 검증을 보고하고 다음 단위로 이어간다.
4. U5의 마지막 단위는 전체 완료 검증과 필수 `after_implement` hook까지 열린 상태로 유지한 뒤 최종 commit한다.

**최소 가치 범위**: U1~U5 전체. 비로그인 진입(S1)이 가치를 가지려면 홈 표시(S2)와 탭 제한(S3)이 함께 있어야 빈 화면·요청
실패가 노출되지 않으므로 P1 시나리오를 분리해 배포하지 않는다. S4(P2)는 U4·U5 안에서 함께 구현된다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 문제 해결과 암묵지 기록은 구현 작업으로 만들지 않는다.
