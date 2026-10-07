# 외부 상태와 `Binding`

[Git It iOS View 내부 선언 컨벤션](../view-declarations.md)의 규칙 문서입니다.

읽기 값·`Binding`·콜백으로 입력을 나누는 기준은
[View 컨벤션 — 표시 값, Binding과 콜백](../view/display-value-binding-callback.md)이
소유합니다. 이 문서는 받은 외부 상태를 View가 어떻게 보존하는지만 정합니다.

- `@State`, observable reference 또는 별도 상태 wrapper에 외부 값을 복제하지 않습니다.
- `Binding`의 기본값을 `.constant`로 제공해 상태 연결 누락을 숨기지 않습니다.
- 로딩·선택·활성화처럼 외부가 결정하는 상태는 표시 값 또는 `Binding`으로 명시합니다.
