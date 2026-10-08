# 계약: UIComponent 공개 초기화 계약과 시각 속성 계약

**명세**: [spec.md](../spec.md) | **데이터 모델**: [data-model.md](../data-model.md) | **조사**: [research.md](../research.md)

이 문서는 전환 뒤 UIComponent의 공개 API를 정한다. 필드의 타입과 기본값은 명시한 경우를 빼고 현재
초기화 인자의 타입과 기본값을 그대로 옮긴다. 구현 본문은 담지 않는다.

## 1. 시각 속성 계약

위치: `sources/Projects/UI/Component/Contracts/`. 파일 하나에 계약 하나를 둔다.

```swift
public protocol StyleConfigurable: View {
    associatedtype Style
    func style(_ style: Style) -> Self
}

public protocol SizeConfigurable: View {
    associatedtype Size
    func size(_ size: Size) -> Self
}

public protocol TextStyleConfigurable: View {
    func textStyle(_ textStyle: TextStyleToken) -> Self
}

public protocol ForegroundColorConfigurable: View {
    func foregroundColorToken(_ color: ColorToken) -> Self
}

public protocol BackgroundColorConfigurable: View {
    func backgroundColorToken(_ color: ColorToken) -> Self
}
```

모든 채택자에게 다음 규칙을 적용한다.

- 반환값은 호출한 속성만 바뀐 사본이다. 표시 값·상태·콜백·다른 시각 속성은 그대로다(FR-005).
- 서로 다른 속성 메서드는 순서와 무관하게 같은 결과를 낸다. 같은 속성을 여러 번 호출하면 마지막
  값이 남는다(FR-006).
- 메서드를 호출하지 않으면 [data-model.md](../data-model.md) §2의 기본값으로 그린다(FR-007).
- 시각 속성 메서드는 SwiftUI 일반 수정자보다 먼저 호출한다. 일반 수정자 뒤에서 호출하면 반환 타입이
  컴포넌트가 아니므로 컴파일 오류가 난다.

## 2. 시각 속성 대상의 초기화 메서드

| 컴포넌트 | 전환 후 공개 초기화 메서드 | 채택 계약 |
| --- | --- | --- |
| `StyledText` | `init(text:)` | `TextStyleConfigurable`, `ForegroundColorConfigurable` |
| `ActionButton` | `init(title:isEnabled:action:)`, `init(styledText:isEnabled:action:)` | `StyleConfigurable`(`Style`), `SizeConfigurable`(`Size`) |
| `TagBadge` | `init(text:)` | `StyleConfigurable`, `SizeConfigurable` |
| `IconGlassButton` | `init(icon:label:action:)` | `StyleConfigurable`, `SizeConfigurable` |
| `ContinuousProgressBar` | `init(progress:)` | `SizeConfigurable`(`Height`) |
| `IconPlainButton` | `init(icon:label:iconSize:size:action:)` | `ForegroundColorConfigurable`, `BackgroundColorConfigurable` |
| `SelectionCardList` | `init(items:selection:)`(`selection: Binding<String?>`, §3.1) | `StyleConfigurable`(`SelectionCardStyle`) |
| `ScreenContainer` | `init(content:)` | `BackgroundColorConfigurable` |
| `OverlayContainer` | `init(header:content:background:footer:)`, `where Background == EmptyView`: `init(header:content:footer:)` | `BackgroundColorConfigurable` |
| `LabeledCard` | §3 참조 | `StyleConfigurable` |
| `LabeledProgressBar` | §3 참조 | `ForegroundColorConfigurable` |
| `SelectionCard` | §3 참조 | `StyleConfigurable`(`SelectionCardStyle`) |
| `HomeProjectCard` | §3 참조 | `StyleConfigurable`(`HomeProjectCard.Style`, 이전 `Variant`) |

Feature 래퍼 `FeedbackActionButton`(`sources/Projects/Feature/Shared/Views/FeedbackActionButton.swift`)은
`ActionButton`과 같은 두 초기화 메서드를 가진다. 같은 두 계약을 `ActionButton.Style`·`ActionButton.Size`로
채택한다([research.md](../research.md) §4.4).

## 3. 표시 값 모델 대상의 초기화 메서드

첫 인자는 `displayModel: DisplayModel`이다. 나머지 인자는 기존 이름·타입·기본값·순서를 유지한다.
각 `DisplayModel`은 `public struct DisplayModel: Sendable, Equatable`이며, 아래 필드를 같은 순서로
받는 `public init`을 가진다.

| 컴포넌트 | `DisplayModel` 필드 | 전환 후 초기화 메서드 |
| --- | --- | --- |
| `ChoiceResultRow` | `text`, `explanation` | `init(displayModel:judgement:isExpanded:)`(`isExpanded: Binding<Bool>`, §3.1) |
| `HomeProjectCard` | `title`, `technologies`, `progress`, `currentSetLabel`, `setTitle` | `init(displayModel:isLearningEnabled:onSelect:onStart:)` |
| `LearningSetRow` | `label`, `title`, `questionCount`, `completedCount` | `init(displayModel:onStart:)` |
| `ProjectRow` | `name`, `supportingText`, `progress`, `currentSet`, `setTitle` | `init(displayModel:isDeleting:onAccessoryTap:thumbnail:)` |
| `SavedQuestionCard` | `metadata`, `prompt`, `actionTitle` | `init(displayModel:isBookmarked:onActionTap:)`(`isBookmarked: Binding<Bool>`, §3.1) |
| `SelectionCard` | `title`, `supportingText = nil`, `badgeText = nil` | `init(displayModel:isSelected:thumbnail:)`, `where Thumbnail == EmptyView`: `init(displayModel:isSelected:)` |
| `ChoiceAnswerOption` | `letter`, `text` | `init(displayModel:state:expansion:onTap:)` |
| `LabeledTextField` | `label`, `placeholder`, `supportingText = nil` | `init(displayModel:text:isError:keyboardType:textInputAutocapitalization:autocorrectionDisabled:accessibilityLabel:focus:)` |
| `PolicyAgreementRow` | `title`, `isRequired` | `init(displayModel:isSelected:onOpenLink:)`(`isSelected: Binding<Bool>`, §3.1) |
| `ScreenControlBar` | `leading = .back`, `trailing = nil` | `init(displayModel: DisplayModel = .init(), onLeadingTap:onTrailingTap:)` |
| `TextField` | `placeholder`, `errorMessage = nil` | `init(displayModel:text:isSecure:onCommit:)` |
| `LabeledCard` | `label`, `text` | `init(displayModel:)` |
| `RubricView` | `criteria`, `overallFeedback = nil` | `init(displayModel:)` |
| `ScreenHeaderTitle` | `title = nil`, `subtitle = nil` | `init(displayModel:)` |
| `EmptyState` | `title`, `message` | `init(displayModel:illustration:)` |
| `LabeledProgressBar` | `label`, `progress`, `valueText` | `init(displayModel:)` |
| `PageIndicator` | `currentPage`, `totalPages` | `init(displayModel:)` |
| `ProgressSegments` | `completed`, `total` | `init(displayModel:)` |
| `ConfirmationSheet` | `imageURL`, `title`, `message`, `confirmTitle`, `cancelTitle` | `init(displayModel:onConfirmTap:onCancelTap:)` |
| `WebSheet` | `title`, `url` | `init(displayModel:onDismiss:)` |

중첩 값 타입(값 타입이며 View가 아님):

| 타입 | `DisplayModel` 필드 | 전환 후 초기화 메서드 |
| --- | --- | --- |
| `SelectionCardList.Item` | `title`, `supportingText = nil`, `illust = nil` | `init(id:displayModel:)`(`isSelected` 제거, §3.1) |

- `ScreenControlBar`의 `displayModel` 기본값 `.init()`은 기존 `leading = .back`·`trailing = nil`
  기본값을 보존한다. 그래서 현재 `leading`·`trailing`을 생략한 호출부의 의미가 그대로다.

## 3.1 상태 `Binding` 대상(FR-017)

상태 `Binding` 인자는 기본값이 없다. 저장은 `@Binding private var`이며, 쓰는 값은
[research.md](../research.md) §9.1을 따른다. 표시 값 모델을 함께 받는 컴포넌트는 §3의 시그니처가 정본이다.

| 컴포넌트·타입 | 전환 후 초기화 메서드·case | 제거되는 인자 |
| --- | --- | --- |
| `Chip` | `init(label:isSelected: Binding<Bool>)` | `onTap` |
| `SelectableSettingRow` | `init(title:isSelected: Binding<Bool>)` | `onTap`, `isSelected`의 기본값 |
| `PolicyAgreementRow` | §3 | `onToggle`, `isSelected`의 기본값 |
| `ChoiceResultRow` | §3 | `onTap` |
| `SavedQuestionCard` | §3 | `onBookmarkTap`, `isBookmarked`의 기본값 |
| `BookmarkButton` | `init(isSaved: Binding<Bool>, accessibilityLabel:)` | `onTap` |
| `ModalOverlay` | `init(isPresented: Binding<Bool>, content:)` | `onDismiss` |
| `SelectionCardList` | `init(items:selection: Binding<String?>)` | `onSelect`, `Item.isSelected` |
| `ChoiceAnswerOption.ExpansionControl` | `case toggleable(isExpanded: Binding<Bool>)` | `onToggleExpand` |

값으로 남는 상태와 동작 콜백 목록은 [research.md](../research.md) §9.1에 있다.

## 4. 변경하지 않는 공개 API

- 표시 값이 1개 이하이고 시각 속성이 없는 컴포넌트의 초기화 메서드는 그대로다.
  목록은 [research.md](../research.md) §1.3에 있다.
- `ActionMenu.Item(id:title:role:accessibilityLabel:)`: `role`은 동작 의미이므로 유지한다. 표시 값은
  1개다.
- `ScreenControlBar.Control(icon:label:)`와 정적 값 `back`·`close`.
- `ResourceImage.resizable(_:)`: 이 기능의 범위(시각 속성·표시 값 모델) 밖의 기존 정적 API다.
- 모든 `Style`·`Size`·`Height` enum의 case와 토큰 대응(FR-013). 예외로 `HomeProjectCard.Variant`는
  이름만 `HomeProjectCard.Style`로 바뀌고 case와 `init(index:)`는 유지한다.

## 5. 호출부 전환 예

Feature의 상태 `Binding` 연결은 [research.md](../research.md) §9.3을 따른다.

```swift
// 전
BookmarkButton(isSaved: store.isBookmarked, accessibilityLabel: label, onTap: { send(.bookmarkToggleTapped) })

// 후
BookmarkButton(
    isSaved: Binding(get: { store.isBookmarked }, set: { _ in send(.bookmarkToggleTapped) }),
    accessibilityLabel: label,
)
```

```swift
// 전
StyledText(text: "제목", style: .subtitle1, color: .grey400, alignment: .center)
ActionButton(title: "계속하기", style: .secondary, size: .medium) { send(.continueTapped) }
LabeledCard(label: "AI 해설", text: explanation, style: .accent)

// 후
StyledText(text: "제목")
    .textStyle(.subtitle1)
    .foregroundColorToken(.grey400)
    .multilineTextAlignment(.center)
ActionButton(title: "계속하기") { send(.continueTapped) }
    .style(.secondary)
    .size(.medium)
LabeledCard(displayModel: .init(label: "AI 해설", text: explanation))
    .style(.accent)
```
