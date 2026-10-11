# 색상 어휘 소유

[Git It iOS View 토큰 컨벤션](../view-tokens.md)의 규칙 문서입니다.

색상은 DesignSystem의 색 토큰으로만 참조합니다. 역할 이름을 가진 별도의 색상
계층은 두지 않으며, 컴포넌트나 화면이 같은 역할로 반복해서 쓰는 색은 그 컴포넌트의
`Constant`나 공개 계약(기본값을 가진 색 시각 속성과 그 계약 메서드)으로 드러냅니다.

**Feature와 UIComponent는 `extension Color`로 자체 색상 이름을 정의하지 않습니다.**
필요한 팔레트 값이 없으면 DesignSystem의 색 토큰에 추가합니다.
