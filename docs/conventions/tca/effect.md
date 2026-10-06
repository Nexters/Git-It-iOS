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

상위 문서와의 우선순위는
[컨벤션 공통 규칙](../README.md#상위-문서와-충돌-해소)을 따릅니다.

## 1. 적용 범위

- `sources/Projects/Feature/**`의 Reducer 구현과 Effect 작성에 적용합니다.
- `sources/Projects/Feature/Tests/**`의 `TestStore` 기반 테스트 중 Effect·취소·delegate
  출력 검증에 적용합니다.
- Feature 분리 기준, `State`·`Action` 설계는
  [Feature](./feature.md)·[State](./state.md)·[Action](./action.md) 컨벤션이 적용
  범위를 소유합니다.

## 2. Reducer와 Effect

### 2.1 Reducer 책임

- Reducer는 현재 State와 Action을 해석해 State를 동기적으로 전이하고 실행할 Effect를
  반환합니다.
- 화면 상태를 바꾸는 판단, 사용자 의도 해석과 유효하지 않은 입력 차단은 Reducer가
  소유합니다.
- Reducer나 View 안에서 `Task`를 만들거나 Use Case, `URLSession`,
  `NotificationCenter` 같은 외부 작업을 직접 실행하지 않습니다.
- Domain의 비즈니스 규칙을 Reducer에 다시 구현하지 않고 주입받은 Domain contract를
  Effect에서 호출합니다.
- 오류를 무시하거나 View가 Domain 오류를 직접 해석하게 하지 않습니다.

### 2.2 의존성 주입

- Effect에 필요한 Domain dependency는 Reducer의 초기화 메서드 또는 명시적인 초기화
  인자로 주입합니다.
- production dependency는 Reducer의 private 불변 저장 프로퍼티로 보존합니다.
- TCA Dependencies의 `@Dependency`, dependency key, Service Locator 또는 전역 mutable
  container를 production dependency 전달 수단으로 사용하지 않습니다.
- 테스트는 같은 initializer에 Test Double을 직접 주입합니다.

```swift
@Reducer
public struct ProjectFeature: Sendable {
    public init(fetchProject: any FetchProjectUseCase) {
        self.fetchProject = fetchProject
    }

    private let fetchProject: any FetchProjectUseCase
}
```

### 2.3 Effect 작성

Effect는 Domain Use Case 호출, 비동기 대기, timer·clock, notification·stream 관찰,
cancellation 또는 후속 Action 전달이 필요할 때만 만듭니다.

- Effect는 성공, 실패와 취소 시의 State 정리 경로를 명확히 합니다.
- 알려진 Domain 오류는 보존하고 알 수 없는 오류는 Feature가 의존하는 Domain 오류의
  fallback case로 변환합니다. `any Error`를 Action이나 State에 전달하지 않습니다.
- 교체 가능한 요청은 request identity와 cancellation ID를 함께 사용해 최신 결과만
  반영합니다.
- 동시에 실행되면 안 되거나 소유 State 제거 시 끝나야 하는 Effect에는 안정적인
  cancellation ID와 명시적인 취소 경로를 둡니다.
- helper 이름은 `loadInitialProjects`, `deleteProject`처럼 대상과 의도를 표현합니다.
  반환 타입이 이미 `Effect<Action>`이면 `Effect`를 이름에 반복하지 않습니다.

### 2.4 취소와 mutation

취소 정책은 작업의 의미에 따라 구분합니다.

| 작업 | `cancelInFlight` | 사용자 취소 |
| --- | --- | --- |
| 검색·검증·새로고침처럼 새 요청이 이전 요청을 대체 | 허용 | 최신 요청만 유지할 수 있음 |
| pagination | 동일 page 중복만 차단하고 원칙적으로 대체하지 않음 | 명시적인 화면 정책이 있을 때만 |
| debounce·delay | 허용 | 새 입력이 이전 작업을 대체 |
| 장기 observation | 허용 | 소유 State 제거 시 취소 |
| 서버 mutation | `true` 금지 | 요청 전 confirmation에서만 허용 |

로컬 Effect를 취소하는 것은 서버 mutation이 rollback됐다는 의미가 아닙니다. 삭제, 제출,
탈퇴 같은 파괴적 작업은 `idle → confirming → committing → success | failure` 상태 전이를
드러내고 다음을 지킵니다.

- `confirming`에서는 취소할 수 있습니다.
- `committing` 진입 뒤에는 중복 요청, 취소와 해당 상태를 잃는 dismiss를 차단합니다.
- 성공하기 전에 서버 정본과 연결된 local 항목을 제거하지 않습니다.
- 불가피하게 화면 수명이 먼저 끝나 결과를 잃을 수 있으면, 소유자를 상위로 올리거나
  재진입 시 서버 정본을 다시 조회하는 조정 경로를 둡니다.

## 3. 테스트

- Domain dependency는 initializer로 Test Double을 주입합니다.
- 사용자 입력과 부모 input은 `store.send`, Effect event와 delegate 출력은
  `store.receive`로 검증합니다.
- 상태 변화는 관련 Action을 처리하는 단계에서 명시합니다.
- 배타 상태에서 유효하지 않은 Action이 State나 Effect를 바꾸지 않는지 검증합니다.
- 교체 가능한 요청은 이전 request identity의 늦은 결과를 거부하고 최신 결과만 반영하는지
  검증합니다.
- 동시에 실행되면 안 되는 Effect의 중복 차단, cancellation과 소유 State 제거 시 정리를
  검증합니다.
- mutation은 `committing` 동안 중복 입력과 취소를 차단하고 성공·실패 뒤 정본과 복구
  상태가 일치하는지 검증합니다.
- 취소 가능한 미완료 Effect는 테스트 종료 전에 정의된 취소 Action을 보내고 `finish()`로
  정리합니다. `committing` 상태의 mutation은 취소하지 않고 성공 또는 실패 결과까지
  수신합니다.
- 화면 밖 흐름은 실제 navigation을 실행하지 않고 Feature가 출력한 delegate Action으로
  검증합니다.
- 테스트는 `Tests/<기능>/` 아래에서 State, Effect, 사용자 상호작용과 delegate 출력을
  중심으로 구성합니다.

테스트 이름, 비동기 종료, Test Double과 target 구성의 공통 규칙은
[테스트 컨벤션](../test.md)을 따릅니다.

## 4. 검토 체크리스트

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
