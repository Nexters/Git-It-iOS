# 컴포넌트의 공개 생성 경로는 초기화 메서드 하나입니다

[Git It iOS View 컨벤션](../view.md)의 규칙 문서입니다.

컴포넌트가 공개하는 생성 경로는 `init` 하나뿐입니다. 초기화 메서드는 다음만 받습니다.

- 표시 값: 2개 이상이면 컴포넌트에 중첩한 `DisplayModel` 하나로 받습니다.
- 상태: 컴포넌트가 스스로 바꾸는 상태는 변경 콜백 대신 기본값 없는 `Binding`으로 받습니다.
- 값으로 받는 상태·동작 설정: 초기화 인자가 아니라 `enabled(_:)` 같은 `Self` 반환 상태 선언
  메서드로 선언합니다. 기본값이 없는 필수 상태만 초기화 인자로 받습니다.
- 화면에 보이지 않는 접근성 문구
- 상태 변경과 무관한 동작 콜백
- 자식 View: `@ViewBuilder`로 받는 컴포넌트는 `init(..., content:)`를 생성 경로로 둡니다.

인자 구분과 기본값은 [표시 값, Binding과 콜백](./display-value-binding-callback.md)을 따릅니다.

## 시각 속성은 계약 메서드로 선언합니다

스타일·크기·텍스트 스타일·전경색·배경색 같은 시각 속성은 초기화 인자로 받지 않습니다. 속성 종류마다
`sources/Projects/UI/Component/Contracts/`의 계약을 채택하고, 계약이 정한 `Self` 반환 메서드로
선언합니다.

| 계약 | 메서드 |
|---|---|
| `StyleConfigurable` | `style(_:)` — 컴포넌트의 `Style` |
| `SizeConfigurable` | `size(_:)` — 컴포넌트의 `Size` |
| `TextStyleConfigurable` | `textStyle(_:)` — `TextStyleToken` |
| `ForegroundColorConfigurable` | `foregroundColorToken(_:)` — `ColorToken` |
| `BackgroundColorConfigurable` | `backgroundColorToken(_:)` — `ColorToken` |

- 시각 속성은 `private var style = Style.neutral`처럼 기본값을 가진 저장 프로퍼티로 둡니다. 모든 시각
  속성은 기본값을 가지며, 기본값은 호출부 최빈값이 아니라 디자인 시스템의 중립·기본 값(텍스트는 본문
  스타일, enum은 기본 case)으로 고릅니다.
- 메서드는 `var copy = self`로 사본을 만들고 그 속성 하나만 바꿔 반환합니다. 표시 값·상태·콜백·다른
  시각 속성은 그대로입니다.
- 서로 다른 속성 메서드는 호출 순서와 무관하게 같은 결과를 내고, 같은 속성을 여러 번 호출하면 마지막
  값이 남습니다.
- 시각 속성 메서드는 SwiftUI 일반 수정자보다 먼저 호출합니다. 일반 수정자 뒤에서는 반환 타입이
  컴포넌트가 아니므로 컴파일되지 않습니다.
- 같은 속성을 선언하는 두 번째 경로(초기화 인자, 변형마다 이름을 부여한 `public static func`
  팩토리, 별도 래퍼)를 두지 않습니다. 시각 토큰 묶음은 호출부가 나열하지 않고 `Style`이 소유합니다.

## 예시

```swift
// Feature 호출부의 정본: store는 UI 컴포넌트 내부가 아니라 호출부에만 존재합니다.
StyledText(text: "제목")
    .textStyle(.subtitle1)
    .foregroundColorToken(.grey400)
    .multilineTextAlignment(.center)
ActionButton(title: "계속하기") { send(.continueTapped) }
    .style(.secondary)
    .size(.medium)
LabeledCard(displayModel: .init(label: "AI 해설", text: explanation))
    .style(.accent)
BookmarkButton(
    isSaved: Binding(get: { store.isBookmarked }, set: { _ in send(.bookmarkToggleTapped) }),
    accessibilityLabel: label,
)

// 사용하지 않습니다
ProjectRow(project: project)
ActionButton(title: "계속하기", style: .secondary, size: .medium) { send(.continueTapped) }
BookmarkButton(isSaved: store.isBookmarked, accessibilityLabel: label, onTap: { send(.bookmarkToggleTapped) })
```

초기화 메서드는 Feature 모델을 그대로 받지 않습니다. 기본값과 인자 순서는 초기화 메서드와 시각 속성
저장 프로퍼티 한 곳에만 선언합니다. 변형 enum의 case 이름은 특정 Feature의 업무 역할이 아니라
`neutral`, `accent`, `destructive`처럼 UI 패키지에서 독립적으로 해석할 수 있는 시각 의미를 사용합니다.
