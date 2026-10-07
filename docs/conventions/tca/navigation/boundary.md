# Navigation 경계

[Git It iOS TCA 컨벤션 — Navigation과 화면 연결](../navigation.md)의 규칙 문서입니다.

- 현재 Feature 수명 안에서 완결되는 sheet, alert와 내부 화면은 Destination 또는 Child
  State로 소유할 수 있습니다.
- Feature 바깥으로 이동해야 하면 현재 Feature는 delegate 또는 navigation intent를
  출력하고 App이 목적지와 전환 방식을 결정합니다.
- Feature는 다른 최상위 Feature를 직접 생성하거나 push, present와 같은 App Navigation
  방식을 명령하지 않습니다.
