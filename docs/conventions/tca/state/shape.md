# 상태 형태

[Git It iOS TCA 컨벤션 — State](../state.md)의 규칙 문서입니다.

- 서로 배타적인 상태는 여러 `Bool`과 optional 조합 대신 연관 값을 가진 `enum`으로
  표현합니다.
- 동시에 진행할 수 있는 operation은 하나의 거대한 상태 열거형에 합치지 않고 각각의
  상태로 분리합니다. 초기 조회, pagination과 삭제는 서로 병행 가능하면 별도 상태를
  가집니다.
- payload가 없고 실제로 두 경우만 존재하는 표현 상태에는 `Bool`을 사용할 수 있습니다.
- Child 수명은 optional child State나 `@Presents`처럼 생성과 제거가 드러나는 상태로
  표현합니다. 순차 흐름의 화면 State는 예외로 Router가 항상 보유합니다
  ([Navigation 컨벤션 — Router](../navigation/router.md)).
- 실패 상태는 Domain 오류의 의미와 사용자가 실행할 수 있는 재시도·복구 경로를
  보존합니다.

```swift
public enum Deletion: Sendable, Equatable {
    case idle
    case confirming(itemID: String)
    case committing(itemID: String, requestID: Int)
    case failed(itemID: String, error: ExampleError)
}

@ObservableState
public struct State: Sendable, Equatable {
    public var items: [ExampleItem] = []
    public var initialLoad: InitialLoad = .idle
    public var pagination: Pagination = .idle
    public var deletion: Deletion = .idle
    public var isMenuPresented = false
}
```

`isDeleting`, `pendingDeletion`과 `isDeletionLoading`처럼 하나의 배타 프로세스를 여러
프로퍼티로 나눠 유효하지 않은 조합을 만들지 않습니다.
