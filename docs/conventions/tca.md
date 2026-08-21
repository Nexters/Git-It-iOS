# Git It iOS TCA 컨벤션

**상태**: 초안

**작성일**: 2026-08-21

**최종 수정일**: 2026-08-21

## 목적

이 문서는 Feature가 TCA(The Composable Architecture)로 사용자 기능의 상태와 상호작용을
구현하는 공통 방식을 정의합니다. Feature 패키지의 책임과 허용 의존성은
[Feature 패키지 규칙](../package-rules/feature.md)이 소유하고, Feature 분리 기준,
`State`, `Action`, Reducer, Effect, Navigation 출력과 화면 연결의 구체적인 구현 방식은
이 문서가 소유합니다.

Git It은 TCA Dependencies의 `@Dependency`나 의존성 접근 키 대신 **생성자 또는 명시적인
초기화 인자를 통한 의존성 주입**을 정본으로 사용합니다. TCA 예제의 dependency 조회
방식을 그대로 복사하지 않고 이 프로젝트의 아키텍처 경계를 우선합니다.

## 1. 적용 범위

- `sources/Projects/Feature/Presentation/**`의 TCA Feature와 화면에 적용합니다.
- `sources/Projects/Feature/Tests/**`의 `TestStore` 기반 테스트에 적용합니다.
- App이 Feature의 Reducer와 화면을 생성하거나 delegate·navigation intent를 해석할 때
  공개 계약 부분에 적용합니다.
- Domain 규칙, production 구현 선택과 앱 전체 Navigation 정책은 이 문서의 범위가
  아닙니다.

## 2. 핵심 용어

| 용어 | 정의 | 포함하지 않는 것 |
| --- | --- | --- |
| Feature | 제품 동작에 영향을 주는 고유한 변경 가능 상태, 상태 수명과 전이 규칙을 소유하는 단위 | SwiftUI 파일이나 단순 레이아웃 |
| State | 현재 Feature가 사실로 간주하는 최소 정보 | dependency, `Task`, Effect와 중복 파생값 |
| Action | 이미 발생했거나 Feature가 수신한 사건 | 앞으로 실행할 작업을 나타내는 명령 |
| Reducer | 현재 State와 Action을 해석해 다음 State와 실행할 Effect를 결정하는 경계 | 직접 비동기 작업을 시작하는 코드 |
| Effect | Reducer가 실행하도록 반환하는 비동기·외부 작업 | 로딩 여부와 같은 상태 값 |
| Effect event | Effect가 완료되거나 값을 수신한 뒤 Reducer로 돌려보내는 사건 | Effect 자체 |
| Delegate | Feature가 부모 또는 App에 전달하는 결과·의도 | 실제 애플리케이션 Navigation 실행 |
| Destination | 현재 Feature 수명 안에서 소유하는 sheet·alert·내부 화면 상태 | 다른 최상위 Feature로 이동하는 App Navigation |

핵심 구분은 **Action은 이미 일어난 일이고, Effect는 앞으로 실행할 일**이라는 것입니다.
사용자 사건인 `retryTapped`를 받은 Reducer가 현재 상태를 해석해 조회 Effect를 반환하며,
앞으로 할 일을 그대로 명령하는 `fetchProjects` 같은 View Action을 만들지 않습니다.

## 3. Feature 구성과 분리 기준

### 3.1 Feature 단위

- Feature는 SwiftUI `View` 타입이나 디자인 프레임 수가 아니라 논리적인 상태 소유자를
  기준으로 나눕니다.
- 하나의 사용자 기능은 `@Reducer`가 붙은 Feature 타입 하나를 중심으로 구성합니다.
- 같은 논리 화면의 loading, loaded, empty, menu, confirmation과 오류 표현은 별도
  Feature가 아니라 원칙적으로 하나의 Feature가 소유하는 State 변형입니다.
- 하나의 Feature는 여러 View를 렌더링할 수 있고, 하나의 화면은 부모 Feature와 여러
  Child Feature를 조합할 수 있으므로 Feature와 View를 1:1로 맞추지 않습니다.
- 한 사용자 기능의 Reducer와 화면은 `Presentation/Screens/<기능>/`에 함께 둡니다.
- 여러 화면이 공유하는 View가 아닌 Presentation 보조 타입만 `Presentation/Shared/`에
  둘 수 있습니다.

논리 화면이나 상태 영역이 다음 중 하나 이상을 소유하면 Feature 후보로 봅니다.

- Use Case 입력, 제출 가능 여부 또는 Navigation 목적지처럼 제품 동작을 바꾸는 상태
- Action에 따른 상태 전이와 독립적으로 검증할 가치가 있는 불변식
- 비동기 작업, 오류 복구, validation 또는 cancellation 수명
- 화면 재진입 뒤 보존하거나 다른 화면·부모가 관찰해야 하는 사용자 입력과 진행 상태

누름 애니메이션, geometry 측정, 일시적인 highlight, 부모 State에서 완전히 계산되는
표시 값이나 callback만 전달하는 행은 Feature 분리 근거가 아닙니다.

### 3.2 Child Feature 분리

다음 중 하나 이상을 만족하면 Child Feature 분리를 우선 검토합니다.

- 독립적인 비동기 Effect와 cancellation 수명을 가집니다.
- 자체 오류·재시도 상태와 상태 전이 규칙을 가집니다.
- 부모와 별도로 제시·제거되며 그 생성과 제거가 상태 수명을 결정합니다.
- 여러 화면에서 동일한 제품 동작 단위로 재사용됩니다.
- 부모가 하위 상태의 불변식을 계속 대신 관리해야 합니다.

표시 값과 callback만 가지거나 부모 State에서 완전히 파생되는 하위 View는
[UIComponent 컨벤션](./ui-component.md)의 재사용 기준을 적용합니다. 단순 confirmation은
부모의 배타 상태나 Destination으로 표현할 수 있으며, 그 안에서 독립적인 mutation,
실패 복구와 수명을 소유할 때 Child Feature 분리를 검토합니다.

### 3.3 공개 표면

- `State`, `Action`, 목적지 상태와 cancellation ID는 해당 Feature 타입이 소유합니다.
- Feature의 공개 표면은 App이 생성하는 Reducer와 화면, App이 해석할 delegate 또는
  navigation intent로 제한합니다.
- Child Feature는 부모가 조합하고, 다른 최상위 Feature의 목적지 생성과 앱 전체
  Navigation은 App에 위임합니다.

## 4. State

### 4.1 정본과 파생값

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

### 4.2 상태 형태

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

### 4.3 요청 식별

- 새 요청이 이전 요청을 대체하거나 같은 종류의 요청이 겹칠 수 있으면 State가 현재
  request generation 또는 request ID를 보존합니다.
- Effect event는 자신이 속한 request identity를 함께 전달하고, Reducer는 현재 요청과
  일치하는 결과만 반영합니다.
- cancellation만으로 늦은 응답이 State에 반영되지 않는다고 가정하지 않습니다.
- 서로 겹칠 수 없도록 State 전이로 입력을 차단한 mutation에는 불필요한 request ID를
  추가하지 않아도 되지만, 결과의 대상 ID는 event에 보존합니다.

### 4.4 SwiftUI 로컬 상태

`@State`와 `@FocusState`는 다음 조건을 모두 만족할 때만 화면에 둘 수 있습니다.

- View가 사라질 때 손실돼도 제품 동작이 바뀌지 않습니다.
- Use Case 입력이나 Navigation에 영향을 주지 않습니다.
- Reducer test 대상이 아닙니다.
- 부모나 다른 화면이 관찰할 필요가 없습니다.
- 비동기 Effect를 시작하거나 취소하지 않습니다.

하나라도 만족하지 않으면 Feature State가 소유합니다.

## 5. Action

### 5.1 출처 분류

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

### 5.2 이름과 payload

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

### 5.3 Binding Action

`BindableAction`은 아직 제출되지 않은 텍스트, selection과 local form toggle처럼 화면의
draft 입력을 변경하는 용도로 제한합니다. 삭제, 탈퇴, 북마크 또는 서버 정본을 즉시
바꾸는 작업은 binding setter에서 실행하지 않고 `submitTapped`, `deletionConfirmed`와
같은 명시적인 View Action을 거칩니다.

## 6. Reducer와 Effect

### 6.1 Reducer 책임

- Reducer는 현재 State와 Action을 해석해 State를 동기적으로 전이하고 실행할 Effect를
  반환합니다.
- 화면 상태를 바꾸는 판단, 사용자 의도 해석과 유효하지 않은 입력 차단은 Reducer가
  소유합니다.
- Reducer나 View 안에서 `Task`를 만들거나 Use Case, `URLSession`,
  `NotificationCenter` 같은 외부 작업을 직접 실행하지 않습니다.
- Domain의 비즈니스 규칙을 Reducer에 다시 구현하지 않고 주입받은 Domain contract를
  Effect에서 호출합니다.
- 오류를 무시하거나 View가 Domain 오류를 직접 해석하게 하지 않습니다.

### 6.2 의존성 주입

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

### 6.3 Effect 작성

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

### 6.4 취소와 mutation

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

## 7. Navigation과 화면 연결

### 7.1 Navigation 경계

- 현재 Feature 수명 안에서 완결되는 sheet, alert와 내부 화면은 Destination 또는 Child
  State로 소유할 수 있습니다.
- Feature 바깥으로 이동해야 하면 현재 Feature는 delegate 또는 navigation intent를
  출력하고 App이 목적지와 전환 방식을 결정합니다.
- Feature는 다른 최상위 Feature를 직접 생성하거나 push, present와 같은 App Navigation
  방식을 명령하지 않습니다.

### 7.2 TCA 화면

- TCA 화면은 `StoreOf<Feature>`를 `init(store:)`로 받고 화면 상태의 단일 정본으로
  사용합니다.
- 화면은 `@ViewAction`을 적용하고 Store를 관찰해 렌더링하며 사용자 사건을 View Action으로
  보냅니다.
- UIComponent가 요구하는 읽기 전용 값은 Store에서 파생해 직접 전달하고, 변경 가능한
  값은 SwiftUI `Binding`으로 연결합니다.
- UIComponent 콜백은 View Action으로 해석하며 UIComponent에 Store, Action, Feature
  State나 Domain 업무 모델을 전달하지 않습니다.
- TCA Store와 같은 상태를 복제하는 화면 ViewModel을 정의하지 않습니다.
- 화면은 상태 분기, 화면 목적지 생성과 컴포넌트 조립을 소유합니다.
- 화면 전용 렌더링 조각은 private 연산 프로퍼티나 메서드로 유지합니다. 독립된 표현
  계약이 생기면 UI 패키지로 옮기고 화면 파일 안에 별도 `View` 타입을 만들지 않습니다.

구체적인 화면 생성 경로와 내부 선언은 [View 컨벤션](./view.md)을, UIComponent 입력
경계는 [UIComponent 컨벤션](./ui-component.md)을 따릅니다.

## 8. 테스트

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
- 테스트는 `Tests/<기능>/` 아래에서 State, Effect, 사용자 상호작용과 delegate 출력을
  중심으로 구성합니다.

테스트 이름, 비동기 종료, Test Double과 target 구성의 공통 규칙은
[테스트 컨벤션](./test.md)을 따릅니다.

## 9. 제약조건

- Data DTO나 Data API를 참조하지 않습니다.
- Infrastructure의 기술 API를 참조하지 않습니다.
- Composition에서 dependency를 조회하지 않습니다.
- Repository 또는 production 구현체를 Feature 내부에서 생성하지 않습니다.
- Domain의 비즈니스 규칙을 Reducer에 다시 구현하지 않습니다.
- Feature State, Action 또는 업무 모델을 UIComponent 공개 API에 노출하지 않습니다.
- TCA Store와 같은 상태를 복제하는 화면 ViewModel을 정의하지 않습니다.
- 다른 Feature의 목적지 생성과 애플리케이션 전체 Navigation 정책을 소유하지 않습니다.

## 10. 검토 체크리스트

- [ ] Feature가 View 파일이나 디자인 프레임이 아니라 고유한 상태와 수명을 기준으로
      나뉘는가?
- [ ] 독립적인 Effect·오류 복구·수명이 있는 하위 동작은 Child Feature 분리를 검토했는가?
- [ ] State가 최소 정본만 저장하고 파생값, dependency, Task와 Effect를 저장하지 않는가?
- [ ] 배타 상태는 `enum`, 병행 가능한 operation은 별도 상태로 표현하는가?
- [ ] 교체 가능한 요청에 request identity가 있고 늦은 결과를 거부하는가?
- [ ] Action이 `view`, `effect`, `delegate` 등 실제 출처를 구분하는가?
- [ ] View Action이 관찰된 사건을, Effect event가 완료된 작업을 표현하는가?
- [ ] Delegate가 App의 전환 방식을 명령하지 않고 완전한 payload를 전달하는가?
- [ ] dependency가 Reducer initializer로 주입되고 private 불변 프로퍼티로 보존되는가?
- [ ] Effect의 성공·실패·취소와 소유 State 제거 경로가 명시적인가?
- [ ] 서버 mutation이 `committing` 뒤 취소되지 않고 충돌 입력을 차단하는가?
- [ ] 화면이 Store를 단일 정본으로 사용하고 View Action만 보내는가?
- [ ] UIComponent에 TCA, Feature 또는 Domain 업무 타입이 노출되지 않는가?
- [ ] `TestStore`가 상태 전이, Effect event, 취소, 늦은 응답과 delegate 출력을 검증하는가?

## 관련 문서

- [아키텍처](../architecture.md)
- [Feature 패키지 규칙](../package-rules/feature.md)
- [App 패키지 규칙](../package-rules/app.md)
- [View 컨벤션](./view.md)
- [UIComponent 컨벤션](./ui-component.md)
- [테스트 컨벤션](./test.md)

## 문서 변경 기준

TCA 버전 변경, Feature 분리 기준, State·Action·Effect 구성 방식, dependency 주입 방식,
Navigation 출력 또는 화면과 Store의 연결 규칙이 바뀔 때 수정합니다. 특정 화면의 상태와
구현만 바뀌면 이 문서를 수정하지 않습니다. Feature 패키지의 책임이나 의존 방향이 바뀌면
이 문서보다 아키텍처와 Feature 패키지 규칙을 먼저 갱신합니다.
