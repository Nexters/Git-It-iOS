# SwiftUI 로컬 상태

[Git It iOS TCA 컨벤션 — State](../state.md)의 규칙 문서입니다.

`@State`와 `@FocusState`는 다음 조건을 모두 만족할 때만 화면에 둘 수 있습니다.

- View가 사라질 때 손실돼도 제품 동작이 바뀌지 않습니다.
- Use Case 입력이나 Navigation에 영향을 주지 않습니다.
- Reducer test 대상이 아닙니다.
- 부모나 다른 화면이 관찰할 필요가 없습니다.
- 비동기 Effect를 시작하거나 취소하지 않습니다.

하나라도 만족하지 않으면 Feature State가 소유합니다.
