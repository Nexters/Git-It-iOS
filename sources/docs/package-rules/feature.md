# Feature 패키지 규칙

**상태**: 초안

**작성일**: 2026-08-07

**최종 수정일**: 2026-08-18

## 설명

Feature는 사용자가 인지하는 기능을 TCA 기반 상태, 사용자 상호작용과 화면으로 구현하는 Presentation 경계입니다. State, Action, Reducer와 View를 통해 사용자 입력을 처리하고 Domain 기능의 결과를 화면 상태로 반영합니다.

Feature는 Domain이 제공하는 비즈니스 기능을 사용하고 UI가 제공하는 공용 시각 요소를 조립합니다. Feature 바깥의 화면 흐름이 필요한 경우 App이 해석할 수 있는 delegate 또는 navigation intent를 출력합니다.

이 문서는 Feature 패키지가 **무엇을 소유하고 어떤 의존성을 사용하는지**를 정의합니다.
화면 구현의 공통 컨벤션 — 화면 생성 경로, View 내부 선언, 디자인 토큰 사용, 화면
골격, 접근성, 프리뷰 — 은 [View 컨벤션](../view-conventions.md)을 따릅니다.
화면이 소유하는 `ViewModel`, `Style`, `Constant`는
[View 컨벤션 §5](../view-conventions.md#5-view-내부-선언)에 따라 화면 타입에 중첩해
화면 파일에 둡니다.

## 정책

- 공개 이름은 [네이밍 가이드](../naming.md)를 따르며 사용자 기능과 Presentation 책임을 드러내고 Data·Infrastructure 또는 production 구현 문맥을 노출해서는 안 됩니다.
- 모든 내부 target은 하나 이상의 사용자 기능을 표현하는 화면, 상태, Action, Reducer 또는 Presentation 흐름을 소유해야 합니다.
- 비즈니스 기능은 Domain이 제공하는 타입과 계약을 통해 사용해야 합니다.
- 외부 Effect에 필요한 dependency는 initializer 또는 명시적인 초기화 인자로 주입받아야 합니다.
- 모든 재사용 UI 구성요소는 UI가 제공하는 API를 통해 사용해야 합니다.
- Feature는 화면에서 독립된 `View` 컴포넌트를 소유하지 않으며
  `Presentation/Components/` 디렉터리를 두지 않습니다. 재사용 가능한 하위 View는
  제품 고유의 표현 의미를 포함하더라도 UI 패키지의 `UIComponent`에 둡니다.
- Feature는 자신의 State와 업무 모델을 UI 컴포넌트의 불변 `ViewModel`로 변환하고,
  컴포넌트 콜백을 Feature Action 또는 화면 동작으로 해석해야 합니다.
- 화면 목적지 생성, Feature State 분기와 화면 흐름처럼 Feature 타입을 직접 해석하는
  조립은 별도 컴포넌트로 추출하지 않고 `Screens/`의 화면 구현에 유지합니다.
- Feature 바깥의 Navigation이 필요하면 App이 해석할 수 있는 delegate 또는 navigation intent를 출력해야 합니다.
- TCA 상태 변화와 Effect는 Domain dependency를 Test Double로 주입하여 독립적으로 검증해야 합니다.
- 프로젝트 내부 의존성은 아키텍처 문서에서 Feature에 허용한 패키지로 한정해야 합니다.

## 제약조건

- TCA Dependencies의 `@Dependency` 또는 의존성 접근 키를 production dependency 조회에 사용해서는 안 됩니다.
- Data DTO나 Data API를 참조해서는 안 됩니다.
- Core의 기술 API를 참조해서는 안 됩니다.
- Composition에 직접 접근해서 dependency를 조회해서는 안 됩니다.
- Repository 또는 기술 구현체를 Feature 내부에서 생성해서는 안 됩니다.
- Domain의 비즈니스 규칙을 Feature에 다시 구현해서는 안 됩니다.
- 재사용 가능한 말단 또는 조합 UI 컴포넌트를 소유해서는 안 됩니다.
- Feature State, Action 또는 업무 모델을 UI 컴포넌트 공개 API에 노출해서는 안 됩니다.
- `extension Color`처럼 DesignSystem 밖에 시각 어휘를 정의해서는 안 됩니다. 필요한
  의미 이름은 DesignSystem에 추가합니다.
- 화면 파일 안에 별도 `View` 타입을 정의해서는 안 됩니다.
- 다른 Feature의 목적지 생성과 애플리케이션 전체 Navigation 정책을 소유해서는 안 됩니다.
