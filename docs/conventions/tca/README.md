# Git It iOS TCA 컨벤션

**상태**: 초안

**작성일**: 2026-08-21

**최종 수정일**: 2026-09-13 (Feature의 정의 단위를 관심사로 교체)

## 목적

이 문서는 Feature가 TCA(The Composable Architecture)로 사용자 기능을 구현할 때
공통으로 적용하는 핵심 용어와 제약조건을 정의하고, 세부 규칙을 담은 하위 문서로
안내하는 진입점입니다. 각 하위 문서는 자기 완결적으로 읽을 수 있으며, 소유 범위는
아래 §3의 표를 따릅니다.

Feature 패키지의 책임과 허용 의존성은 [Feature 패키지 규칙](../../package-rules/feature.md)이
소유합니다. 문서 우선순위, 문서 구조와 문서 간 참조 규칙은
[컨벤션 공통 원칙](../common/README.md)이 소유합니다.

## 1. 적용 범위

- `sources/Projects/Feature/**`의 모든 TCA Feature 구현에 적용합니다.
- `sources/Projects/Feature/Tests/**`의 `TestStore` 기반 테스트에 적용합니다.
- App이 Feature의 Reducer와 화면을 생성하거나 delegate·navigation intent를 해석할 때
  공개 계약 부분에 적용합니다.
- Domain 규칙, production 구현 선택과 앱 전체 Navigation 정책은 이 문서 계열의 범위가
  아닙니다.

## 2. 핵심 용어

| 용어 | 정의 | 포함하지 않는 것 |
| --- | --- | --- |
| Feature | 하나의 관심사 — 함께 변하고 함께 검증되는 상태·전이·Effect의 묶음 | 화면 하나와의 1:1 대응, SwiftUI 파일이나 단순 레이아웃 |
| State | 현재 Feature가 사실로 간주하는 최소 정보 | dependency, `Task`, Effect와 중복 파생값 |
| Action | 이미 발생했거나 Feature가 수신한 사건 | 앞으로 실행할 작업을 나타내는 명령 |
| Reducer | 현재 State와 Action을 해석해 다음 State와 실행할 Effect를 결정하는 경계 | 직접 비동기 작업을 시작하는 코드 |
| Effect | Reducer가 실행하도록 반환하는 비동기·외부 작업 | 로딩 여부와 같은 상태 값 |
| Effect event | Effect가 완료되거나 값을 수신한 뒤 Reducer로 돌려보내는 사건 | Effect 자체 |
| Delegate | Feature가 부모 또는 App에 전달하는 결과·의도 | 실제 애플리케이션 Navigation 실행 |
| Destination | 현재 Feature 수명 안에서 소유하는 sheet·alert·내부 화면 상태 | 다른 최상위 Feature로 이동하는 App Navigation |
| Router-Feature | 화면 전환이라는 관심사 하나만 소유하고 화면들의 Feature를 조합하는 상위 Feature | 화면 상태, 업무 로직, 진입 준비와 결과 판단 |
| 활성 화면 값 | Router가 소유하는, 현재 어떤 화면이 활성인지를 나타내는 enum | 흐름을 벗어남을 뜻하는 case |

핵심 구분은 **Action은 이미 일어난 일이고, Effect는 앞으로 실행할 일**이라는 것입니다.
자세한 내용은 [Action 컨벤션](./action.md)·[Effect 컨벤션](./effect.md)을 따릅니다.

## 3. 문서 구성

| 문서 | 소유하는 규칙 |
| --- | --- |
| [Feature](./feature.md) | 정의 단위(관심사), 관심사 판별, 화면 전환 목적지, Feature 조합, 단위 테스트 기반 검증, 공개 표면 |
| [State](./state.md) | State 정본과 파생값, 상태 형태, 요청 식별, SwiftUI 로컬 상태 |
| [Action](./action.md) | Action 출처 분류, 이름·payload, Binding Action |
| [Effect](./effect.md) | Reducer 책임, dependency 주입, Effect 작성·취소, 테스트 |
| [Navigation](./navigation.md) | Destination, delegate, 화면-Store 연결, Router-Feature |

## 4. 제약조건

Feature가 지켜야 하는 의존성·소유 제약의 정본은
[Feature 패키지 규칙의 제약조건](../../package-rules/feature.md#제약조건)입니다.

이 문서 계열은 그 제약을 TCA 구현에서 지키는 방법을 각 하위 문서에서 설명합니다 —
State 정본과 파생값은 [State 컨벤션 — 정본과 파생값](./state/source-of-truth.md), dependency
주입은 [Effect 컨벤션 — 의존성 주입](./effect/dependency-injection.md), Reducer의 책임 경계는
[Effect 컨벤션 — Reducer 책임](./effect/reducer.md), Navigation 출력은
[Navigation 컨벤션 — Navigation 경계](./navigation/boundary.md), UIComponent 경계는
[Navigation 컨벤션 — TCA 화면과 Store 연결](./navigation/tca-screen.md)입니다.

## 5. 검토 체크리스트

이 문서는 하위 문서의 체크리스트를 대신하지 않습니다. 각 하위 문서가 자신의 규칙에
대한 체크리스트를 소유합니다 — [Feature](./feature.md#6-검토-체크리스트),
[State](./state.md#6-검토-체크리스트), [Action](./action.md#5-검토-체크리스트),
[Effect](./effect.md#4-검토-체크리스트), [Navigation](./navigation.md#3-검토-체크리스트).

## 관련 문서

- [아키텍처](../../architecture.md)
- [Feature 패키지 규칙](../../package-rules/feature.md)
- [App 패키지 규칙](../../package-rules/app.md)
- [View 컨벤션](../view.md)
- [UIComponent 컨벤션](../ui-component.md)
- [테스트 컨벤션](../test.md)

## 문서 변경 기준

핵심 용어, 문서 구성 또는 제약조건 매핑이 바뀔 때 수정합니다. Feature 단위·State·
Action·Reducer·Effect·Navigation 각각의 세부 규칙은 이 문서가 아니라 §3의 해당
하위 문서를 갱신합니다. Feature 패키지의 책임이나 의존 방향이 바뀌면 이 문서보다
아키텍처와 Feature 패키지 규칙을 먼저 갱신합니다.
