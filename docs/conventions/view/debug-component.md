# 검토·디버그 전용 컴포넌트

[Git It iOS View 컨벤션](../view.md)의 규칙 문서입니다.

TestFlight 레이아웃 검토 도구처럼 제품 화면이 아닌 UI는 `UIComponent`에 두지 않고
컴포넌트 검토용 프리뷰 앱 target이 소유합니다. 이 UI는 다음 예외를 가집니다.

- 제품 시각 어휘 대신 플랫폼 기본 표현(`List`, `.ultraThinMaterial`)을 쓸 수 있습니다.
- 디자인 토큰 적용 의무([View 토큰 컨벤션 §2](../view-tokens.md#2-디자인-토큰))의
  대상이 아닙니다.

그 외 규칙 — 파일 구성, 공개 생성 경로, View 내부 선언 — 은 동일하게 적용합니다.
제품 컴포넌트는 검토 전용 UI를 참조하지 않으며, 검토 전용 UI를 `UIComponent`의 역할
폴더로 옮기지 않습니다.
