---

description: "기능 구현 작업 목록: Onboarding Router 리팩토링"
---

# 작업 목록: Onboarding Router 리팩토링

**입력**: `/specs/017-onboarding-router-refactor/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/onboarding-router-flow.md](./contracts/onboarding-router-flow.md)

**테스트**: 명세가 TDD 방식을 명시적으로 요청했으므로(`spec.md` 입력, FR-009) 각 패키지
단계에 실패하는 테스트(Red) → 구현(Green) 순서로 작업을 포함한다.

**구성**: 패키지를 최상위 구현·승인 단위로 사용하고 변경 시나리오는 각 패키지 안에서
`[S1]`(책임 분리) / `[S2]`(App Root 진입 판단과 Router 흐름) / `[S3]`(화면 이동 추적)
라벨로 추적한다. 적용 대상 패키지는 **Feature → App** 순서다(근거는 아래 "패키지 순서와
승인 게이트" 참고). **Composition 패키지는 이 기능에서 변경하지 않는다** —
`research.md` 4절에서 확인했듯 `AppComposition`은 Feature 타입을 참조하지 않는 평평한
UseCase 제공자이며, 배선은 App 패키지(`GitItApp.swift`)가 담당한다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 승인된 현재 패키지 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[시나리오]**: `[S1]`/`[S2]`/`[S3]` — `spec.md`의 변경 시나리오 1/2/3에 대응
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 실행 또는
  수동 검증. `make tuist` 파생 산출물 갱신은 허용하되 실행 전후 Git 상태를 비교한다.

---

## 작업 패키지 1: Feature

**목표**: `OnboardingFeature`(약 500줄) 하나를 세션 복원용 신규 `AppEntryFeature`(별도
폴더)와, 온보딩 안내·큐레이션 2개 화면 Feature + 이를 조합하는 `OnboardingRouterFeature`
+ 전환 여부만 판단하는 `OnboardingExitFeature`로 재구성한다. 각 Feature는 다른 Feature의
State·Action을 참조하지 않고 독립 컴파일·테스트되며, Router는 화면 전환마다 테스트로
조회 가능한 이동 이벤트를 기록한다.

**소유 경로**: `sources/Projects/Feature/AppEntry/**`,
`sources/Projects/Feature/Onboarding/**`, `sources/Projects/Feature/Tests/AppEntry/**`,
`sources/Projects/Feature/Tests/Onboarding/**`, `docs/conventions/tca.md`

**관련 변경 시나리오**: S1, S2, S3

**독립 검증**: Feature target만 build·test를 실행해 다른 패키지(App)의 타입을
import하지 않고 컴파일·통과하는지 확인한다(SC-002).

### 준비와 기반 — 최소 타입 골격

- [X] T001 [S1] `sources/Projects/Feature/AppEntry/Reducers/AppEntryFeature.swift`에
  `AppEntryFeature`의 `State`/`Action`/`Destination` 타입 골격(로직 없음)을 만든다
  (`data-model.md` "AppEntryFeature" 참고).
- [X] T002 [S1] `sources/Projects/Feature/Onboarding/Reducers/OnboardingGuideFeature.swift`에
  `OnboardingGuideFeature`의 `State`/`Action`/`Screen` 타입 골격을 만든다.
- [X] T003 [S1] `sources/Projects/Feature/Onboarding/Reducers/CurationFeature.swift`에
  `CurationFeature`의 `State`/`Action`/`Screen` 타입 골격을 만든다.
- [X] T004 [S1] [S3] `sources/Projects/Feature/Onboarding/Reducers/OnboardingExitFeature.swift`에
  `OnboardingExitFeature`의 `State`/`Action`(`input`/`delegate`) 타입 골격을 만든다.
- [X] T005 [S1] [S2] [S3] `sources/Projects/Feature/Onboarding/Reducers/OnboardingRouterFeature.swift`에
  `OnboardingRouterFeature`의 `State`(`activeScreen`, `guide`, `curation`, `exit`,
  `transitionLog`)/`Action`/`ActiveScreen`/`ScreenTransitionEvent` 타입 골격을 만들고
  네 Child를 `Scope`로 조합한다(로직은 T019에서 채운다).

### 테스트 — TDD Red

- [X] T006 [P] [S1] `sources/Projects/Feature/Tests/AppEntry/Reducers/AppEntryFeatureTests.swift`에
  `contracts/onboarding-router-flow.md`의 "AppEntryFeature 목적지 계약" 5가지 분기를
  검증하는 실패 테스트를 작성한다.
- [X] T007 [P] [S1] `sources/Projects/Feature/Tests/Onboarding/Reducers/OnboardingGuideFeatureTests.swift`에
  튜토리얼·약관 동의·로그인 상태 전이와 `signInSucceeded` delegate를 검증하는 실패
  테스트를 작성한다.
- [X] T008 [P] [S1] `sources/Projects/Feature/Tests/Onboarding/Reducers/CurationFeatureTests.swift`에
  포지션·경력 선택, 뒤로 가기, 제출 성공/실패를 검증하는 실패 테스트를 작성한다.
- [X] T009 [P] [S1] [S3] `sources/Projects/Feature/Tests/Onboarding/Reducers/OnboardingExitFeatureTests.swift`에
  `curationSucceeded` input을 받으면 `shouldExit` delegate를 발생시키는 실패 테스트를
  작성한다.
- [X] T010 [S1] [S2] [S3] `sources/Projects/Feature/Tests/Onboarding/Reducers/OnboardingRouterFeatureTests.swift`에
  대표 여정(정상 완료, 로그인 실패, 포지션 선택 뒤로 가기)의 `activeScreen` 전이와
  `transitionLog` 기록(FR-006·FR-007, SC-004)을 검증하는 실패 테스트를 작성한다.
- [X] T011 [S1] `sources/Projects/Feature/Tests/Onboarding/Reducers/OnboardingRestoreTests.swift`를
  삭제한다 — 커버리지는 T006의 `AppEntryFeatureTests`로 이전된다.
- [X] T012 [S1] `sources/Projects/Feature/Tests/Onboarding/Reducers/OnboardingLegalAndSignInTests.swift`를
  `OnboardingGuideFeature` 대상으로 다시 작성한다.
- [X] T013 [S1] `sources/Projects/Feature/Tests/Onboarding/Reducers/OnboardingCurationTests.swift`를
  `CurationFeature` 대상으로 다시 작성한다.
- [X] T014 [S1] `sources/Projects/Feature/Tests/Onboarding/Reducers/OnboardingAccessibilityTests.swift`를
  재구성된 화면 Feature 기준으로 갱신한다.

### 구현 — Green

- [X] T015 [S1] `sources/Projects/Feature/AppEntry/Reducers/AppEntryFeature.swift`에
  `restoreSession`·`fetchMemberProfile`·`signOut`(404 정리) 호출과 목적지 판단 로직을
  구현해 T006을 통과시킨다(기존 `OnboardingFeature`의 `restoreSessionFinished`·
  `memberProfileFetchFinished` 분기를 이전).
- [X] T016 [S1] `sources/Projects/Feature/Onboarding/Reducers/OnboardingGuideFeature.swift`에
  튜토리얼·약관 동의·Apple 로그인 로직을 구현해 T007을 통과시킨다(기존
  `OnboardingFeature`의 해당 로직 이전).
- [X] T017 [S1] `sources/Projects/Feature/Onboarding/Reducers/CurationFeature.swift`에
  포지션·경력 선택과 제출 로직을 구현해 T008을 통과시킨다(기존 `OnboardingFeature`의
  해당 로직 이전).
- [X] T018 [S1] [S3] `sources/Projects/Feature/Onboarding/Reducers/OnboardingExitFeature.swift`에
  전환 판단 로직을 구현해 T009를 통과시킨다.
- [X] T019 [S1] [S2] [S3] `sources/Projects/Feature/Onboarding/Reducers/OnboardingRouterFeature.swift`에
  Child delegate 처리, `activeScreen` 전환, `transitionLog` 기록 로직을 구현해 T010을
  통과시킨다. `startingAt(OnboardingEntryPoint)` 초기화도 포함한다.
- [X] T020 [S1] `sources/Projects/Feature/Onboarding/Reducers/OnboardingFeature.swift`를
  삭제한다(`OnboardingRouterFeature`+3개 Feature로 대체됨).

### 구현 — 화면

- [X] T021 [S1] `sources/Projects/Feature/AppEntry/Screens/AppEntryScreen.swift`를
  기존 `SplashScreen.swift` 내용을 옮겨 `AppEntryFeature` Store에 바인딩해 만든다.
- [X] T022 [S1] `sources/Projects/Feature/Onboarding/Screens/SplashScreen.swift`를
  삭제한다(T021로 대체됨).
- [X] T023 [S1] `sources/Projects/Feature/Onboarding/Screens/TutorialScreen.swift`를
  `OnboardingGuideFeature` Store에 바인딩하도록 갱신한다.
- [X] T024 [S1] `sources/Projects/Feature/Onboarding/Screens/LegalAgreementScreen.swift`를
  `OnboardingGuideFeature` Store에 바인딩하도록 갱신한다.
- [X] T025 [S1] `sources/Projects/Feature/Onboarding/Screens/OnboardingGuideScreen.swift`를
  만들어 `OnboardingGuideFeature.Screen`에 따라 `TutorialScreen`/`LegalAgreementScreen`을
  전환한다.
- [X] T026 [S1] `sources/Projects/Feature/Onboarding/Screens/PositionSelectionScreen.swift`를
  `CurationFeature` Store에 바인딩하도록 갱신한다.
- [X] T027 [S1] `sources/Projects/Feature/Onboarding/Screens/CareerSelectionScreen.swift`를
  `CurationFeature` Store에 바인딩하도록 갱신한다.
- [X] T028 [S1] `sources/Projects/Feature/Onboarding/Screens/CurationScreen.swift`를
  만들어 `CurationFeature.Screen`에 따라 `PositionSelectionScreen`/`CareerSelectionScreen`을
  전환한다.
- [X] T029 [S1] [S2] `sources/Projects/Feature/Onboarding/Screens/OnboardingScreen.swift`를
  `OnboardingRouterFeature` Store에 바인딩하고 `activeScreen`에 따라
  `OnboardingGuideScreen`/`CurationScreen`을 전환하도록 갱신한다.

### 구현 — Preview

- [X] T030 [P] [S1] `sources/Projects/Feature/AppEntry/Previews/AppEntryScreenPreviews.swift`를
  기존 `Onboarding/Previews/SplashScreenPreviews.swift` 내용을 옮겨 만든다.
- [X] T031 [P] [S1] `sources/Projects/Feature/Onboarding/Previews/SplashScreenPreviews.swift`를
  삭제한다(T030으로 대체됨).
- [X] T032 [P] [S1] `sources/Projects/Feature/Onboarding/Previews/TutorialScreenPreviews.swift`를
  `OnboardingGuideFeature` 기준으로 갱신한다.
- [X] T033 [P] [S1] `sources/Projects/Feature/Onboarding/Previews/LegalAgreementScreenPreviews.swift`를
  `OnboardingGuideFeature` 기준으로 갱신한다.
- [X] T034 [P] [S1] `sources/Projects/Feature/Onboarding/Previews/PositionSelectionScreenPreviews.swift`를
  `CurationFeature` 기준으로 갱신한다.
- [X] T035 [P] [S1] `sources/Projects/Feature/Onboarding/Previews/CareerSelectionScreenPreviews.swift`를
  `CurationFeature` 기준으로 갱신한다.
- [X] T036 [P] [S1] `sources/Projects/Feature/Onboarding/Previews/OnboardingScreenPreviews.swift`를
  `OnboardingRouterFeature` 기준으로 갱신한다.
- [X] T037 [P] [S1] `sources/Projects/Feature/AppEntry/Previews/AppEntryPreviewSupport/AppEntryPreviewRestoreSession.swift`를
  기존 `Onboarding/Previews/OnboardingPreviewSupport/OnboardingPreviewRestoreSession.swift`
  내용을 옮겨 만든다.
- [X] T038 [P] [S1] `sources/Projects/Feature/AppEntry/Previews/AppEntryPreviewSupport/AppEntryPreviewFetchMemberProfile.swift`를
  기존 `Onboarding/Previews/OnboardingPreviewSupport/OnboardingPreviewFetchMemberProfile.swift`
  내용을 옮겨 만든다.
- [X] T039 [P] [S1] `sources/Projects/Feature/Onboarding/Previews/OnboardingPreviewSupport/OnboardingPreviewRestoreSession.swift`와
  `OnboardingPreviewFetchMemberProfile.swift`를 삭제한다(T037·T038로 대체됨).
- [X] T040 [P] [S1] `sources/Projects/Feature/Onboarding/Previews/OnboardingPreviewSupport/OnboardingPreviewSignIn.swift`·
  `OnboardingPreviewSignOut.swift`·`OnboardingPreviewPolicyConsent.swift`가
  `OnboardingGuideFeature` 미리보기에서 쓰이도록 갱신한다.
- [X] T041 [P] [S1] `sources/Projects/Feature/Onboarding/Previews/OnboardingPreviewSupport/OnboardingPreviewCompleteCuration.swift`가
  `CurationFeature` 미리보기에서 쓰이도록 갱신한다.
- [X] T042 [S1] `sources/Projects/Feature/Onboarding/Previews/OnboardingPreviewSupport/OnboardingPreviewSupport.swift`를
  재구성된 Preview 지원 타입 구성에 맞춰 갱신한다.

### 구현 — TestDoubles

- [X] T043 [S1] `sources/Projects/Feature/Tests/AppEntry/TestDoubles/RestoreSessionUseCaseMock.swift`를
  기존 `Onboarding/TestDoubles/RestoreSessionUseCaseMock.swift`를 옮겨 만든다.
- [X] T044 [S1] `sources/Projects/Feature/Tests/AppEntry/TestDoubles/FetchMemberProfileUseCaseMock.swift`를
  기존 `Onboarding/TestDoubles/FetchMemberProfileUseCaseMock.swift`를 옮겨 만든다.
- [X] T045 [S1] `sources/Projects/Feature/Tests/Onboarding/TestDoubles/RestoreSessionUseCaseMock.swift`와
  `FetchMemberProfileUseCaseMock.swift`를 삭제한다(T043·T044로 대체됨).
- [X] T046 [S1] `sources/Projects/Feature/Tests/Onboarding/TestDoubles/OnboardingTestSupport.swift`를
  `OnboardingGuideFeature`/`CurationFeature`/`OnboardingRouterFeature`의 새
  initializer에 맞춰 갱신한다.
- [X] T047 [S1] `sources/Projects/Feature/Tests/Onboarding/TestDoubles/OnboardingTestFixture.swift`를
  같은 기준으로 갱신한다.

### 구현 — 문서

- [X] T048 [S1] `docs/conventions/tca.md`에 Router-Feature가 하위 Screen Feature를
  조합하는 방식과 화면 이동 이벤트를 다루는 정식 섹션을 추가한다(FR-011).

### 정리와 패키지 검증

- [X] T049 [no-write] `project_build_runner compile`과 `test`를 Feature target 범위로
  실행하고 결과(통과/실패, 특히 T006~T010 Red→Green 전환)를 기록한다.

**승인 게이트**: T001~T049의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가
App 패키지 진행을 명시적으로 승인하기 전에는 App 패키지 파일을 변경하지 않는다.

---

## 작업 패키지 2: App

**목표**: `AppRootFeature`가 세션 복원·목적지 판단을 `AppEntryFeature`(Feature 패키지)에
위임하고, 그 `delegate`만으로 `route`를 전환하도록 갱신한다. `AppRootView`는 스플래시
placeholder를 실제 `AppEntryScreen`으로 교체하고, `GitItApp.swift`는 새 initializer
시그니처에 맞춰 조립 인자를 재배선한다.

**소유 경로**: `sources/Projects/App/GitIt/**`, `sources/Projects/App/Tests/GitIt/**`

**관련 변경 시나리오**: S1, S2

**독립 검증**: App target build·test를 실행해 `AppRootFeatureTests`가 대표 진입 판단
4가지(SC-003)를 모두 검증하는지 확인한다.

### 테스트 — TDD Red

- [X] T050 [S1] [S2] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`를
  다시 작성한다: `.view(.task)`는 더 이상 즉시 `route = .onboarding`으로 바꾸지 않고
  `AppEntryFeature`의 `delegate(.destinationDecided(...))`를 받은 뒤에만 `route`를
  전환하도록 검증하는 실패 테스트로 교체한다(SC-003의 4가지 대표 시나리오 포함).
- [X] T051 [S1] `sources/Projects/App/Tests/GitIt/TestDoubles/AppRootTestSupport.swift`를
  `AppRootFeature`의 새 initializer 시그니처(변경 시 `AppEntryFeature` 관련 인자 반영)에
  맞춰 갱신한다.

### 구현 — Green

- [X] T052 [S1] [S2] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`의
  `State`에 `appEntry: AppEntryFeature.State`를 추가하고 `onboarding` 필드 타입을
  `OnboardingRouterFeature.State`로 바꾼다.
- [X] T053 [S1] [S2] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`의
  `body`에서 `appEntry`를 `restoring` 단계의 Child로 `Scope` 조합하고,
  `.appEntry(.delegate(.destinationDecided(let destination)))`를 받아 `destination`에
  따라 `route`와 `onboarding` 시작 지점을 결정하도록 구현해 T050을 통과시킨다. 기존
  `.view(.task)`의 즉시 `route = .onboarding` 전환 로직을 제거한다.
- [X] T054 [S1] `sources/Projects/App/GitIt/Screens/AppRootView.swift`의
  `restoringContent`(`ProgressView` placeholder)를
  `AppEntryScreen(store: store.scope(state: \.appEntry, action: \.appEntry))`로
  교체한다.
- [X] T055 [S1] `sources/Projects/App/GitIt/GitItApp.swift`의 `AppRootFeature(...)` 생성
  호출부를 갱신된 initializer 시그니처에 맞춰 재배선한다(`composition`에서 가져오는
  UseCase 목록 자체는 변경하지 않는다 — `research.md` 4절).

### 정리와 패키지 검증

- [X] T056 [no-write] `project_build_runner compile`과 `test`를 App(GitIt) target
  범위로 실행하고 결과를 기록한다.

**승인 게이트**: T050~T056의 변경 파일과 검증 결과를 보고한 뒤 중단한다. 사용자가
전체 완료 검증 진행을 명시적으로 승인하기 전에는 추가 파일을 변경하지 않는다.

---

## 전체 완료 검증

**선행 조건**: App 패키지(작업 패키지 2)의 구현·검증·결과 보고가 완료되어야 한다.

- [X] T057 [no-write] `project_build_runner build`·`compile`·`test`를 전체 공유 scheme
  기준으로 실행하고 결과를 기록한다.
- [X] T058 [no-write] `quickstart.md`의 시나리오 1~3 검증 절차(테스트 target별 실행,
  `transitionLog` 조회)와 수동 확인 절차(Simulator에서 로그아웃/재로그인/뒤로 가기
  흐름 재현)를 수행하고 SC-001~SC-005 각각의 통과 여부를 기록한다(SC-006은 T061에서
  별도 절차로 확인한다).
- [X] T059 [no-write] `grep -n "Router" docs/conventions/tca.md`로 Router 패턴 섹션이
  실제로 존재하는지 확인한다(FR-011).
- [X] T060 [no-write] `grep -rn "@Shared\|@Binding\|inout " sources/Projects/Feature/Onboarding
  sources/Projects/Feature/AppEntry sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`로
  Router보다 긴 생명주기 상태에 TCA `@Shared`·`Binding`·`inout` 기반 저장이 없는지
  확인한다(FR-012). 일치하는 결과가 있으면 각 위치가 실제 FR-012 위반인지 판단해 근거와
  함께 보고한다.
- [X] T061 [no-write] `OnboardingGuideFeature`·`CurationFeature`·`OnboardingExitFeature`·
  `OnboardingRouterFeature` 각 Reducer의 `body`를 코드 리뷰로 확인해, 자신이 속한 책임
  단위(온보딩 안내/큐레이션/전환 판단/Router)가 아닌 다른 Feature가 소유한 State 필드를
  직접 대입·변경하는 Action case가 하나도 없는지 검증한다(SC-006). 검토한 파일·라인과
  판단 근거(위반 없음 또는 발견된 위반과 조치)를 기록한다.

## 의존성과 실행 순서

### 패키지 순서와 승인 게이트

- **Feature → App** 순서로 진행한다. 근거: `docs/architecture.md` 3.1의 의존성 표에서
  `App → Feature, Composition, Domain`이므로 App은 Feature가 제공하는 새 Reducer
  타입(`AppEntryFeature`, `OnboardingRouterFeature`)이 먼저 존재해야 그것을 조합하는
  코드를 작성·컴파일할 수 있다. Feature는 App에 의존하지 않으므로 독립적으로 먼저
  완료할 수 있다.
- **Composition은 이 기능에 포함되지 않는다** — `AppComposition.swift`가 이미 필요한
  모든 UseCase를 개별 프로퍼티로 제공하고 있어 변경할 것이 없다(`research.md` 4절).
- 한 번에 한 패키지만 구현한다. Feature 패키지의 모든 작업과 검증이 끝나기 전에는
  App 패키지 작업을 시작하지 않는다.
- 각 패키지의 변경 파일과 검증 결과를 보고하고 명시적 사용자 승인을 받은 뒤 다음
  패키지로 진행한다.

### 변경 시나리오 추적성

- **S1(책임별 Feature 분리)**: T001~T049(Feature 전체), T052~T055(App)에서 구현되고,
  T049·T056·T057에서 컴파일·테스트로, T058에서 SC-002로, T061에서 SC-006(응집도)으로
  검증한다.
- **S2(App Root 진입 판단과 Router 조합)**: T001, T005, T010, T015, T019, T050~T054에서
  구현되고 T058에서 SC-003·SC-004로 검증한다.
- **S3(화면 이동 추적)**: T004, T005, T009, T010, T018, T019에서 구현되고 T058에서
  SC-004로 검증한다.
- 각 시나리오는 관련된 모든 패키지가 완료된 뒤 `spec.md`의 수용 시나리오 기준으로
  독립 검증한다.
- **FR-012(Router보다 긴 생명주기 상태 공유 금지)**: 특정 시나리오 라벨에 종속되지 않는
  전 패키지 횡단 설계 제약이며, T004·T005·T015~T019(Feature)와 T052~T054(App)의 구현이
  이 제약을 지켜야 하고 T060에서 grep 기반으로 검증한다.

### 패키지 내부 실행

- Feature 패키지의 T006~T010(신규 Reducer 테스트)은 서로 다른 파일이므로 `[P]`로
  표시된 항목끼리 병렬 실행할 수 있다. T011~T014(기존 테스트 갱신)도 서로 다른
  파일이라 병렬 가능하지만 대상 Reducer 구현(T015~T019)이 끝나야 통과하므로 실행
  순서상 테스트 작성 자체는 구현 전에, 통과 확인은 구현 후에 이뤄진다.
- T030~T041(Preview)은 서로 다른 파일이라 `[P]`로 병렬 실행할 수 있다.
- App 패키지의 T050·T051은 서로 다른 파일이라 병렬 가능하다. T052~T055는 같은 파일
  (`AppRootFeature.swift`)을 여러 단계로 수정하거나 서로 의존하므로 순차 실행한다.
- 다른 패키지(Feature/App)의 작업은 승인 게이트를 넘어 병렬 실행하지 않는다.

## 구현 전략

1. Feature 패키지의 준비(T001~T005) → 테스트(T006~T014) → 구현(T015~T048) → 검증
   (T049)을 모두 완료한다.
2. 변경 파일과 실제 테스트 결과(Red→Green 전환 포함)를 보고하고 App 패키지 진행 승인을
   요청한 뒤 중단한다.
3. 승인 후 App 패키지의 테스트(T050~T051) → 구현(T052~T055) → 검증(T056)을 완료한다.
4. 변경 파일과 검증 결과를 보고하고 전체 완료 검증 진행 승인을 요청한 뒤 중단한다.
5. 승인 후에만 T057~T061의 전체 `[no-write]` 검증(빌드·테스트, 수용 시나리오, 문서
   섹션 존재, FR-012 grep 검증, SC-006 응집도 코드 리뷰)을 실행한다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 파일 변경 작업은 정확한 경로를 포함한다.
- 변경 시나리오의 독립성은 유지하되 구현·승인 단위는 패키지(Feature → App)다.
- Composition 패키지 작업이 없는 것은 누락이 아니라 `research.md` 4절에서 실제
  코드를 읽고 확인한 결과다.
- 문제 해결과 암묵지 기록(`trouble-shooting.md`, `tacit-knowledge.md`)은 이 작업
  ID들로 생성하지 않는다.
