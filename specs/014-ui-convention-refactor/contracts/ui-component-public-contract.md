# UIComponent 공개 계약

## 공통 규칙

- public component는 presentation value와 UI 의미 타입을 initializer에 직접 받는다.
- 일회성 interaction은 callback, 즉시 양방향 control만 `Binding`을 사용한다.
- component-scoped `ViewModel`과 initializer 인자를 복제한 `Model`, `Configuration`, `Props`는 public/private 모두 금지한다.
- DesignSystem token, SwiftUI/Foundation 값과 승인된 Lottie 경계 외에 상위 프로젝트 타입을 노출하지 않는다.
- 기존 default, progress clamp, resource mapping, geometry와 accessibility 의미를 보존한다.

## Leaf 계약

| Component | 직접 입력 | 보존할 결과 |
| --- | --- | --- |
| `ActionButton` | title/표시 label 값, `Style`, `Size`, `isEnabled`, action | internal pressing, variant token, size별 surface, 44pt 이상 hit area |
| `ContinuousProgressBar` | progress | `0...1` clamp, track/fill geometry, 접근성 progress 의미 |
| `IconGlassButton` | symbol, 접근성 의미, `Style`, `Size`, action | variant, surface와 44pt hit area |
| `IconPlainButton` | symbol/asset, 접근성 의미, tint/background, size, action | 기존 asset·hit area |
| `ProgressSegments` | completed, total | 범위 처리와 segment geometry |
| `ResourceAnimation` | `Asset`, looping, speed, content mode, completion | Lottie/resource 경계와 Reduce Motion fallback |
| `ResourceImage` | `Asset`, content mode | UIComponent resource bundle과 fallback |
| `ScreenEdgeScrim` | top/bottom 생성 경로 | gradient geometry와 hit-testing 비활성 |
| `StyledText` | text, typography token, color token, alignment | DesignSystem text 적용과 Dynamic Type |
| `TagBadge` | text, `Style` | variant token과 8pt radius |

## Composite 계약

| Component | 직접 입력 | 상태·interaction 규칙 |
| --- | --- | --- |
| `ActionMenu` | `[Item]`, `onSelect(Item.ID)` | stable ID, item별 접근성 의미, callback 1회 |
| `BottomActionBar` | content | 빈 wrapper 없이 content slot 제공 |
| `EmptyState` | title, message, illustration | 읽기 값과 illustration slot |
| `HomeProjectCard` | title, technologies, progress, current set 값, variant, callback | 표시 projection과 start callback |
| `OnboardingMockup` | page/asset 의미 | 기존 page-to-asset mapping |
| `ProjectRow` | name, supporting text, progress, current set 값, deleting, callbacks, thumbnail | route ID 비소유, 상태별 geometry |
| `SavedQuestionCard` | metadata, prompt, action title, callback | 직접 표시 값과 action 전달 |
| `ScreenContainer` | background, content | 기본 background와 content slot |
| `ScreenHeader` | title/subtitle, style, UI 전용 user/control 값, callbacks, avatar | Feature 타입 비노출과 기존 접근성 |
| `SelectionCard` | title, supporting/badge 값, selected, thumbnail | 선택 표현은 직접 값에서 파생 |
| `SelectionCardList` | `[Item]`, 선택값과 selection output | stable ID 기준 선택; 위치/index 상태 금지 |
| `SheetSurface` | content | grabber와 content geometry |
| `TabShell` | selected, `onSelect`, content | controlled contract, `.constant` 금지 |

## 허용 보조 타입

- `Style`, `Size`, `Variant`: 시각 의미와 공개 변형
- `Item`, `Option`: 반복 UI와 stable identity
- `Asset`: UI resource 경계
- `TabShellItem`: generic tab 표현 계약

허용 타입은 Domain/DTO를 복제하거나 initializer 전체를 묶어서는 안 된다.

## Source 및 소비 계약

- production source root: `sources/Projects/UI/Component/Components/{Leaf,Composite}/`
- Preview/Review type과 fixture는 production source root 밖 `sources/Projects/UI/ComponentPreview/`에 둔다.
- UI 내부 Composite, Preview, unit/UI tests와 `#Preview`를 새 직접 입력 계약으로 함께 갱신한다.
- 현재 Feature/App source 소비 지점은 0건이다. 새 소비가 발견되면 UI 단계 밖 파일을 수정하기 전에 적용 패키지와 승인 게이트를 갱신한다.
