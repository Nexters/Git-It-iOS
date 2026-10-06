# Git It iOS View 토큰 컨벤션

**상태**: 초안

**작성일**: 2026-08-31

**최종 수정일**: 2026-08-31 ([View 컨벤션](./view.md)에서 분리)

## 목적

이 문서는 UIComponent와 Feature 화면이 DesignSystem의 색상·레이아웃·Typography
토큰을 사용하는 방식을 정의합니다. 공개 생성 경로, 화면 조립과 프리뷰는
[View 컨벤션](./view.md), View 내부 선언은
[View 내부 선언 컨벤션](./view-declarations.md)이 소유합니다.

상위 문서와의 우선순위는 [컨벤션 공통 규칙](./README.md#상위-문서와-충돌-해소)을
따릅니다.

## 1. 적용 범위

- `sources/Projects/UI/Component/**`의 모든 컴포넌트가 사용하는 색상·레이아웃·문자열
  렌더링
- `sources/Projects/UI/DesignSystem/**`의 토큰과 토큰 적용 API
- `sources/Projects/Feature/**`의 화면이 사용하는 색상·레이아웃·문자열 렌더링

의미 토큰의 정의 자체와 원시 토큰 카탈로그의 구성은 `UI/DesignSystem/` 소스가
소유하며, 이 문서는 **컴포넌트와 화면이 그 토큰을 어떻게 참조하는지**만 정합니다.

## 2. 디자인 토큰

### 2.1 의미 색상은 DesignSystem이 소유합니다

`ColorToken`은 팔레트 원시 값(`grey600`, `blue100`)을 표현합니다. 화면에서 반복되는
**역할**(카드 배경, 보조 텍스트, 강조)에는 원시 토큰을 직접 쓰지 않고 DesignSystem이
소유하는 `SemanticColorToken`을 사용합니다. `SemanticColorToken`은 역할 이름과 참조하는
`ColorToken`을 함께 소유하며 §2.2의 적용 API가 두 타입을 모두 받습니다.

의미 토큰은 다음 기준을 모두 만족할 때 정의합니다.

1. 이름이 팔레트 위치가 아니라 화면에서의 역할을 설명합니다.
   (`cardBackground` ○ / `purpleSurface` ×, `darkAccent` ×)
2. 역할이 바뀌면 참조하는 원시 토큰이 함께 바뀌어야 합니다.
3. 둘 이상의 컴포넌트 또는 화면이 같은 역할로 사용합니다.

기준을 만족하지 못하는 팔레트 별칭은 정의하지 않고 원시 `ColorToken`을 그대로
사용합니다.

**Feature와 UIComponent는 `extension Color`로 자체 색상 이름을 정의하지 않습니다.**
필요한 의미 이름이 없으면 DesignSystem에 추가하고, 추가할 근거가 없으면 원시 토큰을
사용합니다.

### 2.2 색상 적용 방법

한 파일 안에서 색상 표현 방식을 섞지 않습니다.

- View의 전경·배경: `designSystemForeground(_:)` · `designSystemBackground(_:)`
- 도형 채우기나 `in:` 인자처럼 `Color` 값이 필요한 위치: `Color(designSystem:)`
- `Color(red:green:blue:)`, `Color(hex:)` 등 토큰 밖 색상 리터럴: 사용하지 않습니다.

세 API 모두 `ColorToken`과 `SemanticColorToken` 오버로드를 제공하므로 역할이 있는
색은 의미 토큰을, 변형별 팔레트 선택은 원시 토큰을 같은 호출 형태로 전달합니다.

### 2.3 레이아웃·모서리·컨트롤 크기

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
[View 내부 선언 컨벤션 §2.1](./view-declarations.md#21-constant)의 `Constant`로
둡니다.

`ControlSizeToken`은 `DesignTokenSet.validate()`에서 44pt 미만을 오류로 판정합니다.
44pt 미만의 터치 대상이 필요하면 토큰이 아니라 컴포넌트 로컬 상수로 두고, 실제 터치
영역은 `contentShape` 또는 확장된 `frame`으로 44pt 이상을 확보합니다.

### 2.4 Typography

문자열 렌더링은 `Text`를 직접 구성하지 않고 `StyledText`의 Typography 팩토리를
사용합니다. `TextStyleToken`은 자간·행간·언어별 폰트 선택을 함께 결정하므로
`.font(.caption2)` 같은 플랫폼 API로 대체하면 표현이 갈라집니다.

**`Text` 값이 필요한 경우 예외**: `StyledText`는 View이므로 `Button` label 안에서
`Text` 값 수준의 구성이 필요한 위치에는 넣을 수 없습니다. `ActionButton`, `TagBadge`처럼
자기 문자열을 직접 그리는 컴포넌트는
DesignSystem의 토큰 적용 API인 `Text.designSystemStyled(_:style:)`과
`designSystemLineSpacing(_:)`을 사용합니다. 이 경로도 `TextStyleToken`을 통과하므로
표현이 갈라지지 않습니다.

플랫폼 기본 폰트는 SF Symbol의 크기 지정(`.font(.system(size:weight:))`, `.font(.caption)`)과
`TextEditor`처럼 `Text`가 아닌 입력 컨트롤에만 사용합니다.

## 3. 검토 체크리스트

- [ ] 토큰 밖 색상 리터럴이 없는가?
- [ ] `extension Color`로 패키지 로컬 색상 이름을 추가하지 않았는가?
- [ ] 여러 곳이 공유하는 수치를 토큰으로 승격했는가?
- [ ] 문자열이 `StyledText` Typography 팩토리를 통과하는가?
- [ ] 한 View 안에서만 쓰는 토큰 참조가 `body`에 흩어지지 않고 `Constant`의
      `static` 멤버로 모여 있는가?

## 관련 문서

- [아키텍처](../architecture.md)
- [View 컨벤션](./view.md)
- [View 내부 선언 컨벤션](./view-declarations.md)
- [UIComponent 컨벤션](./ui-component.md)

## 문서 변경 기준

색상·레이아웃·Typography 토큰의 사용 규칙이나 적용 API가 바뀔 때 수정합니다. 공개
생성 경로, 화면 조립이나 프리뷰가 바뀌면 이 문서가 아니라
[View 컨벤션](./view.md)을, View 내부 선언 규칙이 바뀌면
[View 내부 선언 컨벤션](./view-declarations.md)을 갱신합니다. 토큰 자체의 정의와
카탈로그 구성이 바뀌면 `UI/DesignSystem/` 소스와 함께 이 문서를 갱신합니다.
