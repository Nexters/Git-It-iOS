# 계약: Feature·App 경계 (TCA State/Action/Delegate)

## 1. `ProjectRegistrationFeature` 공개 계약 변경

### 초기화

```swift
public init(
    fetchExternalRepository: any FetchExternalRepositoryUseCase,
    createLearningProject: any CreateLearningProjectUseCase,
    observeLearningProjectGenerationOutcomes: any ObserveLearningProjectGenerationOutcomesUseCase, // 신규
)
```

### `Action.View` 추가

```swift
case waitAtHomeTapped                 // "홈에서 기다리기" CTA
case notificationOptionAccepted       // 알림 옵션 시트 수락
case notificationOptionDeclined       // 알림 옵션 시트 거절(또는 시트 닫기)
case retryTapped                      // 재시도 가능한 실패 상태에서 재시도
```

기존 `submitTapped`의 성공 경로는 더 이상 즉시 `delegate(.projectRegistered)`를
보내지 않고 `submission = .awaitingGeneration(receipt)`로 전이한다.

### `Action.EffectEvent` 추가

```swift
case generationOutcomeReceived(LearningProjectGenerationOutcome)
```

### `Action.Delegate`

```swift
public enum Delegate: Sendable, Equatable {
    case projectRegistered(ProjectRegistrationReceipt)  // 기존, 발행 시점만 변경
    case notificationOptionSelected(accepted: Bool)     // 신규, 상위가 해석할 intent
}
```

**보장 사항**

- `projectRegistered`는 다음 두 경로 중 정확히 하나로만 발행된다: (a)
  `waitAtHomeTapped` 처리 완료(알림 옵션 시트를 거쳤다면 그 이후), (b)
  `awaitingGeneration` 상태에서 일치하는 `projectID`의 `completed` outcome 수신.
  두 경로가 동시에 만족돼도 State가 이미 제거되었으므로 중복 발행되지 않는다.
- `notificationOptionSelected`는 실제 알림 권한 요청이나 로컬 알림 예약을 유발하지
  않는다. 상위(App)가 이 delegate를 받아도 아무 것도 하지 않을 수 있다(이번 기능은
  UI와 intent 출력까지만 다룬다).
- `retryTapped`는 `submission`이 `.failed`일 때만 `createLearningProject`를 동일
  `githubRepoURL`/`quizLevel`로 다시 호출한다.
- `awaitingGeneration` 중 일치하는 `projectID`의 `failed` outcome을 수신하면
  `submission = .failed(.unexpected)`로 전이한다(`LearningProjectGenerationOutcome`은
  실패 원인을 담지 않으므로 항상 `.unexpected`로 매핑하며, 제출 자체 실패와 동일한
  표현을 공유한다).

## 2. `HomeFeature` 공개 계약 변경

### 초기화

```swift
public init(
    fetchLearningProjects: any FetchLearningProjectsUseCase,
    fetchMemberProfile: any FetchMemberProfileUseCase,
    observeLearningProjectGenerationOutcomes: any ObserveLearningProjectGenerationOutcomesUseCase, // 신규
)
```

### `Action.View` 추가

```swift
case reloadRequested   // 등록 흐름 종료로 복귀했을 때 상위(App)가 보내는 1회 재조회 신호
```

`reloadRequested`는 사용자가 직접 발생시키는 사건이 아니라 App이 위임하는 명시적
신호이므로, 프로젝트가 TCA 컨벤션에서 허용하는 "부모의 외부 조정 신호"에 해당한다.
현재 코드베이스는 이런 신호를 `view`에 얹는 대신 새 `input` 분류를 쓸 수도 있으나,
이 Feature는 아직 `input` 분류를 쓰지 않으므로 기존 관례(HomeFeature의 다른 사용자
사건과 동일하게 `.view`에 둠)를 따르되 이름으로 출처를 분명히 한다. 구현 단위에서
`input` 신설이 더 적합하다고 판단되면 `tasks.md`에서 이유를 남기고 조정한다.

### `Action.EffectEvent` 추가

```swift
case generationOutcomeReceived(LearningProjectGenerationOutcome)
```

**보장 사항**

- `.view(.task)`는 `generationOutcomeObservation == .idle`일 때만 관찰 Effect를
  시작하고 이후 재호출에서는 중복 구독하지 않는다.
- 이 관찰 Effect는 `HomeFeature.State`가 존재하는 한(= `MainShellFeature.State`가
  재생성되기 전까지, 즉 로그아웃 전까지) 취소되지 않는다.
- `reloadRequested`는 현재 `projectLoad`가 `.loading`이 아니면 새 조회를 시작한다
  (중복 조회 방지, FR-013).

## 3. `MainShellFeature` 변경

- `HomeFeature`를 조립하는 `Scope`에 `observeLearningProjectGenerationOutcomes`를
  그대로 통과시킨다.
- `Action.Delegate`, `Action.View`는 이 기능으로 추가되지 않는다. `home` 자식
  Action은 그대로 통과(`case .home: return .none`)한다.

## 4. `AppRootFeature` 변경

### `State`

```swift
@Presents var projectRegistration: ProjectRegistrationFeature.State?
```

### `Action`

```swift
case projectRegistration(PresentationAction<ProjectRegistrationFeature.Action>)
```

### Reducer 계약

```swift
Reduce { state, action in
    switch action {
    case .mainShell(.delegate(.projectRegistrationRequested)):
        state.projectRegistration = ProjectRegistrationFeature.State()
        return .none

    case .projectRegistration(.presented(.delegate(.projectRegistered(let receipt)))):
        state.projectRegistration = nil
        return .send(.mainShell(.home(.view(.reloadRequested))))

    case .projectRegistration(.presented(.delegate(.notificationOptionSelected))):
        return .none // 이번 기능 범위에서 상위가 추가로 할 일 없음(로그·분석 등 후속 기능)

    case .projectRegistration:
        return .none
    …
    }
}
.ifLet(\.$projectRegistration, action: \.projectRegistration) {
    ProjectRegistrationFeature(
        fetchExternalRepository: fetchExternalRepository,
        createLearningProject: createLearningProject,
        observeLearningProjectGenerationOutcomes: observeLearningProjectGenerationOutcomes,
    )
}
```

**보장 사항**

- `projectRegistration`이 `nil`이 아닌 동안 `AppRootView`는 `fullScreenCover`로
  이를 표시하며, 이 표시는 SwiftUI `fullScreenCover`의 기본 동작상 하위 탭 전환 UI를
  가리므로 FR-001a("MainShell 탭 전환과 다른 화면 접근 차단")를 별도 잠금 상태 없이
  만족한다.
- `AppRootFeature`의 initializer는 `fetchExternalRepository`, `createLearningProject`,
  `observeLearningProjectGenerationOutcomes`를 새 매개변수로 받는다(FR-017: 생성자
  주입 유지).

## 5. `AppRootView` 변경

```swift
case .mainShell:
    MainShellScreen(store: store.scope(state: \.mainShell, action: \.mainShell))
        .fullScreenCover(
            item: $store.scope(state: \.projectRegistration, action: \.projectRegistration)
        ) { store in
            ProjectRegistrationScreen(store: store)
        }
```

## 6. 테스트 계약(요약)

- `ProjectRegistrationFeatureTests`: `submitTapped` 성공 시 `awaitingGeneration`
  전이, `waitAtHomeTapped` 경로의 delegate 발행, `generationOutcomeReceived`의
  `projectID` 필터링과 멱등 처리, `retryTapped`의 재제출.
- `HomeFeatureTests`: `reloadRequested`의 중복 조회 차단, 관찰 Effect의 idle→observing
  1회 전이.
- `AppRootFeatureTests`: `projectRegistrationRequested` → `@Presents` 생성,
  `projectRegistered` delegate → `nil` 전이 + `home(.reloadRequested)` 발행이
  정확히 1회.
- Composition: `LearningProjectGenerationOutcomeRepositoryAdapterTests`(DTO→Domain
  변환, 알 수 없는 상태 폐기). App의 `GitItAppDelegate`는 UIKit 콜백 특성상
  단위 테스트 대신 quickstart.md의 수동 시나리오로 검증한다.
