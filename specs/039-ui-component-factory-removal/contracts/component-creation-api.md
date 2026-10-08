# 계약: UIComponent 공개 생성 API

**기능**: [spec.md](./../spec.md) | **데이터 모델**: [data-model.md](./../data-model.md)

UI 패키지가 Feature에 공개하는 인터페이스 계약이다. 전환 전후의 공개 표면을 대조해
무엇이 사라지고 무엇이 남는지 확정한다.

## 1. 제거되는 공개 표면 (30개)

전환 후 아래 선언이 하나도 남지 않아야 한다(SC-001).

| 컴포넌트 | 제거 대상 |
| --- | --- |
| `ActionButton` | `primary`×2, `secondary`×2, `destructive`×2, `text`×2, `primaryText`×1 |
| `IconGlassButton` | `neutral`, `accent`, `destructive` |
| `TagBadge` | `neutral`, `accent`, `selected`, `muted` |
| `LabeledCard` | `accent`, `neutral` |
| `ScreenEdgeScrim` | `top`, `bottom` |
| `StyledText` | `headline1`, `headline2`, `subtitle1`, `subtitle2`, `subtitle3`, `body1`, `body2`, `body3`, `caption1`, `caption2` |

`ActionButton`의 변형별 팩토리가 2개씩인 것은 `String`과 `StyledText` 레이블 형태로 나뉘기
때문이다. `primaryText`만 1개다.

## 2. 전환 후 공개 표면

```swift
// Controls/ActionButton.swift
public init(title: String, style: Style = .primary, size: Size = .large,
            isEnabled: Bool = true, action: @escaping () -> Void = { })
public init(styledText: StyledText, style: Style = .primary, size: Size = .large,
            isEnabled: Bool = true, action: @escaping () -> Void = { })
public enum Style { case primary, secondary, destructive, text, primaryText }
public enum Size { case large, medium, small }

// Controls/IconGlassButton.swift
public init(icon: Icon, label: String, style: Style = .neutral, size: Size = .small,
            action: @escaping () -> Void = { })
public enum Style { case neutral, accent, destructive }
public enum Size { case medium, small }

// Displays/TagBadge.swift
public init(text: String, style: Style = .neutral, size: Size = .regular)
public enum Style { case neutral, accent, selected, muted }
public enum Size { case regular, compact }

// Displays/LabeledCard.swift        — init 신규, Style 접근 수준 승격
public init(label: String, text: String, style: Style)
public enum Style { case accent, neutral }

// Displays/StyledText.swift
public init(text: String, style: TextStyleToken, color: ColorToken = .grey100,
            alignment: TextAlignment = .leading)

// Overlays/ScreenEdgeScrim.swift    — init·Edge 모두 신규
public init(edge: Edge, height: CGFloat)
public enum Edge { case top, bottom }
```

## 3. 호출부 전환 대응

| 전환 전 | 전환 후 |
| --- | --- |
| `ActionButton.primary("계속")  { … }` | `ActionButton(title: "계속") { … }` |
| `ActionButton.secondary("취소") { … }` | `ActionButton(title: "취소", style: .secondary) { … }` |
| `IconGlassButton.accent(icon: .x, label: "l") { … }` | `IconGlassButton(icon: .x, label: "l", style: .accent) { … }` |
| `TagBadge.selected("문제 풀기")` | `TagBadge(text: "문제 풀기", style: .selected)` |
| `LabeledCard.accent(label: "l", text: "t")` | `LabeledCard(label: "l", text: "t", style: .accent)` |
| `ScreenEdgeScrim.top(height: 70)` | `ScreenEdgeScrim(edge: .top, height: 70)` |
| `StyledText.body2("문구", color: .grey300)` | `StyledText(text: "문구", style: .body2, color: .grey300)` |

기본 변형(`ActionButton.primary`, `IconGlassButton.neutral`, `TagBadge.neutral`)은 초기화
메서드의 기본값과 같으므로 `style:` 인자를 생략할 수 있다. 생략 여부는 전환 전 호출부가 얻던
값을 바꾸지 않는 선에서 선택한다.

`ScreenEdgeScrim`은 팩토리 이름이 인자로 이동하므로 `height:` 레이블이 유지된다.

## 4. 계약 검증

| 항목 | 검증 방법 |
| --- | --- |
| 팩토리 0개 | 여섯 컴포넌트 파일에서 `public static func` 선언이 없다 |
| 호출부 0건 | `UI`·`Feature`에서 §1 표의 팩토리 호출 표현이 검색되지 않는다 |
| 기본값 단일 선언 | 각 컴포넌트에서 기본값이 초기화 메서드에만 있다 |
| 표현 불변 | 프리뷰와 UI 자동화로 전환 전후 렌더링을 비교한다 |
| compile | 각 작업 단위 커밋이 단독으로 build·compile을 통과한다 |

## 5. 의존 방향

이 계약은 `Feature → UIComponent → DesignSystem` 사용 방향을 바꾸지 않는다
([UI 패키지 규칙](./../../../docs/package-rules/ui.md)). UIComponent는 Feature·Domain·Data·
Composition 타입을 참조하지 않으며, 이번 변경은 UIComponent가 이미 공개하던 타입의 노출
방식만 바꾼다.
