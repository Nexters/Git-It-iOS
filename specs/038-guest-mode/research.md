# 조사: 비로그인(게스트) 모드

**기능**: [spec.md](spec.md) | **계획**: [plan.md](plan.md) | **작성일**: 2026-09-19

## R1. 세션 모드(메인 화면 접근 수준)를 어디에 둘 것인가

- 결정: `MainShellRouterFeature.State`가 접근 수준 `MainShellAccess`(`member`, `guest`)를 소유하고,
  `HomeFeature.State`는 같은 값을 복사해 표시와 요청 여부를 결정한다. 값의 변경은 App(`AppRootFeature`)이
  `MainShellRouterFeature`의 `input`으로만 지시하고, MainShellRouter가 Home에 전파한다.
- 근거: 비로그인 여부는 메인 화면 수명 안의 표시 정책이다. FR-003에 따라 기기에 저장하지 않으므로 Domain·Data에
  세션 모드 저장소를 새로 만들 이유가 없다. `AppEntryFeature`의 복원 결과(`restoreSignIn`)는 로그인 사용자만
  다루므로 변경하지 않는다.
- Router 컨벤션 정합성: [Router 컨벤션](../../docs/conventions/tca/navigation/router.md)은 Router `State`에 전환
  상태만 두고, Router보다 긴 생명주기가 필요한 상태의 정본은 상위가 소유하도록 한다. `access`는 두 조건을 모두
  만족하므로 Router가 정본을 소유한다.
  - 전환 상태다: `access`는 셸 흐름의 활성 화면 값(`selectedTab`)이 가질 수 있는 값, 즉 선택 가능한 탭을
    결정하고, 마이 탭 자리에 그릴 화면(`SettingsRouter` 또는 로그인 화면)을 결정한다.
  - 수명이 Router와 같다: `access`는 `MainShellRouterFeature.State`와 함께 생성되고(`init(access:)`), 로그아웃·계정
    삭제 시 App의 `returnToOnboarding`이 `MainShellRouterFeature.State()`로 초기화할 때 함께 사라진다. 비로그인
    선택을 저장하지 않으므로(FR-003) Router보다 오래 보존해야 할 값이 없다.
  - App은 `access`를 바꾸지 않고 `State(access:)` 생성과 `input(.memberAccessGranted)`로만 지시한다. App의 가드
    (`applicationBecameActive`, `signInVerified`, `deviceTokenRefreshed`)는 이 값을 읽기만 한다.
- 검토한 대안:
  - App(`AppRootFeature.State`)이 세션 모드 정본을 소유하고 Router에 복사: 같은 값을 App·Router·Home 세 곳에 두고
    동기화해야 하며, 수명이 Router와 같아 상위 소유의 이점이 없으므로 기각.
  - Domain `AccountUseCase`에 게스트 상태 추가: 저장하지 않는 표시 정책을 비즈니스 계약으로 올리는 셈이라 기각.
  - `AppRootFeature.Route`에 `guestMainShell` 추가: 같은 `MainShellRouter` 화면을 두 route로 나눠 탭 유지(명확화
    Q3)가 route 전환마다 깨지므로 기각.

## R2. 비로그인 진입 경로

- 결정: `TutorialFeature`에 `view(.guestAccessTapped)`와 `delegate(.guestAccessRequested)`를 추가하고,
  `OnboardingRouterFeature`가 `delegate(.guestAccessRequested)`로 App에 전달한다. App은
  `MainShellRouterFeature.State(access: .guest)`로 메인 화면에 진입하고 기기 등록을 하지 않는다.
  로그인 진행 중(`authentication == .signingIn`)에는 비로그인 진입을 무시한다.
- 근거: FR-001(마지막 면 보조 동작), FR-002(약관·직군 요구 없음), 예외 사례(로그인 진행 중 중복 입력).
  기존 Apple 로그인 버튼 아래 영역은 `isHintVisible`(마지막 면 여부)로 이미 가시성을 제어하므로 같은 조건을 쓴다.
- 검토한 대안: AppEntry에서 바로 게스트 진입 — 튜토리얼 마지막 면이라는 결정(FR-001)과 맞지 않아 기각.

## R3. 비로그인 상태의 로그인 흐름(그 자리에서 Apple 로그인)

- 결정: `Feature/MainShell/Router/GuestSignInFeature`를 새로 만들고 `MainShellRouterFeature`가 자식으로
  소유한다. 화면이 없는 관심사 Feature이므로 [Feature 흐름 배치](../../docs/conventions/directory-file/feature-layout.md)의
  1뎁스 중 화면 폴더를 만들 수 없고, 같은 조건의 `OnboardingExitFeature`가 `Onboarding/Router/`에 있는 선례를
  따른다. 순서는 다음과 같다.
  1. `input(.start)` → 자식 `LegalAgreementFeature`에 `input(.load)`를 보내 문서 목록과 기기의 약관 동의 기록
     충족 여부(`isStoredConsentValid`)를 채운다. 이미 문서가 채워져 있으면 기존 값을 쓴다. 별도의
     `policyConsentStatus` 호출 Effect를 만들지 않으며, 이 의존성은 `LegalAgreementFeature` 생성에만 전달한다.
  2. 충족 → Apple 로그인(`signIn(.apple)`). 미충족 → `input(.prepare)`로 선택을 초기화하고 약관 화면을 띄우고
     동의 완료 시 Apple 로그인, 취소 시 아무 변화 없이 종료.
  3. 로그인 결과: `signedIn` → `delegate(.signedIn(needsCuration:))`, `cancelled` → 조용히 종료,
     `retryableFailure` → 실패 알럿 표시.
  화면은 `MainShellRouter`가 기존 `ModalOverlay` + `LegalAgreementScreen` + `WebSheet` 조합을 온보딩과 같은
  방식으로 덮어 그린다.
- 근거: FR-011(메인 화면을 벗어나지 않음), FR-013(취소·실패 시 유지). 약관 동의는 로그인 전에 기기에 기록하는
  사전 조건이므로(`Account.consent` → `PolicyConsentRepository.record`) 온보딩과 같은 선후 관계를 유지해야 한다.
  `TutorialFeature`는 페이지·디버그용 계정 초기화(`deletesCompletedAccountOnSignIn`) 책임까지 가지므로 재사용하지
  않는다. 디버그 초기화는 튜토리얼 경로에만 적용한다.
- 약관 자식 State 수명(예외): `legalAgreement`는 optional이 아니라 `GuestSignInFeature.State`가 항상 보유한다.
  [State 형태 컨벤션](../../docs/conventions/tca/state/shape.md)은 자식 수명을 optional·`@Presents`로 드러내도록
  하고 항상 보유는 순차 흐름 Router에만 허용하므로, 이 결정은 컨벤션 예외다. 이유: 자식은 약관 화면 표시
  (`agreeingToPolicies`)뿐 아니라 표시 전 판정(`checkingConsent`)에도 쓰이며, 한 번 불러온 문서 목록과
  `isStoredConsentValid`를 다음 로그인 시도에서 재사용해 약관 문서 요청을 반복하지 않는다(온보딩 라우터와 같은
  방식). 표시 여부는 `phase`가 정본이고 `legalAgreement`의 존재로 판단하지 않는다. 영향: 자식 State가 화면 표시와
  무관하게 남으므로 `phase`를 거치지 않고 자식 값만으로 표시 여부를 판단하는 코드를 만들지 않는다. 이 예외는
  plan.md 복잡성 추적과 PR 본문(원칙 3)에 기록한다.
- 검토한 대안:
  - `legalAgreement`를 optional 자식으로 두고 `start`에서 생성, `idle`에서 제거: 컨벤션과 맞지만 로그인 시도마다
    약관 문서를 다시 요청하고, 판정 단계와 표시 단계의 생성 시점 분기가 늘어나 기각.
  - 온보딩 route로 전환해 튜토리얼 로그인 재사용: FR-011(메인 화면에서 그 자리에서 로그인)에 위배되어 기각.
  - App이 로그인 흐름을 직접 소유: Feature 수명 안에서 끝나는 sheet·alert는 Feature가 소유한다는
    [TCA Navigation 컨벤션](../../docs/conventions/tca/navigation.md)에 어긋나 기각.

## R4. 로그인 후 추가 온보딩(직군·연차)과 중단

- 결정: 비로그인 로그인 결과가 `needsCuration == true`이면 App이 `OnboardingRouterFeature.State(startingAt:
  .curation, ...)`에 `curationExit = .returnToCaller`를 지정해 `route = .onboarding`으로 전환한다. 이때
  `mainShell` 상태는 초기화하지 않는다. OnboardingRouter는 `positionSelection(.delegate(.exitRequested))`를 받으면
  `curationExit`가 `.returnToCaller`일 때 튜토리얼로 가지 않고 `delegate(.curationAbandoned)`를 보낸다. App은
  이를 받아 `route = .mainShell`(비로그인 유지)로 되돌린다. 직군·연차 완료(`mainShellRequested`)는
  `route = .mainShell` + `mainShell(.input(.memberAccessGranted))` + 기기 등록.
- 근거: FR-012, 명확화 Q1(중단 시 로그아웃 후 비로그인 메인). `PositionSelectionFeature`는 종료 시 이미
  `signOut`을 호출하므로 로그아웃은 기존 동작을 재사용한다. 약관 동의는 R3에서 로그인 전에 끝나므로 로그인 후
  중단할 수 있는 단계는 직군·연차뿐이다. `mainShell` 상태를 유지하므로 선택 탭이 보존된다(명확화 Q3).
- 검토한 대안: 직군·연차 화면을 MainShell 위에 fullScreenCover로 새로 구성 — 온보딩 화면 흐름을 복제하게 되어
  기각.

## R5. 비활성 탭 표현

- 결정: UI `TabShell`에 `isEnabled: (Item) -> Bool` 입력(기본값 전부 활성)을 추가하고, iOS 18+ `Tab(value:)`
  API와 `TabContent.disabled(_:)`로 탭 막대 항목을 비활성화한다. 선택 거부의 정본은 Reducer다.
  `MainShellRouterFeature`는 비로그인 상태에서 `.projects`, `.saved` 선택을 무시하고 `selectedTab`을 유지한다.
- 근거: FR-009, SC-003. 시스템 비활성 표시는 VoiceOver의 "흐리게 표시됨" 안내를 함께 제공한다(접근성 미룬
  항목 해소). Reducer 가드는 화면 없이 테스트할 수 있다.
- 검토한 대안: 탭 선택 시 알럿 — 입력 원문("탭 - 비활성")과 명세 가정(알럿 없음)에 어긋나 기각.
- 구현 시 확인: 최소 배포 대상이 iOS 26이므로 `Tab` API를 쓸 수 있다. 다음 중 하나라도 해당하면 `Tab(value:)`로
  전환하지 않고 기존 `.tabItem` 구성을 유지한 채 Reducer 가드는 그대로 두고 비활성 탭의 아이콘·제목에 `grey400`
  색을 적용하는 대체안으로 바꾼다: (a) `TabContent.disabled(_:)`가 컴파일되지 않는다, (b) `Tab` label 안에서 기존
  아이콘 아래 `padding(.bottom, LayoutToken.tightSpacing)` 또는 `Text.designSystemStyled(_:style: .tabItem)` 제목
  스타일을 그대로 적용할 수 없다. 대체안에서는 탭 막대가 선택 입력을 막지 않고(Reducer가 거부) VoiceOver 비활성
  안내도 없으므로 [ui-tab-shell 계약](contracts/ui-tab-shell.md)의 대체안 보장 범위를 따른다. 대체안 적용 사실과 이유는 `tasks.md`가 아니라 실행 단위 보고와 PR 본문에 남긴다(`speckit-implement`는
  Constitution 원칙 5에 따라 `tasks.md`의 완료 표시만 수정할 수 있다).

## R6. 계정 데이터 요청 차단(FR-004, SC-002)

- 결정:
  - Home: `access == .guest`이면 `view(.task)`와 `input(.learningProjectsReloadRequested)`에서 프로필·프로젝트
    요청 Effect를 만들지 않는다.
  - MainShellRouter: 비로그인 상태에서 `reloadLearningProjects()`를 보내지 않고, 마이 탭에는 `SettingsRouter`
    대신 로그인 화면을 그려 설정·프로필 Effect가 시작되지 않게 한다. 프로젝트·저장 탭 자리에는
    `ProjectListScreen`·`SavedScreen` 대신 Store·`task`가 없는 빈 배경을 그린다. 탭 선택 거부에만 의존하지 않고
    `TabView`가 탭 내용을 미리 만들더라도 계정 요청 Effect가 구조적으로 시작되지 않게 하기 위함이다.
  - App: 비로그인 상태에서 `applicationBecameActive`의 `verifySignIn`, 프로젝트 재조회, 기기 등록 재시도를
    수행하지 않고, `deviceTokenRefreshed`의 토큰 갱신·기기 등록을 건너뛴다. `signInVerified(.reauthenticationRequired)`로
    온보딩에 돌아가지 않는다(FR-014).
- 근거: 이의제기 문서의 "모든 콘텐츠 요청이 인증 헤더를 붙인다"는 사실 때문에 비로그인 요청은 실패만 만든다.
- 검토한 대안: Data 계층에서 인증 정보가 없으면 요청 생략 — 화면 단 차단보다 늦고, 실패 상태가 화면에 드러나므로
  기각.

## R7. Figma 근거와 문구

- 결정: 이번 기능에 대응하는 Figma 노드는 [Figma 노드 인덱스](../../.agents/skills/implement-figma-ui/references/figma-index.md)에
  없고, 현재 세션에서는 Figma MCP 인증이 없어 새 노드를 조회할 수 없다. 따라서 새 레이아웃 값을 만들지 않고
  **같은 화면에 이미 구현된 배치와 기존 UIComponent·DesignSystem 토큰만** 재사용한다.
  - 홈 로그인 섹션: `HomeScreen.ProfileHeaderView`의 실패 상태 배치(제목·캡션 + `ActionButton.secondary(size: .small)`)를
    그대로 쓴다. 문구: 제목 `로그인이 필요해요`, 캡션 `로그인하고 나만의 학습을 시작해 보세요.`, 버튼 `로그인`.
  - 홈 프로젝트 영역: `ProjectSection`의 `emptyProjects` 배치를 재사용한다. 문구:
    `로그인하면 학습 중인 레포지토리를 볼 수 있어요.`(Body 2, `purple200` — 빈 상태와 같은 스타일).
  - 전체보기 비활성: 기존 버튼에 `.disabled(true)`와 `grey400` 색을 적용한다.
  - 프로젝트 생성 알럿: 시스템 `.alert`. 제목 `로그인이 필요해요`, 본문 `프로젝트를 만들려면 로그인해 주세요.`,
    버튼 `로그인`, `닫기`(cancel).
  - 마이 탭 로그인 화면: `ScreenContainer` + `StyledText.subtitle1` 제목 `로그인이 필요해요` + `StyledText.body2`
    본문 `로그인하면 학습 현황과 설정을 확인할 수 있어요.` + 기존 `AppleSignInButton`. 간격은 `LayoutToken`만 쓴다.
  - 튜토리얼 비로그인 진입: `AppleSignInButton` 아래 `ActionButton`의 Text 스타일, 문구 `로그인 없이 둘러보기`.
  - 로그인 실패 알럿: 제목 `로그인하지 못했어요`, 본문 `잠시 후 다시 시도해 주세요.`, 버튼 `확인`.
- 근거: AGENTS.md의 "노드 근거 없이 레이아웃 값을 추정해 구현하지 않는다" 규칙을 지키면서 심사 대응 일정을
  막지 않기 위함이다.
- 후속: Figma 비로그인 시안이 나오면 `implement-figma-ui` 스킬로 문구·배치를 교정한다(이번 범위 밖).
  특히 튜토리얼 3면(`779:33564`)은 Figma 노드가 있는 화면이므로, 그 위에 추가하는 `로그인 없이 둘러보기` 버튼은
  노드 근거가 없는 배치다. 디자인 확인 대상으로 PR 본문에 명시한다.

## R8. 로그인 성공 뒤 탭과 데이터 재적재

- 결정: `MainShellRouterFeature.input(.memberAccessGranted)`는 `access = .member`로 바꾸고 `selectedTab`은
  유지한다. Home에 `input(.accessChanged(.member))`를 보내 프로필·프로젝트 적재를 시작하고, 프로젝트 목록 재조회를
  보낸다. 마이 탭은 다음 렌더에서 `SettingsRouter`로 바뀌어 기존 `task`가 프로필을 불러온다.
- 근거: 명확화 Q3(시작한 탭 유지, 마이는 프로필로 전환), 시나리오 4.

## R9. MainShell 테스트의 `AccountUseCase` 대역

- 결정: `MainShellRouterFeatureTests.swift`의 private `MainShellAccountUseCaseStub`을
  `Feature/Tests/MainShell/TestDoubles/MainShellAccountUseCaseStub.swift`로 옮기고, 설정한 `SignInResult`·약관 충족
  여부를 돌려주며 로그인 호출 수를 기록하도록 확장한다. 새 대역을 따로 만들지 않는다. `GuestSignInFeatureTests`도
  Onboarding 흐름의 `AccountUseCaseSignInMock` 대신 이 대역의 메서드를 클로저로 넘겨 쓴다.
- 컨벤션 예외: [Feature 패키지 규칙 제약조건](../../docs/package-rules/feature.md)은 테스트에서도 Domain UseCase
  프로토콜을 Feature 안에서 구현하지 않도록 한다. 그러나 `MainShellRouterFeature.init`이 이미
  `account: any AccountUseCase`를 받고, 기존 `MainShellAccountUseCaseStub`·Home `ProjectUseCaseMock`도 같은 방식으로
  프로토콜을 구현한다. 이 기능은 새 프로토콜 구현을 추가하지 않고 기존 대역 하나를 승격·확장하는 데서 멈춘다.
  - 이유: 라우터 생성자를 클로저 subset으로 바꾸면 App 조합과 Settings 주입까지 바뀌어 비로그인 모드와 무관한
    범위 확대가 된다.
  - 영향: Feature 테스트가 `AccountUseCase` 프로토콜 변경에 계속 결합된다.
  - 기록: plan.md 복잡성 추적과 PR 본문(원칙 3). 부채 해소는 별도 명세로 다룬다.
- 검토한 대안: `MainShellRouterFeature`가 `account` 대신 필요한 클로저만 받도록 변경 — 범위 확대로 기각.
