# 접근 수준

[Git It iOS View 컨벤션](../view.md)의 규칙 문서입니다.

- UIComponent의 컴포넌트: `public`
- 프리뷰 전용 타입: `internal`
- Feature 화면: App이 목적지로 생성하는 화면만 `public`, 다른 화면 안에서만
  생성되는 화면은 `internal`
- UI 컴포넌트에 중첩한 `Style`과 그 밖의 비상태 보조 타입: 공개 계약에 필요한 경우만
  `public`, 그 외에는 `private`
- View가 소유한 `Constant`와 그 밖의 보조 선언: 항상 `private`([View 내부 선언 컨벤션 —
  `Constant`](../view-declarations/constant.md))

"모든 화면을 `public`으로 연다"와 "필요할 때 연다"를 파일마다 다르게 적용하지
않습니다. 화면을 `public`으로 여는 근거는 App의 Navigation에서 생성되는지 여부
하나입니다.

`Style`은 호출부가 직접 선택하는 공개 초기화 경로에 필요할 때만 `public`으로 엽니다.
