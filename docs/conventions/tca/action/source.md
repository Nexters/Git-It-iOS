# Action 출처 분류

[Git It iOS TCA 컨벤션 — Action](../action.md)의 규칙 문서입니다.

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
        case itemRowTapped(itemID: String)
        case deletionConfirmed
    }

    public enum EffectEvent: Sendable, Equatable {
        case itemsLoadFinished(
            requestID: Int,
            result: Result<ExamplePage, ExampleError>
        )
    }

    public enum Delegate: Sendable, Equatable {
        case detailRequested(route: ExampleRoute)
    }
}
```
