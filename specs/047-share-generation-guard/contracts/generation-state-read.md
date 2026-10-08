# 계약: 생성 상태 일회 조회와 공유 확장 판정

**명세**: [spec.md](../spec.md) | **데이터 모델**: [data-model.md](../data-model.md) | **조사**: [research.md](../research.md)

선언 형태만 적는다. 구현은 `tasks.md`와 구현 단계가 소유한다.

## Data `DataShared`

```swift
public enum KeyValueStorageError: Error, Equatable, Sendable {
    case unavailable
    case unreadable
}

public protocol KeyValueStorage: Sendable {
    // 기존 연산 유지
    func verifiedValue<Value: Codable & Sendable>(
        _ type: Value.Type,
        forKey key: String,
    ) async throws(KeyValueStorageError) -> Value?
}
```

- 값이 없으면 `nil`을 돌려준다.
- `UnavailableKeyValueStorage`는 항상 `unavailable`을 던진다.
- `LocalKeyValueStorage`는 저장된 데이터의 디코딩에 실패하면 `unreadable`을 던진다.
- 기존 `value(_:forKey:)`의 동작(실패 시 `nil`)은 바꾸지 않는다.
- 적합 타입: `LocalKeyValueStorage`, `UnavailableKeyValueStorage`, 테스트 더블 `InMemoryKeyValueStorage` 6개
  (Data Tests: Authentication·LegalConsent·LearningProject, Composition Tests: Authentication·ShareExtension·LearningProject).

## Data `DataLearningProject`

```swift
public actor LocalPendingGenerationStore {
    public func verifiedState() async throws(KeyValueStorageError) -> GenerationStateDTO
}
```

- 기록이 없으면 빈 `GenerationStateDTO`를 돌려준다.
- 다른 연산과 같은 직렬 실행 순서 안에서 읽는다.

## Domain `DomainProjectGeneration`

```swift
public protocol PendingGenerationRepository: Sendable {
    // 기존 연산 유지
    func confirmedPendingState() async throws -> GenerationState
}

public protocol ProjectGenerationUseCase: Sendable {
    // 기존 연산 유지
    func currentState() async throws(ProjectGenerationError) -> ProjectGenerationState
}

public enum ProjectGenerationError {
    // 기존 사례 유지
    case stateUnavailable
}

extension ProjectGenerationState {
    public var hasRequestInProgress: Bool { get }
}
```

- `currentState()`는 관찰(`states()`의 결과·로그아웃·저장소 변경 관찰과 만료 타이머)을 시작하지 않는다.
- `currentState()`는 `states()`가 방출하는 값과 같은 투영 규칙(보관 기한 경과 기록 제외, 기록 상태→단계 변환)을 쓴다.
- `confirmedPendingState()`는 Domain 오류(`ProjectGenerationError.stateUnavailable`)만 던진다. `currentState()`는 그 오류를 전달하고,
  그 밖의 오류는 `stateUnavailable`로 본다.
- `hasRequestInProgress`는 `requests` 중 `.inProgress` 단계가 하나라도 있으면 참이다. 앱 홈 잠금과 공유 확장 판정이 이 프로퍼티만 쓴다.
- `ProjectGenerationUseCase` 적합 타입: `ProjectGeneration`, App 프리뷰 `NoopProjectGeneration`, App 테스트 `ProjectGenerationUseCaseMock`,
  Feature 테스트 `ProjectGenerationUseCaseStub`·`ProjectGenerationUseCaseSpy`.
- `PendingGenerationRepository` 적합 타입: Composition `PendingGenerationRepositoryAdapter`, Domain 테스트 `InMemoryPendingGenerationRepository`.

## Composition `CompositionLearningProject`

- `PendingGenerationRepositoryAdapter.confirmedPendingState()`는 `store.verifiedState()`를 Domain `GenerationState`로 바꾸고 `pendingState()`와
  같은 보관 기한 정리를 적용한다. 저장소 오류(`KeyValueStorageError`의 모든 사례)는 `ProjectGenerationError.stateUnavailable`로 바꿔
  던진다. Data 오류 타입은 Domain 계약 밖으로 나가지 않는다.

## Feature `ShareRegistration`

판정 전용 타입을 두지 않는다. 하위 등록 Feature는 UseCase 전체가 아니라 쓰는 동작만 클로저로 받는다(명확화 2026-09-29).
소스 위치는 이동 단위 뒤의 `Feature/ShareRegistration/ShareRegistration/`이다([research R9](../research.md#r9-공유-확장-흐름-배치-정리-fr-012-명확화-2026-09-29)).

```swift
public struct SharedRepositoryRegistrationFeature {
    public init(
        parseRepositoryLink: any ExternalRepositoryLocator,
        lookUpRepository: @escaping @Sendable (ExternalRepositoryURL) async throws -> ExternalRepository,
        requestGeneration: @escaping @Sendable (ProjectGenerationRequest) async throws -> ProjectGenerationReceipt,
        currentGenerationState: @escaping @Sendable () async throws -> ProjectGenerationState,
        signInAvailability: @escaping @Sendable () async -> SignInAvailability,
        recordDiagnostic: @escaping @Sendable (ShareRegistrationDiagnosticEvent) -> Void,
    )
}
```

- `externalRepository`·`projectGeneration` 인자는 없어진다. 세 클로저 모두 기본값이 없다.
- 조회한 상태는 `hasRequestInProgress`로만 해석하고, 조회 오류는 확인 실패로 본다. 자체 판정 규칙을 두지 않는다(FR-009).
- 차단 결과는 기존 Effect event `validationFinished(State.Phase)`로 전달한다. 새 Action case는 없다.
- `ShareRegistrationFeature`의 공개 initializer는 바뀌지 않는다. 내부에서 `{ try await externalRepository.repository(at: $0) }`,
  `{ try await projectGeneration.request($0) }`, `{ try await projectGeneration.currentState() }`를 만들어 하위 Feature에 전달한다.
- `SharedRepositoryRegistrationFeature.State.Phase`에 `generationInProgress`, `generationUnverified(retry: RetryTarget)`를 추가한다.
- `ShareRegistrationDiagnosticEvent`에 `generationInProgressBlocked`, `generationStateUnverified`를 추가한다.

## App

- `ShareRegistrationDiagnosticLog`는 새 진단 사례를 기록한다. `ShareViewController`의 조립은 바뀌지 않는다.
- `AppRootFeature.applyGenerationState`는 홈 잠금 판정에 `ProjectGenerationState.hasRequestInProgress`를 쓴다. 판정 결과는 바뀌지 않는다(FR-010).
