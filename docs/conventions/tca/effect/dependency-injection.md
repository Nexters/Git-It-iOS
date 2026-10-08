# 의존성 주입

[Git It iOS TCA 컨벤션 — Reducer와 Effect](../effect.md)의 규칙 문서입니다.

- Effect에 필요한 Domain dependency는 Reducer의 초기화 메서드 또는 명시적인 초기화
  인자로 주입합니다.
- production dependency는 Reducer의 private 불변 저장 프로퍼티로 보존합니다.
- 금지되는 전달 수단(`@Dependency`, Service Locator, 전역 container)의 정본은
  [Feature 패키지 규칙](../../../package-rules/feature.md#제약조건)입니다.
- 테스트는 같은 initializer에 Test Double을 직접 주입합니다.

```swift
@Reducer
public struct ExampleFeature: Sendable {
    public init(fetchItem: any FetchExampleItemUseCase) {
        self.fetchItem = fetchItem
    }

    private let fetchItem: any FetchExampleItemUseCase
}
```
