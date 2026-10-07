# 레이아웃·모서리·컨트롤 크기

[Git It iOS View 토큰 컨벤션](../view-tokens.md)의 규칙 문서입니다.

여러 컴포넌트나 화면이 공유하는 수치는 컴포넌트마다 복제하지 않고 DesignSystem
토큰으로 승격한 뒤 토큰 적용 API로 사용합니다.

| 값 | 토큰 | 적용 API |
|---|---|---|
| 화면 가로 여백 | `LayoutToken.margin` | `designSystemScreenMargin()` |
| 요소 간 기본 간격 | `LayoutToken.gutter` | 직접 참조 |
| 모서리 반경 | `CornerRadiusToken` | `designSystemCornerRadius(_:)` · `RoundedRectangle(designSystem:)` |
| 컨트롤 크기 | `ControlSizeToken` | `designSystemControlHeight(_:)` · `designSystemControlSize(_:)` |

`in:` 인자로 도형을 넘기는 위치에서는 `RoundedRectangle(designSystem:)`을 사용해
`clipShape` 경로와 같은 토큰을 참조합니다.

토큰 적용 API가 존재하는데도 같은 수치를 리터럴로 반복하지 않습니다. 반대로 한
컴포넌트 안에서만 의미를 갖는 수치는 토큰이 아니라
[View 내부 선언 컨벤션 — `Constant`](../view-declarations/constant.md)의 `Constant`로
둡니다.

`ControlSizeToken`은 `DesignTokenSet.validate()`에서 44pt 미만을 오류로 판정합니다.
44pt 미만의 터치 대상이 필요하면 토큰이 아니라 컴포넌트 로컬 상수로 두고, 실제 터치
영역은 `contentShape` 또는 확장된 `frame`으로 44pt 이상을 확보합니다.
