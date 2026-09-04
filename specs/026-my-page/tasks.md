---

description: "기능 구현 작업 목록: 마이페이지 구현 (재계획)"

---

# 작업 목록: 마이페이지 구현

**입력**: `/specs/026-my-page/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**재계획 사유**: `/speckit-implement` T001(Figma 조회)에서 "마이" 탭이 단일 화면이 아니라
프로필+설정(+선택 3화면) 5개 화면 Router 구조이고, 학습 통계 필드가 Domain 모델과
불일치함을 확인해 spec/plan/research/data-model/contracts를 재작성했다. 이 tasks.md는 그
결과를 반영한 신규 버전이며 이전 버전(단일 `SettingsScreen`)의 작업은 모두 무효화됐다.

**Git 기준선**: 이 tasks.md 재작성 시점의 blob hash와 전체 diff를 새 실행 기준선으로
snapshot한다. 이전 tasks.md 버전에 대한 커밋은 없었다(구현 파일 변경 없이 T001에서 중단).

**테스트**: Domain·Composition 필드 교정은 기존 테스트를 갱신하는 형태로 포함한다. 신규
`ProfileDisplay`(순수 변환)는 이 계층을 항상 테스트하는 저장소 관행에 따라 테스트를
포함한다. `SettingsFeature`에 추가하는 내비게이션 Action(T031)은 별도 reducer 테스트 대신
`SettingsRouterFeatureTests`(T012)가 Router 전이를 통해 검증한다.

**구성**: 적용 패키지는 Domain → App(소규모, 호출부 갱신) → Composition → UI(조건부) →
Feature → App(연동, Feature의 새 delegate 처리) 순서다(아키텍처 표의 `Feature → Domain, UI`,
`Composition → Domain, Data, Infrastructure`, `App → Feature, Composition, Domain`을 근거로,
Domain을 다른 모든 패키지가 참조하므로 가장 먼저 진행). 변경 시나리오는 [S1]~[S4] 라벨로
추적한다.

**UI 패키지에 대한 참고**: [research.md §5](./research.md#5-직군연차-선택-화면--selectioncardlist-재사용)에
따라 개발 분야/수준 선택은 기존 `SelectionCardList`로 표현 가능하다고 판단했다. 구현
단계에서 Figma를 재대조해 기존 컴포넌트(`ScreenHeader`, `SettingRow`,
`SelectionCardList`, `AccountActionRow`, `EmptyState`)로 표현할 수 없는 요소를 발견하면
정확한 컴포넌트 경로를 포함한 UI 패키지 작업 추가가 필요하므로 구현을 중단하고 범위
확장을 명시적으로 승인받는다.

## 작업 패키지 1: Domain

**목표**: `LearningStatistics`/`WeeklyLearningCount`를 서버 실측 응답
(`thisWeekSolvedCount`/`thisMonthSolvedCount`/`streakDays`/`weeklyChart`)에 맞게
교정한다.

**소유 경로**: `sources/Projects/Domain/Member/Models/MemberProfile/LearningStatistics.swift`,
`sources/Projects/Domain/Member/Models/MemberProfile/WeeklyLearningCount.swift`,
`sources/Projects/Domain/Tests/Member/Models/MemberProfileTests.swift`,
`sources/Projects/Domain/Tests/Member/Models/MemberRegistrationStatusTests.swift`,
`sources/Projects/Domain/Tests/Member/UseCases/FetchMemberProfileTests.swift`

**관련 변경 시나리오**: S1

**독립 검증**: Domain 패키지만 build-for-testing·test-without-building으로 검증한다
(다른 패키지 변경 없이도 Domain은 독립적으로 컴파일된다 — 호출부는 이후 패키지에서
갱신).

### 구현

- [X] T001 [S1] `sources/Projects/Domain/Member/Models/MemberProfile/LearningStatistics.swift`의
  `totalAnsweredCount`/`totalCorrectCount`를 `thisWeekSolvedCount`/`thisMonthSolvedCount`로
  바꾸고 `streakDays: Int`를 추가한다([data-model.md §1](./data-model.md#1-domain-모델-교정-domain-패키지)).
- [X] T002 [S1] `sources/Projects/Domain/Member/Models/MemberProfile/WeeklyLearningCount.swift`의
  `weekStartDate: Date`를 `dayLabel: String`으로 바꾼다.
- [X] T003 [S1] `sources/Projects/Domain/Tests/Member/Models/MemberProfileTests.swift`,
  `sources/Projects/Domain/Tests/Member/Models/MemberRegistrationStatusTests.swift`,
  `sources/Projects/Domain/Tests/Member/UseCases/FetchMemberProfileTests.swift`의
  `LearningStatistics(...)`/`WeeklyLearningCount(...)` 호출을 T001·T002의 새 필드명으로
  갱신한다.

### 정리와 패키지 검증

- [ ] T004 [no-write] `"$project_build_runner" test`(Domain scheme 한정 또는 전체 중
  Domain 관련 결과)로 T003의 테스트가 통과하는지 확인한다.

**진행 점검**: T001~T004의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음
실행 단위(App)로 진행한다.

---

## 작업 패키지 2: App

**목표**: Domain 필드 교정으로 깨지는 App의 fixture 호출부를 갱신한다.

**소유 경로**: `sources/Projects/App/GitIt/Screens/AppRootView.swift`

**관련 변경 시나리오**: S1

**독립 검증**: 전체 공유 scheme Debug 빌드에서 App target이 새 `LearningStatistics`
필드로 컴파일되는지 확인한다.

### 구현

- [X] T005 [S1] `sources/Projects/App/GitIt/Screens/AppRootView.swift`의
  `LearningStatistics(totalAnsweredCount: 0, totalCorrectCount: 0, weeklyCounts: [])`
  호출을 `LearningStatistics(thisWeekSolvedCount: 0, thisMonthSolvedCount: 0,
  streakDays: 0, weeklyCounts: [])`로 갱신한다.

### 정리와 패키지 검증

- [ ] T006 [no-write] `"$project_build_runner" build`로 App target이 정상 컴파일되는지
  확인한다.

**진행 점검**: T005~T006을 보고하고 다음 실행 단위(Composition)로 진행한다.

---

## 작업 패키지 3: Composition

**목표**: `MemberRepositoryAdapter`가 서버 응답의 `thisWeekSolvedCount`/
`thisMonthSolvedCount`/`streakDays`/`weeklyChart`를 손실 없이 `LearningStatistics`로
매핑하도록 교정하고, 날짜 파싱 버그를 제거한다.

**소유 경로**: `sources/Projects/Composition/Adapter/Adapters/MemberRepositoryAdapter.swift`,
`sources/Projects/Composition/Tests/Adapter/Adapters/MemberRepositoryAdapterTests.swift`

**관련 변경 시나리오**: S1

**독립 검증**: Composition 패키지 test-without-building으로
`MemberRepositoryAdapterTests`가 통과하는지 확인한다.

### 테스트

- [X] T007 [S1] `sources/Projects/Composition/Tests/Adapter/Adapters/MemberRepositoryAdapterTests.swift`의
  `프로필 응답 DTO를 Domain MemberProfile로 변환한다` 테스트에
  `#expect(profile.statistics.thisWeekSolvedCount == 3)`,
  `#expect(profile.statistics.thisMonthSolvedCount == 12)`,
  `#expect(profile.statistics.streakDays == 5)`,
  `#expect(profile.statistics.weeklyCounts.first?.dayLabel == "2026-08-17")`(기존 fixture
  문자열 그대로, 날짜 형식이 아니어도 손실 없이 보존되는지 확인하는 것이 목적) 단언을
  추가하는 실패 테스트로 갱신한다([data-model.md §2](./data-model.md#2-composition-매핑-교정)).

### 구현

- [X] T008 [S1] `sources/Projects/Composition/Adapter/Adapters/MemberRepositoryAdapter.swift`의
  `fetchProfile()`이 `LearningStatistics(thisWeekSolvedCount: response.thisWeekSolvedCount,
  thisMonthSolvedCount: response.thisMonthSolvedCount, streakDays: response.streakDays,
  weeklyCounts: response.weeklyChart.map { WeeklyLearningCount(dayLabel: $0.dayLabel,
  count: $0.count) })`를 반환하도록 T007을 통과시킨다. `dayFormatter`와 private
  `weeklyCount(from:)`(날짜 파싱 시도, 항상 실패해 데이터를 버리던 코드)를 제거한다.

### 정리와 패키지 검증

- [ ] T009 [no-write] `"$project_build_runner" test`로 Composition의
  `MemberRepositoryAdapterTests`가 통과하는지 확인한다.

**진행 점검**: T007~T009를 보고하고 다음 실행 단위(Feature)로 진행한다. UI 패키지는
조건부이므로 Feature 구현 중 필요성이 확인되면 그 시점에 별도 단위로 삽입한다.

---

## 작업 패키지 4: Feature

**목표**: "마이" 탭에 `SettingsRouter`(신규)를 연결해 프로필 화면(신규
`ProfileFeature`)과 설정 화면(기존 `SettingsFeature` 재사용, 목록/개발 분야 선택/개발
수준 선택/계정 삭제 확인 4단계)을 구현한다.

**소유 경로**: `sources/Projects/Feature/Settings/Router/**`,
`sources/Projects/Feature/Settings/Profile/**`,
`sources/Projects/Feature/Settings/Shared/ViewModels/**`,
`sources/Projects/Feature/Settings/Settings/**`(기존 `SettingsFeature.swift`는 T031의
내비게이션 Action 추가 범위에서만 변경),
`sources/Projects/Feature/MainShell/Router/MainShellRouter.swift`,
`sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift`,
`sources/Projects/Feature/MainShell/Router/SubViews/MainShellRouter+PlaceholderView.swift`(삭제),
`sources/Projects/Feature/Home/Home/Previews/HomeScreenPreviews.swift`,
`sources/Projects/Feature/Tests/Settings/**`,
`sources/Projects/Feature/Tests/MainShell/Router/MainShellRouterFeatureTests.swift`,
`sources/Projects/Feature/Tests/Home/TestDoubles/HomeTestFixture.swift`,
`sources/Projects/Feature/Tests/Onboarding/TestDoubles/OnboardingTestFixture.swift`

**관련 변경 시나리오**: S1, S2, S3, S4

**독립 검증**: Tuist 공유 scheme의 `test-without-building`으로 신규 테스트를 실행하고,
Simulator에서 "마이" 탭 진입 시 프로필 화면 → (설정 아이콘) → 설정 화면 → (행 탭) →
선택/확인 화면까지 전체 흐름이 동작하는지 확인한다.

### 준비

- [ ] T010 [S1] [S2] [S3] [S4] `implement-figma-ui` 스킬로 노드 `1539:19209`(프로필,
  이미 조회한 스크린샷 재확인), `1465:19689`(설정), `1535:18281`(개발 분야 선택),
  `1535:18378`(개발 수준 선택), `1636:31714`(계정 삭제 확인)를 조회해 각 화면의 정확한
  레이아웃·문구·색상·타이포그래피를 확정한다. 기존 컴포넌트로 표현할 수 없는 요소를
  발견하면 이후 작업을 시작하기 전에 중단하고 UI 패키지 작업 추가에 대한 명시적 승인을
  요청한다.

### 테스트

- [ ] T011 [P] [S1] `sources/Projects/Feature/Tests/Settings/Profile/ViewModels/ProfileDisplayTests.swift`에
  `ProfileFeature.State.ProfileLoad`의 `idle`/`loading`/`loaded`/`failed` 전이가
  이름·이메일·배지(직군·연차 `nil`이면 배지 숨김)·통계 3종·주간 추이를 올바르게
  파생하는지 검증하는 실패 테스트를 작성한다([data-model.md §4](./data-model.md#4-신규-표시-모델-feature-패키지)).
- [ ] T012 [P] [S1] [S2] [S3] `sources/Projects/Feature/Tests/Settings/Router/SettingsRouterFeatureTests.swift`에
  설정 아이콘 탭 → `.settings(.list)`, 개발 분야/수준 행 탭 → 해당 선택 화면,
  뒤로가기 → 이전 화면으로 되돌아가는 `activeScreen` 전이와 `settings(.delegate(...))`가
  Router의 `delegate`로 그대로 전달되는지 검증하는 실패 테스트를 작성한다
  ([contracts/settings-router-contract.md §2](./contracts/settings-router-contract.md#2-화면-전환-계약)).

### 구현

- [ ] T013 [S1] `sources/Projects/Feature/Settings/Profile/ProfileFeature.swift`에
  `FetchMemberProfileUseCase`를 생성자로 받아 `task`에서 1회 프로필을 조회하는 신규
  Reducer를 T011을 통과시키며 구현한다.
- [ ] T014 [S1] `sources/Projects/Feature/Settings/Profile/ViewModels/ProfileDisplay.swift`에
  `HomeProfileDisplay` 패턴을 재사용해 `ProfileFeature.State`를 표시 값으로 변환하는
  `ProfileDisplay`를 구현한다.
- [ ] T015 [S1] `sources/Projects/Feature/Settings/Profile/ProfileScreen.swift`와
  `sources/Projects/Feature/Settings/Profile/SubViews/`(프로필 헤더, 통계 카드, 주간
  추이 서브뷰 — T010에서 확정한 구성에 따라 파일 분할)에 화면을 구현한다. 로딩·실패
  상태를 포함한다([contracts/profile-screen-contract.md §1](./contracts/profile-screen-contract.md#1-profilefeature--profilescreen-신규)).
- [ ] T016 [S1] [S2] [S3] `sources/Projects/Feature/Settings/Router/SettingsRouterFeature.swift`에
  `profile: ProfileFeature.State`·`settings: SettingsFeature.State`를 항상 보유하고
  `ActiveScreen`/`SettingsStep`을 소유하는 Router Reducer를 T012를 통과시키며 구현한다
  ([data-model.md §3](./data-model.md#3-router-상태-feature-패키지-신규)).
- [ ] T017 [S1] [S2] [S3] `sources/Projects/Feature/Settings/Router/SettingsRouter.swift`에
  `activeScreen`을 `switch`해 `ProfileScreen`/`SettingsScreen`(및 그 서브뷰)을 그리는
  Router View를 구현한다.
- [ ] T018 [S2] `sources/Projects/Feature/Settings/Settings/SettingsScreen.swift`(목록)와
  `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+PositionSelectionView.swift`,
  `SettingsScreen+CareerLevelSelectionView.swift`에 `SelectRow`(개발 분야/수준/약관),
  `SelectionCardList` 기반 선택 화면을 구현하고 기존 `SettingsFeature`의
  `positionSelected`/`careerLevelSelected`에 연결한다. 온보딩의
  `PositionSelectionScreen.Display`/`CareerSelectionScreen.Display`와 동일한 문구·순서로
  설정 전용 `Display`를 각 파일에 정의한다([research.md §5](./research.md#5-직군연차-선택-화면--selectioncardlist-재사용)).
- [ ] T019 [S3] `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+AccountDeletionView.swift`에
  `accountAction == .confirmingDeletion` 표시 조건의 계정 삭제 확인 전체 화면을
  구현하고 `deleteAccountConfirmed`/`deleteAccountCancelled`에 연결한다
  ([research.md §6](./research.md#6-계정-삭제-확인--전체-화면)).
- [ ] T020 [S2] `sources/Projects/Feature/Settings/Settings/SettingsScreen.swift`에
  `AccountActionRow`로 로그아웃(`.view(.signOutTapped)`)을 추가하고, 미설정 직군·연차는
  "선택 안 함"으로 표시한다(FR-006a).
- [ ] T021 [S4] `sources/Projects/Feature/Settings/Settings/SettingsScreen.swift`에
  "서비스 약관 및 정책" 행을 추가한다. 목적지(정적 인앱 화면 vs 외부 링크)는 T010에서
  확정한 내용에 따라 구현한다([contracts/profile-screen-contract.md §5](./contracts/profile-screen-contract.md#5-fr-013-확장약관-계약-참고)).
- [ ] T022 [S1] [S2] [S3] `sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift`의
  `State.settings` 타입을 `SettingsFeature.State`에서 `SettingsRouterFeature.State`로,
  `Action.settings` 페이로드를 `SettingsRouterFeature.Action`으로 바꾸고,
  `Scope(state: \.settings, action: \.settings)`가 `SettingsRouterFeature(...)`를
  생성하도록 갱신한다. `.settings(.delegate(.signedOut)), .settings(.delegate(.accountDeleted))`
  패턴 매칭 경로도 갱신한다([contracts/settings-router-contract.md §4](./contracts/settings-router-contract.md#4-mainshellrouterfeature-연동)).
- [ ] T023 [S1] `sources/Projects/Feature/MainShell/Router/MainShellRouter.swift`의
  `case .settings`가 `Self.PlaceholderView(title: tab.tabTitle)` 대신
  `SettingsRouter(store: store.scope(state: \.settings, action: \.settings))`를
  반환하도록 수정한다. 이로써 쓰이지 않게 되는
  `sources/Projects/Feature/MainShell/Router/SubViews/MainShellRouter+PlaceholderView.swift`를
  삭제한다.
- [X] T024 [S1] `sources/Projects/Feature/Home/Home/Previews/HomeScreenPreviews.swift`의
  `LearningStatistics(totalAnsweredCount: 12, totalCorrectCount: 9, weeklyCounts: [])`
  호출을 새 필드명으로 갱신한다(Domain 필드 교정으로 인한 fixture 갱신, 기능 변경
  없음).

### 구현 중 확인된 추가 작업

T010의 Figma 재확인과 Router 설계 과정에서 필요성이 드러난 작업이다. ID는 뒤에 붙였지만
실행 순서는 아래 의존성 절에 따른다.

- [ ] T031 [S2] [S3] [S4] `sources/Projects/Feature/Settings/Settings/SettingsFeature.swift`에
  Router가 해석하는 내비게이션 View Action(`backTapped`/`positionRowTapped`/
  `careerLevelRowTapped`/`termsTapped`)과 Delegate(`backRequested`/
  `positionSelectionRequested`/`careerLevelSelectionRequested`/`accountDeletionRequested`/
  `accountDeletionCancelled`/`externalURLRequested(URL)`)를 추가한다. 화면 Feature가 이전·
  다음 화면을 알지 않고 delegate로만 의도를 알리는 [TCA 내비게이션 컨벤션 §2.3](../../docs/conventions/tca/navigation.md)을
  따른다. 실패(`.failed`) 뒤 로그아웃·계정 삭제를 재시도할 수 있게 guard를 완화하고, 약관
  URL은 Figma `1465:19712` 주석("클릭 시 브라우저를 열고 서비스 정책 노션을 호출함")의
  링크를 상수로 둔다.
- [ ] T032 [S1] [S2] `sources/Projects/Feature/Settings/Shared/ViewModels/PositionDisplay.swift`,
  `sources/Projects/Feature/Settings/Shared/ViewModels/CareerLevelDisplay.swift`에 프로필
  배지·설정 값·선택 카드가 공유하는 직군/연차 표시 값(문구·순서·일러스트, FR-006a
  "선택 안 함")을 정의한다. 개발 분야 순서는 Figma `1535:18281`의 Front-end → Back-end →
  iOS → Android를 따른다(온보딩 순서와 다름).
- [X] T033 [S1] `sources/Projects/Feature/Tests/Home/TestDoubles/HomeTestFixture.swift`,
  `sources/Projects/Feature/Tests/Onboarding/TestDoubles/OnboardingTestFixture.swift`의
  `LearningStatistics(...)` 호출을 새 필드명으로 갱신한다(Domain 필드 교정에 따른 fixture
  갱신).
- [ ] T034 [S3] `sources/Projects/Feature/Tests/MainShell/Router/MainShellRouterFeatureTests.swift`의
  로그아웃·계정 삭제 delegate 인자 타입을 `SettingsRouterFeature.Action.Delegate`로
  갱신한다.

### 정리와 패키지 검증

- [ ] T025 [S1] `sources/Projects/Feature/Settings/Profile/Previews/ProfileScreenPreviews.swift`,
  `sources/Projects/Feature/Settings/Settings/Previews/SettingsScreenPreviews.swift`에
  로딩·정상(직군·연차 설정됨)·정상(미설정)·실패 상태별 프리뷰를 추가한다(Figma node
  ID를 프리뷰 이름에 포함).
- [ ] T026 [no-write] `"$project_build_runner" build`로 전체 공유 scheme를 Debug
  빌드해 컴파일 오류가 없는지 확인한다.
- [ ] T027 [no-write] `"$project_build_runner" compile`로 build-for-testing을
  실행한다.
- [ ] T028 [no-write] `"$project_build_runner" test`로 test-without-building을
  실행하고 T011·T012의 신규 테스트가 통과하는지 확인한다.

**진행 점검**: T010~T034의 변경 파일과 검증 결과를 보고하고 다음 실행 단위(App 연동)로
진행한다.

---

## 작업 패키지 5: App(연동)

**목표**: Feature가 올리는 외부 링크 요청(서비스 약관, S4)을 App이 `openExternalURL`로
처리하고, Domain 필드 교정으로 깨지는 App 테스트 fixture를 갱신한다.

**소유 경로**: `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`,
`sources/Projects/App/Tests/GitIt/TestDoubles/AppRootTestSupport.swift`,
`sources/Projects/App/Tests/GitIt/TestDoubles/NoopFetchMemberProfileUseCase.swift`

**관련 변경 시나리오**: S1, S4

**순서 근거**: `MainShellRouterFeature.Action.Delegate.externalURLRequested`(T022)를
참조하므로 Feature 뒤에 둔다. 작업 패키지 2(App)와 같은 패키지지만 의존 방향이 달라 별도
단위로 분리했다.

### 구현

- [ ] T035 [S4] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`의 외부 링크 처리
  `case`(`.projectDetail(.presented(.delegate(.externalURLRequested)))` 등)에
  `.mainShell(.delegate(.externalURLRequested(let url)))`를 추가해 `openExternalURL`로 연다.
- [ ] T036 [S1] `sources/Projects/App/Tests/GitIt/TestDoubles/AppRootTestSupport.swift`,
  `sources/Projects/App/Tests/GitIt/TestDoubles/NoopFetchMemberProfileUseCase.swift`의
  `LearningStatistics(...)` 호출을 새 필드명으로 갱신한다.

### 정리와 패키지 검증

- [ ] T037 [no-write] `"$project_build_runner" build`·`compile`·`test`로 App target과 App
  테스트가 통과하는지 확인한다.

**진행 점검**: T035~T037을 보고한다. 이 명세가 적용하는 패키지는
Domain·App·Composition·Feature이므로 다음은 전체 완료 검증이다.

---

## 전체 완료 검증

**선행 조건**: 작업 패키지 5의 모든 파일 변경 작업을 완료하고, 전체 검증과 hook 결과를
포함할 마지막 커밋 단위를 아직 commit하지 않은 상태여야 한다.

**커밋 경계**: 아래 `[no-write]` 작업은 작업 패키지 5의 마지막 커밋 단위에 배정한다.
모든 검증과 필수 `after_implement` hook을 마친 뒤 그 단위를 최종 commit한다.

- [ ] T029 [no-write] Simulator에서 [quickstart.md](./quickstart.md)의 시나리오별 수동
  검증(S1 프로필 화면, S2 직군·연차 변경, S3 로그아웃·계정 삭제, S4 이용약관)을
  수행하고 결과를 기록한다.
- [ ] T030 [no-write] `implement-figma-ui` 스킬 기준으로 T010에서 확정한 5개 Figma
  노드와 최종 구현을 다시 대조해 FR-012·SC-005(레이아웃·타이포그래피·색상 일치)를
  확인한다. 차이가 있으면 수정하거나 사용자 승인을 받아 근거를 남긴다.

## 의존성과 실행 순서

### 실행 단위 순서와 위험 기반 승인

- `Domain → App → Composition → Feature` 순서로 진행한다. Domain을 App·Composition·
  Feature가 모두 참조하므로 가장 먼저 완료한다. App과 Composition은 서로 의존하지
  않으므로 상대 순서는 이 문서가 정했다(App이 더 작아 먼저 배치). UI는 조건부이며
  필요성이 확인되면 Feature 구현 착수 전에 별도 단위로 삽입한다.
- Feature 뒤에 `App(연동)` 단위(T035~T037)를 둔다. Feature의 새 delegate를 참조하므로
  Feature보다 먼저 컴파일될 수 없다.
- 추가 작업 T031~T034는 Feature 단위에 속한다. T032(공유 표시 값)는 T014·T018 이전에,
  T031(SettingsFeature 내비게이션 Action)은 T016(Router) 이전에, T033·T034(테스트 fixture·
  인자 타입 갱신)는 T026 이전에 완료한다.
- Data, Infrastructure는 이번 기능에서 변경하지 않는다(기존 DTO가 이미 올바른 필드를
  제공).
- 각 패키지 안에서는 테스트(요청된 경우) → 구현 → 정리·검증 순서를 지킨다.
- T011~T012(테스트)는 T013~T024(구현) 이전에 실행해 실패를 확인한 뒤 통과시킨다.
- T013~T015(Profile)와 T016~T017(Router 골격)은 서로 다른 파일이므로 병렬 가능하지만
  T016(Router)은 T013(ProfileFeature)의 타입을 참조하므로 T013 완료 후 시작한다.
- T018~T021(Settings 서브뷰)은 서로 다른 파일이므로 T016 완료 후 병렬 가능하다.
- T022~T023(MainShell 연동)은 T016~T021 완료 후 실행한다.
- T024는 Domain(T001~T002) 완료 후 언제든 가능하며 늦어도 T026 이전에 완료한다.
- T026~T028([no-write] 패키지 검증)은 T010~T025의 모든 파일 변경 완료 후 실행한다.
- T029~T030([no-write] 전체 완료 검증)은 T026~T028 통과 후 실행한다.
- 새 범위(UI 패키지 신규 컴포넌트, "서비스 약관" 목적지가 새 Domain 계약을 요구하는
  경우, FR-014로 제외한 알림 설정), 파괴적 작업(계정 삭제 실제 실행은 테스트 계정에서만),
  remote·외부 상태 변경, 새로운 제품 결정이 필요할 때만 중단하고 명시적 승인을
  요청한다. 그 외 T001~T030은 반복 승인 없이 연속 진행한다.

### 변경 시나리오 추적성

- **S1(프로필 화면)**: T001~T006, T010~T017, T022~T024, T026~T030, T032~T033, T036~T037
- **S2(직군·연차 변경)**: T007~T009, T012, T016, T018, T020, T022, T029, T031~T032
- **S3(로그아웃·계정 삭제)**: T012, T016, T019, T020, T022, T029, T031, T034
- **S4(이용약관)**: T010, T021, T029, T031, T035, T037
- 최소 가치 범위도 동일한 위험 기반 승인 기준을 적용한다.

### 실행 단위 내부 실행

**병렬 실행 예시** (Feature 패키지, T016 완료 후):

```text
T018 [S2] sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+PositionSelectionView.swift
T019 [S3] sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+AccountDeletionView.swift
T021 [S4] sources/Projects/Feature/Settings/Settings/SettingsScreen.swift(약관 행)
```

- 같은 파일을 변경하는 작업(T022 → T023)과 Red → Green 의존 작업(T011→T013~T015,
  T012→T016~T017)은 순차 실행한다.
- `/speckit-implement`는 파일을 수정하기 전에 현재 패키지의 미완료 작업을 논리적
  커밋 단위로 묶는다(예: "Domain 필드 교정"(T001~T004), "App fixture 갱신"(T005~T006),
  "Composition 매핑 교정"(T007~T009), "Profile 화면"(T011+T013~T015),
  "Router"(T012+T016~T017), "Settings 서브뷰"(T018~T021), "MainShell 연동"(T022~T024)).
- 마지막 커밋 단위(T026~T030을 포함하는 단위)는 전체 완료 검증과 필수
  `after_implement` hook이 끝날 때까지 commit하지 않는다.

## 구현 전략

1. 먼저 중단 단위와 tasks.md 전체 diff를 분류하고 blob hash와 diff를 기준선으로
   고정한다. 재개 단위가 없으면 T001부터 시작한다(T010은 이전 세션에서 이미 부분적으로
   수행한 조사를 재확인하는 성격이며, 이미 확보한 스크린샷·노드 ID를 재사용해 빠르게
   완료할 수 있다).
2. Domain → App → Composition 순서로 완료하고 각 단위 커밋 후 Feature로 진행한다.
3. Feature 패키지는 T010(Figma 재확인) → 테스트 → Profile → Router → Settings
   서브뷰 → MainShell 연동 순서로 논리적 커밋 단위를 설계한다.
4. 실행 단위가 커밋되면 변경 파일, 검증 결과와 커밋을 진행 상황으로 보고하고 다음
   단위로 이어간다.
5. UI 패키지 신규 컴포넌트나 FR-014로 제외한 알림 설정이 필요한 경계가 나타나면 변경을
   시작하기 전에 중단하고 명시적 승인을 요청한다.
6. 마지막 단위에서는 전체 읽기 전용 검증(T026~T028)과 변경 시나리오 수용 검증
   (T029~T030), 필수 `after_implement` hook을 실행하고 결과를 재검증한 뒤 최종
   commit한다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 파일 변경 작업은 정확한 경로를 포함한다.
- 변경 시나리오의 독립성은 유지하되 구현 단위는 논리적 실행 단위다.
- 이 기능은 Domain·App·Composition·Feature 4개 패키지에 걸쳐 있으며 각각 독립적으로
  컴파일·검증 가능한 순서로 배치했다(UI 확장이 승인되면 그 시점에 tasks.md를
  갱신한다).
- 모호한 소유권과 검증되지 않은 범위 확대를 허용하지 않는다.
- 문제 해결과 암묵지 기록을 구현 작업 ID로 생성하지 않는다.
