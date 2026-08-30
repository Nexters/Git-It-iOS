# 작업 목록: 홈 화면과 MainShell 4탭 통합

**입력**: `/specs/018-home-screen/`의 `plan.md`, `spec.md`, `research.md`, `data-model.md`,
`contracts/`, `quickstart.md`

**선행 조건**: `feature/home-screen` 브랜치와 활성 기능 `specs/018-home-screen`의
정합성이 `tools/spec-kit/bin/validate.sh`로 확인되어야 한다.

**Git 기준선**: `/speckit-implement`를 시작할 때 이 `tasks.md`의 blob hash와 전체
diff를 snapshot한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이
필요한 경우에만 선택한다.

**테스트**: 기능 명세가 reducer, 표시 변환, UIComponent 계약, Preview·접근성 검증을
명시적으로 요구하므로 테스트 작업을 포함한다. 각 패키지에서 테스트를 구현보다
먼저 작성하고 예상한 이유로 실패하는지 확인한다.

**구성**: 의존 방향 `App → Feature`, `Feature → UI, Domain`에 따라 `UI → Feature → App`
순서로 실행한다. Domain·Data·Infrastructure·Composition은 현재 계약을 변경 없이
재사용하므로 실행 단위에서 제외한다. 모든 파일 변경은 단일 패키지에서 독립
컴파일할 수 있으므로 다중 패키지 integration unit은 없다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능하다.
- **[S1]**: MainShell이 Home부터 시작하고 네 탭을 전환한다.
- **[S2]**: 등록된 학습 프로젝트를 Home에서 확인하고 이어서 학습한다.
- **[S3]**: 프로젝트 조회 결과에 맞는 로딩·빈 상태·실패 표현을 제공한다.
- **[S4]**: 기존 프로젝트 등록 흐름을 요청하고 전체 보기로 project 탭을 선택한다.
- **[S5]**: Figma 근거와 접근성을 갖춘 Home을 검증한다.
- **[no-write]**: `make tuist`의 파생 workspace·project·symbolic link·cache 갱신을 제외하고
  추적 대상 소스·문서와 Git index를 직접 변경하지 않는 검증이다.

---

## 실행 단위 1: UI 패키지

**목표**: `HomeProjectCard`가 표시 값, Domain 순서 기반 색 variant, 카드 본문과
학습 버튼의 독립 control 계약만 소유하고 목록 좌표 기반 회전을 소유하지 않게 한다.

**소유 경로**: `sources/Projects/UI/Component/CollectionItems/HomeProjectCard/HomeProjectCard.swift`,
`sources/Projects/UI/Component/CollectionItems/HomeProjectCard/HomeProjectCard+Variant.swift`,
`sources/Projects/UI/Tests/Component/Unit/CollectionItems/HomeProjectCardTests.swift`

**관련 변경 시나리오**: S2, S5

**독립 검증**: UI scheme의 build-for-testing·test-without-building이 통과하고,
`currentSetLabel`의 원문 보존, 3색 variant, 두 control의 독립 콜백·disabled 학습·44
44pt 최소 터치 계약이 자동 테스트로 확인된다.

### 테스트

- [X] T001 [S2] `sources/Projects/UI/Tests/Component/Unit/CollectionItems/HomeProjectCardTests.swift`에 `currentSetLabel` 원문, `Variant(index:)` 3색 순환, progress 0...1 clamp, 본문·학습 독립 콜백, 학습 disabled와 44pt 최소 터치 계약 테스트를 작성한다

### 구현

- [X] T002 [P] [S2] `sources/Projects/UI/Component/CollectionItems/HomeProjectCard/HomeProjectCard.swift`의 `currentSet: Int`를 손실 없는 `currentSetLabel: String`으로 교체하고 `onSelect`·`onStart`·학습 활성 입력을 받는 형제 control로 본문과 재생 동작을 배타적으로 구현한다
- [X] T003 [P] [S2] `sources/Projects/UI/Component/CollectionItems/HomeProjectCard/HomeProjectCard+Variant.swift`에서 `rotationDegrees`를 제거해 variant를 Domain 조회 순서 `index % 3`의 색·대비 표현으로만 제한한다

### 패키지 검증과 결과 보고

- [X] T004 [no-write] `Makefile`의 `make tuist`를 실행한 뒤 `sources/GitIt.xcworkspace`의 UI scheme을 build-for-testing·test-without-building하고, 실행 전후 `git status --short`를 비교해 추적 파일·index 변경이 없을 때만 T001~T003의 변경 파일과 결과를 보고한다

**진행 점검**: T001~T004의 변경 파일과 검증 결과를 보고하고 Feature 실행 단위로
연속 진행한다. 새 범위·권한이 필요할 때만 중단하고 명시적 승인을 요청한다.

---

## 실행 단위 2: Feature 패키지

**목표**: Home의 독립 조회 State·Effect·intent, 현재 좌표를 사용한 카드 스크롤,
표시 상태·Preview를 구현하고 MainShell이 Home과 기존 세 child를 함께 소유하게 한다.

**소유 경로**: 아래 T005~T029에 적힌 `sources/Projects/Feature/Home/`,
`sources/Projects/Feature/MainShell/`, `sources/Projects/Feature/Tests/Home/`,
`sources/Projects/Feature/Tests/MainShell/` 하위의 정확한 파일만 소유한다.

> 위 소유 경로는 설명을 위한 범위이며 구현 write allowlist는 아래 각 작업에 적힌
> 정확한 파일 경로로만 구성한다.

**관련 변경 시나리오**: S1, S2, S3, S4, S5

**독립 검증**: Feature scheme의 build-for-testing·test-without-building으로 최초 1회 조회,
교차 실패·재시도·stale 응답, Domain 표시 변환·intent payload, 앵커 보간, 네 탭·Home
기본·전체 보기·초기화가 검증된다.

### 테스트 기반

- [X] T005 [P] `sources/Projects/Feature/Tests/Home/TestDoubles/HomeLearningProjectsUseCaseMock.swift`에 순서가 있는 `Result<LearningProjectPage, LearningProjectError>` 응답, 호출 횟수와 지연 완료를 관찰할 수 있는 actor Test Double을 작성한다
- [X] T006 [P] `sources/Projects/Feature/Tests/Home/TestDoubles/HomeMemberProfileUseCaseMock.swift`에 순서가 있는 `Result<MemberProfile, MemberError>` 응답, 호출 횟수와 지연 완료를 관찰할 수 있는 actor Test Double을 작성한다
- [X] T007 [P] `sources/Projects/Feature/Tests/Home/TestDoubles/HomeTestFixture.swift`에 nullable profile 4종, 0·1·3개 이상 project page, 학습 ID 유효·무효 표본을 Domain 원문 기반으로 정의한다

### 테스트

- [X] T008 [P] [S2] `sources/Projects/Feature/Tests/Home/Models/HomeCardScrollLayoutTests.swift`에 `P0/P1/P2` 각도, 두 중간점의 선형 보간, 양쪽 clamp, 1·2개 카드 포즈가 `±0.5°` 오차 이내인지 검증하는 테스트를 작성한다
- [X] T009 [P] [S2] `sources/Projects/Feature/Tests/Home/Screens/HomeProjectPresentationTests.swift`에 `LearningProjectSummary`의 표시 값·Domain 순서 variant·percent-to-ratio 변환·학습 ID 활성 변환과 카드 본문·학습 intent payload를 검증한다
- [X] T010 [P] [S3] `sources/Projects/Feature/Tests/Home/Reducers/HomeFeatureLoadTests.swift`에 최초 profile/project 각 1회 조회, 복귀 시 추가 조회 0회, 독립 성공·실패, profile만 재시도, stale 응답 무시를 `TestStore`로 검증한다
- [X] T011 [P] [S4] `sources/Projects/Feature/Tests/Home/Reducers/HomeFeatureNavigationTests.swift`에 있음·없음 CTA의 동일 등록 delegate, 전체 보기 Action, ProjectDetail delegate와 실제 destination 생성 0건을 검증한다
- [X] T012 [P] [S5] `sources/Projects/Feature/Tests/Home/Screens/HomeAccessibilityTests.swift`에 profile 보조 문구 4종, 기본 avatar, CTA·전체 보기·카드·학습의 접근성 label·disabled 의미와 긴 표시 값 변환을 검증한다
- [X] T013 [P] [S1] `sources/Projects/Feature/Tests/MainShell/Reducers/MainShellFeatureTests.swift`에 Home 기본·네 탭 순서, 탭 전환 시 child State 보존, Home 복귀 시 추가 조회 0회, 로그아웃·계정 삭제 초기화를 검증한다

### Home 구현

- [X] T014 [P] [S2] `sources/Projects/Feature/Home/Models/HomeCardScrollLayout.swift`에 현재 layout의 `P0/P1/P2` 중심 좌표를 산출하고 `0° ↔ +16° ↔ -12°`를 연속 선형 보간·clamp하는 index·variant 독립 순수 함수를 구현한다
- [X] T015 [P] [S3] `sources/Projects/Feature/Home/Reducers/HomeFeature.swift`에 initializer로 주입된 두 Use Case, 독립 `ProfileLoad`·`ProjectLoad`, 각 request ID·CancelID, 최초 1회 조회, profile 전용 재시도와 stale 응답 거부를 구현한다
- [X] T016 [S2] `sources/Projects/Feature/Home/Reducers/HomeFeature.swift`에 카드 본문의 `projectID` 상세 intent와 세 ID가 모두 존재할 때만 생성되는 학습 intent를 추가하고 무효 ID에서 임의 값을 재구성하지 않는다
- [X] T017 [S4] `sources/Projects/Feature/Home/Reducers/HomeFeature.swift`에 프로젝트 있음·없음이 공유하는 등록 intent와 MainShell이 해석할 `showAllProjectsTapped` Action을 추가하되 실제 destination은 만들지 않는다
- [X] T018 [S2] `.agents/skills/implement-figma-ui/SKILL.md`의 직접 노드 대조 절차를 적용해 `sources/Projects/Feature/Home/Screens/HomeScreen.swift`에 `ScreenContainer`·`ScreenHeader`·`HomeProjectCard`·DesignSystem token을 재사용하고, Domain 표시 값·고정 variant·`scrollTargetLayout`·`viewAligned`·`visualEffect`로 모든 `items`의 스크롤·좌표 회전을 구현하며 SwiftUI `ScrollView`가 scroll로 인식한 접촉에서 카드·학습 intent를 억제한다
- [X] T019 [S3] `sources/Projects/Feature/Home/Screens/HomeScreen.swift`에 idle·loading이 빈 상태로 보이지 않는 분기, 성공 0개·프로젝트 실패의 동일 illustration·문구·CTA, profile 실패의 헤더 내 error·전용 retry와 독립 영역 보존을 구현한다
- [X] T020 [S5] `sources/Projects/Feature/Home/Screens/HomeScreen.swift`에 profile·CTA·전체 보기·카드·학습 control의 중복 없는 접근성 label·trait·disabled 의미와 iOS 26 `DynamicTypeSize` 전체 12단계·긴 표시 값에서 핵심 동작을 보존하는 layout을 추가한다

### Preview 구현

- [X] T021 [P] [S5] `sources/Projects/Feature/Home/Previews/HomePreviewSupport/HomePreviewFetchLearningProjects.swift`에 loading·성공 0개·성공 1개 이상·실패를 결정론적으로 반환하는 Preview Use Case를 작성한다
- [X] T022 [P] [S5] `sources/Projects/Feature/Home/Previews/HomePreviewSupport/HomePreviewFetchMemberProfile.swift`에 nullable 표시 조합의 성공과 헤더 실패를 결정론적으로 반환하는 Preview Use Case를 작성한다
- [X] T023 [S5] `sources/Projects/Feature/Home/Previews/HomePreviewSupport/HomePreviewSupport.swift`에 두 Preview Use Case를 initializer로 주입해 project present·absent·loading·project failure-as-empty·profile failure Store를 만드는 표본을 구성한다
- [X] T024 [S5] `sources/Projects/Feature/Home/Previews/HomeScreenPreviews.swift`에 `Project Present - 1465:19015`, `Project Absent - 1542:19610`, `Loading`, `Project Failure as Empty - 1542:19610`, `Profile Failure` 상태를 `360×800` 비교용 진입점으로 추가한다

### MainShell 통합

- [X] T025 [P] [S1] `sources/Projects/Feature/MainShell/Models/MainShellTab.swift`에 `.home`을 선행 case로 추가하고 `home`·`projects`·`saved`·`settings`의 제목·icon·순서 계약을 구현한다
- [X] T026 [S1] `sources/Projects/Feature/MainShell/Reducers/MainShellFeature.swift`에 `HomeFeature.State`·Action·Scope와 두 기존 Use Case의 initializer 주입을 추가하고 기본 탭과 sign-out·account deletion 후 네 child를 새 `MainShellFeature.State()`로 초기화한다
- [X] T027 [S1] `sources/Projects/Feature/MainShell/Screens/MainShellScreen.swift`에 Home 탭의 scoped `HomeScreen`과 projects·saved·settings의 기존 제목 placeholder를 분기하고 `TabShell` 선택 상태를 유지한다
- [X] T028 [S4] `sources/Projects/Feature/MainShell/Reducers/MainShellFeature.swift`에 Home의 `showAllProjectsTapped`을 `selectedTab = .projects`로 해석하고 등록·ProjectDetail·학습 delegate payload를 App 경계로 손실 없이 중계한다

### 패키지 검증과 결과 보고

- [X] T029 [no-write] `Makefile`의 `make tuist`를 실행한 뒤 `sources/GitIt.xcworkspace`의 Feature scheme을 build-for-testing·test-without-building하고, 실행 전후 `git status --short`를 비교해 추적 파일·index 변경이 없을 때만 T005~T028의 변경 파일과 결과를 보고한다

**진행 점검**: T005~T029의 변경 파일과 검증 결과를 보고하고 App 실행 단위로
연속 진행한다. 새 범위·권한이 필요할 때만 중단하고 명시적 승인을 요청한다.

---

## 실행 단위 3: App 패키지

**목표**: MainShell이 전달한 Home 등록·ProjectDetail·학습 intent를 App 경계에서
명시적으로 수신하되 후속 destination과 기존 authentication·onboarding·splash route를 변경하지
않고, MainShell 재생성에서 Home 기본을 보존한다.

**소유 경로**: `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`,
`sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`

**관련 변경 시나리오**: S1, S4

**독립 검증**: AppTests scheme의 build-for-testing·test-without-building으로 세 intent의 payload가
보존되고 route·destination이 변경되지 않으며 sign-out·session invalidation·reset 후 새
MainShell이 Home 기본인지 검증한다.

### 테스트

- [ ] T030 [S4] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`에 MainShell의 등록·ProjectDetail·학습 delegate가 payload를 보존하면서 AppRoot route·MainShell State·destination을 변경하지 않는 테스트를 작성한다
- [ ] T031 [S1] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`에 sign-out·session invalidation·reset으로 `MainShellFeature.State()`가 재생성된 뒤 다음 MainShell 진입이 Home으로 시작하는 테스트를 추가한다

### 구현

- [ ] T032 [S4] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`에 MainShell의 Home 등록·ProjectDetail·학습 delegate case를 명시적 no-op으로 처리해 실제 ProjectRegistration·ProjectDetail·Quiz destination을 생성하지 않는다

### 패키지 검증과 결과 보고

- [ ] T033 [no-write] `Makefile`의 `make tuist`를 실행한 뒤 `sources/GitIt.xcworkspace`의 AppTests scheme을 build-for-testing·test-without-building하고, 실행 전후 `git status --short`를 비교해 추적 파일·index 변경이 없을 때만 T030~T032의 변경 파일과 결과를 보고한다

**진행 점검**: T030~T033의 변경 파일과 검증 결과를 보고하고 전체 완료
검증으로 연속 진행한다. 새 범위·권한이 필요할 때만 중단하고 명시적 승인을 요청한다.

---

## 전체 완료 검증

**선행 조건**: App 패키지의 파일 변경까지 완료하고, 전체 검증과 필수
`after_implement` hook 결과를 포함할 마지막 App 커밋 단위를 아직 commit하지 않은
상태여야 한다.

**쓰기 제한**: 아래 작업은 `make tuist`의 파생 산출물을 제외하고 추적 대상
소스·문서와 Git index를 직접 변경하지 않는다. 검증 실패 시 수정은 해당 소유
패키지의 미완료 작업으로 되돌려 수행하고 이 섹션의 write 범위를 넓히지 않는다.

**커밋 경계**: T034~T044와 필수 `after_implement` hook을 마친 뒤 App 마지막
단위를 재검증하고 최종 commit한다. 이미 파일 변경 단위가 모두 commit된 단순
재개에서는 `tasks.md` 완료 표시를 위한 별도 최종 검증 단위를 둔다.

- [ ] T034 [no-write] `Makefile`의 `make tuist`를 실행하고 `tools/spec-kit/bin/validate.sh`로 현재 branch와 `specs/018-home-screen/spec.md` metadata의 identity, Spec-Kit skill write boundary와 mandatory hook policy를 확인한다. `specs/018-home-screen/spec.md`·`specs/018-home-screen/plan.md`·`specs/018-home-screen/tasks.md`의 존재와 현재 feature 경로 참조는 별도로 판독하고, `validate.sh` 결과를 세 산출물 내용의 교차 정합성 검증으로 보고하지 않으며, 실행 전후 Git 상태에 새 추적 파일·index 변경이 생기면 완료로 처리하지 않는다
- [ ] T035 [no-write] `tools/githooks/project-build/bin/run.sh build`로 `sources/GitIt.xcworkspace`의 모든 공유 scheme production Debug build를 실행하고 성공·실패 scheme을 별도로 기록한다
- [ ] T036 [no-write] `tools/githooks/project-build/bin/run.sh compile-unit`로 `sources/GitIt.xcworkspace`의 unit test scheme build-for-testing을 실행하고 production build와 구분해 결과를 기록한다
- [ ] T037 [no-write] `tools/githooks/project-build/bin/run.sh test-unit`로 `sources/GitIt.xcworkspace`의 test-without-building을 실행하고 test compile과 구분해 실제 실행 결과를 기록한다
- [ ] T038 [no-write] [S1] `sources/GitIt.xcworkspace`의 MainShell 자동화 결과와 Simulator에서 Home 기본·네 탭 순서·Home 복귀 상태 보존·나머지 세 탭 placeholder를 독립 수용 기준으로 검증한다
- [ ] T039 [no-write] [S2] `sources/GitIt.xcworkspace`의 project-present Home Preview와 Simulator에서 Domain 표시 값·모든 `items`·색 variant 고정·카드 본문·학습 intent·drag 우선·감속 후 `P0 ± 1pt`를 독립 수용 기준으로 검증한다
- [ ] T040 [no-write] [S3] `sources/GitIt.xcworkspace`의 loading·project-absent·project-failure-as-empty·profile-failure Preview에서 빈 상태 노출 시점, 실패 표현, 교차 영역 보존·profile 전용 retry를 독립 수용 기준으로 검증한다
- [ ] T041 [no-write] [S4] `sources/GitIt.xcworkspace`의 project-present·project-absent Home에서 동일 등록 intent 1회와 `전체 보기`의 project 탭 전환을 확인하고 ProjectRegistration·ProjectDetail·Quiz·새 project-list destination이 생성되지 않았음을 독립 수용 기준으로 검증한다
- [ ] T042 [no-write] [S5] `sources/GitIt.xcworkspace`의 `360×800` Home Preview를 Figma `1465:19015`·`1542:19610`과 비교해 차이를 수정 또는 승인 예외로 100% 분류하고, 승인 예외는 사용자 명시적 승인과 검증 결과·PR의 차이·근거·영향·미검증 범위 기록을 요구하며 미승인 차이가 남으면 실패로 처리한다. Simulator에서 VoiceOver label·trait·탭 선택 상태·`44pt × 44pt` 터치·iOS 26 `DynamicTypeSize` 전체 12단계(`xSmall`~`accessibility5`)·긴 이름·기술 스택·세트 제목을 독립 수용 기준으로 검증한다
- [ ] T043 [no-write] `sources/Projects/Feature/Home/Models/`·`sources/Projects/Feature/Home/Reducers/`·`sources/Projects/Feature/Home/Screens/`의 production source를 정적 검사해 Data·Infrastructure·Composition 직접 import와 production `@Dependency` 기반 Use Case 조회가 각각 0건임을 확인하고, `git diff -- sources/Projects/Domain/ sources/Projects/Data/ sources/Projects/Infrastructure/`로 새 Avatar Backend·Domain 계약 추가가 0건임을 확인해 SC-010 결과를 별도로 기록한다
- [ ] T044 [no-write] [S4] 기능 기준 HEAD `f22467dc1b0224883f0b59c7f241123605d58fc3`부터 현재 HEAD까지의 `git diff --name-status`와 `git status --short --untracked-files=all`을 `sources/Projects/Domain/`·`sources/Projects/Data/`·`sources/Projects/Infrastructure/`·`sources/Projects/Feature/Home/`에 한정해 함께 검사하고, Home 전용 프로젝트 등록 API·Domain 모델·등록 Feature 선언이나 파일 추가가 0건임을 확인한다. 등록 delegate intent만 허용된 경계임을 구분해 FR-020·SC-005 결과를 별도로 기록한다

## 의존성과 실행 순서

### 실행 단위 순서와 위험 기반 승인

```text
UI (T001~T004)
  ↓ Feature가 UIComponent 공개 계약에 의존
Feature (T005~T029)
  ↓ App이 Feature 상태·Action·delegate에 의존
App (T030~T033)
  ↓
전체 [no-write] 검증 (T034~T044)
```

- UI의 공개 initializer·variant 변경을 먼저 컴파일 가능하게 완료한 뒤 Feature가
  소비한다. Feature의 새 Home·MainShell delegate 계약이 완료된 뒤 App switch를 갱신한다.
- Domain과 Composition은 두 Use Case를 이미 제공·주입하므로 작업 순서에 포함하지
  않는다. Tuist manifest는 기존 source glob과 target 의존성이 범위를 포함하므로 변경하지 않는다.
- 각 실행 단위를 구현·검증하고 변경 파일과 결과를 보고한 뒤 동일한
  기능 범위의 다음 단위로 반복 승인 없이 연속 진행한다.
- 새 범위, 파괴적·복구 곤란 작업, remote·외부 상태 변경, 사용자 소유 변경의 소비,
  새 보안·비용·제품 결정이 필요할 때만 중단하고 명시적 승인을 요청한다.

### 변경 시나리오 추적성과 독립 수용 기준

- **S1**: UI 완료 후 Feature의 `MainShellFeatureTests`와 App 초기화 테스트만으로
  Home 기본·네 탭 순서·placeholder·child State 보존·재진입을 검증할 수 있다.
- **S2**: UI의 카드 계약과 Feature의 fixture·순수 좌표 함수·reducer·HomeScreen을
  함께 실행해 Domain 표시 값·색 고정·회전·스냅·본문·학습 intent를 검증할 수 있다.
- **S3**: `HomeFeatureLoadTests`와 4개 상태 Preview를 사용해 idle·loading·empty·failure,
  교차 영역 보존, profile 전용 retry·stale 거부를 독립적으로 검증할 수 있다.
- **S4**: Home·MainShell·App reducer 테스트로 있음·없음 CTA의 동일 등록 intent,
  전체 보기의 project 탭 선택과 실제 destination 0건을 검증할 수 있다.
- **S5**: Figma node ID가 포함된 deterministic Preview와 접근성 표시 테스트,
  `360×800` Simulator의 Figma 차이 분류·VoiceOver·`DynamicTypeSize` 12단계·터치·drag
  검증으로 독립 수용할 수 있다.

**최소 가치 범위**: S1은 MainShell 진입과 상태 수명의 기반이지만 Home의 실제 화면이
조회·표시되려면 UI·Feature 실행 단위가 함께 완료되어야 한다. 실행은 S1만을
위해 의존 순서를 건너뛰지 않고, 새 권한이 필요 없으면 UI → Feature → App을 연속
진행한다.

### 실행 단위 내부 병렬 실행 예시

- **UI**: T001이 예상한 이유로 실패한 후 서로 다른 파일을 바꾸는 T002와 T003을
  병렬 실행할 수 있다. T004는 둘이 모두 완료된 뒤 실행한다.
- **Feature**: T005·T006·T007을 병렬로 작성한 뒤, 서로 다른 테스트 파일인
  T008~T013을 병렬로 작성할 수 있다. Red 확인 후 T014·T015·T025를 병렬
  시작할 수 있고, T021·T022는 Home 공개 계약이 완료된 뒤 병렬 실행할 수 있다.
- **App**: T030과 T031은 동일 파일을 변경하므로 순차 실행한다. T032는 두
  테스트가 예상한 이유로 실패한 뒤 실행한다.
- **전체 검증**: T034~T044는 공유 DerivedData·Simulator·UI 상태를 사용하므로
  병렬 실행하지 않는다.

## 구현 전략

1. 중단 단위와 `specs/018-home-screen/tasks.md` 전체 diff를 분류하고 blob hash와 diff를
   기준선으로 고정한다. 재개 단위가 없으면 UI의 첫 미완료 작업부터 시작한다.
2. 선택한 실행 단위의 미완료 작업을 파일을 수정하기 전에 하나 이상의 논리적
   커밋 단위로 설계하고 작업 ID·정확한 파일·검증·커밋 메시지를 제시한다.
3. 각 단위의 구현·검증·`[X]` 표시·정확한 staging·commit을 순서대로 완료하고
   생성된 commit을 확인한다. 단, App의 마지막 단위는 전체 검증과 필수 hook까지
   열린 상태로 유지한다.
4. 실행 단위가 커밋되면 변경 파일·검증·commit을 보고하고 동일 범위의 다음
   실행 단위로 이어간다.
5. 새 권한이 필요한 경계가 발견되면 변경을 시작하기 전에 중단하고 명시적 승인을
   요청한다.
6. T034~T044를 순차 실행하고 필수 `after_implement` swift-format hook을 적용한 뒤
   포맷 변경과 전체 검증 결과를 재확인하고 App 마지막 단위를 최종 commit한다.

## 참고

- 작업 ID는 실제 실행 순서대로 T001~T044를 사용한다.
- 파일 변경 작업은 정확한 저장소 상대 경로를 포함한다.
- 변경 시나리오는 독립 수용성을 유지하되 구현 단위는 패키지다.
- 커밋 단위는 `tasks.md`에 고정하지 않고 `/speckit-implement`가 실행 시점에 설계한다.
- 문제 해결·암묵지 기록 파일을 구현 작업으로 생성하지 않는다.
