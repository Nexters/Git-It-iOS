# 색상 적용 방법

[Git It iOS View 토큰 컨벤션](../view-tokens.md)의 규칙 문서입니다.

한 파일 안에서 색상 표현 방식을 섞지 않습니다.

- View의 전경·배경: `designSystemForeground(_:)` · `designSystemBackground(_:)`
- 도형 채우기나 `in:` 인자처럼 `Color` 값이 필요한 위치: `Color(designSystem:)`
- `Color(red:green:blue:)`, `Color(hex:)` 등 토큰 밖 색상 리터럴: 사용하지 않습니다.

세 API 모두 DesignSystem의 색 토큰을 받습니다.
