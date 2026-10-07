# 공개 계약

[Git It iOS UIComponent 컨벤션](../ui-component.md)의 규칙 문서입니다.

- 컴포넌트는 화면과 Feature 구현에서 독립적으로 해석 가능한 표현 계약이어야 합니다.
- 표시 값·`Binding`·콜백으로 입력을 나누는 방식과 표시 상태 wrapper 금지는
  [View 컨벤션 — 공개 생성 경로](../view.md#3-공개-생성-경로)이 소유합니다.
- 외부 라이브러리가 필요하면 구현에 필요한 범위로 격리하고 외부 타입을 Feature에
  공개하지 않습니다.
- Feature·TCA 타입을 공개 API와 구현에 쓰지 않는다는 제약은
  [UI 패키지 규칙](../../package-rules/ui.md#제약조건)이 소유합니다.
