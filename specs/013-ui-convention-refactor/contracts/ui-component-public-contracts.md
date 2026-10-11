# UIComponent 공개 계약

## 공통 규칙

- 모든 읽기 값은 init 또는 factory의 직접 인자다.
- 외부 변경 값은 필수 `Binding`, 일회성 입력은 callback이다.
- `ViewModel`, `State` 또는 동등한 표시 wrapper를 공개·비공개로 정의하지 않는다.
- 기존 geometry, 기본값, 값 정규화와 시각 변형은 별도 변경 근거가 없는 한 유지한다.
- accessibility label·value·trait용 입력과 modifier를 제거한다.

## Leaf 계약

| 컴포넌트 | 직접 입력과 생성 경로 | 보존할 규칙 |
| --- | --- | --- |
| `ActionButton` | `title`, 기존 styled label의 직접 typography 값, `Style`, `Size`, `isEnabled`, `action`; `primary/secondary/destructive/text` factory | 내부 pressing, size별 surface 54/40/36pt, 44pt hit area |
| `ContinuousProgressBar` | `progress` | `0...1` clamp, 6pt track/fill geometry |
| `IconGlassButton` | `symbol`, `Style`, `Size`, `action`; `neutral/accent/destructive` factory | 접근성 전용 `label` 제거, 기존 surface와 44pt hit area |
| `IconPlainButton` | `symbol`, tint/background token, icon/surface size, `action` | 접근성 전용 `label` 제거, 기존 hit area |
| `ProgressSegments` | `completed`, `total` | 기존 범위 처리와 segment geometry |
| `ResourceAnimation` | `Asset`, `isLooping`, `speed`, `contentMode`, `onCompletion` | Lottie와 asset 경계 유지 |
| `ResourceImage` | `Asset`, `contentMode` | UIComponent resource bundle 소유 유지 |
| `ScreenEdgeScrim` | `top()`, `bottom()` | hit testing 비활성, 기존 gradient·height |
| `StyledText` | `text`, `TextStyleToken`, `ColorToken`, `TextAlignment`; typography factory | DesignSystem typography 적용 경로 유지 |
| `TagBadge` | `text`, `Style`; `neutral/accent/selected` factory | 기존 token 조합과 8pt radius |

`ActionButton`은 `StyledText` View를 자식으로 만들지 않고 DesignSystem의 `Text` 적용 API로
문자열을 직접 그려 Leaf 자격을 유지한다.

## Composite 계약

| 컴포넌트 | 직접 입력과 생성 경로 | 외부 입력/상태 규칙 |
| --- | --- | --- |
| `ActionMenu` | `items`, `onSelect`; `Item(id:title:)` | `accessibilityLabel` 제거, 선택 ID callback 1회 |
| `BottomActionBar` | `content` | 빈 wrapper 제거 |
| `EmptyState` | `title`, `message`, `illustration` | 읽기 값만 직접 전달 |
| `HomeProjectCard` | `title`, `technologies`, `progress`, `currentSet`, `setTitle`, `Variant`, `onStart` | variant token과 callback 유지 |
| `OnboardingMockup` | `page` | page 1·2 외 값이 3번 asset으로 수렴하는 기존 규칙 유지 |
| `ProjectRow` | `name`, `supportingText`, `progress`, `currentSet`, `setTitle`, `isDeleting`, `onAccessoryTap`, `thumbnail` | 삭제/기본 geometry와 callback 유지 |
| `SavedQuestionCard` | `metadata`, `prompt`, `actionTitle`, `onActionTap` | 직접 숫자 literal은 중첩 `Constant`로 이동 |
| `ScreenContainer` | `background`, `content` | 기본 `.screenBackground`, dark scheme 소유 유지 |
| `ScreenHeader` | `title`, `subtitle`, `Style`, `User?`, `Control?`, callbacks, optional avatar | `Control`의 접근성 전용 label 제거, 기존 style layout 유지 |
| `SelectionCard` | `title`, `supportingText?`, `badgeText?`, `isSelected`, `thumbnail` | 선택 border는 읽기 값에서 파생 |
| `SelectionCardList` | `items`, `selection: Binding<Item.ID?>` | tap으로 binding 갱신, ID 비교로 card 선택 파생 |
| `SheetSurface` | `content` | 빈 wrapper 제거, grabber·content geometry 유지 |
| `TabShell` | `selection: Binding<Item>`, `content` | `.constant` 제거, 외부 선택 원본과 양방향 연결 |

## 유지하는 보조 타입

- 시각 규칙: `Style`, `Size`, `Variant`
- 리소스 경계: `Asset`
- 반복 항목: `Item`
- 표현 의미: `ScreenHeader.User`, `ScreenHeader.Control`
- 제네릭 제약 때문에 독립 선언이 필요한 `TabShellItem`
- preview-only `TabShellPreviewItem`은 internal로 유지한다.

## 제거 조건

다음 검색은 production Leaf·Composite에서 결과가 없어야 한다.

```sh
rg -n '\b(ViewModel|State)\b' \
  sources/Projects/UI/Component/Components/Leaf \
  sources/Projects/UI/Component/Components/Composite

rg -n '\.accessibility[A-Za-z]*\(' \
  sources/Projects/UI/Component/Components/Leaf \
  sources/Projects/UI/Component/Components/Composite
```
