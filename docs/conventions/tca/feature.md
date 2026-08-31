# Git It iOS TCA 컨벤션 — Feature 분리

**상태**: 초안

**작성일**: 2026-08-31

**최종 수정일**: 2026-08-31 ([TCA 컨벤션](./README.md)에서 분리)

## 목적

이 문서는 TCA(The Composable Architecture) Feature를 어떤 단위로 나누고, 언제 Child
Feature로 분리하며, Feature가 공개하는 표면을 어디까지로 제한할지를 정의합니다.
`State`·`Action` 설계는 [State 컨벤션](./state.md)·[Action 컨벤션](./action.md),
Reducer·Effect 작성은 [Effect 컨벤션](./effect.md), Navigation 출력은
[Navigation 컨벤션](./navigation.md)이 소유합니다.

상위 문서와의 우선순위는
[컨벤션 공통 규칙](../README.md#상위-문서와-충돌-해소)을 따릅니다.

## 1. 적용 범위

- `sources/Projects/Feature/**`의 Feature 단위 판단과 Child Feature 분리 여부에
  적용합니다.
- Feature가 App 또는 부모 Feature에 공개하는 표면(Reducer, 화면, delegate)에
  적용합니다.
- `State`·`Action` 설계, Reducer·Effect 작성과 Navigation 출력은 각 소유 문서가 적용
  범위를 갖습니다.

## 2. Feature 단위

- Feature는 SwiftUI `View` 타입이나 디자인 프레임 수가 아니라 논리적인 상태 소유자를
  기준으로 나눕니다.
- 하나의 사용자 기능은 `@Reducer`가 붙은 Feature 타입 하나를 중심으로 구성합니다.
- 같은 논리 화면의 loading, loaded, empty, menu, confirmation과 오류 표현은 별도
  Feature가 아니라 원칙적으로 하나의 Feature가 소유하는 State 변형입니다.
- 하나의 Feature는 여러 View를 렌더링할 수 있고, 하나의 화면은 부모 Feature와 여러
  Child Feature를 조합할 수 있으므로 Feature와 View를 1:1로 맞추지 않습니다.
- 한 사용자 기능의 Reducer와 화면은 `<기능>/`에 함께 둡니다.
- 여러 화면이 공유하는 View가 아닌 Presentation 보조 타입만 `Shared/`에
  둘 수 있습니다.

논리 화면이나 상태 영역이 다음 중 하나 이상을 소유하면 Feature 후보로 봅니다.

- Use Case 입력, 제출 가능 여부 또는 Navigation 목적지처럼 제품 동작을 바꾸는 상태
- Action에 따른 상태 전이와 독립적으로 검증할 가치가 있는 불변식
- 비동기 작업, 오류 복구, validation 또는 cancellation 수명
- 화면 재진입 뒤 보존하거나 다른 화면·부모가 관찰해야 하는 사용자 입력과 진행 상태

누름 애니메이션, geometry 측정, 일시적인 highlight, 부모 State에서 완전히 계산되는
표시 값이나 callback만 전달하는 행은 Feature 분리 근거가 아닙니다.

## 3. Child Feature 분리

다음 중 하나 이상을 만족하면 Child Feature 분리를 우선 검토합니다.

- 독립적인 비동기 Effect와 cancellation 수명을 가집니다.
- 자체 오류·재시도 상태와 상태 전이 규칙을 가집니다.
- 부모와 별도로 제시·제거되며 그 생성과 제거가 상태 수명을 결정합니다.
- 여러 화면에서 동일한 제품 동작 단위로 재사용됩니다.
- 부모가 하위 상태의 불변식을 계속 대신 관리해야 합니다.

표시 값과 callback만 가지거나 부모 State에서 완전히 파생되는 하위 View는
[UIComponent 컨벤션](../ui-component.md)의 재사용 기준을 적용합니다. 단순
confirmation은 부모의 배타 상태나 Destination으로 표현할 수 있으며, 그 안에서 독립적인
mutation, 실패 복구와 수명을 소유할 때 Child Feature 분리를 검토합니다.

## 4. 공개 표면

- `State`, `Action`, 목적지 상태와 cancellation ID는 해당 Feature 타입이 소유합니다.
- Feature의 공개 표면은 App이 생성하는 Reducer와 화면, App이 해석할 delegate 또는
  navigation intent로 제한합니다.
- Child Feature는 부모가 조합하고, 다른 최상위 Feature의 목적지 생성과 앱 전체
  Navigation은 App에 위임합니다.

## 5. 검토 체크리스트

- [ ] Feature가 View 파일이나 디자인 프레임이 아니라 고유한 상태와 수명을 기준으로
      나뉘는가?
- [ ] 독립적인 Effect·오류 복구·수명이 있는 하위 동작은 Child Feature 분리를 검토했는가?
- [ ] Feature의 공개 표면이 App이 생성하는 Reducer·화면과 delegate로 제한되는가?
- [ ] Child Feature의 목적지 생성과 앱 전체 Navigation을 App에 위임하는가?

## 관련 문서

- [아키텍처](../../architecture.md)
- [TCA 컨벤션](./README.md)
- [State 컨벤션](./state.md)
- [Action 컨벤션](./action.md)
- [Effect 컨벤션](./effect.md)
- [Navigation 컨벤션](./navigation.md)
- [UIComponent 컨벤션](../ui-component.md)
- [Feature 패키지 규칙](../../package-rules/feature.md)

## 문서 변경 기준

Feature 단위 판단 기준, Child Feature 분리 기준 또는 공개 표면 제약이 바뀔 때
수정합니다. `State`·`Action` 설계가 바뀌면 이 문서가 아니라
[State 컨벤션](./state.md)·[Action 컨벤션](./action.md)을, Reducer·Effect 작성 방식이
바뀌면 [Effect 컨벤션](./effect.md)을 갱신합니다. Feature 패키지의 책임이나 의존
방향이 바뀌면 이 문서보다 아키텍처와 Feature 패키지 규칙을 먼저 갱신합니다.
