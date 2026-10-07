# 컴포넌트의 공개 생성 경로는 두 가지입니다

[Git It iOS View 컨벤션](../view.md)의 규칙 문서입니다.

컴포넌트가 공개하는 생성 경로는 다음 둘뿐입니다.

1. 표시 값·`Binding`·콜백을 직접 받는 `init` — `@ViewBuilder` 자식이 있으면 함께
   받습니다.
2. 시각 변형별 `public static func` 팩토리 — 고정된 토큰 조합에 이름을 부여합니다.

초기화 메서드는 렌더링 계약에 필요한 값만 직접 노출합니다. 여러 인자가 항상 함께
변경된다는 이유만으로 상태 wrapper를 추가하지 않으며, Feature 모델을 그대로 받지도
않습니다. 시각 토큰 묶음은 호출부가 나열하지 않고 `Style` 또는 팩토리가 소유합니다.

```swift
// Feature 호출부의 정본: store는 UI 컴포넌트 내부가 아니라 호출부에만 존재합니다.
ActionButton.primary("계속하기") { store.send(.continueTapped) }
SelectionToggle(isSelected: $store.isSelected)
TagBadge(text: "문제 풀기", color: .blue100)

// 사용하지 않습니다
ProjectRow(project: project)
SelectionToggle(state: .init(isSelected: store.isSelected))
```

팩토리는 `Self`를 반환하고 고정된 시각 변형을 선택하며, 호출부는 텍스트, 상태와
콜백처럼 화면 문맥에 따라 달라지는 값만 전달합니다. 팩토리 이름은 특정 Feature의 업무
역할이 아니라 `neutral`, `accent`, `destructive`처럼 UI 패키지에서 독립적으로 해석할
수 있는 시각 의미를 사용하고, Typography 팩토리는 적용하는 `TextStyleToken` 이름과
일치시킵니다.
