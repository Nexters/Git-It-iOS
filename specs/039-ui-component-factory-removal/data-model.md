# 데이터 모델: UIComponent 변형 축

**기능**: [spec.md](./spec.md) | **조사**: [research.md](./research.md)

이 기능은 저장 데이터를 다루지 않는다. 여기서 모델링하는 대상은 각 컴포넌트가 공개하는
**변형 축 enum**과 그 축을 받는 **공개 생성 경로**다.

## 1. 변형 축

변형 축은 한 컴포넌트가 가질 수 있는 시각 변형의 집합을 나타내는 `enum`이다. 소유 컴포넌트에
중첩하고 이름에 컴포넌트 이름을 반복하지 않는다
([View 내부 선언](../../docs/conventions/view-declarations/internal-declarations.md)).

| 컴포넌트 | 축 | case | 전환 전 접근 수준 | 전환 후 접근 수준 |
| --- | --- | --- | --- | --- |
| `ActionButton` | `Style` | `primary`, `secondary`, `destructive`, `text`, `primaryText` | `public` | `public`(유지) |
| `ActionButton` | `Size` | `large`, `medium`, `small` | `public` | `public`(유지) |
| `IconGlassButton` | `Style` | `neutral`, `accent`, `destructive` | `public` | `public`(유지) |
| `IconGlassButton` | `Size` | `medium`, `small` | `public` | `public`(유지) |
| `TagBadge` | `Style` | `neutral`, `accent`, `selected`, `muted` | `public` | `public`(유지) |
| `TagBadge` | `Size` | `regular`, `compact` | `public` | `public`(유지) |
| `LabeledCard` | `Style` | `accent`, `neutral` | **`private`** | **`public`로 승격** |
| `ScreenEdgeScrim` | `Edge` | `top`, `bottom` | **없음** | **신규 `public`** |
| `StyledText` | `TextStyleToken` | DesignSystem 소유(컴포넌트 중첩 아님) | `public` | `public`(유지) |

`StyledText`의 축만 컴포넌트가 아니라 DesignSystem이 소유한다. `TextStyleToken`은 자간·행간·
언어별 폰트 선택을 함께 결정하는 토큰이므로 컴포넌트에 중첩하지 않는다.

### 1.1 `ScreenEdgeScrim.Edge` (신규)

- 소유: `ScreenEdgeScrim`에 중첩, 같은 파일
- case: `top`, `bottom`
- 책임: case마다 대응하는 `GradientToken`(`.topEdgeScrim`, `.bottomEdgeScrim`)을 소유한다.
  View는 `edge.gradientToken`처럼 결과만 읽고 `body`에서 `switch`하지 않는다
  ([`Style`](../../docs/conventions/view-declarations/style.md)).
- 이름 근거: [research.md §3](./research.md)

### 1.2 `LabeledCard.Style` (접근 수준 승격)

- case와 토큰 매핑은 그대로 유지한다. 변경은 접근 수준뿐이다.
- 승격 이유: 팩토리가 사라지면 이 축이 유일한 변형 선택 수단이 되므로 호출부에서 참조
  가능해야 한다.

## 2. 공개 생성 경로

전환 후 각 컴포넌트가 공개하는 생성 경로다. 정적 팩토리는 남기지 않는다.

| 컴포넌트 | 전환 후 공개 생성 경로 | 신규 여부 |
| --- | --- | --- |
| `ActionButton` | `init(title:style:size:isEnabled:action:)`, `init(styledText:style:size:isEnabled:action:)` | 기존 유지 |
| `IconGlassButton` | `init(icon:label:style:size:action:)` | 기존 유지 |
| `TagBadge` | `init(text:style:size:)` | 기존 유지 |
| `LabeledCard` | `init(label:text:style:)` | **신규** |
| `ScreenEdgeScrim` | `init(edge:height:)` | **신규** |
| `StyledText` | `init(text:style:color:alignment:)` | 기존 유지 |

`ActionButton`의 두 초기화 메서드는 시각 변형이 아니라 레이블 입력 형태가 다르므로 둘 다
유지한다([research.md §5](./research.md)).

## 3. 기본값

기본값은 전환 후 초기화 메서드 한 곳에만 선언한다(FR-002). 전환 전에는 초기화 메서드와 팩토리
양쪽에 중복돼 있다.

| 컴포넌트 | 기본값을 가진 인자 |
| --- | --- |
| `ActionButton` | `style = .primary`, `size = .large`, `isEnabled = true`, `action = { }` |
| `IconGlassButton` | `style = .neutral`, `size = .small`, `action = { }` |
| `TagBadge` | `style = .neutral`, `size = .regular` |
| `StyledText` | `color = .grey100`, `alignment = .leading` |
| `LabeledCard` | 없음(신규 초기화 메서드에도 두지 않는다) |
| `ScreenEdgeScrim` | 없음(`edge`와 `height` 모두 호출부가 지정) |

**검증 규칙**: 전환 시 호출부가 실제로 얻던 값을 유지해야 한다. 팩토리와 초기화 메서드의
기본값이 다르면 전환 전 값을 정본으로 삼는다(명세 예외·경계 사례).

## 4. 대상이 아닌 선언

생성 팩토리가 아니라 값을 변환해 돌려주는 계산이므로 이 기능이 건드리지 않는다(FR-009).

- `Scaffolds/TabShell/TabShellItem.swift`의 `tabColor(isSelected:)` — `ColorToken` 반환
- `Displays/ResourceImage.swift`의 `resizable(_:)` — `Image` 반환
