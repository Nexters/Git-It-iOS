---

description: "UI 컴포넌트 초기화 계약 재구성 작업 목록"
---

# 작업 목록: UI 컴포넌트 초기화 계약 재구성 — 시각 속성 메서드와 표시 값 모델

**입력**: `specs/042-component-attribute-modifiers/`의 설계 문서

**선행 조건**: plan.md, spec.md, research.md, data-model.md, contracts/component-init-contracts.md, quickstart.md

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를
snapshot한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만
선택한다.

**테스트**: 명세 SC-007이 시각 속성 계약별 단위 테스트를 요구한다. 그래서 계약 테스트 작업을 둔다.
기존 테스트는 초기화 인자가 바뀐 호출부만 전환하고 단언(토큰 대응, 상태 비보관)은 유지한다.

**구성**: 실행 단위를 최상위 구조로 사용하고 변경 시나리오는 각 단위 안에서 `[S1]`~`[S4]`로
추적한다. UI 공개 초기화 메서드 변경은 Feature 호출부와 함께 바꿔야 compile되므로 대부분의 단위는
UI+Feature integration unit이다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[시나리오]**: S1 시각 속성 Self 반환 메서드, S2 속성 종류별 공통 계약, S3 호출부 전환과
  문서 개정, S4 표시 값 모델
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 실행 또는 수동
  검증. `make tuist`의 파생 workspace·project·심볼릭 링크·cache 갱신은 허용하되 실행 전후
  `git status --porcelain`을 비교하고 추적 파일 변경이 생기면 완료로 처리하지 않는다.
- 경로는 저장소 루트 기준이다. 공개 이름과 시그니처는
  [contracts/component-init-contracts.md](./contracts/component-init-contracts.md)가 정본이다.

## 공통 전환 규칙(모든 호출부 전환 작업에 적용)

- **시각 속성 인자 → 메서드**: 초기화 인자 뒤에, 그리고 SwiftUI 일반 수정자보다 앞에 붙인다.
  - `style:` → `.style(_)`
  - `size:` → `.size(_)`
  - `height:` → `.size(_)`
  - `StyledText`의 `style:` → `.textStyle(_)`
  - `color:`·`tintColor:`·`valueColor:` → `.foregroundColorToken(_)`
  - `backgroundColor:`·`background:`·`screenBackground:` → `.backgroundColorToken(_)`
  - trailing closure가 있는 호출은 closure 뒤에 붙인다.
- **기본값 생략**: 전환 뒤 기본값([data-model.md](./data-model.md) §2)과 같은 값이면 메서드를
  생략한다(FR-009).
  - 새 기본값: `StyledText` `.body1`, `LabeledCard` `.neutral`, `HomeProjectCard` `.purple`
  - 기존 기본값: `.grey100`, `.primary`, `.large`, `.neutral`, `.regular`, `.small`, `.row`, `.white`,
    `.clear`, `.grey400`, `.detailed`, `.grey700`
- **`StyledText` 정렬**: `alignment: .center`는 `.multilineTextAlignment(.center)`로 옮긴다. T010
  조사 결과에 오른 호출부에는 `.multilineTextAlignment(.leading)`을 붙인다.
- **표시 값 → 모델**: 표시 값 인자를 `displayModel: .init(...)` 하나로 옮긴다. 필드 순서는
  계약 문서 §3을 따른다. 상태·동작 설정·`accessibilityLabel`·`Binding`·콜백·자식 View 인자는
  원래 이름으로 뒤에 남긴다.
- **Feature 매핑 위치**: Feature에서는 View(화면·SubViews·Previews)의 호출 지점에서 모델을
  만든다. State·Reducer·`ViewModels/` 타입에 `DisplayModel`을 추가하지 않는다(SC-008).
- **값 보존**: 전환 전후 각 호출부가 그리는 값이 같아야 한다(FR-009·FR-013). 계산식으로 넘기던
  값은 같은 식을 메서드 인자로 옮긴다.

## 실행 단위 소유권 규칙

- UI 패키지(`sources/Projects/UI/**`) 파일은 UI가, Feature 패키지(`sources/Projects/Feature/**`)
  파일은 Feature가 소유한다. 두 패키지를 함께 바꾸는 단위는 integration unit으로 표시한다.
- App·Composition은 `UIComponent`를 쓰지 않아 변경하지 않는다([research.md](./research.md) §1.1).
- 문서(`docs/**`, `.agents/skills/implement-figma-ui/references/component-index.md`)는 규칙을
  정한 패키지(UI·Feature)의 문서 실행 단위(U9)가 소유한다.
- `docs/spec-kit/<feature>/trouble-shooting.md`와 `tacit-knowledge.md`는 작업으로 만들지 않는다.

---

## 실행 단위 1: 계약 도입과 `StyledText` 전환 (integration unit: UI, Feature)

**목표**: 시각 속성 계약 5개를 도입한다. `StyledText`가 텍스트 스타일·전경색을 메서드로
선언하게 하고, 정렬을 SwiftUI 수정자로 옮긴다.

**분리 불가 근거**: `StyledText`의 `style:` 인자는 기본값이 없는 필수 인자다. 이를 제거하면 UI
컴포넌트 28개·UI 테스트 3개·Feature 48개 파일의 호출부가 함께 바뀌어야 compile된다.

**소유 경로**: `sources/Projects/UI/Component/Contracts/`의 5개 파일,
`sources/Projects/UI/Component/Displays/StyledText.swift`, 아래 작업에 적은 UI·Feature 호출부 파일,
`sources/Projects/UI/Tests/Component/Unit/Contracts/`의 2개 테스트 파일

**관련 변경 시나리오**: S1, S2

**통합 검증**: `compile`·`test` 통과, [quickstart.md](./quickstart.md) §2.1의 `StyledText` 패턴 0줄,
§3 정렬 대조

### 준비와 기반

- [X] T001 [no-write] 전환 전 기준선을 기록한다(SC-003 "전환 전후").
  - 파일을 수정하기 전에 `"$project_build_runner" build`, `"$project_build_runner" compile`, `"$project_build_runner" test`를 순차 실행한다.
  - 결과(통과·실패와 실패 테스트 이름)를 단위 보고에 남긴다.
  - 기준선에서 이미 실패하는 항목이 있으면 이 기능과 무관한 기존 실패로 분리해 기록한다. 이후 단위 검증에서는 새 실패만 전환 결과로 판정한다.
- [X] T002 [S2] `sources/Projects/UI/Component/Contracts/StyleConfigurable.swift`에 `public protocol StyleConfigurable: View { associatedtype Style; func style(_ style: Style) -> Self }`를 만든다
- [X] T003 [P] [S2] `sources/Projects/UI/Component/Contracts/SizeConfigurable.swift`에 `public protocol SizeConfigurable: View { associatedtype Size; func size(_ size: Size) -> Self }`를 만든다
- [X] T004 [P] [S2] `sources/Projects/UI/Component/Contracts/TextStyleConfigurable.swift`에 `public protocol TextStyleConfigurable: View { func textStyle(_ textStyle: TextStyleToken) -> Self }`를 만든다(`import DesignSystem`)
- [X] T005 [P] [S2] `sources/Projects/UI/Component/Contracts/ForegroundColorConfigurable.swift`에 `public protocol ForegroundColorConfigurable: View { func foregroundColorToken(_ color: ColorToken) -> Self }`를 만든다(`import DesignSystem`)
- [X] T006 [P] [S2] `sources/Projects/UI/Component/Contracts/BackgroundColorConfigurable.swift`에 `public protocol BackgroundColorConfigurable: View { func backgroundColorToken(_ color: ColorToken) -> Self }`를 만든다(`import DesignSystem`)

### 테스트

- [X] T007 [P] [S2] `sources/Projects/UI/Tests/Component/Unit/Contracts/TextStyleConfigurableTests.swift`에 `@Suite("TextStyleConfigurable 계약")`을 만들고 `StyledText`에 대해 네 가지를 검증한다. `Mirror`로 저장 프로퍼티 `textStyle`·`foregroundColor`·`text`를 읽는다.
  - 호출하지 않으면 `.body1`이다.
  - `textStyle(_:)`은 텍스트 스타일만 바꾸고 `text`·전경색을 유지한다.
  - 두 번 선언하면 마지막 값이 남는다.
  - `foregroundColorToken(_:)`과 호출 순서를 바꿔도 결과가 같다.
- [X] T008 [P] [S2] `sources/Projects/UI/Tests/Component/Unit/Contracts/ForegroundColorConfigurableTests.swift`에 `@Suite("ForegroundColorConfigurable 계약")`을 만들고 `StyledText`에 대해 세 가지를 검증한다.
  - 호출하지 않으면 `.grey100`이다.
  - `foregroundColorToken(_:)`은 전경색만 바꾸고 `text`·텍스트 스타일을 유지한다.
  - 두 번 선언하면 마지막 값이 남는다.

### 구현

- [X] T009 [S1] `sources/Projects/UI/Component/Displays/StyledText.swift`를 전환한다.
  - 초기화 메서드를 `init(text:)`로 바꾼다.
  - `private var textStyle: TextStyleToken = .body1`, `private var foregroundColor: ColorToken = .grey100`을 둔다.
  - `alignment` 저장 프로퍼티와 `.multilineTextAlignment(alignment)`를 제거한다.
  - `TextStyleConfigurable`·`ForegroundColorConfigurable`을 채택하고 두 메서드를 값 복사로 구현한다.
  - `public let text`만 공개로 남기고 `Sendable`·`Equatable`을 유지한다.
  - 파일 하단 `#Preview`를 새 방식으로 바꾼다.
- [X] T010 [no-write] [S1] 정렬 인자 없이 호출하던 `StyledText` 호출부 중, 상위 View에 `.multilineTextAlignment`가 걸린 곳을 T011~T026 대상 파일에서 조회한다.
  - 조회 명령: `rg -n 'multilineTextAlignment' sources/Projects/UI/Component sources/Projects/Feature`로 찾은 컨테이너 안의 `StyledText(`를 확인한다.
  - 결과 목록(파일:줄)을 단위 보고에 남긴다. 해당 호출부는 T011~T026에서 `.multilineTextAlignment(.leading)`을 붙인다([research.md](./research.md) §4.2).
- [X] T011 [P] [S1] UI CollectionItems의 `StyledText` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/UI/Component/CollectionItems/ChoiceResultRow.swift`
  - `sources/Projects/UI/Component/CollectionItems/HomeProjectCard/HomeProjectCard.swift`
  - `sources/Projects/UI/Component/CollectionItems/LearningSetRow.swift`
  - `sources/Projects/UI/Component/CollectionItems/ProjectRow/ProjectRow.swift`
  - `sources/Projects/UI/Component/CollectionItems/SavedQuestionCard/SavedQuestionCard.swift`
  - `sources/Projects/UI/Component/CollectionItems/SelectionCard/SelectionCard.swift`
  - `sources/Projects/UI/Component/CollectionItems/SettingRow.swift`
- [X] T012 [P] [S1] UI Controls의 `StyledText` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/UI/Component/Controls/AppleSignInButton.swift`
  - `sources/Projects/UI/Component/Controls/Chip/Chip.swift`
  - `sources/Projects/UI/Component/Controls/ChoiceAnswerOption.swift`
  - `sources/Projects/UI/Component/Controls/LabeledTextField/LabeledTextField.swift`
  - `sources/Projects/UI/Component/Controls/PolicyAgreementRow/PolicyAgreementRow.swift`
  - `sources/Projects/UI/Component/Controls/SelectableSettingRow/SelectableSettingRow.swift`
  - `sources/Projects/UI/Component/Controls/TextField.swift`
- [X] T013 [P] [S1] UI Displays·Indicators의 `StyledText` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/UI/Component/Displays/LabeledCard.swift`
  - `sources/Projects/UI/Component/Displays/RubricView/RubricView.swift`
  - `sources/Projects/UI/Component/Displays/ScreenHeaderTitle.swift`
  - `sources/Projects/UI/Component/Indicators/EmptyState/EmptyState.swift`
  - `sources/Projects/UI/Component/Indicators/LabeledProgressBar.swift`
- [X] T014 [P] [S1] UI Overlays·Scaffolds의 `StyledText` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/UI/Component/Overlays/ActionMenu/ActionMenu.swift`
  - `sources/Projects/UI/Component/Overlays/ConfirmationSheet.swift`
  - `sources/Projects/UI/Component/Overlays/ModalOverlay.swift`
  - `sources/Projects/UI/Component/Overlays/PushedScreenOverlay.swift`
  - `sources/Projects/UI/Component/Overlays/SheetSurface/SheetSurface.swift`
  - `sources/Projects/UI/Component/Overlays/WebSheet.swift`
  - `sources/Projects/UI/Component/Scaffolds/FlowNavigationStack.swift`
  - `sources/Projects/UI/Component/Scaffolds/ScreenContainer.swift`
  - `sources/Projects/UI/Component/Scaffolds/TabShell/TabShell.swift`
- [X] T015 [P] [S1] UI 테스트의 `StyledText` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/UI/Tests/Component/Unit/Controls/ActionButtonSizeContractTests.swift`
  - `sources/Projects/UI/Tests/Component/Unit/Scaffolds/OverlayContainerContractTests.swift`
  - `sources/Projects/UI/Tests/Component/Unit/Scaffolds/ScreenContainerContractTests.swift`
- [X] T016 [P] [S1] Feature Home의 `StyledText` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/Home/SubViews/HomeScreen+GreetingView.swift`
  - `sources/Projects/Feature/Home/SubViews/HomeScreen+ProfileHeaderView.swift`
  - `sources/Projects/Feature/Home/SubViews/HomeScreen+ProjectSection.swift`
  - `sources/Projects/Feature/Home/SubViews/HomeScreen+RegistrationPanelView.swift`
  - `sources/Projects/Feature/Home/SubViews/HomeScreen+SignInSectionView.swift`
- [X] T017 [P] [S1] Feature MainShell의 `StyledText` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/MainShell/Router/SubViews/MainShellRouter+SignInPromptView.swift`
- [X] T018 [P] [S1] Feature Onboarding의 `StyledText` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionScreen.swift`
  - `sources/Projects/Feature/Onboarding/LegalAgreement/LegalAgreementScreen.swift`
  - `sources/Projects/Feature/Onboarding/LegalAgreement/SubViews/LegalAgreementScreen+AllAgreementRow.swift`
  - `sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionScreen.swift`
  - `sources/Projects/Feature/Onboarding/Tutorial/SubViews/TutorialScreen+PageView.swift`
  - `sources/Projects/Feature/Onboarding/Tutorial/SubViews/TutorialScreen+SignInSection.swift`
- [X] T019 [P] [S1] Feature ProjectDetail의 `StyledText` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+ErrorView.swift`
  - `sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+RepositorySummaryView.swift`
  - `sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+SetListSection.swift`
- [X] T020 [P] [S1] Feature ProjectList의 `StyledText` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/ProjectList/SubViews/ProjectListScreen+FailureView.swift`
  - `sources/Projects/Feature/ProjectList/SubViews/ProjectListScreen+NextPageFooter.swift`
- [X] T021 [P] [S1] Feature ProjectRegistration의 `StyledText` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/ProjectRegistration/QuizGenerationConfirmation/QuizGenerationConfirmationScreen.swift`
  - `sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+ChecklistView.swift`
  - `sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+FailureView.swift`
  - `sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+GeneratingView.swift`
  - `sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+GenerationReminderSheet.swift`
  - `sources/Projects/Feature/ProjectRegistration/QuizLevelSelection/QuizLevelSelectionScreen.swift`
  - `sources/Projects/Feature/ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationScreen.swift`
  - `sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputScreen.swift`
  - `sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/SubViews/RepositoryLinkInputScreen+GuideSectionView.swift`
- [X] T022 [P] [S1] Feature Quiz의 `StyledText` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/Quiz/LearningCompletion/LearningCompletionScreen.swift`
  - `sources/Projects/Feature/Quiz/LearningSetIntro/LearningSetIntroScreen.swift`
  - `sources/Projects/Feature/Quiz/LearningSetIntro/SubViews/LearningSetIntroScreen+ErrorView.swift`
  - `sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingScreen.swift`
  - `sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+AnswerEditor.swift`
  - `sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+QuestionPrompt.swift`
  - `sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+SourceSheet.swift`
- [X] T023 [P] [S1] Feature Saved의 `StyledText` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/Saved/SubViews/SavedScreen+ErrorView.swift`
  - `sources/Projects/Feature/Saved/SubViews/SavedScreen+FilterSection.swift`
- [X] T024 [P] [S1] Feature Settings Profile의 `StyledText` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/Settings/Profile/ProfileScreen.swift`
  - `sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+LoadFailureView.swift`
  - `sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+ProfileHeaderView.swift`
  - `sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+StatisticsCardView.swift`
  - `sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+WeeklyChartView.swift`
- [X] T025 [P] [S1] Feature Settings Settings의 `StyledText` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/Settings/Settings/SettingsScreen.swift`
  - `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+AccountDeletionView.swift`
  - `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+CareerLevelSelectionView.swift`
  - `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+PositionSelectionView.swift`
  - `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+SectionView.swift`
  - `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+SettingRowContent.swift`
- [X] T026 [P] [S1] Feature ShareRegistration의 `StyledText` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/ShareRegistration/SubViews/ShareRegistrationScreen+GuidanceView.swift`
  - `sources/Projects/Feature/ShareRegistration/SubViews/ShareRegistrationScreen+LoadingView.swift`

### 정리와 단위 검증

- [X] T027 [no-write] [S1] `"$project_build_runner" compile`과 `"$project_build_runner" test`를 순차 실행한다. `StyledText(` 초기화 인자 안에 `style:`·`color:`·`alignment:`가 0곳인지 확인한다. 괄호 균형 검색을 쓰므로 여러 줄 호출도 잡고, 다른 컴포넌트의 인자는 잡지 않는다: `rg -U --pcre2 -c 'StyledText\((?:[^()]|\((?:[^()]|\([^()]*\))*\))*?\b(style|color|alignment):' sources/Projects --glob '*.swift'`(전환 전 기준선 170곳, 기대값 0곳).
- [X] T028 [no-write] [S1] [quickstart.md](./quickstart.md) §3 대조를 수행한다.
  - `alignment: .center` 55곳이 `.multilineTextAlignment(.center)`로 옮겨졌는지 확인한다.
  - T010 목록의 `.leading` 보존을 확인한다.
  - 전경색 `.grey100`·텍스트 스타일 `.body1` 명시가 생략되고 다른 값은 보존됐는지 diff로 확인한다.
  - `StyledText`와 `HomeScreen`·`ProfileScreen` 프리뷰에서 전환 전과 같은 렌더링인지 확인한다.

**진행 점검**: T001~T028의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행
단위로 진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을 요청한다.

---

## 실행 단위 2: 스타일·크기 컴포넌트 (integration unit: UI, Feature)

**목표**: `ActionButton`, `TagBadge`, `IconGlassButton`, `ContinuousProgressBar`의 스타일·크기를
메서드로 선언하게 한다. Feature 래퍼 `FeedbackActionButton`도 같은 계약을 채택한다.

**분리 불가 근거**: UI 초기화 메서드에서 `style:`·`size:`·`height:`를 제거하면 Feature의
`FeedbackActionButton`과 그 호출부, `TagBadge`·`IconGlassButton` 호출부가 compile되지 않는다.

**소유 경로**: 아래 작업에 적은 UI·Feature 파일과
`sources/Projects/UI/Tests/Component/Unit/Contracts/{StyleConfigurableTests,SizeConfigurableTests}.swift`

**관련 변경 시나리오**: S1, S2

**통합 검증**: `compile`·`test` 통과, [quickstart.md](./quickstart.md) §2.1의 해당 패턴 0줄

### 테스트

- [ ] T029 [P] [S2] `sources/Projects/UI/Tests/Component/Unit/Contracts/StyleConfigurableTests.swift`에 `@Suite("StyleConfigurable 계약")`을 만든다. `ActionButton`·`TagBadge`·`IconGlassButton`에 대해 세 가지를 `Mirror`로 검증한다.
  - 기본 스타일(`.primary`·`.neutral`·`.neutral`)
  - `style(_:)`이 스타일만 바꾸고 표시 값·크기를 유지함
  - 마지막 선언 우선
- [ ] T030 [P] [S2] `sources/Projects/UI/Tests/Component/Unit/Contracts/SizeConfigurableTests.swift`에 `@Suite("SizeConfigurable 계약")`을 만든다. `ActionButton`·`TagBadge`·`IconGlassButton`·`ContinuousProgressBar`에 대해 세 가지를 검증한다.
  - 기본 크기(`.large`·`.regular`·`.small`·`.row`)
  - `size(_:)`가 크기만 바꾸고 스타일·표시 값을 유지함
  - `style(_:)`과 호출 순서를 바꿔도 결과가 같음

### 구현

- [ ] T031 [S1] `sources/Projects/UI/Component/Controls/ActionButton.swift`를 전환한다.
  - 두 초기화 메서드를 `init(title:isEnabled:action:)`·`init(styledText:isEnabled:action:)`로 바꾼다.
  - `private var style: Style = .primary`, `private var size: Size = .large`를 둔다.
  - `StyleConfigurable`·`SizeConfigurable`을 채택해 `style(_:)`·`size(_:)`를 구현한다.
  - `#Preview`를 전환한다.
- [ ] T032 [P] [S1] `sources/Projects/UI/Component/Displays/TagBadge.swift`를 전환한다.
  - 초기화 메서드를 `init(text:)`로 바꾼다.
  - `private var style: Style = .neutral`, `private var size: Size = .regular`를 둔다.
  - 두 계약을 채택하고 `#Preview`를 전환한다.
- [ ] T033 [P] [S1] `sources/Projects/UI/Component/Controls/IconGlassButton.swift`를 전환한다.
  - 초기화 메서드를 `init(icon:label:action:)`로 바꾼다.
  - `private var style: Style = .neutral`, `private var size: Size = .small`을 둔다.
  - 두 계약을 채택하고 `#Preview`를 전환한다.
- [ ] T034 [P] [S1] `sources/Projects/UI/Component/Indicators/ContinuousProgressBar.swift`를 전환한다.
  - 초기화 메서드를 `init(progress:)`로 바꾼다.
  - 비공개 저장 프로퍼티 `height`를 `private var size: Height = .row`로 바꾼다.
  - `SizeConfigurable`을 채택해 `size(_ size: Height) -> Self`를 구현하고 `#Preview`를 전환한다.
- [ ] T035 [S1] `sources/Projects/Feature/Shared/Views/FeedbackActionButton.swift`를 전환한다.
  - 두 초기화 메서드에서 `style`·`size`를 제거한다.
  - `private var style: ActionButton.Style = .primary`, `private var size: ActionButton.Size = .large`를 둔다.
  - `StyleConfigurable`·`SizeConfigurable`을 채택한다.
  - `body`의 안쪽 `ActionButton`에 `.style(style).size(size)`로 전달한다([research.md](./research.md) §4.4).
- [ ] T036 [P] [S1] UI 컴포넌트 내부 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/UI/Component/Overlays/ConfirmationSheet.swift`: `ActionButton` ×2
  - `sources/Projects/UI/Component/CollectionItems/ProjectRow/ProjectRow.swift`: `TagBadge`, `IconGlassButton`
  - `sources/Projects/UI/Component/CollectionItems/SelectionCard/SelectionCard.swift`: `TagBadge`
  - `sources/Projects/UI/Component/Controls/ScreenControlBar/ScreenControlBar.swift`: `IconGlassButton` ×2
  - `sources/Projects/UI/Component/Indicators/LabeledProgressBar.swift`: `ContinuousProgressBar` `.detail` → `.size(.detail)`
- [ ] T037 [P] [S1] UI 테스트 호출부를 공통 전환 규칙으로 바꾼다. 기존 단언은 유지한다.
  - `sources/Projects/UI/Tests/Component/Unit/Controls/ActionButtonSizeContractTests.swift`
  - `sources/Projects/UI/Tests/Component/Unit/Displays/TagBadgeContractTests.swift`
- [ ] T038 [P] [S1] Feature Home·Onboarding의 `FeedbackActionButton` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/Home/SubViews/HomeScreen+ProfileHeaderView.swift`
  - `sources/Projects/Feature/Home/SubViews/HomeScreen+ProjectSection.swift`
  - `sources/Projects/Feature/Home/SubViews/HomeScreen+SignInSectionView.swift`
  - `sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionScreen.swift`
  - `sources/Projects/Feature/Onboarding/LegalAgreement/LegalAgreementScreen.swift`
  - `sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionScreen.swift`
  - `sources/Projects/Feature/Onboarding/Tutorial/SubViews/TutorialScreen+SignInSection.swift`
- [ ] T039 [P] [S1] Feature ProjectDetail·ProjectList·ProjectRegistration의 `FeedbackActionButton` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+ErrorView.swift`
  - `sources/Projects/Feature/ProjectList/SubViews/ProjectListScreen+FailureView.swift`
  - `sources/Projects/Feature/ProjectList/SubViews/ProjectListScreen+NextPageFooter.swift`
  - `sources/Projects/Feature/ProjectRegistration/QuizGenerationConfirmation/QuizGenerationConfirmationScreen.swift`
  - `sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+FailureView.swift`
  - `sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+GeneratingView.swift`
  - `sources/Projects/Feature/ProjectRegistration/QuizGenerationProgress/SubViews/QuizGenerationProgressScreen+GenerationReminderSheet.swift`
  - `sources/Projects/Feature/ProjectRegistration/QuizLevelSelection/QuizLevelSelectionScreen.swift`
  - `sources/Projects/Feature/ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationScreen.swift`
  - `sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputScreen.swift`
- [ ] T040 [P] [S1] Feature Quiz·Saved·Settings·ShareRegistration의 `FeedbackActionButton` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/Quiz/LearningCompletion/LearningCompletionScreen.swift`
  - `sources/Projects/Feature/Quiz/LearningSetIntro/LearningSetIntroScreen.swift`
  - `sources/Projects/Feature/Quiz/LearningSetIntro/SubViews/LearningSetIntroScreen+ErrorView.swift`
  - `sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingScreen.swift`
  - `sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+SourceSheet.swift`
  - `sources/Projects/Feature/Saved/SubViews/SavedScreen+ErrorView.swift`
  - `sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+LoadFailureView.swift`
  - `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+AccountDeletionView.swift`
  - `sources/Projects/Feature/ShareRegistration/SubViews/ShareRegistrationScreen+GuidanceView.swift`
- [ ] T041 [P] [S1] Feature의 `TagBadge` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+QuestionPrompt.swift`
  - `sources/Projects/Feature/Settings/Profile/SubViews/ProfileScreen+ProfileHeaderView.swift`
- [ ] T042 [P] [S1] Feature의 `IconGlassButton` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/ProjectList/ProjectListScreen.swift`
  - `sources/Projects/Feature/Saved/SavedScreen.swift`
  - `sources/Projects/Feature/Saved/SubViews/SavedScreen+ErrorView.swift`
  - `sources/Projects/Feature/Settings/Profile/ProfileScreen.swift`
  - `sources/Projects/Feature/Settings/Settings/SettingsScreen.swift`
  - `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+AccountDeletionView.swift`
  - `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+CareerLevelSelectionView.swift`
  - `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+PositionSelectionView.swift`

### 정리와 단위 검증

- [ ] T043 [no-write] [S1] `"$project_build_runner" compile`과 `"$project_build_runner" test`를 순차 실행하고 두 가지를 확인한다.
  - [quickstart.md](./quickstart.md) §2.1의 `ActionButton|FeedbackActionButton|TagBadge|IconGlassButton`·`ContinuousProgressBar` 패턴이 0줄이다.
  - diff에서 명시 값이 보존됐다. `FeedbackActionButton` `.primary` 19곳과 `IconGlassButton` `.small` 1곳 등 기본값과 같은 명시는 생략됐고, 그 밖의 값은 메서드로 옮겨졌다.
  - `ActionButton(styledText:)` 경로(명세 예외·경계 사례)가 전달받은 `StyledText`의 텍스트 스타일·전경색을 그대로 그린다. 확인 대상은 `ActionButton.swift` `#Preview`와 `styledText:`를 쓰는 `FeedbackActionButton` 호출부 1곳이다. `ActionButton`이 안쪽 `StyledText`에 시각 속성 메서드를 다시 적용하지 않는지 코드로도 확인한다.

**진행 점검**: T029~T043의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행
단위로 진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을 요청한다.

---

## 실행 단위 3: 색 컴포넌트 (단일 패키지: UI)

**목표**: `IconPlainButton`, `ScreenContainer`, `OverlayContainer`의 색을 메서드로 선언하게 한다.

**패키지 근거**: 세 컴포넌트의 색 인자에는 기본값이 있고, 명시 호출부는 UI 안(`IconPlainButton`
프리뷰, UI 테스트 2곳)에만 있다. 그래서 Feature 호출부는 바뀌지 않는다([research.md](./research.md) §1.2).

**소유 경로**: 아래 작업에 적은 UI 파일

**관련 변경 시나리오**: S1, S2

**독립 검증**: `compile`·`test` 통과, [quickstart.md](./quickstart.md) §2.1의 해당 패턴 0줄

### 테스트

- [ ] T044 [P] [S2] `sources/Projects/UI/Tests/Component/Unit/Contracts/BackgroundColorConfigurableTests.swift`에 `@Suite("BackgroundColorConfigurable 계약")`을 만든다. `IconPlainButton`·`ScreenContainer`·`OverlayContainer`에 대해 세 가지를 검증한다.
  - 기본값(`.clear`·`.grey700`·`.grey700`)
  - `backgroundColorToken(_:)`이 배경색만 바꿈
  - 마지막 선언 우선
  - `IconPlainButton`은 `foregroundColorToken(_:)`과 순서를 바꿔도 결과가 같음
- [ ] T045 [S2] `sources/Projects/UI/Tests/Component/Unit/Contracts/ForegroundColorConfigurableTests.swift`에 `IconPlainButton`에 대한 두 가지 검증을 추가한다. 기본 전경색 `.white`와, 전경색만 바뀌고 배경색·`label`이 유지됨이다.

### 구현

- [ ] T046 [P] [S1] `sources/Projects/UI/Component/Controls/IconPlainButton.swift`를 전환한다.
  - 초기화 메서드를 `init(icon:label:iconSize:size:action:)`로 바꾼다.
  - `private var foregroundColor: ColorToken = .white`, `private var backgroundColor: ColorToken = .clear`를 둔다.
  - `ForegroundColorConfigurable`·`BackgroundColorConfigurable`을 채택하고 `#Preview`를 전환한다.
- [ ] T047 [P] [S1] `sources/Projects/UI/Component/Scaffolds/ScreenContainer.swift`를 전환한다.
  - 초기화 메서드를 `init(content:)`로 바꾼다.
  - `private var backgroundColor: ColorToken = .grey700`을 둔다.
  - `BackgroundColorConfigurable`을 채택한다.
- [ ] T048 [P] [S1] `sources/Projects/UI/Component/Scaffolds/OverlayContainer.swift`를 전환한다.
  - `where Background == EmptyView` 초기화 메서드와 비공개 공통 초기화 메서드에서 `screenBackground` 인자를 제거한다.
  - `private var screenBackground: ColorToken = .grey700`을 둔다.
  - 타입 전체에서 `BackgroundColorConfigurable`을 채택한다([research.md](./research.md) §4.5).
- [ ] T049 [P] [S1] UI 테스트 호출부를 공통 전환 규칙으로 바꾼다. 기존 단언은 유지한다.
  - `sources/Projects/UI/Tests/Component/Unit/Scaffolds/ScreenContainerContractTests.swift`
  - `sources/Projects/UI/Tests/Component/Unit/Scaffolds/OverlayContainerContractTests.swift`

### 정리와 단위 검증

- [ ] T050 [no-write] [S1] `"$project_build_runner" compile`과 `"$project_build_runner" test`를 순차 실행한다. [quickstart.md](./quickstart.md) §2.1의 `IconPlainButton`·`ScreenContainer`·`OverlayContainer` 패턴이 0줄인지 확인한다. Feature 화면 프리뷰의 배경이 `.grey700`으로 유지되는지 확인한다.

**진행 점검**: T044~T050의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행
단위로 진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을 요청한다.

---

## 실행 단위 4: `HomeProjectCard.Variant` 이름 변경 (integration unit: UI, Feature)

**목표**: 순수 이름 변경으로 `HomeProjectCard.Variant`를 `HomeProjectCard.Style`로 바꾼다. case와
`init(index:)`는 유지한다([research.md](./research.md) §4.3). 동작·시그니처 형태는 바꾸지 않는다.

**분리 불가 근거**: Feature `HomeProjectDisplay`가 `HomeProjectCard.Variant` 타입을 참조한다. 이름만
바꿔도 Feature가 함께 바뀌어야 compile된다.

**소유 경로**: `sources/Projects/UI/Component/CollectionItems/HomeProjectCard/HomeProjectCard.swift`,
`sources/Projects/UI/Tests/Component/Unit/CollectionItems/HomeProjectCardTests.swift`,
`sources/Projects/Feature/Home/ViewModels/HomeProjectDisplay.swift`

**관련 변경 시나리오**: S1

**통합 검증**: `compile`·`test` 통과. `rg -n 'Variant' sources/Projects/UI/Component/CollectionItems sources/Projects/Feature/Home sources/Projects/UI/Tests`가 0줄이다.

### 구현

- [ ] T051 [S1] `sources/Projects/UI/Component/CollectionItems/HomeProjectCard/HomeProjectCard.swift`에서 `public enum Variant`와 그 `// MARK:` 제목, 초기화 인자 타입, 저장 프로퍼티 타입의 이름을 `Style`로 바꾼다. 인자 이름 `variant:`와 저장 프로퍼티 이름은 이 작업에서 바꾸지 않는다.
- [ ] T052 [P] [S1] `sources/Projects/Feature/Home/ViewModels/HomeProjectDisplay.swift`에서 `HomeProjectCard.Variant` 참조 2곳을 `HomeProjectCard.Style`로 바꾼다. 프로퍼티 이름 `variant`는 유지한다.
- [ ] T053 [P] [S1] `sources/Projects/UI/Tests/Component/Unit/CollectionItems/HomeProjectCardTests.swift`에서 `HomeProjectCard.Variant` 참조를 `HomeProjectCard.Style`로 바꾼다.

### 정리와 단위 검증

- [ ] T054 [no-write] [S1] `"$project_build_runner" compile`과 `"$project_build_runner" test`를 순차 실행한다. 단위 통합 검증 조회가 0줄인지 확인한다. `sources/Projects/Feature/Tests/Home/Home/ViewModels/HomeProjectDisplayTests.swift`가 수정 없이 통과하는지 확인한다.

**진행 점검**: T051~T054의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행
단위로 진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을 요청한다.

---

## 실행 단위 5: 시각 속성과 표시 값 모델을 함께 전환 (integration unit: UI, Feature)

**목표**: `LabeledCard`, `LabeledProgressBar`, `SelectionCard`, `SelectionCardList`(+`Item`),
`HomeProjectCard`의 시각 속성을 메서드로 옮기고 표시 값을 `DisplayModel`로 묶는다. 호출부는 한 번만
고친다.

**분리 불가 근거**: 초기화 메서드의 표시 값 인자와 시각 속성 인자를 함께 제거하므로 Feature 호출부
(QuestionSolving, ProjectDetail, Onboarding·Settings 선택 화면, Home)가 같은 단위에서 바뀌어야
compile된다.

**소유 경로**: 아래 작업에 적은 UI·Feature 파일

**관련 변경 시나리오**: S1, S2, S4

**통합 검증**: `compile`·`test` 통과, [quickstart.md](./quickstart.md) §2.1·§2.2 조회 0줄,
`SelectionCardList` `.compact` 프리뷰 확인

### 테스트

- [ ] T055 [P] [S2] `sources/Projects/UI/Tests/Component/Unit/Contracts/StyleConfigurableTests.swift`에 검증을 추가한다.
  - `LabeledCard` 기본 `.neutral`, `HomeProjectCard` 기본 `.purple`
  - `SelectionCard` 경로별 기본값: 썸네일 경로 `.detailed`, `Thumbnail == EmptyView` 경로 `.compact`
  - `SelectionCardList` 기본 `.detailed`
  - `style(_:)`이 `displayModel`을 유지함
- [ ] T056 [P] [S2] `sources/Projects/UI/Tests/Component/Unit/Contracts/ForegroundColorConfigurableTests.swift`에 `LabeledProgressBar`에 대한 두 가지 검증을 추가한다. 기본 `.grey400`과, 전경색만 바뀌고 `displayModel`이 유지됨이다.

### 구현

- [ ] T057 [P] [S1] [S4] `sources/Projects/UI/Component/Displays/LabeledCard.swift`를 전환한다.
  - `public struct DisplayModel: Sendable, Equatable { label, text }`를 `extension LabeledCard`에 둔다.
  - 초기화 메서드를 `init(displayModel:)`로 바꾼다.
  - `private var style: Style = .neutral`을 두고 `StyleConfigurable`을 채택한다.
  - `#Preview`를 전환한다.
- [ ] T058 [P] [S1] [S4] `sources/Projects/UI/Component/Indicators/LabeledProgressBar.swift`를 전환한다.
  - `DisplayModel { label, progress, valueText }`를 둔다.
  - 초기화 메서드를 `init(displayModel:)`로 바꾼다.
  - `private var foregroundColor: ColorToken = .grey400`을 두고 `ForegroundColorConfigurable`을 채택한다.
  - `#Preview`를 전환한다.
- [ ] T059 [S1] [S4] `sources/Projects/UI/Component/CollectionItems/SelectionCard/SelectionCard.swift`를 전환한다.
  - `DisplayModel { title, supportingText = nil, badgeText = nil }`를 둔다.
  - 두 생성 경로를 `init(displayModel:isSelected:thumbnail:)`·`init(displayModel:isSelected:)`로 바꾼다.
  - `private var style: SelectionCardStyle = .detailed`를 두고, EmptyView 경로에서는 `.compact`를 대입한다.
  - `StyleConfigurable`을 채택하고 `#Preview`를 전환한다([research.md](./research.md) §4.6).
- [ ] T060 [S4] `sources/Projects/UI/Component/Controls/SelectionCardList/SelectionCardList+Item.swift`를 전환한다.
  - `Item.DisplayModel { title, supportingText = nil, illust = nil }`을 같은 파일에 둔다.
  - 초기화 메서드를 `init(id:displayModel:isSelected:)`로 바꾼다.
- [ ] T061 [S1] [S4] `sources/Projects/UI/Component/Controls/SelectionCardList/SelectionCardList.swift`를 전환한다.
  - 초기화 메서드를 `init(items:onSelect:)`로 바꾼다.
  - `private var style: SelectionCardStyle = .detailed`를 두고 `StyleConfigurable`을 채택한다.
  - `card(for:)`에서 `SelectionCard.DisplayModel(title:supportingText:)`을 만든다. 썸네일 경로에는 `.style(style)`을 전달한다.
  - `#Preview`의 `Item` 생성을 전환한다.
- [ ] T062 [S1] [S4] `sources/Projects/UI/Component/CollectionItems/HomeProjectCard/HomeProjectCard.swift`를 전환한다.
  - `DisplayModel { title, technologies, progress, currentSetLabel, setTitle }`를 둔다.
  - 초기화 메서드를 `init(displayModel:isLearningEnabled:onSelect:onStart:)`로 바꾼다.
  - 저장 프로퍼티를 `private var style: Style = .purple`로 두고 `StyleConfigurable`을 채택한다.
  - `#Preview`를 전환한다.
- [ ] T063 [P] [S4] `sources/Projects/UI/Component/Scaffolds/OverlayContainer.swift`의 `#Preview` 속 `LabeledCard` 호출을 공통 전환 규칙으로 바꾼다
- [ ] T064 [P] [S1] [S4] UI 테스트 호출부를 공통 전환 규칙으로 바꾼다. 기존 단언은 유지한다.
  - `sources/Projects/UI/Tests/Component/Unit/Displays/LabeledCardTests.swift`
  - `sources/Projects/UI/Tests/Component/Unit/Controls/SelectionCardListTests.swift`
  - `sources/Projects/UI/Tests/Component/Unit/CollectionItems/HomeProjectCardTests.swift`
- [ ] T065 [P] [S1] [S4] Feature의 `LabeledCard` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingScreen.swift`
  - `sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+EssayResultSection.swift`
- [ ] T066 [P] [S4] `sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+RepositorySummaryView.swift`의 `LabeledProgressBar` 호출을 공통 전환 규칙으로 바꾼다
- [ ] T067 [P] [S1] [S4] Feature의 `SelectionCardList`·`SelectionCardList.Item` 생성을 공통 전환 규칙으로 바꾼다. `style: .compact`는 `.style(.compact)`로 옮긴다.
  - `sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionScreen.swift`
  - `sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionScreen.swift`
  - `sources/Projects/Feature/ProjectRegistration/QuizLevelSelection/QuizLevelSelectionScreen.swift`
  - `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+CareerLevelSelectionView.swift`
  - `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+PositionSelectionView.swift`
- [ ] T068 [P] [S1] [S4] `sources/Projects/Feature/Home/SubViews/HomeScreen+ProjectSection.swift`의 `HomeProjectCard` 호출에서 `HomeProjectDisplay` 값으로 `HomeProjectCard.DisplayModel`을 호출 지점에서 만들고 `variant`를 `.style(project.variant)`로 옮긴다. `HomeProjectDisplay`·`HomeProjectSectionState`는 바꾸지 않는다.

### 정리와 단위 검증

- [ ] T069 [no-write] [S4] `"$project_build_runner" compile`과 `"$project_build_runner" test`를 순차 실행하고 다음을 확인한다.
  - [quickstart.md](./quickstart.md) §2.1(`LabeledCard`·`LabeledProgressBar`·`SelectionCard(List)`·`HomeProjectCard` 패턴)과 §2.2(Feature State·Reducer·`ViewModels/`의 `DisplayModel` 참조) 조회가 0줄이다.
  - `LabeledCard` `.neutral` 5곳, `HomeProjectCard` `.purple` 명시가 생략되고 다른 값은 보존됐다.
  - `SelectionCardList` `.compact` 목록(PositionSelection) 프리뷰가 전환 전과 같다.

**진행 점검**: T055~T069의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행
단위로 진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을 요청한다.

---

## 실행 단위 6: 표시 값 모델 — CollectionItems (integration unit: UI, Feature)

**목표**: `ChoiceResultRow`, `LearningSetRow`, `ProjectRow`, `SavedQuestionCard`의 표시 값을
`DisplayModel`로 묶는다.

**분리 불가 근거**: 필수 표시 값 인자를 제거하므로 Feature 호출부(ProjectDetail, ProjectList,
Saved)가 함께 바뀌어야 compile된다.

**소유 경로**: 아래 작업에 적은 UI·Feature 파일

**관련 변경 시나리오**: S4

**통합 검증**: `compile`·`test` 통과, [quickstart.md](./quickstart.md) §2.2 조회 0줄

### 구현

- [ ] T070 [P] [S4] `sources/Projects/UI/Component/CollectionItems/ChoiceResultRow.swift`에 `DisplayModel { text, explanation }`을 두고, 초기화 메서드를 `init(displayModel:judgement:isExpanded:onTap:)`로 바꾼다. `#Preview`를 전환한다
- [ ] T071 [P] [S4] `sources/Projects/UI/Component/CollectionItems/LearningSetRow.swift`에 `DisplayModel { label, title, questionCount, completedCount }`를 두고, 초기화 메서드를 `init(displayModel:onStart:)`로 바꾼다. `#Preview`를 전환한다
- [ ] T072 [P] [S4] `sources/Projects/UI/Component/CollectionItems/ProjectRow/ProjectRow.swift`에 `DisplayModel { name, supportingText, progress, currentSet, setTitle }`를 두고, 초기화 메서드를 `init(displayModel:isDeleting:onAccessoryTap:thumbnail:)`로 바꾼다. `#Preview`를 전환한다
- [ ] T073 [P] [S4] `sources/Projects/UI/Component/CollectionItems/SavedQuestionCard/SavedQuestionCard.swift`에 `DisplayModel { metadata, prompt, actionTitle }`을 두고, 초기화 메서드를 `init(displayModel:isBookmarked:onActionTap:onBookmarkTap:)`로 바꾼다. `#Preview`를 전환한다
- [ ] T074 [P] [S4] UI 테스트 호출부를 공통 전환 규칙으로 바꾼다. 기존 단언은 유지한다.
  - `sources/Projects/UI/Tests/Component/Unit/CollectionItems/ChoiceResultRowTests.swift`
  - `sources/Projects/UI/Tests/Component/Unit/CollectionItems/LearningSetRowTests.swift`
- [ ] T075 [P] [S4] `sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+SetListSection.swift`의 `LearningSetRow` 호출에서 호출 지점에 `LearningSetRow.DisplayModel`을 만들도록 바꾼다
- [ ] T076 [P] [S4] `sources/Projects/Feature/ProjectList/ProjectListScreen.swift`의 `ProjectRow` 호출에서 호출 지점에 `ProjectRow.DisplayModel`을 만들도록 바꾼다
- [ ] T077 [P] [S4] `sources/Projects/Feature/Saved/SavedScreen.swift`의 `SavedQuestionCard` 호출에서 호출 지점에 `SavedQuestionCard.DisplayModel`을 만들도록 바꾼다

### 정리와 단위 검증

- [ ] T078 [no-write] [S4] `"$project_build_runner" compile`과 `"$project_build_runner" test`를 순차 실행한다. [quickstart.md](./quickstart.md) §2.2 조회가 0줄인지, 네 컴포넌트의 `public init` 첫 인자가 `displayModel`인지 확인한다. `ProjectListScreen`·`SavedScreen` 프리뷰가 전환 전과 같은지 확인한다.

**진행 점검**: T070~T078의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행
단위로 진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을 요청한다.

---

## 실행 단위 7: 표시 값 모델 — Controls (integration unit: UI, Feature)

**목표**: `ChoiceAnswerOption`, `LabeledTextField`, `PolicyAgreementRow`, `ScreenControlBar`,
`TextField`의 표시 값을 `DisplayModel`로 묶는다.

**분리 불가 근거**: 표시 값 인자를 제거하므로 Feature 호출부(QuestionSolving, RepositoryLinkInput,
LegalAgreement, `ScreenControlBar`의 `leading`·`trailing`을 명시한 화면)가 함께 바뀌어야
compile된다.

**소유 경로**: 아래 작업에 적은 UI·Feature 파일

**관련 변경 시나리오**: S4

**통합 검증**: `compile`·`test` 통과, [quickstart.md](./quickstart.md) §2.2 조회 0줄

### 구현

- [ ] T079 [P] [S4] `sources/Projects/UI/Component/Controls/ChoiceAnswerOption.swift`에 `DisplayModel { letter, text }`를 두고, 초기화 메서드를 `init(displayModel:state:expansion:onTap:)`로 바꾼다. `#Preview`를 전환한다
- [ ] T080 [P] [S4] `sources/Projects/UI/Component/Controls/LabeledTextField/LabeledTextField.swift`에 `DisplayModel { label, placeholder, supportingText = nil }`을 둔다. 초기화 메서드를 `init(displayModel:text:isError:keyboardType:textInputAutocapitalization:autocorrectionDisabled:accessibilityLabel:focus:)`로 바꾸고 `#Preview`를 전환한다
- [ ] T081 [P] [S4] `sources/Projects/UI/Component/Controls/PolicyAgreementRow/PolicyAgreementRow.swift`에 `DisplayModel { title, isRequired }`를 두고, 초기화 메서드를 `init(displayModel:isSelected:onToggle:onOpenLink:)`로 바꾼다. `#Preview`를 전환한다
- [ ] T082 [P] [S4] `sources/Projects/UI/Component/Controls/ScreenControlBar/ScreenControlBar.swift`에 `DisplayModel { leading: Control? = .back, trailing: Control? = nil }`을 둔다. 초기화 메서드를 `init(displayModel: DisplayModel = .init(), onLeadingTap:onTrailingTap:)`로 바꾸고 `#Preview`를 전환한다
- [ ] T083 [P] [S4] `sources/Projects/UI/Component/Controls/TextField.swift`에 `DisplayModel { placeholder, errorMessage = nil }`을 두고, 초기화 메서드를 `init(displayModel:text:isSecure:onCommit:)`로 바꾼다. `#Preview`를 전환한다
- [ ] T084 [P] [S4] UI 테스트 호출부를 공통 전환 규칙으로 바꾼다. 기존 단언은 유지한다.
  - `sources/Projects/UI/Tests/Component/Unit/Controls/ChoiceAnswerOptionTests.swift`
  - `sources/Projects/UI/Tests/Component/Unit/Controls/PolicyAgreementRowTests.swift`
  - `sources/Projects/UI/Tests/Component/Unit/Controls/TextFieldTests.swift`
- [ ] T085 [P] [S4] `sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+ChoiceSection.swift`의 `ChoiceAnswerOption` 호출을 공통 전환 규칙으로 바꾼다
- [ ] T086 [P] [S4] `sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputScreen.swift`의 `LabeledTextField` 호출을 공통 전환 규칙으로 바꾼다
- [ ] T087 [P] [S4] `sources/Projects/Feature/Onboarding/LegalAgreement/LegalAgreementScreen.swift`의 `PolicyAgreementRow` 호출을 공통 전환 규칙으로 바꾼다
- [ ] T088 [P] [S4] Feature에서 `leading:`·`trailing:`을 명시한 `ScreenControlBar` 호출을 `displayModel: .init(leading:trailing:)`로 바꾼다. 인자를 생략한 호출부는 바꾸지 않는다.
  - `sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionScreen.swift`
  - `sources/Projects/Feature/Onboarding/PositionSelection/PositionSelectionScreen.swift`
  - `sources/Projects/Feature/ProjectDetail/ProjectDetailScreen.swift`
  - `sources/Projects/Feature/Quiz/LearningCompletion/LearningCompletionScreen.swift`

### 정리와 단위 검증

- [ ] T089 [no-write] [S4] `"$project_build_runner" compile`과 `"$project_build_runner" test`를 순차 실행한다. [quickstart.md](./quickstart.md) §2.2 조회가 0줄이고 `rg -n 'ScreenControlBar\([^)]*\b(leading|trailing):' sources/Projects`가 0줄인지 확인한다.

**진행 점검**: T079~T089의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행
단위로 진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을 요청한다.

---

## 실행 단위 8: 표시 값 모델 — Displays·Indicators·Overlays (integration unit: UI, Feature)

**목표**: `RubricView`, `ScreenHeaderTitle`, `EmptyState`, `PageIndicator`, `ProgressSegments`,
`ConfirmationSheet`, `WebSheet`의 표시 값을 `DisplayModel`로 묶는다.

**분리 불가 근거**: 표시 값 인자를 제거하므로 Feature 호출부(ProjectList, Saved, Settings,
ProjectDetail, Tutorial, MainShell·Onboarding Router)가 함께 바뀌어야 compile된다.

**소유 경로**: 아래 작업에 적은 UI·Feature 파일

**관련 변경 시나리오**: S4

**통합 검증**: `compile`·`test` 통과, [quickstart.md](./quickstart.md) §2.2 조회 0줄

### 구현

- [ ] T090 [P] [S4] `sources/Projects/UI/Component/Displays/RubricView/RubricView.swift`에 `DisplayModel { criteria, overallFeedback = nil }`을 두고, 초기화 메서드를 `init(displayModel:)`로 바꾼다. `#Preview`를 전환한다
- [ ] T091 [P] [S4] `sources/Projects/UI/Component/Displays/ScreenHeaderTitle.swift`에 `DisplayModel { title = nil, subtitle = nil }`을 두고, 초기화 메서드를 `init(displayModel:)`로 바꾼다. `#Preview`를 전환한다
- [ ] T092 [P] [S4] `sources/Projects/UI/Component/Indicators/EmptyState/EmptyState.swift`에 `DisplayModel { title, message }`를 두고, 초기화 메서드를 `init(displayModel:illustration:)`로 바꾼다. `#Preview`를 전환한다
- [ ] T093 [P] [S4] `sources/Projects/UI/Component/Indicators/PageIndicator.swift`에 `DisplayModel { currentPage, totalPages }`를 두고, 초기화 메서드를 `init(displayModel:)`로 바꾼다. `#Preview`를 전환한다
- [ ] T094 [P] [S4] `sources/Projects/UI/Component/Indicators/ProgressSegments.swift`에 `DisplayModel { completed, total }`을 두고, 초기화 메서드를 `init(displayModel:)`로 바꾼다. `#Preview`를 전환한다
- [ ] T095 [P] [S4] `sources/Projects/UI/Component/Overlays/ConfirmationSheet.swift`에 `DisplayModel { imageURL, title, message, confirmTitle, cancelTitle }`을 두고, 초기화 메서드를 `init(displayModel:onConfirmTap:onCancelTap:)`로 바꾼다. `#Preview`를 전환한다
- [ ] T096 [P] [S4] `sources/Projects/UI/Component/Overlays/WebSheet.swift`에 `DisplayModel { title, url }`을 두고, 초기화 메서드를 `init(displayModel:onDismiss:)`로 바꾼다. `#Preview`를 전환한다
- [ ] T097 [P] [S4] UI 내부 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/UI/Component/CollectionItems/LearningSetRow.swift`: `ProgressSegments`
  - `sources/Projects/UI/Component/Scaffolds/OverlayContainer.swift`: `#Preview`의 `ScreenHeaderTitle`
- [ ] T098 [P] [S4] `sources/Projects/UI/Tests/Component/Unit/Indicators/PageIndicatorTests.swift`의 `PageIndicator` 호출부를 공통 전환 규칙으로 바꾼다. 기존 단언은 유지한다
- [ ] T099 [P] [S4] Feature의 `ScreenHeaderTitle` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/ProjectList/ProjectListScreen.swift`
  - `sources/Projects/Feature/ProjectList/SubViews/ProjectListScreen+FailureView.swift`
  - `sources/Projects/Feature/Saved/SavedScreen.swift`
  - `sources/Projects/Feature/Saved/SubViews/SavedScreen+ErrorView.swift`
  - `sources/Projects/Feature/Settings/Profile/ProfileScreen.swift`
  - `sources/Projects/Feature/Settings/Settings/SettingsScreen.swift`
  - `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+AccountDeletionView.swift`
  - `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+CareerLevelSelectionView.swift`
  - `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+PositionSelectionView.swift`
- [ ] T100 [P] [S4] Feature의 `EmptyState` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+SetListSection.swift`
  - `sources/Projects/Feature/ProjectList/SubViews/ProjectListScreen+EmptyProjectsView.swift`
  - `sources/Projects/Feature/Saved/SavedScreen.swift`
- [ ] T101 [P] [S4] `sources/Projects/Feature/Onboarding/Tutorial/SubViews/TutorialScreen+SignInSection.swift`의 `PageIndicator` 호출을 공통 전환 규칙으로 바꾼다
- [ ] T102 [P] [S4] Feature의 `ConfirmationSheet` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/ProjectDetail/ProjectDetailScreen.swift`
  - `sources/Projects/Feature/ProjectList/ProjectListScreen.swift`
- [ ] T103 [P] [S4] Feature의 `WebSheet` 호출부를 공통 전환 규칙으로 바꾼다.
  - `sources/Projects/Feature/MainShell/Router/MainShellRouter.swift`
  - `sources/Projects/Feature/Onboarding/Router/OnboardingRouter.swift`

### 정리와 단위 검증

- [ ] T104 [no-write] [S4] `"$project_build_runner" compile`과 `"$project_build_runner" test`를 순차 실행한다. [quickstart.md](./quickstart.md) §2.2 조회가 0줄인지, 일곱 컴포넌트의 `public init` 첫 인자가 `displayModel`인지 확인한다. `ProjectListScreen`·`SettingsScreen` 프리뷰가 전환 전과 같은지 확인한다.

**진행 점검**: T090~T104의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행
단위로 진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을 요청한다.

---

## 실행 단위 9: 컨벤션·패키지 규칙 문서 개정 (문서 단위: UI·Feature 규칙 문서)

**목표**: 명세 규칙(FR-003·FR-004·FR-007·FR-012·FR-015)을 문서에 반영한다. 반영 대상은 명세
FR-016 목록과 [research.md](./research.md) §7의 추가 문서다(SC-006).

**소유 근거**: 문서는 UIComponent·Feature의 규칙을 정하며, 코드 변경(U1~U8)이 모두 끝난 뒤 최종
형태를 서술한다. 문서 루트는 `GIT_IT_DOCS_ROOT` 판독 결과인 `docs`다.

**소유 경로**: 아래 작업에 적은 문서 16개

**관련 변경 시나리오**: S3

**독립 검증**: [quickstart.md](./quickstart.md) §5 조회 0줄, 문서만 읽고 새 컴포넌트의 선언 방식을
판정할 수 있는지 검토

### 구현

- [ ] T105 [P] [S3] `docs/conventions/view/component-init.md`(책임: UI)를 개정한다.
  - 시각 속성은 속성 종류별 계약의 `Self` 반환 메서드로 선언한다고 쓴다.
  - 초기화 메서드는 표시 값(2개 이상이면 `DisplayModel`)·상태·동작 설정·접근성 문구·`Binding`·콜백·자식 View만 받는다고 쓴다.
  - 모든 시각 속성은 기본값을 가지며, 기본값 선택 기준은 디자인 시스템의 중립·기본 값이라고 쓴다.
  - 시각 속성 메서드는 일반 수정자보다 먼저 호출한다고 쓴다.
  - "시각 변형은 초기화 인자" 문장, "상태 wrapper를 추가하지 않는다" 문장, `SelectionToggle(state:)` 금지 예시를 삭제한다.
  - 예시를 계약 문서 §5로 바꾼다. `ProjectRow(project:)` 금지는 유지한다.
- [ ] T106 [P] [S3] `docs/conventions/view/display-value-binding-callback.md`(책임: UI)를 개정한다.
  - 표시 상태 wrapper 금지 문장을 삭제한다.
  - 표시 값 모델 규칙을 서술한다. 인자를 표시 값·상태·동작 설정·화면에 보이지 않는 문구로 구분하고, 식별자는 세지 않는다.
- [ ] T107 [P] [S3] `docs/conventions/view.md`(책임: UI·Feature)를 개정한다.
  - §3 요약을 새 초기화 계약에 맞춘다.
  - §6 체크리스트의 wrapper 금지 항목을 두 항목으로 바꾼다: "시각 속성을 초기화 인자로 받지 않고 계약 메서드로 선언하는가", "표시 값 2개 이상을 `DisplayModel`로 받는가".
  - 최종 수정일을 갱신한다.
- [ ] T108 [P] [S3] `docs/package-rules/ui.md`(책임: UI)의 "표시 상태를 묶는 ViewModel, State 또는 동등한 wrapper 타입을 정의해서는 안 됩니다" 제약을 삭제한다. 설명의 "표시 값·SwiftUI `Binding`·콜백 기반 컴포넌트"에 표시 값 모델·시각 속성 계약을 반영하고 최종 수정일을 갱신한다
- [ ] T109 [P] [S3] `docs/conventions/ui-component/public-contract.md`(책임: UI)에서 "표시 상태 wrapper 금지" 언급을 삭제하고 표시 값 모델·시각 속성 계약 규칙의 소유 문서 링크로 바꾼다
- [ ] T110 [P] [S3] `docs/conventions/view-declarations/style.md`(책임: UI)의 예시와 마지막 문단을 개정한다. `Style`을 초기화 인자로 넘긴다는 서술을 `StyleConfigurable`의 `style(_:)` 메서드로 선택한다는 서술로 바꾼다
- [ ] T111 [P] [S3] `docs/conventions/view-declarations/internal-declarations.md`(책임: UI)를 개정한다.
  - "표시 값과 `Binding`은 별도 타입으로 감싸지 않고" 문장을 표시 값 모델 규칙으로 바꾼다.
  - 선언 표에 `struct DisplayModel` 행(정의 조건: 표시 값 2개 이상, 접근 수준: `public`)을 추가한다.
- [ ] T112 [P] [S3] `docs/conventions/view-declarations.md`(책임: UI)의 §2.3 요약과 체크리스트를 T110·T111 규칙에 맞춰 갱신하고 최종 수정일을 갱신한다
- [ ] T113 [P] [S3] `docs/conventions/view-declarations/binding.md`(책임: UI)에서 "별도 상태 wrapper에 외부 값을 복제하지 않습니다" 문장을 삭제한다. 나머지 `Binding` 보존 규칙은 유지한다
- [ ] T114 [P] [S3] `docs/conventions/view/preview.md`(책임: UI)에 한 가지를 보강한다. 컴포넌트 프리뷰가 시각 변형을 계약 메서드로 나열한다는 문장이다
- [ ] T115 [P] [S3] `docs/package-rules/feature.md`(책임: Feature)에 두 가지를 추가한다.
  - Feature View가 컴포넌트 호출 지점에서 State·업무 모델을 표시 값 모델로 매핑한다.
  - Feature State·Reducer·State에 담기는 표시 모델은 UI `DisplayModel`을 보유하지 않는다.
  - 최종 수정일을 갱신한다.
- [ ] T116 [P] [S3] `docs/conventions/ui-component/folder-file.md`(책임: UI)의 "1뎁스는 §3.2의 역할 폴더와 `Resources/`뿐" 문장에 시각 속성 계약을 두는 `Contracts/`를 추가한다
- [ ] T117 [P] [S3] `docs/conventions/file-vocabulary/shape-vocabulary.md`(책임: UI)의 `UI/Component/` 행에 `Contracts/`(여러 역할 폴더가 채택하는 시각 속성 계약 프로토콜)를 추가한다
- [ ] T118 [P] [S3] `docs/conventions/abstraction.md`(책임: UI)의 §1 "다루지 않습니다" 목록에 항목을 추가한다. 추가할 항목은 "여러 컴포넌트가 같은 이름·형태의 공개 메서드를 제공하도록 강제하는 UI 시각 속성 계약"이다([research.md](./research.md) §6)
- [ ] T119 [S3] `docs/conventions/abstraction/structure-baseline.md`(책임: UI)를 갱신한다.
  - §2 명령으로 프로덕션 Swift 파일 수·프로토콜 수를 다시 재 §1 표에 "명세 042 후" 열을 추가한다.
  - §3에 "UI 시각 속성 계약(5개)" 분류로 `StyleConfigurable`·`SizeConfigurable`·`TextStyleConfigurable`·`ForegroundColorConfigurable`·`BackgroundColorConfigurable`을 등재한다.
- [ ] T120 [P] [S3] `.agents/skills/implement-figma-ui/references/component-index.md`(책임: UI)를 새 공개 계약에 맞춘다.
  - 초기화 인자로 설명한 시각 속성(`Style`·`Size` 선택, `ActionButton.destructive` 같은 호출 표기)을 메서드 선언으로 바꾼다.
  - 표시 값 서술(`ConfirmationSheet`의 `title`/`message` 초기화 인자 등)을 `DisplayModel`로 바꾼다.

### 정리와 단위 검증

- [ ] T121 [no-write] [S3] [quickstart.md](./quickstart.md) §5 조회(`rg -n '표시 상태를 묶는|상태 wrapper|시각 변형은 .*초기화 인자' docs .agents/skills/implement-figma-ui/references`)가 0줄인지 확인한다. T105~T120 문서의 상호 링크가 유효한지도 확인한다. 확인 명령은 `rg -o '\]\(([^)#]+)' -r '$1'`로 추출한 상대경로의 존재 확인이다.

**진행 점검**: T105~T121의 변경 파일과 검증 결과를 보고한 뒤 전체 완료 검증으로 진행한다. 이
단위가 마지막 적용 단위이므로 전체 완료 검증과 필수 `after_implement` 훅이 끝날 때까지 이 단위의
마지막 커밋 단위를 commit하지 않는다.

---

## 전체 완료 검증

**선행 조건**: T001~T121의 파일 변경 작업을 완료하고, 전체 검증과 hook 결과를 포함할 마지막
커밋 단위(U9)를 아직 commit하지 않은 상태여야 한다.

**커밋 경계**: 아래 `[no-write]` 작업은 U9의 마지막 커밋 단위에 배정한다. 모든 검증과 필수
`after_implement` hook을 마친 뒤 그 단위를 최종 commit한다. 이미 파일 변경 단위가 모두 commit된
단순 재개에서는 `tasks.md` 완료 표시를 위한 별도 최종 검증 단위를 둔다.

- [ ] T122 [no-write] `"$project_build_runner" build`, `"$project_build_runner" compile`, `"$project_build_runner" test`를 순차 실행하고 결과를 기록한다(SC-003)
- [ ] T123 [no-write] [S1] [S2] [S4] [quickstart.md](./quickstart.md) §2.1·§2.2·§2.3 조회를 전체 저장소에 실행한다. 각 대상 컴포넌트의 `public init`을 [contracts/component-init-contracts.md](./contracts/component-init-contracts.md) §2·§3과 대조해 기록한다(SC-001·SC-002·SC-008).
  - SC-005: 메서드 이름 `style`·`size`·`textStyle`·`foregroundColorToken`·`backgroundColorToken`이 SwiftUI `View` 인스턴스 메서드와 겹치지 않는지 Apple 개발자 문서(`DocumentationSearch` 또는 SwiftUI 인터페이스)에서 조회한다.
  - 대표 호출부(예: `StyledText(text:).textStyle(.body2)`, `ActionButton(title:).style(.secondary)`)에서 Xcode의 Jump to Definition이나 `swiftc -typecheck` 진단으로 계약 메서드가 선택되는지 확인해 기록한다.
- [ ] T124 [no-write] [S1] [quickstart.md](./quickstart.md) §3 렌더링 동일성 대조 결과를 기록한다(SC-004). 호출부 값 대조 요약, 확인한 프리뷰 목록과 자동 비교 미검증 범위를 적는다
- [ ] T125 [no-write] [S3] 개정 문서만 읽고 가상의 새 컴포넌트를 판정한다. 가정은 "표시 값 3개, 스타일 변형 2개, `Binding` 1개"다. 판정할 항목은 시각 속성 선언 방식, 기본값·호출 순서 제약, `DisplayModel` 적용과 인자 구분이며, 판정 결과를 기록한다(SC-006)
- [ ] T126 [no-write] 변경 시나리오 S1~S4의 수용 시나리오를 [spec.md](./spec.md) 기준으로 하나씩 대조해 충족 근거를 기록한다

## 의존성과 실행 순서

### 실행 단위 순서와 위험 기반 승인

- **채택한 순서**: U1 → U2 → U3 → U4 → U5 → U6 → U7 → U8 → U9 → 전체 완료 검증
- **근거**:
  - 패키지 위상 순서는 UI → Feature이며([docs/architecture.md](../../docs/architecture.md)), 각
    단위는 UI 변경과 그에 의존하는 Feature 호출부를 함께 담는다.
  - U1은 계약과 가장 많이 쓰이는 `StyledText`를 먼저 전환해, 이후 단위의 컴포넌트 본문이 새
    `StyledText` 방식을 쓰게 한다.
  - U2·U3은 U5~U8의 컴포넌트가 안에서 쓰는 컴포넌트를 먼저 전환한다
    ([research.md](./research.md) §1.4). 예를 들어 `ProjectRow`는 `TagBadge`·`IconGlassButton`·
    `IconPlainButton`·`ContinuousProgressBar`를, `ConfirmationSheet`는 `ActionButton`을,
    `ScreenControlBar`는 `IconGlassButton`을, `SelectionCard`는 `TagBadge`를 쓴다.
  - U4 순수 이름 변경은 U5의 설계 변경과 분리한다.
  - U6~U8은 서로 파일이 겹치지 않지만 순서는 이 문서가 정한 대로 고정한다.
  - U9는 최종 코드 형태를 서술하므로 마지막에 둔다.
- 각 단위의 변경 파일과 검증 결과를 보고하되 같은 기능 범위에서는 반복 승인을 요구하지 않는다.
- 새 범위, 파괴적 작업, remote·외부 상태 변경, 사용자 소유 변경 소비 또는 새로운 제품 결정이
  필요할 때만 중단하고 명시적 승인을 요청한다. 예를 들어 T010 조사에서 정렬 보존만으로 렌더링을
  유지할 수 없는 호출부가 나오면 중단한다.
- 작업 트리에는 이 기능과 무관한 사용자 변경이 있다(`sources/Projects/Feature/ProjectList/ProjectListScreen.swift`
  수정, `specs/041-*` 산출물). `ProjectListScreen.swift`는 U2(T042)·U6(T076)·U8(T099·T102)의 대상이다.
  구현 시작 전 이 파일의 기존 미커밋 변경을 사용자에게 확인하고, 이 기능의 커밋에 섞지 않는다.

### 변경 시나리오 추적성

| 시나리오 | 작업 | 독립 수용 기준 |
| --- | --- | --- |
| S1 시각 속성 Self 반환 메서드 | T009~T026, T031~T042, T046~T049, T051~T053, T057~T068 | 대상 컴포넌트 초기화 메서드에 시각 속성 인자가 0개이고 기본값·다중 선언·마지막 값 우선이 성립한다(T027·T043·T050·T069·T123) |
| S2 속성 종류별 공통 계약 | T002~T008, T029·T030, T044·T045, T055·T056 | 같은 종류는 같은 메서드 이름 하나이고, 받지 않는 속성 메서드는 존재하지 않는다(T123 §2.3) |
| S3 호출부 전환과 문서 개정 | T105~T120 | 문서에 wrapper 금지·"시각 변형은 초기화 인자" 문장이 0곳이고, 문서만으로 새 컴포넌트를 판정할 수 있다(T121·T125) |
| S4 표시 값 모델 | T057~T062, T064~T068, T070~T103 | 표시 값 2개 이상인 타입은 `displayModel` 하나만 받고, Feature State·Reducer에 `DisplayModel` 참조가 0곳이다(T069·T078·T089·T104·T123) |

### 실행 단위 내부 실행

- 계약 테스트(T007·T008, T029·T030, T044·T045, T055·T056)는 같은 단위의 구현 작업 전에 작성한다.
  구현 전에는 새 초기화 메서드·메서드가 없어 compile 실패로 실패하는지 확인한다.
- `[P]`는 현재 실행 단위 안의 서로 다른 파일에만 붙였다. 같은 파일을 여러 작업이 바꾸는 경우는
  순차 실행한다(예: U5의 T059 → T061, T062 → T068).
- 여러 단위가 같은 파일을 순서대로 바꾼다. 해당 파일은 다음과 같고, 단위 순서대로만 실행한다.
  - `ProjectRow.swift`(U1·U2·U6)
  - `OverlayContainer.swift`(U3·U5·U8)
  - `LearningSetRow.swift`(U1·U6·U8)
  - `HomeProjectCard.swift`(U1·U4·U5)
  - Feature 화면 파일 다수
- `/speckit-implement`는 파일을 수정하기 전에 현재 단위의 미완료 작업을 하나의 목적과 독립적인
  rollback 경계를 갖는 커밋 단위로 묶는다. 이름 변경(U4)과 자동 포맷은 목적이 다르므로 분리한다.
- 각 커밋 단위는 포함 작업 ID, 정확한 파일 경로, 검증과 커밋 메시지를 먼저 제시한다. 단위의
  검증과 `[X]` 표시를 완료한 뒤 해당 파일과 이 `tasks.md`만 stage·commit하고, 커밋 성공을
  확인하기 전에는 다음 단위를 시작하지 않는다.
- 마지막 단위(U9)는 전체 완료 검증과 필수 `after_implement` hook이 끝날 때까지 commit하지 않는다.
  Hook이 만든 허용된 포맷 결과를 재검증해 같은 최종 commit에 포함한다.

### 병렬 실행 예시(현재 단위 안에서만)

```text
U1: T003·T004·T005·T006 동시 → T007·T008 동시 → T009 → T011~T026 동시(서로 다른 파일)
U2: T029·T030 동시 → T031 → T032·T033·T034 동시 → T035 → T036~T042 동시
U8: T090~T096 동시 → T097~T103 동시
U9: T105~T118·T120 동시 → T119
```

## 구현 전략

1. 이 tasks.md의 blob hash와 전체 diff를 기준선으로 고정하고, 작업 트리의 무관한 사용자 변경
   (`ProjectListScreen.swift`, `specs/041-*`)을 분류한다.
2. 최소 가치 범위는 U1이다(계약 도입 + `StyledText`, 시나리오 S1·S2의 첫 수용 기준). 새 권한이
   필요하지 않으므로 U2 이후로 연속 진행한다.
3. 각 단위의 구현·검증·완료 표시·커밋을 순서대로 완료하고 생성된 커밋을 확인한다.
4. U9에서 문서를 개정한 뒤 T122~T126 전체 검증과 `after_implement` 포맷 훅을 실행하고 최종 commit한다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 커밋 제목과 커밋 그룹은 이 문서가 고정하지 않는다.
- 문제 해결과 암묵지 기록은 구현 작업 ID로 만들지 않는다(Constitution 원칙 9).
