# 작업 목록: UI 패키지 컨벤션 정본화

**입력**: `/specs/014-ui-convention-refactor/`의 `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**테스트**: 명세 FR-012·FR-013과 SC-007·SC-008이 unit/UI 자동 검증을 명시하므로 테스트 작업을 포함한다.

**구성**: 실제 변경 패키지는 `UI` 하나다. 모든 쓰기 작업은 UI package source·test 또는 UI 변경을 최초로 필요로 하는 공용 Tuist helper·UI 정본 문서에 한정한다. Feature/App는 source 변경 없이 전체 읽기 전용 검증에서 compile boundary만 확인한다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 승인된 UI 패키지 안에서 서로 다른 파일을 대상으로 선행 미완료 의존성이 없을 때만 병렬 실행 가능
- **[S1]**: 일관된 component 공개 계약
- **[S2]**: Preview catalog 탐색과 결정적 fixture
- **[S3]**: 자동화된 UI 계약 검증
- **[S4]**: 정본·target·활성 구현 동기화
- **[no-write]**: 추적 파일을 변경하지 않는 명령 실행, 결과 보고 또는 수동 검증

## 작업 패키지 1: UI

**목표**: component-scoped `ViewModel`을 직접 입력 계약으로 교체하고, Preview 전용 source를 production target에서 분리하며, `UIComponentPreview`를 전체 public component의 결정적 catalog 및 UI test host로 제공한다.

**소유 경로**: 아래 task에 적힌 `sources/Projects/UI/**`, UI 선언만 변경하는 `sources/Tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift`와 `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`, `docs/package-rules/ui.md`, `docs/conventions/ui-component.md`

**관련 변경 시나리오**: S1, S2, S3, S4

**독립 검증**: ViewModel·legacy 이름·금지 dependency·source inclusion 정적 검사 결과가 0건이고, `compile-unit`, `test-unit`, `compile-ui`, `test-ui`가 성공하며 Preview의 23개 public component route와 환경 fixture를 열 수 있다.

### 테스트 — 직접 입력 및 Preview 계약을 먼저 고정

- [ ] T001 [P] [S1] `ui-component-public-contract.md`와 `preview-and-validation-contract.md`를 기준으로 23개 public component 각각의 적용 여부와 assertion 연결을 기계 판독 가능한 테스트 matrix로 명시하고, 적용 항목인 직접 initializer·default parameter, style·size·variant 및 state·range mapping, callback·selection output, accessibility label·value·trait 의미, component-scoped `ViewModel`·동등 aggregate wrapper 부재가 자동 assertion에 연결되지 않으면 실패하며 T062 결과 대조로 대체되지 않는 계약 테스트를 `sources/Projects/UI/Tests/Component/Unit/ComponentDirectInputContractTests.swift`에 작성한다
- [ ] T002 [P] [S1] `selected + onSelect`와 `.constant` 금지, selection callback을 검증하는 실패 테스트를 `sources/Projects/UI/Tests/Component/Unit/TabShellContractTests.swift`에 작성한다
- [ ] T003 [P] [S1] 기존 size·pressed·disabled·destructive·44pt 계약을 직접 입력 API로 검증하도록 `sources/Projects/UI/Tests/Component/Unit/ActionButtonSizeContractTests.swift`를 갱신한다
- [ ] T004 [P] [S1] 직접 `[Item]` 입력, stable ID, accessibility 의미와 callback 1회를 검증하도록 `sources/Projects/UI/Tests/Component/Unit/ActionMenuContractTests.swift`를 갱신한다
- [ ] T005 [P] [S1] 직접 progress 입력, `0...1` clamp, geometry와 접근성 값을 검증하도록 `sources/Projects/UI/Tests/Component/Unit/ContinuousProgressBarContractTests.swift`를 갱신한다
- [ ] T006 [P] [S3] Preview의 23개 stable route와 환경 fixture 접근뿐 아니라 실제 렌더링·접근성 관찰값으로 light/dark appearance 적용, 최대 Dynamic Type·긴 텍스트 계약, Reduce Motion fallback, image·animation failure fallback의 기대 결과를 자동 판정하고 Preview-local 상태 표시는 환경 적용 상태만 노출하며 pass/fail을 계산하지 않고 T057 수동 확인으로 대체되지 않는 실패 UI test를 `sources/Projects/UI/Tests/Component/UI/ComponentPreviewCatalogUITests.swift`에 작성한다
- [ ] T007 [S3] 기존 geometry·44pt interaction·callback·accessibility assertion을 새 Preview route와 직접 입력 계약으로 유지하도록 `sources/Projects/UI/Tests/Component/UI/LayoutContractUITests.swift`를 갱신한다
- [ ] T008 [no-write] [S3] `make tuist`로 T001~T007의 새 test source를 generated project에 반영한 뒤 repository project-build runner의 `compile-unit`, `test-unit`, `compile-ui`, `test-ui`를 실행해 새 직접 입력·Preview 계약의 부재라는 예상 원인으로 실패하는지 기록하고 환경·기존 실패이면 중단한다

### S1 — Leaf component 직접 입력 전환

- [ ] T009 [P] [S1] `ViewModel`을 제거하고 title/label 값, `Style`, `Size`, `isEnabled`, action을 직접 받으며 기존 접근성과 geometry를 보존하도록 `sources/Projects/UI/Component/Components/Leaf/ActionButton.swift`를 갱신한다
- [ ] T010 [P] [S1] `ViewModel`을 제거하고 progress를 직접 받으며 clamp·접근성 progress 의미를 보존하도록 `sources/Projects/UI/Component/Components/Leaf/ContinuousProgressBar.swift`를 갱신한다
- [ ] T011 [P] [S1] `ViewModel`을 제거하고 symbol·접근성 의미·`Style`·`Size`·action을 직접 받도록 `sources/Projects/UI/Component/Components/Leaf/IconGlassButton.swift`를 갱신한다
- [ ] T012 [P] [S1] `ViewModel`을 제거하고 symbol/asset·접근성 의미·색·크기·action을 직접 받도록 `sources/Projects/UI/Component/Components/Leaf/IconPlainButton.swift`를 갱신한다
- [ ] T013 [P] [S1] `ViewModel`을 제거하고 completed와 total을 직접 받으며 기존 범위 처리를 보존하도록 `sources/Projects/UI/Component/Components/Leaf/ProgressSegments.swift`를 갱신한다
- [ ] T014 [P] [S1] `ViewModel`을 제거하고 `Asset`, looping, speed, content mode, completion을 직접 받으며 Reduce Motion fallback 경계를 유지하도록 `sources/Projects/UI/Component/Components/Leaf/ResourceAnimation.swift`를 갱신한다
- [ ] T015 [P] [S1] `ViewModel`을 제거하고 `Asset`과 content mode를 직접 받으며 resource bundle과 fallback을 보존하도록 `sources/Projects/UI/Component/Components/Leaf/ResourceImage.swift`를 갱신한다
- [ ] T016 [P] [S1] `ViewModel`을 제거하고 text·typography·color·alignment를 직접 받으며 Dynamic Type을 보존하도록 `sources/Projects/UI/Component/Components/Leaf/StyledText.swift`를 갱신한다
- [ ] T017 [P] [S1] `ViewModel`을 제거하고 text와 `Style`을 직접 받으며 variant token과 8pt radius를 보존하도록 `sources/Projects/UI/Component/Components/Leaf/TagBadge.swift`를 갱신한다

### S1 — Composite component 직접 입력 전환

- [ ] T018 [P] [S1] `ViewModel`을 제거하고 `[Item]`과 `onSelect(Item.ID)`를 직접 받으며 item 접근성을 보존하도록 `sources/Projects/UI/Component/Components/Composite/ActionMenu.swift`를 갱신한다
- [ ] T019 [P] [S1] 빈 `ViewModel`을 제거하고 content slot만 공개 계약으로 유지하도록 `sources/Projects/UI/Component/Components/Composite/BottomActionBar.swift`를 갱신한다
- [ ] T020 [P] [S1] `ViewModel`을 제거하고 title·message·illustration을 직접 받도록 `sources/Projects/UI/Component/Components/Composite/EmptyState.swift`를 갱신한다
- [ ] T021 [S1] Leaf 직접 입력 계약을 사용해 title·technologies·progress·current set 값·variant·callback을 직접 받도록 `sources/Projects/UI/Component/Components/Composite/HomeProjectCard.swift`를 갱신한다
- [ ] T022 [P] [S1] `ViewModel`을 제거하고 page/asset 의미를 직접 받으며 기존 page-to-asset mapping을 보존하도록 `sources/Projects/UI/Component/Components/Composite/OnboardingMockup.swift`를 갱신한다
- [ ] T023 [S1] Leaf 직접 입력 계약을 사용해 name·supporting text·progress·current set 값·deleting·callbacks·thumbnail을 직접 받도록 `sources/Projects/UI/Component/Components/Composite/ProjectRow.swift`를 갱신한다
- [ ] T024 [S1] Leaf 직접 입력 계약을 사용해 metadata·prompt·action title·callback을 직접 받도록 `sources/Projects/UI/Component/Components/Composite/SavedQuestionCard.swift`를 갱신한다
- [ ] T025 [P] [S1] `ViewModel`을 제거하고 background와 content를 직접 받으며 기본 background를 보존하도록 `sources/Projects/UI/Component/Components/Composite/ScreenContainer.swift`를 갱신한다
- [ ] T026 [S1] Leaf 직접 입력 계약을 사용해 title/subtitle·style·UI 전용 user/control 값·callbacks·avatar를 직접 받으며 기존 접근성을 보존하도록 `sources/Projects/UI/Component/Components/Composite/ScreenHeader.swift`를 갱신한다
- [ ] T027 [S1] `ViewModel`을 제거하고 title·supporting/badge 값·isSelected·thumbnail을 직접 받도록 `sources/Projects/UI/Component/Components/Composite/SelectionCard.swift`를 갱신한다
- [ ] T028 [S1] `SelectionCard` 직접 계약 위에 stable `[Item]`, 외부 선택값과 selection output을 제공하고 위치/index 상태를 제거하도록 `sources/Projects/UI/Component/Components/Composite/SelectionCardList.swift`를 갱신한다
- [ ] T029 [P] [S1] 빈 `ViewModel`을 제거하고 content slot만 공개 계약으로 유지하며 grabber geometry를 보존하도록 `sources/Projects/UI/Component/Components/Composite/SheetSurface.swift`를 갱신한다
- [ ] T030 [S1] `ViewModel`과 `.constant` selection을 제거하고 `selected + onSelect` controlled contract와 content slot을 제공하도록 `sources/Projects/UI/Component/Components/Composite/TabShell.swift`를 갱신한다

### S2 — Preview source 분리와 catalog 구성

- [ ] T031 [P] [S2] stable `componentID`, display name, category, variants, sizes, states와 factory metadata를 정의하는 `sources/Projects/UI/ComponentPreview/Catalog/ComponentPreviewEntry.swift`를 생성한다
- [ ] T032 [P] [S2] appearance·Dynamic Type·긴 텍스트·Reduce Motion·fallback을 결정적으로 선택하는 `sources/Projects/UI/ComponentPreview/Environment/ComponentPreviewEnvironment.swift`를 생성한다
- [ ] T033 [S2] `preview-and-validation-contract.md`의 component별 최소 catalog matrix를 모두 충족하도록 23개 public component의 variant·size·state와 test marker를 local data로 재현하는 `sources/Projects/UI/ComponentPreview/Fixtures/ComponentPreviewFixtures.swift`를 생성한다
- [ ] T034 [P] [S2] production source에서 분리된 internal tab fixture를 `sources/Projects/UI/ComponentPreview/Fixtures/TabShellPreviewItem.swift`에 생성한다
- [ ] T035 [S2] 23개 entry를 Leaf·Composite별로 등록하고 route·fixture·environment를 조립하되 assertion을 포함하지 않는 `sources/Projects/UI/ComponentPreview/Catalog/ComponentPreviewCatalog.swift`를 생성한다
- [ ] T036 [P] [S2] 기존 Review 목록을 직접 입력과 internal 접근 수준으로 이전한 `sources/Projects/UI/ComponentPreview/Catalog/ComponentPreviewCatalogList.swift`를 생성한다
- [ ] T037 [P] [S2] 기존 Review chrome을 Preview 탐색 책임과 internal 접근 수준으로 이전한 `sources/Projects/UI/ComponentPreview/Catalog/ComponentPreviewChrome.swift`를 생성한다
- [ ] T038 [P] [S2] 기존 Review detail을 fixture 표시 책임과 internal 접근 수준으로 이전한 `sources/Projects/UI/ComponentPreview/Catalog/ComponentPreviewDetail.swift`를 생성한다
- [ ] T039 [S2] `ComponentPreviewCatalog`를 실행하고 production service를 초기화하지 않는 `sources/Projects/UI/ComponentPreview/App/UIComponentPreviewApp.swift`를 생성한다
- [ ] T040 [P] [S2] 이전이 완료된 legacy app entry를 `sources/Projects/UI/ComponentLayoutHarness/UIComponentLayoutHarnessApp.swift`에서 제거한다
- [ ] T041 [P] [S2] 이전이 완료된 단일 legacy catalog를 `sources/Projects/UI/ComponentLayoutHarness/LayoutContractCatalog.swift`에서 제거한다
- [ ] T042 [P] [S2] Preview 목록 이전 후 production Review 타입을 `sources/Projects/UI/Component/Components/Review/LayoutReviewCatalogList.swift`에서 제거한다
- [ ] T043 [P] [S2] Preview chrome 이전 후 production Review 타입을 `sources/Projects/UI/Component/Components/Review/LayoutReviewChrome.swift`에서 제거한다
- [ ] T044 [P] [S2] Preview detail 이전 후 production Review 타입을 `sources/Projects/UI/Component/Components/Review/LayoutReviewDetail.swift`에서 제거한다
- [ ] T045 [P] [S2] Preview tab fixture 이전 후 production 포함 파일을 `sources/Projects/UI/Component/Components/Composite/TabShellPreviewItem.swift`에서 제거한다

### S4 — Target graph와 활성 정본 동기화

- [ ] T046 [S4] `UIComponentLayoutHarness` case·app target·source path·UI test dependency를 `UIComponentPreview`와 `ComponentPreview`로 교체하고 bundle identifier를 `com.nexters.hytime.gitit.uicomponentpreview`로 확정하되 UI 선언만 변경하도록 `sources/Tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift`를 갱신한다
- [ ] T047 [S4] `UI`와 `UIUITests` scheme 이름은 유지하고 build/run target 참조만 `UIComponentPreview`로 교체하도록 `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`를 갱신한다
- [ ] T048 [P] [S4] UI 패키지 적용 범위·target 책임·금지 dependency를 직접 입력 API와 `UIComponentPreview` 기준으로 정본화하도록 `docs/package-rules/ui.md`를 갱신한다
- [ ] T049 [P] [S4] component 공개 입력, Preview catalog와 자동 검증 책임을 정본화하고 legacy Harness 표현을 제거하도록 `docs/conventions/ui-component.md`를 갱신한다

### UI 패키지 정리·검증·승인 게이트

- [ ] T050 [no-write] [S4] `make tuist`로 workspace와 generated target graph를 재생성하고 `UIComponentPreview` source inclusion 및 `UI`·`UIUITests` scheme 연결과 함께 `UIComponent`의 project-module dependency가 `DesignSystem`뿐이고 승인된 외부 Lottie 경계만 유지되는지, `UIComponentPreview`의 project-module dependency가 `UIComponent`·`DesignSystem`뿐인지, App·Composition·Feature·Domain·Data·Infrastructure dependency가 0건인지 확인하며 위반 시 UI 단계 완료를 중단한다
- [ ] T051 [no-write] [S1] generated target/module inventory와 `rg`·source review로 `sources/Projects/UI/Component`, `sources/Projects/UI/ComponentPreview` 전체에서 `ComposableArchitecture` 및 App·Composition·Feature·Domain·Data·Infrastructure 패키지가 소유한 모든 module의 import 결과와 Leaf·Composite production source의 `ViewModel|viewModel:` 및 initializer를 복제한 `Model|Configuration|Props` 결과가 각각 0건인지 확인하고, Feature/App/sample/활성 문서 예시의 legacy consumer를 전수 검색해 금지 import 또는 legacy consumer 발견 시 UI 단계 완료를 중단하며 후자는 패키지 범위를 갱신한다
- [ ] T052 [no-write] [S2] production public View 23개와 Preview catalog `componentID` 등록 집합의 차이가 0건이고 각 entry가 계약의 component별 최소 variant·size·state matrix를 충족하며 Preview source가 UIComponent generated source 목록에 포함되지 않았는지 확인한다
- [ ] T053 [no-write] [S4] 활성 UI source·Tuist helper·CI·scheme·`docs/package-rules/ui.md`·`docs/conventions/ui-component.md`에서 `UIComponentLayoutHarness|ComponentLayoutHarness|LayoutContractCatalog` 결과가 0건이고 별도 test plan이 없다는 기준선이 유지되는지 확인한다
- [ ] T054 [no-write] [S3] repository project-build runner의 `compile-unit`과 `test-unit`을 순서대로 실행해 UIComponent 직접 입력·상태·callback·접근성 계약의 build-for-testing과 test body 결과를 구분해 기록한다
- [ ] T055 [no-write] [S3] repository project-build runner의 `compile-ui`와 `test-ui`를 순서대로 실행해 Preview route·geometry·interaction·환경·접근성 UI test의 build-for-testing과 test body 결과를 구분해 기록한다
- [ ] T056 [no-write] [S3] `GIT_IT_SWIFT_FORMAT_RUNNER`의 `lint` 공개 명령으로 현재 변경 Swift 파일의 format·lint required gate를 실행하고 결과를 기록한다
- [ ] T057 [no-write] [S2] `UI` scheme으로 `UIComponentPreview`를 실행해 23개 component와 공개 variant·size·주요 state·환경 fixture를 네트워크 없이 탐색하고 Preview에 pass/fail 판정 UI가 없음을 수동 확인하되 T006·T007의 자동 assertion을 대체하지 않는다
- [ ] T058 [no-write] UI 패키지 변경 파일, S1~S4 검증 결과, 미검증 범위와 예외를 사용자에게 보고하고 UI 단계 완료에 대한 명시적 승인을 받은 뒤 중단한다

**승인 게이트**: T001~T058의 구현·검증·결과 보고가 모두 완료돼야 한다. 이 명세에는 다음 적용 패키지가 없으므로 T058 승인 전에는 전체 완료 검증을 실행하지 않는다. 검증 중 Feature/App 또는 다른 패키지 파일 수정이 필요해지면 작업을 중단하고 `/speckit-tasks`로 적용 패키지와 순서를 갱신한다.

---

## 전체 완료 검증

**선행 조건**: UI 패키지 T001~T058 완료와 사용자 승인. 아래 작업은 어떤 추적 파일도 변경하지 않는다.

- [ ] T059 [no-write] [S4] repository project-build runner의 `build`를 실행해 모든 shared scheme production build와 Feature/App compile 전이를 확인하고 실제 결과를 기록한다
- [ ] T060 [no-write] [S3] 동일 DerivedData 흐름에서 repository project-build runner의 `compile`을 실행해 모든 test scheme build-for-testing 결과를 기록한다
- [ ] T061 [no-write] [S3] T060 성공 뒤 repository project-build runner의 `test`를 실행해 unit/UI test body 결과를 기록하고 Simulator·destination 실패를 테스트 통과로 판정하지 않는다
- [ ] T062 [no-write] [S1] public component 23개 전체에서 직접 입력·default·style/size/variant·state/range·callback/Binding·금지 wrapper·접근성·geometry 수용 기준이 충족됐는지 계약과 자동 테스트 결과를 대조하되 T001~T007의 자동 assertion을 대체하지 않는다
- [ ] T063 [no-write] [S2] Preview catalog 등록률 100%, local deterministic fixture, Preview 도달성과 GitIt App 도달성의 별도 판정이 충족됐는지 결과를 대조한다
- [ ] T064 [no-write] [S4] S1~S4 성공 기준, 활성 문서·target·source 일치, 미해결 legacy 참조 0건과 미검증 범위를 최종 보고한다

## 의존성과 실행 순서

### 패키지 순서와 승인 게이트

- 적용 패키지는 `UI` 하나다. Domain, Data, Infrastructure, Composition, Feature, App은 변경하지 않는다.
- T001~T007로 실패하는 계약 검증을 먼저 작성하고, T009~T030 직접 입력 구현, T031~T045 Preview 분리, T046~T049 target·문서 동기화 순으로 진행한다.
- UI package implementation과 T050~T057 검증을 완료하고 T058에서 결과를 보고한 뒤 반드시 사용자 승인을 기다린다.
- UI 승인 뒤에만 T059~T064 전체 읽기 전용 검증을 실행한다.

### 변경 시나리오 완료 순서

```text
S1 직접 입력 공개 계약
 ├─→ S2 Preview catalog와 fixture
 └─→ S3 unit/UI 자동 검증
S2 + S3 ─→ S4 target·문서 동기화 및 전체 완료 판정
```

- **S1 독립 검증**: 23개 public component에서 ViewModel·동등 wrapper 0건, direct initializer compile, callback/Binding 및 기존 접근성·geometry 보존.
- **S2 독립 검증**: Preview에서 23개 component와 모든 공개 variant·size·주요 state를 local fixture로 열고 production source inclusion 0건 확인.
- **S3 독립 검증**: unit/UI test가 public API, 상태, geometry, interaction, 접근성 및 환경 계약을 자동 판정하고 Swift lint가 통과하며 Preview에는 assertion이 없음.
- **S4 독립 검증**: active source·Tuist·scheme·문서의 legacy 이름 0건, generated target graph와 전체 build/compile/test 성공.

### UI 패키지 내부 병렬 실행 예시

- T001~T006은 서로 다른 test 파일이므로 병렬 작성할 수 있으며 T007은 기존 UI test 충돌을 피하기 위해 단독 수행한다.
- T009~T017은 서로 다른 Leaf 파일이므로 병렬 가능하다. 단 `ActionButton`의 `StyledText` 사용을 바꾸는 경우 T016 계약을 먼저 확정한다.
- T018~T030 중 독립 Composite는 `[P]` 항목만 병렬 수행하고, T021·T023·T024·T026는 Leaf 직접 입력 계약 뒤, T028은 T027 뒤, T030는 T002 뒤 수행한다.
- T031과 T032은 병렬 가능하며, T033~T039은 entry/environment 계약 뒤 진행한다.
- T040~T045는 대응 Preview source 생성과 참조 전환을 확인한 뒤 같은 패키지 안에서 병렬 제거할 수 있다.
- T048과 T049은 서로 다른 UI 문서이므로 병렬 가능하지만 T046·T047의 확정 target 이름을 사용한다.

## 구현 전략

1. T001~T007의 계약 테스트를 작성하고 T008에서 기존 ViewModel/legacy Preview 구조 때문에 예상대로 실패하는지 확인한다.
2. S1의 Leaf와 Composite를 직접 입력 계약으로 전환해 unit contract를 통과시킨다.
3. S2의 catalog·fixture·environment를 만들고 Preview 전용 source를 production target에서 제거한다.
4. S4의 Tuist graph와 UI 정본 문서를 같은 UI 단계에서 동기화한다.
5. T050~T057로 UI 범위를 검증하고 T058에서 결과를 보고한 뒤 승인을 기다린다.
6. 승인 후 T059~T064의 전체 읽기 전용 검증으로 기능을 완료한다.

## 최소 가치 범위

최소 가치 범위는 S1의 직접 입력 공개 계약과 이를 입증하는 unit test지만, production source inclusion과 target graph가 깨지지 않도록 UI 패키지 단계 T001~T058 및 승인 게이트를 생략할 수 없다. S2~S4를 제외한 상태를 기능 완료로 판정하지 않는다.

## 참고

- 작업 ID는 실행 순서대로 증가한다.
- `[P]`는 UI 패키지 승인 범위 안에서만 적용한다.
- source 이동은 새 경로 생성과 기존 경로 제거를 별도 task로 나눠 `/speckit-implement` allowlist를 명확히 했다.
- `docs/spec-kit/014-ui-convention-refactor/trouble-shooting.md`와 `tacit-knowledge.md`는 구현 작업이 아니며 실제 기록 조건이 발생한 세션에서 전용 스킬만 갱신한다.
