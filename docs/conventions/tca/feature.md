# Git It iOS TCA 컨벤션 — Feature 분리

**상태**: 초안

**작성일**: 2026-08-31

**최종 수정일**: 2026-09-13 (정의 단위를 화면 1:1에서 관심사로 교체하고 조합 규칙을 분리)

## 목적

이 문서는 TCA(The Composable Architecture) Feature를 어떤 단위로 정의하고, 나눈
Feature를 어떻게 조합하며, Feature가 공개하는 표면을 어디까지로 제한할지를 정의합니다.
`State`·`Action` 설계는 [State 컨벤션](./state.md)·[Action 컨벤션](./action.md),
Reducer·Effect 작성은 [Effect 컨벤션](./effect.md), Navigation 출력은
[Navigation 컨벤션](./navigation.md)이 소유합니다.

문서 우선순위, 문서 구조와 문서 간 참조 규칙은
[컨벤션 공통 원칙](../common/README.md)이 소유합니다.

## 1. 적용 범위

- `sources/Projects/Feature/**`의 Feature 정의 단위 판단과 Feature 조합에 적용합니다.
- Feature가 App 또는 부모 Feature에 공개하는 표면(Reducer, 화면, delegate)에
  적용합니다.
- `State`·`Action` 설계, Reducer·Effect 작성과 Navigation 출력은 각 소유 문서가 적용
  범위를 갖습니다.

## 2. 정의 단위 — 관심사

Feature 하나의 정의 단위는 하나의 관심사입니다.

→ [정의 단위 — 관심사](./feature/definition-unit.md)

### 2.2 화면 전환 목적지

Router가 전환 단위로 삼는 목적지는 그 상태를 소유하는 Feature 또는 Feature 조합을 가져야 합니다.

→ [화면 전환 목적지](./feature/transition-destination.md)

## 3. Feature 조합

관심사로 나눈 Feature는 상위 Feature가 조합합니다.

→ [Feature 조합](./feature/composition.md)

## 4. 정의 단위의 검증 — 단위 테스트

§2가 관심사 판단이라면 이 절은 그 판단의 검증입니다.

→ [정의 단위의 검증 — 단위 테스트](./feature/test-validation.md)

## 5. 공개 표면

Feature의 공개 표면은 App이 생성하는 Reducer·화면과 App이 해석할 delegate로 제한되며,
그 제약의 정본은 [Feature 패키지 규칙](../../package-rules/feature.md#공개-계약과-의존성)입니다.

## 6. 검토 체크리스트

- [ ] Feature가 화면이나 View 파일 수가 아니라 관심사 하나를 단위로 정의되었는가?
- [ ] 관심사가 여럿인 화면이 Feature를 여럿 조합하는가? 한 Feature가 여러 관심사를
      함께 쥐고 있지 않은가?
- [ ] Router-Feature가 화면 전환 외의 관심사를 함께 쥐지 않고 별개 Feature로 조합하는가?
- [ ] Router가 전환 단위로 삼는 목적지마다 그 상태를 소유하는 Feature 또는 Feature
      조합이 있는가?
- [ ] 화면의 Feature가 흐름의 다른 화면으로 가는 목적지 상태를 갖지 않고 `delegate`로만
      알리는가?
- [ ] 하위가 `delegate`로만 결과를 알리고, 상위가 하위 내부를 대신 운전하지 않는가?
- [ ] 여러 곳에서 쓰이는 관심사를 복제하지 않고 하나의 Feature로 각 상위가 조합하는가?
- [ ] Feature 하나의 단위 테스트에 주입하는 Test Double이 그 Feature의 관심사만큼으로
      유지되는가?
- [ ] 화면 Feature 테스트가 라우팅 결과가 아니라 `delegate` 방출까지만 검증하는가?
- [ ] 지속되는 Effect를 소유한 Feature에서 그 Effect의 취소를 단위 테스트로 검증할 수
      있는가?
- [ ] Feature의 공개 표면이 App이 생성하는 Reducer·화면과 delegate로 제한되는가?

## 관련 문서

- [아키텍처](../../architecture.md)
- [TCA 컨벤션](./README.md)
- [State 컨벤션](./state.md)
- [Action 컨벤션](./action.md)
- [Effect 컨벤션](./effect.md)
- [Navigation 컨벤션](./navigation.md)
- [View 컨벤션](../view.md)
- [UIComponent 컨벤션](../ui-component.md)
- [테스트 컨벤션](../test.md)
- [Feature 패키지 규칙](../../package-rules/feature.md)

## 문서 변경 기준

Feature의 정의 단위, 관심사 판별 기준, 조합 규칙, 단위 테스트 검증 기준 또는 공개 표면
제약이 바뀔 때 수정합니다. `State`·`Action` 설계가 바뀌면 이 문서가 아니라
[State 컨벤션](./state.md)·[Action 컨벤션](./action.md)을, Reducer·Effect 작성 방식이
바뀌면 [Effect 컨벤션](./effect.md)을, Router의 전환 관심사 범위가 바뀌면
[Navigation 컨벤션](./navigation.md)을 갱신합니다. Feature 패키지의 책임이나 의존
방향이 바뀌면 이 문서보다 아키텍처와 Feature 패키지 규칙을 먼저 갱신합니다.
