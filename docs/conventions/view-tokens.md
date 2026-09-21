# Git It iOS View 토큰 컨벤션

**상태**: 초안

**작성일**: 2026-08-31

**최종 수정일**: 2026-09-13 (`SemanticColorToken` 폐기, 색상은 `ColorToken`만 참조)

## 목적

이 문서는 UIComponent와 Feature 화면이 DesignSystem의 색상·레이아웃·Typography
토큰을 사용하는 방식을 정의합니다. 공개 생성 경로, 화면 조립과 프리뷰는
[View 컨벤션](./view.md), View 내부 선언은
[View 내부 선언 컨벤션](./view-declarations.md)이 소유합니다.

문서 우선순위, 문서 구조와 문서 간 참조 규칙은
[컨벤션 공통 원칙](./common/README.md)이 소유합니다.

## 1. 적용 범위

- `sources/Projects/UI/Component/**`의 모든 컴포넌트가 사용하는 색상·레이아웃·문자열
  렌더링
- `sources/Projects/UI/DesignSystem/**`의 토큰과 토큰 적용 API
- `sources/Projects/Feature/**`의 화면이 사용하는 색상·레이아웃·문자열 렌더링

토큰 카탈로그의 구성은 `UI/DesignSystem/` 소스가
소유하며, 이 문서는 **컴포넌트와 화면이 그 토큰을 어떻게 참조하는지**만 정합니다.

## 2. 디자인 토큰

색상, 레이아웃 수치와 문자열 렌더링의 시각 어휘는 DesignSystem이 정본으로 소유합니다. 컴포넌트와 화면은 원시 값을 직접 쓰지 않고 토큰과 토큰
적용 API로만 시각 어휘를 사용합니다.

### 2.1 색상 어휘는 DesignSystem이 소유합니다

색상은 `ColorToken`으로만 참조하고, Feature와 UIComponent는 `extension Color`로 자체 색상 이름을 정의하지 않습니다.

→ [색상 어휘 소유](./view-tokens/color-ownership.md)

### 2.2 색상 적용 방법

한 파일 안에서 색상 표현 방식을 섞지 않습니다.

→ [색상 적용 방법](./view-tokens/color-application.md)

### 2.3 레이아웃·모서리·컨트롤 크기

여러 컴포넌트나 화면이 공유하는 수치는 컴포넌트마다 복제하지 않고 DesignSystem 토큰으로 승격한 뒤 토큰 적용 API로 사용합니다.

→ [레이아웃·모서리·컨트롤 크기](./view-tokens/layout-metrics.md)

### 2.4 Typography

문자열 렌더링은 `Text`를 직접 구성하지 않고 `StyledText` 초기화에 `TextStyleToken`을 넘깁니다.

→ [Typography](./view-tokens/typography.md)

## 3. 검토 체크리스트

- [ ] 토큰 밖 색상 리터럴이 없는가?
- [ ] `extension Color`로 패키지 로컬 색상 이름을 추가하지 않았는가?
- [ ] 여러 곳이 공유하는 수치를 토큰으로 승격했는가?
- [ ] 문자열이 `TextStyleToken`을 받는 `StyledText` 초기화를 통과하는가?
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
