# Feature 패키지 타입 목록

[인덱스로 돌아가기](README.md) · [단어 사전](glossary.md)

타입 380개, 관심사 폴더 56개. 항목은 파일 경로와 선언 줄 순서다. 각 항목은 `이름` 종류 · 접근 수준 · 파일 링크, 한 줄 설명, 그리고 이름을 이루는 단어와 정의로 구성된다.

| 종류 | 개수 |
|---|---|
| enum | 233 |
| struct | 145 |
| typealias | 2 |

## AppEntry

- **`OnboardingEntryPoint`** `enum` · public · [AppEntryFeature.swift:8](../../../sources/Projects/Feature/AppEntry/AppEntryFeature.swift#L8) · 채택: Equatable, Sendable  
  온보딩 흐름을 어느 단계부터 시작할지 나타내는 열거형으로 guide(가이드부터)와 curation(큐레이션 입력부터) 두 경우를 가진다. AppEntryFeature.Destination의 .onboarding(startingAt:) 연관값으로 쓰인다.  
  단어: `Onboarding` 온보딩·신규 사용자 안내 절차. 여기서는 앱 최초 진입 시 가이드와 큐레이션을 거치는 온보딩 흐름 · `Entry` 진입·들어감. 여기서는 온보딩 흐름에 들어가는 행위 · `Point` 지점·위치. 여기서는 온보딩이 시작되는 단계(가이드 또는 큐레이션)
- **`AppEntryFeature`** `struct` · public · [AppEntryFeature.swift:15](../../../sources/Projects/Feature/AppEntry/AppEntryFeature.swift#L15) · 채택: Sendable  
  앱 시작 시 로그인 세션 복원(restoreSignIn) → 큐레이션 조회(curation) → 필요 시 로컬 정리(signOut) 클로저를 순서대로 실행해 mainShell 또는 onboarding 목적지를 결정하는 @Reducer 타입. 스플래시 애니메이션이 끝나기 전에는 목적지를 pendingDestination에 보류하고, 일시 장애는 자동 재시도 1회 후 retryableFailure 상태로 전환한다.  
  단어: `App` 응용 프로그램. 여기서는 Git It iOS 앱 자체 · `Entry` 진입·입구. 여기서는 앱이 처음 실행돼 들어오는 스플래시 단계 · `Feature` 기능·특징. 여기서는 TCA에서 State·Action·Reducer를 묶은 기능 단위(Reducer 타입)
- **`AppEntryFeature.AuthenticationStatus`** `enum` · public · [AppEntryFeature.swift:32](../../../sources/Projects/Feature/AppEntry/AppEntryFeature.swift#L32) · 채택: Equatable, Sendable  
  앱 진입 시 세션 복원 진행 상태를 나타내는 열거형으로 idle, restoring, retryableFailure 세 경우를 가진다. State.authentication에 저장되며 isShowingRecoverableError 계산과 task·retryTapped 가드 조건에 쓰인다.  
  단어: `Authentication` 인증. 여기서는 저장된 로그인 세션을 복원해 사용자를 인증하는 절차 · `Status` 상태. 여기서는 인증 절차의 진행 단계(대기·복원 중·재시도 가능 실패)
- **`AppEntryFeature.Destination`** `enum` · public · [AppEntryFeature.swift:38](../../../sources/Projects/Feature/AppEntry/AppEntryFeature.swift#L38) · 채택: Equatable, Sendable  
  앱 진입 판정 결과로 이동할 목적지를 나타내며 mainShell과 onboarding(startingAt: OnboardingEntryPoint) 두 경우를 가진다. State.pendingDestination과 Delegate.destinationDecided의 연관값으로 쓰인다.  
  단어(단일): `Destination` 목적지·행선지. 여기서는 앱 진입 판정 후 이동할 화면(메인 셸 또는 온보딩)
- **`AppEntryFeature.State`** `struct` · public · [AppEntryFeature.swift:43](../../../sources/Projects/Feature/AppEntry/AppEntryFeature.swift#L43) · 채택: Equatable, Sendable  
  AppEntryFeature의 @ObservableState 상태로 authentication 상태, 요청 식별자 requestID, 스플래시 애니메이션 완료 여부 isSplashAnimationFinished, 보류 목적지 pendingDestination, 자동 재시도 횟수 automaticRetryCount를 보유한다. isShowingRecoverableError 계산 속성으로 재시도 알림 표시 여부를 제공한다.  
  단어(단일): `State` 상태. 여기서는 TCA Reducer가 관리하는 관찰 가능한 상태 값 묶음(@ObservableState struct)
- **`AppEntryFeature.Action`** `enum` · public · [AppEntryFeature.swift:64](../../../sources/Projects/Feature/AppEntry/AppEntryFeature.swift#L64) · 채택: ViewAction, Sendable, Equatable  
  AppEntryFeature가 처리하는 액션의 최상위 분류로 view(View), effect(EffectEvent), delegate(Delegate) 세 경우를 가진다. ViewAction 채택으로 AppEntryScreen이 send(.view(...))로 화면 이벤트를 전달한다.  
  단어(단일): `Action` 행동·동작. 여기서는 TCA Reducer에 전달되는 이벤트를 분류한 열거형
- **`AppEntryFeature.Action.View`** `enum` · public · [AppEntryFeature.swift:71](../../../sources/Projects/Feature/AppEntry/AppEntryFeature.swift#L71) · 채택: Sendable, Equatable  
  AppEntryScreen에서 발생하는 화면 이벤트 액션으로 task(화면 등장), retryTapped(다시 시도), splashAnimationFinished(로고 애니메이션 종료) 세 경우를 가진다. @CasePathable이 적용돼 있다.  
  단어(단일): `View` 보기·화면. 여기서는 SwiftUI 화면에서 발생해 Reducer로 보내는 액션 분류
- **`AppEntryFeature.Action.EffectEvent`** `enum` · public · [AppEntryFeature.swift:78](../../../sources/Projects/Feature/AppEntry/AppEntryFeature.swift#L78) · 채택: Sendable, Equatable  
  비동기 effect의 완료 결과를 Reducer에 되돌리는 액션으로 restoreSignInFinished, curationFetchFinished, localCleanupFinished 세 경우를 가지며 각각 requestID와 결과 값을 연관값으로 담는다. 같은 패키지의 HomeFeature는 같은 역할 분류를 Effect라는 이름으로 둔다.  
  단어: `Effect` 효과·부수 효과. 여기서는 TCA에서 Reducer 밖에서 실행되는 비동기 작업 · `Event` 사건·이벤트. 여기서는 effect 작업이 끝났음을 알리는 결과 액션
- **`AppEntryFeature.Action.Delegate`** `enum` · public · [AppEntryFeature.swift:85](../../../sources/Projects/Feature/AppEntry/AppEntryFeature.swift#L85) · 채택: Sendable, Equatable  
  상위 Reducer에 알리는 위임 액션으로 destinationDecided(Destination) 하나를 가진다. 진입 판정과 스플래시 애니메이션 종료가 모두 끝났을 때 decideDestination 또는 splashAnimationFinished 처리에서 발송된다.  
  단어(단일): `Delegate` 위임·대리인. 여기서는 하위 기능이 처리 결과를 상위 Reducer에 넘기는 액션 분류
- **`AppEntryFeature.Constant`** `enum` · private · [AppEntryFeature.swift:178](../../../sources/Projects/Feature/AppEntry/AppEntryFeature.swift#L178)  
  AppEntryFeature 내부 상수 네임스페이스로 자동 재시도 최대 횟수 maximumAutomaticRetryCount(1)만 보유한다. retryAutomaticallyOrFail에서 재시도 한도 판단에 쓰인다.  
  단어(단일): `Constant` 상수. 여기서는 Reducer 내부의 고정 값(자동 재시도 한도)을 모아 두는 네임스페이스 enum
- **`AppEntryFeature.CancelID`** `enum` · private · [AppEntryFeature.swift:182](../../../sources/Projects/Feature/AppEntry/AppEntryFeature.swift#L182) · 채택: Hashable  
  취소 가능한 effect를 구분하는 식별자로 restore(세션 복원), profile(큐레이션 조회), cleanup(로컬 정리) 세 경우를 가진다. 각 effect의 .cancellable(id:cancelInFlight:)에 전달돼 같은 종류의 진행 중 effect를 취소한다.  
  단어: `Cancel` 취소. 여기서는 진행 중인 TCA effect를 취소하는 동작 · `ID` Identifier(식별자). 여기서는 취소 대상 effect를 구분하는 키
- **`AppEntryScreen`** `struct` · public · [AppEntryScreen.swift:8](../../../sources/Projects/Feature/AppEntry/AppEntryScreen.swift#L8) · 채택: View  
  AppEntryFeature 스토어를 받아 ScreenContainer 안에 LaunchLogo 스플래시를 표시하는 SwiftUI 화면으로 등장 시 task 액션을, 로고 애니메이션 완료 시 splashAnimationFinished를 보낸다. isShowingRecoverableError가 참이면 "세션을 확인하지 못했어요" 알림과 다시 시도 버튼을 띄운다.  
  단어: `App` 응용 프로그램. 여기서는 Git It iOS 앱 자체 · `Entry` 진입·입구. 여기서는 앱이 처음 실행돼 들어오는 스플래시 단계 · `Screen` 화면. 여기서는 스토어를 받아 렌더링하는 SwiftUI 화면 View 타입

## Home

- **`HomeFeature`** `struct` · public · [HomeFeature.swift:6](../../../sources/Projects/Feature/Home/HomeFeature.swift#L6) · 채택: Sendable  
  홈 탭의 @Reducer 타입으로 프로젝트 목록 스트림(projects), 새로고침(refreshProjects), 프로필 조회(profile) 클로저를 주입받아 profileLoad·projectLoad 상태를 관리한다. 카드 탭·학습 시작·프로젝트 등록 요청은 Delegate로 상위 MainShellRouterFeature에 전달한다.  
  단어: `Home` 집·홈. 여기서는 메인 셸의 첫 번째 탭인 홈 화면 · `Feature` 기능·특징. 여기서는 TCA에서 State·Action·Reducer를 묶은 기능 단위(Reducer 타입)
- **`HomeFeature.State`** `struct` · public · [HomeFeature.swift:23](../../../sources/Projects/Feature/Home/HomeFeature.swift#L23) · 채택: Equatable, Sendable  
  홈 기능의 @ObservableState 상태로 profileLoad·projectLoad 로드 상태, 각 요청 식별자 profileRequestID·projectRequestID, 문제 생성 진행 여부 isGenerationInProgress를 보유한다. 중첩 타입 ProfileLoad·ProjectLoad를 정의한다.  
  단어(단일): `State` 상태. 여기서는 TCA Reducer가 관리하는 관찰 가능한 상태 값 묶음(@ObservableState struct)
- **`HomeFeature.State.ProfileLoad`** `enum` · public · [HomeFeature.swift:32](../../../sources/Projects/Feature/Home/HomeFeature.swift#L32) · 채택: Equatable, Sendable  
  사용자 프로필 로드 상태로 idle, loading, loaded(UserProfile), failed(UserInfoError) 네 경우를 가진다. HomeProfileDisplay가 이를 ProfileHeaderView 표시용 값으로 변환한다.  
  단어: `Profile` 프로필·인물 정보. 여기서는 사용자 이름·큐레이션을 담은 UserProfile · `Load` 적재·불러오기. 여기서는 비동기 조회의 진행 상태(대기·로딩·완료·실패)
- **`HomeFeature.State.ProjectLoad`** `enum` · public · [HomeFeature.swift:39](../../../sources/Projects/Feature/Home/HomeFeature.swift#L39) · 채택: Equatable, Sendable  
  학습 프로젝트 목록 로드 상태로 idle, loading, loaded(ProjectList), failed(ProjectError) 네 경우를 가지며 isLoaded 계산 속성을 제공한다. HomeProjectSectionState가 이를 섹션 표시 상태로 변환하고 Reducer는 startRefresh·refreshFinished에서 isLoaded로 덮어쓰기 여부를 판단한다.  
  단어: `Project` 프로젝트. 여기서는 사용자가 등록해 학습 중인 저장소(레포지토리) 단위 · `Load` 적재·불러오기. 여기서는 목록 조회의 진행 상태(대기·로딩·완료·실패)
- **`HomeFeature.Action`** `enum` · public · [HomeFeature.swift:62](../../../sources/Projects/Feature/Home/HomeFeature.swift#L62) · 채택: ViewAction, Equatable, Sendable  
  HomeFeature 액션의 최상위 분류로 view(View), input(Input), effect(Effect), delegate(Delegate) 네 경우를 가진다. ViewAction 채택으로 HomeScreen의 @ViewAction 매크로가 send(.view(...))를 생성한다.  
  단어(단일): `Action` 행동·동작. 여기서는 TCA Reducer에 전달되는 이벤트를 분류한 열거형
- **`HomeFeature.Action.View`** `enum` · public · [HomeFeature.swift:70](../../../sources/Projects/Feature/Home/HomeFeature.swift#L70) · 채택: Equatable, Sendable  
  HomeScreen에서 발생하는 화면 이벤트 액션으로 task, profileRetryTapped, projectRetryTapped, projectRegistrationTapped, showAllProjectsTapped, projectCardTapped(projectID:), learningTapped(projectID:) 일곱 경우를 가진다.  
  단어(단일): `View` 보기·화면. 여기서는 SwiftUI 화면에서 발생해 Reducer로 보내는 액션 분류
- **`HomeFeature.Action.Input`** `enum` · public · [HomeFeature.swift:81](../../../sources/Projects/Feature/Home/HomeFeature.swift#L81) · 채택: Equatable, Sendable  
  상위 Reducer가 홈 기능에 주입하는 입력 액션으로 learningProjectsReloadRequested(목록 재조회 요청)와 generationProgressChanged(isInProgress:)(문제 생성 진행 여부 변경)를 가진다. MainShellRouterFeature가 탭 전환·프로젝트 삭제 시 learningProjectsReloadRequested를 발송한다.  
  단어(단일): `Input` 입력. 여기서는 외부(상위 Reducer)에서 이 기능으로 주입되는 액션 분류
- **`HomeFeature.Action.Effect`** `enum` · public · [HomeFeature.swift:87](../../../sources/Projects/Feature/Home/HomeFeature.swift#L87) · 채택: Equatable, Sendable  
  비동기 작업 결과를 되돌리는 액션으로 profileLoadFinished(requestID:result:), projectsReceived(ProjectList), refreshFinished(requestID:error:) 세 경우를 가진다. TCA의 Effect 타입과 이름이 겹쳐 Reducer 본문에서는 ComposableArchitecture.Effect<Action>으로 완전 한정해 쓴다.  
  단어(단일): `Effect` 효과·부수 효과. 여기서는 비동기 effect의 완료 결과를 Reducer에 전달하는 액션 분류
- **`HomeFeature.Action.Delegate`** `enum` · public · [HomeFeature.swift:94](../../../sources/Projects/Feature/Home/HomeFeature.swift#L94) · 채택: Equatable, Sendable  
  상위 MainShellRouterFeature에 알리는 위임 액션으로 projectRegistrationRequested, projectDetailRequested(projectID:), learningRequested(projectID:nextSetID:) 세 경우를 가진다.  
  단어(단일): `Delegate` 위임·대리인. 여기서는 하위 기능이 처리 결과를 상위 Reducer에 넘기는 액션 분류
- **`HomeFeature.CancelID`** `enum` · private · [HomeFeature.swift:177](../../../sources/Projects/Feature/Home/HomeFeature.swift#L177)  
  취소 가능한 effect 식별자로 profile(프로필 조회), projects(목록 스트림 구독), refresh(새로고침) 세 경우를 가진다. 각 effect의 .cancellable(id:cancelInFlight:)에 쓰인다.  
  단어: `Cancel` 취소. 여기서는 진행 중인 TCA effect를 취소하는 동작 · `ID` Identifier(식별자). 여기서는 취소 대상 effect를 구분하는 키
- **`HomeScreen`** `struct` · public · [HomeScreen.swift:8](../../../sources/Projects/Feature/Home/HomeScreen.swift#L8) · 채택: View · 그래프 미수집(grep 보강)  
  HomeFeature 스토어를 받아 OverlayContainer 안에 ProfileHeaderView, GreetingView, RegistrationPanelView, ProjectSection을 세로로 배치하는 홈 탭 SwiftUI 화면(@ViewAction(for: HomeFeature.self)). 카드 목록 선두 X 좌표 cardListLeadingX를 @State로 보유해 ProjectSection의 카드 회전 계산에 넘긴다.  
  단어: `Home` 집·홈. 여기서는 메인 셸의 첫 번째 탭인 홈 화면 · `Screen` 화면. 여기서는 스토어를 받아 렌더링하는 SwiftUI 화면 View 타입
- **`HomeScreen.Constant`** `enum` · fileprivate · [HomeScreen.swift:62](../../../sources/Projects/Feature/Home/HomeScreen.swift#L62)  
  HomeScreen 본문 배치에 쓰는 상단 여백 상수 profileTopPadding, greetingTopPadding, registrationPanelTopPadding, projectSectionTopPadding을 모은 네임스페이스로 HomeScreen.swift 안에서 extension으로 선언된다.  
  단어(단일): `Constant` 상수. 여기서는 홈 화면 배치 여백 고정 값을 모아 두는 네임스페이스 enum

## Home/Previews

- **`HomePreviewFixture`** `enum` · private · [HomeScreenPreviews.swift:6](../../../sources/Projects/Feature/Home/Previews/HomeScreenPreviews.swift#L6)  
  HomeScreen의 #Preview에 쓰는 고정 데이터 네임스페이스로 샘플 UserProfile(profile), ProjectSummary 생성 함수 project(_:), ProjectList 생성 함수 list(_:), EmptyReducer 기반 StoreOf<HomeFeature> 생성 함수 store(projectLoad:profileLoad:)를 제공한다.  
  단어: `Home` 집·홈. 여기서는 홈 탭 화면 · `Preview` 미리보기. 여기서는 Xcode #Preview 렌더링 · `Fixture` 고정 장치·시험용 고정 데이터. 여기서는 미리보기에 주입하는 샘플 데이터와 스토어 묶음

## Home/SubViews

- **`HomeScreen.EmptyDeckShape`** `struct` · internal · [HomeScreen+EmptyDeckShape.swift:6](../../../sources/Projects/Feature/Home/SubViews/HomeScreen+EmptyDeckShape.swift#L6) · 채택: Shape  
  프로젝트가 없거나 로딩·실패 상태일 때 배경으로 그리는 카드 묶음 실루엣 Shape로 Card 배열의 둥근 사각형 경로를 합집합(union)한 뒤 주어진 rect에 비율을 유지하며 맞춘다. size 계산 속성으로 합집합 경로의 크기를 제공하며 ProjectSection이 채움·외곽선으로 그린다.  
  단어: `Empty` 비어 있는. 여기서는 등록된 프로젝트가 없는 빈 상태 · `Deck` 카드 한 벌·묶음. 여기서는 겹쳐 놓인 프로젝트 카드 묶음 · `Shape` 도형. 여기서는 SwiftUI Shape 프로토콜을 채택한 경로 도형
- **`HomeScreen.EmptyDeckShape.Card`** `struct` · internal · [HomeScreen+EmptyDeckShape.swift:41](../../../sources/Projects/Feature/Home/SubViews/HomeScreen+EmptyDeckShape.swift#L41) · 채택: Sendable, Equatable  
  EmptyDeckShape를 구성하는 카드 하나의 기하 정보로 frame, rotation(Angle), cornerRadius를 보유하고 fileprivate path 계산 속성으로 중심 기준 회전된 둥근 사각형 Path를 만든다. ProjectSection.Constant.emptyDeckCards()가 세 장을 생성한다.  
  단어(단일): `Card` 카드. 여기서는 빈 덱 실루엣을 이루는 카드 한 장의 위치·회전·모서리 정보
- **`HomeScreen.GreetingView`** `struct` · internal · [HomeScreen+GreetingView.swift:5](../../../sources/Projects/Feature/Home/SubViews/HomeScreen+GreetingView.swift#L5) · 채택: View  
  홈 화면 인사말 영역으로 "Hello World"(grey400)와 "Let’s Git -it-!" 두 줄 headline1 텍스트를 세로로 배치하고 접근성 요소로 결합한다. 입력 값이 없는 고정 View다.  
  단어: `Greeting` 인사·인사말. 여기서는 홈 상단의 환영 문구 · `View` 보기·뷰. 여기서는 SwiftUI View 타입
- **`HomeScreen.ProfileHeaderView`** `struct` · internal · [HomeScreen+ProfileHeaderView.swift:5](../../../sources/Projects/Feature/Home/SubViews/HomeScreen+ProfileHeaderView.swift#L5) · 채택: View  
  홈 상단 프로필 헤더로 HomeProfileDisplay를 받아 실패 시 안내 문구와 다시 시도 버튼(onRetry), 로드 완료 시 아바타 아이콘·이름·역할 텍스트, 그 외 상태에서는 같은 높이의 투명 공간을 표시한다.  
  단어: `Profile` 프로필·인물 정보. 여기서는 사용자 이름과 역할 · `Header` 머리말·상단부. 여기서는 홈 화면 최상단 영역 · `View` 보기·뷰. 여기서는 SwiftUI View 타입
- **`HomeScreen.ProfileHeaderView.Constant`** `enum` · private · [HomeScreen+ProfileHeaderView.swift:47](../../../sources/Projects/Feature/Home/SubViews/HomeScreen+ProfileHeaderView.swift#L47)  
  ProfileHeaderView 배치 상수 네임스페이스로 messageSpacing, failureMinHeight, headerHeight, topPadding, bottomPadding, userProfileSpacing, avatarSize를 보유한다.  
  단어(단일): `Constant` 상수. 여기서는 프로필 헤더 배치 고정 값을 모아 두는 네임스페이스 enum
- **`HomeScreen.ProjectSection`** `struct` · internal · [HomeScreen+ProjectSection.swift:6](../../../sources/Projects/Feature/Home/SubViews/HomeScreen+ProjectSection.swift#L6) · 채택: View  
  "학습 중인 레포지토리" 섹션으로 HomeProjectSectionState에 따라 HomeProjectCard 가로 스크롤 목록, 로딩 인디케이터, 빈 상태 문구, 실패 재시도 버튼을 EmptyDeckShape 실루엣 위에 표시한다. 섹션 너비를 관측해 카드 너비를 계산하고 HomeCardScrollLayout으로 스크롤 위치별 카드 회전각을 적용한다.  
  단어: `Project` 프로젝트. 여기서는 학습 중인 저장소(레포지토리) · `Section` 구획·섹션. 여기서는 홈 화면의 한 영역
- **`HomeScreen.ProjectSection.Constant`** `enum` · private · [HomeScreen+ProjectSection.swift:47](../../../sources/Projects/Feature/Home/SubViews/HomeScreen+ProjectSection.swift#L47)  
  ProjectSection의 상수·계산 함수 네임스페이스로 접근성 라벨 showAllLabel, 간격·여백·선 두께·최대 회전각·기본 섹션 너비 상수와 cardWidth(forSectionWidth:), cardStride(cardWidth:), rotationSlack(cardWidth:), sectionHeight(cardWidth:), emptyDeckCards() 정적 함수를 보유한다.  
  단어(단일): `Constant` 상수. 여기서는 프로젝트 섹션 배치 고정 값과 파생 계산 함수를 모아 두는 네임스페이스 enum
- **`HomeScreen.RegistrationPanelView`** `struct` · internal · [HomeScreen+RegistrationPanelView.swift:5](../../../sources/Projects/Feature/Home/SubViews/HomeScreen+RegistrationPanelView.swift#L5) · 채택: View  
  프로젝트 문제 생성 안내 패널로 안내 문구와 함께 isGenerationInProgress가 거짓이면 "지금 불러오기" 버튼(onRegister)을, 참이면 로딩 애니메이션과 "문제 생성 중" 라벨을 표시한다.  
  단어: `Registration` 등록. 여기서는 오픈소스 프로젝트를 불러와 등록하는 동작 · `Panel` 판·패널. 여기서는 배경이 있는 카드형 안내 영역 · `View` 보기·뷰. 여기서는 SwiftUI View 타입
- **`HomeScreen.RegistrationPanelView.Constant`** `enum` · private · [HomeScreen+RegistrationPanelView.swift:49](../../../sources/Projects/Feature/Home/SubViews/HomeScreen+RegistrationPanelView.swift#L49)  
  RegistrationPanelView 상수 네임스페이스로 접근성 라벨 registrationLabel·generationInProgressLabel과 progressLabelSpacing, progressIndicatorSize, progressLabelHorizontalPadding을 보유한다.  
  단어(단일): `Constant` 상수. 여기서는 등록 패널의 라벨 문자열과 배치 고정 값을 모아 두는 네임스페이스 enum

## Home/ViewModels

- **`HomeCardScrollLayout`** `struct` · internal · [HomeCardScrollLayout.swift:3](../../../sources/Projects/Feature/Home/ViewModels/HomeCardScrollLayout.swift#L3) · 채택: Equatable, Sendable  
  가로 스크롤 중인 프로젝트 카드의 회전각을 계산하는 값 타입으로 첫 카드 중심 X(p0CenterX)와 카드 간격(cardStride)을 받아 angle(cardCenterX:)로 위치 구간별(-16~16도) 각도를, initialAngles(cardCount:)로 초기 각도 배열을 돌려준다. ProjectSection의 visualEffect 회전에 쓰인다.  
  단어: `Home` 집·홈. 여기서는 홈 탭 화면 · `Card` 카드. 여기서는 HomeProjectCard 프로젝트 카드 · `Scroll` 스크롤·두루마리. 여기서는 카드 목록의 가로 스크롤 동작 · `Layout` 배치. 여기서는 스크롤 위치에 따른 카드 회전 배치 계산
- **`HomeProfileDisplay`** `struct` · internal · [HomeProfileDisplay.swift:3](../../../sources/Projects/Feature/Home/ViewModels/HomeProfileDisplay.swift#L3) · 채택: Equatable, Sendable  
  HomeFeature.State.ProfileLoad를 ProfileHeaderView 표시용 값(name, role, isFailed)으로 변환하는 값 타입으로 role은 커리어 레벨 영문 명칭에 " Developer"를 붙여 만든다. positionTitle(_:) 정적 함수도 정의돼 있으나 현재 init에서는 호출되지 않는다.  
  단어: `Home` 집·홈. 여기서는 홈 탭 화면 · `Profile` 프로필·인물 정보. 여기서는 사용자 이름과 역할 · `Display` 표시·표시용. 여기서는 화면에 보여 줄 형태로 가공한 데이터
- **`HomeProjectDisplay`** `struct` · internal · [HomeProjectDisplay.swift:5](../../../sources/Projects/Feature/Home/ViewModels/HomeProjectDisplay.swift#L5) · 채택: Equatable, Sendable  
  ProjectSummary와 인덱스를 받아 HomeProjectCard에 넘길 표시 값(projectID, title, technologies, progress, currentSetLabel, setTitle, variant, isLearningEnabled)으로 변환하는 값 타입. variant는 purple·lightBlue·darkBlue를 인덱스 순환으로 배정하고 isLearningEnabled는 next?.quizID 존재 여부로 정한다.  
  단어: `Home` 집·홈. 여기서는 홈 탭 화면 · `Project` 프로젝트. 여기서는 학습 중인 저장소 요약 ProjectSummary · `Display` 표시·표시용. 여기서는 카드에 보여 줄 형태로 가공한 데이터
- **`HomeProjectSectionState`** `enum` · internal · [HomeProjectSectionState.swift:1](../../../sources/Projects/Feature/Home/ViewModels/HomeProjectSectionState.swift#L1) · 채택: Equatable, Sendable  
  HomeFeature.State.ProjectLoad를 ProjectSection 표시 상태로 변환한 열거형으로 loading, empty, failed, loaded([HomeProjectDisplay]) 네 경우를 가진다. idle·loading은 loading으로, 빈 목록은 empty로, 나머지 loaded는 HomeProjectDisplay 배열로 매핑한다.  
  단어: `Home` 집·홈. 여기서는 홈 탭 화면 · `Project` 프로젝트. 여기서는 학습 중인 저장소 · `Section` 구획·섹션. 여기서는 홈 화면의 프로젝트 영역 · `State` 상태. 여기서는 섹션이 보여 줄 표시 상태(로딩·빈·실패·목록)

## MainShell/Router

- **`MainShellRouter`** `struct` · public · [MainShellRouter.swift:8](../../../sources/Projects/Feature/MainShell/Router/MainShellRouter.swift#L8) · 채택: View  
  MainShellRouterFeature 스토어를 받아 TabShell로 home·projects·saved·settings 탭 화면(HomeScreen, ProjectListScreen, SavedScreen, SettingsRouter)을 전환하는 SwiftUI 라우터 뷰(@ViewAction). 단일 문제 진입 준비 중 스크림 오버레이, 준비 실패 알림, PushedScreenOverlay 안의 QuestionSolvingScreen도 함께 표시한다.  
  단어: `Main` 주요·메인. 여기서는 로그인 후 사용하는 주 화면 영역 · `Shell` 껍데기·외곽. 여기서는 탭 바로 하위 화면을 감싸는 컨테이너 · `Router` 경로 지정자. 여기서는 탭·오버레이 화면을 선택해 보여 주는 뷰
- **`MainShellRouterFeature`** `struct` · public · [MainShellRouterFeature.swift:10](../../../sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift#L10) · 채택: Sendable  
  메인 셸의 @Reducer 타입으로 ProjectUseCase·QuizDetailUseCase·AccountUseCase·UserInfoUseCase·AppSettingUseCase를 주입받아 HomeFeature·ProjectListFeature·SavedFeature·SettingsRouterFeature를 Scope로 합성하고 SingleQuestionEntryFeature·QuestionSolvingFeature를 ifLet으로 붙인다. 탭 전환, 자식 delegate의 상위 전달, 저장 문제 단일 풀이 진입, 로그아웃·탈퇴 시 상태 초기화를 담당한다.  
  단어: `Main` 주요·메인. 여기서는 로그인 후 사용하는 주 화면 영역 · `Shell` 껍데기·외곽. 여기서는 탭 바로 하위 화면을 감싸는 컨테이너 · `Router` 경로 지정자. 여기서는 탭·오버레이 화면 전환을 결정하는 역할 · `Feature` 기능·특징. 여기서는 TCA에서 State·Action·Reducer를 묶은 기능 단위(Reducer 타입)
- **`MainShellRouterFeature.State`** `struct` · public · [MainShellRouterFeature.swift:33](../../../sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift#L33) · 채택: Equatable, Sendable  
  메인 셸의 @ObservableState 상태로 selectedTab과 자식 상태 home·projectList·saved·settings, 옵셔널 singleQuestionEntry, @Presents singleQuestion을 보유한다.  
  단어(단일): `State` 상태. 여기서는 TCA Reducer가 관리하는 관찰 가능한 상태 값 묶음(@ObservableState struct)
- **`MainShellRouterFeature.Action`** `enum` · public · [MainShellRouterFeature.swift:46](../../../sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift#L46) · 채택: ViewAction, Sendable, Equatable  
  메인 셸 액션의 최상위 분류로 view·input·delegate와 자식 액션 home·projectList·saved·settings·singleQuestionEntry·singleQuestion(PresentationAction) 아홉 경우를 가진다.  
  단어(단일): `Action` 행동·동작. 여기서는 TCA Reducer에 전달되는 이벤트를 분류한 열거형
- **`MainShellRouterFeature.Action.Input`** `enum` · public · [MainShellRouterFeature.swift:59](../../../sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift#L59) · 채택: Sendable, Equatable  
  상위 Reducer에서 메인 셸로 주입하는 입력 액션으로 learningProjectsReloadRequested 하나를 가지며 reloadLearningProjects()로 홈과 프로젝트 목록 양쪽에 재조회를 전파한다.  
  단어(단일): `Input` 입력. 여기서는 외부(상위 Reducer)에서 이 기능으로 주입되는 액션 분류
- **`MainShellRouterFeature.Action.View`** `enum` · public · [MainShellRouterFeature.swift:64](../../../sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift#L64) · 채택: Sendable, Equatable  
  MainShellRouter 뷰에서 발생하는 이벤트 액션으로 tabSelected(MainShellTab) 하나를 가진다. 탭 선택 바인딩의 set에서 발송된다.  
  단어(단일): `View` 보기·화면. 여기서는 SwiftUI 화면에서 발생해 Reducer로 보내는 액션 분류
- **`MainShellRouterFeature.Action.Delegate`** `enum` · public · [MainShellRouterFeature.swift:69](../../../sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift#L69) · 채택: Sendable, Equatable  
  상위 Reducer에 전달하는 위임 액션으로 projectRegistrationRequested, projectDetailRequested(projectID:), learningRequested(projectID:nextSetID:), externalURLRequested(URL), loggedOut 다섯 경우를 가진다.  
  단어(단일): `Delegate` 위임·대리인. 여기서는 하위 기능이 처리 결과를 상위 Reducer에 넘기는 액션 분류
- **`MainShellTab`** `enum` · public · [MainShellTab.swift:3](../../../sources/Projects/Feature/MainShell/Router/MainShellTab.swift#L3) · 채택: String, CaseIterable, Hashable, Identifiable, Sendable, TabShellItem  
  메인 셸 탭 종류 home, projects, saved, settings를 나타내는 String 원시값 열거형으로 TabShellItem 채택을 통해 tabTitle("Home"·"프로젝트"·"저장"·"마이")과 tabSystemImage 아이콘 이름을 제공한다. MainShellRouterFeature.State.selectedTab과 TabShell 선택 값으로 쓰인다.  
  단어: `Main` 주요·메인. 여기서는 로그인 후 사용하는 주 화면 영역 · `Shell` 껍데기·외곽. 여기서는 탭 바로 하위 화면을 감싸는 컨테이너 · `Tab` 탭. 여기서는 탭 바의 항목 하나

## Onboarding/CareerSelection

- **`CareerSelectionFeature`** `struct` · public · [CareerSelectionFeature.swift:4](../../../sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionFeature.swift#L4) · 채택: Sendable  
  온보딩 큐레이션 단계에서 사용자의 경력 수준(CareerLevel)을 선택받아, 라우터가 미리 넣어 준 MemberPosition과 함께 Curation으로 묶어 생성자 주입된 updateCuration 클로저로 제출하는 TCA 리듀서(@Reducer). 제출 진행·실패 상태(Submission)를 관리하고 성공·뒤로가기를 Delegate 액션으로 OnboardingRouterFeature에 전달한다.  
  단어: `Career` 경력·직업 이력. 여기서는 사용자가 고르는 코드 이해 수준(CareerLevel: 입문·주니어·미들·시니어) · `Selection` 선택·고르기. 여기서는 온보딩 화면에서 경력 수준 하나를 고르는 행위 · `Feature` 기능 단위. 여기서는 TCA 컨벤션상 화면 하나의 State·Action·Reducer를 묶는 리듀서 타입
- **`CareerSelectionFeature.Submission`** `enum` · public · [CareerSelectionFeature.swift:15](../../../sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionFeature.swift#L15) · 채택: Equatable, Sendable  
  CareerSelectionFeature.State.submission이 갖는 큐레이션 제출 진행 상태로 idle·submitting·failed 세 경우를 가진다. submitting이면 재선택·뒤로가기·재제출을 막고, failed면 CareerSelectionScreen이 실패 안내 문구를 보여준다.  
  단어(단일): `Submission` 제출·제출 행위. 여기서는 Curation을 updateCuration으로 보내는 제출 작업의 진행 상태
- **`CareerSelectionFeature.State`** `struct` · public · [CareerSelectionFeature.swift:21](../../../sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionFeature.swift#L21) · 채택: Equatable, Sendable  
  CareerSelectionFeature의 관찰 가능 상태(@ObservableState)로 선택된 careerLevel(CareerLevel?), 제출 상태 submission, 그리고 OnboardingRouterFeature가 이전 단계 결과로 채워 주는 내부 접근 position(MemberPosition?)을 보유한다.  
  단어(단일): `State` 상태·현재 값. 여기서는 CareerSelectionFeature이 보유하는 TCA 관찰 가능 상태(@ObservableState) 구조체
- **`CareerSelectionFeature.Action`** `enum` · public · [CareerSelectionFeature.swift:31](../../../sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionFeature.swift#L31) · 채택: ViewAction, Sendable, Equatable  
  CareerSelectionFeature의 액션 루트로 view(View)·effect(EffectEvent)·delegate(Delegate) 세 하위 케이스 그룹을 감싸며, ViewAction을 채택해 @ViewAction 화면의 send(_:)가 View 케이스를 직접 보내게 한다.  
  단어(단일): `Action` 행위·동작. 여기서는 CareerSelectionFeature에 보내는 TCA 액션의 루트 열거형
- **`CareerSelectionFeature.Action.View`** `enum` · public · [CareerSelectionFeature.swift:38](../../../sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionFeature.swift#L38) · 채택: Sendable, Equatable  
  CareerSelectionScreen이 보내는 사용자 입력 액션 묶음(@CasePathable)으로 careerLevelSelected(CareerLevel)·submitTapped·backTapped 세 케이스를 가진다.  
  단어(단일): `View` 보기·화면. 여기서는 CareerSelectionScreen 화면의 사용자 입력(탭·선택)을 표현하는 액션 묶음
- **`CareerSelectionFeature.Action.EffectEvent`** `enum` · public · [CareerSelectionFeature.swift:45](../../../sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionFeature.swift#L45) · 채택: Sendable, Equatable  
  updateCuration 비동기 effect의 완료 결과를 리듀서로 되돌리는 액션 묶음(@CasePathable)으로 curationFinished(success: Bool) 하나를 가진다. 성공이면 submission을 idle로 되돌리고 curationSucceeded를 위임하며 실패면 failed로 바꾼다.  
  단어: `Effect` 부수 효과·비동기 작업. 여기서는 CareerSelectionFeature이 실행한 비동기 effect · `Event` 사건·발생한 일. 여기서는 effect가 끝나며 리듀서로 되돌리는 결과 액션
- **`CareerSelectionFeature.Action.Delegate`** `enum` · public · [CareerSelectionFeature.swift:50](../../../sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionFeature.swift#L50) · 채택: Sendable, Equatable  
  부모 OnboardingRouterFeature에게 알리는 액션 묶음(@CasePathable)으로 curationSucceeded(큐레이션 저장 성공)와 backRequested(이전 단계인 분야 선택으로 돌아가기 요청)를 가진다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 CareerSelectionFeature이 부모 리듀서(OnboardingRouterFeature)에게 결과를 위임해 알리는 액션 묶음
- **`CareerSelectionFeature.CancelID`** `enum` · private · [CareerSelectionFeature.swift:102](../../../sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionFeature.swift#L102) · 채택: Hashable  
  updateCuration 실행 effect를 .cancellable(id:)로 묶을 때 쓰는 취소 식별자로 curation 케이스 하나만 가진다.  
  단어: `Cancel` 취소. 여기서는 CareerSelectionFeature의 실행 중 effect를 취소하는 동작 · `ID` Identifier(식별자). 여기서는 .cancellable(id:)에 넘기는 effect 취소 식별자
- **`CareerSelectionScreen`** `struct` · internal · [CareerSelectionScreen.swift:10](../../../sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionScreen.swift#L10) · 채택: View · 그래프 미수집(grep 보강)  
  CareerSelectionFeature 스토어(@Bindable StoreOf)를 바인딩해 경력 수준 선택 화면을 그리는 SwiftUI View(@ViewAction). OverlayContainer 안에 뒤로가기 ScreenControlBar, 제목·제출 실패 안내·SelectionCardList, 하단 BottomActionBar의 안내 문구와 '다음' ActionButton을 배치하며 OnboardingRouter가 생성한다.  
  단어: `Career` 경력·직업 이력. 여기서는 사용자가 고르는 코드 이해 수준(CareerLevel) · `Selection` 선택·고르기. 여기서는 SelectionCardList로 경력 수준 하나를 고르는 행위 · `Screen` 화면. 여기서는 View 컨벤션상 라우터가 표시하는 단일 화면 SwiftUI View
- **`CareerSelectionScreen.Display`** `enum` · fileprivate · [CareerSelectionScreen.swift:73](../../../sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionScreen.swift#L73)  
  CareerSelectionScreen이 CareerLevel을 화면 표시 값으로 바꾸는 파일 전용 네임스페이스로 표시 순서(orderedLevels), 케이스별 카드 식별자·제목·설명·일러스트(ResourceImage.Asset.Illust) 매핑과 식별자→CareerLevel 역변환(level(forIdentifier:))을 정적 함수로 제공한다.  
  단어(단일): `Display` 표시·화면에 보이기. 여기서는 CareerSelectionScreen이 CareerLevel 도메인 값을 카드 식별자·제목 등 표시용 값으로 변환하는 파일 전용 네임스페이스
- **`CareerSelectionScreen.Constant`** `enum` · fileprivate · [CareerSelectionScreen.swift:117](../../../sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionScreen.swift#L117)  
  CareerSelectionScreen 전용 고정 값 네임스페이스로 화면 제목(title)·안내 문구(guidance) 문자열과 제목-옵션 간 간격(titleToOptionsSpacing: 64) 값을 보관한다.  
  단어(단일): `Constant` 상수·고정 값. 여기서는 CareerSelectionScreen 전용 문구·레이아웃 고정 값 네임스페이스

## Onboarding/LegalAgreement

- **`LegalAgreementFeature`** `struct` · public · [LegalAgreementFeature.swift:5](../../../sources/Projects/Feature/Onboarding/LegalAgreement/LegalAgreementFeature.swift#L5) · 채택: Sendable  
  온보딩 약관 동의 시트를 담당하는 TCA 리듀서(@Reducer)로 생성자 주입된 policyConsentStatus로 필수 정책 문서 목록과 저장된 동의 유효성을 불러오고, 문서별·전체 선택 토글과 문서 열람 시트 표시 상태를 관리하며, 계속 시 선택한 PolicyDocumentID 목록을 consent 클로저로 제출한 뒤 consentCompleted를 위임한다.  
  단어: `Legal` 법적·법률상의. 여기서는 개인정보 처리방침·이용 약관 같은 법적 정책 문서(PolicyDocument) · `Agreement` 동의·합의. 여기서는 사용자가 정책 문서에 동의(consent)하는 행위 · `Feature` 기능 단위. 여기서는 TCA 컨벤션상 시트 하나의 State·Action·Reducer를 묶는 리듀서 타입
- **`LegalAgreementFeature.State`** `struct` · public · [LegalAgreementFeature.swift:20](../../../sources/Projects/Feature/Onboarding/LegalAgreement/LegalAgreementFeature.swift#L20) · 채택: Equatable, Sendable  
  LegalAgreementFeature의 관찰 가능 상태(@ObservableState)로 requiredDocuments([PolicyDocument]), isStoredConsentValid, selectedDocumentIDs(Set<PolicyDocumentID>), presentedDocumentID를 보유하고, 이를 바탕으로 presentedDocument·isAllSelected·canContinue(필수 문서가 모두 선택됐는지)를 계산 프로퍼티로 제공한다.  
  단어(단일): `State` 상태·현재 값. 여기서는 LegalAgreementFeature이 보유하는 TCA 관찰 가능 상태(@ObservableState) 구조체
- **`LegalAgreementFeature.Action`** `enum` · public · [LegalAgreementFeature.swift:52](../../../sources/Projects/Feature/Onboarding/LegalAgreement/LegalAgreementFeature.swift#L52) · 채택: ViewAction, Sendable, Equatable  
  LegalAgreementFeature의 액션 루트로 view(View)·effect(EffectEvent)·input(Input)·delegate(Delegate) 네 하위 케이스 그룹을 감싸며 ViewAction을 채택한다.  
  단어(단일): `Action` 행위·동작. 여기서는 LegalAgreementFeature에 보내는 TCA 액션의 루트 열거형
- **`LegalAgreementFeature.Action.View`** `enum` · public · [LegalAgreementFeature.swift:60](../../../sources/Projects/Feature/Onboarding/LegalAgreement/LegalAgreementFeature.swift#L60) · 채택: Sendable, Equatable  
  LegalAgreementScreen이 보내는 사용자 입력 액션 묶음(@CasePathable)으로 documentToggled(documentID:)·allDocumentsToggled·documentLinkTapped(documentID:)·documentSheetDismissed·cancelTapped·continueTapped 여섯 케이스를 가진다.  
  단어(단일): `View` 보기·화면. 여기서는 LegalAgreementScreen 화면의 사용자 입력(탭·선택)을 표현하는 액션 묶음
- **`LegalAgreementFeature.Action.EffectEvent`** `enum` · public · [LegalAgreementFeature.swift:70](../../../sources/Projects/Feature/Onboarding/LegalAgreement/LegalAgreementFeature.swift#L70) · 채택: Sendable, Equatable  
  policyConsentStatus 비동기 effect의 결과를 리듀서로 되돌리는 액션 묶음(@CasePathable)으로 statusLoaded(requiredDocuments:isStoredConsentValid:) 하나를 가지며, 수신 시 State의 문서 목록과 저장된 동의 유효성을 갱신한다.  
  단어: `Effect` 부수 효과·비동기 작업. 여기서는 LegalAgreementFeature이 실행한 비동기 effect · `Event` 사건·발생한 일. 여기서는 effect가 끝나며 리듀서로 되돌리는 결과 액션
- **`LegalAgreementFeature.Action.Input`** `enum` · public · [LegalAgreementFeature.swift:75](../../../sources/Projects/Feature/Onboarding/LegalAgreement/LegalAgreementFeature.swift#L75) · 채택: Sendable, Equatable  
  부모 OnboardingRouterFeature가 자식 LegalAgreementFeature에 내려보내는 액션 묶음(@CasePathable)으로 load(문서 목록이 비어 있을 때 정책 동의 상태 조회 시작)와 prepare(선택 문서 ID 초기화)를 가진다.  
  단어(단일): `Input` 입력·투입. 여기서는 부모 리듀서가 자식에게 지시로 넣어 주는 액션 묶음(사용자 입력인 View와 구분)
- **`LegalAgreementFeature.Action.Delegate`** `enum` · public · [LegalAgreementFeature.swift:81](../../../sources/Projects/Feature/Onboarding/LegalAgreement/LegalAgreementFeature.swift#L81) · 채택: Sendable, Equatable  
  부모 OnboardingRouterFeature에게 알리는 액션 묶음(@CasePathable)으로 consentCompleted(동의 제출 완료)와 cancelled(취소 탭 또는 시트 닫힘)를 가진다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 LegalAgreementFeature이 부모 리듀서(OnboardingRouterFeature)에게 결과를 위임해 알리는 액션 묶음
- **`LegalAgreementScreen`** `struct` · internal · [LegalAgreementScreen.swift:10](../../../sources/Projects/Feature/Onboarding/LegalAgreement/LegalAgreementScreen.swift#L10) · 채택: View · 그래프 미수집(grep 보강)  
  LegalAgreementFeature 스토어(@Bindable StoreOf)를 바인딩해 약관 동의 시트를 그리는 SwiftUI View(@ViewAction). 스크롤 가능한 SheetSurface 안에 '약관 동의' 제목, AllAgreementRow, 문서별 PolicyAgreementRow 목록, 취소·다음 ActionButton을 배치하며 OnboardingRouter가 시트로 띄운다.  
  단어: `Legal` 법적·법률상의. 여기서는 법적 정책 문서(PolicyDocument) · `Agreement` 동의·합의. 여기서는 정책 문서에 동의하는 행위 · `Screen` 화면. 여기서는 View 컨벤션상 라우터가 시트로 표시하는 단일 화면 SwiftUI View
- **`LegalAgreementScreen.Constant`** `enum` · fileprivate · [LegalAgreementScreen.swift:59](../../../sources/Projects/Feature/Onboarding/LegalAgreement/LegalAgreementScreen.swift#L59)  
  LegalAgreementScreen 전용 고정 레이아웃 값 네임스페이스로 actionsTopSpacing(25)·titleBottomSpacing(10)·documentsTopSpacing(7)·documentRowLeadingPadding(17)을 보관한다.  
  단어(단일): `Constant` 상수·고정 값. 여기서는 LegalAgreementScreen 전용 문구·레이아웃 고정 값 네임스페이스

## Onboarding/LegalAgreement/SubViews

- **`LegalAgreementScreen.AllAgreementRow`** `struct` · internal · [LegalAgreementScreen+AllAgreementRow.swift:6](../../../sources/Projects/Feature/Onboarding/LegalAgreement/SubViews/LegalAgreementScreen+AllAgreementRow.swift#L6) · 채택: View  
  LegalAgreementScreen의 하위 뷰로 '전체 동의' 한 줄을 그리는 SwiftUI View. isSelected에 따라 statusCheck·statusDisabled 아이콘과 색을 바꾸고, 행 전체가 Button이라 탭 시 onToggle 클로저를 호출한다.  
  단어: `All` 전체·모두. 여기서는 필수 정책 문서 전부를 한 번에 선택·해제하는 대상 · `Agreement` 동의·합의. 여기서는 정책 문서 동의 행위 · `Row` 행·한 줄. 여기서는 목록 위에 놓이는 한 줄짜리 토글 뷰
- **`LegalAgreementScreen.AllAgreementRow.Constant`** `enum` · private · [LegalAgreementScreen+AllAgreementRow.swift:34](../../../sources/Projects/Feature/Onboarding/LegalAgreement/SubViews/LegalAgreementScreen+AllAgreementRow.swift#L34)  
  AllAgreementRow 전용 고정 값 네임스페이스로 '전체 동의' 제목 문자열과 rowHeight(54)·checkSize(24)·checkSpacing(12)·rowHorizontalPadding(17)을 보관한다.  
  단어(단일): `Constant` 상수·고정 값. 여기서는 AllAgreementRow 전용 문구·레이아웃 고정 값 네임스페이스

## Onboarding/PositionSelection

- **`PositionSelectionFeature`** `struct` · public · [PositionSelectionFeature.swift:5](../../../sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionFeature.swift#L5) · 채택: Sendable  
  온보딩 큐레이션 첫 단계에서 학습할 분야(MemberPosition)를 선택받아 다음 탭 시 Delegate confirmed로 부모에 넘기고, 닫기(backTapped) 시 생성자 주입된 signOut 클로저로 로그아웃을 수행해 SignOutResult에 따라 exitRequested를 위임하거나 failed 상태를 표시하는 TCA 리듀서(@Reducer).  
  단어: `Position` 위치·직무. 여기서는 사용자가 학습할 개발 분야(MemberPosition: frontend·backend·ios·android) · `Selection` 선택·고르기. 여기서는 온보딩 화면에서 분야 하나를 고르는 행위 · `Feature` 기능 단위. 여기서는 TCA 컨벤션상 화면 하나의 State·Action·Reducer를 묶는 리듀서 타입
- **`PositionSelectionFeature.ExitStatus`** `enum` · public · [PositionSelectionFeature.swift:16](../../../sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionFeature.swift#L16) · 채택: Equatable, Sendable  
  PositionSelectionFeature.State.exitStatus가 갖는 온보딩 이탈(로그아웃) 진행 상태로 idle·inProgress·failed 세 경우를 가진다. inProgress면 중복 닫기 요청을 막고 failed면 PositionSelectionScreen이 실패 안내 문구를 보여준다.  
  단어: `Exit` 나가기·이탈. 여기서는 닫기 버튼으로 온보딩을 벗어나며 signOut을 수행하는 동작 · `Status` 상태·진행 상황. 여기서는 이탈 작업의 idle·inProgress·failed 진행 상태
- **`PositionSelectionFeature.State`** `struct` · public · [PositionSelectionFeature.swift:22](../../../sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionFeature.swift#L22) · 채택: Equatable, Sendable  
  PositionSelectionFeature의 관찰 가능 상태(@ObservableState)로 선택된 position(MemberPosition?)과 이탈 진행 상태 exitStatus(ExitStatus)를 보유한다.  
  단어(단일): `State` 상태·현재 값. 여기서는 PositionSelectionFeature이 보유하는 TCA 관찰 가능 상태(@ObservableState) 구조체
- **`PositionSelectionFeature.Action`** `enum` · public · [PositionSelectionFeature.swift:30](../../../sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionFeature.swift#L30) · 채택: ViewAction, Sendable, Equatable  
  PositionSelectionFeature의 액션 루트로 view(View)·effect(EffectEvent)·delegate(Delegate) 세 하위 케이스 그룹을 감싸며 ViewAction을 채택한다.  
  단어(단일): `Action` 행위·동작. 여기서는 PositionSelectionFeature에 보내는 TCA 액션의 루트 열거형
- **`PositionSelectionFeature.Action.View`** `enum` · public · [PositionSelectionFeature.swift:37](../../../sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionFeature.swift#L37) · 채택: Sendable, Equatable  
  PositionSelectionScreen이 보내는 사용자 입력 액션 묶음(@CasePathable)으로 positionSelected(MemberPosition)·nextTapped·backTapped 세 케이스를 가진다.  
  단어(단일): `View` 보기·화면. 여기서는 PositionSelectionScreen 화면의 사용자 입력(탭·선택)을 표현하는 액션 묶음
- **`PositionSelectionFeature.Action.EffectEvent`** `enum` · public · [PositionSelectionFeature.swift:44](../../../sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionFeature.swift#L44) · 채택: Sendable, Equatable  
  signOut 비동기 effect의 결과를 리듀서로 되돌리는 액션 묶음(@CasePathable)으로 signOutFinished(SignOutResult) 하나를 가진다. signedOut이면 exitRequested를 위임하고 retryableFailure면 exitStatus를 failed로 바꾼다.  
  단어: `Effect` 부수 효과·비동기 작업. 여기서는 PositionSelectionFeature이 실행한 비동기 effect · `Event` 사건·발생한 일. 여기서는 effect가 끝나며 리듀서로 되돌리는 결과 액션
- **`PositionSelectionFeature.Action.Delegate`** `enum` · public · [PositionSelectionFeature.swift:49](../../../sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionFeature.swift#L49) · 채택: Sendable, Equatable  
  부모 OnboardingRouterFeature에게 알리는 액션 묶음(@CasePathable)으로 confirmed(MemberPosition)(분야 확정, 라우터가 CareerSelectionFeature.State.position에 넣음)와 exitRequested(로그아웃 성공 후 온보딩 이탈 요청)를 가진다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 PositionSelectionFeature이 부모 리듀서(OnboardingRouterFeature)에게 결과를 위임해 알리는 액션 묶음
- **`PositionSelectionFeature.CancelID`** `enum` · private · [PositionSelectionFeature.swift:95](../../../sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionFeature.swift#L95) · 채택: Hashable  
  signOut 실행 effect를 .cancellable(id:cancelInFlight:)로 묶을 때 쓰는 취소 식별자로 exit 케이스 하나만 가진다.  
  단어: `Cancel` 취소. 여기서는 PositionSelectionFeature의 실행 중 effect를 취소하는 동작 · `ID` Identifier(식별자). 여기서는 .cancellable(id:)에 넘기는 effect 취소 식별자
- **`PositionSelectionScreen`** `struct` · internal · [PositionSelectionScreen.swift:10](../../../sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionScreen.swift#L10) · 채택: View · 그래프 미수집(grep 보강)  
  PositionSelectionFeature 스토어(@Bindable StoreOf)를 바인딩해 분야 선택 화면을 그리는 SwiftUI View(@ViewAction). OverlayContainer 안에 닫기 ScreenControlBar, 제목·이탈 실패 안내·compact 스타일 SelectionCardList, 하단 BottomActionBar의 '다음' ActionButton을 배치하며 OnboardingRouter가 생성한다.  
  단어: `Position` 위치·직무. 여기서는 사용자가 학습할 개발 분야(MemberPosition) · `Selection` 선택·고르기. 여기서는 SelectionCardList로 분야 하나를 고르는 행위 · `Screen` 화면. 여기서는 View 컨벤션상 라우터가 표시하는 단일 화면 SwiftUI View
- **`PositionSelectionScreen.Display`** `enum` · fileprivate · [PositionSelectionScreen.swift:70](../../../sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionScreen.swift#L70)  
  PositionSelectionScreen이 MemberPosition을 화면 표시 값으로 바꾸는 파일 전용 네임스페이스로 표시 순서(orderedPositions), 케이스별 카드 식별자·제목(iOS·Android·Back-end·Front-end) 매핑과 식별자→MemberPosition 역변환(position(forIdentifier:))을 정적 함수로 제공한다.  
  단어(단일): `Display` 표시·화면에 보이기. 여기서는 PositionSelectionScreen이 MemberPosition 도메인 값을 카드 식별자·제목 등 표시용 값으로 변환하는 파일 전용 네임스페이스
- **`PositionSelectionScreen.Constant`** `enum` · fileprivate · [PositionSelectionScreen.swift:100](../../../sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionScreen.swift#L100)  
  PositionSelectionScreen 전용 고정 값 네임스페이스로 화면 제목(title) 문자열과 제목-옵션 간 간격(titleToOptionsSpacing: 64) 값을 보관한다.  
  단어(단일): `Constant` 상수·고정 값. 여기서는 PositionSelectionScreen 전용 문구·레이아웃 고정 값 네임스페이스

## Onboarding/Previews

- **`OnboardingPreviewSupport`** `enum` · internal · [OnboardingPreviewSupport.swift:4](../../../sources/Projects/Feature/Onboarding/Previews/OnboardingPreviewSupport.swift#L4)  
  온보딩 SwiftUI 프리뷰가 공유하는 샘플 데이터 네임스페이스로 개인정보 처리방침·서비스 이용 약관 두 개의 PolicyDocument 배열(requiredDocuments)만 정적으로 제공하며 LegalAgreementScreenPreviews에서 사용한다.  
  단어: `Onboarding` On + boarding, 신규 사용자 안내·가입 절차. 여기서는 Feature 패키지의 Onboarding 관심사(약관 동의·분야·경력 선택 흐름) · `Preview` 미리 보기. 여기서는 Xcode SwiftUI #Preview 렌더링 · `Support` 지원·보조. 여기서는 프리뷰 전용 샘플 데이터를 제공하는 보조 네임스페이스

## Onboarding/Router

- **`OnboardingExitFeature`** `struct` · public · [OnboardingExitFeature.swift:6](../../../sources/Projects/Feature/Onboarding/Router/OnboardingExitFeature.swift#L6) · 채택: Sendable  
  @Reducer로 선언된 온보딩 종료 Reducer로, input(.curationSucceeded)를 받으면 delegate(.shouldExit)를 보내는 것이 유일한 책임이다. OnboardingRouterFeature가 Scope로 포함해 shouldExit를 받으면 activeScreen을 curationSplash로 바꾼다.  
  단어: `Onboarding` On + boarding, 신규 사용자를 서비스에 태우는 안내·가입 절차. 여기서는 튜토리얼·약관 동의·직무/경력 선택으로 이어지는 앱 최초 진입 흐름 · `Exit` 나감·종료. 여기서는 큐레이션 완료 뒤 온보딩 흐름을 빠져나가는 단계 · `Feature` 기능·특징. 여기서는 TCA @Reducer로 상태·액션·효과를 묶은 기능 단위(Reducer 타입)의 프로젝트 관용 접미어
- **`OnboardingExitFeature.State`** `struct` · public · [OnboardingExitFeature.swift:15](../../../sources/Projects/Feature/Onboarding/Router/OnboardingExitFeature.swift#L15) · 채택: Equatable, Sendable  
  @ObservableState가 적용된 OnboardingExitFeature의 상태로, 저장 프로퍼티가 없는 빈 구조체다. OnboardingRouterFeature.State의 exit 프로퍼티로 보유된다.  
  단어(단일): `State` 상태. 여기서는 TCA Reducer가 보유하는 관찰 가능한 상태 구조체
- **`OnboardingExitFeature.Action`** `enum` · public · [OnboardingExitFeature.swift:20](../../../sources/Projects/Feature/Onboarding/Router/OnboardingExitFeature.swift#L20) · 채택: Sendable, Equatable  
  OnboardingExitFeature가 처리하는 액션으로 input(Input)과 delegate(Delegate) 두 케이스를 가진다. 부모 OnboardingRouterFeature.Action의 exit 케이스에 감싸여 전달된다.  
  단어(단일): `Action` 동작·행위. 여기서는 TCA Reducer가 처리하는 액션 열거형
- **`OnboardingExitFeature.Action.Input`** `enum` · public · [OnboardingExitFeature.swift:26](../../../sources/Projects/Feature/Onboarding/Router/OnboardingExitFeature.swift#L26) · 채택: Sendable, Equatable  
  @CasePathable 입력 액션으로 curationSucceeded 케이스 하나만 가진다. OnboardingRouterFeature가 careerSelection의 curationSucceeded delegate를 받았을 때 exit(.input(.curationSucceeded))로 보낸다.  
  단어(단일): `Input` 입력. 여기서는 부모 Reducer가 자식 Reducer에 명령으로 보내는 입력 액션 묶음
- **`OnboardingExitFeature.Action.Delegate`** `enum` · public · [OnboardingExitFeature.swift:31](../../../sources/Projects/Feature/Onboarding/Router/OnboardingExitFeature.swift#L31) · 채택: Sendable, Equatable  
  @CasePathable 위임 액션으로 shouldExit 케이스 하나만 가진다. OnboardingRouterFeature가 이를 받아 activeScreen을 curationSplash로 전환한다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 자식 Reducer가 결과를 부모 Reducer에 알리는 위임 액션 묶음
- **`OnboardingRouter`** `struct` · public · [OnboardingRouter.swift:5](../../../sources/Projects/Feature/Onboarding/Router/OnboardingRouter.swift#L5) · 채택: View  
  @ViewAction(for: OnboardingRouterFeature.self)이 적용된 온보딩 루트 View로, StoreOf<OnboardingRouterFeature>를 보유하고 activeScreen에 따라 FlowNavigationStack 경로를 계산해 TutorialScreen 위에 PositionSelectionScreen·CareerSelectionScreen·CurationSplashView를 push한다. LegalAgreementScreen과 WebSheet는 ModalOverlay로 띄우며 AppRootView가 onboarding 스코프로 생성한다.  
  단어: `Onboarding` On + boarding, 신규 사용자를 서비스에 태우는 안내·가입 절차. 여기서는 튜토리얼·약관 동의·직무/경력 선택으로 이어지는 앱 최초 진입 흐름 · `Router` 경로 지정자·중계기. 여기서는 온보딩 하위 화면들 사이의 내비게이션 경로를 계산해 배치하는 컨테이너 View
- **`OnboardingRouterFeature`** `struct` · public · [OnboardingRouterFeature.swift:6](../../../sources/Projects/Feature/Onboarding/Router/OnboardingRouterFeature.swift#L6) · 채택: Sendable  
  @Reducer로 선언된 온보딩 라우팅 Reducer로 TutorialFeature·LegalAgreementFeature·PositionSelectionFeature·CareerSelectionFeature·OnboardingExitFeature를 Scope로 합성하고, signIn·signOut·policyConsentStatus·consent·updateCuration·withdraw 클로저를 생성자 주입으로 받는다. 자식 delegate와 view 액션에 따라 activeScreen을 전환하고 변경마다 transitionLog에 ScreenTransitionEvent를 기록하며, 완료 시 delegate(.mainShellRequested)를 보낸다.  
  단어: `Onboarding` On + boarding, 신규 사용자를 서비스에 태우는 안내·가입 절차. 여기서는 튜토리얼·약관 동의·직무/경력 선택으로 이어지는 앱 최초 진입 흐름 · `Router` 경로 지정자·중계기. 여기서는 온보딩 하위 Reducer들 사이의 화면 전환 규칙을 결정하는 상위 Reducer · `Feature` 기능·특징. 여기서는 TCA @Reducer로 상태·액션·효과를 묶은 기능 단위(Reducer 타입)의 프로젝트 관용 접미어
- **`OnboardingRouterFeature.ActiveScreen`** `enum` · public · [OnboardingRouterFeature.swift:31](../../../sources/Projects/Feature/Onboarding/Router/OnboardingRouterFeature.swift#L31) · 채택: Hashable, Sendable  
  현재 활성화된 온보딩 화면을 나타내는 열거형으로 guide(Guide)·curation(Curation)·curationSplash 세 케이스를 가진다. State.activeScreen과 ScreenTransitionEvent의 from/to에 저장되며 OnboardingRouter가 이 값으로 push 경로를 계산한다.  
  단어: `Active` 활성·현재 동작 중인. 여기서는 지금 사용자에게 표시되고 있는 · `Screen` 화면. 여기서는 사용자가 보는 온보딩 화면 단위
- **`OnboardingRouterFeature.ActiveScreen.Guide`** `enum` · public · [OnboardingRouterFeature.swift:36](../../../sources/Projects/Feature/Onboarding/Router/OnboardingRouterFeature.swift#L36) · 채택: Hashable, Sendable  
  ActiveScreen.guide에 연관되는 안내 단계 화면으로 tutorial과 legalAgreement 케이스를 가진다. OnboardingEntryPoint.guide로 시작하면 guide(.tutorial)이 초기 화면이 되고, legalAgreement일 때 OnboardingRouter가 LegalAgreementScreen 오버레이를 표시한다.  
  단어(단일): `Guide` 안내·지침. 여기서는 로그인 전 튜토리얼과 약관 동의로 이루어진 온보딩 안내 단계
- **`OnboardingRouterFeature.ActiveScreen.Curation`** `enum` · public · [OnboardingRouterFeature.swift:41](../../../sources/Projects/Feature/Onboarding/Router/OnboardingRouterFeature.swift#L41) · 채택: Hashable, Sendable  
  ActiveScreen.curation에 연관되는 큐레이션 단계 화면으로 positionSelection과 careerSelection 케이스를 가진다. 같은 파일에서 updateCuration 클로저가 받는 DomainUserInfo의 Curation 도메인 타입과 이름이 같으며, 중첩 위치로 구분된다.  
  단어(단일): `Curation` 큐레이션·선별. 여기서는 직무(position)와 경력(career)을 골라 맞춤 설정하는 온보딩 단계의 화면 구분
- **`OnboardingRouterFeature.ScreenTransitionEvent`** `struct` · public · [OnboardingRouterFeature.swift:47](../../../sources/Projects/Feature/Onboarding/Router/OnboardingRouterFeature.swift#L47) · 채택: Equatable, Sendable  
  화면 전환 기록 하나를 나타내는 값으로 from·to(ActiveScreen)와 trigger(String) 세 상수를 가진다. Reduce에서 activeScreen이 바뀔 때마다 String(describing: action)을 trigger로 삼아 State.transitionLog에 추가된다.  
  단어: `Screen` 화면. 여기서는 사용자가 보는 온보딩 화면 단위 · `Transition` 전환·이행. 여기서는 activeScreen 값이 한 화면에서 다른 화면으로 바뀌는 것 · `Event` 사건·발생 기록. 여기서는 전환 한 건을 기록한 값 객체
- **`OnboardingRouterFeature.State`** `struct` · public · [OnboardingRouterFeature.swift:53](../../../sources/Projects/Feature/Onboarding/Router/OnboardingRouterFeature.swift#L53) · 채택: Equatable, Sendable  
  @ObservableState가 적용된 OnboardingRouterFeature의 상태로 activeScreen, 자식 상태(tutorial·legalAgreement·positionSelection·careerSelection·exit), transitionLog를 보유한다. init(startingAt:bundleVersion:)이 OnboardingEntryPoint에 따라 초기 activeScreen을 guide(.tutorial) 또는 curation(.positionSelection)으로 정한다.  
  단어(단일): `State` 상태. 여기서는 TCA Reducer가 보유하는 관찰 가능한 상태 구조체
- **`OnboardingRouterFeature.Action`** `enum` · public · [OnboardingRouterFeature.swift:84](../../../sources/Projects/Feature/Onboarding/Router/OnboardingRouterFeature.swift#L84) · 채택: ViewAction, Sendable, Equatable  
  OnboardingRouterFeature가 처리하는 액션으로 view(View)와 자식 액션 래퍼(tutorial·legalAgreement·positionSelection·careerSelection·exit), delegate(Delegate) 케이스를 가진다. ViewAction 채택으로 OnboardingRouter의 send가 view 케이스로 매핑된다.  
  단어(단일): `Action` 동작·행위. 여기서는 TCA Reducer가 처리하는 액션 열거형
- **`OnboardingRouterFeature.Action.View`** `enum` · public · [OnboardingRouterFeature.swift:93](../../../sources/Projects/Feature/Onboarding/Router/OnboardingRouterFeature.swift#L93) · 채택: Sendable, Equatable  
  @CasePathable 뷰 액션으로 curationSplashFinished·legalAgreementDismissed·legalDocumentSheetDismissed 케이스를 가진다. OnboardingRouter의 SplashView 완료 콜백과 ModalOverlay onDismiss에서 send된다.  
  단어(단일): `View` 보기·화면. 여기서는 SwiftUI View가 사용자 상호작용으로 보내는 액션 묶음(TCA ViewAction)
- **`OnboardingRouterFeature.Action.Delegate`** `enum` · public · [OnboardingRouterFeature.swift:100](../../../sources/Projects/Feature/Onboarding/Router/OnboardingRouterFeature.swift#L100) · 채택: Sendable, Equatable  
  @CasePathable 위임 액션으로 mainShellRequested 케이스 하나만 가진다. 큐레이션이 필요 없는 로그인 성공 시 또는 curationSplash가 끝났을 때 상위(AppRoot)에 메인 셸 진입을 요청한다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 자식 Reducer가 결과를 부모 Reducer에 알리는 위임 액션 묶음

## Onboarding/Router/SubViews

- **`OnboardingRouter.CurationSplashView`** `struct` · internal · [OnboardingRouter+CurationSplashView.swift:6](../../../sources/Projects/Feature/Onboarding/Router/SubViews/OnboardingRouter+CurationSplashView.swift#L6) · 채택: View  
  OnboardingRouter의 확장으로 선언된 내부 View로 onCompletion 클로저를 받아 UIComponent의 SplashView를 ScreenContainer와 designSystemScreenMargin으로 감싼다. activeScreen이 curationSplash일 때 push되며 완료 시 curationSplashFinished 뷰 액션을 보낸다.  
  단어: `Curation` 큐레이션·선별. 여기서는 직무·경력 선택 단계가 끝난 뒤를 뜻함 · `Splash` 스플래시(짧게 보여 주는 전환 화면). 여기서는 큐레이션 완료 뒤 메인 진입 전에 잠시 표시되는 화면 · `View` 보기·화면. 여기서는 SwiftUI View 타입

## Onboarding/Tutorial/SubViews

- **`TutorialScreen.PageView`** `struct` · internal · [TutorialScreen+PageView.swift:6](../../../sources/Projects/Feature/Onboarding/Tutorial/SubViews/TutorialScreen+PageView.swift#L6) · 채택: View  
  TutorialScreen의 확장으로 선언된 내부 View로 page(Int)를 받아 Constant.title(for:)의 제목 StyledText와 OnboardingMockup(page:)을 세로로 배치한다. TutorialScreen의 TabView가 페이지 1...totalPages마다 생성한다.  
  단어: `Page` 쪽·페이지. 여기서는 튜토리얼 TabView의 한 페이지 · `View` 보기·화면. 여기서는 SwiftUI View 타입
- **`TutorialScreen.PageView.Constant`** `enum` · private · [TutorialScreen+PageView.swift:28](../../../sources/Projects/Feature/Onboarding/Tutorial/SubViews/TutorialScreen+PageView.swift#L28)  
  PageView 전용 상수 네임스페이스로 titleTopInset(68)·mockupWidth(212)와 페이지 번호별 안내 문구를 돌려주는 title(for:) 정적 함수를 가진다.  
  단어(단일): `Constant` 상수. 여기서는 레이아웃 수치·고정 문구를 모아 둔 private 네임스페이스 enum
- **`TutorialScreen.SignInSection`** `struct` · internal · [TutorialScreen+SignInSection.swift:6](../../../sources/Projects/Feature/Onboarding/Tutorial/SubViews/TutorialScreen+SignInSection.swift#L6) · 채택: View  
  TutorialScreen의 확장으로 선언된 내부 View로 currentPage·totalPages·bundleVersion·isHintVisible·onAppleSignIn을 받아 PageIndicator, 가입 힌트 캡션, AppleSignInButton, 버전 텍스트를 세로로 배치한다. TutorialScreen 하단에 배치된다.  
  단어: `SignIn` Sign + In, 로그인. 여기서는 Apple 로그인 버튼이 있는 영역 · `Section` 구역·부분. 여기서는 튜토리얼 화면 하단 로그인 영역
- **`TutorialScreen.SignInSection.Constant`** `enum` · private · [TutorialScreen+SignInSection.swift:37](../../../sources/Projects/Feature/Onboarding/Tutorial/SubViews/TutorialScreen+SignInSection.swift#L37)  
  SignInSection 전용 상수 네임스페이스로 hintTitle("3초만에 가입하기")·indicatorPadding(12)·versionTopSpacing(21)·bottomInset(29)를 가진다.  
  단어(단일): `Constant` 상수. 여기서는 레이아웃 수치·고정 문구를 모아 둔 private 네임스페이스 enum

## Onboarding/Tutorial

- **`TutorialFeature`** `struct` · public · [TutorialFeature.swift:4](../../../sources/Projects/Feature/Onboarding/Tutorial/TutorialFeature.swift#L4) · 채택: Sendable  
  @Reducer로 선언된 튜토리얼 Reducer로 signIn·withdraw 클로저와 deletesCompletedAccountOnSignIn 플래그를 생성자 주입으로 받는다. 페이지 전환, Apple 로그인 시작·완료(requestID로 응답 검증), 완료 계정 재설정 재시도 로직을 처리하고 appeared·signInRequested·signInSucceeded를 부모에 위임한다.  
  단어: `Tutorial` 지침·안내 학습. 여기서는 앱 기능을 소개하는 3페이지 안내 화면 · `Feature` 기능·특징. 여기서는 TCA @Reducer로 상태·액션·효과를 묶은 기능 단위(Reducer 타입)의 프로젝트 관용 접미어
- **`TutorialFeature.AuthenticationStatus`** `enum` · public · [TutorialFeature.swift:21](../../../sources/Projects/Feature/Onboarding/Tutorial/TutorialFeature.swift#L21) · 채택: Equatable, Sendable  
  로그인 진행 상태를 나타내는 열거형으로 idle·signingIn·cancelled·retryableFailure 케이스를 가진다. State.authentication에 저장되며 signingIn이면 중복 로그인 요청을 막고 cancelled·retryableFailure는 isShowingRecoverableError로 노출된다.  
  단어: `Authentication` 인증. 여기서는 Apple 로그인 절차 · `Status` 상태·진행 단계. 여기서는 로그인 절차가 현재 어느 단계인지
- **`TutorialFeature.PageProgress`** `struct` · public · [TutorialFeature.swift:28](../../../sources/Projects/Feature/Onboarding/Tutorial/TutorialFeature.swift#L28) · 채택: Equatable, Sendable  
  currentPage와 totalPages 두 Int 상수를 담는 값으로 State.pageProgress 계산 프로퍼티가 page - 1과 Constant.pageCount로 만든다. TutorialScreen이 SignInSection의 PageIndicator와 TabView 범위에 사용한다.  
  단어: `Page` 쪽·페이지. 여기서는 튜토리얼 페이지 · `Progress` 진행·진척. 여기서는 전체 페이지 중 현재 위치
- **`TutorialFeature.State`** `struct` · public · [TutorialFeature.swift:33](../../../sources/Projects/Feature/Onboarding/Tutorial/TutorialFeature.swift#L33) · 채택: Equatable, Sendable  
  @ObservableState가 적용된 TutorialFeature의 상태로 page·authentication·requestID·hasAttemptedCompletedAccountReset과 주입된 bundleVersion을 보유하며 pageProgress·isShowingRecoverableError 계산 프로퍼티를 제공한다. OnboardingRouterFeature.State.tutorial로 보유된다.  
  단어(단일): `State` 상태. 여기서는 TCA Reducer가 보유하는 관찰 가능한 상태 구조체
- **`TutorialFeature.Action`** `enum` · public · [TutorialFeature.swift:56](../../../sources/Projects/Feature/Onboarding/Tutorial/TutorialFeature.swift#L56) · 채택: ViewAction, Sendable, Equatable  
  TutorialFeature가 처리하는 액션으로 view(View)·effect(EffectEvent)·input(Input)·delegate(Delegate) 네 케이스를 가진다. ViewAction 채택으로 TutorialScreen의 send가 view 케이스로 매핑된다.  
  단어(단일): `Action` 동작·행위. 여기서는 TCA Reducer가 처리하는 액션 열거형
- **`TutorialFeature.Action.View`** `enum` · public · [TutorialFeature.swift:64](../../../sources/Projects/Feature/Onboarding/Tutorial/TutorialFeature.swift#L64) · 채택: Sendable, Equatable  
  @CasePathable 뷰 액션으로 appeared·pageChanged(Int)·appleSignInTapped 케이스를 가진다. TutorialScreen의 task, TabView 선택 바인딩, AppleSignInButton에서 send된다.  
  단어(단일): `View` 보기·화면. 여기서는 SwiftUI View가 사용자 상호작용으로 보내는 액션 묶음(TCA ViewAction)
- **`TutorialFeature.Action.EffectEvent`** `enum` · public · [TutorialFeature.swift:71](../../../sources/Projects/Feature/Onboarding/Tutorial/TutorialFeature.swift#L71) · 채택: Sendable, Equatable  
  @CasePathable 효과 결과 액션으로 signInFinished(requestID:result:) 케이스 하나만 가진다. startSignIn과 재시도 .run 효과가 signIn 클로저 결과를 이 액션으로 되돌려 보내며 Reducer는 requestID가 현재 값과 같을 때만 처리한다.  
  단어: `Effect` 효과·부수 효과. 여기서는 TCA Effect(.run)로 실행한 비동기 작업 · `Event` 사건·결과 통지. 여기서는 비동기 작업이 끝났음을 알리는 액션
- **`TutorialFeature.Action.Input`** `enum` · public · [TutorialFeature.swift:76](../../../sources/Projects/Feature/Onboarding/Tutorial/TutorialFeature.swift#L76) · 채택: Sendable, Equatable  
  @CasePathable 입력 액션으로 returnToLastPage와 startSignIn 케이스를 가진다. OnboardingRouterFeature가 약관 동의 완료·취소나 직무 선택 이탈 시 튜토리얼에 명령으로 보낸다.  
  단어(단일): `Input` 입력. 여기서는 부모 Reducer가 자식 Reducer에 명령으로 보내는 입력 액션 묶음
- **`TutorialFeature.Action.Delegate`** `enum` · public · [TutorialFeature.swift:82](../../../sources/Projects/Feature/Onboarding/Tutorial/TutorialFeature.swift#L82) · 채택: Sendable, Equatable  
  @CasePathable 위임 액션으로 appeared·signInRequested·signInSucceeded(needsCuration:) 케이스를 가진다. OnboardingRouterFeature가 이를 받아 약관 로드, 약관 동의 화면 전환 또는 로그인 시작, 큐레이션 진입 또는 메인 셸 요청을 결정한다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 자식 Reducer가 결과를 부모 Reducer에 알리는 위임 액션 묶음
- **`TutorialFeature.Constant`** `enum` · private · [TutorialFeature.swift:148](../../../sources/Projects/Feature/Onboarding/Tutorial/TutorialFeature.swift#L148)  
  TutorialFeature 전용 상수 네임스페이스로 pageCount(3) 하나를 가진다. pageProgress의 totalPages와 returnToLastPage·startSignIn의 마지막 페이지 이동에 사용된다.  
  단어(단일): `Constant` 상수. 여기서는 레이아웃 수치·고정 문구를 모아 둔 private 네임스페이스 enum
- **`TutorialFeature.CancelID`** `enum` · private · [TutorialFeature.swift:152](../../../sources/Projects/Feature/Onboarding/Tutorial/TutorialFeature.swift#L152) · 채택: Hashable  
  로그인 효과의 취소 식별자로 signIn 케이스 하나만 가진다. startSignIn과 완료 계정 재설정 재시도의 .run 효과에 cancellable(id: CancelID.signIn, cancelInFlight: true)로 붙어 진행 중인 요청을 대체한다.  
  단어: `Cancel` 취소. 여기서는 진행 중인 TCA Effect를 취소하는 것 · `ID` Identifier(식별자). 여기서는 취소 대상 효과를 구별하는 키
- **`TutorialScreen`** `struct` · internal · [TutorialScreen.swift:6](../../../sources/Projects/Feature/Onboarding/Tutorial/TutorialScreen.swift#L6) · 채택: View  
  @ViewAction(for: TutorialFeature.self)이 적용된 내부 화면 View로 StoreOf<TutorialFeature>를 보유하고 ScreenContainer 안에 페이지 스타일 TabView(PageView)와 SignInSection을 세로로 배치하며 task에서 appeared를 보낸다. OnboardingRouter가 FlowNavigationStack의 루트 콘텐츠로 사용한다.  
  단어: `Tutorial` 지침·안내 학습. 여기서는 앱 기능을 소개하는 3페이지 안내 화면 · `Screen` 화면. 여기서는 온보딩 안내 단계를 표시하는 SwiftUI 화면 View

## ProjectDetail

- **`ProjectDetailFeature`** `struct` · public · [ProjectDetailFeature.swift:8](../../../sources/Projects/Feature/ProjectDetail/ProjectDetailFeature.swift#L8) · 채택: Sendable  
  @Reducer로 선언된 프로젝트 상세 화면의 TCA 리듀서로, 생성자로 주입된 projectDetail·deleteProject 클로저를 사용해 상세를 로드(requestID로 최신 응답만 반영)하고 삭제 확인·실행, 메뉴 표시, 세트 시작·저장한 문제·외부 URL·뒤로 가기 delegate 전달을 처리한다. ProjectDetailRouterFeature가 Scope로 합성한다.  
  단어: `Project` 기획·과업 단위. 여기서는 사용자가 등록한 GitHub 저장소 하나를 학습 대상으로 삼은 단위(ProjectID로 식별) · `Detail` 세부·상세 정보. 여기서는 프로젝트 하나의 저장소 정보와 학습 세트 진행 현황을 담은 상세 화면·상세 데이터(ProjectDetail) · `Feature` 기능·특성. 여기서는 TCA에서 State·Action·body를 갖는 리듀서 단위(@Reducer)를 가리키는 프로젝트 관례 접미어
- **`ProjectDetailFeature.LoadStatus`** `enum` · public · [ProjectDetailFeature.swift:23](../../../sources/Projects/Feature/ProjectDetail/ProjectDetailFeature.swift#L23) · 채택: Equatable, Sendable  
  프로젝트 상세 로드 진행 상태를 idle·loading·loaded·failed(ProjectError) 네 케이스로 나타내는 열거형이다. State.loadStatus에 보관되며 ProjectDetailScreen이 ErrorView 전환과 ProgressView 표시 여부를 결정하는 데 사용한다.  
  단어: `Load` 불러오기·적재. 여기서는 projectDetail 클로저로 ProjectDetail을 가져오는 비동기 로드 작업 · `Status` 상태·진행 단계. 여기서는 로드가 시작 전·진행 중·완료·실패 중 어느 단계인지
- **`ProjectDetailFeature.Deletion`** `enum` · public · [ProjectDetailFeature.swift:30](../../../sources/Projects/Feature/ProjectDetail/ProjectDetailFeature.swift#L30) · 채택: Equatable, Sendable  
  프로젝트 삭제 흐름의 단계를 idle·confirming·committing·failed(ProjectError)로 나타내는 열거형이다. State.deletion에 보관되어 ConfirmationSheet 표시 조건과 committing 중 중복 삭제·취소 차단에 사용된다.  
  단어(단일): `Deletion` 삭제·제거 행위. 여기서는 deleteProject 클로저로 프로젝트를 지우는 흐름의 진행 단계
- **`ProjectDetailFeature.State`** `struct` · public · [ProjectDetailFeature.swift:37](../../../sources/Projects/Feature/ProjectDetail/ProjectDetailFeature.swift#L37) · 채택: Equatable, Sendable  
  @ObservableState로 선언된 상세 화면 상태로 projectID, 로드된 detail(ProjectDetail?), loadStatus, requestID(요청 순서 카운터), isMenuPresented, deletion을 보관한다. isEmpty·firstIncompleteSet(완료 수가 quizCount보다 작은 첫 세트)·isResumeEnabled 파생 값을 제공한다.  
  단어(단일): `State` 상태. 여기서는 TCA 리듀서가 소유하는 프로젝트 상세 화면의 전체 상태 값
- **`ProjectDetailFeature.Action`** `enum` · public · [ProjectDetailFeature.swift:69](../../../sources/Projects/Feature/ProjectDetail/ProjectDetailFeature.swift#L69) · 채택: ViewAction, Sendable, Equatable  
  ProjectDetailFeature가 처리하는 액션 열거형으로 view(View)·input(Input)·effect(EffectEvent)·delegate(Delegate) 네 하위 그룹으로 분류한다. ViewAction을 채택해 @ViewAction 화면에서 send(_:)로 view 케이스를 보낼 수 있다.  
  단어(단일): `Action` 동작·행위. 여기서는 TCA 리듀서에 전달되어 상태 변경이나 Effect를 유발하는 이벤트 값
- **`ProjectDetailFeature.Action.View`** `enum` · public · [ProjectDetailFeature.swift:77](../../../sources/Projects/Feature/ProjectDetail/ProjectDetailFeature.swift#L77) · 채택: Sendable, Equatable  
  화면에서 발생한 사용자 입력 액션(task, retryTapped, setStartTapped(setID:), resumeTapped, menuTapped, menuDismissed, savedQuestionsTapped, repositoryLinkTapped, deleteTapped, deletionCancelled, deletionConfirmed, backTapped)을 정의한 @CasePathable 열거형이다. ProjectDetailScreen이 send로 보낸다.  
  단어(단일): `View` 보기·화면. 여기서는 SwiftUI 화면(ProjectDetailScreen)에서 비롯된 사용자 조작 액션 그룹
- **`ProjectDetailFeature.Action.Input`** `enum` · public · [ProjectDetailFeature.swift:93](../../../sources/Projects/Feature/ProjectDetail/ProjectDetailFeature.swift#L93) · 채택: Sendable, Equatable  
  화면 밖(부모 리듀서 등)에서 들어오는 입력 액션을 정의한 @CasePathable 열거형으로 refreshRequested 케이스 하나를 가진다. 수신 시 load(&state)로 상세를 다시 불러온다.  
  단어(단일): `Input` 입력. 여기서는 사용자 조작이 아닌 외부에서 리듀서로 주입되는 요청 액션 그룹
- **`ProjectDetailFeature.Action.EffectEvent`** `enum` · public · [ProjectDetailFeature.swift:98](../../../sources/Projects/Feature/ProjectDetail/ProjectDetailFeature.swift#L98) · 채택: Sendable, Equatable  
  비동기 Effect의 완료 결과를 전달하는 @CasePathable 열거형으로 detailLoadFinished(requestID:result:)와 deletionFinished(projectID:error:) 케이스를 가진다. 리듀서가 requestID 일치 여부와 error 유무로 상태를 갱신한다.  
  단어: `Effect` 효과·부수 효과. 여기서는 TCA의 .run으로 실행한 비동기 작업(로드·삭제) · `Event` 사건·발생 통지. 여기서는 그 비동기 작업이 끝났음을 리듀서에 알리는 결과 액션
- **`ProjectDetailFeature.Action.Delegate`** `enum` · public · [ProjectDetailFeature.swift:104](../../../sources/Projects/Feature/ProjectDetail/ProjectDetailFeature.swift#L104) · 채택: Sendable, Equatable  
  부모 리듀서(ProjectDetailRouterFeature)에 처리를 위임하는 @CasePathable 열거형으로 setStartRequested(projectID:setID:label:), savedQuestionsRequested(projectID:), externalURLRequested(URL), projectDeleted(projectID:), dismissRequested 케이스를 가진다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 자식 리듀서가 직접 처리하지 않고 부모에게 넘기는 액션 그룹
- **`ProjectDetailFeature.CancelID`** `enum` · private · [ProjectDetailFeature.swift:215](../../../sources/Projects/Feature/ProjectDetail/ProjectDetailFeature.swift#L215) · 채택: Hashable  
  Effect 취소 식별자로 load(상세 로드, cancelInFlight: true)와 delete(삭제, cancelInFlight: false) 케이스를 가진다. .cancellable(id:) 호출에서 사용된다.  
  단어: `Cancel` 취소. 여기서는 진행 중인 TCA Effect를 중단하는 동작 · `ID` Identifier의 약어(식별자). 여기서는 취소 대상 Effect를 구분하는 Hashable 키
- **`ProjectDetailScreen`** `struct` · internal · [ProjectDetailScreen.swift:9](../../../sources/Projects/Feature/ProjectDetail/ProjectDetailScreen.swift#L9) · 채택: View · 그래프 미수집(grep 보강)  
  @ViewAction(for: ProjectDetailFeature.self)으로 선언된 SwiftUI 화면으로 @Bindable StoreOf<ProjectDetailFeature>를 보유한다. 로드 실패 시 ErrorView, 그 외에는 OverlayContainer 안에 ScreenControlBar·RepositorySummaryView·SetListSection과 heroBackground 그라데이션을 배치하고, ActionMenu 오버레이·삭제 ConfirmationSheet(ModalOverlay)·ProgressView를 덧씌운다. ProjectDetailRouter가 FlowNavigationStack 루트로 사용한다.  
  단어: `Project` 기획·과업 단위. 여기서는 사용자가 등록한 GitHub 저장소 하나를 학습 대상으로 삼은 단위(ProjectID로 식별) · `Detail` 세부·상세 정보. 여기서는 프로젝트 하나의 저장소 정보와 학습 세트 진행 현황을 담은 상세 화면·상세 데이터(ProjectDetail) · `Screen` 화면. 여기서는 Store를 받아 한 화면 전체를 그리는 SwiftUI View를 가리키는 프로젝트 관례 접미어
- **`ProjectDetailScreen.Constant`** `enum` · fileprivate · [ProjectDetailScreen.swift:136](../../../sources/Projects/Feature/ProjectDetail/ProjectDetailScreen.swift#L136)  
  ProjectDetailScreen extension에 선언된 상수 네임스페이스로 summaryTopSpacing·setListTopSpacing·contentBottomPadding·heroGradientHeight·menuTopOffset·menuTransitionDuration 레이아웃 값, menuControl(ScreenControlBar.Control), menuItems([ActionMenu.Item]), heroGradient(GradientToken)를 보관한다.  
  단어(단일): `Constant` 상수. 여기서는 화면 레이아웃 수치·메뉴 정의·그라데이션 토큰을 모아 둔 static 값 묶음
- **`ProjectDetailScreen.Constant.MenuItemID`** `enum` · fileprivate · [ProjectDetailScreen.swift:137](../../../sources/Projects/Feature/ProjectDetail/ProjectDetailScreen.swift#L137)  
  Constant 안에 접근 제어자 없이 선언되어 fileprivate 상위 타입에 묶인 네임스페이스로 ActionMenu 항목의 문자열 식별자 savedQuestions·repositoryLink·delete를 static let으로 보관한다. menuItems 생성과 menuItemSelected(_:) 분기에서 사용된다.  
  단어: `Menu` 메뉴. 여기서는 화면 우상단 ActionMenu · `Item` 항목. 여기서는 ActionMenu.Item 한 줄(저장한 문제·GitHub에서 보기·삭제하기) · `ID` Identifier의 약어(식별자). 여기서는 항목을 구분하는 문자열 키

## ProjectDetail/Router

- **`ProjectDetailRouter`** `struct` · public · [ProjectDetailRouter.swift:6](../../../sources/Projects/Feature/ProjectDetail/Router/ProjectDetailRouter.swift#L6) · 채택: View  
  StoreOf<ProjectDetailRouterFeature>를 @Bindable로 보유하는 public SwiftUI View로, activeScreen에 따라 pushedScreens 경로를 계산해 FlowNavigationStack에 ProjectDetailScreen을 루트로 두고 SavedScreen·QuestionSolvingScreen을 push한다. 단일 문제 준비 중에는 스크림과 ProgressView 오버레이, 준비 실패 시 alert를 표시하며 App 패키지 AppRootView에서 사용된다.  
  단어: `Project` 기획·과업 단위. 여기서는 사용자가 등록한 GitHub 저장소 하나를 학습 대상으로 삼은 단위(ProjectID로 식별) · `Detail` 세부·상세 정보. 여기서는 프로젝트 하나의 저장소 정보와 학습 세트 진행 현황을 담은 상세 화면·상세 데이터(ProjectDetail) · `Router` 경로 결정자·라우터. 여기서는 activeScreen에 따라 자식 화면을 push·pop하고 자식 delegate를 중계하는 흐름 조정 계층을 그리는 SwiftUI View
- **`ProjectDetailRouterFeature`** `struct` · public · [ProjectDetailRouterFeature.swift:9](../../../sources/Projects/Feature/ProjectDetail/Router/ProjectDetailRouterFeature.swift#L9) · 채택: Sendable  
  프로젝트 상세 흐름의 라우팅 리듀서로 ProjectUseCase·QuizDetailUseCase를 주입받아 ProjectDetailFeature·SavedFeature·SingleQuestionEntryFeature를 Scope로, QuestionSolvingFeature를 ifLet으로 합성한다. 자식 delegate를 받아 activate(_:cause:state:)로 activeScreen을 전환·기록하고 learningSetRequested·externalURLRequested·projectDeleted·dismissRequested를 부모에게 전달한다.  
  단어: `Project` 기획·과업 단위. 여기서는 사용자가 등록한 GitHub 저장소 하나를 학습 대상으로 삼은 단위(ProjectID로 식별) · `Detail` 세부·상세 정보. 여기서는 프로젝트 하나의 저장소 정보와 학습 세트 진행 현황을 담은 상세 화면·상세 데이터(ProjectDetail) · `Router` 경로 결정자·라우터. 여기서는 activeScreen에 따라 자식 화면을 push·pop하고 자식 delegate를 중계하는 흐름 조정 계층 · `Feature` 기능·특성. 여기서는 TCA에서 State·Action·body를 갖는 리듀서 단위(@Reducer)를 가리키는 프로젝트 관례 접미어
- **`ProjectDetailRouterFeature.ActiveScreen`** `enum` · public · [ProjectDetailRouterFeature.swift:24](../../../sources/Projects/Feature/ProjectDetail/Router/ProjectDetailRouterFeature.swift#L24) · 채택: Hashable, Sendable  
  현재 활성 화면을 projectDetail·savedQuestions·singleQuestion 세 케이스로 나타내는 열거형이다. State.activeScreen과 ScreenTransition의 from·to에 보관되고 ProjectDetailRouter가 pushedScreens 경로와 destination 화면을 결정하는 데 사용한다.  
  단어: `Active` 활성·현재 동작 중인. 여기서는 사용자에게 지금 보이는 상태 · `Screen` 화면. 여기서는 프로젝트 상세 흐름 안의 세 화면 중 하나
- **`ProjectDetailRouterFeature.ScreenTransition`** `struct` · public · [ProjectDetailRouterFeature.swift:30](../../../sources/Projects/Feature/ProjectDetail/Router/ProjectDetailRouterFeature.swift#L30) · 채택: Equatable, Sendable  
  화면 전환 한 건을 from·to(ActiveScreen)와 cause(Cause)로 기록하는 값 타입이다. activate가 activeScreen을 바꿀 때 State.screenTransitions에 append한다.  
  단어: `Screen` 화면. 여기서는 ActiveScreen으로 표현되는 흐름 내 화면 · `Transition` 전이·전환. 여기서는 한 화면에서 다른 화면으로 활성 상태가 바뀐 사건의 기록
- **`ProjectDetailRouterFeature.ScreenTransition.Cause`** `enum` · public · [ProjectDetailRouterFeature.swift:46](../../../sources/Projects/Feature/ProjectDetail/Router/ProjectDetailRouterFeature.swift#L46) · 채택: Equatable, Sendable  
  화면 전환의 원인을 savedQuestionsRequested·singleQuestionPrepared(questionID: QuizID)·singleQuestionFinished·backRequested로 구분하는 열거형이다. ScreenTransition.cause에 담겨 activate 호출마다 기록된다.  
  단어(단일): `Cause` 원인·이유. 여기서는 어떤 자식 delegate가 화면 전환을 유발했는지
- **`ProjectDetailRouterFeature.State`** `struct` · public · [ProjectDetailRouterFeature.swift:59](../../../sources/Projects/Feature/ProjectDetail/Router/ProjectDetailRouterFeature.swift#L59) · 채택: Equatable, Sendable  
  @ObservableState로 선언된 라우터 상태로 projectID, activeScreen, screenTransitions 기록과 자식 상태 projectDetail(ProjectDetailFeature.State)·savedQuestions(SavedFeature.State)·singleQuestion(QuestionSolvingFeature.State?)·singleQuestionEntry(SingleQuestionEntryFeature.State)를 보유한다. init(projectID:)에서 자식 State를 함께 초기화한다.  
  단어(단일): `State` 상태. 여기서는 라우터 리듀서가 소유하는 활성 화면·전환 기록·자식 상태의 묶음
- **`ProjectDetailRouterFeature.Action`** `enum` · public · [ProjectDetailRouterFeature.swift:85](../../../sources/Projects/Feature/ProjectDetail/Router/ProjectDetailRouterFeature.swift#L85) · 채택: Sendable, Equatable  
  자식 리듀서 액션을 감싸는 projectDetail·savedQuestions·singleQuestion·singleQuestionEntry 케이스와 부모에게 보내는 delegate(Delegate) 케이스를 가진 액션 열거형이다. Scope·ifLet의 action 키 경로로 사용된다.  
  단어(단일): `Action` 동작·행위. 여기서는 라우터 리듀서가 받는 자식 액션 래핑과 delegate 이벤트
- **`ProjectDetailRouterFeature.Action.Delegate`** `enum` · public · [ProjectDetailRouterFeature.swift:94](../../../sources/Projects/Feature/ProjectDetail/Router/ProjectDetailRouterFeature.swift#L94) · 채택: Sendable, Equatable  
  상위(App 패키지 AppRootFeature)로 전달하는 @CasePathable 열거형으로 learningSetRequested(projectID:setID:label:), externalURLRequested(URL), projectDeleted(projectID:), dismissRequested 케이스를 가진다. ProjectDetailFeature와 QuestionSolvingFeature의 delegate를 변환·중계한 결과다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 라우터가 자체 처리하지 않고 앱 루트에 넘기는 액션 그룹

## ProjectDetail/SingleQuestionEntry

- **`SingleQuestionEntryFeature`** `struct` · public · [SingleQuestionEntryFeature.swift:8](../../../sources/Projects/Feature/ProjectDetail/SingleQuestionEntry/SingleQuestionEntryFeature.swift#L8) · 채택: Sendable  
  저장한 문제 목록에서 고른 문제 하나를 풀기 위해 fetchQuizSet(QuizSetID, ProjectID) 클로저로 QuizSet을 불러오고 questionID와 일치하는 Quiz를 찾아 questionPrepared delegate로 넘기는 @Reducer이다. 세트 로드 실패나 문제 부재(quizUnavailable) 시 preparation을 failed로 두고 preparationFailed를 보낸다.  
  단어: `Single` 단일·하나의. 여기서는 세트 전체가 아닌 문제 한 개만 대상으로 함 · `Question` 문제·질문. 여기서는 QuizID로 식별되는 퀴즈 문항(Quiz) · `Entry` 진입·입구. 여기서는 QuestionSolvingFeature로 들어가기 전 문제 데이터를 준비하는 진입 단계 · `Feature` 기능·특성. 여기서는 TCA에서 State·Action·body를 갖는 리듀서 단위(@Reducer)를 가리키는 프로젝트 관례 접미어
- **`SingleQuestionEntryFeature.Preparation`** `enum` · public · [SingleQuestionEntryFeature.swift:19](../../../sources/Projects/Feature/ProjectDetail/SingleQuestionEntry/SingleQuestionEntryFeature.swift#L19) · 채택: Equatable, Sendable  
  단일 문제 준비 상태를 idle·loading(questionID: QuizID)·failed(QuizDetailError)로 나타내는 열거형이다. State.preparation에 보관되어 중복 요청 차단, 응답 questionID 검증, isPreparing·preparationError 파생에 쓰인다.  
  단어(단일): `Preparation` 준비·채비. 여기서는 문제 풀이 화면에 넘길 Quiz를 QuizSet에서 불러와 찾는 과정의 진행 단계
- **`SingleQuestionEntryFeature.State`** `struct` · public · [SingleQuestionEntryFeature.swift:25](../../../sources/Projects/Feature/ProjectDetail/SingleQuestionEntry/SingleQuestionEntryFeature.swift#L25) · 채택: Equatable, Sendable  
  @ObservableState로 선언된 상태로 projectID와 preparation(Preparation)을 보유하고 isPreparing(loading 여부)·preparationError(failed의 오류) 파생 값을 제공한다. ProjectDetailRouter가 오버레이와 alert 표시 조건으로 읽는다.  
  단어(단일): `State` 상태. 여기서는 단일 문제 준비 리듀서가 소유하는 projectID와 준비 단계 값
- **`SingleQuestionEntryFeature.Action`** `enum` · public · [SingleQuestionEntryFeature.swift:53](../../../sources/Projects/Feature/ProjectDetail/SingleQuestionEntry/SingleQuestionEntryFeature.swift#L53) · 채택: Sendable, Equatable  
  SingleQuestionEntryFeature가 처리하는 액션 열거형으로 input(Input)·effect(EffectEvent)·delegate(Delegate) 세 하위 그룹으로 분류한다. 화면 전용 View 그룹은 없다.  
  단어(단일): `Action` 동작·행위. 여기서는 단일 문제 준비 리듀서에 전달되는 이벤트 값
- **`SingleQuestionEntryFeature.Action.Input`** `enum` · public · [SingleQuestionEntryFeature.swift:60](../../../sources/Projects/Feature/ProjectDetail/SingleQuestionEntry/SingleQuestionEntryFeature.swift#L60) · 채택: Sendable, Equatable  
  외부에서 들어오는 입력 액션을 정의한 @CasePathable 열거형으로 questionRequested(setID:questionID:)와 failureDismissed 케이스를 가진다. ProjectDetailRouterFeature가 SavedFeature의 questionSelected delegate를 받아 questionRequested를 보내고 ProjectDetailRouter의 alert 확인이 failureDismissed를 보낸다.  
  단어(단일): `Input` 입력. 여기서는 부모 리듀서·라우터 View에서 주입되는 요청 액션 그룹
- **`SingleQuestionEntryFeature.Action.EffectEvent`** `enum` · public · [SingleQuestionEntryFeature.swift:66](../../../sources/Projects/Feature/ProjectDetail/SingleQuestionEntry/SingleQuestionEntryFeature.swift#L66) · 채택: Sendable, Equatable  
  비동기 세트 로드 결과를 전달하는 @CasePathable 열거형으로 setLoadFinished(questionID:result: Result<QuizSet, QuizDetailError>) 케이스 하나를 가진다. 리듀서가 preparation의 loading questionID와 일치할 때만 처리한다.  
  단어: `Effect` 효과·부수 효과. 여기서는 fetchQuizSet을 실행하는 .run Effect · `Event` 사건·발생 통지. 여기서는 세트 로드가 끝났음을 알리는 결과 액션
- **`SingleQuestionEntryFeature.Action.Delegate`** `enum` · public · [SingleQuestionEntryFeature.swift:71](../../../sources/Projects/Feature/ProjectDetail/SingleQuestionEntry/SingleQuestionEntryFeature.swift#L71) · 채택: Sendable, Equatable  
  부모(ProjectDetailRouterFeature)에 결과를 위임하는 @CasePathable 열거형으로 questionPrepared(question: Quiz, projectID:)와 preparationFailed(QuizDetailError) 케이스를 가진다. 부모는 questionPrepared를 받아 QuestionSolvingFeature.State를 만들고 singleQuestion 화면으로 전환한다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 준비 성공·실패 결과를 부모 라우터에 넘기는 액션 그룹
- **`SingleQuestionEntryFeature.CancelID`** `enum` · private · [SingleQuestionEntryFeature.swift:128](../../../sources/Projects/Feature/ProjectDetail/SingleQuestionEntry/SingleQuestionEntryFeature.swift#L128) · 채택: Hashable  
  세트 로드 Effect의 취소 식별자로 load 케이스 하나를 가진다. questionRequested 처리 시 .cancellable(id: CancelID.load, cancelInFlight: true)로 이전 로드를 취소한다.  
  단어: `Cancel` 취소. 여기서는 진행 중인 세트 로드 Effect를 중단하는 동작 · `ID` Identifier의 약어(식별자). 여기서는 취소 대상 Effect를 구분하는 Hashable 키

## ProjectDetail/SubViews

- **`ProjectDetailScreen.ErrorView`** `struct` · internal · [ProjectDetailScreen+ErrorView.swift:6](../../../sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+ErrorView.swift#L6) · 채택: View  
  ProjectDetailScreen extension에 선언된 로드 실패 화면으로 onBack·onRetry 클로저를 받아 ScreenControlBar, '프로젝트를 불러오지 못했어요' 안내 StyledText, ActionButton.primary('다시 시도하기')를 세로로 배치한다. loadStatus가 failed일 때 ScreenContainer 안에 표시된다.  
  단어: `Error` 오류·실패. 여기서는 프로젝트 상세 로드가 ProjectError로 실패한 상황 · `View` 보기·화면 조각. 여기서는 실패 안내와 재시도 버튼을 그리는 SwiftUI View
- **`ProjectDetailScreen.ErrorView.Constant`** `enum` · private · [ProjectDetailScreen+ErrorView.swift:35](../../../sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+ErrorView.swift#L35)  
  ErrorView 전용 레이아웃 상수 네임스페이스로 textSpacing(10)과 bottomButtonPadding(24)을 static let으로 보관한다.  
  단어(단일): `Constant` 상수. 여기서는 ErrorView의 간격·패딩 수치를 모아 둔 static 값 묶음
- **`ProjectDetailScreen.RepositorySummaryView`** `struct` · internal · [ProjectDetailScreen+RepositorySummaryView.swift:7](../../../sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+RepositorySummaryView.swift#L7) · 채택: View  
  ProjectDetailScreen extension에 선언된 저장소 요약 헤더로 repositoryName·repositoryImageURL·starCount·techStack·overallProgressPercent·isResumeEnabled·onResumeTap을 받는다. AsyncImage 배너, k/m 단위로 축약한 별 수와 기술 스택 메타 행, '이어서 학습' 재생 버튼, LabeledProgressBar('전체 진행률')를 배치한다.  
  단어: `Repository` 저장소. 여기서는 프로젝트가 가리키는 GitHub 저장소(ProjectDetail.repository) · `Summary` 요약. 여기서는 이름·이미지·별 수·기술 스택·전체 진행률만 간추린 정보 · `View` 보기·화면 조각. 여기서는 상세 화면 상단 헤더를 그리는 SwiftUI View
- **`ProjectDetailScreen.RepositorySummaryView.Constant`** `enum` · private · [ProjectDetailScreen+RepositorySummaryView.swift:48](../../../sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+RepositorySummaryView.swift#L48)  
  RepositorySummaryView 전용 레이아웃 상수 네임스페이스로 bannerToContentSpacing·contentSpacing·textSpacing·metaSpacing·starSpacing 간격, dividerHeight·bannerSize·starSize·resumeSurfaceSize·resumeTouchSize 크기, disabledOpacity(0.4)를 보관한다.  
  단어(단일): `Constant` 상수. 여기서는 요약 헤더의 간격·크기·투명도 수치를 모아 둔 static 값 묶음
- **`ProjectDetailScreen.SetListSection`** `struct` · internal · [ProjectDetailScreen+SetListSection.swift:6](../../../sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+SetListSection.swift#L6) · 채택: View  
  ProjectDetailScreen extension에 선언된 학습 세트 목록 섹션으로 sets([ProjectDetailSetDisplay])와 onStart((String) -> Void)를 받아 '학습 세트' 제목 아래 LearningSetRow를 ForEach로 나열한다. sets가 비어 있으면 EmptyState와 levelEntry 일러스트를 대신 표시한다.  
  단어: `Set` 집합·묶음. 여기서는 프로젝트 하나에서 생성된 퀴즈 묶음(학습 세트, QuizSetID로 식별) · `List` 목록. 여기서는 학습 세트를 세로로 나열한 배열 표시 · `Section` 구역·섹션. 여기서는 상세 화면 안에서 제목과 목록을 묶은 한 영역
- **`ProjectDetailScreen.SetListSection.Constant`** `enum` · private · [ProjectDetailScreen+SetListSection.swift:23](../../../sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+SetListSection.swift#L23)  
  SetListSection 전용 레이아웃 상수 네임스페이스로 emptyStateVerticalPadding(32)·titleSpacing(16)·cardSpacing(6)을 static let으로 보관한다.  
  단어(단일): `Constant` 상수. 여기서는 세트 목록 섹션의 패딩·간격 수치를 모아 둔 static 값 묶음

## ProjectDetail/ViewModels

- **`ProjectDetailSetDisplay`** `struct` · public · [ProjectDetailSetDisplay.swift:7](../../../sources/Projects/Feature/ProjectDetail/ViewModels/ProjectDetailSetDisplay.swift#L7) · 채택: Equatable, Sendable, Identifiable  
  상세 화면 표시용 학습 세트 모델로 id(QuizSetID)·label·title·questionCount·completedCount를 보관하고 isCompleted(questionCount > 0이면서 완료 수가 문제 수 이상) 파생 값을 제공한다. static list(sets:)가 DomainProject의 ProjectSetProgress 배열(quizCount → questionCount)을 변환하며 SetListSection이 LearningSetRow 입력으로 사용한다.  
  단어: `Project` 기획·과업 단위. 여기서는 사용자가 등록한 GitHub 저장소 하나를 학습 대상으로 삼은 단위(ProjectID로 식별) · `Detail` 세부·상세 정보. 여기서는 프로젝트 하나의 저장소 정보와 학습 세트 진행 현황을 담은 상세 화면·상세 데이터(ProjectDetail) · `Set` 집합·묶음. 여기서는 프로젝트 하나에서 생성된 퀴즈 묶음(학습 세트) · `Display` 표시·표시용. 여기서는 Domain 모델을 화면 표시 형태로 바꾼 뷰 모델

## ProjectList

- **`ProjectListFeature`** `struct` · public · [ProjectListFeature.swift:8](../../../sources/Projects/Feature/ProjectList/ProjectListFeature.swift#L8) · 채택: Sendable  
  @Reducer로 선언된 프로젝트 목록 화면의 TCA Reducer로, 생성자 주입된 projects 스트림·refreshProjects·requestNextPage·deleteProject 클로저를 사용해 초기 로드·새로고침·다음 페이지 로드·삭제 흐름을 처리하고 선택·학습 요청·삭제 완료를 Delegate 액션으로 상위에 전달한다. MainShellRouterFeature가 이 Reducer를 생성해 사용한다.  
  단어: `Project` 프로젝트·과제. 여기서는 사용자가 등록한 GitHub 저장소 기반 학습 프로젝트 · `List` 목록. 여기서는 프로젝트 요약(ProjectSummary)을 나열하는 화면의 목록 · `Feature` 기능·특성. 여기서는 TCA에서 State·Action·Reducer를 한데 묶은 화면 단위 기능 Reducer
- **`ProjectListFeature.State`** `struct` · public · [ProjectListFeature.swift:27](../../../sources/Projects/Feature/ProjectList/ProjectListFeature.swift#L27) · 채택: Equatable, Sendable  
  @ObservableState가 붙은 프로젝트 목록 화면의 상태로, 프로젝트 요약 배열 projects, hasNextPage, 초기 로드 상태 initialLoad, 페이지네이션 상태 pagination, 화면 모드 mode, 삭제 진행 상태 deletion, 새로고침 요청을 구분하는 requestID를 보유한다.  
  단어(단일): `State` 상태. 여기서는 프로젝트 목록 화면이 Reducer로 관리하는 TCA 상태 값 묶음
- **`ProjectListFeature.InitialLoad`** `enum` · public · [ProjectListFeature.swift:40](../../../sources/Projects/Feature/ProjectList/ProjectListFeature.swift#L40) · 채택: Equatable, Sendable  
  프로젝트 목록의 최초 로드 진행 상태를 idle·loading·loaded·failed(ProjectError)로 표현하는 열거형으로, State.initialLoad에 저장되어 화면이 로딩 인디케이터·실패 화면·목록 중 무엇을 보일지 결정한다.  
  단어: `Initial` 최초의·처음의. 여기서는 화면 진입 후 처음 수행하는 프로젝트 목록 로드 · `Load` 적재·불러오기. 여기서는 프로젝트 목록 데이터를 불러오는 작업과 그 진행 상태
- **`ProjectListFeature.Pagination`** `enum` · public · [ProjectListFeature.swift:47](../../../sources/Projects/Feature/ProjectList/ProjectListFeature.swift#L47) · 채택: Equatable, Sendable  
  다음 페이지 로드 상태를 idle·loading·failed(ProjectError)·exhausted로 표현하는 열거형으로, State.pagination에 저장되고 NextPageFooter가 이 값을 받아 로딩·재시도 UI를 그린다.  
  단어(단일): `Pagination` 페이지 나눔·페이지 단위 로드. 여기서는 프로젝트 목록의 다음 페이지 요청 진행 상태
- **`ProjectListFeature.Mode`** `enum` · public · [ProjectListFeature.swift:54](../../../sources/Projects/Feature/ProjectList/ProjectListFeature.swift#L54) · 채택: Equatable, Sendable  
  화면의 상호작용 모드를 browsing·menuPresented·deleting 세 가지로 구분하는 열거형으로, 메뉴 표시 여부·삭제 모드 전환·탭 바 숨김과 헤더 제어 버튼 구성을 결정한다.  
  단어(단일): `Mode` 모드·동작 방식. 여기서는 프로젝트 목록 화면이 탐색·메뉴 표시·삭제 중 어느 상호작용 상태인지
- **`ProjectListFeature.Deletion`** `enum` · public · [ProjectListFeature.swift:60](../../../sources/Projects/Feature/ProjectList/ProjectListFeature.swift#L60) · 채택: Equatable, Sendable  
  프로젝트 삭제 절차의 단계를 idle·confirming(projectID)·committing(projectID)·failed(projectID, error)로 표현하는 열거형으로, 삭제 확인 시트 표시와 deleteProject 실행 결과 반영에 사용된다.  
  단어(단일): `Deletion` 삭제. 여기서는 특정 프로젝트를 삭제하는 절차의 진행 단계
- **`ProjectListFeature.Action`** `enum` · public · [ProjectListFeature.swift:67](../../../sources/Projects/Feature/ProjectList/ProjectListFeature.swift#L67) · 채택: ViewAction, Sendable, Equatable  
  프로젝트 목록 Reducer가 받는 액션의 최상위 열거형으로, view(View)·input(Input)·effect(EffectEvent)·delegate(Delegate) 네 갈래로 출처를 나눈다. ViewAction 채택으로 화면에서 send(.view(...))를 축약해 보낼 수 있다.  
  단어(단일): `Action` 동작·행위. 여기서는 TCA Reducer에 전달되어 상태 변화와 Effect를 유발하는 액션
- **`ProjectListFeature.Action.Input`** `enum` · public · [ProjectListFeature.swift:75](../../../sources/Projects/Feature/ProjectList/ProjectListFeature.swift#L75) · 채택: Sendable, Equatable  
  @CasePathable이 붙은 외부 입력 액션 열거형으로, 상위 Reducer가 보내는 learningProjectsReloadRequested 하나를 가지며 수신 시 새로고침(startRefresh)을 실행한다.  
  단어(단일): `Input` 입력. 여기서는 화면이 아닌 상위 Reducer 등 외부에서 이 기능으로 들어오는 액션
- **`ProjectListFeature.Action.View`** `enum` · public · [ProjectListFeature.swift:80](../../../sources/Projects/Feature/ProjectList/ProjectListFeature.swift#L80) · 채택: Sendable, Equatable  
  @CasePathable이 붙은 화면 발신 액션 열거형으로, task·refreshRequested·listBottomReached·nextPageRetryTapped·projectRowTapped·learningTapped·menuTapped·menuDismissed·deletionMenuItemTapped·backTapped·deleteButtonTapped·deletionCancelled·deletionConfirmed 등 사용자 조작과 뷰 생명주기 이벤트를 담는다.  
  단어(단일): `View` 뷰·화면. 여기서는 ProjectListScreen이 사용자 조작·생명주기에 따라 보내는 액션 묶음
- **`ProjectListFeature.Action.EffectEvent`** `enum` · public · [ProjectListFeature.swift:97](../../../sources/Projects/Feature/ProjectList/ProjectListFeature.swift#L97) · 채택: Sendable, Equatable  
  @CasePathable이 붙은 비동기 Effect 결과 액션 열거형으로, projectsReceived(ProjectList)·refreshFinished(requestID, error)·nextPageFinished(error)·deletionFinished(projectID, error)를 통해 스트림 수신과 새로고침·다음 페이지·삭제 작업의 완료를 Reducer에 되돌린다.  
  단어: `Effect` 효과·부수 효과. 여기서는 TCA의 비동기 Effect(프로젝트 스트림 구독, 새로고침·페이지·삭제 요청) · `Event` 사건·이벤트. 여기서는 Effect가 완료되거나 값을 방출했을 때 Reducer로 보내는 결과 통지
- **`ProjectListFeature.Action.Delegate`** `enum` · public · [ProjectListFeature.swift:105](../../../sources/Projects/Feature/ProjectList/ProjectListFeature.swift#L105) · 채택: Sendable, Equatable  
  @CasePathable이 붙은 상위 위임 액션 열거형으로, projectSelected(projectID)·learningRequested(projectID, nextSetID)·projectDeleted를 통해 화면 전환과 삭제 완료를 부모 Reducer(MainShellRouterFeature)에 알린다. Reducer 자신은 .delegate를 받아도 아무 처리를 하지 않는다.  
  단어(단일): `Delegate` 위임·대리인. 여기서는 이 기능이 직접 처리하지 않고 상위 Reducer에 넘기는 액션
- **`ProjectListFeature.CancelID`** `enum` · private · [ProjectListFeature.swift:244](../../../sources/Projects/Feature/ProjectList/ProjectListFeature.swift#L244) · 채택: Hashable  
  TCA Effect 취소 식별자로 쓰이는 private 열거형으로, projects·refresh·nextPage·deletion 케이스를 .cancellable(id:)와 .cancel(id:)에 넘겨 진행 중인 스트림 구독·새로고침·다음 페이지·삭제 Effect를 취소하거나 중복 실행을 막는다.  
  단어: `Cancel` 취소. 여기서는 진행 중인 TCA Effect를 중단하는 동작 · `ID` Identifier(식별자). 여기서는 취소 대상 Effect를 구분하는 키
- **`ProjectListScreen`** `struct` · public · [ProjectListScreen.swift:9](../../../sources/Projects/Feature/ProjectList/ProjectListScreen.swift#L9) · 채택: View · 그래프 미수집(grep 보강)  
  @ViewAction(for: ProjectListFeature.self)가 붙은 프로젝트 목록 화면 SwiftUI View로, StoreOf<ProjectListFeature>를 받아 initialLoad·projects 유무에 따라 FailureView·EmptyProjectsView·목록(ProjectRow + NextPageFooter)을 그리고, ActionMenu 오버레이·삭제 ConfirmationSheet·로딩 ProgressView·탭 바 숨김을 mode와 deletion 상태로 제어한다.  
  단어: `Project` 프로젝트·과제. 여기서는 사용자가 등록한 GitHub 저장소 기반 학습 프로젝트 · `List` 목록. 여기서는 프로젝트 행(ProjectRow)을 세로로 나열한 목록 · `Screen` 화면. 여기서는 탭 하나를 차지하는 최상위 SwiftUI 화면 View
- **`ProjectListScreen.Constant`** `enum` · fileprivate · [ProjectListScreen.swift:250](../../../sources/Projects/Feature/ProjectList/ProjectListScreen.swift#L250)  
  ProjectListScreen 확장 안에 선언된 fileprivate 상수 네임스페이스로, contentVerticalPadding·menuTopOffset·menuTransitionDuration·헤더 높이·간격·패딩 값과 메뉴 제어 버튼(menuControl)·메뉴 항목 목록(menuItems)을 static let으로 보관한다.  
  단어(단일): `Constant` 상수. 여기서는 프로젝트 목록 화면 레이아웃 수치와 메뉴 정의를 모아 둔 네임스페이스

## ProjectList/SubViews

- **`ProjectListScreen.EmptyProjectsView`** `struct` · internal · [ProjectListScreen+EmptyProjectsView.swift:6](../../../sources/Projects/Feature/ProjectList/SubViews/ProjectListScreen+EmptyProjectsView.swift#L6) · 채택: View  
  프로젝트가 하나도 없을 때 ProjectListScreen이 헤더 아래에 표시하는 빈 상태 View로, UIComponent의 EmptyState에 'projects = []' 제목·안내 문구·projectEmpty ResourceAnimation을 넣어 세로 중앙에 배치한다.  
  단어: `Empty` 비어 있는. 여기서는 등록된 프로젝트가 0개인 상태 · `Projects` 프로젝트들(복수). 여기서는 사용자가 등록한 학습 프로젝트 목록 · `View` 뷰. 여기서는 SwiftUI View 프로토콜을 따르는 화면 구성 요소
- **`ProjectListScreen.FailureView`** `struct` · internal · [ProjectListScreen+FailureView.swift:6](../../../sources/Projects/Feature/ProjectList/SubViews/ProjectListScreen+FailureView.swift#L6) · 채택: View  
  초기 로드가 failed일 때 ProjectListScreen이 전체 화면으로 표시하는 실패 View로, '프로젝트' 헤더 제목·불러오기 실패 안내 문구·'다시 시도하기' ActionButton을 그리고 onRetry 클로저로 재시도를 알린다.  
  단어: `Failure` 실패. 여기서는 프로젝트 목록 초기 로드가 실패한 상태 · `View` 뷰. 여기서는 실패 상태를 표시하는 SwiftUI View
- **`ProjectListScreen.FailureView.Constant`** `enum` · private · [ProjectListScreen+FailureView.swift:41](../../../sources/Projects/Feature/ProjectList/SubViews/ProjectListScreen+FailureView.swift#L41)  
  FailureView 내부의 private 상수 네임스페이스로, textSpacing·bottomButtonPadding·headerControlRowHeight·headerTitleSpacing·headerBottomPadding·headerHeight 레이아웃 수치를 static let으로 보관한다.  
  단어(단일): `Constant` 상수. 여기서는 FailureView 레이아웃 수치를 모아 둔 네임스페이스
- **`ProjectListScreen.NextPageFooter`** `struct` · internal · [ProjectListScreen+NextPageFooter.swift:6](../../../sources/Projects/Feature/ProjectList/SubViews/ProjectListScreen+NextPageFooter.swift#L6) · 채택: View  
  프로젝트 목록 LazyVStack 맨 아래에 붙는 푸터 View로, ProjectListFeature.Pagination 값에 따라 loading이면 ProgressView, failed면 안내 문구와 '다시 시도하기' 텍스트 버튼(onRetry)을 그리고 idle·exhausted면 EmptyView를 반환한다.  
  단어: `Next` 다음. 여기서는 현재 목록 뒤에 이어질 다음 페이지 · `Page` 페이지·쪽. 여기서는 페이지네이션 단위로 불러오는 프로젝트 목록 조각 · `Footer` 바닥글·하단부. 여기서는 목록 끝에 붙어 로딩·재시도 UI를 보이는 하단 영역
- **`ProjectListScreen.NextPageFooter.Constant`** `enum` · private · [ProjectListScreen+NextPageFooter.swift:38](../../../sources/Projects/Feature/ProjectList/SubViews/ProjectListScreen+NextPageFooter.swift#L38)  
  NextPageFooter 내부의 private 상수 네임스페이스로, verticalPadding과 textSpacing 두 레이아웃 수치를 static let으로 보관한다.  
  단어(단일): `Constant` 상수. 여기서는 NextPageFooter 레이아웃 수치를 모아 둔 네임스페이스
- **`ProjectListScreen.Thumbnail`** `struct` · internal · [ProjectListScreen+Thumbnail.swift:6](../../../sources/Projects/Feature/ProjectList/SubViews/ProjectListScreen+Thumbnail.swift#L6) · 채택: View  
  프로젝트 행(ProjectRow)의 썸네일 슬롯에 들어가는 View로, imageURL 문자열이 유효한 URL이면 AsyncImage로 이미지를 fill 비율로 표시하고 그렇지 않거나 로딩 중이면 grey500 색 placeholder를 보이며 접근성에서 숨긴다.  
  단어(단일): `Thumbnail` 축소 이미지·미리보기 그림. 여기서는 프로젝트 행에 표시하는 저장소 이미지

## ProjectList/ViewModels

- **`ProjectListDisplay`** `struct` · public · [ProjectListDisplay.swift:7](../../../sources/Projects/Feature/ProjectList/ViewModels/ProjectListDisplay.swift#L7) · 채택: Equatable, Sendable, Identifiable  
  Domain의 ProjectSummary를 화면 표시용으로 변환한 값 타입으로, id·name·supportingText(techStack을 ' · '로 결합)·imageURL·progress(퍼센트를 0~1로 환산)·currentSet(label에서 숫자 추출, 없으면 1)·setTitle을 보유하며 static list(projects:)로 배열을 일괄 변환한다. ProjectListScreen이 행 렌더링과 삭제 대상 조회에 사용한다.  
  단어: `Project` 프로젝트·과제. 여기서는 사용자가 등록한 GitHub 저장소 기반 학습 프로젝트 · `List` 목록. 여기서는 프로젝트 목록 화면의 행 하나에 대응하는 항목 · `Display` 표시·화면 출력. 여기서는 Domain 모델을 화면에 그리기 좋게 가공한 표시용 모델

## ProjectRegistration/Previews

- **`ProjectRegistrationPreviewSupport`** `enum` · internal · [ProjectRegistrationPreviewSupport.swift:5](../../../sources/Projects/Feature/ProjectRegistration/Previews/ProjectRegistrationPreviewSupport.swift#L5)  
  ProjectRegistration 관심사의 SwiftUI 프리뷰가 공유하는 정적 샘플 데이터(ExternalRepository 2종 `repository`·`repositoryWithoutAvatar`, ProjectGenerationReceipt `receipt`)를 담는 네임스페이스 enum이다. RepositoryConfirmationScreen·QuizGenerationProgressScreen·ProjectRegistrationRouter 프리뷰 파일에서 참조한다.  
  단어: `Project` 프로젝트. 여기서는 외부 저장소 하나를 등록해 만드는 학습 프로젝트 · `Registration` 등록. 여기서는 저장소 링크 입력부터 퀴즈 생성까지 이어지는 프로젝트 등록 흐름 · `Preview` 미리보기. 여기서는 Xcode SwiftUI #Preview 렌더링 · `Support` 지원·보조. 여기서는 프리뷰에 넣을 샘플 값을 제공하는 보조 역할

## ProjectRegistration/QuizGenerationConfirmation

- **`QuizGenerationConfirmationFeature`** `struct` · public · [QuizGenerationConfirmationFeature.swift:3](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationConfirmation/QuizGenerationConfirmationFeature.swift#L3) · 채택: Sendable  
  학습 세트(퀴즈) 생성을 시작할지 최종 확인하는 화면의 `@Reducer`다. 보유 상태 없이 `startTapped`를 `delegate(.submitRequested)`로, `backTapped`를 `delegate(.backRequested)`로 변환해 부모에게 넘긴다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 저장소를 분석해 생성하는 학습 문제 · `Generation` 생성. 여기서는 학습 세트(퀴즈) 생성 작업 · `Confirmation` 확인·확정. 여기서는 사용자가 생성 시작을 최종 확인하는 단계 · `Feature` 기능. 여기서는 State·Action·body를 갖는 TCA Reducer 단위
- **`QuizGenerationConfirmationFeature.State`** `struct` · public · [QuizGenerationConfirmationFeature.swift:12](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationConfirmation/QuizGenerationConfirmationFeature.swift#L12) · 채택: Equatable, Sendable  
  QuizGenerationConfirmationFeature의 `@ObservableState` 상태로, 저장 프로퍼티가 없는 빈 구조체다. 확인 화면이 표시할 데이터가 없어 존재만 하며 `public init()`만 제공한다.  
  단어(단일): `State` 상태. 여기서는 TCA Reducer가 보유하는 화면 상태(비어 있음)
- **`QuizGenerationConfirmationFeature.Action`** `enum` · public · [QuizGenerationConfirmationFeature.swift:17](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationConfirmation/QuizGenerationConfirmationFeature.swift#L17) · 채택: ViewAction, Sendable, Equatable  
  QuizGenerationConfirmationFeature가 받는 액션의 최상위 enum으로 `view(View)`와 `delegate(Delegate)` 두 case를 가진다. TCA `ViewAction`을 채택해 화면의 `send`가 `view` case로 감싸진다.  
  단어(단일): `Action` 동작·액션. 여기서는 TCA Reducer에 전달되는 이벤트 값
- **`QuizGenerationConfirmationFeature.Action.View`** `enum` · public · [QuizGenerationConfirmationFeature.swift:21](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationConfirmation/QuizGenerationConfirmationFeature.swift#L21) · 채택: Sendable, Equatable  
  확인 화면에서 사용자가 일으키는 액션 묶음으로 `startTapped`(시작하기)와 `backTapped`(뒤로) 두 case를 가진다. `@CasePathable`로 선언되어 QuizGenerationConfirmationScreen의 `send(...)`로 전달된다.  
  단어(단일): `View` 보기·화면. 여기서는 SwiftUI 화면에서 발생한 사용자 입력 액션의 그룹(TCA ViewAction 규약)
- **`QuizGenerationConfirmationFeature.Action.Delegate`** `enum` · public · [QuizGenerationConfirmationFeature.swift:27](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationConfirmation/QuizGenerationConfirmationFeature.swift#L27) · 채택: Sendable, Equatable  
  부모 Reducer(라우터)에게 결과를 알리는 액션 묶음으로 `submitRequested`(생성 제출 요청)와 `backRequested`(뒤로 이동 요청) 두 case를 가진다. 이 Feature 자신은 `.delegate`를 받으면 `.none`을 반환한다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 처리를 부모 Reducer에 위임해 넘기는 결과 액션 그룹
- **`QuizGenerationConfirmationScreen`** `struct` · internal · [QuizGenerationConfirmationScreen.swift:9](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationConfirmation/QuizGenerationConfirmationScreen.swift#L9) · 채택: View · 그래프 미수집(grep 보강)  
  `StoreOf<QuizGenerationConfirmationFeature>`를 `@Bindable`로 보유하는 `@ViewAction` SwiftUI 화면이다. ScreenControlBar(뒤로), 안내 문구("입력해주신 정보로 학습 세트를 만들게요", "1~5분의 시간이 소요돼요"), 하단 "시작하기" ActionButton을 세로로 배치하고 각각 `backTapped`·`startTapped`를 보낸다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 저장소를 분석해 생성하는 학습 문제 · `Generation` 생성. 여기서는 학습 세트(퀴즈) 생성 작업 · `Confirmation` 확인·확정. 여기서는 생성 시작을 최종 확인하는 단계 · `Screen` 화면. 여기서는 Feature의 Store를 받아 렌더링하는 SwiftUI 최상위 View
- **`QuizGenerationConfirmationScreen.Constant`** `enum` · fileprivate · [QuizGenerationConfirmationScreen.swift:39](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationConfirmation/QuizGenerationConfirmationScreen.swift#L39)  
  QuizGenerationConfirmationScreen의 레이아웃 상수 네임스페이스로 `textSetSpacing`(16)과 `bottomButtonPadding`(24) 두 CGFloat을 가진다. 파일 하단 extension에 fileprivate으로 선언되어 화면 body에서만 쓰인다.  
  단어(단일): `Constant` 상수. 여기서는 화면 레이아웃 간격·패딩 수치 모음

## ProjectRegistration/QuizGenerationProgress

- **`QuizGenerationProgressFeature`** `struct` · public · [QuizGenerationProgressFeature.swift:7](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/QuizGenerationProgressFeature.swift#L7) · 채택: Sendable  
  학습 세트 생성 진행 화면의 `@Reducer`로, `submit` 액션을 받아 `requestGeneration`으로 생성 요청을 보낸 뒤 `generationStates` 스트림에서 해당 projectID의 phase를 관찰해 완료(`projectRegistered`)·실패(`failed`)로 전환한다. 생성자로 주입되는 5개 클로저(requestGeneration, generationStates, notificationAuthorization, requestNotificationAuthorization, openNotificationSettings)로 "홈에서 기다리기" 시 알림 권한 확인과 리마인더 시트 처리도 담당한다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 저장소를 분석해 생성하는 학습 문제 · `Generation` 생성. 여기서는 서버에 요청해 진행되는 학습 세트 생성 작업 · `Progress` 진행·진척. 여기서는 생성 요청이 제출·대기·실패로 옮겨가는 진행 상태 · `Feature` 기능. 여기서는 State·Action·body를 갖는 TCA Reducer 단위
- **`QuizGenerationProgressFeature.RegistrationProgress`** `enum` · public · [QuizGenerationProgressFeature.swift:28](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/QuizGenerationProgressFeature.swift#L28) · 채택: Equatable, Sendable  
  생성 등록 흐름의 진행 단계를 나타내는 enum으로 `idle`, `submitting`, `awaitingOutcome(ProjectGenerationReceipt)`, `failed(ProjectGenerationError)` 네 case를 가진다. `State.progress`의 타입이며 reducer의 guard 조건과 화면의 FailureView/GeneratingView 분기에 쓰인다.  
  단어: `Registration` 등록. 여기서는 저장소를 프로젝트로 등록하는 생성 요청 절차 · `Progress` 진행·진척. 여기서는 등록 절차가 현재 어느 단계에 있는지 나타내는 상태
- **`QuizGenerationProgressFeature.State`** `struct` · public · [QuizGenerationProgressFeature.swift:35](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/QuizGenerationProgressFeature.swift#L35) · 채택: Equatable, Sendable  
  QuizGenerationProgressFeature의 `@ObservableState` 상태로 공개 프로퍼티 `progress`(RegistrationProgress, 기본 `.idle`)와 `isGenerationReminderSheetPresented`(Bool), 내부 프로퍼티 `repository`(ExternalRepository?)와 `quizLevel`(QuizLevel, 기본 `.l1`)을 보유한다. `repository`·`quizLevel`은 `submit` 시 저장되어 재시도에 재사용된다.  
  단어(단일): `State` 상태. 여기서는 생성 진행 단계·리마인더 시트 표시 여부·재시도용 입력값을 담는 TCA 상태
- **`QuizGenerationProgressFeature.Action`** `enum` · public · [QuizGenerationProgressFeature.swift:48](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/QuizGenerationProgressFeature.swift#L48) · 채택: ViewAction, Sendable, Equatable  
  QuizGenerationProgressFeature의 최상위 액션으로 `view(View)`, `effect(EffectEvent)`, `submit(repository:quizLevel:)`, `delegate(Delegate)` 네 case를 가진다. `submit`은 부모 라우터가 저장소와 난이도를 넘겨 생성을 시작시키는 진입 액션이다.  
  단어(단일): `Action` 동작·액션. 여기서는 TCA Reducer에 전달되는 이벤트 값
- **`QuizGenerationProgressFeature.Action.View`** `enum` · public · [QuizGenerationProgressFeature.swift:56](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/QuizGenerationProgressFeature.swift#L56) · 채택: Sendable, Equatable  
  진행 화면의 사용자 액션 묶음으로 `waitAtHomeTapped`, `retryTapped`, `dismissTapped`, `generationReminderAccepted`, `generationReminderDeclined` 다섯 case를 가진다. GeneratingView·FailureView·GenerationReminderSheet의 버튼 콜백이 각각 이 case로 `send`된다.  
  단어(단일): `View` 보기·화면. 여기서는 SwiftUI 화면에서 발생한 사용자 입력 액션의 그룹(TCA ViewAction 규약)
- **`QuizGenerationProgressFeature.Action.EffectEvent`** `enum` · public · [QuizGenerationProgressFeature.swift:65](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/QuizGenerationProgressFeature.swift#L65) · 채택: Sendable, Equatable  
  비동기 Effect가 reducer로 되돌려 보내는 결과 액션 묶음으로 `submissionFinished(Result<ProjectGenerationReceipt, ProjectGenerationError>)`, `generationPhaseReceived(ProjectGenerationPhase)`, `waitAtHomeAuthorizationChecked(NotificationAuthorizationStatus)` 세 case를 가진다. `submit`·`waitAtHomeTapped`의 `.run` 클로저 안에서만 send된다.  
  단어: `Effect` 효과·부수효과. 여기서는 TCA `.run` Effect로 실행되는 비동기 작업 · `Event` 사건·이벤트. 여기서는 그 비동기 작업이 끝나거나 값을 받았을 때 발생하는 결과 통지
- **`QuizGenerationProgressFeature.Action.Delegate`** `enum` · public · [QuizGenerationProgressFeature.swift:72](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/QuizGenerationProgressFeature.swift#L72) · 채택: Sendable, Equatable  
  부모 Reducer에 결과를 알리는 액션 묶음으로 `projectRegistered(ProjectGenerationReceipt)`, `generationReminderPreferenceSelected(isEnabled: Bool)`, `dismissRequested` 세 case를 가진다. `finishWaiting`에서 리마인더 선택 여부와 등록 완료 영수증을 순서대로 보낸다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 등록 완료·리마인더 선택·닫기 요청을 부모 Reducer에 넘기는 결과 액션 그룹
- **`QuizGenerationProgressFeature.CancelID`** `enum` · private · [QuizGenerationProgressFeature.swift:151](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/QuizGenerationProgressFeature.swift#L151) · 채택: Hashable  
  취소 가능한 Effect를 식별하는 private enum으로 `registrationPipeline` 단일 case를 가진다. `submit`의 생성 요청·상태 관찰 `.run` Effect에 `.cancellable(id:cancelInFlight:)`로 붙고, 실패 전환과 `finishWaiting`에서 `.cancel(id:)`로 같은 파이프라인을 중단한다.  
  단어: `Cancel` 취소. 여기서는 실행 중인 TCA Effect 중단 · `ID` Identifier, 식별자. 여기서는 취소 대상 Effect를 구분하는 Hashable 키
- **`QuizGenerationProgressScreen`** `struct` · internal · [QuizGenerationProgressScreen.swift:8](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/QuizGenerationProgressScreen.swift#L8) · 채택: View · 그래프 미수집(grep 보강)  
  `StoreOf<QuizGenerationProgressFeature>`를 보유하는 `@ViewAction` SwiftUI 화면으로 `store.progress`가 `.failed`면 FailureView, 아니면 GeneratingView를 그린다. `isGenerationReminderSheetPresented`에 따라 GenerationReminderSheet를 `.medium` detent와 interactiveDismissDisabled로 띄우며, 하위 뷰 콜백을 `dismissTapped`·`retryTapped`·`waitAtHomeTapped`·`generationReminderAccepted`·`generationReminderDeclined`로 보낸다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 저장소를 분석해 생성하는 학습 문제 · `Generation` 생성. 여기서는 진행 중인 학습 세트 생성 작업 · `Progress` 진행·진척. 여기서는 생성이 진행되는 동안 보여주는 상태 · `Screen` 화면. 여기서는 Feature의 Store를 받아 렌더링하는 SwiftUI 최상위 View
- **`QuizGenerationProgressScreen.Constant`** `enum` · fileprivate · [QuizGenerationProgressScreen.swift:52](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/QuizGenerationProgressScreen.swift#L52)  
  QuizGenerationProgressScreen의 레이아웃 상수 네임스페이스로 `failureBottomButtonPadding`(24) 하나를 가진다. FailureView를 생성할 때 `bottomButtonPadding` 인자로 전달된다.  
  단어(단일): `Constant` 상수. 여기서는 실패 화면 하단 버튼 패딩 수치

## ProjectRegistration/QuizGenerationProgress/SubViews

- **`QuizGenerationProgressScreen.ChecklistView`** `struct` · internal · [QuizGenerationProgressScreen+ChecklistView.swift:9](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+ChecklistView.swift#L9) · 채택: View  
  `progress: Double`(0~1)을 받아 Stage 5단계를 세로 목록으로 그리는 하위 View다. 각 행은 진행률과 단계의 `progressRange`를 비교해 얻은 ChecklistStatus의 아이콘과 제목으로 구성되며, GeneratingView가 시뮬레이션된 진행률을 넘겨 사용한다.  
  단어: `Checklist` 점검 목록. 여기서는 생성 단계(정보 확인·구조 분석·개념 구성·문제 생성·검증)를 나열한 목록 · `View` 보기·뷰. 여기서는 화면 일부를 그리는 SwiftUI 하위 View
- **`QuizGenerationProgressScreen.ChecklistView.Constant`** `enum` · private · [QuizGenerationProgressScreen+ChecklistView.swift:27](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+ChecklistView.swift#L27)  
  ChecklistView 내부의 레이아웃 상수로 `rowSpacing`(19), `itemSpacing`(14), `iconSize`(24)를 가진다. 행 간격, 아이콘과 제목 사이 간격, 상태 아이콘 크기에 쓰인다.  
  단어(단일): `Constant` 상수. 여기서는 체크리스트 행·아이콘 레이아웃 수치 모음
- **`QuizGenerationProgressScreen.Stage`** `enum` · private · [QuizGenerationProgressScreen+ChecklistView.swift:63](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+ChecklistView.swift#L63) · 채택: CaseIterable  
  체크리스트가 표시하는 생성 단계 enum으로 `repositoryInfo`, `codeStructureAnalysis`, `learningOutlineComposition`, `quizGeneration`, `verification` 다섯 case를 가진다. 각 case는 한국어 `title`과 진행률 구간 `progressRange`(0~0.03, 0.03~0.38, 0.38~0.55, 0.55~0.85, 0.85~0.99)를 제공하며 QuizGenerationProgressScreen extension 안에 private으로 선언된다.  
  단어(단일): `Stage` 단계·국면. 여기서는 학습 세트 생성 체크리스트의 한 단계
- **`QuizGenerationProgressScreen.ChecklistStatus`** `enum` · private · [QuizGenerationProgressScreen+ChecklistView.swift:93](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+ChecklistView.swift#L93) · 채택: Equatable  
  체크리스트 항목의 상태 enum으로 `done`, `active`, `pending` 세 case를 가진다. `icon`은 각각 statusCheck 이미지·generalLoading 반복 애니메이션·statusLoadingDisabled 이미지를 반환하고 `accessibilityDescription`은 "완료"·"진행 중"·"대기 중"을 반환한다.  
  단어: `Checklist` 점검 목록. 여기서는 생성 단계 목록 · `Status` 상태. 여기서는 목록 항목 하나의 완료·진행·대기 상태
- **`QuizGenerationProgressScreen.FailureView`** `struct` · internal · [QuizGenerationProgressScreen+FailureView.swift:6](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+FailureView.swift#L6) · 채택: View  
  생성 실패 시 보여주는 하위 View로 `bottomButtonPadding`, `onDismiss`, `onRetry`를 받는다. ScreenControlBar(닫기), 안내 문구("학습 세트를 만들지 못했어요", "잠시 후 다시 시도해 주세요."), "다시 시도하기" ActionButton을 배치한다.  
  단어: `Failure` 실패. 여기서는 생성 요청 제출 실패 또는 서버 생성 실패 상태 · `View` 보기·뷰. 여기서는 화면 일부를 그리는 SwiftUI 하위 View
- **`QuizGenerationProgressScreen.FailureView.Constant`** `enum` · private · [QuizGenerationProgressScreen+FailureView.swift:36](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+FailureView.swift#L36)  
  FailureView 내부의 레이아웃 상수로 `guideStepSpacing`(10) 하나를 가진다. 제목과 보조 문구 사이 간격에 쓰인다.  
  단어(단일): `Constant` 상수. 여기서는 실패 안내 문구 간격 수치
- **`QuizGenerationProgressScreen.GeneratingView`** `struct` · internal · [QuizGenerationProgressScreen+GeneratingView.swift:7](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+GeneratingView.swift#L7) · 채택: View  
  생성이 진행되는 동안 보여주는 하위 View로 `onWaitAtHome` 콜백을 받는다. setCreationLoading 애니메이션, 안내 문구, ChecklistView, 하단 "홈에서 기다리기" 텍스트 버튼을 배치하고, `@State progress`를 `.task`에서 180~300초 사이 무작위 총 시간 기준으로 200ms마다 최대 0.98까지 올리는 시뮬레이션 진행률을 ChecklistView에 넘긴다.  
  단어: `Generating` 생성 중. 여기서는 학습 세트 생성이 진행 중인 동안의 화면 상태 · `View` 보기·뷰. 여기서는 화면 일부를 그리는 SwiftUI 하위 View
- **`QuizGenerationProgressScreen.GeneratingView.Constant`** `enum` · private · [QuizGenerationProgressScreen+GeneratingView.swift:45](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+GeneratingView.swift#L45)  
  GeneratingView 내부 상수로 레이아웃 수치(`loadingGraphicSize` 200, `textSetSpacing` 16, `checklistTopSpacing` 53, `bottomButtonPadding` 24 등)와 진행률 시뮬레이션 파라미터(`simulatedDurationRange` 180...300, `maxSimulatedProgress` 0.98, `simulatedProgressTickInterval` 200ms)를 가진다. `topSpacerMinLength`, `loadingGraphicFadeStart`, `loadingGraphicBottomSpacing`은 선언만 있고 body에서 참조되지 않는다.  
  단어(단일): `Constant` 상수. 여기서는 생성 중 화면의 레이아웃 수치와 진행률 시뮬레이션 설정값 모음
- **`QuizGenerationProgressScreen.GenerationReminderSheet`** `struct` · internal · [QuizGenerationProgressScreen+GenerationReminderSheet.swift:6](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+GenerationReminderSheet.swift#L6) · 채택: View  
  생성 완료 리마인드 알림 설정을 묻는 바텀 시트 View로 `onAccept`, `onDecline` 콜백을 받는다. SheetSurface 안에 notification 애니메이션, 안내 문구("세트 생성이 완료되면 리마인드 알림을 보내드려요."), "리마인드 알림 설정하기" primary 버튼과 "다시 보지 않기" text 버튼을 배치하며 배경과 presentationBackground를 clear로 둔다.  
  단어: `Generation` 생성. 여기서는 완료를 알려줄 대상인 학습 세트 생성 작업 · `Reminder` 리마인더·상기 알림. 여기서는 생성 완료 시 보내는 푸시 알림 · `Sheet` 시트. 여기서는 SwiftUI `.sheet`로 띄우는 바텀 시트 View
- **`QuizGenerationProgressScreen.GenerationReminderSheet.Constant`** `enum` · private · [QuizGenerationProgressScreen+GenerationReminderSheet.swift:42](../../../sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+GenerationReminderSheet.swift#L42)  
  GenerationReminderSheet 내부의 레이아웃 상수로 `contentSpacing`(31), `textSetSpacing`(8), `bellSize`(120), `contentTopPadding`(21)을 가진다. 시트 콘텐츠 간격, 문구 간격, 알림 애니메이션 크기, 상단 패딩에 쓰인다.  
  단어(단일): `Constant` 상수. 여기서는 리마인더 시트 레이아웃 수치 모음

## ProjectRegistration/QuizLevelSelection

- **`QuizLevelSelectionFeature`** `struct` · public · [QuizLevelSelectionFeature.swift:4](../../../sources/Projects/Feature/ProjectRegistration/QuizLevelSelection/QuizLevelSelectionFeature.swift#L4) · 채택: Sendable  
  퀴즈 난이도(QuizLevel)를 고르는 화면의 `@Reducer`다. `levelSelected`로 `state.quizLevel`을 갱신하고, `nextTapped`는 `delegate(.confirmed(quizLevel))`, `backTapped`는 `delegate(.backRequested)`로 변환해 부모에게 넘긴다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 생성될 학습 문제 · `Level` 수준·단계. 여기서는 사용자의 저장소 이해도에 따른 퀴즈 난이도(QuizLevel l1/l2/l3) · `Selection` 선택. 여기서는 난이도 하나를 고르는 행위 · `Feature` 기능. 여기서는 State·Action·body를 갖는 TCA Reducer 단위
- **`QuizLevelSelectionFeature.State`** `struct` · public · [QuizLevelSelectionFeature.swift:13](../../../sources/Projects/Feature/ProjectRegistration/QuizLevelSelection/QuizLevelSelectionFeature.swift#L13) · 채택: Equatable, Sendable  
  QuizLevelSelectionFeature의 `@ObservableState` 상태로 현재 선택된 `quizLevel: QuizLevel` 하나를 보유하며 생성자 기본값은 `.l1`이다. QuizLevelSelectionScreen이 카드의 `isSelected` 판정에 읽는다.  
  단어(단일): `State` 상태. 여기서는 선택된 퀴즈 난이도를 담는 TCA 상태
- **`QuizLevelSelectionFeature.Action`** `enum` · public · [QuizLevelSelectionFeature.swift:24](../../../sources/Projects/Feature/ProjectRegistration/QuizLevelSelection/QuizLevelSelectionFeature.swift#L24) · 채택: ViewAction, Sendable, Equatable  
  QuizLevelSelectionFeature의 최상위 액션으로 `view(View)`와 `delegate(Delegate)` 두 case를 가진다. TCA `ViewAction`을 채택해 화면의 `send`가 `view` case로 감싸진다.  
  단어(단일): `Action` 동작·액션. 여기서는 TCA Reducer에 전달되는 이벤트 값
- **`QuizLevelSelectionFeature.Action.View`** `enum` · public · [QuizLevelSelectionFeature.swift:28](../../../sources/Projects/Feature/ProjectRegistration/QuizLevelSelection/QuizLevelSelectionFeature.swift#L28) · 채택: Sendable, Equatable  
  난이도 선택 화면의 사용자 액션 묶음으로 `levelSelected(QuizLevel)`, `nextTapped`, `backTapped` 세 case를 가진다. SelectionCardList의 onSelect와 "다음"·뒤로 버튼이 각각 이 case로 `send`된다.  
  단어(단일): `View` 보기·화면. 여기서는 SwiftUI 화면에서 발생한 사용자 입력 액션의 그룹(TCA ViewAction 규약)
- **`QuizLevelSelectionFeature.Action.Delegate`** `enum` · public · [QuizLevelSelectionFeature.swift:35](../../../sources/Projects/Feature/ProjectRegistration/QuizLevelSelection/QuizLevelSelectionFeature.swift#L35) · 채택: Sendable, Equatable  
  부모 Reducer에 결과를 알리는 액션 묶음으로 `confirmed(QuizLevel)`(선택 난이도 확정)와 `backRequested`(뒤로 이동 요청) 두 case를 가진다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 난이도 확정·뒤로 요청을 부모 Reducer에 넘기는 결과 액션 그룹
- **`QuizLevelSelectionScreen`** `struct` · internal · [QuizLevelSelectionScreen.swift:10](../../../sources/Projects/Feature/ProjectRegistration/QuizLevelSelection/QuizLevelSelectionScreen.swift#L10) · 채택: View · 그래프 미수집(grep 보강)  
  `StoreOf<QuizLevelSelectionFeature>`를 보유하는 `@ViewAction` SwiftUI 화면으로 ScreenControlBar, 질문 문구("이 레포지토리와 사용 기술을 어느 정도 알고 있나요?"), SelectionCardList, "다음" 버튼을 배치한다. 정적 `levels` 배열이 `.l1/.l2/.l3`에 제목·보조 문구·일러스트를 매핑하고, 카드 선택 시 identifier로 QuizLevel을 역조회해 `levelSelected`를 보낸다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 생성될 학습 문제 · `Level` 수준·단계. 여기서는 퀴즈 난이도(QuizLevel) · `Selection` 선택. 여기서는 난이도 카드 하나를 고르는 행위 · `Screen` 화면. 여기서는 Feature의 Store를 받아 렌더링하는 SwiftUI 최상위 View
- **`QuizLevelSelectionScreen.Level`** `typealias` · fileprivate · [QuizLevelSelectionScreen.swift:48](../../../sources/Projects/Feature/ProjectRegistration/QuizLevelSelection/QuizLevelSelectionScreen.swift#L48) · 그래프 미수집(grep 보강)  
  QuizLevelSelectionScreen extension 안의 fileprivate typealias로 튜플 `(level: QuizLevel, title: String, supportingText: String, illust: ResourceImage.Asset.Illust)`를 가리킨다. 정적 `levels: [Level]` 배열의 원소 타입이며 `levelItems`에서 SelectionCardList.Item으로 변환된다.  
  단어(단일): `Level` 수준·단계. 여기서는 퀴즈 난이도 하나와 그 카드에 표시할 제목·보조 문구·일러스트를 묶은 튜플
- **`QuizLevelSelectionScreen.Constant`** `enum` · fileprivate · [QuizLevelSelectionScreen.swift:50](../../../sources/Projects/Feature/ProjectRegistration/QuizLevelSelection/QuizLevelSelectionScreen.swift#L50)  
  QuizLevelSelectionScreen의 레이아웃 상수 네임스페이스로 `titleTopPadding`(20), `listTopPadding`(46), `bottomButtonPadding`(24)을 가진다. 제목·카드 목록·하단 버튼의 세로 패딩에 쓰인다.  
  단어(단일): `Constant` 상수. 여기서는 난이도 선택 화면 레이아웃 패딩 수치 모음

## ProjectRegistration/RepositoryConfirmation

- **`RepositoryConfirmationFeature`** `struct` · public · [RepositoryConfirmationFeature.swift:4](../../../sources/Projects/Feature/ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationFeature.swift#L4) · 채택: Sendable  
  조회된 외부 저장소가 사용자가 의도한 것인지 확인하는 화면의 `@Reducer`다. `confirmTapped`는 `delegate(.confirmed)`로, `rejectTapped`와 `backTapped`는 모두 `delegate(.rejected)`로 변환해 부모에게 넘긴다.  
  단어: `Repository` 저장소. 여기서는 링크로 조회한 GitHub 등 외부 코드 저장소(ExternalRepository) · `Confirmation` 확인·확정. 여기서는 조회된 저장소가 맞는지 사용자가 확인하는 단계 · `Feature` 기능. 여기서는 State·Action·body를 갖는 TCA Reducer 단위
- **`RepositoryConfirmationFeature.State`** `struct` · public · [RepositoryConfirmationFeature.swift:13](../../../sources/Projects/Feature/ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationFeature.swift#L13) · 채택: Equatable, Sendable  
  RepositoryConfirmationFeature의 `@ObservableState` 상태로 확인 대상 `repository: ExternalRepository?` 하나를 보유하며 기본값은 nil이다. 화면이 소유자 이름·저장소 이름·아바타 URL을 읽는 원천이다.  
  단어(단일): `State` 상태. 여기서는 확인할 외부 저장소 정보를 담는 TCA 상태
- **`RepositoryConfirmationFeature.Action`** `enum` · public · [RepositoryConfirmationFeature.swift:24](../../../sources/Projects/Feature/ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationFeature.swift#L24) · 채택: ViewAction, Sendable, Equatable  
  RepositoryConfirmationFeature의 최상위 액션으로 `view(View)`와 `delegate(Delegate)` 두 case를 가진다. TCA `ViewAction`을 채택해 화면의 `send`가 `view` case로 감싸진다.  
  단어(단일): `Action` 동작·액션. 여기서는 TCA Reducer에 전달되는 이벤트 값
- **`RepositoryConfirmationFeature.Action.View`** `enum` · public · [RepositoryConfirmationFeature.swift:28](../../../sources/Projects/Feature/ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationFeature.swift#L28) · 채택: Sendable, Equatable  
  저장소 확인 화면의 사용자 액션 묶음으로 `confirmTapped`(다음), `rejectTapped`(이 레포지토리가 아니에요), `backTapped`(뒤로) 세 case를 가진다.  
  단어(단일): `View` 보기·화면. 여기서는 SwiftUI 화면에서 발생한 사용자 입력 액션의 그룹(TCA ViewAction 규약)
- **`RepositoryConfirmationFeature.Action.Delegate`** `enum` · public · [RepositoryConfirmationFeature.swift:35](../../../sources/Projects/Feature/ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationFeature.swift#L35) · 채택: Sendable, Equatable  
  부모 Reducer에 결과를 알리는 액션 묶음으로 `confirmed`(저장소 확정)와 `rejected`(다른 저장소 또는 뒤로) 두 case를 가진다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 저장소 확정·거부 결과를 부모 Reducer에 넘기는 액션 그룹
- **`RepositoryConfirmationScreen`** `struct` · internal · [RepositoryConfirmationScreen.swift:11](../../../sources/Projects/Feature/ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationScreen.swift#L11) · 채택: View · 그래프 미수집(grep 보강)  
  `StoreOf<RepositoryConfirmationFeature>`를 보유하는 `@ViewAction` SwiftUI 화면으로 ScreenControlBar, 안내 문구, ThumbnailView와 소유자 이름·저장소 이름, "다음"·"이 레포지토리가 아니에요" 버튼을 배치한다. `avatarURL`은 `store.repository?.imageURL`을 URL로 변환한 계산 프로퍼티다.  
  단어: `Repository` 저장소. 여기서는 링크로 조회한 외부 코드 저장소 · `Confirmation` 확인·확정. 여기서는 조회된 저장소가 맞는지 확인하는 단계 · `Screen` 화면. 여기서는 Feature의 Store를 받아 렌더링하는 SwiftUI 최상위 View
- **`RepositoryConfirmationScreen.Constant`** `enum` · fileprivate · [RepositoryConfirmationScreen.swift:62](../../../sources/Projects/Feature/ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationScreen.swift#L62)  
  RepositoryConfirmationScreen의 레이아웃 상수 네임스페이스로 `textSetSpacing`(16), `thumbnailSpacing`(21), `thumbnailTopPadding`(29), `bottomButtonPadding`(24)을 가진다. 문구 간격, 썸네일과 텍스트 간격, 썸네일 상단 패딩, 하단 버튼 패딩에 쓰인다.  
  단어(단일): `Constant` 상수. 여기서는 저장소 확인 화면 레이아웃 수치 모음

## ProjectRegistration/RepositoryConfirmation/SubViews

- **`RepositoryConfirmationScreen.ThumbnailView`** `struct` · internal · [RepositoryConfirmationScreen+ThumbnailView.swift:7](../../../sources/Projects/Feature/ProjectRegistration/RepositoryConfirmation/SubViews/RepositoryConfirmationScreen+ThumbnailView.swift#L7) · 채택: View  
  `avatarURL: URL?`을 받아 80pt 정사각 썸네일을 그리는 하위 View다. grey600 둥근 사각형에 gradient3를 0.2 불투명도로 덮은 placeholder 위에 AsyncImage로 아바타를 채우며(로딩 중 generalLoading 애니메이션, 실패 시 EmptyView), medium 코너 반경을 적용하고 접근성에서 숨긴다.  
  단어: `Thumbnail` 썸네일·축소 이미지. 여기서는 저장소 소유자의 아바타 이미지 · `View` 보기·뷰. 여기서는 화면 일부를 그리는 SwiftUI 하위 View
- **`RepositoryConfirmationScreen.ThumbnailView.Constant`** `enum` · private · [RepositoryConfirmationScreen+ThumbnailView.swift:26](../../../sources/Projects/Feature/ProjectRegistration/RepositoryConfirmation/SubViews/RepositoryConfirmationScreen+ThumbnailView.swift#L26)  
  ThumbnailView 내부의 상수로 `size`(80), `loadingSize`(28), `overlayOpacity`(0.2)를 가진다. 썸네일 프레임 크기, 로딩 애니메이션 크기, 그라데이션 오버레이 불투명도에 쓰인다.  
  단어(단일): `Constant` 상수. 여기서는 썸네일 크기·로딩 크기·오버레이 불투명도 수치 모음

## ProjectRegistration/RepositoryLinkInput

- **`RepositoryLinkInputFeature`** `struct` · public · [RepositoryLinkInputFeature.swift:5](../../../sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputFeature.swift#L5) · 채택: Sendable  
  @Reducer로 선언된 TCA 리듀서로, 사용자가 입력한 GitHub 저장소 링크 문자열을 생성자로 주입받은 `repository` 클로저(ExternalRepositoryURL → ExternalRepository)로 검증하고, 요청 ID로 최신 요청만 반영하며 결과를 delegate 액션(repositoryValidated·dismissRequested)으로 상위에 알린다. ProjectRegistrationRouterFeature가 Scope로 자식 리듀서로 붙여 사용한다.  
  단어: `Repository` 저장소. 여기서는 사용자가 학습 대상으로 등록하려는 외부(GitHub) 코드 저장소 · `Link` 링크·연결 주소. 여기서는 저장소를 가리키는 URL 문자열 · `Input` 입력. 여기서는 사용자가 텍스트 필드에 링크를 입력하는 행위·단계 · `Feature` 기능 단위. 여기서는 TCA 컨벤션상 State·Action·body를 가진 리듀서 타입을 뜻하는 접미어
- **`RepositoryLinkInputFeature.ValidationStatus`** `enum` · public · [RepositoryLinkInputFeature.swift:16](../../../sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputFeature.swift#L16) · 채택: Equatable, Sendable  
  저장소 링크 검증의 진행 상태를 나타내는 열거형으로 idle·validating·validated(ExternalRepository)·failed 네 케이스를 가진다. State.validation에 저장되어 버튼 활성 여부, 실패 표시, 버튼 제목 계산에 쓰인다.  
  단어: `Validation` 검증·유효성 확인. 여기서는 입력한 링크가 실제 GitHub 저장소로 확인되는지의 검사 · `Status` 상태. 여기서는 검증이 대기·진행·성공·실패 중 어느 단계인지
- **`RepositoryLinkInputFeature.State`** `struct` · public · [RepositoryLinkInputFeature.swift:23](../../../sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputFeature.swift#L23) · 채택: Equatable, Sendable  
  @ObservableState 리듀서 상태로 repositoryURLInput(입력 문자열), validation(ValidationStatus), validationRequestID(최신 요청 식별 정수)를 보유한다. 파생 속성 canValidate·isValidationFailed·validateButtonTitle을 계산해 화면(RepositoryLinkInputScreen)이 버튼 활성·오류 표시·버튼 문구를 읽도록 한다.  
  단어(단일): `State` 상태. 여기서는 TCA 리듀서가 소유하는 화면 상태 구조체
- **`RepositoryLinkInputFeature.Action`** `enum` · public · [RepositoryLinkInputFeature.swift:53](../../../sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputFeature.swift#L53) · 채택: ViewAction, Sendable, Equatable  
  리듀서가 처리하는 액션의 최상위 열거형으로 view(View)·effect(EffectEvent)·delegate(Delegate) 세 갈래로 묶는다. TCA의 ViewAction 프로토콜을 채택해 화면이 @ViewAction 매크로의 send로 View 케이스를 보낼 수 있게 한다.  
  단어(단일): `Action` 동작·행위. 여기서는 TCA 리듀서에 전달되는 이벤트 열거형
- **`RepositoryLinkInputFeature.Action.View`** `enum` · public · [RepositoryLinkInputFeature.swift:60](../../../sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputFeature.swift#L60) · 채택: Sendable, Equatable  
  @CasePathable 열거형으로 화면에서 발생한 사용자 입력을 담는다. repositoryURLChanged(String)·validateTapped·dismissTapped 케이스를 가지며 RepositoryLinkInputScreen이 send(...)로 전송한다.  
  단어(단일): `View` 화면·뷰. 여기서는 SwiftUI 화면에서 비롯된 사용자 액션 그룹
- **`RepositoryLinkInputFeature.Action.EffectEvent`** `enum` · public · [RepositoryLinkInputFeature.swift:67](../../../sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputFeature.swift#L67) · 채택: Sendable, Equatable  
  @CasePathable 열거형으로 비동기 Effect가 끝났을 때 리듀서로 돌아오는 이벤트를 담는다. validationFinished(requestID:result:) 한 케이스만 있으며 result는 Result<ExternalRepository, ExternalRepositoryError>이다.  
  단어: `Effect` 효과·부수 효과. 여기서는 TCA의 비동기 Effect(저장소 조회 실행) · `Event` 사건·이벤트. 여기서는 Effect 완료 시 리듀서로 되돌아오는 결과 알림
- **`RepositoryLinkInputFeature.Action.Delegate`** `enum` · public · [RepositoryLinkInputFeature.swift:72](../../../sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputFeature.swift#L72) · 채택: Sendable, Equatable  
  @CasePathable 열거형으로 부모 리듀서에게 알리는 결과를 담는다. repositoryValidated(ExternalRepository)·dismissRequested 케이스가 있으며 ProjectRegistrationRouterFeature가 이를 받아 화면 전환이나 닫기 위임을 처리한다.  
  단어(단일): `Delegate` 위임·대리자. 여기서는 자식 리듀서가 부모에게 처리를 넘기는 액션 그룹
- **`RepositoryLinkInputFeature.CancelID`** `enum` · private · [RepositoryLinkInputFeature.swift:113](../../../sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputFeature.swift#L113) · 채택: Hashable  
  검증 Effect의 취소 식별자로 쓰이는 private 열거형이며 validation 케이스 하나를 가진다. startValidation이 `.cancellable(id: CancelID.validation, cancelInFlight: true)`로 이전 검증 요청을 취소하는 데 사용한다.  
  단어: `Cancel` 취소. 여기서는 진행 중인 TCA Effect를 중단하는 것 · `ID` Identifier(식별자). 여기서는 취소 대상 Effect를 구분하는 키
- **`RepositoryLinkInputScreen`** `struct` · internal · [RepositoryLinkInputScreen.swift:8](../../../sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputScreen.swift#L8) · 채택: View · 그래프 미수집(grep 보강)  
  @ViewAction(for: RepositoryLinkInputFeature.self)가 붙은 SwiftUI 화면으로, StoreOf<RepositoryLinkInputFeature>를 @Bindable로 보유하고 ScreenControlBar·안내 제목·LabeledTextField·GuideSectionView·ActionButton.primary를 세로로 배치한다. 텍스트 입력은 repositoryURLChanged, 버튼은 validateTapped·dismissTapped로 store에 보내며 ProjectRegistrationRouter의 루트 화면으로 사용된다.  
  단어: `Repository` 저장소. 여기서는 등록하려는 외부 GitHub 코드 저장소 · `Link` 링크·주소. 여기서는 저장소 URL 문자열 · `Input` 입력. 여기서는 사용자가 링크를 붙여넣는 단계 · `Screen` 화면. 여기서는 프로젝트 등록 흐름의 한 전체 화면 SwiftUI View
- **`RepositoryLinkInputScreen.Constant`** `enum` · fileprivate · [RepositoryLinkInputScreen.swift:80](../../../sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputScreen.swift#L80)  
  RepositoryLinkInputScreen의 extension 안에 선언된 fileprivate 열거형으로 titleFieldSpacing·headerContentSpacing·fieldGuideSpacing·guideHorizontalPadding·bottomButtonPadding 같은 CGFloat 레이아웃 상수를 static let으로 모아 둔다. 화면 body의 spacing·padding 값으로만 쓰인다.  
  단어(단일): `Constant` 상수. 여기서는 화면 레이아웃 간격·여백 고정값의 이름 공간

## ProjectRegistration/RepositoryLinkInput/SubViews

- **`RepositoryLinkInputScreen.GuideSectionView`** `struct` · internal · [RepositoryLinkInputScreen+GuideSectionView.swift:6](../../../sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/SubViews/RepositoryLinkInputScreen+GuideSectionView.swift#L6) · 채택: View  
  RepositoryLinkInputScreen에 중첩된 SwiftUI 하위 뷰로 "불러오기 방법" 헤더 버튼과 @State isGuideExpanded로 접고 펼치는 5단계 안내 문구 목록을 grey600 배경의 둥근 사각형 안에 그린다. 링크 입력 필드 아래에 배치되어 GitHub 주소 복사 방법을 안내한다.  
  단어: `Guide` 안내·지침. 여기서는 GitHub 저장소 주소를 복사해 입력하는 방법 설명 · `Section` 구역·섹션. 여기서는 화면 안의 한 영역(접이식 안내 블록) · `View` 뷰. 여기서는 SwiftUI View 프로토콜을 채택한 하위 뷰 타입
- **`RepositoryLinkInputScreen.GuideSectionView.Constant`** `enum` · private · [RepositoryLinkInputScreen+GuideSectionView.swift:55](../../../sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/SubViews/RepositoryLinkInputScreen+GuideSectionView.swift#L55)  
  GuideSectionView 내부의 private 열거형으로 guideStepSpacing·headerHeight·headerTrailingPadding·chevronSize·chevronBoxSize·bodyVerticalPadding 레이아웃 상수와 안내 문구 배열 guideSteps(String 5개)를 static let으로 보유한다. GuideSectionView의 body에서만 참조된다.  
  단어(단일): `Constant` 상수. 여기서는 안내 섹션의 레이아웃 값과 안내 문구 고정 데이터의 이름 공간
- **`RepositoryLinkInputScreen.KeyboardDismissLayer`** `struct` · internal · [RepositoryLinkInputScreen+KeyboardDismissLayer.swift:4](../../../sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/SubViews/RepositoryLinkInputScreen+KeyboardDismissLayer.swift#L4) · 채택: View  
  RepositoryLinkInputScreen에 중첩된 SwiftUI 뷰로 Color.clear에 contentShape(Rectangle())와 onTapGesture를 붙여 탭 시 onTap 클로저를 호출한다. 화면 background로 깔려 빈 영역을 탭하면 isLinkFieldFocused를 false로 만들어 키보드를 내리는 데 쓰인다.  
  단어: `Keyboard` 키보드. 여기서는 링크 텍스트 필드에 뜬 iOS 소프트웨어 키보드 · `Dismiss` 해제·닫기. 여기서는 포커스를 풀어 키보드를 내리는 동작 · `Layer` 층·레이어. 여기서는 화면 뒤에 깔리는 투명한 탭 감지 영역

## ProjectRegistration/Router

- **`ProjectRegistrationRouter`** `struct` · public · [ProjectRegistrationRouter.swift:5](../../../sources/Projects/Feature/ProjectRegistration/Router/ProjectRegistrationRouter.swift#L5) · 채택: View  
  StoreOf<ProjectRegistrationRouterFeature>를 @Bindable로 보유하는 public SwiftUI 뷰로, ScreenContainer 안의 FlowNavigationStack에 RepositoryLinkInputScreen을 루트로 두고 store.activeScreen에 따라 RepositoryConfirmation·QuizLevelSelection·QuizGenerationConfirmation·QuizGenerationProgress 화면을 push 경로 배열로 계산해 표시한다. App 패키지의 AppRootView가 프로젝트 등록 흐름 진입 시 생성한다.  
  단어: `Project` 프로젝트. 여기서는 GitHub 저장소를 학습 대상으로 등록해 만들어지는 학습 프로젝트 · `Registration` 등록. 여기서는 링크 입력부터 퀴즈 생성까지 프로젝트를 새로 만드는 흐름 · `Router` 라우터·경로 결정자. 여기서는 활성 화면 상태를 내비게이션 스택으로 매핑하는 뷰
- **`ProjectRegistrationRouterFeature`** `struct` · public · [ProjectRegistrationRouterFeature.swift:6](../../../sources/Projects/Feature/ProjectRegistration/Router/ProjectRegistrationRouterFeature.swift#L6) · 채택: Sendable  
  @Reducer로 선언된 프로젝트 등록 흐름의 부모 리듀서로 ExternalRepositoryUseCase·ProjectGenerationUseCase·AppSettingUseCase와 openNotificationSettings 클로저를 생성자 주입받아 다섯 자식 Feature를 Scope로 결합하고, 자식 delegate 액션에 따라 activate(_:state:)로 activeScreen과 screenTransitions를 갱신하거나 상위 delegate로 전달한다. App 패키지의 AppRootFeature가 @Presents 상태로 띄운다.  
  단어: `Project` 프로젝트. 여기서는 저장소 기반 학습 프로젝트 · `Registration` 등록. 여기서는 프로젝트 신규 등록 흐름 · `Router` 라우터. 여기서는 자식 화면 리듀서 사이의 전환을 결정하는 상위 리듀서 · `Feature` 기능 단위. 여기서는 TCA 리듀서 타입 접미어
- **`ProjectRegistrationRouterFeature.ActiveScreen`** `enum` · public · [ProjectRegistrationRouterFeature.swift:25](../../../sources/Projects/Feature/ProjectRegistration/Router/ProjectRegistrationRouterFeature.swift#L25) · 채택: Hashable, Sendable  
  프로젝트 등록 흐름에서 현재 표시 중인 화면을 나타내는 열거형으로 repositoryLinkInput·repositoryConfirmation·quizLevelSelection·quizGenerationConfirmation·quizGenerationProgress 케이스를 가진다. State.activeScreen과 ScreenTransition의 from·to 값이며 ProjectRegistrationRouter가 push 경로 배열 원소로도 사용한다.  
  단어: `Active` 활성·현재 동작 중인. 여기서는 지금 화면에 보이는 · `Screen` 화면. 여기서는 등록 흐름을 구성하는 다섯 단계 화면 중 하나
- **`ProjectRegistrationRouterFeature.ScreenTransition`** `struct` · public · [ProjectRegistrationRouterFeature.swift:33](../../../sources/Projects/Feature/ProjectRegistration/Router/ProjectRegistrationRouterFeature.swift#L33) · 채택: Equatable, Sendable  
  화면 전환 한 건을 from·to 두 ActiveScreen 값으로 기록하는 값 타입이다. activate(_:state:)가 activeScreen을 바꿀 때마다 State.screenTransitions 배열에 추가한다.  
  단어: `Screen` 화면. 여기서는 등록 흐름의 ActiveScreen 값 · `Transition` 전환·이동. 여기서는 한 화면에서 다른 화면으로의 이동 기록
- **`ProjectRegistrationRouterFeature.State`** `struct` · public · [ProjectRegistrationRouterFeature.swift:38](../../../sources/Projects/Feature/ProjectRegistration/Router/ProjectRegistrationRouterFeature.swift#L38) · 채택: Equatable, Sendable  
  @ObservableState 상태로 activeScreen(ActiveScreen)·screenTransitions([ScreenTransition])와 다섯 자식 상태(repositoryLinkInput·repositoryConfirmation·quizLevelSelection·quizGenerationConfirmation·quizGenerationProgress)를 보유한다. 각 자식 상태는 해당 Feature의 State 기본 초기값으로 생성된다.  
  단어(단일): `State` 상태. 여기서는 등록 흐름 전체와 자식 화면들의 상태를 합친 리듀서 상태
- **`ProjectRegistrationRouterFeature.Action`** `enum` · public · [ProjectRegistrationRouterFeature.swift:54](../../../sources/Projects/Feature/ProjectRegistration/Router/ProjectRegistrationRouterFeature.swift#L54) · 채택: Sendable, Equatable  
  다섯 자식 Feature의 Action을 감싸는 케이스(repositoryLinkInput·repositoryConfirmation·quizLevelSelection·quizGenerationConfirmation·quizGenerationProgress)와 delegate(Delegate) 케이스를 가진 열거형이다. Scope의 action 키패스와 Reduce의 분기 대상이 된다.  
  단어(단일): `Action` 동작. 여기서는 라우터 리듀서가 받는 자식 액션과 위임 액션의 열거형
- **`ProjectRegistrationRouterFeature.Action.Delegate`** `enum` · public · [ProjectRegistrationRouterFeature.swift:62](../../../sources/Projects/Feature/ProjectRegistration/Router/ProjectRegistrationRouterFeature.swift#L62) · 채택: Sendable, Equatable  
  @CasePathable 열거형으로 라우터가 상위(AppRootFeature)에 알리는 결과를 담는다. projectRegistered(ProjectGenerationReceipt)·generationReminderPreferenceSelected(isEnabled:)·dismissRequested 케이스가 있으며 QuizGenerationProgress와 RepositoryLinkInput의 delegate를 그대로 승격해 전달한다.  
  단어(단일): `Delegate` 위임·대리자. 여기서는 라우터 리듀서가 앱 루트에 넘기는 액션 그룹

## Quiz/LearningCompletion

- **`LearningCompletionFeature`** `struct` · public · [LearningCompletionFeature.swift:6](../../../sources/Projects/Feature/Quiz/LearningCompletion/LearningCompletionFeature.swift#L6) · 채택: Sendable  
  @Reducer 매크로가 붙은 TCA 리듀서로, 학습 세트를 모두 푼 뒤 표시되는 완료 화면의 상태와 액션을 다룬다. view의 closeTapped와 primaryActionTapped를 모두 delegate(.dismissRequested)로 변환하며, QuizRouterFeature가 자식 리듀서로 합성하고 LearningCompletionScreen이 store로 사용한다.  
  단어: `Learning` 학습·배움. 여기서는 퀴즈 세트를 푸는 사용자의 학습 흐름을 가리킨다. · `Completion` 완료·끝마침. 여기서는 학습 세트의 모든 문제를 마친 상태를 가리킨다. · `Feature` 기능·특성. 여기서는 TCA에서 State·Action·body를 묶어 한 화면의 로직을 담당하는 리듀서 단위를 가리킨다.
- **`LearningCompletionFeature.State`** `struct` · public · [LearningCompletionFeature.swift:15](../../../sources/Projects/Feature/Quiz/LearningCompletion/LearningCompletionFeature.swift#L15) · 채택: Equatable, Sendable  
  @ObservableState가 붙은 학습 완료 화면의 상태로, projectID와 객관식 정답 수(correctChoiceCount)·객관식 문제 수(choiceQuestionCount)를 보유한다. 객관식 문제가 하나라도 있으면 점수를 표시하는 isScorePresented와 접근성 문구 scoreAccessibilityLabel을 계산한다.  
  단어(단일): `State` 상태. 여기서는 TCA 리듀서가 소유하는 학습 완료 화면의 관찰 가능한 상태 값 묶음을 가리킨다.
- **`LearningCompletionFeature.Action`** `enum` · public · [LearningCompletionFeature.swift:47](../../../sources/Projects/Feature/Quiz/LearningCompletion/LearningCompletionFeature.swift#L47) · 채택: ViewAction, Sendable, Equatable  
  학습 완료 화면 리듀서가 받는 액션의 최상위 열거형으로, 화면 입력을 감싸는 view(View)와 부모에게 알리는 delegate(Delegate) 두 케이스만 가진다. ViewAction을 채택해 @ViewAction 화면에서 send(_:)로 View 케이스를 보낼 수 있게 한다.  
  단어(단일): `Action` 동작·행위. 여기서는 TCA 리듀서에 전달되어 상태 변경이나 Effect를 유발하는 이벤트 열거형을 가리킨다.
- **`LearningCompletionFeature.Action.View`** `enum` · public · [LearningCompletionFeature.swift:53](../../../sources/Projects/Feature/Quiz/LearningCompletion/LearningCompletionFeature.swift#L53) · 채택: Sendable, Equatable  
  @CasePathable이 붙은 화면 입력 액션으로, 닫기 버튼 탭(closeTapped)과 하단 확인 버튼 탭(primaryActionTapped) 두 케이스를 가진다. LearningCompletionScreen이 send(.closeTapped) 등으로 보낸다.  
  단어(단일): `View` 보기·화면. 여기서는 SwiftUI 화면에서 발생한 사용자 입력을 나타내는 액션 묶음을 가리킨다.
- **`LearningCompletionFeature.Action.Delegate`** `enum` · public · [LearningCompletionFeature.swift:59](../../../sources/Projects/Feature/Quiz/LearningCompletion/LearningCompletionFeature.swift#L59) · 채택: Sendable, Equatable  
  @CasePathable이 붙은 부모 통지 액션으로, 완료 화면을 닫아 달라는 dismissRequested 케이스 하나만 가진다. 리듀서는 닫기·확인 탭을 모두 이 케이스로 보내고 자신은 처리하지 않는다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 자식 리듀서가 직접 처리하지 않고 부모(QuizRouterFeature)에게 처리를 넘기는 액션 묶음을 가리킨다.
- **`LearningCompletionScreen`** `struct` · internal · [LearningCompletionScreen.swift:9](../../../sources/Projects/Feature/Quiz/LearningCompletion/LearningCompletionScreen.swift#L9) · 채택: View · 그래프 미수집(grep 보강)  
  @ViewAction(for: LearningCompletionFeature.self)이 붙은 SwiftUI 화면으로, StoreOf<LearningCompletionFeature>를 받아 닫기 컨트롤 바, 완료 애니메이션(ResourceAnimation .complete), "학습을 마쳤어요" 문구, 객관식 점수(정답 수/문제 수)와 안내 문구, 하단 "확인" 버튼을 그린다. QuizRouter가 완료 단계에서 이 화면을 생성한다.  
  단어: `Learning` 학습·배움. 여기서는 퀴즈 세트를 푸는 사용자의 학습 흐름을 가리킨다. · `Completion` 완료·끝마침. 여기서는 학습 세트의 모든 문제를 마친 상태를 가리킨다. · `Screen` 화면. 여기서는 Feature 패키지에서 store를 받아 한 화면 전체를 그리는 SwiftUI View를 가리킨다.
- **`LearningCompletionScreen.Constant`** `enum` · fileprivate · [LearningCompletionScreen.swift:75](../../../sources/Projects/Feature/Quiz/LearningCompletion/LearningCompletionScreen.swift#L75)  
  LearningCompletionScreen의 extension 안에 선언된 케이스 없는 열거형으로, 콘텐츠 간격·애니메이션 크기·점수 구분선 크기·하단 버튼 패딩 같은 레이아웃 값과 안내 문구 message를 static 상수로 모아 둔다.  
  단어(단일): `Constant` 상수. 여기서는 화면 레이아웃 수치와 고정 문구를 static let으로 모아 둔 네임스페이스를 가리킨다.

## Quiz/LearningSetIntro

- **`LearningSetIntroFeature`** `struct` · public · [LearningSetIntroFeature.swift:8](../../../sources/Projects/Feature/Quiz/LearningSetIntro/LearningSetIntroFeature.swift#L8) · 채택: Sendable  
  @Reducer 매크로가 붙은 TCA 리듀서로, 학습 세트 시작 전 소개 화면의 로직을 담당한다. 생성자로 주입된 fetchQuizSet·fetchBookmarks 클로저로 세트와 북마크를 불러오고, 시작 탭 시 LearningSetResumption과 북마크된 문제 ID를 담아 delegate(.startRequested)를 보내며, 요청 ID로 늦게 도착한 세트 응답을 무시한다.  
  단어: `Learning` 학습·배움. 여기서는 퀴즈 세트를 푸는 사용자의 학습 흐름을 가리킨다. · `Set` 집합·묶음. 여기서는 프로젝트 하나에서 생성된 퀴즈 묶음(QuizSet, 학습 세트)을 가리킨다. · `Intro` Introduction의 축약, 소개·도입. 여기서는 세트를 풀기 전에 제목·설명을 보여 주고 시작을 받는 진입 화면을 가리킨다. · `Feature` 기능·특성. 여기서는 TCA에서 State·Action·body를 묶어 한 화면의 로직을 담당하는 리듀서 단위를 가리킨다.
- **`LearningSetIntroFeature.SetLoad`** `enum` · public · [LearningSetIntroFeature.swift:23](../../../sources/Projects/Feature/Quiz/LearningSetIntro/LearningSetIntroFeature.swift#L23) · 채택: Equatable, Sendable  
  학습 세트 불러오기의 진행 상태를 나타내는 열거형으로 idle, loading(requestID:), loaded(QuizSet), failed(QuizDetailError) 케이스를 가진다. State.setLoad에 저장되며 화면은 failed면 ErrorView, loading이면 ProgressView를 보여 준다.  
  단어: `Set` 집합·묶음. 여기서는 불러오는 대상인 퀴즈 묶음(QuizSet, 학습 세트)을 가리킨다. · `Load` 불러오기·적재. 여기서는 세트를 비동기로 가져오는 작업과 그 진행 상태를 가리킨다.
- **`LearningSetIntroFeature.BookmarkLoad`** `enum` · public · [LearningSetIntroFeature.swift:30](../../../sources/Projects/Feature/Quiz/LearningSetIntro/LearningSetIntroFeature.swift#L30) · 채택: Equatable, Sendable  
  프로젝트의 북마크 목록 불러오기 진행 상태를 나타내는 열거형으로 idle, loading, loaded(Set<QuizID>), failed(QuizDetailError) 케이스를 가진다. loaded 값은 State.bookmarkedQuestionIDs로 노출되어 startRequested 위임 액션에 함께 전달된다.  
  단어: `Bookmark` 책갈피·즐겨찾기. 여기서는 사용자가 저장해 둔 퀴즈 문제(북마크)를 가리킨다. · `Load` 불러오기·적재. 여기서는 북마크 목록을 비동기로 가져오는 작업과 그 진행 상태를 가리킨다.
- **`LearningSetIntroFeature.State`** `struct` · public · [LearningSetIntroFeature.swift:37](../../../sources/Projects/Feature/Quiz/LearningSetIntro/LearningSetIntroFeature.swift#L37) · 채택: Equatable, Sendable  
  @ObservableState가 붙은 세트 소개 화면 상태로, projectID·setID·label·autoStartsOnLoad와 setLoad·bookmarkLoad·isEmptySetReported·loadRequestID를 보유한다. 계산 속성 learningSet, bookmarkedQuestionIDs, isStartEnabled(세트가 로드됐고 빈 세트 보고가 없을 때)를 제공한다.  
  단어(단일): `State` 상태. 여기서는 TCA 리듀서가 소유하는 세트 소개 화면의 관찰 가능한 상태 값 묶음을 가리킨다.
- **`LearningSetIntroFeature.Action`** `enum` · public · [LearningSetIntroFeature.swift:82](../../../sources/Projects/Feature/Quiz/LearningSetIntro/LearningSetIntroFeature.swift#L82) · 채택: ViewAction, Sendable, Equatable  
  세트 소개 화면 리듀서의 최상위 액션으로 view(View), input(Input), effect(EffectEvent), delegate(Delegate) 네 케이스를 가진다. 화면 입력, 외부 입력, 비동기 결과, 부모 통지를 케이스로 구분한다.  
  단어(단일): `Action` 동작·행위. 여기서는 TCA 리듀서에 전달되어 상태 변경이나 Effect를 유발하는 이벤트 열거형을 가리킨다.
- **`LearningSetIntroFeature.Action.View`** `enum` · public · [LearningSetIntroFeature.swift:90](../../../sources/Projects/Feature/Quiz/LearningSetIntro/LearningSetIntroFeature.swift#L90) · 채택: Sendable, Equatable  
  @CasePathable이 붙은 화면 입력 액션으로 task(화면 등장 시 로드 시작), retryTapped, startTapped, backTapped 케이스를 가진다. LearningSetIntroScreen과 ErrorView의 버튼에서 send로 보낸다.  
  단어(단일): `View` 보기·화면. 여기서는 SwiftUI 화면에서 발생한 사용자 입력과 생명주기 이벤트를 나타내는 액션 묶음을 가리킨다.
- **`LearningSetIntroFeature.Action.Input`** `enum` · public · [LearningSetIntroFeature.swift:98](../../../sources/Projects/Feature/Quiz/LearningSetIntro/LearningSetIntroFeature.swift#L98) · 채택: Sendable, Equatable  
  @CasePathable이 붙은 외부 입력 액션으로, 세트에 풀 문제가 없음을 알리는 emptySetReported 케이스 하나를 가진다. 리듀서는 이를 받아 isEmptySetReported를 true로 바꿔 시작 버튼을 비활성화한다.  
  단어(단일): `Input` 입력. 여기서는 화면이 아닌 바깥(부모 리듀서 등)에서 이 리듀서로 들어오는 액션 묶음을 가리킨다.
- **`LearningSetIntroFeature.Action.EffectEvent`** `enum` · public · [LearningSetIntroFeature.swift:103](../../../sources/Projects/Feature/Quiz/LearningSetIntro/LearningSetIntroFeature.swift#L103) · 채택: Sendable, Equatable  
  @CasePathable이 붙은 비동기 결과 액션으로, 세트 로드 완료 setLoadFinished(requestID:result:)와 북마크 로드 완료 bookmarksLoadFinished(Result)를 가진다. loadSet·loadBookmarks의 .run Effect가 성공·실패를 Result로 감싸 보낸다.  
  단어: `Effect` 효과·부수 효과. 여기서는 TCA에서 비동기 작업을 수행하는 Effect를 가리킨다. · `Event` 사건·이벤트. 여기서는 Effect가 끝난 뒤 리듀서로 되돌아오는 결과 액션을 가리킨다.
- **`LearningSetIntroFeature.Action.Delegate`** `enum` · public · [LearningSetIntroFeature.swift:109](../../../sources/Projects/Feature/Quiz/LearningSetIntro/LearningSetIntroFeature.swift#L109) · 채택: Sendable, Equatable  
  @CasePathable이 붙은 부모 통지 액션으로, 학습 시작 요청 startRequested(set:resumption:bookmarkedQuestionIDs:)와 뒤로 가기 요청 backRequested를 가진다. startRequested는 QuizSet, LearningSetResumption, 북마크된 QuizID 집합을 함께 전달한다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 자식 리듀서가 직접 처리하지 않고 부모(QuizRouterFeature)에게 처리를 넘기는 액션 묶음을 가리킨다.
- **`LearningSetIntroFeature.CancelID`** `enum` · private · [LearningSetIntroFeature.swift:177](../../../sources/Projects/Feature/Quiz/LearningSetIntro/LearningSetIntroFeature.swift#L177) · 채택: Hashable  
  세트 로드와 북마크 로드 Effect를 취소 가능하게 식별하는 private 열거형으로 setLoad, bookmarkLoad 케이스를 가진다. .cancellable(id:cancelInFlight: true)에 넘겨 같은 종류의 진행 중 요청을 새 요청이 대체하게 한다.  
  단어: `Cancel` 취소. 여기서는 진행 중인 TCA Effect를 중단하는 동작을 가리킨다. · `ID` Identifier, 식별자. 여기서는 취소 대상 Effect를 구별하는 Hashable 키를 가리킨다.
- **`LearningSetIntroScreen`** `struct` · internal · [LearningSetIntroScreen.swift:9](../../../sources/Projects/Feature/Quiz/LearningSetIntro/LearningSetIntroScreen.swift#L9) · 채택: View · 그래프 미수집(grep 보강)  
  @ViewAction(for: LearningSetIntroFeature.self)이 붙은 SwiftUI 화면으로, setLoad가 failed면 ErrorView를, 아니면 OverlayContainer 안에 label·세트 제목·설명과 그라데이션 배경, 하단 "시작하기" 버튼(BottomActionBar)을 그리고 loading 중에는 ProgressView를 겹친다. .task에서 .view(.task)를 보내 로드를 시작하며 QuizRouter가 생성한다.  
  단어: `Learning` 학습·배움. 여기서는 퀴즈 세트를 푸는 사용자의 학습 흐름을 가리킨다. · `Set` 집합·묶음. 여기서는 프로젝트 하나에서 생성된 퀴즈 묶음(QuizSet, 학습 세트)을 가리킨다. · `Intro` Introduction의 축약, 소개·도입. 여기서는 세트 제목·설명을 보여 주고 시작을 받는 진입 화면을 가리킨다. · `Screen` 화면. 여기서는 Feature 패키지에서 store를 받아 한 화면 전체를 그리는 SwiftUI View를 가리킨다.
- **`LearningSetIntroScreen.Constant`** `enum` · fileprivate · [LearningSetIntroScreen.swift:89](../../../sources/Projects/Feature/Quiz/LearningSetIntro/LearningSetIntroScreen.swift#L89)  
  LearningSetIntroScreen의 extension 안에 선언된 케이스 없는 열거형으로 textTopPadding, textSpacing, descriptionTopPadding, bottomButtonPadding 네 개의 CGFloat 레이아웃 상수를 담는다.  
  단어(단일): `Constant` 상수. 여기서는 화면 레이아웃 수치를 static let으로 모아 둔 네임스페이스를 가리킨다.

## Quiz/LearningSetIntro/SubViews

- **`LearningSetIntroScreen.ErrorView`** `struct` · internal · [LearningSetIntroScreen+ErrorView.swift:6](../../../sources/Projects/Feature/Quiz/LearningSetIntro/SubViews/LearningSetIntroScreen+ErrorView.swift#L6) · 채택: View  
  LearningSetIntroScreen의 중첩 SwiftUI 뷰로, 세트 로드 실패 시 뒤로 가기 컨트롤 바와 "학습 세트를 불러오지 못했어요" 안내, "다시 시도하기" 버튼을 그린다. bottomButtonPadding과 onBack·onRetry 클로저를 부모 화면에서 주입받는다.  
  단어: `Error` 오류. 여기서는 학습 세트 불러오기가 실패한 상황을 가리킨다. · `View` 보기·뷰. 여기서는 오류 상황을 표시하는 SwiftUI 하위 뷰를 가리킨다.
- **`LearningSetIntroScreen.ErrorView.Constant`** `enum` · private · [LearningSetIntroScreen+ErrorView.swift:36](../../../sources/Projects/Feature/Quiz/LearningSetIntro/SubViews/LearningSetIntroScreen+ErrorView.swift#L36)  
  ErrorView 안에 선언된 private 케이스 없는 열거형으로, 안내 문구 두 줄 사이 간격 textSpacing(10) 상수 하나를 담는다.  
  단어(단일): `Constant` 상수. 여기서는 오류 뷰의 레이아웃 수치를 static let으로 모아 둔 네임스페이스를 가리킨다.

## Quiz/QuestionSolving

- **`QuestionSolvingFeature`** `struct` · public · [QuestionSolvingFeature.swift:8](../../../sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingFeature.swift#L8) · 채택: Sendable  
  @Reducer 매크로가 붙은 TCA 리듀서로, 문제 하나를 푸는 화면의 로직을 담당한다. 생성자로 주입된 gradeChoiceAnswer·gradeEssayAnswer·setBookmark 클로저로 객관식·서술형 답안 채점과 북마크 토글을 수행하고, 선택지 선택·서술 입력(essayCharacterLimit 400자)·제출·다음 진행·출처 시트·외부 링크·뒤로 가기를 처리하며 QuizRouterFeature가 자식으로 합성한다.  
  단어: `Question` 질문·문제. 여기서는 학습 세트에 속한 퀴즈 문제(Quiz) 하나를 가리킨다. · `Solving` 풀이·해결. 여기서는 사용자가 문제에 답안을 작성해 제출하고 채점 결과를 보는 행위를 가리킨다. · `Feature` 기능·특성. 여기서는 TCA에서 State·Action·body를 묶어 한 화면의 로직을 담당하는 리듀서 단위를 가리킨다.
- **`QuestionSolvingFeature.AnswerOutcome`** `enum` · public · [QuestionSolvingFeature.swift:25](../../../sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingFeature.swift#L25) · 채택: Equatable, Sendable  
  제출된 답안의 채점 결과를 문제 유형별로 담는 열거형으로 choice(ChoiceGrading)와 essay(EssayGrading) 케이스를 가진다. Submission.answered의 연관값이며 화면은 이를 보고 AI 해설이나 서술형 결과 섹션을 그린다.  
  단어: `Answer` 답·답안. 여기서는 사용자가 문제에 제출한 응답을 가리킨다. · `Outcome` 결과·성과. 여기서는 답안을 채점해 돌려받은 객관식·서술형 채점 결과를 가리킨다.
- **`QuestionSolvingFeature.Submission`** `enum` · public · [QuestionSolvingFeature.swift:30](../../../sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingFeature.swift#L30) · 채택: Equatable, Sendable  
  답안 제출의 진행 단계를 나타내는 열거형으로 editing, submitting, answered(AnswerOutcome), failed(QuizDetailError) 케이스를 가진다. State.submission에 저장되며 isSubmitting·answerOutcome·submissionError 계산 속성의 근거가 된다.  
  단어(단일): `Submission` 제출. 여기서는 작성한 답안을 채점에 넘기는 과정과 그 진행 단계를 가리킨다.
- **`QuestionSolvingFeature.BookmarkMutation`** `enum` · public · [QuestionSolvingFeature.swift:37](../../../sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingFeature.swift#L37) · 채택: Equatable, Sendable  
  북마크 토글 요청의 진행 상태를 나타내는 열거형으로 idle, committing, failed(QuizDetailError) 케이스를 가진다. committing 중에는 bookmarkToggleTapped를 무시하고, 성공 시 isBookmarked를 갱신한 뒤 idle로 돌아간다.  
  단어: `Bookmark` 책갈피·즐겨찾기. 여기서는 현재 문제를 저장 목록에 넣거나 빼는 북마크를 가리킨다. · `Mutation` 변경·변이. 여기서는 북마크 여부를 서버에 바꾸는 쓰기 요청과 그 진행 상태를 가리킨다.
- **`QuestionSolvingFeature.State`** `struct` · public · [QuestionSolvingFeature.swift:43](../../../sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingFeature.swift#L43) · 채택: Equatable, Sendable  
  @ObservableState가 붙은 문제 풀이 화면 상태로, projectID·question(Quiz)·questionNumber·advanceActionTitle과 submission·draftChoiceIndex·draftEssayText·isBookmarked·bookmarkMutation·isSourceSheetPresented를 보유한다. isSourceControlPresented, answerOutcome, submissionError, isSubmitting, isSubmitEnabled(객관식은 선택지가 있을 때, 서술형은 항상)를 계산한다.  
  단어(단일): `State` 상태. 여기서는 TCA 리듀서가 소유하는 문제 풀이 화면의 관찰 가능한 상태 값 묶음을 가리킨다.
- **`QuestionSolvingFeature.Action`** `enum` · public · [QuestionSolvingFeature.swift:107](../../../sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingFeature.swift#L107) · 채택: ViewAction, Sendable, Equatable  
  문제 풀이 화면 리듀서의 최상위 액션으로 view(View), effect(EffectEvent), delegate(Delegate) 세 케이스를 가진다. ViewAction을 채택해 QuestionSolvingScreen이 send(_:)로 View 케이스를 보낼 수 있게 한다.  
  단어(단일): `Action` 동작·행위. 여기서는 TCA 리듀서에 전달되어 상태 변경이나 Effect를 유발하는 이벤트 열거형을 가리킨다.
- **`QuestionSolvingFeature.Action.View`** `enum` · public · [QuestionSolvingFeature.swift:114](../../../sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingFeature.swift#L114) · 채택: Sendable, Equatable  
  @CasePathable이 붙은 화면 입력 액션으로 choiceSelected(Int), essayTextChanged(String), submitAnswerTapped, advanceTapped, bookmarkToggleTapped, sourceTapped, sourceSheetDismissed, sourceLinkTapped(URL), backTapped 케이스를 가진다. QuestionSolvingScreen과 그 하위 뷰의 사용자 조작이 여기로 모인다.  
  단어(단일): `View` 보기·화면. 여기서는 SwiftUI 화면에서 발생한 사용자 입력을 나타내는 액션 묶음을 가리킨다.
- **`QuestionSolvingFeature.Action.EffectEvent`** `enum` · public · [QuestionSolvingFeature.swift:127](../../../sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingFeature.swift#L127) · 채택: Sendable, Equatable  
  @CasePathable이 붙은 비동기 결과 액션으로 choiceAnswerFinished, essayAnswerFinished, bookmarkFinished 세 케이스를 가지며 각각 questionID와 Result를 연관값으로 담는다. 리듀서는 questionID가 현재 문제와 같을 때만 결과를 반영한다.  
  단어: `Effect` 효과·부수 효과. 여기서는 TCA에서 채점·북마크 요청을 수행하는 비동기 Effect를 가리킨다. · `Event` 사건·이벤트. 여기서는 Effect가 끝난 뒤 리듀서로 되돌아오는 결과 액션을 가리킨다.
- **`QuestionSolvingFeature.Action.Delegate`** `enum` · public · [QuestionSolvingFeature.swift:143](../../../sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingFeature.swift#L143) · 채택: Sendable, Equatable  
  @CasePathable이 붙은 부모 통지 액션으로 answerSubmitted(questionID:choiceCorrect:), advanceRequested, externalURLRequested(URL), backRequested 케이스를 가진다. 채점 성공 시 answerSubmitted를 보내며 객관식은 정답 여부를, 서술형은 nil을 choiceCorrect에 담는다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 자식 리듀서가 직접 처리하지 않고 부모(QuizRouterFeature)에게 처리를 넘기는 액션 묶음을 가리킨다.
- **`QuestionSolvingFeature.CancelID`** `enum` · private · [QuestionSolvingFeature.swift:254](../../../sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingFeature.swift#L254) · 채택: Hashable  
  답안 제출 Effect와 북마크 Effect를 취소 가능하게 식별하는 private 열거형으로 submit, bookmark 케이스를 가진다. .cancellable(id:cancelInFlight: true)에 넘겨 같은 종류의 진행 중 요청을 새 요청이 대체하게 한다.  
  단어: `Cancel` 취소. 여기서는 진행 중인 TCA Effect를 중단하는 동작을 가리킨다. · `ID` Identifier, 식별자. 여기서는 취소 대상 Effect를 구별하는 Hashable 키를 가리킨다.
- **`QuestionSolvingScreen`** `struct` · internal · [QuestionSolvingScreen.swift:10](../../../sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingScreen.swift#L10) · 채택: View · 그래프 미수집(grep 보강)  
  @ViewAction(for: QuestionSolvingFeature.self)이 붙은 SwiftUI 화면으로, 컨트롤 바·QuestionPrompt·답안 영역(객관식은 ChoiceSection과 AI 해설 카드, 서술형은 AnswerEditor 또는 EssayResultSection)·제출 실패 안내·출처 버튼·하단 BookmarkButton과 제출/진행 버튼을 그린다. @FocusState로 서술형 입력 포커스를 관리하고 ModalOverlay로 SourceSheet를 띄우며 QuizRouter가 생성한다.  
  단어: `Question` 질문·문제. 여기서는 학습 세트에 속한 퀴즈 문제(Quiz) 하나를 가리킨다. · `Solving` 풀이·해결. 여기서는 사용자가 문제에 답안을 작성해 제출하고 채점 결과를 보는 행위를 가리킨다. · `Screen` 화면. 여기서는 Feature 패키지에서 store를 받아 한 화면 전체를 그리는 SwiftUI View를 가리킨다.
- **`QuestionSolvingScreen.Constant`** `enum` · fileprivate · [QuestionSolvingScreen.swift:185](../../../sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingScreen.swift#L185)  
  QuestionSolvingScreen의 extension 안에 선언된 케이스 없는 열거형으로 섹션 간격·세로 패딩, 서술형 placeholder와 제출 실패 문구, 출처 버튼의 간격·쉐브론 크기·패딩 상수를 담는다.  
  단어(단일): `Constant` 상수. 여기서는 화면 레이아웃 수치와 고정 문구를 static let으로 모아 둔 네임스페이스를 가리킨다.

## Quiz/QuestionSolving/SubViews

- **`QuestionSolvingScreen.AnswerEditor`** `struct` · internal · [QuestionSolvingScreen+AnswerEditor.swift:6](../../../sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+AnswerEditor.swift#L6) · 채택: View  
  QuestionSolvingScreen의 중첩 SwiftUI 뷰로, 서술형 답안을 입력하는 TextEditor를 placeholder·포커스 여부에 따른 테두리(BorderToken .focus/.default)·글자 수 카운터와 함께 그린다. @Binding text, FocusState 바인딩, placeholder, characterLimit, isDisabled를 부모에게서 받는다.  
  단어: `Answer` 답·답안. 여기서는 서술형 문제에 사용자가 작성하는 텍스트 답안을 가리킨다. · `Editor` 편집기. 여기서는 답안 텍스트를 입력·수정하는 TextEditor 기반 입력 영역을 가리킨다.
- **`QuestionSolvingScreen.AnswerEditor.Constant`** `enum` · private · [QuestionSolvingScreen+AnswerEditor.swift:53](../../../sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+AnswerEditor.swift#L53)  
  AnswerEditor 안에 선언된 private 케이스 없는 열거형으로 텍스트 스타일 토큰(body1), 최소·최대 높이(160·240), 안쪽 여백 textInset(16) 상수를 담는다.  
  단어(단일): `Constant` 상수. 여기서는 답안 편집기의 스타일 토큰과 레이아웃 수치를 static let으로 모아 둔 네임스페이스를 가리킨다.
- **`QuestionSolvingScreen.ChoiceSection`** `struct` · internal · [QuestionSolvingScreen+ChoiceSection.swift:6](../../../sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+ChoiceSection.swift#L6) · 채택: View  
  QuestionSolvingScreen의 중첩 SwiftUI 뷰로, [ChoiceOptionDisplay] 목록을 ChoiceAnswerOption 컴포넌트로 세로 나열하고 A~F 글자, 강조 상태, 펼침 제어를 매핑한다. 채점 전에는 항상 펼친 상태로 onSelect를 받고, 채점 후에는 @State expandedOptionIDs로 토글하며 강조된 선택지를 자동으로 펼친다.  
  단어: `Choice` 선택·선택지. 여기서는 객관식 문제의 보기(선택지)를 가리킨다. · `Section` 구역·섹션. 여기서는 화면 안에서 선택지 목록을 담당하는 영역을 가리킨다.
- **`QuestionSolvingScreen.ChoiceSection.Constant`** `enum` · private · [QuestionSolvingScreen+ChoiceSection.swift:37](../../../sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+ChoiceSection.swift#L37)  
  ChoiceSection 안에 선언된 private 케이스 없는 열거형으로, 선택지 인덱스를 표시 글자로 바꿀 때 쓰는 letters 배열(["A"..."F"]) 상수를 담는다.  
  단어(단일): `Constant` 상수. 여기서는 선택지 글자 배열을 static let으로 모아 둔 네임스페이스를 가리킨다.
- **`QuestionSolvingScreen.EssayResultSection`** `struct` · internal · [QuestionSolvingScreen+EssayResultSection.swift:6](../../../sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+EssayResultSection.swift#L6) · 채택: View  
  QuestionSolvingScreen의 중첩 SwiftUI 뷰로, 서술형 채점 후 "나의 답안"(LabeledCard.neutral)과 "AI 해설"(LabeledCard.accent) 카드를 세로로 그린다. myAnswer, aiAnswer, criteria를 받지만 body는 myAnswer와 aiAnswer만 표시한다.  
  단어: `Essay` 논술·서술. 여기서는 자유 텍스트로 답하는 서술형 문제를 가리킨다. · `Result` 결과. 여기서는 서술형 답안의 채점 결과(내 답안·AI 해설)를 가리킨다. · `Section` 구역·섹션. 여기서는 화면 안에서 서술형 결과를 담당하는 영역을 가리킨다.
- **`QuestionSolvingScreen.QuestionPrompt`** `struct` · internal · [QuestionSolvingScreen+QuestionPrompt.swift:6](../../../sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+QuestionPrompt.swift#L6) · 채택: View  
  QuestionSolvingScreen의 중첩 SwiftUI 뷰로, 문제 번호가 있으면 "문제 N" TagBadge를, 그 아래 문제 지문(prompt)을 subtitle3로 그리고 접근성 요소를 하나로 합친다.  
  단어: `Question` 질문·문제. 여기서는 현재 풀고 있는 퀴즈 문제를 가리킨다. · `Prompt` 지문·질문 문구. 여기서는 문제 본문 텍스트와 번호를 함께 보여 주는 영역을 가리킨다.
- **`QuestionSolvingScreen.QuestionPrompt.Constant`** `enum` · private · [QuestionSolvingScreen+QuestionPrompt.swift:27](../../../sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+QuestionPrompt.swift#L27)  
  QuestionPrompt 안에 선언된 private 케이스 없는 열거형으로, 번호 배지와 지문 사이 간격 contentSpacing(10) 상수 하나를 담는다.  
  단어(단일): `Constant` 상수. 여기서는 문제 지문 뷰의 레이아웃 수치를 static let으로 모아 둔 네임스페이스를 가리킨다.
- **`QuestionSolvingScreen.SourceSheet`** `struct` · internal · [QuestionSolvingScreen+SourceSheet.swift:7](../../../sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+SourceSheet.swift#L7) · 채택: View  
  QuestionSolvingScreen의 중첩 SwiftUI 뷰로, SheetSurface 안에 "문제 N 출처" 제목과 [QuestionSourceDisplay] 목록(요약 텍스트와 링크 칩)을 나열하고 하단 "닫기" 버튼을 둔다. referenceURL이 있는 출처는 링크 아이콘이 있는 Button으로 onLinkTap을 호출한다.  
  단어: `Source` 출처·근거. 여기서는 퀴즈 문제가 만들어진 근거인 코드 파일·심볼·참조 URL(QuizSource)을 가리킨다. · `Sheet` 시트·아래에서 올라오는 패널. 여기서는 ModalOverlay 위에 표시되는 출처 목록 패널을 가리킨다.
- **`QuestionSolvingScreen.SourceSheet.Constant`** `enum` · private · [QuestionSolvingScreen+SourceSheet.swift:38](../../../sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+SourceSheet.swift#L38)  
  SourceSheet 안에 선언된 private 케이스 없는 열거형으로 제목 상단 패딩, 제목-출처 간격, 출처 간 간격, 설명-링크 간격, 버튼 상단 패딩, 링크 칩 패딩과 아이콘 크기 상수를 담는다.  
  단어(단일): `Constant` 상수. 여기서는 출처 시트의 레이아웃 수치를 static let으로 모아 둔 네임스페이스를 가리킨다.

## Quiz/QuestionSolving/ViewModels

- **`ChoiceOptionDisplay`** `struct` · public · [ChoiceOptionDisplay.swift:6](../../../sources/Projects/Feature/Quiz/QuestionSolving/ViewModels/ChoiceOptionDisplay.swift#L6) · 채택: Equatable, Sendable, Identifiable  
  객관식 선택지 하나를 화면용으로 가공한 표시 모델로 id(인덱스)·text·emphasis·isSelected를 보유하고 접근성 문구 accessibilityLabel을 만든다. static editing(choices:selectedIndex:)은 채점 전, answered(choices:selectedIndex:grading:)는 ChoiceGrading의 correctIndex에 따라 정답·오답 강조를 붙여 목록을 생성하며 QuestionSolvingScreen이 ChoiceSection에 넘긴다.  
  단어: `Choice` 선택·선택지. 여기서는 객관식 문제의 보기를 가리킨다. · `Option` 선택 항목. 여기서는 보기 목록 중 항목 하나를 가리킨다. · `Display` 표시·화면 표현. 여기서는 도메인 값을 화면에 그리기 위해 가공한 표시 전용 모델임을 가리킨다.
- **`ChoiceOptionDisplay.Emphasis`** `enum` · public · [ChoiceOptionDisplay.swift:24](../../../sources/Projects/Feature/Quiz/QuestionSolving/ViewModels/ChoiceOptionDisplay.swift#L24) · 채택: Equatable, Sendable  
  선택지의 시각적 강조 상태를 나타내는 열거형으로 neutral, selected, correct, incorrect 케이스를 가진다. ChoiceSection이 이를 ChoiceAnswerOption.State로 변환하고, 접근성 문구에 "정답"·"오답"을 덧붙이는 기준으로 쓴다.  
  단어(단일): `Emphasis` 강조. 여기서는 선택지를 선택됨·정답·오답 중 어떤 스타일로 강조해 그릴지 나타내는 상태를 가리킨다.
- **`QuestionSourceDisplay`** `struct` · public · [QuestionSourceDisplay.swift:6](../../../sources/Projects/Feature/Quiz/QuestionSolving/ViewModels/QuestionSourceDisplay.swift#L6) · 채택: Equatable, Sendable, Identifiable  
  문제 출처(QuizSource)를 화면용으로 가공한 표시 모델로 id·title·detail(행 범위 문구)·lineAnchor(L10-L20 형식)·summary·referenceURL을 보유하고 linkLabel, isLink, accessibilityLabel을 계산한다. static list(sources:)가 filePath·symbol·referenceURL·summary 순으로 제목을 고르고 시작·끝 행에서 detail과 lineAnchor를 만들어 SourceSheet에 넘길 목록을 생성한다.  
  단어: `Question` 질문·문제. 여기서는 출처가 딸린 퀴즈 문제를 가리킨다. · `Source` 출처·근거. 여기서는 문제가 만들어진 근거인 코드 파일·심볼·참조 URL(QuizSource)을 가리킨다. · `Display` 표시·화면 표현. 여기서는 도메인 값을 화면에 그리기 위해 가공한 표시 전용 모델임을 가리킨다.

## Quiz/Router

- **`QuizRouter`** `struct` · public · [QuizRouter.swift:6](../../../sources/Projects/Feature/Quiz/Router/QuizRouter.swift#L6) · 채택: View  
  QuizRouterFeature의 Store를 받아 FlowNavigationStack으로 퀴즈 흐름 화면을 구성하는 SwiftUI View. 루트에 LearningSetIntroScreen을 두고 store.activeScreen에 따라 QuestionSolvingScreen·LearningCompletionScreen을 push 경로로 계산해 보여준다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 학습 세트의 문제를 푸는 퀴즈 흐름(LearningSetIntro → QuestionSolving → LearningCompletion) 전체 · `Router` 경로 지정자·화면 전환 담당. 여기서는 퀴즈 흐름 안에서 어느 화면을 보여줄지 결정하고 하위 화면을 연결하는 역할
- **`QuizRouterFeature`** `struct` · public · [QuizRouterFeature.swift:8](../../../sources/Projects/Feature/Quiz/Router/QuizRouterFeature.swift#L8) · 채택: Sendable  
  퀴즈 흐름(학습 세트 소개→문제 풀이→학습 완료)의 화면 전환과 하위 Feature 연결을 담당하는 @Reducer. QuizDetailUseCase를 생성자 주입받아 LearningSetIntroFeature·QuestionSolvingFeature·LearningCompletionFeature에 클로저로 넘기고, 현재 문제 인덱스·정답 수·북마크 ID를 유지하며 delegate로 외부 URL 열기·닫기 요청을 상위에 전달한다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 학습 세트의 문제를 푸는 퀴즈 흐름(LearningSetIntro → QuestionSolving → LearningCompletion) 전체 · `Router` 경로 지정자·화면 전환 담당. 여기서는 퀴즈 흐름 안에서 어느 화면을 보여줄지 결정하고 하위 화면을 연결하는 역할 · `Feature` 기능·TCA Reducer 단위. 여기서는 State·Action·body를 가진 TCA Reducer 타입
- **`QuizRouterFeature.ActiveScreen`** `enum` · public · [QuizRouterFeature.swift:19](../../../sources/Projects/Feature/Quiz/Router/QuizRouterFeature.swift#L19) · 채택: Hashable, Sendable  
  퀴즈 흐름에서 현재 활성화된 화면을 나타내는 열거형으로 learningSetIntro·questionSolving·learningCompletion 세 case를 가진다. State.activeScreen과 ScreenTransition의 from/to, QuizRouter의 push 경로 계산에 쓰인다.  
  단어: `Active` 활성·현재 동작 중인. 여기서는 지금 사용자에게 보이는 화면 · `Screen` 화면. 여기서는 퀴즈 흐름을 구성하는 개별 화면 단위
- **`QuizRouterFeature.ScreenTransition`** `struct` · public · [QuizRouterFeature.swift:25](../../../sources/Projects/Feature/Quiz/Router/QuizRouterFeature.swift#L25) · 채택: Equatable, Sendable  
  화면 전환 한 건을 기록하는 값 타입으로 출발 화면(from)·도착 화면(to)·원인(cause)을 보유한다. QuizRouterFeature.activate에서 활성 화면이 바뀔 때마다 State.screenTransitions 배열에 추가된다.  
  단어: `Screen` 화면. 여기서는 퀴즈 흐름의 ActiveScreen · `Transition` 전환·이행. 여기서는 한 화면에서 다른 화면으로 넘어간 사건 기록
- **`QuizRouterFeature.ScreenTransition.Cause`** `enum` · public · [QuizRouterFeature.swift:41](../../../sources/Projects/Feature/Quiz/Router/QuizRouterFeature.swift#L41) · 채택: Equatable, Sendable  
  화면 전환이 일어난 원인을 나타내는 열거형으로 startRequested(학습 시작 요청)·advancedToCompletion(마지막 문제 이후 완료 화면 진입) 두 case를 가진다. ScreenTransition.cause 값으로 저장된다.  
  단어(단일): `Cause` 원인·이유. 여기서는 화면 전환을 유발한 사용자 행위 또는 진행 조건
- **`QuizRouterFeature.State`** `struct` · public · [QuizRouterFeature.swift:52](../../../sources/Projects/Feature/Quiz/Router/QuizRouterFeature.swift#L52) · 채택: Equatable, Sendable  
  퀴즈 흐름 라우터의 @ObservableState 상태. projectID·setID·setLabel과 활성 화면·전환 기록, 하위 Feature 상태(learningSetIntro·questionSolving·learningCompletion)를 보유하고, 로드된 QuizSet·현재 문제 인덱스·재개 정보(LearningSetResumption)·세션 정답 수·북마크된 문제 ID 집합을 internal(set)으로 관리한다.  
  단어(단일): `State` 상태. 여기서는 TCA Reducer가 보유·변경하는 관찰 가능한 상태 구조체
- **`QuizRouterFeature.Action`** `enum` · public · [QuizRouterFeature.swift:96](../../../sources/Projects/Feature/Quiz/Router/QuizRouterFeature.swift#L96) · 채택: Sendable, Equatable  
  퀴즈 흐름 라우터의 액션 열거형. 하위 Feature 액션(learningSetIntro·questionSolving·learningCompletion)을 감싸는 case와 상위로 전달하는 delegate case로 구성된다.  
  단어(단일): `Action` 동작·행위. 여기서는 TCA Reducer가 처리하는 액션 열거형
- **`QuizRouterFeature.Action.Delegate`** `enum` · public · [QuizRouterFeature.swift:104](../../../sources/Projects/Feature/Quiz/Router/QuizRouterFeature.swift#L104) · 채택: Sendable, Equatable  
  QuizRouterFeature가 부모 Reducer에게 위임하는 액션 열거형(@CasePathable). externalURLRequested(URL)로 외부 링크 열기를, dismissRequested(projectID:)로 퀴즈 흐름 닫기를 요청한다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 부모 Reducer에게 처리를 위임하는 상위 전달용 액션 묶음
- **`QuizRouterOverlay`** `struct` · public · [QuizRouterOverlay.swift:5](../../../sources/Projects/Feature/Quiz/Router/QuizRouterOverlay.swift#L5) · 채택: View  
  옵셔널 QuizRouterFeature Store를 받아 PushedScreenOverlay로 QuizRouter를 오버레이 표시하는 SwiftUI View. store가 nil이 아니면 표시(isPresented)하며, AppRootView에서 .overlay 수정자로 사용된다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 학습 세트의 문제를 푸는 퀴즈 흐름(LearningSetIntro → QuestionSolving → LearningCompletion) 전체 · `Router` 경로 지정자·화면 전환 담당. 여기서는 퀴즈 흐름 안에서 어느 화면을 보여줄지 결정하고 하위 화면을 연결하는 역할 · `Overlay` 덮어씌우는 층·오버레이. 여기서는 기존 화면 위에 push 형태로 겹쳐 띄우는 컨테이너 뷰

## Quiz/Shared/Models

- **`LearningSetResumption`** `struct` · public · [LearningSetResumption.swift:3](../../../sources/Projects/Feature/Quiz/Shared/Models/LearningSetResumption.swift#L3) · 채택: Equatable, Sendable  
  QuizSet을 받아 학습 재개 지점을 계산하는 값 타입. 첫 미답변 문제 인덱스(startIndex), 객관식 문제 수(choiceQuestionCount), 재개 지점 이전에 이미 맞힌 객관식 수(skippedCorrectChoiceCount)를 보유하며 QuizRouterFeature·LearningSetIntroFeature에서 사용된다.  
  단어: `Learning` 학습. 여기서는 사용자가 퀴즈 세트를 푸는 학습 활동 · `Set` 집합·묶음. 여기서는 프로젝트 하나에서 생성된 퀴즈 묶음(QuizSet, 학습 세트) · `Resumption` 재개·이어하기. 여기서는 이미 답한 문제를 건너뛰고 이어서 풀 시작 위치와 누적 통계

## Saved

- **`SavedFeature`** `struct` · public · [SavedFeature.swift:8](../../../sources/Projects/Feature/Saved/SavedFeature.swift#L8) · 채택: Sendable  
  저장(북마크)한 문제 목록 화면의 @Reducer. fetchBookmarks·setBookmark 클로저를 생성자 주입받아 프로젝트 필터별 북마크 목록을 로드하고, 문제별 북마크 토글을 requestID·CancelID로 중복 없이 처리하며, 문제 풀기 선택·뒤로 가기를 delegate로 상위에 전달한다. MainShellRouterFeature·ProjectDetailRouterFeature에서 생성된다.  
  단어: `Saved` 저장된. 여기서는 사용자가 북마크해 둔 문제 · `Feature` 기능·TCA Reducer 단위. 여기서는 State·Action·body를 가진 TCA Reducer 타입
- **`SavedFeature.LoadStatus`** `enum` · public · [SavedFeature.swift:23](../../../sources/Projects/Feature/Saved/SavedFeature.swift#L23) · 채택: Equatable, Sendable  
  북마크 목록 로드 상태 열거형으로 idle·loading·loaded·failed(QuizDetailError) case를 가진다. State.loadStatus에 저장되어 SavedScreen이 오류 화면·목록 화면 분기에 사용한다.  
  단어: `Load` 불러오기·적재. 여기서는 북마크 목록을 UseCase에서 가져오는 작업 · `Status` 상태·진행 단계. 여기서는 로드 작업의 대기·진행·완료·실패 단계
- **`SavedFeature.BookmarkMutation`** `enum` · public · [SavedFeature.swift:30](../../../sources/Projects/Feature/Saved/SavedFeature.swift#L30) · 채택: Equatable, Sendable  
  문제 하나의 북마크 변경 작업 상태 열거형으로 idle·committing·failed(QuizDetailError) case를 가진다. State.bookmarkMutations에 QuizID별로 저장되어 committing 중인 문제의 중복 토글을 막는다.  
  단어: `Bookmark` 책갈피·북마크. 여기서는 문제를 저장 목록에 넣는 표시 · `Mutation` 변경·변이. 여기서는 북마크 켜기/끄기 요청의 진행 상태
- **`SavedFeature.State`** `struct` · public · [SavedFeature.swift:36](../../../sources/Projects/Feature/Saved/SavedFeature.swift#L36) · 채택: Equatable, Sendable  
  저장한 문제 화면의 @ObservableState 상태. 뒤로 가기 버튼 표시 여부(isBackControlPresented), 선택된 프로젝트 필터, 로드된 QuizBookmarkList, LoadStatus, 요청 순번(requestID), 문제별 북마크 재정의(bookmarkOverrides)와 변경 상태(bookmarkMutations)를 보유하고 isEmpty·isBookmarked(questionID:)를 제공한다.  
  단어(단일): `State` 상태. 여기서는 TCA Reducer가 보유·변경하는 관찰 가능한 상태 구조체
- **`SavedFeature.Action`** `enum` · public · [SavedFeature.swift:70](../../../sources/Projects/Feature/Saved/SavedFeature.swift#L70) · 채택: ViewAction, Sendable, Equatable  
  저장한 문제 화면의 액션 열거형(ViewAction 채택). 뷰 입력 view(View), 비동기 결과 effect(EffectEvent), 상위 전달 delegate(Delegate) 세 case로 구성된다.  
  단어(단일): `Action` 동작·행위. 여기서는 TCA Reducer가 처리하는 액션 열거형
- **`SavedFeature.Action.View`** `enum` · public · [SavedFeature.swift:77](../../../sources/Projects/Feature/Saved/SavedFeature.swift#L77) · 채택: Sendable, Equatable  
  SavedScreen이 보내는 뷰 액션 열거형(@CasePathable). task·retryTapped·filterSelected(projectID:)·solveTapped(QuizBookmark)·bookmarkToggleTapped(QuizBookmark)·backTapped를 가진다.  
  단어(단일): `View` 뷰·화면. 여기서는 SwiftUI 뷰에서 발생한 사용자 입력 액션 묶음
- **`SavedFeature.Action.EffectEvent`** `enum` · public · [SavedFeature.swift:87](../../../sources/Projects/Feature/Saved/SavedFeature.swift#L87) · 채택: Sendable, Equatable  
  비동기 Effect의 완료 결과를 전달하는 액션 열거형(@CasePathable). bookmarksLoadFinished(requestID:result:)로 목록 로드 결과를, bookmarkToggleFinished(questionID:result:)로 북마크 토글 결과를 Reducer에 돌려준다.  
  단어: `Effect` 효과·부수 효과. 여기서는 TCA의 비동기 Effect(.run) 작업 · `Event` 사건·이벤트. 여기서는 Effect가 끝나며 발생시킨 결과 통지
- **`SavedFeature.Action.Delegate`** `enum` · public · [SavedFeature.swift:99](../../../sources/Projects/Feature/Saved/SavedFeature.swift#L99) · 채택: Sendable, Equatable  
  SavedFeature가 부모 Reducer에게 위임하는 액션 열거형(@CasePathable). questionSelected(QuizBookmark)로 문제 풀기 화면 진입을, backRequested로 뒤로 가기를 요청한다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 부모 Reducer에게 처리를 위임하는 상위 전달용 액션 묶음
- **`SavedFeature.CancelID`** `enum` · private · [SavedFeature.swift:160](../../../sources/Projects/Feature/Saved/SavedFeature.swift#L160) · 채택: Hashable  
  SavedFeature의 Effect 취소 식별자 열거형. load(목록 로드)와 bookmarkToggle(QuizID)(문제별 토글) case로 .cancellable(id:cancelInFlight:)에 사용되어 진행 중인 동일 요청을 취소한다.  
  단어: `Cancel` 취소. 여기서는 진행 중인 TCA Effect를 중단하는 동작 · `ID` Identifier(식별자). 여기서는 취소 대상 Effect를 구분하는 키
- **`SavedScreen`** `struct` · internal · [SavedScreen.swift:9](../../../sources/Projects/Feature/Saved/SavedScreen.swift#L9) · 채택: View · 그래프 미수집(grep 보강)  
  SavedFeature Store를 바인딩해 저장한 문제 목록을 그리는 SwiftUI 화면(@ViewAction). loadStatus·isEmpty에 따라 ErrorView·EmptyState·OverlayContainer(헤더+SavedQuestionCard 목록)로 분기하고, FilterSection과 SavedQuestionDisplay를 사용하며 MainShellRouter·ProjectDetailRouter에서 생성된다.  
  단어: `Saved` 저장된. 여기서는 사용자가 북마크한 문제 · `Screen` 화면. 여기서는 Feature 단위의 최상위 SwiftUI 화면 뷰
- **`SavedScreen.Constant`** `enum` · fileprivate · [SavedScreen.swift:141](../../../sources/Projects/Feature/Saved/SavedScreen.swift#L141)  
  SavedScreen 전용 레이아웃 상수 열거형(extension 안 fileprivate). 목록 상단 패딩, 콘텐츠 하단 패딩, 헤더 제목 높이·행 높이·세로 간격·하단 패딩 CGFloat 값을 static let로 보유한다.  
  단어(단일): `Constant` 상수. 여기서는 레이아웃 수치·문구 등 뷰 전용 고정값 묶음

## Saved/SubViews

- **`SavedScreen.ErrorView`** `struct` · internal · [SavedScreen+ErrorView.swift:6](../../../sources/Projects/Feature/Saved/SubViews/SavedScreen+ErrorView.swift#L6) · 채택: View  
  SavedScreen의 로드 실패 화면 서브뷰. isBackControlPresented·onBack·onRetry를 받아 뒤로 가기 IconGlassButton, '저장한 문제' 제목, 실패 안내 문구, '다시 시도하기' ActionButton을 세로로 배치한다.  
  단어: `Error` 오류·실패. 여기서는 북마크 목록 로드 실패 상태 · `View` 뷰. 여기서는 오류 상태를 표시하는 SwiftUI 서브뷰
- **`SavedScreen.ErrorView.Constant`** `enum` · private · [SavedScreen+ErrorView.swift:54](../../../sources/Projects/Feature/Saved/SubViews/SavedScreen+ErrorView.swift#L54)  
  ErrorView 전용 레이아웃 상수 열거형. 문구 간격, 하단 버튼 패딩, 헤더 컨트롤 행 높이, 헤더 제목 간격, 헤더 하단 패딩, 헤더 높이 CGFloat 값을 보유한다.  
  단어(단일): `Constant` 상수. 여기서는 레이아웃 수치·문구 등 뷰 전용 고정값 묶음
- **`SavedScreen.FilterSection`** `struct` · internal · [SavedScreen+FilterSection.swift:8](../../../sources/Projects/Feature/Saved/SubViews/SavedScreen+FilterSection.swift#L8) · 채택: View  
  SavedScreen 헤더에 들어가는 프로젝트 필터 서브뷰. QuizBookmarkProject 목록·선택된 ProjectID·문제 수·onSelect 콜백을 받아 '전체' Chip과 프로젝트별 Chip을 가로 스크롤로 나열하고 아래에 '\(count)개' 문구를 표시한다.  
  단어: `Filter` 거름·필터. 여기서는 저장한 문제를 프로젝트별로 걸러 보는 조건 · `Section` 구역·섹션. 여기서는 화면 헤더 안의 필터 영역
- **`SavedScreen.FilterSection.Constant`** `enum` · private · [SavedScreen+FilterSection.swift:39](../../../sources/Projects/Feature/Saved/SubViews/SavedScreen+FilterSection.swift#L39)  
  FilterSection 전용 상수 열거형. 행 세로 패딩(rowVerticalPadding)과 전체 필터 Chip 문구 allLabel("전체")을 보유한다.  
  단어(단일): `Constant` 상수. 여기서는 레이아웃 수치·문구 등 뷰 전용 고정값 묶음

## Saved/ViewModels

- **`SavedQuestionDisplay`** `struct` · public · [SavedQuestionDisplay.swift:7](../../../sources/Projects/Feature/Saved/ViewModels/SavedQuestionDisplay.swift#L7) · 채택: Equatable, Sendable, Identifiable  
  저장한 문제 카드 하나를 그리기 위한 표시용 값 타입. id(QuizID)·metadata("프로젝트명 · 세트 라벨 · 문제 N")·prompt·isBookmarked를 보유하고, static list(questions:bookmarkOverrides:)로 QuizBookmark 배열을 변환하며 actionTitle("문제풀기")을 제공한다. SavedScreen의 SavedQuestionCard 데이터로 사용된다.  
  단어: `Saved` 저장된. 여기서는 사용자가 북마크한 문제 · `Question` 문제·질문. 여기서는 퀴즈 문제 하나(QuizBookmark) · `Display` 표시·화면 표현. 여기서는 도메인 모델을 카드 UI에 맞게 가공한 표시용 데이터

## Settings/Profile/Previews

- **`ProfilePreviewFixture`** `enum` · private · [ProfileScreenPreviews.swift:5](../../../sources/Projects/Feature/Settings/Profile/Previews/ProfileScreenPreviews.swift#L5)  
  ProfileScreen의 Xcode #Preview에서 쓰는 고정 데이터 네임스페이스. 요일별 WeeklyLearningCount 배열, 빈·활성 LearningStatistics, UserProfile과 Curation을 만드는 정적 함수, EmptyReducer로 ProfileFeature Store를 만드는 store(profileLoad:)를 보유한다.  
  단어: `Profile` 인물 소개·개요. 여기서는 마이(프로필) 화면과 그 화면이 보여주는 사용자 프로필 · `Preview` 미리 보기. 여기서는 SwiftUI #Preview 매크로로 렌더링하는 Xcode 미리 보기 · `Fixture` 고정 장치·고정된 시험 데이터. 여기서는 미리 보기에 넣는 미리 정해진 프로필·통계·Store 값

## Settings/Profile

- **`ProfileFeature`** `struct` · public · [ProfileFeature.swift:4](../../../sources/Projects/Feature/Settings/Profile/ProfileFeature.swift#L4) · 채택: Sendable  
  @Reducer로 선언된 마이(프로필) 화면의 TCA Reducer. 생성자로 주입받은 profile 클로저로 UserProfile을 비동기 조회하고, profileRequestID로 오래된 응답을 걸러 State.profileLoad를 갱신하며, 설정 버튼 탭은 delegate(.settingsRequested)로 상위 SettingsRouterFeature에 전달한다.  
  단어: `Profile` 인물 소개·개요. 여기서는 사용자 이름·이메일·직군·연차·학습 통계를 담은 UserProfile과 그것을 보여주는 마이 화면 · `Feature` 기능·특징. 여기서는 TCA 컨벤션상 State·Action·body를 가진 Reducer 단위
- **`ProfileFeature.State`** `struct` · public · [ProfileFeature.swift:15](../../../sources/Projects/Feature/Settings/Profile/ProfileFeature.swift#L15) · 채택: Equatable, Sendable  
  @ObservableState로 선언된 ProfileFeature의 상태. 프로필 조회 단계 profileLoad(기본 .idle)와 최신 조회 요청을 식별하는 profileRequestID(기본 0)를 보유하며, SettingsRouterFeature.State가 profile 속성으로 포함한다.  
  단어(단일): `State` 상태. 여기서는 TCA Reducer가 소유하고 View가 관찰하는 프로필 화면의 상태 값
- **`ProfileFeature.State.ProfileLoad`** `enum` · public · [ProfileFeature.swift:24](../../../sources/Projects/Feature/Settings/Profile/ProfileFeature.swift#L24) · 채택: Equatable, Sendable  
  프로필 조회의 진행 단계를 나타내는 열거형으로 idle, loading, loaded(UserProfile), failed(UserInfoError) 케이스를 가진다. ProfileDisplay가 표시 상태로 변환하고, SettingsRouterFeature가 화면 전환 시 loaded 값을 SettingsFeature와 주고받는다.  
  단어: `Profile` 인물 소개·개요. 여기서는 조회 대상인 UserProfile · `Load` 적재·불러오기. 여기서는 프로필을 비동기로 불러오는 작업과 그 진행 단계
- **`ProfileFeature.Action`** `enum` · public · [ProfileFeature.swift:36](../../../sources/Projects/Feature/Settings/Profile/ProfileFeature.swift#L36) · 채택: ViewAction, Equatable, Sendable  
  ProfileFeature의 액션을 view(View)·effect(EffectEvent)·delegate(Delegate) 세 갈래로 나눈 열거형. ViewAction을 채택해 ProfileScreen이 @ViewAction의 send로 view 케이스를 보낸다.  
  단어(단일): `Action` 행위·동작. 여기서는 TCA Reducer가 처리하는 입력 이벤트
- **`ProfileFeature.Action.View`** `enum` · public · [ProfileFeature.swift:43](../../../sources/Projects/Feature/Settings/Profile/ProfileFeature.swift#L43) · 채택: Equatable, Sendable  
  @CasePathable로 선언된 화면 발생 액션으로 task(화면 진입 시 조회 시작), retryTapped(실패 후 재시도), settingsTapped(설정 이동 요청)를 가진다. ProfileScreen의 .task 수정자와 버튼 액션에서 보낸다.  
  단어(단일): `View` 보기·화면. 여기서는 SwiftUI 화면(사용자 입력)에서 발생한 액션 묶음
- **`ProfileFeature.Action.EffectEvent`** `enum` · public · [ProfileFeature.swift:50](../../../sources/Projects/Feature/Settings/Profile/ProfileFeature.swift#L50) · 채택: Equatable, Sendable  
  @CasePathable로 선언된 비동기 effect 결과 액션. profileLoadFinished(requestID:result:) 하나로 프로필 조회의 성공(UserProfile) 또는 실패(UserInfoError)를 요청 ID와 함께 Reducer에 되돌려 준다.  
  단어: `Effect` 효과·부수 효과. 여기서는 TCA에서 Reducer 밖에서 실행되는 비동기 작업(프로필 조회) · `Event` 사건·이벤트. 여기서는 그 비동기 작업이 끝났을 때 Reducer로 돌아오는 결과 알림
- **`ProfileFeature.Action.Delegate`** `enum` · public · [ProfileFeature.swift:55](../../../sources/Projects/Feature/Settings/Profile/ProfileFeature.swift#L55) · 채택: Equatable, Sendable  
  @CasePathable로 선언된 상위 위임 액션. settingsRequested 하나이며 settingsTapped 처리 시 보내지고, SettingsRouterFeature가 받아 activeScreen을 .settings(.list)로 바꾼다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 하위 Reducer가 직접 처리하지 않고 상위 Reducer에 넘기는 액션
- **`ProfileFeature.CancelID`** `enum` · private · [ProfileFeature.swift:106](../../../sources/Projects/Feature/Settings/Profile/ProfileFeature.swift#L106)  
  프로필 조회 effect의 취소 식별자로 profile 케이스 하나를 가진다. startProfileLoad가 .cancellable(id: CancelID.profile, cancelInFlight: true)로 사용해 진행 중인 조회를 새 조회로 대체한다.  
  단어: `Cancel` 취소. 여기서는 TCA effect를 취소하는 동작 · `ID` Identifier, 식별자. 여기서는 취소 대상 effect를 구분하는 키
- **`ProfileScreen`** `struct` · public · [ProfileScreen.swift:9](../../../sources/Projects/Feature/Settings/Profile/ProfileScreen.swift#L9) · 채택: View · 그래프 미수집(grep 보강)  
  @ViewAction(for: ProfileFeature.self)로 선언된 마이 화면 SwiftUI View. OverlayContainer 상단에 "마이" ScreenHeaderTitle과 설정 IconGlassButton을 두고, ProfileDisplay의 isFailed·isLoading에 따라 LoadFailureView, ProgressView, 또는 ProfileHeaderView·StatisticsCardView·WeeklyChartView를 배치한다. SettingsRouter가 FlowNavigationStack 루트로 생성한다.  
  단어: `Profile` 인물 소개·개요. 여기서는 사용자 프로필과 학습 현황을 보여주는 마이 화면 · `Screen` 화면. 여기서는 내비게이션 단위가 되는 최상위 SwiftUI View
- **`ProfileScreen.Constant`** `enum` · fileprivate · [ProfileScreen.swift:86](../../../sources/Projects/Feature/Settings/Profile/ProfileScreen.swift#L86)  
  ProfileScreen extension에 선언된 상수 네임스페이스. 제목 "마이", 섹션 제목 "학습 현황", 설정 컨트롤 ScreenControlBar.Control(icon: .setting, label: "설정")과 카드·섹션·로딩·실패·헤더의 패딩·간격·높이 CGFloat 값을 static으로 보유한다.  
  단어(단일): `Constant` 상수. 여기서는 ProfileScreen 레이아웃과 문구의 고정값 모음

## Settings/Profile/SubViews

- **`ProfileScreen.LoadFailureView`** `struct` · internal · [ProfileScreen+LoadFailureView.swift:5](../../../sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+LoadFailureView.swift#L5) · 채택: View  
  프로필 조회 실패 시 ProfileScreen이 보여주는 하위 View. "프로필을 불러오지 못했어요" 제목과 안내 문구를 세로로, "다시 시도" ActionButton.secondary를 오른쪽에 배치하고 버튼 탭 시 onRetry 클로저를 호출한다.  
  단어: `Load` 적재·불러오기. 여기서는 프로필 조회 작업 · `Failure` 실패. 여기서는 프로필 조회가 UserInfoError로 끝난 상태 · `View` 보기·화면 요소. 여기서는 SwiftUI View 프로토콜을 채택한 하위 화면 조각
- **`ProfileScreen.LoadFailureView.Constant`** `enum` · private · [ProfileScreen+LoadFailureView.swift:26](../../../sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+LoadFailureView.swift#L26)  
  LoadFailureView의 상수 네임스페이스. 실패 제목·안내 메시지·재시도 버튼 문구와 메시지 간격(4), 최소 높이(88) 값을 static으로 보유한다.  
  단어(단일): `Constant` 상수. 여기서는 LoadFailureView의 문구와 레이아웃 고정값 모음
- **`ProfileScreen.ProfileHeaderView`** `struct` · internal · [ProfileScreen+ProfileHeaderView.swift:5](../../../sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+ProfileHeaderView.swift#L5) · 채택: View  
  프로필 카드 상단을 그리는 ProfileScreen 하위 View. ProfileDisplay를 받아 원형으로 자른 프로필 아이콘 ResourceImage, 이름·이메일 StyledText, hasBadges일 때 직군(TagBadge.accent)·연차(TagBadge.neutral) 배지를 가로로 배치한다.  
  단어: `Profile` 인물 소개·개요. 여기서는 사용자 이름·이메일·직군·연차 정보 · `Header` 머리글·상단부. 여기서는 마이 화면 콘텐츠 맨 위의 프로필 요약 영역 · `View` 보기·화면 요소. 여기서는 SwiftUI View 프로토콜을 채택한 하위 화면 조각
- **`ProfileScreen.ProfileHeaderView.Constant`** `enum` · private · [ProfileScreen+ProfileHeaderView.swift:42](../../../sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+ProfileHeaderView.swift#L42)  
  ProfileHeaderView의 레이아웃 상수 네임스페이스. 아바타 크기(78), 아바타 간격(15), 정보 간격(8), 배지 간격(6) CGFloat 값을 static으로 보유한다.  
  단어(단일): `Constant` 상수. 여기서는 ProfileHeaderView의 크기·간격 고정값 모음
- **`ProfileScreen.StatisticsCardView`** `struct` · internal · [ProfileScreen+StatisticsCardView.swift:5](../../../sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+StatisticsCardView.swift#L5) · 채택: View  
  학습 통계 카드를 그리는 ProfileScreen 하위 View. ProfileDisplay의 thisWeekSolvedCount·thisMonthSolvedCount·streakDays를 "이번 주"·"이번 달"·"연속 학습" 세 열로 보여주고 blue500 그라데이션 배경의 큰 둥근 사각형에 담는다.  
  단어: `Statistics` 통계. 여기서는 LearningStatistics에서 온 주간·월간 풀이 수와 연속 학습 일수 · `Card` 카드. 여기서는 배경과 둥근 모서리를 가진 카드형 레이아웃 컨테이너 · `View` 보기·화면 요소. 여기서는 SwiftUI View 프로토콜을 채택한 하위 화면 조각
- **`ProfileScreen.StatisticsCardView.Constant`** `enum` · private · [ProfileScreen+StatisticsCardView.swift:24](../../../sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+StatisticsCardView.swift#L24)  
  StatisticsCardView의 상수 네임스페이스. 열 라벨("이번 주", "이번 달", "연속 학습")과 단위("문제", "일") 문구, 카드 높이(88), 열 간격(4), 그라데이션 끝 불투명도(0.5)를 static으로 보유한다.  
  단어(단일): `Constant` 상수. 여기서는 StatisticsCardView의 문구·크기·색 고정값 모음
- **`ProfileScreen.WeeklyChartView`** `struct` · internal · [ProfileScreen+WeeklyChartView.swift:5](../../../sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+WeeklyChartView.swift#L5) · 채택: View  
  주간 문제 풀이량 막대 차트 카드를 그리는 ProfileScreen 하위 View. ProfileDisplay.weeklyTitle을 제목으로 두고 weeklyBars를 ForEach로 순회해 풀이 수 라벨과 그라데이션 막대를 세로로 쌓으며, maxWeeklyCount 대비 비율로 막대 높이를 계산하고 오늘 요일(isHighlighted) 막대는 다른 색으로 강조한다.  
  단어: `Weekly` 주간·매주의. 여기서는 월~일 7일 단위의 학습 기록 · `Chart` 도표·차트. 여기서는 요일별 풀이 수를 높이로 나타내는 막대 그래프 · `View` 보기·화면 요소. 여기서는 SwiftUI View 프로토콜을 채택한 하위 화면 조각
- **`ProfileScreen.WeeklyChartView.Constant`** `enum` · private · [ProfileScreen+WeeklyChartView.swift:46](../../../sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+WeeklyChartView.swift#L46)  
  WeeklyChartView의 상수 네임스페이스. 섹션 라벨 "주간 문제 풀이량"과 카드·차트·막대·라벨 행 높이, 가로·세로 패딩, 막대 간격, 빈 막대 높이(1), 막대 모서리 반경(4) 등 CGFloat 값을 static으로 보유한다.  
  단어(단일): `Constant` 상수. 여기서는 WeeklyChartView의 문구와 차트 레이아웃 고정값 모음

## Settings/Profile/ViewModels

- **`ProfileDisplay`** `struct` · internal · [ProfileDisplay.swift:4](../../../sources/Projects/Feature/Settings/Profile/ViewModels/ProfileDisplay.swift#L4) · 채택: Equatable, Sendable  
  ProfileFeature.State.ProfileLoad를 화면 표시용 값으로 변환하는 뷰 모델. 이름·이메일, PositionDisplay·CareerLevelDisplay로 만든 직군·연차 배지 문구, 주간·월간 풀이 수, 연속 일수, 오늘 요일이 강조된 WeeklyBar 목록, isLoading·isFailed 플래그를 보유하고 weeklyTitle·maxWeeklyCount·currentDayLabel을 계산한다. ProfileScreen과 그 하위 View가 사용한다.  
  단어: `Profile` 인물 소개·개요. 여기서는 UserProfile에 담긴 사용자 정보와 학습 통계 · `Display` 표시·화면에 보이는 것. 여기서는 도메인 값을 View가 바로 그릴 수 있게 가공한 표시 전용 모델
- **`ProfileDisplay.WeeklyBar`** `struct` · internal · [ProfileDisplay.swift:51](../../../sources/Projects/Feature/Settings/Profile/ViewModels/ProfileDisplay.swift#L51) · 채택: Equatable, Sendable, Identifiable  
  주간 차트의 막대 하나를 나타내는 표시 모델. 요일 라벨 dayLabel, 풀이 수 count, 오늘 요일 여부 isHighlighted를 보유하고 dayLabel을 Identifiable id로 쓴다. ProfileDisplay가 WeeklyLearningCount 배열(비어 있으면 기본 요일 7개)에서 만들고 WeeklyChartView가 ForEach로 그린다.  
  단어: `Weekly` 주간·매주의. 여기서는 한 주를 이루는 요일 단위 기록 · `Bar` 막대. 여기서는 막대 차트에서 요일 하나의 풀이 수를 나타내는 막대 데이터

## Settings/Router

- **`SettingsRouter`** `struct` · public · [SettingsRouter.swift:5](../../../sources/Projects/Feature/Settings/Router/SettingsRouter.swift#L5) · 채택: View  
  설정 탭의 내비게이션 SwiftUI View. FlowNavigationStack 루트에 ProfileScreen을 두고 store.activeScreen을 push 경로 배열로 변환해 SettingsScreen과 PositionSelectionView·CareerLevelSelectionView·AccountDeletionView를 destination으로 그린다. MainShellRouter가 settings scope로 생성한다.  
  단어: `Settings` 설정. 여기서는 프로필·설정 목록·직군/연차 선택·탈퇴를 묶은 설정 탭 흐름 · `Router` 경로 안내자·라우터. 여기서는 활성 화면 상태를 내비게이션 스택으로 옮겨 화면을 전환하는 View
- **`SettingsRouterFeature`** `struct` · public · [SettingsRouterFeature.swift:7](../../../sources/Projects/Feature/Settings/Router/SettingsRouterFeature.swift#L7) · 채택: Sendable  
  @Reducer로 선언된 설정 탭 라우팅 Reducer. AccountUseCase·UserInfoUseCase·AppSettingUseCase와 openNotificationSettings 클로저를 생성자 주입받아 ProfileFeature와 SettingsFeature를 Scope로 합성하고, 두 하위 delegate 액션에 따라 activeScreen을 전환하며 프로필 값을 양쪽 State에 동기화하고, signedOut·accountDeleted·externalURLRequested는 자신의 delegate로 상위 MainShellRouterFeature에 전달한다.  
  단어: `Settings` 설정. 여기서는 프로필·설정 목록·직군/연차 선택·탈퇴를 묶은 설정 탭 흐름 · `Router` 경로 안내자·라우터. 여기서는 하위 화면 간 전환 상태(activeScreen)를 결정하는 역할 · `Feature` 기능·특징. 여기서는 TCA 컨벤션상 State·Action·body를 가진 Reducer 단위
- **`SettingsRouterFeature.State`** `struct` · public · [SettingsRouterFeature.swift:26](../../../sources/Projects/Feature/Settings/Router/SettingsRouterFeature.swift#L26) · 채택: Equatable, Sendable  
  @ObservableState로 선언된 SettingsRouterFeature의 상태. 하위 ProfileFeature.State(profile), SettingsFeature.State(settings)와 현재 표시 화면 activeScreen(기본 .profile)을 보유한다.  
  단어(단일): `State` 상태. 여기서는 설정 탭의 하위 상태와 활성 화면을 담은 라우터 Reducer의 상태 값
- **`SettingsRouterFeature.State.ActiveScreen`** `enum` · public · [SettingsRouterFeature.swift:35](../../../sources/Projects/Feature/Settings/Router/SettingsRouterFeature.swift#L35) · 채택: Hashable, Sendable  
  설정 탭에서 현재 보이는 화면을 나타내는 열거형으로 profile과 settings(SettingsStep) 케이스를 가진다. SettingsRouter가 이 값을 FlowNavigationStack의 push 경로 배열과 destination View로 변환한다.  
  단어: `Active` 활성·현재 동작 중인. 여기서는 지금 사용자에게 보이는 · `Screen` 화면. 여기서는 내비게이션 스택에서 표시되는 화면 단위
- **`SettingsRouterFeature.State.SettingsStep`** `enum` · public · [SettingsRouterFeature.swift:40](../../../sources/Projects/Feature/Settings/Router/SettingsRouterFeature.swift#L40) · 채택: Hashable, Sendable  
  설정 화면 안의 단계를 나타내는 열거형으로 list, positionSelection, careerLevelSelection, accountDeletion 케이스를 가진다. ActiveScreen.settings의 연관값이며 list 외 단계는 list 위에 한 단계 더 push된다.  
  단어: `Settings` 설정. 여기서는 SettingsScreen과 그 하위 선택·탈퇴 화면 · `Step` 단계. 여기서는 설정 흐름 안에서 목록·직군 선택·연차 선택·탈퇴 중 어느 화면인지
- **`SettingsRouterFeature.Action`** `enum` · public · [SettingsRouterFeature.swift:53](../../../sources/Projects/Feature/Settings/Router/SettingsRouterFeature.swift#L53) · 채택: Equatable, Sendable  
  SettingsRouterFeature의 액션으로 하위 profile(ProfileFeature.Action), settings(SettingsFeature.Action)와 상위 위임 delegate(Delegate) 케이스를 가진다. body의 Reduce가 하위 delegate 케이스를 패턴 매칭해 화면 전환을 처리한다.  
  단어(단일): `Action` 행위·동작. 여기서는 라우터 Reducer가 처리하는 하위 액션과 위임 액션
- **`SettingsRouterFeature.Action.Delegate`** `enum` · public · [SettingsRouterFeature.swift:60](../../../sources/Projects/Feature/Settings/Router/SettingsRouterFeature.swift#L60) · 채택: Equatable, Sendable  
  @CasePathable로 선언된 상위 위임 액션으로 signedOut, accountDeleted, externalURLRequested(URL) 케이스를 가진다. SettingsFeature의 같은 이름 delegate를 받아 그대로 상위 MainShellRouterFeature로 전달할 때 보낸다.  
  단어(단일): `Delegate` 위임·대리. 여기서는 로그아웃·탈퇴·외부 URL 열기처럼 설정 탭 밖에서 처리해야 하는 결과를 상위에 넘기는 액션

## Settings/Settings/Previews

- **`SettingsPreviewFixture`** `enum` · private · [SettingsScreenPreviews.swift:5](../../../sources/Projects/Feature/Settings/Settings/Previews/SettingsScreenPreviews.swift#L5)  
  SettingsScreen 관련 #Preview에서 쓰는 UserProfile·Curation 샘플과 EmptyReducer 기반 StoreOf<SettingsFeature>를 만드는 파일 전용 팩토리 enum이다. profile, curation, store 정적 함수만 가지며 상태(profile, accountAction, positionMutation)를 인자로 받아 미리보기 시나리오를 구성한다.  
  단어: `Settings` 설정·환경 설정. 여기서는 앱의 설정 화면(직군·연차·알림·약관·로그아웃·계정 삭제) 기능 영역 · `Preview` 미리보기. 여기서는 Xcode #Preview에서만 쓰는 지원 코드 · `Fixture` 고정 장치·시험용 고정 데이터. 여기서는 미리보기에 넣을 미리 정해진 프로필·스토어 샘플

## Settings/Settings

- **`SettingsFeature`** `struct` · public · [SettingsFeature.swift:9](../../../sources/Projects/Feature/Settings/Settings/SettingsFeature.swift#L9) · 채택: Sendable  
  @Reducer로 선언된 설정 화면 리듀서로, signOut·profile·updatePosition·updateCareerLevel·withdraw·알림 권한 조회/요청/설정 열기 클로저를 생성자로 주입받는다. 프로필 조회, 직군·연차 변경, 알림 권한 확인, 로그아웃·계정 삭제 흐름을 처리하고 화면 전환·완료 결과를 Delegate 액션으로 상위에 전달한다.  
  단어: `Settings` 설정·환경 설정. 여기서는 앱의 설정 화면(직군·연차·알림·약관·로그아웃·계정 삭제) 기능 영역 · `Feature` 기능·특징. 여기서는 TCA 컨벤션상 State·Action·body를 가진 Reducer 타입을 뜻하는 접미어
- **`SettingsFeature.State`** `struct` · public · [SettingsFeature.swift:36](../../../sources/Projects/Feature/Settings/Settings/SettingsFeature.swift#L36) · 채택: Equatable, Sendable  
  SettingsFeature의 @ObservableState 상태 구조체다. profile(UserProfile?), profileLoad, positionMutation, careerLevelMutation, accountAction, notificationStatus 값을 보유하며 기본 생성자는 모두 idle·nil로 시작한다.  
  단어(단일): `State` 상태. 여기서는 TCA 리듀서가 소유하는 설정 화면의 관찰 가능한 상태 값 묶음
- **`SettingsFeature.ProfileLoad`** `enum` · public · [SettingsFeature.swift:48](../../../sources/Projects/Feature/Settings/Settings/SettingsFeature.swift#L48) · 채택: Equatable, Sendable  
  프로필 조회의 진행 상태(idle·loading·loaded·failed(UserInfoError))를 나타내는 enum이다. State.profileLoad에 담기며 SettingsScreen이 프로필 실패 메시지 표시 여부를 판단할 때 사용한다.  
  단어: `Profile` 프로필·개인 정보 요약. 여기서는 UserProfile(이름·이메일·통계·직군·연차) 조회 대상 · `Load` 적재·불러오기. 여기서는 프로필을 서버에서 불러오는 작업과 그 진행 단계
- **`SettingsFeature.MutationStatus`** `enum` · public · [SettingsFeature.swift:55](../../../sources/Projects/Feature/Settings/Settings/SettingsFeature.swift#L55) · 채택: Equatable, Sendable  
  직군·연차 변경 요청의 진행 상태(idle·committing·failed(UserInfoError))를 나타내는 enum이다. State.positionMutation과 careerLevelMutation에 공용으로 쓰이며 committing 중에는 같은 종류의 변경 요청을 다시 시작하지 않도록 막는 기준이 된다.  
  단어: `Mutation` 변이·변경. 여기서는 프로필의 직군 또는 연차 값을 서버에 갱신하는 쓰기 요청 · `Status` 상태·진행 상황. 여기서는 그 변경 요청이 대기·진행·실패 중 어디에 있는지
- **`SettingsFeature.AccountAction`** `enum` · public · [SettingsFeature.swift:61](../../../sources/Projects/Feature/Settings/Settings/SettingsFeature.swift#L61) · 채택: Equatable, Sendable  
  로그아웃·계정 삭제 같은 계정 조작의 진행 상태(idle·signingOut·confirmingDeletion·deletingAccount·failed(UserInfoError))를 나타내는 enum이다. fileprivate 계산 속성 canStartAccountAction으로 idle·failed일 때만 새 계정 조작을 시작할 수 있게 판단한다.  
  단어: `Account` 계정. 여기서는 사용자의 로그인 계정(로그아웃·삭제 대상) · `Action` 동작·조치. 여기서는 계정에 가하는 로그아웃·삭제 조작과 그 진행 상태(TCA Action 타입이 아님)
- **`SettingsFeature.NotificationStatus`** `enum` · public · [SettingsFeature.swift:84](../../../sources/Projects/Feature/Settings/Settings/SettingsFeature.swift#L84) · 채택: Equatable, Sendable  
  알림 권한을 화면에 표시하기 위한 상태(idle·allowed·denied) enum이다. NotificationAuthorizationStatus 확인 결과를 authorized면 allowed, 그 외는 denied로 매핑해 State.notificationStatus에 보관하며 SettingsScreen이 '켜짐/꺼짐' 값으로 바꿔 보여 준다.  
  단어: `Notification` 알림. 여기서는 세트 생성 완료 푸시 알림에 대한 시스템 권한 · `Status` 상태. 여기서는 알림 권한이 미확인·허용·거부 중 어느 것인지
- **`SettingsFeature.Action`** `enum` · public · [SettingsFeature.swift:90](../../../sources/Projects/Feature/Settings/Settings/SettingsFeature.swift#L90) · 채택: ViewAction, Sendable, Equatable  
  SettingsFeature의 액션 루트 enum으로 view(View)·effect(EffectEvent)·delegate(Delegate) 세 갈래로 나뉜다. ViewAction을 채택해 @ViewAction 화면의 send(_:)가 view 케이스로 감싸 보내도록 한다.  
  단어(단일): `Action` 동작·행위. 여기서는 TCA 리듀서가 처리하는 모든 입력 이벤트의 루트 타입
- **`SettingsFeature.Action.View`** `enum` · public · [SettingsFeature.swift:97](../../../sources/Projects/Feature/Settings/Settings/SettingsFeature.swift#L97) · 채택: Sendable, Equatable  
  SettingsScreen과 하위 뷰에서 발생하는 생명주기·사용자 입력 액션 enum이다. task, applicationBecameActive, backTapped, 직군·연차·알림·약관 행 탭, positionSelected, careerLevelSelected, signOutTapped, deleteAccountTapped/Cancelled/Confirmed 케이스를 가지며 @CasePathable이 적용돼 있다.  
  단어(단일): `View` 보기·뷰. 여기서는 SwiftUI 뷰에서 올라오는 사용자 입력·생명주기 액션 묶음
- **`SettingsFeature.Action.EffectEvent`** `enum` · public · [SettingsFeature.swift:114](../../../sources/Projects/Feature/Settings/Settings/SettingsFeature.swift#L114) · 채택: Sendable, Equatable  
  비동기 Effect의 완료 결과를 리듀서로 되돌리는 액션 enum이다. profileLoadFinished, notificationAuthorizationChecked, positionUpdateFinished, careerLevelUpdateFinished, signOutFinished, deleteAccountFinished 케이스로 각각 결과 값이나 UserInfoError?를 담는다.  
  단어: `Effect` 효과·부수 효과. 여기서는 TCA Effect(.run)로 실행한 비동기 작업 · `Event` 사건·발생한 일. 여기서는 그 비동기 작업이 끝나 리듀서에 알리는 결과 이벤트
- **`SettingsFeature.Action.Delegate`** `enum` · public · [SettingsFeature.swift:124](../../../sources/Projects/Feature/Settings/Settings/SettingsFeature.swift#L124) · 채택: Sendable, Equatable  
  상위 리듀서(라우터)에 전달하는 결과 액션 enum이다. backRequested, positionSelectionRequested, careerLevelSelectionRequested, accountDeletionRequested, accountDeletionCancelled, externalURLRequested(URL), signedOut, accountDeleted 케이스를 가지며 리듀서 자신은 delegate를 받아도 아무 처리를 하지 않는다.  
  단어(단일): `Delegate` 위임·대리인. 여기서는 처리를 상위 리듀서에 위임하기 위해 밖으로 내보내는 액션 묶음
- **`SettingsFeature.CancelID`** `enum` · private · [SettingsFeature.swift:322](../../../sources/Projects/Feature/Settings/Settings/SettingsFeature.swift#L322) · 채택: Hashable  
  SettingsFeature Effect의 취소 식별자 enum으로 positionMutation, careerLevelMutation, accountAction 케이스를 가진다. 직군·연차 변경과 로그아웃·계정 삭제 Effect의 .cancellable(id:)에 사용된다.  
  단어: `Cancel` 취소. 여기서는 진행 중인 TCA Effect를 취소하는 일 · `ID` Identifier(식별자). 여기서는 취소 대상 Effect를 구분하는 Hashable 키
- **`SettingsFeature.Constant`** `enum` · private · [SettingsFeature.swift:328](../../../sources/Projects/Feature/Settings/Settings/SettingsFeature.swift#L328)  
  SettingsFeature의 상수 네임스페이스 enum이다. termsTapped 시 열어 달라고 위임할 서비스 약관·정책 Notion 페이지 주소 servicePolicyURL(URL?) 하나만 보유한다.  
  단어(단일): `Constant` 상수. 여기서는 SettingsFeature가 쓰는 고정 값(약관 URL)의 네임스페이스
- **`SettingsScreen`** `struct` · public · [SettingsScreen.swift:9](../../../sources/Projects/Feature/Settings/Settings/SettingsScreen.swift#L9) · 채택: View · 그래프 미수집(grep 보강)  
  StoreOf<SettingsFeature>를 받아 설정 화면을 그리는 @ViewAction public SwiftUI View다. OverlayContainer 안에 뒤로 가기 헤더와 학습 설정·알림·일반 섹션(SectionView + SettingRow)을 배치하고, task·scenePhase 활성화·각 행 탭을 send로 리듀서에 보내며 accountAction·profileLoad 실패 메시지를 표시한다.  
  단어: `Settings` 설정·환경 설정. 여기서는 앱의 설정 화면(직군·연차·알림·약관·로그아웃·계정 삭제) 기능 영역 · `Screen` 화면. 여기서는 Feature 스토어를 받아 한 화면 전체를 그리는 SwiftUI View 접미어
- **`SettingsScreen.Constant`** `enum` · fileprivate · [SettingsScreen.swift:165](../../../sources/Projects/Feature/Settings/Settings/SettingsScreen.swift#L165)  
  SettingsScreen의 화면 문구(제목 '설정', 섹션·행 제목, 알림 켜짐/꺼짐 값, 로그아웃·계정 삭제 제목, 실패 메시지)와 레이아웃 수치(구분선 높이, 패딩, 헤더 높이·간격)를 담는 파일 전용 상수 enum이다.  
  단어(단일): `Constant` 상수. 여기서는 설정 화면 본문의 문구와 레이아웃 수치 네임스페이스

## Settings/Settings/SubViews

- **`SettingsScreen.AccountDeletionView`** `struct` · internal · [SettingsScreen+AccountDeletionView.swift:7](../../../sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+AccountDeletionView.swift#L7) · 채택: View  
  계정 삭제 확인 화면을 그리는 @ViewAction 하위 View다. 안내 문단 세 개와 accountAction 실패 메시지를 보여 주고, 뒤로 가기 버튼은 deleteAccountCancelled, 하단 BottomActionBar의 '계정 삭제' 버튼은 deleteAccountConfirmed를 보내며 deletingAccount 중에는 버튼을 비활성화한다.  
  단어: `Account` 계정. 여기서는 삭제 대상인 사용자 로그인 계정 · `Deletion` 삭제. 여기서는 계정과 개인정보를 지우는 회원 탈퇴 절차 · `View` 보기·뷰. 여기서는 화면 일부를 그리는 SwiftUI View 타입 접미어
- **`SettingsScreen.AccountDeletionView.Constant`** `enum` · private · [SettingsScreen+AccountDeletionView.swift:62](../../../sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+AccountDeletionView.swift#L62)  
  AccountDeletionView의 제목·확인 버튼 문구('계정 삭제'), 안내 문단 배열, 실패 메시지와 문단 간격·상단 패딩·헤더 높이 상수를 담는 enum이다.  
  단어(단일): `Constant` 상수. 여기서는 계정 삭제 화면의 문구와 수치 네임스페이스
- **`SettingsScreen.CareerLevelSelectionView`** `struct` · internal · [SettingsScreen+CareerLevelSelectionView.swift:7](../../../sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+CareerLevelSelectionView.swift#L7) · 채택: View  
  개발 수준(연차) 선택 화면을 그리는 @ViewAction 하위 View다. CareerLevelDisplay의 순서·식별자·제목·설명·일러스트로 SelectionCardList 항목을 만들고 현재 profile.curation.careerLevel을 선택 표시하며, 선택 시 careerLevelSelected를, careerLevelMutation 실패 시 오류 메시지를 보여 준다.  
  단어: `Career` 경력. 여기서는 개발자로서의 경력 수준 · `Level` 수준·단계. 여기서는 입문·주니어·미들·시니어로 나뉘는 CareerLevel 도메인 값 · `Selection` 선택. 여기서는 목록 중 하나를 고르는 사용자 행위 · `View` 보기·뷰. 여기서는 화면 일부를 그리는 SwiftUI View 타입 접미어
- **`SettingsScreen.CareerLevelSelectionView.Constant`** `enum` · private · [SettingsScreen+CareerLevelSelectionView.swift:65](../../../sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+CareerLevelSelectionView.swift#L65)  
  CareerLevelSelectionView의 제목('개발 수준')·실패 메시지와 메시지 간격·상단 패딩·헤더 높이 상수를 담는 enum이다.  
  단어(단일): `Constant` 상수. 여기서는 개발 수준 선택 화면의 문구와 수치 네임스페이스
- **`SettingsScreen.PositionSelectionView`** `struct` · internal · [SettingsScreen+PositionSelectionView.swift:7](../../../sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+PositionSelectionView.swift#L7) · 채택: View  
  개발 분야(직군) 선택 화면을 그리는 @ViewAction 하위 View다. PositionDisplay의 순서·식별자·제목으로 compact 스타일 SelectionCardList를 구성하고 현재 profile.curation.position을 선택 표시하며, 선택 시 positionSelected를, positionMutation 실패 시 오류 메시지를 보여 준다.  
  단어: `Position` 직위·직군. 여기서는 프론트엔드·백엔드·iOS·Android로 나뉘는 MemberPosition 도메인 값 · `Selection` 선택. 여기서는 목록 중 하나를 고르는 사용자 행위 · `View` 보기·뷰. 여기서는 화면 일부를 그리는 SwiftUI View 타입 접미어
- **`SettingsScreen.PositionSelectionView.Constant`** `enum` · private · [SettingsScreen+PositionSelectionView.swift:64](../../../sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+PositionSelectionView.swift#L64)  
  PositionSelectionView의 제목('개발 분야')·실패 메시지와 메시지 간격·상단 패딩·헤더 높이 상수를 담는 enum이다.  
  단어(단일): `Constant` 상수. 여기서는 개발 분야 선택 화면의 문구와 수치 네임스페이스
- **`SettingsScreen.SectionView`** `struct` · internal · [SettingsScreen+SectionView.swift:5](../../../sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+SectionView.swift#L5) · 채택: View  
  설정 화면의 한 섹션을 그리는 제네릭(Rows: View) View다. caption2 제목 아래에 @ViewBuilder로 받은 행들을 grey600 배경과 grey500 구분선, large 코너 반경으로 묶어 표시하며 SettingsScreen이 학습 설정·알림·일반 세 섹션에 사용한다.  
  단어: `Section` 구역·절. 여기서는 설정 화면에서 제목 아래 행들을 묶는 한 그룹 · `View` 보기·뷰. 여기서는 화면 일부를 그리는 SwiftUI View 타입 접미어
- **`SettingsScreen.SettingRowContent`** `struct` · internal · [SettingsScreen+SettingRowContent.swift:6](../../../sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+SettingRowContent.swift#L6) · 채택: View  
  UIComponent의 SettingRow 안에 넣는 아이콘+제목 내용 View다. ResourceImage 아이콘(16pt)과 body2 제목 텍스트를 가로로 배치하며 색상은 ColorToken(기본 grey100)으로 받고, SettingsScreen의 직군·연차·알림·약관 행에 쓰인다.  
  단어: `Setting` 설정 항목. 여기서는 설정 화면의 개별 항목 하나 · `Row` 행·줄. 여기서는 목록에서 한 줄을 차지하는 항목 셀(SettingRow) · `Content` 내용. 여기서는 그 행 안에 채워 넣는 아이콘·제목 부분
- **`SettingsScreen.SettingRowContent.Icon`** `typealias` · internal · [SettingsScreen+SettingRowContent.swift:22](../../../sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+SettingRowContent.swift#L22) · 그래프 미수집(grep 보강)  
  SettingRowContent가 생성자 인자로 받는 아이콘 타입의 별칭으로 ResourceImage.Asset.Icon을 가리킨다. 행마다 settingDevelop·settingLevel·settingAlert·settingPolicy 같은 아이콘 에셋을 지정하는 데 쓴다.  
  단어(단일): `Icon` 아이콘·작은 그림 기호. 여기서는 설정 행 왼쪽에 놓는 ResourceImage 아이콘 에셋 타입
- **`SettingsScreen.SettingRowContent.Constant`** `enum` · private · [SettingsScreen+SettingRowContent.swift:34](../../../sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+SettingRowContent.swift#L34)  
  SettingRowContent의 아이콘 크기(iconSize 16)와 아이콘-제목 간격(iconTitleSpacing 10) 상수를 담는 enum이다.  
  단어(단일): `Constant` 상수. 여기서는 설정 행 내용의 레이아웃 수치 네임스페이스

## Settings/Shared/ViewModels

- **`CareerLevelDisplay`** `enum` · internal · [CareerLevelDisplay.swift:4](../../../sources/Projects/Feature/Settings/Shared/ViewModels/CareerLevelDisplay.swift#L4)  
  CareerLevel 도메인 값을 화면 표현으로 바꾸는 정적 함수 전용 네임스페이스 enum이다. 표시 순서(orderedLevels), 문자열 식별자 상호 변환, 제목·설명·일러스트 에셋, 설정 행 값(미선택 시 '선택 안 함')을 제공하며 CareerLevelSelectionView와 SettingsScreen이 사용한다.  
  단어: `Career` 경력. 여기서는 개발자 경력 수준 · `Level` 수준·단계. 여기서는 CareerLevel 도메인 값 · `Display` 표시·표현. 여기서는 도메인 값을 사용자에게 보여 줄 문자열·이미지로 바꾸는 역할
- **`PositionDisplay`** `enum` · internal · [PositionDisplay.swift:3](../../../sources/Projects/Feature/Settings/Shared/ViewModels/PositionDisplay.swift#L3)  
  MemberPosition 도메인 값을 화면 표현으로 바꾸는 정적 함수 전용 네임스페이스 enum이다. 표시 순서(orderedPositions), 문자열 식별자 상호 변환, 제목(iOS·Android·Back-end·Front-end), 설정 행 값(미선택 시 '선택 안 함')을 제공하며 PositionSelectionView와 SettingsScreen이 사용한다.  
  단어: `Position` 직위·직군. 여기서는 MemberPosition 도메인 값 · `Display` 표시·표현. 여기서는 도메인 값을 사용자에게 보여 줄 문자열로 바꾸는 역할

## ShareRegistration/Previews

- **`ShareRegistrationPreviewSupport`** `enum` · internal · [ShareRegistrationPreviewSupport.swift:10](../../../sources/Projects/Feature/ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift#L10)  
  #if DEBUG 안에서만 존재하는 공유 등록 미리보기 지원 enum이다. 지정한 Status와 샘플 ExternalRepository(apple/swift)를 담은 StoreOf<ShareRegistrationFeature>를 미리보기 대역(PreviewRepositoryLocator·PreviewExternalRepository·PreviewProjectGeneration)과 signedIn 가용성으로 구성해 돌려준다.  
  단어: `Share` 공유. 여기서는 iOS 공유 시트(Share Extension)로 링크를 앱에 넘기는 행위 · `Registration` 등록. 여기서는 공유받은 GitHub 저장소 링크를 학습 프로젝트로 등록(생성 요청)하는 일 · `Preview` 미리보기. 여기서는 Xcode #Preview에서만 쓰는 지원 코드 · `Support` 지원·보조. 여기서는 미리보기를 구성하는 데 필요한 스토어·대역을 제공하는 보조 코드
- **`ShareRegistrationPreviewSupport.PreviewRepositoryLocator`** `struct` · private · [ShareRegistrationPreviewSupport.swift:30](../../../sources/Projects/Feature/ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift#L30) · 채택: ExternalRepositoryLocator  
  ExternalRepositoryLocator의 미리보기 대역 구조체다. 어떤 ExternalRepositoryURL을 받아도 owner 'apple', name 'swift'인 ExternalRepositoryLocation을 돌려준다.  
  단어: `Preview` 미리보기. 여기서는 Xcode #Preview에서만 쓰는 지원 코드 · `Repository` 저장소. 여기서는 GitHub 원격 코드 저장소 · `Locator` 위치 지정자·찾아내는 것. 여기서는 URL에서 저장소 소유자·이름 위치 정보를 파싱하는 역할
- **`ShareRegistrationPreviewSupport.PreviewExternalRepository`** `struct` · private · [ShareRegistrationPreviewSupport.swift:36](../../../sources/Projects/Feature/ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift#L36) · 채택: ExternalRepositoryUseCase  
  ExternalRepositoryUseCase의 미리보기 대역 구조체다. repository(at:)가 URL과 무관하게 항상 ShareRegistrationPreviewSupport.sampleRepository를 돌려준다.  
  단어: `Preview` 미리보기. 여기서는 Xcode #Preview에서만 쓰는 지원 코드 · `External` 외부의. 여기서는 앱 밖 서비스(GitHub)에 있는 · `Repository` 저장소. 여기서는 외부 GitHub 저장소 정보를 조회하는 유스케이스 대상
- **`ShareRegistrationPreviewSupport.PreviewProjectGeneration`** `struct` · private · [ShareRegistrationPreviewSupport.swift:42](../../../sources/Projects/Feature/ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift#L42) · 채택: ProjectGenerationUseCase  
  ProjectGenerationUseCase의 미리보기 대역 구조체다. request(_:)는 projectID 'preview-project'와 요청의 quizLevel을 담은 ProjectGenerationReceipt를 돌려주고, states()는 즉시 종료되는 빈 AsyncStream을 돌려준다.  
  단어: `Preview` 미리보기. 여기서는 Xcode #Preview에서만 쓰는 지원 코드 · `Project` 프로젝트. 여기서는 GitHub 저장소 하나를 등록해 만드는 학습 프로젝트 · `Generation` 생성. 여기서는 저장소로부터 학습 프로젝트(퀴즈 세트)를 생성 요청하는 일

## ShareRegistration

- **`ShareRegistrationDiagnosticEvent`** `enum` · public · [ShareRegistrationDiagnosticEvent.swift:3](../../../sources/Projects/Feature/ShareRegistration/ShareRegistrationDiagnosticEvent.swift#L3) · 채택: Equatable, Sendable  
  공유 등록 흐름에서 외부에 기록할 진단 이벤트 enum이다. sharedItemUnavailable, repositoryLinkRejected, signInAvailabilityResolved(SignInAvailability), repositoryLookupFailed(reason:), registrationFailed(reason:), registrationSucceeded 케이스를 가지며 ShareRegistrationFeature가 recordDiagnostic 클로저로 전달한다.  
  단어: `Share` 공유. 여기서는 iOS 공유 시트(Share Extension)로 링크를 앱에 넘기는 행위 · `Registration` 등록. 여기서는 공유받은 GitHub 저장소 링크를 학습 프로젝트로 등록(생성 요청)하는 일 · `Diagnostic` 진단의. 여기서는 문제 추적·로그 기록 목적의 · `Event` 사건·이벤트. 여기서는 흐름 중 발생해 기록할 개별 사건
- **`ShareRegistrationFeature`** `struct` · public · [ShareRegistrationFeature.swift:10](../../../sources/Projects/Feature/ShareRegistration/ShareRegistrationFeature.swift#L10) · 채택: Sendable  
  @Reducer로 선언된 공유 등록 흐름 리듀서로 ExternalRepositoryLocator·ExternalRepositoryUseCase·ProjectGenerationUseCase·signInAvailability·recordDiagnostic·dismiss를 생성자로 주입받는다. 공유된 URL을 검증해 로그인 가용성 확인과 저장소 조회를 수행하고, RepositoryConfirmation·QuizLevelSelection·QuizGenerationConfirmation 자식 리듀서를 Scope로 묶어 단계(Status) 전환, 프로젝트 생성 요청, 재시도·닫기를 처리한다.  
  단어: `Share` 공유. 여기서는 iOS 공유 시트(Share Extension)로 링크를 앱에 넘기는 행위 · `Registration` 등록. 여기서는 공유받은 GitHub 저장소 링크를 학습 프로젝트로 등록(생성 요청)하는 일 · `Feature` 기능·특징. 여기서는 TCA 컨벤션상 State·Action·body를 가진 Reducer 타입을 뜻하는 접미어
- **`ShareRegistrationFeature.RetryTarget`** `enum` · public · [ShareRegistrationFeature.swift:33](../../../sources/Projects/Feature/ShareRegistration/ShareRegistrationFeature.swift#L33) · 채택: Equatable, Sendable  
  실패 상태에서 재시도할 때 다시 수행할 단계를 나타내는 enum으로 lookup(링크 검증·저장소 조회)과 registration(생성 요청) 케이스를 가진다. Status.failed(reason:retry:)의 연관값으로 담기며 retryTapped 처리 시 validate와 submit 중 하나를 고르는 기준이다.  
  단어: `Retry` 재시도. 여기서는 실패한 작업을 다시 실행하는 일 · `Target` 대상·목표. 여기서는 재시도로 다시 실행할 단계
- **`ShareRegistrationFeature.Status`** `enum` · public · [ShareRegistrationFeature.swift:38](../../../sources/Projects/Feature/ShareRegistration/ShareRegistrationFeature.swift#L38) · 채택: Equatable, Sendable  
  공유 등록 흐름의 현재 단계를 나타내는 enum으로 validating, repositoryConfirmation, quizLevelSelection, quizGenerationConfirmation, invalidURL(reason:), signInRequired, appLaunchRequired, submitting, succeeded, failed(reason:retry:) 케이스를 가진다. State.status에 담기며 ShareRegistrationScreen이 이 값으로 표시할 하위 화면을 고른다.  
  단어(단일): `Status` 상태·진행 단계. 여기서는 공유 등록 흐름이 검증·확인·선택·제출·성공·실패 중 어느 단계인지
- **`ShareRegistrationFeature.State`** `struct` · public · [ShareRegistrationFeature.swift:51](../../../sources/Projects/Feature/ShareRegistration/ShareRegistrationFeature.swift#L51) · 채택: Equatable, Sendable  
  ShareRegistrationFeature의 @ObservableState 상태 구조체다. sharedURL(String?)과 status, 세 자식 Feature의 State(repositoryConfirmation·quizLevelSelection·quizGenerationConfirmation)를 보유하고 repository·quizLevel·isBusy·canDismiss·canRetry 계산 속성을 제공한다.  
  단어(단일): `State` 상태. 여기서는 공유 등록 리듀서가 소유하는 관찰 가능한 상태 값 묶음
- **`ShareRegistrationFeature.Action`** `enum` · public · [ShareRegistrationFeature.swift:97](../../../sources/Projects/Feature/ShareRegistration/ShareRegistrationFeature.swift#L97) · 채택: ViewAction, Sendable, Equatable  
  ShareRegistrationFeature의 액션 루트 enum이다. view(View)·effect(EffectEvent)·delegate(Delegate)와 세 자식 Feature 액션(repositoryConfirmation, quizLevelSelection, quizGenerationConfirmation) 케이스로 나뉘며 ViewAction을 채택한다.  
  단어(단일): `Action` 동작·행위. 여기서는 공유 등록 리듀서가 처리하는 모든 입력 이벤트의 루트 타입
- **`ShareRegistrationFeature.Action.View`** `enum` · public · [ShareRegistrationFeature.swift:107](../../../sources/Projects/Feature/ShareRegistration/ShareRegistrationFeature.swift#L107) · 채택: Sendable, Equatable  
  ShareRegistrationScreen에서 발생하는 생명주기·사용자 입력 액션 enum으로 task, sharedURLResolved(String?), retryTapped, dismissTapped 케이스를 가지며 @CasePathable이 적용돼 있다.  
  단어(단일): `View` 보기·뷰. 여기서는 SwiftUI 뷰에서 올라오는 사용자 입력·생명주기 액션 묶음
- **`ShareRegistrationFeature.Action.EffectEvent`** `enum` · public · [ShareRegistrationFeature.swift:115](../../../sources/Projects/Feature/ShareRegistration/ShareRegistrationFeature.swift#L115) · 채택: Sendable, Equatable  
  비동기 Effect의 결과를 리듀서로 되돌리는 액션 enum으로 validationFinished(Status), repositoryResolved(ExternalRepository), registrationFinished(Result<ProjectID, ProjectGenerationError>) 케이스를 가진다.  
  단어: `Effect` 효과·부수 효과. 여기서는 TCA Effect(.run)로 실행한 검증·조회·등록 비동기 작업 · `Event` 사건. 여기서는 그 작업이 끝나 리듀서에 알리는 결과 이벤트
- **`ShareRegistrationFeature.Action.Delegate`** `enum` · public · [ShareRegistrationFeature.swift:122](../../../sources/Projects/Feature/ShareRegistration/ShareRegistrationFeature.swift#L122) · 채택: Sendable, Equatable  
  상위에 전달하는 결과 액션 enum으로 dismissRequested 케이스 하나를 가진다. 리듀서는 이 액션을 받으면 주입된 dismiss 클로저를 실행하는 Effect를 돌려준다.  
  단어(단일): `Delegate` 위임·대리인. 여기서는 닫기 처리를 상위(확장 컨텍스트)에 위임하기 위해 내보내는 액션
- **`ShareRegistrationFeature.CancelID`** `enum` · private · [ShareRegistrationFeature.swift:223](../../../sources/Projects/Feature/ShareRegistration/ShareRegistrationFeature.swift#L223) · 채택: Hashable  
  ShareRegistrationFeature Effect의 취소 식별자 enum으로 validation과 registration 케이스를 가진다. validate·submit Effect의 cancelInFlight 취소와 dismissIfIdle에서의 명시적 취소에 사용된다.  
  단어: `Cancel` 취소. 여기서는 진행 중인 검증·등록 Effect를 취소하는 일 · `ID` Identifier(식별자). 여기서는 취소 대상 Effect를 구분하는 Hashable 키
- **`ShareRegistrationScreen`** `struct` · public · [ShareRegistrationScreen.swift:9](../../../sources/Projects/Feature/ShareRegistration/ShareRegistrationScreen.swift#L9) · 채택: View · 그래프 미수집(grep 보강)  
  StoreOf<ShareRegistrationFeature>를 받아 공유 등록 화면을 그리는 @ViewAction public View다. store.status에 따라 LoadingView, 자식 화면(RepositoryConfirmationScreen·QuizLevelSelectionScreen·QuizGenerationConfirmationScreen), GuidanceView 중 하나를 ScreenContainer 안에 표시하고 task·재시도·닫기를 send로 보낸다.  
  단어: `Share` 공유. 여기서는 iOS 공유 시트(Share Extension)로 링크를 앱에 넘기는 행위 · `Registration` 등록. 여기서는 공유받은 GitHub 저장소 링크를 학습 프로젝트로 등록(생성 요청)하는 일 · `Screen` 화면. 여기서는 Feature 스토어를 받아 한 화면 전체를 그리는 SwiftUI View 접미어
- **`ShareRegistrationScreen.Constant`** `enum` · fileprivate · [ShareRegistrationScreen.swift:97](../../../sources/Projects/Feature/ShareRegistration/ShareRegistrationScreen.swift#L97)  
  ShareRegistrationScreen의 안내 문구 상수 enum이다. 조회·요청 중 로딩 메시지, 잘못된 링크·로그인 필요·앱 실행 필요·성공·실패 제목과 안내 문장, 재시도·닫기 버튼 문구를 담는다.  
  단어(단일): `Constant` 상수. 여기서는 공유 등록 화면의 문구 네임스페이스

## ShareRegistration/SubViews

- **`ShareRegistrationScreen.GuidanceView`** `struct` · internal · [ShareRegistrationScreen+GuidanceView.swift:7](../../../sources/Projects/Feature/ShareRegistration/SubViews/ShareRegistrationScreen+GuidanceView.swift#L7) · 채택: View  
  제목·메시지와 재시도(retryTitle이 있을 때만)·닫기 버튼을 세로로 배치한 안내 화면 View다. 상단 ScreenControlBar의 leading 탭도 onDismiss로 연결하며 ShareRegistrationScreen이 invalidURL·signInRequired·appLaunchRequired·succeeded·failed 상태에 사용한다.  
  단어: `Guidance` 안내·지도. 여기서는 사용자에게 현재 결과와 다음 행동을 알려 주는 안내 문구 화면 · `View` 보기·뷰. 여기서는 화면 일부를 그리는 SwiftUI View 타입 접미어
- **`ShareRegistrationScreen.GuidanceView.Constant`** `enum` · private · [ShareRegistrationScreen+GuidanceView.swift:47](../../../sources/Projects/Feature/ShareRegistration/SubViews/ShareRegistrationScreen+GuidanceView.swift#L47)  
  GuidanceView의 텍스트 묶음 간격(textSetSpacing 16)과 하단 버튼 패딩(bottomButtonPadding 24) 상수를 담는 enum이다.  
  단어(단일): `Constant` 상수. 여기서는 안내 화면의 레이아웃 수치 네임스페이스
- **`ShareRegistrationScreen.LoadingView`** `struct` · internal · [ShareRegistrationScreen+LoadingView.swift:7](../../../sources/Projects/Feature/ShareRegistration/SubViews/ShareRegistrationScreen+LoadingView.swift#L7) · 채택: View  
  generalLoading 반복 애니메이션(120pt)과 메시지 텍스트를 화면 가운데 세로로 배치한 로딩 화면 View다. ShareRegistrationScreen이 validating·submitting 상태에서 각각 조회 중·요청 중 메시지와 함께 사용한다.  
  단어: `Loading` 불러오는 중·적재 중. 여기서는 저장소 조회나 생성 요청이 진행 중임을 보여 주는 상태 · `View` 보기·뷰. 여기서는 화면 일부를 그리는 SwiftUI View 타입 접미어
- **`ShareRegistrationScreen.LoadingView.Constant`** `enum` · private · [ShareRegistrationScreen+LoadingView.swift:30](../../../sources/Projects/Feature/ShareRegistration/SubViews/ShareRegistrationScreen+LoadingView.swift#L30)  
  LoadingView의 애니메이션 인디케이터 크기(indicatorSize 120)와 텍스트 간격(textSetSpacing 16) 상수를 담는 enum이다.  
  단어(단일): `Constant` 상수. 여기서는 로딩 화면의 레이아웃 수치 네임스페이스
