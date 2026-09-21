# 표시 값, Binding과 콜백

[Git It iOS View 컨벤션](../view.md)의 규칙 문서입니다.

UI 컴포넌트는 초기화 인자를 표시 값·상태·동작 설정·화면에 보이지 않는 문구로 구분해 받습니다.
일회성 사용자 입력은 프레임워크 중립 콜백으로 상위에 전달하며, TCA `Store`, `Action` 또는 `Effect`를
컴포넌트 계약에 포함하지 않습니다. 시각 속성은 초기화 인자가 아니라
[계약 메서드](./component-init.md#시각-속성은-계약-메서드로-선언합니다)로 선언합니다.

## 인자 구분

| 구분 | 예 | 받는 방법 |
|---|---|---|
| 표시 값 | 텍스트·수치·진행률·이미지·아이콘, `placeholder`·`errorMessage`·`supportingText`, 고정 표기를 정하는 `isRequired` | 2개 이상이면 `DisplayModel` 하나, 1개면 개별 인자 |
| 상태 | `isSelected`·`isExpanded`·`isSaved`·`isEnabled`·`isError`·`judgement` | 개별 인자 |
| 동작 설정 | `keyboardType`·`textInputAutocapitalization`·`isLooping`·`contentMode` | 개별 인자 |
| 화면에 보이지 않는 문구 | `accessibilityLabel` | 개별 인자 |

`id` 같은 식별자는 표시 값으로 세지 않습니다. `Binding`·`FocusState`, 콜백과 자식 View도 모델에 넣지
않고 개별 인자로 둡니다.

## 표시 값 모델

표시 값을 2개 이상 받는 컴포넌트와 공개 중첩 값 타입은 표시 값을 `DisplayModel` 하나로 묶어 첫
인자 `displayModel:`로 받습니다.

- `DisplayModel`은 소유 컴포넌트에 중첩한 `public struct DisplayModel: Sendable, Equatable`이며,
  컴포넌트 파일 안 `extension`에 둡니다.
- 표시 값의 기본값(`supportingText: String? = nil` 등)은 `DisplayModel`의 `public init`에 둡니다.
- 상태는 표시 값 모델에 넣지 않고 개별 인자로 둡니다.
- Feature는 화면 View의 호출 지점에서 State·업무 모델 값을 `DisplayModel`로 매핑합니다. Feature
  State와 Reducer는 `DisplayModel`을 보유하지 않습니다.

```swift
LabeledCard(displayModel: .init(label: "AI 해설", text: explanation))
ProjectRow(displayModel: displayModel, isDeleting: isDeleting, onAccessoryTap: onAccessoryTap) { thumbnail }
```

## 상태, Binding과 콜백

- 컴포넌트가 탭·토글·펼침·닫기 같은 상호작용으로 스스로 바꾸는 상태(`Chip.isSelected`,
  `BookmarkButton.isSaved`, `ModalOverlay.isPresented`, `SelectionCardList.selection`)는 기본값 없는
  `Binding`으로 받고 `@Binding private var`에 저장합니다. 그 상태를 바꾸는 짝 변경 콜백(`onTap`,
  `onToggle`, `onDismiss` 등)은 두지 않습니다.
- 컴포넌트가 바꾸지 않는 읽기 전용 상태(`isEnabled`, `judgement`, `isDeleting`, `isError`)와 부모가
  소유하는 상태(`SelectionCard.isSelected`)는 값으로 받습니다.
- 상태 변경과 무관한 동작(`onOpenLink`, `onActionTap`, `onConfirmTap`)은 콜백으로 받습니다.
- Feature 화면은 `Binding(get:set:)`으로 상태 `Binding`을 만들고, setter는 기존 View Action을 보냅니다.

```swift
Chip(label: "SwiftUI", isSelected: $isSelected)
BookmarkButton(
    isSaved: Binding(get: { store.isBookmarked }, set: { _ in send(.bookmarkToggleTapped) }),
    accessibilityLabel: label,
)
```

표시 값과 동작 설정에 자연스러운 기본 표현이 있으면 해당 인자나 `DisplayModel` 필드에 기본값을
제공합니다. 상태 `Binding`에는 `.constant(...)` 같은 기본값을 두지 않습니다.
