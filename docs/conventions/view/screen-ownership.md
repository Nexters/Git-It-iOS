# 화면이 소유하는 것과 소유하지 않는 것

[Git It iOS View 컨벤션](../view.md)의 규칙 문서입니다.

- 화면은 상태 분기, 화면 목적지 생성, 컴포넌트 조립을 소유합니다.
- 화면에서 독립적으로 이름 붙일 수 있는 표현 책임은 UIComponent로 옮깁니다.
- 화면 전용 렌더링 조각은 §4.3의 화면 전용 서브뷰로 분리하고, 패키지 수준의 재사용
  `View` 타입으로 노출하지 않습니다.

화면이 Store와 Action을 다루는 경계는
[TCA Navigation 컨벤션 — TCA 화면과 Store 연결](../tca/navigation/tca-screen.md)를 따릅니다.
