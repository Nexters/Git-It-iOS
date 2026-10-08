# 화면의 생성 경로

[Git It iOS View 컨벤션](../view.md)의 규칙 문서입니다.

Feature 화면은 TCA `Store`를 화면 상태의 단일 정본으로 사용하므로
`init(store: StoreOf<Feature>)`를 생성 경로로 둡니다. 화면은 컴포넌트와 달리 별도
`ViewModel`이나 시각 변형 `Style`을 정의하지 않습니다.

```swift
// Example/ExampleScreen.swift
public struct ExampleScreen: View {
    public init(store: StoreOf<ExampleFeature>) {
        self.store = store
    }

    public var body: some View {
        ExampleContainer {
            if store.hasItems {
                itemList
            } else {
                emptyState
            }
        }
    }

    @Bindable private var store: StoreOf<ExampleFeature>
}
```

화면은 `Store`의 상태를 UI 컴포넌트의 표시 값과 SwiftUI `Binding`으로 연결하고
컴포넌트 콜백을 Feature `Action`으로 해석합니다.
