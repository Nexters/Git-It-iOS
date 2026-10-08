# Typography

[Git It iOS View 토큰 컨벤션](../view-tokens.md)의 규칙 문서입니다.

문자열 렌더링은 `Text`를 직접 구성하지 않고 공용 텍스트 컴포넌트에 타이포그래피 토큰을
지정해 그립니다. 타이포그래피 토큰은 자간·행간·언어별 폰트 선택을 함께 결정하므로
`.font(.caption2)` 같은 플랫폼 API로 대체하면 표현이 갈라집니다.

**`Text` 값이 필요한 경우 예외**: 공용 텍스트 컴포넌트는 View이므로 `Button` label 안에서
`Text` 값 수준의 구성이 필요한 위치에는 넣을 수 없습니다. 버튼·배지처럼
자기 문자열을 직접 그리는 컴포넌트는
DesignSystem의 토큰 적용 API인 `Text.designSystemStyled(_:style:)`과
`designSystemLineSpacing(_:)`을 사용합니다. 이 경로도 타이포그래피 토큰을 통과하므로
표현이 갈라지지 않습니다.

플랫폼 기본 폰트는 SF Symbol의 크기 지정(`.font(.system(size:weight:))`, `.font(.caption)`)과
`TextEditor`처럼 `Text`가 아닌 입력 컨트롤에만 사용합니다.
