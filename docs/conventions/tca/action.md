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

상위 문서와의 우선순위는
[컨벤션 공통 규칙](../README.md#상위-문서와-충돌-해소)을 따릅니다.

## 1. 적용 범위

- `sources/Projects/Feature/**`의 Feature `Action` 설계에 적용합니다.
- `sources/Projects/Feature/Tests/**`의 `TestStore` 기반 테스트 중 Action 검증에
  적용합니다.
- Feature 분리 기준과 `State` 설계는 [Feature 컨벤션](./feature.md)·
  [State 컨벤션](./state.md)이 적용 범위를 소유합니다.

## 2. 출처 분류

Action은 기본적으로 발생 출처에 따라 `view`, `effect`, `delegate`로 분류합니다. 부모의
외부 조정 신호가 실제로 필요할 때만 `input`을, composition이 있을 때만 child Action과
`destination`을 추가합니다. 사용하지 않는 분류를 형식적으로 만들지 않습니다.

| 분류 | 보내는 주체 | 역할 |
| --- | --- | --- |
| `view` | SwiftUI 화면 | 사용자 입력과 화면 lifecycle 사건 |
| `input` | 부모 Feature 또는 App | 외부 조정 신호 |
| `effect` | Effect | 비동기 완료·실패·stream event |
| child case | Child Reducer | Feature composition |
| `destination` | TCA presentation | sheet·alert·내부 화면 Action |
| `delegate` | 현재 Reducer | 부모 또는 App에 전달할 결과·의도 |

TCA 화면은 `@ViewAction`과 `ViewAction`을 사용해 화면이 `View` Action만 보낼 수 있도록
경계를 코드로 드러냅니다.

```swift
public enum Action: ViewAction, Sendable, Equatable {
    case view(View)
    case effect(EffectEvent)
    case delegate(Delegate)

    @CasePathable
    public enum View: Sendable, Equatable {
        case task
        case retryTapped
        case projectRowTapped(projectID: String)
        case deletionConfirmed
    }

    public enum EffectEvent: Sendable, Equatable {
        case projectsLoadFinished(
            requestID: Int,
            result: Result<LearningProjectPage, LearningProjectError>
        )
    }

    public enum Delegate: Sendable, Equatable {
        case learningRequested(route: LearningRoute)
    }
}
```

## 3. 이름과 payload

- View Action은 `retryTapped`, `refreshRequested`, `deletionConfirmed`처럼 관찰된 사용자
  사건이나 lifecycle 사건으로 이름을 짓습니다.
- `fetchProjects`, `deleteProject`, `navigateToQuiz`, `showError`처럼 앞으로 할 작업이나
  구현 결정을 View Action 이름으로 사용하지 않습니다.
- 성공과 실패를 하나의 `Result`로 전달하는 Effect event는
  `projectsLoadFinished`처럼 완료된 작업을 표현합니다. `Response`는 실제 응답 객체가
  Feature 경계에서 의미를 가질 때만 사용합니다.
- Delegate는 `learningRequested`, `projectSelected`, `authenticationRequired`처럼
  Feature가 외부에 알리는 의미를 표현하고 `pushProjectDetail`처럼 App의 전환 방식을
  명령하지 않습니다.
- Delegate payload는 App이 제거될 Child State를 다시 조회하지 않고도 즉시 해석할 수
  있도록 목적지 결정에 필요한 값을 완전하게 전달합니다.
- 사용자가 직접 발생시킬 수 없는 Effect event와 delegate를 View가 보내지 못하게
  Action 접근 경계를 유지합니다.

## 4. Binding Action

`BindableAction`은 아직 제출되지 않은 텍스트, selection과 local form toggle처럼 화면의
draft 입력을 변경하는 용도로 제한합니다. 삭제, 탈퇴, 북마크 또는 서버 정본을 즉시
바꾸는 작업은 binding setter에서 실행하지 않고 `submitTapped`, `deletionConfirmed`와
같은 명시적인 View Action을 거칩니다.

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
