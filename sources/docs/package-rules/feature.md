# Feature 패키지 규칙

**상태**: 초안

**작성일**: 2026-08-07

## 설명

Feature는 사용자가 인지하는 기능을 TCA 기반 상태, 사용자 상호작용과 화면으로 구현하는 Presentation 경계입니다. State, Action, Reducer와 View를 통해 사용자 입력을 처리하고 Domain 기능의 결과를 화면 상태로 반영합니다.

Feature는 Domain이 제공하는 비즈니스 기능을 사용하고 UI가 제공하는 공용 시각 요소를 조립합니다. Feature 바깥의 화면 흐름이 필요한 경우 App이 해석할 수 있는 delegate 또는 navigation intent를 출력합니다.

## 정책

- 공개 이름은 [네이밍 가이드](../naming.md)를 따르며 사용자 기능과 Presentation 책임을 드러내고 Data·Core 또는 production 구현 문맥을 노출해서는 안 됩니다.
- 모든 내부 target은 하나 이상의 사용자 기능을 표현하는 화면, 상태, Action, Reducer 또는 Presentation 흐름을 소유해야 합니다.
- 비즈니스 기능은 Domain이 제공하는 타입과 계약을 통해 사용해야 합니다.
- 외부 Effect에 필요한 dependency는 initializer 또는 명시적인 초기화 인자로 주입받아야 합니다.
- 공용 UI 구성요소는 UI가 제공하는 API를 통해 사용해야 합니다.
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
- 여러 Feature가 공유하는 범용 UI 구성요소를 소유해서는 안 됩니다.
- 다른 Feature의 목적지 생성과 애플리케이션 전체 Navigation 정책을 소유해서는 안 됩니다.
