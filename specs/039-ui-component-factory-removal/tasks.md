---

description: "UIComponent 팩토리 제거 작업 목록"
---

# 작업 목록: UIComponent 정적 팩토리 제거

**입력**: `/specs/039-ui-component-factory-removal/`의 설계 문서

**선행 조건**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/component-creation-api.md](contracts/component-creation-api.md),
[quickstart.md](quickstart.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를
snapshot한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만
선택한다.

**테스트**: 명세는 새 테스트를 요구하지 않는다. 기존 계약 테스트의 호출부만 전환 범위에
포함한다(FR-007).

**구성**: [plan.md](plan.md)가 확정한 실행 단위 7개를 최상위 구조로 사용한다. UI 패키지만
바꾸는 단위는 단일 패키지, UI 공개 API 제거와 Feature 호출부 전환이 같은 compile 경계를
공유하는 단위는 integration unit이다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[시나리오]**: S1(단일 변형 축 컴포넌트), S2(ScreenEdgeScrim), S3(StyledText),
  S4(컨벤션 개정)
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 실행 또는 수동
  검증. `make tuist`의 파생 산출물 갱신은 허용하되 실행 전후 Git 상태를 비교하고 추적 파일
  변경이 생기면 완료로 처리하지 않는다.
- 검증 명령의 실행기 경로는 `project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)`로
  얻는다. 단위 검증은 [quickstart.md](quickstart.md)의 절차를 따른다.
- 제거 대상 팩토리 30개와 전환 후 공개 표면은
  [contracts/component-creation-api.md](contracts/component-creation-api.md)가 정본이다.

## 실행 단위 소유권 규칙

- UI 패키지의 컴포넌트·테스트는 그 컴포넌트를 전환하는 실행 단위가 소유한다.
- Feature 호출부는 해당 컴포넌트의 실행 단위가 함께 소유한다. UI의 팩토리를 제거하면
  Feature가 즉시 compile되지 않으므로 분리할 수 없다.
- 컨벤션 문서 7건(개정 6건 + 삭제 1건)은 실행 단위 7이 소유하며, 각 문서의 정확한 경로를
  작업에 명시한다.
- 여러 단위가 같은 파일을 만지는 경우(`OverlayContainer.swift`, `ProjectRow.swift`,
  `LabeledCard.swift`, `ConfirmationSheet.swift`, `SheetSurface.swift`)에는 단위 간 병렬
  실행을 하지 않는다.

---

## 실행 단위 1: ActionButton (단일 패키지: UI)

**목표**: `ActionButton`의 정적 팩토리 9개를 제거하고 호출부를 두 초기화 메서드로 전환한다.

**소유 경로**: `sources/Projects/UI/Component/Controls/ActionButton.swift`,
`sources/Projects/UI/Component/Overlays/ConfirmationSheet.swift`,
`sources/Projects/UI/Component/Overlays/SheetSurface/SheetSurface.swift`,
`sources/Projects/UI/Component/Scaffolds/BottomActionBar.swift`,
`sources/Projects/UI/Component/Scaffolds/OverlayContainer.swift`,
`sources/Projects/UI/Tests/Component/Unit/Controls/ActionButtonSizeContractTests.swift`,
`sources/Projects/UI/Tests/Component/Unit/Scaffolds/OverlayContainerContractTests.swift`

**관련 변경 시나리오**: S1

**독립 검증**: UI 패키지만 compile하고 `ActionButton.` 뒤에 변형 이름이 오는 호출이 저장소에
남지 않는지 확인한다. Feature 호출부가 없으므로 이 단위는 UI 안에서 닫힌다.

### 구현

- [X] T001 [S1] `sources/Projects/UI/Component/Controls/ActionButton.swift`에서 정적 팩토리
  9개(`primary`, `secondary`, `destructive`, `text`, `primaryText` 계열)를 제거하고 기존
  `public init(title:...)`과 `public init(styledText:...)` 두 경로만 남긴다
- [X] T002 [S1] `sources/Projects/UI/Component/Overlays/ConfirmationSheet.swift`의
  `ActionButton` 팩토리 호출을 `style:`·`size:` 인자를 넘기는 초기화 호출로 전환한다
- [X] T003 [P] [S1] `sources/Projects/UI/Component/Overlays/SheetSurface/SheetSurface.swift`의
  `ActionButton` 팩토리 호출을 초기화 호출로 전환한다
- [X] T004 [P] [S1] `sources/Projects/UI/Component/Scaffolds/BottomActionBar.swift`의
  `ActionButton` 팩토리 호출을 초기화 호출로 전환한다
- [X] T005 [P] [S1] `sources/Projects/UI/Component/Scaffolds/OverlayContainer.swift`의
  `ActionButton` 팩토리 호출을 초기화 호출로 전환한다
- [X] T006 [P] [S1] `sources/Projects/UI/Tests/Component/Unit/Controls/ActionButtonSizeContractTests.swift`의
  팩토리 호출을 초기화 호출로 전환하고 검증 대상 계약을 유지한다
- [X] T007 [P] [S1] `sources/Projects/UI/Tests/Component/Unit/Scaffolds/OverlayContainerContractTests.swift`의
  `ActionButton` 팩토리 호출을 초기화 호출로 전환한다

### 정리와 단위 검증

- [X] T008 [no-write] [quickstart.md](quickstart.md)의 단위 검증 절차로 `compile`을 실행하고
  `ActionButton` 잔여 팩토리 호출 grep이 0건인지 확인한다

**진행 점검**: T001~T008의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행
단위로 진행한다.

---

## 실행 단위 2: ScreenEdgeScrim (단일 패키지: UI)

**목표**: `ScreenEdgeScrim`에 공개 변형 enum `Edge`와 이를 받는 초기화 메서드를 신설하고
정적 팩토리 2개를 제거한다.

**소유 경로**: `sources/Projects/UI/Component/Overlays/ScreenEdgeScrim.swift`,
`sources/Projects/UI/Tests/Component/Unit/Overlays/ScreenEdgeScrimContractTests.swift`

**관련 변경 시나리오**: S2

**독립 검증**: UI 패키지 compile과 `ScreenEdgeScrim` 계약 테스트 통과. `top`/`bottom` 팩토리
호출이 저장소에 남지 않아야 한다.

### 구현

- [X] T009 [S2] `sources/Projects/UI/Component/Overlays/ScreenEdgeScrim.swift`에 공개 변형
  enum `Edge`(`top`, `bottom`)를 추가하고 `GradientToken.topEdgeScrim`·`.bottomEdgeScrim`
  선택을 이 enum이 소유하게 한다([research.md](research.md) §3의 이름 결정)
- [X] T010 [S2] `sources/Projects/UI/Component/Overlays/ScreenEdgeScrim.swift`에
  `public init(edge:height:)`를 추가하고 정적 팩토리 `top(height:)`·`bottom(height:)`와
  같은 파일의 `#Preview` 호출 2곳을 초기화 호출로 전환한다. 이 컴포넌트는 production
  호출부가 없고 프리뷰 2곳과 계약 테스트 2곳이 전부다
- [X] T011 [S2] `sources/Projects/UI/Tests/Component/Unit/Overlays/ScreenEdgeScrimContractTests.swift`의
  호출부를 초기화 호출로 전환한다

### 정리와 단위 검증

- [X] T012 [no-write] [quickstart.md](quickstart.md)의 단위 검증 절차로 `compile`과
  `ScreenEdgeScrim` 계약 테스트를 실행하고 프리뷰 표현이 전환 전과 같은지 확인한다

**진행 점검**: T009~T012의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 실행 단위 3: TagBadge (integration unit: UI, Feature)

**목표**: `TagBadge`의 정적 팩토리 4개를 제거하고 UI·Feature 호출부를 초기화 호출로 전환한다.

**분리 불가 근거**: UI에서 팩토리를 제거하는 순간 `Feature`의 호출부가 compile되지 않는다.
UI만 먼저 변경한 중간 상태는 빌드할 수 없으므로 두 패키지를 한 단위로 묶는다.

**소유 경로**: `sources/Projects/UI/Component/Displays/TagBadge.swift`,
`sources/Projects/UI/Component/CollectionItems/ProjectRow/ProjectRow.swift`,
`sources/Projects/UI/Component/CollectionItems/SelectionCard/SelectionCard.swift`,
`sources/Projects/UI/Tests/Component/Unit/Displays/TagBadgeContractTests.swift`,
`sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+ProfileHeaderView.swift`

**관련 변경 시나리오**: S1

**통합 검증**: UI와 Feature를 함께 포함하는 `compile` 실행과 `TagBadge` 계약 테스트 통과.

### 구현

- [X] T013 [S1] `sources/Projects/UI/Component/Displays/TagBadge.swift`에서 정적 팩토리
  4개를 제거하고 `public init(text:style:size:)`만 공개 생성 경로로 남긴다
- [X] T014 [S1] `sources/Projects/UI/Component/CollectionItems/ProjectRow/ProjectRow.swift`의
  `TagBadge` 팩토리 호출을 초기화 호출로 전환한다
- [X] T015 [P] [S1] `sources/Projects/UI/Component/CollectionItems/SelectionCard/SelectionCard.swift`의
  `TagBadge` 팩토리 호출을 초기화 호출로 전환한다
- [X] T016 [P] [S1] `sources/Projects/UI/Tests/Component/Unit/Displays/TagBadgeContractTests.swift`의
  팩토리 호출을 초기화 호출로 전환한다
- [X] T017 [P] [S1] `sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+ProfileHeaderView.swift`의
  `TagBadge` 팩토리 호출을 초기화 호출로 전환한다

### 정리와 단위 검증

- [X] T018 [no-write] [quickstart.md](quickstart.md)의 통합 검증 절차로 `compile`과 `TagBadge`
  계약 테스트를 실행하고 잔여 팩토리 호출 grep이 0건인지 확인한다

**진행 점검**: T013~T018의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 실행 단위 4: LabeledCard (integration unit: UI, Feature)

**목표**: `LabeledCard`의 `Style`을 `public`으로 올리고 이를 받는 초기화 메서드를 신설한 뒤
정적 팩토리 2개를 제거한다(FR-001a).

**분리 불가 근거**: `LabeledCard`는 현재 공개 초기화 메서드가 없어 팩토리가 유일한 생성
경로다. 팩토리를 제거하면 UI의 `OverlayContainer`와 Feature의 Quiz 화면이 동시에
compile되지 않는다.

**소유 경로**: `sources/Projects/UI/Component/Displays/LabeledCard.swift`,
`sources/Projects/UI/Component/Scaffolds/OverlayContainer.swift`,
`sources/Projects/UI/Tests/Component/Unit/Displays/LabeledCardTests.swift`,
`sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingScreen.swift`,
`sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+EssayResultSection.swift`

**관련 변경 시나리오**: S1

**통합 검증**: UI와 Feature를 함께 포함하는 `compile` 실행과 `LabeledCard` 테스트 통과.

### 구현

- [X] T019 [S1] `sources/Projects/UI/Component/Displays/LabeledCard.swift`의 `private enum Style`을
  `public enum Style`로 올린다. 접근 수준만 바꾸고 `case`·토큰 매핑은 유지한다
- [X] T020 [S1] `sources/Projects/UI/Component/Displays/LabeledCard.swift`에
  `public init(label:text:style:)`을 추가하고 정적 팩토리 `accent(label:text:)`·
  `neutral(label:text:)`를 제거한 뒤 `#Preview` 호출부를 초기화 호출로 전환한다
- [X] T021 [S1] `sources/Projects/UI/Component/Scaffolds/OverlayContainer.swift`의
  `LabeledCard` 팩토리 호출을 초기화 호출로 전환한다
- [X] T022 [P] [S1] `sources/Projects/UI/Tests/Component/Unit/Displays/LabeledCardTests.swift`의
  팩토리 호출을 초기화 호출로 전환한다
- [X] T023 [P] [S1] `sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingScreen.swift`의
  `LabeledCard` 팩토리 호출을 초기화 호출로 전환한다
- [X] T024 [P] [S1] `sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+EssayResultSection.swift`의
  `LabeledCard` 팩토리 호출을 초기화 호출로 전환한다

### 정리와 단위 검증

- [X] T025 [no-write] [quickstart.md](quickstart.md)의 통합 검증 절차로 `compile`과
  `LabeledCard` 테스트를 실행하고 프리뷰 표현이 전환 전과 같은지 확인한다

**진행 점검**: T019~T025의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 실행 단위 5: IconGlassButton (integration unit: UI, Feature)

**목표**: `IconGlassButton`의 정적 팩토리 3개를 제거하고 UI·Feature 호출부를 초기화 호출로
전환한다.

**분리 불가 근거**: Feature 호출부가 11곳으로 가장 많고, UI의 공개 팩토리 제거와 같은
compile 경계를 공유한다.

**소유 경로**: `sources/Projects/UI/Component/Controls/IconGlassButton.swift`,
`sources/Projects/UI/Component/Controls/ScreenControlBar/ScreenControlBar.swift`,
`sources/Projects/UI/Component/CollectionItems/ProjectRow/ProjectRow.swift`,
`sources/Projects/UI/Component/Overlays/WebSheet.swift`,
`sources/Projects/Feature/ProjectList/ProjectListScreen.swift`,
`sources/Projects/Feature/Saved/SavedScreen.swift`,
`sources/Projects/Feature/Saved/SubViews/SavedScreen+ErrorView.swift`,
`sources/Projects/Feature/Settings/Profile/ProfileScreen.swift`,
`sources/Projects/Feature/Settings/Settings/SettingsScreen.swift`,
`sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+AccountDeletionView.swift`,
`sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+CareerLevelSelectionView.swift`,
`sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+PositionSelectionView.swift`

**관련 변경 시나리오**: S1

**통합 검증**: UI와 Feature를 함께 포함하는 `compile` 실행.

### 구현

- [X] T026 [S1] `sources/Projects/UI/Component/Controls/IconGlassButton.swift`에서 정적 팩토리
  3개를 제거하고 `public init(icon:label:style:size:action:)`만 공개 생성 경로로 남긴다
- [X] T027 [S1] `sources/Projects/UI/Component/Controls/ScreenControlBar/ScreenControlBar.swift`의
  `IconGlassButton` 팩토리 호출을 초기화 호출로 전환한다
- [X] T028 [P] [S1] `sources/Projects/UI/Component/CollectionItems/ProjectRow/ProjectRow.swift`의
  `IconGlassButton` 팩토리 호출을 초기화 호출로 전환한다
- [X] T029 [P] [S1] `sources/Projects/UI/Component/Overlays/WebSheet.swift`의
  `IconGlassButton` 팩토리 호출을 초기화 호출로 전환한다
- [X] T030 [P] [S1] `sources/Projects/Feature/ProjectList/ProjectListScreen.swift`의
  `IconGlassButton` 팩토리 호출을 초기화 호출로 전환한다
- [X] T031 [P] [S1] `sources/Projects/Feature/Saved/SavedScreen.swift`의 `IconGlassButton`
  팩토리 호출을 초기화 호출로 전환한다
- [X] T032 [P] [S1] `sources/Projects/Feature/Saved/SubViews/SavedScreen+ErrorView.swift`의
  `IconGlassButton` 팩토리 호출을 초기화 호출로 전환한다
- [X] T033 [P] [S1] `sources/Projects/Feature/Settings/Profile/ProfileScreen.swift`의
  `IconGlassButton` 팩토리 호출을 초기화 호출로 전환한다
- [X] T034 [P] [S1] `sources/Projects/Feature/Settings/Settings/SettingsScreen.swift`의
  `IconGlassButton` 팩토리 호출을 초기화 호출로 전환한다
- [X] T035 [P] [S1] `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+AccountDeletionView.swift`의
  `IconGlassButton` 팩토리 호출을 초기화 호출로 전환한다
- [X] T036 [P] [S1] `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+CareerLevelSelectionView.swift`의
  `IconGlassButton` 팩토리 호출을 초기화 호출로 전환한다
- [X] T037 [P] [S1] `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+PositionSelectionView.swift`의
  `IconGlassButton` 팩토리 호출을 초기화 호출로 전환한다

### 정리와 단위 검증

- [X] T038 [no-write] [quickstart.md](quickstart.md)의 통합 검증 절차로 `compile`을 실행하고
  잔여 팩토리 호출 grep이 0건인지 확인한다

**진행 점검**: T026~T038의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 실행 단위 6: StyledText (integration unit: UI, Feature)

**목표**: `StyledText`의 Typography 팩토리 10개를 제거하고, 호출 168곳을
`StyledText(text:style:color:alignment:)` 초기화와 `TextStyleToken` 인자로 전환한다.

**분리 불가 근거**: `StyledText`는 UI 내부 컴포넌트 30개와 Feature 화면 48개가 함께 쓰는
가장 넓은 공개 표면이다. 팩토리를 제거하면 두 패키지가 동시에 compile되지 않는다.

**소유 경로**: 아래 T039~T056이 명시하는 UI 31개 파일과 Feature 48개 파일.

**관련 변경 시나리오**: S3

**통합 검증**: UI와 Feature를 함께 포함하는 `compile`·`test` 실행과 Typography 팩토리 잔여
호출 grep 0건.

### 구현 — UI 패키지

- [X] T039 [S3] `sources/Projects/UI/Component/Displays/StyledText.swift`에서 Typography 팩토리
  10개(`headline1`, `headline2`, `subtitle1`~`subtitle3`, `body1`~`body3`, `caption1`,
  `caption2`)와 `private static func styled`를 제거하고
  `public init(text:style:color:alignment:)`만 공개 생성 경로로 남긴다
- [X] T040 [S3] `sources/Projects/UI/Component/Displays/ScreenHeaderTitle.swift`,
  `sources/Projects/UI/Component/Displays/RubricView/RubricView.swift`,
  `sources/Projects/UI/Component/Displays/LabeledCard.swift`의 `StyledText` 팩토리 호출을
  초기화 호출로 전환한다
- [X] T041 [P] [S3] `sources/Projects/UI/Component/Controls/AppleSignInButton.swift`,
  `sources/Projects/UI/Component/Controls/Chip/Chip.swift`,
  `sources/Projects/UI/Component/Controls/ChoiceAnswerOption.swift`,
  `sources/Projects/UI/Component/Controls/LabeledTextField/LabeledTextField.swift`,
  `sources/Projects/UI/Component/Controls/PolicyAgreementRow/PolicyAgreementRow.swift`,
  `sources/Projects/UI/Component/Controls/SelectableSettingRow/SelectableSettingRow.swift`,
  `sources/Projects/UI/Component/Controls/TextField.swift`의 `StyledText` 팩토리 호출을
  초기화 호출로 전환한다
- [X] T042 [P] [S3] `sources/Projects/UI/Component/CollectionItems/ChoiceResultRow.swift`,
  `sources/Projects/UI/Component/CollectionItems/LearningSetRow.swift`,
  `sources/Projects/UI/Component/CollectionItems/SettingRow.swift`,
  `sources/Projects/UI/Component/CollectionItems/HomeProjectCard/HomeProjectCard.swift`,
  `sources/Projects/UI/Component/CollectionItems/ProjectRow/ProjectRow.swift`,
  `sources/Projects/UI/Component/CollectionItems/SavedQuestionCard/SavedQuestionCard.swift`,
  `sources/Projects/UI/Component/CollectionItems/SelectionCard/SelectionCard.swift`의
  `StyledText` 팩토리 호출을 초기화 호출로 전환한다
- [X] T043 [P] [S3] `sources/Projects/UI/Component/Overlays/ActionMenu/ActionMenu.swift`,
  `sources/Projects/UI/Component/Overlays/ConfirmationSheet.swift`,
  `sources/Projects/UI/Component/Overlays/ModalOverlay.swift`,
  `sources/Projects/UI/Component/Overlays/PushedScreenOverlay.swift`,
  `sources/Projects/UI/Component/Overlays/SheetSurface/SheetSurface.swift`,
  `sources/Projects/UI/Component/Overlays/WebSheet.swift`의 `StyledText` 팩토리 호출을
  초기화 호출로 전환한다
- [X] T044 [P] [S3] `sources/Projects/UI/Component/Scaffolds/FlowNavigationStack.swift`,
  `sources/Projects/UI/Component/Scaffolds/ScreenContainer.swift`,
  `sources/Projects/UI/Component/Scaffolds/TabShell/TabShell.swift`,
  `sources/Projects/UI/Component/Indicators/LabeledProgressBar.swift`,
  `sources/Projects/UI/Component/Indicators/EmptyState/EmptyState.swift`의 `StyledText`
  팩토리 호출을 초기화 호출로 전환한다. `EmptyState`는 `StyledText`와 팩토리 이름이
  줄바꿈으로 나뉘어 있어 기준선 실측에서 누락됐다
- [X] T045 [P] [S3] `sources/Projects/UI/Tests/Component/Unit/Scaffolds/OverlayContainerContractTests.swift`,
  `sources/Projects/UI/Tests/Component/Unit/Scaffolds/ScreenContainerContractTests.swift`의
  `StyledText` 팩토리 호출을 초기화 호출로 전환한다

### 구현 — Feature 패키지

- [X] T046 [P] [S3] `sources/Projects/Feature/Home/SubViews/HomeScreen+GreetingView.swift`,
  `sources/Projects/Feature/Home/SubViews/HomeScreen+ProfileHeaderView.swift`,
  `sources/Projects/Feature/Home/SubViews/HomeScreen+ProjectSection.swift`,
  `sources/Projects/Feature/Home/SubViews/HomeScreen+RegistrationPanelView.swift`,
  `sources/Projects/Feature/Home/SubViews/HomeScreen+SignInSectionView.swift`의
  `StyledText` 팩토리 호출을 초기화 호출로 전환한다
- [X] T047 [P] [S3] `sources/Projects/Feature/MainShell/Router/SubViews/MainShellRouter+SignInPromptView.swift`의
  `StyledText` 팩토리 호출을 초기화 호출로 전환한다
- [X] T048 [P] [S3] `sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionScreen.swift`,
  `sources/Projects/Feature/Onboarding/LegalAgreement/LegalAgreementScreen.swift`,
  `sources/Projects/Feature/Onboarding/LegalAgreement/SubViews/LegalAgreementScreen+AllAgreementRow.swift`,
  `sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionScreen.swift`,
  `sources/Projects/Feature/Onboarding/Tutorial/SubViews/TutorialScreen+PageView.swift`,
  `sources/Projects/Feature/Onboarding/Tutorial/SubViews/TutorialScreen+SignInSection.swift`의
  `StyledText` 팩토리 호출을 초기화 호출로 전환한다
- [X] T049 [P] [S3] `sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+ErrorView.swift`,
  `sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+RepositorySummaryView.swift`,
  `sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+SetListSection.swift`의
  `StyledText` 팩토리 호출을 초기화 호출로 전환한다
- [X] T050 [P] [S3] `sources/Projects/Feature/ProjectList/SubViews/ProjectListScreen+FailureView.swift`,
  `sources/Projects/Feature/ProjectList/SubViews/ProjectListScreen+NextPageFooter.swift`의
  `StyledText` 팩토리 호출을 초기화 호출로 전환한다
- [X] T051 [P] [S3] `sources/Projects/Feature/ProjectRegistration/QuizGenerationConfirmation/QuizGenerationConfirmationScreen.swift`,
  `sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+ChecklistView.swift`,
  `sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+FailureView.swift`,
  `sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+GeneratingView.swift`,
  `sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+GenerationReminderSheet.swift`,
  `sources/Projects/Feature/ProjectRegistration/QuizLevelSelection/QuizLevelSelectionScreen.swift`,
  `sources/Projects/Feature/ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationScreen.swift`,
  `sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputScreen.swift`,
  `sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/SubViews/RepositoryLinkInputScreen+GuideSectionView.swift`의
  `StyledText` 팩토리 호출을 초기화 호출로 전환한다
- [X] T052 [P] [S3] `sources/Projects/Feature/Quiz/LearningCompletion/LearningCompletionScreen.swift`,
  `sources/Projects/Feature/Quiz/LearningSetIntro/LearningSetIntroScreen.swift`,
  `sources/Projects/Feature/Quiz/LearningSetIntro/SubViews/LearningSetIntroScreen+ErrorView.swift`,
  `sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingScreen.swift`,
  `sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+AnswerEditor.swift`,
  `sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+QuestionPrompt.swift`,
  `sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+SourceSheet.swift`의
  `StyledText` 팩토리 호출을 초기화 호출로 전환한다
- [X] T053 [P] [S3] `sources/Projects/Feature/Saved/SubViews/SavedScreen+ErrorView.swift`,
  `sources/Projects/Feature/Saved/SubViews/SavedScreen+FilterSection.swift`의 `StyledText`
  팩토리 호출을 초기화 호출로 전환한다
- [X] T054 [P] [S3] `sources/Projects/Feature/Settings/Profile/ProfileScreen.swift`,
  `sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+LoadFailureView.swift`,
  `sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+ProfileHeaderView.swift`,
  `sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+StatisticsCardView.swift`,
  `sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+WeeklyChartView.swift`의
  `StyledText` 팩토리 호출을 초기화 호출로 전환한다
- [X] T055 [P] [S3] `sources/Projects/Feature/Settings/Settings/SettingsScreen.swift`,
  `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+AccountDeletionView.swift`,
  `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+CareerLevelSelectionView.swift`,
  `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+PositionSelectionView.swift`,
  `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+SectionView.swift`,
  `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+SettingRowContent.swift`의
  `StyledText` 팩토리 호출을 초기화 호출로 전환한다
- [X] T056 [P] [S3] `sources/Projects/Feature/ShareRegistration/SubViews/ShareRegistrationScreen+GuidanceView.swift`,
  `sources/Projects/Feature/ShareRegistration/SubViews/ShareRegistrationScreen+LoadingView.swift`의
  `StyledText` 팩토리 호출을 초기화 호출로 전환한다

### 정리와 단위 검증

- [X] T057 [no-write] [quickstart.md](quickstart.md)의 통합 검증 절차로 `compile`과 `test`를
  실행하고 `StyledText.` Typography 팩토리 잔여 호출 grep이 0건인지 확인한다

**진행 점검**: T039~T057의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 실행 단위 7: 생성 경로 컨벤션 개정 (단일 패키지: UI)

**목표**: 초기화 메서드 하나만 공개 생성 경로로 규정하도록 컨벤션 문서 6건을 개정하고
1건을 삭제한다(FR-004a, FR-004b, FR-004b-1~FR-004b-3, FR-004d).

**소유 경로**: `docs/conventions/view/component-init.md`,
`docs/conventions/view/factory-criteria.md`(삭제), `docs/conventions/view/screen-init.md`,
`docs/conventions/view.md`, `docs/conventions/view-tokens.md`,
`docs/conventions/view-tokens/typography.md`, `docs/conventions/view-declarations/style.md`

**관련 변경 시나리오**: S4

**책임 배정 근거**: 이 문서들은 패키지에 속하지 않는 공용 문서이지만, 규정 대상이 UI
패키지의 컴포넌트 공개 생성 경로이므로 UI를 책임 패키지로 배정한다. 문서 루트는
`./tools/repository-paths/bin/repository-paths.sh GIT_IT_DOCS_ROOT`로 확인한다.

**독립 검증**: 개정 후 남은 6개 파일에 팩토리 정의를 요구하거나 전제하는 문장이 없고,
삭제한 문서를 가리키는 링크가 저장소에 없는지 grep으로 확인한다(FR-004b, FR-004b-2).
`view.md` §3 제목과 앵커는 유지하고(FR-004b-1) §3.4·§3.5는 재번호하지 않는다(FR-004b-3).

### 구현

- [X] T058 [S4] `docs/conventions/view/component-init.md`의 제목을 "컴포넌트의 공개 생성
  경로는 두 가지입니다"에서 단일 경로를 뜻하는 제목으로 바꾸고, "공개하는 생성 경로는 다음
  둘뿐" 규정과 정적 팩토리 항목을 제거해 초기화 메서드 하나만 공개 생성 경로로 규정한다.
  `ActionButton.primary(...)` 예시도 초기화 호출 예시로 교체한다
- [X] T059 [S4] `docs/conventions/view/component-init.md`에 삭제 대상 문서의 팩토리 무관
  규칙 두 건을 옮긴다. (1) `@ViewBuilder`로 자식 View를 받는 컴포넌트는
  `init(..., content:)`를 생성 경로로 둔다, (2) 필요한 기본값은 해당 초기화 인자에 둔다.
  원문의 "§3.1에 따라"는 문서를 옮기면 가리키는 대상이 사라지므로
  `docs/conventions/view.md` §3.1(표시 값, Binding과 콜백) 링크로 풀어서 옮긴다
- [X] T060 [S4] **사용자 승인 완료(2026-09-20)** — `docs/conventions/view/factory-criteria.md`
  파일을 삭제한다. 문서 전문이 팩토리 정의 기준이며 보존할 규칙은 T059가 이미 옮긴 뒤여야
  한다. Constitution 원칙 5는 `/speckit-implement`에 파일 수정 권한만 부여하고 삭제를 명시하지
  않으므로 승인이 필요했고, 사용자가 이 세션에서 삭제를 승인했다. 구현 시 다시 중단하지 않고
  진행하되 PR에 원칙 3 예외로 기록한다
- [X] T061 [S4] `docs/conventions/view.md`에서 §3.2의 제목과 링크 텍스트
  "컴포넌트의 공개 생성 경로는 두 가지입니다"를 T058의 새 제목에 맞추고, §3.3
  "팩토리를 정의하는 기준" 절과 `./view/factory-criteria.md` 링크를 삭제하며, §6 검토
  체크리스트의 팩토리 전제 항목 2개를 정리한다. 두 가지를 바꾸지 않는다. (1) §3 제목
  "공개 생성 경로"와 앵커 `#3-공개-생성-경로` — `docs/package-rules/ui.md:49`,
  `docs/conventions/ui-component.md:83`,
  `docs/conventions/ui-component/public-contract.md:7` 세 곳이 참조한다(FR-004b-1).
  (2) §3.4·§3.5의 절 번호 — `docs/retrospective/31-quiz-solving-flow.md`가 §3.5를 인용하므로
  재번호하지 않고 번호 공백을 남긴다(FR-004b-3)
- [X] T062 [P] [S4] `docs/conventions/view-tokens/typography.md`의 "`StyledText`의
  Typography 팩토리를 사용합니다" 규정을 `StyledText` 초기화에 `TextStyleToken`을 넘기는
  규정으로 고친다
- [X] T063 [P] [S4] `docs/conventions/view-tokens.md` §2.4 본문과 §3 검토 체크리스트의
  "`StyledText` Typography 팩토리" 문구를 초기화 기준으로 고친다
- [X] T064 [P] [S4] `docs/conventions/view-declarations/style.md`의 "호출부는 시각 변형
  팩토리를 기본 선택 수단으로 사용합니다" 문장을 초기화 인자 기준으로 고친다
- [X] T065 [P] [S4] `docs/conventions/view/screen-init.md`에서 컴포넌트 팩토리를 전제하는
  문구를 정리한다(FR-004d)

### 정리와 단위 검증

- [X] T066 [no-write] [quickstart.md](quickstart.md)의 컨벤션 검증 절차로 남은 6개 파일에
  팩토리 정의를 요구·전제하는 문장이 없고(FR-004b, 금지 서술은 허용), `factory-criteria.md`를 가리키는 링크가
  남지 않았으며(FR-004b-2), `view.md#3-공개-생성-경로` 앵커를 참조하는 세 문서
  (`docs/package-rules/ui.md`, `docs/conventions/ui-component.md`,
  `docs/conventions/ui-component/public-contract.md`)의 링크가 모두 살아 있고(FR-004b-1),
  `view.md` §3.4·§3.5 번호가 그대로인지(FR-004b-3) grep으로 확인한다

**진행 점검**: T058~T066의 변경 파일과 검증 결과를 보고하고 전체 완료 검증으로 진행한다.

---

## 전체 완료 검증

**선행 조건**: 실행 단위 7의 파일 변경 작업(T058~T065)을 완료하고, 전체 검증과 hook 결과를 포함할
마지막 커밋 단위를 아직 commit하지 않은 상태여야 한다.

**커밋 경계**: 아래 `[no-write]` 작업은 실행 단위 7의 마지막 커밋 단위에 배정한다. 모든
검증과 필수 `after_implement` hook을 마친 뒤 그 단위를 최종 commit한다.

- [X] T067 [no-write] `project_build_runner`의 `build`·`compile`·`test`를 순서대로 실행하고
  결과를 기록한다(FR-008)
- [X] T068 [no-write] 제거 대상 팩토리 30개의 호출과 정의가 저장소에 남지 않았는지
  [contracts/component-creation-api.md](contracts/component-creation-api.md)의 검증 표대로
  확인한다
- [X] T069 [no-write] `TabShellItem.tabColor(isSelected:)`와 `ResourceImage.resizable` 등
  생성 팩토리가 아닌 정적 선언이 변경되지 않았는지 확인한다(FR-009)
- [X] T070 [no-write] 시나리오 S1~S4의 독립 수용 기준과 SC-001~SC-007을 [spec.md](spec.md)
  기준으로 검증한다. SC-006a는 남은 `팩토리` 언급이 금지 서술뿐인지와 `component-init.md`의
  단수 규정·초기화 예시 두 조건으로 판정한다

## 의존성과 실행 순서

### 실행 단위 순서와 위험 기반 승인

- [docs/architecture.md](../../docs/architecture.md)의 의존 방향에서 UI는 Feature의 피의존
  패키지다. 따라서 UI 안에서 닫히는 단위(1, 2)를 먼저 두고, UI 공개 API 제거가 Feature
  호출부를 동시에 깨뜨리는 integration unit(3, 4, 5, 6)을 영향 범위가 작은 순서로 잇는다.
- integration unit 사이의 순서는 호출부 수(TagBadge 11 → LabeledCard 10 → IconGlassButton 20
  → StyledText 168)로 정하고, 구현이 끝날 때까지 바꾸지 않는다.
- 컨벤션 개정(단위 7)은 코드 전환이 모두 끝난 뒤 수행한다. FR-004c가 요구하는 범위는
  브랜치 수준이며, FR-010의 컴포넌트 단위 커밋과 양립하도록 단위 7을 같은 브랜치의 마지막
  커밋에 둔다. 브랜치 내부의 일시적 문서·코드 불일치는 명세가 허용한다.
- 단위 간에는 같은 파일을 공유하는 경로가 있어 병렬 실행하지 않는다:
  `OverlayContainer.swift`(단위 1·4), `ProjectRow.swift`(단위 3·5·6),
  `LabeledCard.swift`(단위 4·6), `ConfirmationSheet.swift`·`SheetSurface.swift`(단위 1·6),
  `SelectionCard.swift`(단위 3·6), `WebSheet.swift`(단위 5·6),
  `SettingsScreen+*.swift`·`ProfileScreen*.swift`·`SavedScreen+ErrorView.swift`(단위 5·6).
- 새 범위, 파괴적 작업, 외부 상태 변경 또는 새 제품 결정이 필요할 때만 중단하고 명시적
  승인을 요청한다. 해당 경계는 **T060 하나**였고 2026-09-20 세션에서 사용자 승인을 받았다.
  따라서 단위 1~7 전체를 중단 없이 연속 진행하며, 삭제 사실은 PR에 원칙 3 예외로 기록한다.

### 변경 시나리오 추적성

- S1(단일 변형 축 컴포넌트): T001~T007, T013~T017, T019~T024, T026~T037
- S2(ScreenEdgeScrim): T009~T011
- S3(StyledText): T039~T056
- S4(컨벤션 개정): T058~T065
- 각 시나리오의 독립 수용 기준은 관련 단위가 모두 완료된 뒤 T069에서 검증한다.

### 실행 단위 내부 실행

- 새 테스트는 만들지 않는다. 기존 계약 테스트의 호출부 전환은 같은 단위의 구현 작업이다.
- `[P]`는 현재 실행 단위 안의 서로 다른 파일에만 사용한다. 각 단위에서 공개 표면을 바꾸는
  첫 작업(T001, T009·T010, T013, T019·T020, T026, T039)은 `[P]`가 아니며 먼저 수행한다.
- `/speckit-implement`는 파일을 수정하기 전에 현재 단위의 미완료 작업을 하나의 목적과
  독립적인 rollback 경계를 갖는 순서화된 커밋 단위로 묶는다.
- 각 커밋 단위는 포함 작업 ID, 정확한 파일 경로, 검증과 커밋 메시지를 먼저 제시한다.
- 실행 단위 7의 마지막 단위는 전체 완료 검증과 필수 `after_implement` hook이 끝날 때까지
  commit하지 않는다.

## 구현 전략

1. tasks.md의 blob hash와 전체 diff를 기준선으로 고정한다.
2. 첫 미완료 실행 단위를 선택하고 그 미완료 작업을 논리적 커밋 단위로 설계한다.
3. 각 단위의 구현·검증·완료 표시·커밋을 순서대로 완료한다.
4. 단위가 커밋되면 변경 파일, 검증 결과와 커밋을 보고하고 다음 단위로 이어간다.
5. 단위 7에서 전체 읽기 전용 검증과 시나리오 수용 검증, 필수 `after_implement` hook을
   실행하고 결과를 재검증한 뒤 마지막 단위를 최종 commit한다.
