# Feature 패키지 규칙

**상태**: 초안

**작성일**: 2026-08-07

**최종 수정일**: 2026-08-21

## 설명

Feature는 사용자가 인지하는 기능을 TCA 기반 상태, 사용자 상호작용과 화면으로 구현하는
Presentation 경계입니다. Domain이 제공하는 비즈니스 기능을 사용하고 UI가 제공하는 공통
시각 요소를 조립합니다. Feature 바깥의 화면 흐름은 App이 해석할 delegate 또는
navigation intent로 출력합니다.

이 문서는 Feature가 소유하는 책임과 허용 의존성을 정의합니다. `State`, `Action`,
`Reducer`, Effect와 Store 연결의 구현 방식은 [TCA 컨벤션](../conventions/tca.md), 화면
구현 방식은 [View 컨벤션](../conventions/view.md)을 따릅니다.

## 적용 범위

- 사용자 기능별 State, Action, Reducer, Effect와 화면
- 사용자 기능 안에서 완결되는 목적지 구성과 Presentation 흐름
- Domain contract 호출과 결과를 화면 상태로 변환하는 연결
- UIComponent 조립과 DesignSystem 적용

Domain contract의 production 구현, 객체 수명 선택과 여러 Feature를 잇는 앱 전체
Navigation은 Feature의 범위가 아닙니다.

## 공개 계약과 의존성

- 공개 이름은 [네이밍 컨벤션](../conventions/naming.md)을 따르며 사용자 기능과
  Presentation 책임을 드러냅니다.
- production target은 하나 이상의 사용자 기능을 표현하는 화면, State, Action,
  Reducer 또는 Presentation 흐름을 소유해야 합니다.
- 비즈니스 기능은 Domain이 제공하는 타입과 계약으로 사용합니다.
- Effect에 필요한 Domain dependency는 Reducer의 초기화 메서드나 명시적인 초기화
  인자로 주입합니다.
- 재사용 UI는 UI가 제공하는 공개 API로 사용합니다.
- Feature는 자신의 State와 업무 모델을 UIComponent의 표시 값과 SwiftUI `Binding`으로
  연결하고, 컴포넌트 콜백을 Feature Action으로 해석합니다.
- Feature 바깥의 Navigation은 App이 해석할 delegate 또는 navigation intent로
  출력합니다.
- 프로젝트 내부 의존성은 아키텍처가 허용한 Domain과 UI로 한정합니다.

Feature의 공개 표면은 App이 생성하는 Reducer와 화면, App이 해석할 delegate 또는
navigation intent로 제한합니다. Domain contract 구현체, Data DTO, 저장·네트워크 기술과
UI 내부 자산을 공개 계약에 포함하지 않습니다.

## 구현 컨벤션

- TCA Feature 구성, dependency 주입, Effect 취소와 화면 연결은
  [TCA 컨벤션](../conventions/tca.md)을 따릅니다.
- 화면 생성 경로, 디자인 토큰, 내부 선언, 접근성과 프리뷰는
  [View 컨벤션](../conventions/view.md)을 따릅니다.
- UIComponent 입력 경계와 재사용 판단은
  [UIComponent 컨벤션](../conventions/ui-component.md)을 따릅니다.
- 테스트 이름, 비동기 종료와 target 구성은
  [테스트 컨벤션](../conventions/test.md)을 따릅니다.

## 제약조건

- TCA Dependencies의 `@Dependency` 또는 의존성 접근 키를 production dependency 조회에
  사용해서는 안 됩니다.
- Data DTO나 Data API를 참조해서는 안 됩니다.
- Infrastructure의 기술 API를 참조해서는 안 됩니다.
- Composition에 직접 접근해 dependency를 조회해서는 안 됩니다.
- Repository 또는 production 구현체를 Feature 내부에서 생성해서는 안 됩니다.
- Domain의 비즈니스 규칙을 Feature에 다시 구현해서는 안 됩니다.
- 재사용 가능한 UI 컴포넌트를 소유해서는 안 됩니다.
- Feature State, Action 또는 업무 모델을 UIComponent 공개 API에 노출해서는 안 됩니다.
- DesignSystem 밖에 시각 어휘를 정의해서는 안 됩니다.
- 화면 파일 안에 별도 View 타입을 정의해서는 안 됩니다.
- TCA Store와 같은 상태를 복제하는 화면 ViewModel을 정의해서는 안 됩니다.
- 다른 Feature의 목적지 생성과 앱 전체 Navigation 정책을 소유해서는 안 됩니다.
