# 데이터 모델: UI 컴포넌트 초기화 계약 재구성

**명세**: [spec.md](./spec.md) | **조사**: [research.md](./research.md)

이 기능은 저장 데이터를 다루지 않는다. 여기서 "엔터티"는 명세 핵심 엔터티에 대응하는 공개 타입과
컴포넌트의 입력 구성이다. 공개 시그니처는 [contracts/component-init-contracts.md](./contracts/component-init-contracts.md)가
정본이다.

## 1. 시각 속성 계약

| 필드 | 형태 | 규칙 |
| --- | --- | --- |
| 이름 | `StyleConfigurable`, `SizeConfigurable`, `TextStyleConfigurable`, `ForegroundColorConfigurable`, `BackgroundColorConfigurable` | 종류는 값의 타입이 아니라 역할로 구분한다(FR-004) |
| 정제 대상 | `View` | 채택자는 View다 |
| 속성 타입 | 스타일·크기: `associatedtype`, 나머지: DesignSystem 토큰 고정 | 컴포넌트마다 다른 `Style`·`Size`를 허용한다 |
| 요구사항 | 선언 메서드 하나, `-> Self` | 공개 프로퍼티 요구사항을 두지 않는다(FR-008) |
| 위치 | `sources/Projects/UI/Component/Contracts/<계약>.swift` | 파일 하나에 계약 하나 |

관계: 컴포넌트 하나가 계약 0~3개를 채택한다. 채택 목록은 [research.md](./research.md) §3에 있다.
`IconPlainButton`은 전경색과 배경색 계약을 함께 채택한다. `ActionButton`·`TagBadge`·`IconGlassButton`은
스타일과 크기 계약을 함께 채택한다.

## 2. 시각 속성 값

| 컴포넌트 | 저장 프로퍼티(전환 후) | 타입 | 기본값 |
| --- | --- | --- | --- |
| `StyledText` | `textStyle` | `TextStyleToken` | `.body1`(신규) |
| | `foregroundColor` | `ColorToken` | `.grey100` |
| `ActionButton`, `FeedbackActionButton` | `style` / `size` | `ActionButton.Style` / `ActionButton.Size` | `.primary` / `.large` |
| `TagBadge` | `style` / `size` | `TagBadge.Style` / `TagBadge.Size` | `.neutral` / `.regular` |
| `IconGlassButton` | `style` / `size` | `IconGlassButton.Style` / `IconGlassButton.Size` | `.neutral` / `.small` |
| `ContinuousProgressBar` | `size` | `ContinuousProgressBar.Height` | `.row` |
| `LabeledCard` | `style` | `LabeledCard.Style` | `.neutral`(신규) |
| `IconPlainButton` | `foregroundColor` / `backgroundColor` | `ColorToken` | `.white` / `.clear` |
| `LabeledProgressBar` | `foregroundColor` | `ColorToken` | `.grey400` |
| `SelectionCard` | `style` | `SelectionCardStyle` | 썸네일 경로 `.detailed`, `Thumbnail == EmptyView` 경로 `.compact`(기존 동작 유지, [research.md](./research.md) §4.6) |
| `SelectionCardList` | `style` | `SelectionCardStyle` | `.detailed` |
| `HomeProjectCard` | `style` | `HomeProjectCard.Style`(이전 `Variant`) | `.purple`(신규) |
| `ScreenContainer` | `backgroundColor` | `ColorToken` | `.grey700` |
| `OverlayContainer` | `screenBackground` | `ColorToken` | `.grey700` |

- 저장 프로퍼티는 모두 `private var`이며 초기화 메서드가 인자로 받지 않는다. 예외는 경로마다 고정값이
  다른 `SelectionCard`의 EmptyView 경로 하나이며, 그 경로의 초기화 메서드가 `.compact`를 대입한다.
- 값별 렌더링 대응(`style.titleColor(...)` 등)은 기존 속성 타입이 계속 소유한다(FR-013).
- 저장 프로퍼티 이름은 역할 이름이다. 기존 이름(`tintColor`, `valueColor`, `background`, `variant`,
  `height`)은 전환 단위 안에서 표의 이름으로 바꾼다. 비공개 이름이라 공개 계약에 영향이 없다.
  `OverlayContainer.screenBackground`는 기존 이름을 유지한다. 이 컨테이너에서는 배경 View
  (`background`)와 구분해야 해서, `screenBackground`가 이미 역할을 드러낸다.
- `StyledText`는 `public let` 저장 프로퍼티(`text`, `style`, `color`, `alignment`)를 공개하고 있었다.
  전환 뒤에는 `text`만 공개로 남긴다. 텍스트 스타일과 전경색은 비공개로 두고, `alignment`는 없앤다.
  `Equatable` 합성은 유지된다.

상태 전이: 없음. 값 타입 복사로만 바뀌며, 같은 속성을 여러 번 선언하면 마지막 값이 남는다(FR-006).

## 3. 표시 값 모델

| 필드 | 형태 | 규칙 |
| --- | --- | --- |
| 이름 | `{컴포넌트}.DisplayModel` | 소유 컴포넌트에 중첩한다. 컴포넌트 이름을 반복하지 않는다 |
| 선언 | `public struct DisplayModel: Sendable, Equatable` | 명시적 `public init`을 둔다 |
| 필드 | 표시 값만 | 상태·동작 설정·접근성 문구·식별자·`Binding`·콜백·자식 View·시각 속성은 담지 않는다(FR-015) |
| 기본값 | 기존 초기화 인자의 기본값을 그대로 옮긴다 | 예: `supportingText: String? = nil` |
| 위치 | 소유 컴포넌트 파일의 `extension {컴포넌트}` | 중첩 값 타입(`SelectionCardList.Item`)은 그 타입 파일(`+Item.swift`) |
| 컴포넌트 저장 | `private let displayModel: DisplayModel` | `body`는 `displayModel.title`처럼 읽는다 |

대상과 필드 목록은 [research.md](./research.md) §1.3의 표가 정본이다. 대상은 컴포넌트 20개와
`SelectionCardList.Item`이다.

### 관계와 변환

- `SelectionCardList.Item.DisplayModel` → `SelectionCard.DisplayModel`: `SelectionCardList`가 `body`에서
  만든다. `title`과 `supportingText`를 옮기고 `badgeText`는 기존처럼 넘기지 않는다(기본값 `nil`).
  `illust`는 썸네일 경로에서만 쓴다.
- Feature 업무 모델 → `DisplayModel`: Feature View가 컴포넌트 호출 지점에서 만든다.
  - 매핑 대상 예: `HomeProjectDisplay` → `HomeProjectCard.DisplayModel`, `ProjectSummary` →
    `ProjectRow.DisplayModel`
  - Feature State, Reducer, State에 담기는 `ViewModels/` 타입은 `DisplayModel`을 보유하거나 만들지
    않는다(명확화, SC-008).

## 4. 대상 컴포넌트(전환 후 공개 계약 구성)

```text
공개 계약 = init(displayModel? | 표시 값 1개 이하, 상태…, 동작 설정…, 접근성 문구…, Binding…, 콜백…, 자식 View…)
          + 채택한 시각 속성 계약의 메서드
```

검증 규칙:

- 초기화 메서드에 시각 속성 인자가 0개다(SC-001).
- 표시 값이 2개 이상이면 개별 표시 값 인자가 0개이고 `displayModel` 하나만 받는다(SC-008).
- 생성 경로는 초기화 메서드뿐이다. 정적 팩토리나 두 번째 선언 경로가 없다(FR-008, 039 원칙).
  `SelectionCard`와 `OverlayContainer`의 제네릭 조건부 생성 경로는 자식 View 형태에 따른
  분기이므로 유지한다.

## 5. 상태 `Binding`(FR-017)

| 필드 | 형태 | 규칙 |
| --- | --- | --- |
| 대상 | 컴포넌트가 상호작용으로 스스로 바꾸는 상태 | 목록과 쓰기 값은 [research.md](./research.md) §9.1이 정본이다 |
| 선언 | 초기화 인자 `Binding<Value>`, 저장 `@Binding private var` | 기본값을 두지 않는다. `.constant(...)`는 프리뷰·테스트에서만 넘긴다 |
| 짝 콜백 | 제거 | 그 상태를 바꾸는 용도의 콜백만 제거한다. 동작 콜백(`onOpenLink`·`onActionTap` 등)은 남는다 |
| 위치 | 표시 값 모델 밖의 개별 인자 | `displayModel` 뒤, 기존 상태 인자 자리에 둔다 |
| Feature 생성 | 화면 View의 `Binding(get:set:)` | setter는 제거된 콜백이 보내던 기존 View Action을 보낸다. Action·Reducer·State는 `Binding`을 보유하지 않는다 |

관계:
- `SelectionCardList.selection: Binding<String?>` ↔ `SelectionCardList.Item.id`: 카드 탭은 그 항목의
  `id`를 쓴다. 카드의 선택 표시는 `selection.wrappedValue == item.id`로 계산해 `SelectionCard`의 값
  인자 `isSelected`로 넘긴다. `SelectionCard`는 값 인자를 유지한다.
- `ChoiceAnswerOption.ExpansionControl.toggleable(isExpanded: Binding<Bool>)`: 펼침 버튼과 접근성
  동작이 `toggle()`한다. `.fixed(isExpanded:)`는 값이다.

상태 전이: 컴포넌트는 `wrappedValue`를 한 번 쓰고, 화면은 Store 값이 바뀐 뒤에 갱신된다. Feature
setter가 Action을 보내지 않으면 값은 그대로다(명세 예외·경계 사례).
