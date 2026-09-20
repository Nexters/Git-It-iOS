# 컴포넌트의 공개 생성 경로는 초기화 메서드 하나입니다

[Git It iOS View 컨벤션](../view.md)의 규칙 문서입니다.

컴포넌트가 공개하는 생성 경로는 표시 값·`Binding`·콜백을 직접 받는 `init` 하나뿐입니다.
시각 변형은 `Style`·`Size` 같은 enum을 초기화 인자로 받아 선택하고, 변형마다 이름을
부여한 `public static func` 팩토리를 정의하지 않습니다. `@ViewBuilder`로 자식 View를
받는 컴포넌트는 `init(..., content:)`를 생성 경로로 두고, 필요한 기본값은
[표시 값, Binding과 콜백](./display-value-binding-callback.md)에 따라 해당 초기화 인자에
둡니다.

초기화 메서드는 렌더링 계약에 필요한 값만 직접 노출합니다. 여러 인자가 항상 함께
변경된다는 이유만으로 상태 wrapper를 추가하지 않으며, Feature 모델을 그대로 받지도
않습니다. 시각 토큰 묶음은 호출부가 나열하지 않고 `Style`이 소유합니다.

```swift
// Feature 호출부의 정본: store는 UI 컴포넌트 내부가 아니라 호출부에만 존재합니다.
ActionButton(title: "계속하기") { store.send(.continueTapped) }
SelectionToggle(isSelected: $store.isSelected)
TagBadge(text: "문제 풀기", style: .accent)

// 사용하지 않습니다
ProjectRow(project: project)
SelectionToggle(state: .init(isSelected: store.isSelected))
```

기본값과 인자 순서는 초기화 메서드 한 곳에만 선언합니다. 변형 enum의 case 이름은 특정
Feature의 업무 역할이 아니라 `neutral`, `accent`, `destructive`처럼 UI 패키지에서
독립적으로 해석할 수 있는 시각 의미를 사용합니다.
