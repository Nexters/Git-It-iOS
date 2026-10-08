---

description: "Figma UI 레이아웃 상수 검증 구현 작업"
---

# 작업 목록: Figma UI 레이아웃 상수 검증

**입력**: `/specs/005-figma-layout-audit/`의 설계 문서

**선행 조건**: plan.md, spec.md, research.md, data-model.md, contracts/ui-layout-constants.md, quickstart.md

**테스트**: 사용자가 UI 테스트와 TDD를 명시적으로 요청했으므로 테스트를 구현보다 먼저 실행한다.

**구성**: 변경 패키지는 UI 하나뿐이다. Tuist 공용 helper의 UI target·scheme 선언은 이를 최초로 필요로 하는 UI 패키지에 배정한다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 UI 패키지 안에서 서로 다른 파일을 변경하고 미완료 의존성이 없을 때만 병렬 가능
- **[S1]**: Figma 레이아웃 계약 확인
- **[S2]**: 레이아웃 회귀 자동 검출
- **[S3]**: 불일치 레이아웃 교정
- **[no-write]**: 추적 파일을 변경하지 않는 명령 실행 또는 수동 검증

## 작업 패키지 1: UI

**목표**: Figma 상수 계약을 실제 UI 테스트에서 측정하고 확인된 불일치를 교정한다.

**소유 경로**: `sources/Projects/UI/`, UI 테스트 구성을 최초로 필요로 하는 `sources/Tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift`, `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`

**관련 변경 시나리오**: S1, S2, S3

**독립 검증**: `UIComponentLayout` scheme의 XCUITest, `UIComponentTests`, `DesignSystemTests`와 `UIComponent` build가 모두 통과하면 UI 패키지 책임을 독립 검증할 수 있다.

### 준비와 기반

- [X] T001 [S2] `sources/Tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift`에 `UIComponentLayoutHarness` 앱과 `UIComponentUITests` UI 테스트 target 선언을 추가한다
- [X] T002 [S2] `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`에 두 target을 build·test하는 `UIComponentLayout` shared scheme을 추가한다
- [X] T003 [P] [S2] `sources/Projects/UI/UIComponentLayoutHarness/UIComponentLayoutHarnessApp.swift`에 UI 패키지 레이아웃 검증 앱 진입점을 작성한다
- [X] T004 [S1] `sources/Projects/UI/UIComponentLayoutHarness/LayoutContractCatalog.swift`에 계약 ID별 컴포넌트 변형과 안정적인 접근성 식별자를 제공하는 정적 카탈로그를 작성한다

### 테스트 — Red

- [X] T005 [P] [S1] `sources/Projects/UI/UIComponentTests/LayoutConstantContractTests.swift`에 `ActionButton` LG 54pt·SM 40pt와 `IconGlassButton` MD 40pt·SM 36pt의 이름 있는 크기 계약 테스트를 먼저 작성한다
- [X] T006 [S2] `sources/Projects/UI/UIComponentUITests/LayoutContractUITests.swift`에 앱 실행, 계약 화면 선택, 외곽 프레임 오차 진단, 상태 간 크기 불변과 최소 44pt 터치 영역 UI 테스트를 작성한다
- [X] T007 [S2] [no-write] `UIComponent` test에서 미구현 `ActionButton.Size` 계약의 컴파일 실패를, `UIComponentLayout` XCUITest에서 `iconGlass.touch`의 실제 프레임 실패를 구현 변경 전에 실행해 각각 Red 증거로 기록한다

### 구현 — Green

- [X] T008 [S3] `sources/Projects/UI/UIComponent/Components/Leaf/ActionButton.swift`에 `Size.large(54pt)`·`Size.small(40pt)`를 추가하고 팩토리 기본값을 `large`로 유지하며 작은 시각 표면에 최소 44pt 터치 영역을 제공한다
- [X] T009 [S3] `sources/Projects/UI/UIComponent/Components/Leaf/IconGlassButton.swift`의 임의 `CGFloat` 크기를 `Size.medium(40pt)`·`Size.small(36pt)` 계약으로 바꾸고 시각 표면과 44pt 터치 영역을 분리한다
- [X] T010 [P] [S3] `sources/Projects/UI/UIComponent/Components/Leaf/IconPlainButton.swift`의 36pt 시각 표면을 유지하면서 실제 상호작용 프레임을 최소 44pt로 교정한다
- [X] T011 [S3] `sources/Projects/UI/UIComponent/Components/Composite/ScreenHeader.swift`의 leading·trailing 컨트롤이 `IconGlassButton.Size.small`을 명시해 기존 헤더 시각 크기를 보존하도록 갱신한다
- [X] T012 [S3] `sources/Projects/UI/UIComponent/Components/Composite/ProjectRow.swift`의 삭제 컨트롤이 `IconGlassButton.Size.small`을 명시해 행 레이아웃과 터치 영역을 함께 보존하도록 갱신한다

### 정리와 패키지 검증

- [X] T013 [S1] [no-write] `specs/005-figma-layout-audit/contracts/ui-layout-constants.md`의 A·B 계약과 테스트 식별자 대응을 수동 대조하고 C 항목이 Figma 확정값으로 보고되지 않았는지 확인한다
- [X] T014 [S2] [no-write] `make tuist`로 workspace를 재생성하고 `UIComponentLayout`, `UIComponent`, `DesignSystem` scheme이 존재하는지 확인한다
- [X] T015 [S2] [no-write] `xcodebuild test -workspace sources/GitIt.xcworkspace -scheme UIComponentLayout -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`로 Green 상태와 실패 진단 품질을 검증한다
- [X] T016 [S3] [no-write] 공용 project build runner로 `UIComponent` build와 `DesignSystem` test를 실행해 기존 UI 회귀가 없는지 확인한다

**승인 게이트**: UI가 유일한 적용 대상이다. T001~T016의 변경 파일과 실제 검증 결과를 보고한다. 이후 적용 대상 패키지가 없으므로 추가 패키지 승인 요청 없이 전체 완료 검증으로 진행한다.

---

## 전체 완료 검증

**선행 조건**: UI 패키지 구현·검증·결과 보고가 완료되어야 한다.

- [X] T017 [no-write] 공용 project build runner의 `build`, `compile`, `test`를 순서대로 실행하고 전체 저장소 회귀 결과를 기록한다
- [X] T018 [no-write] S1의 체크리스트 완전성, S2의 Red→Green 증거, S3의 허용 오차·접근성 수용 기준을 독립적으로 재검토한다
- [X] T019 [no-write] 모든 Swift 자연어·식별자·파일 구성이 한국어 산출물 규칙과 UI 패키지의 공개 생성 경로·중첩 선언 규칙을 따르는지 확인한다

## 의존성과 실행 순서

### 패키지 순서와 승인 게이트

- 적용 대상은 UI뿐이며 다른 패키지 파일은 수정하지 않는다.
- T001~T004로 검증 실행 기반을 구성한 뒤 T005~T007의 테스트와 Red 결과를 완료한다.
- Red 결과가 예상 원인과 다르면 구현 파일을 수정하지 않고 테스트·harness 계약을 먼저 교정한다.
- T008~T012 구현 후 T013~T016 패키지 검증을 완료하고 변경 파일·결과를 보고한다.
- 마지막 적용 대상 완료 뒤에만 T017~T019 전체 읽기 전용 검증을 실행한다.

### 변경 시나리오 추적성

- **S1**: T004, T005, T013이 Figma 근거·상수 계약·테스트 식별자 대응을 검증한다.
- **S2**: T001~T007, T014~T015가 실제 XCUITest 실행과 회귀 진단을 제공한다.
- **S3**: T008~T012, T016이 확인된 불일치와 접근성 터치 영역을 교정하고 회귀를 확인한다.

### 패키지 내부 병렬 실행 예시

- T001이 target 이름을 확정한 뒤 T003과 T005는 서로 다른 파일에서 병렬 실행할 수 있다.
- T006은 T004의 카탈로그 식별자 확정 뒤에 실행한다.
- T010은 T008·T009와 다른 파일이므로 Red 결과 확인 후 병렬 실행할 수 있다.
- T011과 T012는 T009의 `Size` API가 확정된 뒤 서로 다른 파일에서 병렬 실행할 수 있다.

## 구현 전략

1. UI 테스트 실행 기반과 계약 카탈로그를 작성한다.
2. 테스트를 먼저 실행해 현재 불일치를 확인한다.
3. 확인된 계약만 최소 범위로 교정한다.
4. 같은 테스트를 Green으로 만들고 UI 패키지 회귀를 검증한다.
5. 전체 빌드·컴파일·테스트와 시나리오 수용 기준을 읽기 전용으로 확인한다.

## 최소 가치 범위

S1의 계약 체크리스트와 S2의 Red UI 테스트까지가 최소 진단 가치다. 다만 현재 UI 패키지 승인 단위 안에서 S3 교정과 패키지 검증을 완료해야 기능을 완료로 보고할 수 있다.
