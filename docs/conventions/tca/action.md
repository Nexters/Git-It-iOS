# Git It iOS TCA 컨벤션 — Action

**상태**: 초안

**작성일**: 2026-08-31

**최종 수정일**: 2026-08-31 ([TCA 컨벤션](./README.md)에서 분리)

## 목적

이 문서는 Feature `Action`의 출처 분류, 이름과 payload 작성 기준, 그리고
`BindableAction`의 사용 범위를 정의합니다. Feature 분리 기준은
[Feature 컨벤션](./feature.md), `State` 설계는 [State 컨벤션](./state.md)이 소유합니다.

핵심 구분은 **Action은 이미 일어난 일이고, Effect는 앞으로 실행할 일**이라는
것입니다. 사용자 사건인 `retryTapped`를 받은 Reducer가 현재 상태를 해석해 조회
Effect를 반환하며, 앞으로 할 일을 그대로 명령하는 `fetchProjects` 같은 View Action을
만들지 않습니다. Effect 자체의 작성 방식은 [Effect 컨벤션](./effect.md)을 따릅니다.

문서 우선순위, 문서 구조와 문서 간 참조 규칙은
[컨벤션 공통 원칙](../common/README.md)이 소유합니다.

## 1. 적용 범위

- `sources/Projects/Feature/**`의 Feature `Action` 설계에 적용합니다.
- `sources/Projects/Feature/Tests/**`의 `TestStore` 기반 테스트 중 Action 검증에
  적용합니다.
- Feature 분리 기준과 `State` 설계는 [Feature 컨벤션](./feature.md)·
  [State 컨벤션](./state.md)이 적용 범위를 소유합니다.

## 2. 출처 분류

Action은 기본적으로 발생 출처에 따라 `view`, `effect`, `delegate`로 분류합니다.

→ [Action 출처 분류](./action/source.md)

## 3. 이름과 payload

View Action은 관찰된 사건, Effect event는 완료된 작업, Delegate는 외부에 알리는 의미를 이름으로 표현합니다.

→ [Action 이름과 payload](./action/naming.md)

## 4. Binding Action

`BindableAction`은 아직 제출되지 않은 텍스트, selection과 local form toggle처럼 화면의 draft 입력을 변경하는 용도로
제한합니다.

→ [Binding Action](./action/binding.md)

## 5. 검토 체크리스트

- [ ] Action이 `view`, `effect`, `delegate` 등 실제 출처를 구분하는가?
- [ ] View Action이 관찰된 사건을, Effect event가 완료된 작업을 표현하는가?
- [ ] Delegate가 App의 전환 방식을 명령하지 않고 완전한 payload를 전달하는가?
- [ ] `BindableAction`이 draft 입력 변경으로만 제한되고, 파괴적 작업은 명시적인 View
      Action을 거치는가?

## 관련 문서

- [아키텍처](../../architecture.md)
- [TCA 컨벤션](./README.md)
- [Feature 컨벤션](./feature.md)
- [State 컨벤션](./state.md)
- [Effect 컨벤션](./effect.md)
- [Navigation 컨벤션](./navigation.md)
- [Feature 패키지 규칙](../../package-rules/feature.md)

## 문서 변경 기준

`Action`의 출처 분류, 이름·payload 작성 기준 또는 `BindableAction` 사용 범위가 바뀔
때 수정합니다. Feature 분리 기준이 바뀌면 이 문서가 아니라
[Feature 컨벤션](./feature.md)을, `State` 설계가 바뀌면
[State 컨벤션](./state.md)을 갱신합니다.
