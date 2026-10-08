# Git It iOS TCA 컨벤션 — Reducer와 Effect

**상태**: 초안

**작성일**: 2026-08-31

**최종 수정일**: 2026-08-31 ([TCA 컨벤션](./README.md)에서 분리)

## 목적

이 문서는 TCA Reducer가 State를 전이시키고 Effect를 반환하는 방식, dependency 주입,
Effect 작성과 취소 정책, 그리고 이를 검증하는 테스트 방식을 정의합니다. Feature 분리
기준은 [Feature 컨벤션](./feature.md), State·Action 설계는
[State 컨벤션](./state.md)·[Action 컨벤션](./action.md), Navigation 출력과 화면 연결은
[Navigation 컨벤션](./navigation.md)이 소유합니다.

문서 우선순위, 문서 구조와 문서 간 참조 규칙은
[컨벤션 공통 원칙](../common/README.md)이 소유합니다.

## 1. 적용 범위

- `sources/Projects/Feature/**`의 Reducer 구현과 Effect 작성에 적용합니다.
- `sources/Projects/Feature/Tests/**`의 `TestStore` 기반 테스트 중 Effect·취소·delegate
  출력 검증에 적용합니다.
- Feature 분리 기준, `State`·`Action` 설계는
  [Feature](./feature.md)·[State](./state.md)·[Action](./action.md) 컨벤션이 적용
  범위를 소유합니다.

## 2. Reducer와 Effect

Reducer는 상태 전이를 동기적으로 결정하고, 외부와의 상호작용은 반환한 Effect가 수행합니다. Reducer가 직접 비동기 작업을 시작하지 않는다는
경계 위에서 의존성 주입, Effect 작성과 취소 정책이 정해집니다.

### 2.1 Reducer 책임

Reducer는 State와 Action을 해석해 State를 동기적으로 전이하고 실행할 Effect를 반환합니다.

→ [Reducer 책임](./effect/reducer.md)

### 2.2 의존성 주입

Effect에 필요한 Domain dependency는 Reducer의 초기화 메서드나 명시적인 초기화 인자로 주입합니다.

→ [의존성 주입](./effect/dependency-injection.md)

### 2.3 Effect 작성

Effect는 Domain Use Case 호출, 비동기 대기, timer·clock, notification·stream 관찰, cancellation 또는
후속 Action 전달이 필요할 때만 만듭니다.

→ [Effect 작성](./effect/writing.md)

### 2.4 취소와 mutation

취소 정책은 작업의 의미에 따라 구분합니다.

→ [취소와 mutation](./effect/cancellation.md)

## 3. 테스트

`TestStore`는 상태 전이, Effect event, 취소, 늦은 응답과 delegate 출력을 검증합니다.

→ [Effect 테스트](./effect/testing.md)

## 4. 검토 체크리스트

- [ ] `Reduce`가 최상위 Action case만 분기하고, 연관값마다 한 단계씩 분기 함수로 나누는가?
- [ ] dependency가 Reducer initializer로 주입되고 private 불변 프로퍼티로 보존되는가?
- [ ] Effect의 성공·실패·취소와 소유 State 제거 경로가 명시적인가?
- [ ] 서버 mutation이 `committing` 뒤 취소되지 않고 충돌 입력을 차단하는가?
- [ ] `TestStore`가 상태 전이, Effect event, 취소, 늦은 응답과 delegate 출력을 검증하는가?

## 관련 문서

- [아키텍처](../../architecture.md)
- [TCA 컨벤션](./README.md)
- [Feature 컨벤션](./feature.md)
- [State 컨벤션](./state.md)
- [Action 컨벤션](./action.md)
- [Navigation 컨벤션](./navigation.md)
- [테스트 컨벤션](../test.md)
- [Feature 패키지 규칙](../../package-rules/feature.md)

## 문서 변경 기준

Reducer의 책임 경계, dependency 주입 방식, Effect 작성·취소 정책 또는 Effect 테스트
방식이 바뀔 때 수정합니다. Feature 분리 기준이 바뀌면 [Feature 컨벤션](./feature.md)을,
State·Action 구성이 바뀌면 [State 컨벤션](./state.md)·[Action 컨벤션](./action.md)을,
Navigation 출력과 화면 연결이 바뀌면 [Navigation 컨벤션](./navigation.md)을
갱신합니다.
