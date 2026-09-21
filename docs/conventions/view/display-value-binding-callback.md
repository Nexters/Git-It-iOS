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
| 상태 | `isSelected`·`isExpanded`·`isSaved`·`isEnabled`·`isError`·`judgement` | 스스로 바꾸면 `Binding`, 그 밖에는 [상태 선언 메서드](#상태-선언-메서드)(기본값이 없으면 초기화 인자) |
| 동작 설정 | `isLooping`·`speed`·`contentMode` | 상태 선언 메서드. SwiftUI에 같은 수정자가 있으면(`keyboardType` 등) 받지 않고 호출부가 SwiftUI 수정자로 붙인다 |
| 화면에 보이지 않는 문구 | `accessibilityLabel` | 개별 인자 |

`id` 같은 식별자는 표시 값으로 세지 않습니다. `Binding`·`FocusState`, 콜백과 자식 View도 모델에 넣지
않고 개별 인자로 둡니다.

## 표시 값 모델

표시 값을 2개 이상 받는 컴포넌트와 공개 중첩 값 타입은 표시 값을 `DisplayModel` 하나로 묶어 첫
인자 `displayModel:`로 받습니다.

- `DisplayModel`은 소유 컴포넌트에 중첩한 `public struct DisplayModel: Sendable, Equatable`이며,
  컴포넌트 파일 안 `extension`에 둡니다.
- 표시 값의 기본값(`supportingText: String? = nil` 등)은 `DisplayModel`의 `public init`에 둡니다.
- 상태는 표시 값 모델에 넣지 않고 [상태 선언 메서드](#상태-선언-메서드) 또는 `Binding`으로 둡니다.
- Feature는 화면 View의 호출 지점에서 State·업무 모델 값을 `DisplayModel`로 매핑합니다. Feature
  State와 Reducer는 `DisplayModel`을 보유하지 않습니다.

```swift
LabeledCard(displayModel: .init(label: "AI 해설", text: explanation))
ProjectRow(displayModel: displayModel, onAccessoryTap: onAccessoryTap) { thumbnail }
    .deleting(isDeleting)
```

## 상태 선언 메서드

값으로 받는 상태와 동작 설정은 개수와 무관하게 초기화 인자로 받지 않습니다. 하나씩 기본값을 가진
`private var`로 저장하고, 시각 속성 계약 메서드처럼 `Self`를 반환하는 선언 메서드로 바꿉니다.
여러 값을 묶는 상태 모델 타입은 두지 않습니다.

- 메서드 이름은 프로퍼티 이름에서 `is`를 뺀 형용사·분사입니다: `ActionButton.enabled(_:)`,
  `HomeProjectCard.learningEnabled(_:)`, `ProjectRow.deleting(_:)`, `SelectionCard.selected(_:)`,
  `PushedScreenOverlay.presented(_:)`, `SheetSurface.scrollable(_:)`, `LabeledTextField.error(_:)`,
  `ResourceAnimation.looping(_:)`. `Bool`이 아닌 값은 프로퍼티 이름을 그대로 씁니다
  (`ResourceAnimation.speed(_:)`, `ResourceAnimation.contentMode(_:)`).
- SwiftUI에 같은 의미의 수정자가 있고 환경으로 안쪽 View에 전달되는 설정(`keyboardType`,
  `textInputAutocapitalization`, `autocorrectionDisabled`)은 컴포넌트가 받지 않습니다. 호출부가 SwiftUI
  수정자를 컴포넌트 뒤에 붙입니다.
- 본문은 `var copy = self`로 사본을 만들어 그 값 하나만 바꿔 반환합니다. 컴포넌트 파일 안
  `extension`(`// MARK: {컴포넌트} 상태 선언`)에 둡니다.
- 기본값은 선언하지 않았을 때 자연스러운 상태(`isEnabled = true`, `isSelected = false`,
  `isPresented = false`)입니다.
- 기본값이 없는 필수 상태(`ChoiceResultRow.judgement`)는 선언을 빠뜨리지 않도록 초기화 인자로 받습니다.
- 선언 메서드는 컴포넌트를 반환하므로 SwiftUI 일반 수정자보다 먼저 호출합니다. 시각 속성 메서드와는
  순서가 무관합니다.
- Feature 공용 래퍼(`FeedbackActionButton`)가 같은 상태를 넘기면 같은 이름의 선언 메서드를 둡니다.

```swift
FeedbackActionButton(title: "다음", action: { send(.nextTapped) })
    .enabled(store.canContinue)
PushedScreenOverlay { QuizRouter(store: store) }
    .presented(store != nil)
LabeledTextField(displayModel: displayModel, text: $url)
    .error(isValidationFailed)
    .keyboardType(.URL)
```

## 상태, Binding과 콜백

- 컴포넌트가 탭·토글·펼침·닫기 같은 상호작용으로 스스로 바꾸는 상태(`Chip.isSelected`,
  `BookmarkButton.isSaved`, `ModalOverlay.isPresented`, `SelectionCardList.selection`)는 기본값 없는
  `Binding`으로 받고 `@Binding private var`에 저장합니다. 그 상태를 바꾸는 짝 변경 콜백(`onTap`,
  `onToggle`, `onDismiss` 등)은 두지 않습니다.
- 컴포넌트가 바꾸지 않는 읽기 전용 상태(`isEnabled`, `judgement`, `isDeleting`, `isError`)와 부모가
  소유하는 상태(`SelectionCard.isSelected`)는 상태 선언 메서드로 받습니다.
- 상태 변경과 무관한 동작(`onOpenLink`, `onActionTap`, `onConfirmTap`)은 콜백으로 받습니다.
- Feature 화면은 `Binding(get:set:)`으로 상태 `Binding`을 만들고, setter는 기존 View Action을 보냅니다.

```swift
Chip(label: "SwiftUI", isSelected: $isSelected)
BookmarkButton(
    isSaved: Binding(get: { store.isBookmarked }, set: { _ in send(.bookmarkToggleTapped) }),
    accessibilityLabel: label,
)
```

표시 값과 동작 설정에 자연스러운 기본 표현이 있으면 해당 인자나 `DisplayModel` 필드·상태 선언 프로퍼티에 기본값을
제공합니다. 상태 `Binding`에는 `.constant(...)` 같은 기본값을 두지 않습니다.
