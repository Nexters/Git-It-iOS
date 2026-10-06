# Git It iOS TCA 컨벤션 — State

**상태**: 초안

**작성일**: 2026-08-31

**최종 수정일**: 2026-08-31 ([TCA 컨벤션](./README.md)에서 분리)

## 목적

이 문서는 Feature `State`가 소유하는 정본의 범위, 배타·병행 상태의 표현 방식, 교체
가능한 요청을 식별하는 방법과 화면 로컬 SwiftUI 상태의 허용 조건을 정의합니다.
Feature 분리 기준은 [Feature 컨벤션](./feature.md), `Action` 설계는
[Action 컨벤션](./action.md)이 소유합니다.

상위 문서와의 우선순위는
[컨벤션 공통 규칙](../README.md#상위-문서와-충돌-해소)을 따릅니다.

## 1. 적용 범위

- `sources/Projects/Feature/**`의 Feature `State` 설계에 적용합니다.
- `sources/Projects/Feature/Tests/**`의 `TestStore` 기반 테스트 중 State 검증에
  적용합니다.
- Feature 분리 기준과 `Action` 설계는 [Feature 컨벤션](./feature.md)·
  [Action 컨벤션](./action.md)이 적용 범위를 소유합니다.

## 2. 정본과 파생값

- `State`는 사용자가 인지하는 Presentation 상태와 화면 흐름에 필요한 최소 정본만
  소유합니다.
- 화면에 필요한 Domain 모델과 ID, 사용자 입력과 operation 상태는 보존할 수 있지만
  Domain 규칙이나 Data DTO를 복제하지 않습니다.
- 표시 문자열, progress 비율과 버튼 활성 여부처럼 정본에서 전부 계산할 수 있는 값은
  computed property나 View 변환으로 만듭니다.
- 같은 값을 화면 `ViewModel`, SwiftUI `@State` 또는 별도 참조 타입에 복제하지 않습니다.
- UI 표시를 위한 변환은 할 수 있지만 누락된 ID를 생성하거나 문자열을 해석해 Domain
  의미를 새로 추론하지 않습니다.

State에는 다음을 저장하지 않습니다.

- `Effect<Action>`, `Task`, Use Case, Repository, dependency 또는 closure
- UIComponent의 표시 입력을 묶은 wrapper
- 서버 메시지 원문이나 `any Error`
- Domain 값에서 단순 계산할 수 있는 중복 표시값
- 현재 요청과 연결되지 않아 유효성을 판단할 수 없는 임시 응답

## 3. 상태 형태

- 서로 배타적인 상태는 여러 `Bool`과 optional 조합 대신 연관 값을 가진 `enum`으로
  표현합니다.
- 동시에 진행할 수 있는 operation은 하나의 거대한 상태 열거형에 합치지 않고 각각의
  상태로 분리합니다. 초기 조회, pagination과 삭제는 서로 병행 가능하면 별도 상태를
  가집니다.
- payload가 없고 실제로 두 경우만 존재하는 표현 상태에는 `Bool`을 사용할 수 있습니다.
- Child 수명은 optional child State, `@Presents` 또는 `StackState`처럼 생성과 제거가
  드러나는 상태로 표현합니다.
- 실패 상태는 Domain 오류의 의미와 사용자가 실행할 수 있는 재시도·복구 경로를
  보존합니다.

```swift
public enum Deletion: Sendable, Equatable {
    case idle
    case confirming(projectID: String)
    case committing(projectID: String, requestID: Int)
    case failed(projectID: String, error: LearningProjectError)
}

@ObservableState
public struct State: Sendable, Equatable {
    public var projects: [LearningProjectSummary] = []
    public var initialLoad: InitialLoad = .idle
    public var pagination: Pagination = .idle
    public var deletion: Deletion = .idle
    public var isMenuPresented = false
}
```

`isDeleting`, `pendingDeletion`과 `isDeletionLoading`처럼 하나의 배타 프로세스를 여러
프로퍼티로 나눠 유효하지 않은 조합을 만들지 않습니다.

## 4. 요청 식별

- 새 요청이 이전 요청을 대체하거나 같은 종류의 요청이 겹칠 수 있으면 State가 현재
  request generation 또는 request ID를 보존합니다.
- Effect event는 자신이 속한 request identity를 함께 전달하고, Reducer는 현재 요청과
  일치하는 결과만 반영합니다.
- cancellation만으로 늦은 응답이 State에 반영되지 않는다고 가정하지 않습니다.
- 서로 겹칠 수 없도록 State 전이로 입력을 차단한 mutation에는 불필요한 request ID를
  추가하지 않아도 되지만, 결과의 대상 ID는 event에 보존합니다.

## 5. SwiftUI 로컬 상태

`@State`와 `@FocusState`는 다음 조건을 모두 만족할 때만 화면에 둘 수 있습니다.

- View가 사라질 때 손실돼도 제품 동작이 바뀌지 않습니다.
- Use Case 입력이나 Navigation에 영향을 주지 않습니다.
- Reducer test 대상이 아닙니다.
- 부모나 다른 화면이 관찰할 필요가 없습니다.
- 비동기 Effect를 시작하거나 취소하지 않습니다.

하나라도 만족하지 않으면 Feature State가 소유합니다.

## 6. 검토 체크리스트

- [ ] State가 최소 정본만 저장하고 파생값, dependency, Task와 Effect를 저장하지 않는가?
- [ ] 배타 상태는 `enum`, 병행 가능한 operation은 별도 상태로 표현하는가?
- [ ] 교체 가능한 요청에 request identity가 있고 늦은 결과를 거부하는가?
- [ ] SwiftUI 로컬 상태가 §5의 다섯 조건을 모두 만족하는가?

## 관련 문서

- [아키텍처](../../architecture.md)
- [TCA 컨벤션](./README.md)
- [Feature 컨벤션](./feature.md)
- [Action 컨벤션](./action.md)
- [Effect 컨벤션](./effect.md)
- [Feature 패키지 규칙](../../package-rules/feature.md)

## 문서 변경 기준

`State`의 정본 범위, 상태 형태 표현 방식, 요청 식별 방식 또는 SwiftUI 로컬 상태 허용
조건이 바뀔 때 수정합니다. Feature 분리 기준이 바뀌면 이 문서가 아니라
[Feature 컨벤션](./feature.md)을, `Action` 설계가 바뀌면
[Action 컨벤션](./action.md)을 갱신합니다.
