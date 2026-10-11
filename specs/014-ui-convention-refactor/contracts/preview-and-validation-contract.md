# UIComponentPreview 및 검증 계약

## Target 계약

| 항목 | 계약 |
| --- | --- |
| target | `UIComponentPreview` application |
| source directory | `sources/Projects/UI/ComponentPreview/` |
| bundle identifier | `com.nexters.hytime.gitit.uicomponentpreview` |
| project dependencies | `UIComponent`, `DesignSystem` |
| product dependencies | Feature, App, Domain, Data, Infrastructure, Composition 0건 |
| UI test host | `UIComponentUITests → UIComponentPreview` |
| shared schemes | `UI`, `UIUITests` 이름 유지 |
| network/credential | 사용하지 않음 |

bundle identifier와 표시명은 repository naming pattern에 맞춰 Preview 책임을 표현하며 production identifier로 취급하지 않는다.

## Catalog 계약

- public View 23개를 모두 등록한다.
- 각 entry는 고유 `componentID`, display name, Leaf/Composite category, 공개 variant·size·state와 factory를 가진다.
- `ComponentPreviewCatalog`는 탐색과 재현만 담당하고 assertion이나 pass/fail UI를 제공하지 않는다.
- Review catalog/chrome/detail과 `TabShellPreviewItem`은 internal Preview source다.
- 파일 단위 `#Preview`는 중앙 catalog 등록을 대체하지 않는다.

### Component별 최소 catalog matrix

| Component | 최소 variant·size·state fixture |
| --- | --- |
| `ActionButton` | 모든 `Style`, 모든 `Size`, enabled, disabled, pressing |
| `ContinuousProgressBar` | 0, 중간, 1, 범위 밖 clamp |
| `IconGlassButton` | 모든 `Style`, 모든 `Size`, enabled |
| `IconPlainButton` | 기본 asset/symbol, enabled |
| `ProgressSegments` | empty, partial, complete, 범위 밖 |
| `ResourceAnimation` | supported asset, looping, completion, Reduce Motion fallback |
| `ResourceImage` | supported asset, content mode, fallback |
| `ScreenEdgeScrim` | top, bottom, pass-through |
| `StyledText` | typography/color/alignment, 긴 텍스트, 최대 Dynamic Type |
| `TagBadge` | 모든 `Style`, 긴 텍스트 |
| `ActionMenu` | 전체 item, selection callback, 긴 텍스트 |
| `BottomActionBar` | content slot |
| `EmptyState` | title/message/illustration, 긴 텍스트 |
| `HomeProjectCard` | 모든 `Variant`, progress 상태, callback |
| `OnboardingMockup` | 모든 supported page/asset mapping |
| `ProjectRow` | default, deleting, progress, callback, 긴 텍스트 |
| `SavedQuestionCard` | metadata/prompt/action, 긴 텍스트 |
| `ScreenContainer` | 기본/명시 background와 content |
| `ScreenHeader` | 모든 `Style`, user/control/avatar 조합, callbacks |
| `SelectionCard` | selected, unselected, optional text/thumbnail |
| `SelectionCardList` | nil selection, item selection, external update, reorder |
| `SheetSurface` | grabber와 content slot |
| `TabShell` | 각 item 선택, user selection callback, parent update |

## Environment 계약

| 환경 | 재현 요구 |
| --- | --- |
| appearance | 지원하는 light/dark 상태 |
| Dynamic Type | 기본과 최대 접근성 크기 |
| long text | title/supporting text overflow 및 scroll |
| Reduce Motion | animation fallback |
| fallback | image/animation failure 또는 대체 표현 |

모든 환경은 launch argument 또는 Preview-local control로 결정적으로 선택할 수 있어야 한다.

## 자동 검증 책임

### UIComponentTests

- 직접 initializer와 default parameter
- style/size/variant 및 resource mapping
- progress/range clamp와 상태 파생
- callback/selection output
- accessibility label/value/trait 의미
- component-scoped ViewModel 및 금지 dependency 부재
- production public component의 직접 입력 API coverage

### UIComponentUITests

- 기존 frame, inset, spacing, radius와 pixel geometry
- 최소 44×44pt interaction 영역
- tap, disabled 차단, selection과 pass-through
- 접근성 element grouping, label/value/trait
- 최대 Dynamic Type, 긴 텍스트와 scrollability
- light/dark appearance, Reduce Motion와 fallback
- catalog에 등록된 23개 public component route의 접근 가능성

### 구조 검증

- active source, Tuist, scheme, CI와 문서의 `UIComponentLayoutHarness` 참조 0건
- Preview source가 UIComponent generated source 목록에 포함된 건수 0건
- UIComponent/Preview의 금지 프로젝트 import와 target dependency 0건
- production public View 목록과 catalog registration 목록의 차이 0건
- Feature/App source, sample과 활성 문서 Swift 예시의 legacy consumer 0건
- 변경 Swift 파일의 `GIT_IT_SWIFT_FORMAT_RUNNER` lint 성공
- Feature/App source 변경 0건을 유지하되 전체 build로 compile boundary 확인

## 결과 판정

- Preview에서 보인다는 사실은 test 통과나 GitIt App 도달성을 의미하지 않는다.
- `build`, `build-for-testing`, `test-without-building` 성공을 각각 구분해 보고한다.
- Simulator 또는 destination 문제로 test body가 실행되지 않으면 테스트 통과로 기록하지 않는다.
