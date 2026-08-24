# 014-all-usecases-implementation 암묵지 기록

**대상 기능**: `014-all-usecases-implementation`

**기록 원칙**: 복수 근거에서 해석한 지식을 상태와 범위와 함께 append-only로 보존한다.

## TK-20260823-001: 이 저장소의 TCA 버전에서 중첩 enum 기반 navigation은 표준 `Scope`/`scope` API보다 수동 dispatch와 명시적 타입 주석이 더 안정적으로 동작한다

**기록일**: 2026-08-23
**상태**: 후보
**확신도**: 중간
**적용 범위**: `sources/Projects/Feature/**`, `sources/Projects/App/**`의 TCA Feature 중
연관값을 가진 여러 `case`로 서로 다른 Child State를 표현하는 상태 머신(App의
`RootFeature.phase`가 대표 사례; U03 `MainShellFeature`의 탭별 child state, U07/U08
route 전이처럼 유사 구조를 가진 다른 Feature에도 잠재적으로 적용 가능)
**관련 항목**: `specs/014-all-usecases-implementation/tasks.md`의 T190~T192,
`sources/Projects/App/Sources/RootFeature.swift`,
`sources/Projects/App/Sources/RootPhaseAndPath.swift`,
`sources/Projects/App/Sources/RootView.swift`

### 해석

이 저장소가 사용하는 TCA 버전에서, 여러 `case`가 각각 다른 Child State를 담는 중첩
연관값 enum(예: `RootFeature.phase`의 `onboarding`/`mainShell` 분기)을 다룰 때는
`Scope(state:action:)`의 case key path 오버로드와 2단계 이상 중첩된 case key path에
표준 문서 사례를 그대로 적용하면 제네릭 추론 실패나 컴파일 오류로 이어질 수 있고,
`store.scope(_:action:)` 호출도 반환 타입을 명시적으로 주석하지 않으면 컴파일러가
잘못된 오버로드를 선택할 수 있다.

### 근거

- `sources/Projects/App/Sources/RootFeature.swift` 구현 중, `RootFeature.phase`(여러
  case가 각각 다른 Child State를 담는 연관값 enum)에 대해 `Scope(state:
  \.phase.onboarding, action: ...)` 형태의 표준 case key path 오버로드를 사용했을 때
  제네릭 추론이 실패해 컴파일이 되지 않았고, `Reduce { state, action in switch ... }`
  형태의 수동 dispatch로 바꾼 뒤에야 컴파일과 동작이 모두 성공했다(같은 파일 내
  독립적으로 재현·수정된 사실).
- 같은 구현 세션에서, `\.phase.onboarding`처럼 2단계로 중첩된 case key path를
  사용하려면 최상위 State가 `@ObservableState`, `phase` enum이 `@CasePathable`이면서
  동시에 `@dynamicMemberLookup`이어야 했고, 이 3중 데코레이션 조합이 갖춰지지 않으면
  컴파일 실패 또는 잘못된 case로 스코프되는 문제가 발생해, 결국
  `sources/Projects/App/Sources/RootPhaseAndPath.swift`에 `phase` 전용
  `RootPhaseReducer` 타입을 분리하는 방식으로 우회했다(첫 번째 근거와는 별도로,
  key path 데코레이션 조합에 대한 독립적인 시행착오).
- 같은 구현 세션에서, `$store.scope(\.path, action:)` 호출에 반환 타입 주석 없이
  `let scopedStore = store.scope(...)`로 작성하면 컴파일러가 여러
  `scope(_:action:)` 오버로드 중 잘못된 것을 선택해 타입 불일치 오류를 냈고,
  `let scopedStore: StoreOf<Child> = store.scope(...)`로 명시적 타입을 붙인 뒤에만
  올바른 오버로드가 선택됐다(세 번째 독립 시행착오).

### 적용과 제외

- 적용: 이 저장소의 Feature가 여러 case가 각각 다른 Child State를 담는 연관값 enum으로
  내부 phase/route를 표현하고, 그 상태를 TCA composition(`Scope`, `store.scope`,
  중첩 case key path)으로 다뤄야 할 때. 특히 App의 `RootFeature`처럼 최상위에서
  onboarding/mainShell 등 서로 다른 대형 Child Feature를 배타적으로 소유하는 구조.
- 제외: 단일 case만 있는 단순 optional Child State(`@Presents` 등 TCA 표준 패턴이
  문제없이 동작하는 것으로 관찰된 다른 Feature들 — 예를 들어 이번 세션에서 구현한
  U02~U08의 단순 Destination/optional child 패턴)에는 이 해석을 적용할 근거가 없다.
  또한 이 해석은 이 저장소가 고정한 특정 TCA 버전에 한정되며, 라이브러리 버전이
  바뀌면 재검증이 필요하다.

### 반례와 불확실성

- 단일 구현 세션(App 패키지 T190~T192) 안에서 확보한 근거이며, 다른 세션이나 다른
  Feature에서 동일 증상이 재현되는지는 아직 확인하지 못했다.
- 표준 `Scope`/`scope` API가 실패한 정확한 컴파일러 내부 원인(제네릭 추론 알고리즘의
  구체적 한계)은 규명하지 못했고, 우회 조치가 재현 가능하다는 사실만 확인했다.
- TCA 라이브러리 버전이 갱신되면 이 제약이 해소되거나 다르게 나타날 수 있다.

### 검증 또는 승격 조건

- 이후 세션에서 유사한 중첩 enum 기반 navigation을 다른 Feature(예: U03
  `MainShellFeature`의 탭 전환, U07/U08 route 전이)에 추가로 구현하면서 동일 증상이
  재현되는지 확인한다. 재현되면 이 항목을 참조하는 후속 항목으로 상태를 `검증됨`으로
  올리고, 재현되지 않으면 조건을 좁히는 후속 항목을 남긴다.
- `docs/conventions/tca.md`에 이 우회 패턴을 정식 컨벤션으로 승격할지는 별도로
  `$speckit-constitution`/문서 갱신 절차를 통해 사용자가 결정해야 한다(이 기록은 참고
  근거일 뿐 상위 문서를 대체하지 않는다).

### 연결

`docs/spec-kit/014-all-usecases-implementation/trouble-shooting.md`의
`TS-20260823-002`(같은 App 패키지 구현에서 발견된 `SWIFT_DEFAULT_ACTOR_ISOLATION:
MainActor`와 `@Reducer` 매크로 circular reference 문제 — 별개 증상이지만 같은
`RootFeature`/`RootView` 구현 세션에서 함께 발견됨)
