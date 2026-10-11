# Domain 계약: RepositoryCreationStateRepository

이 기능은 외부(서버) API를 새로 만들지 않는다. "계약"은 Domain이 Composition에게 요구하는
Swift 프로토콜이다(기존 `LearningProjectRepository`/`BookmarkRepository`와 동일한 위치·형식).

## 위치

`sources/Projects/Domain/LearningProject/Contracts/RepositoryCreationStateRepository.swift`

## 프로토콜 형태

```swift
public protocol RepositoryCreationStateRepository: Sendable {
    /// githubRepoURL을 정규화한 뒤 현재 "생성 중"(만료되지 않은 레코드가 존재)인지 조회한다.
    /// 부수효과 없는 순수 조회이며, FR-001("생성 중" 조회 능력)을 직접 충족한다.
    func isCreating(githubRepoURL: String) async -> Bool

    /// githubRepoURL을 정규화한 뒤 이미 "생성 중"이면 false, 아니면 상태를 기록하고 true를 반환한다.
    /// (원자적 check-and-set — 호출부가 경쟁 상태 없이 중복 생성을 막을 때 사용한다. 단순 조회만
    /// 필요하면 위 isCreating을 사용한다.)
    func beginCreation(githubRepoURL: String) async -> Bool

    /// register() 성공으로 발급된 projectID를 기존 레코드에 연결한다.
    func attachProjectID(_ projectID: String, toGithubRepoURL githubRepoURL: String) async

    /// register() 실패 등으로 즉시 해제할 때 사용한다.
    func endCreation(githubRepoURL: String) async

    /// GenerationOutcome 등 완료/실패 신호로 해제할 때 사용한다.
    func endCreation(projectID: String) async

    /// 현재 "생성 중"(만료되지 않은)으로 간주되는 projectID 집합. projectID가 아직 없는
    /// 레코드(등록 응답 대기 중)는 포함하지 않는다 — 목록 필터링은 projectID 기준이기 때문이다.
    func activeProjectIDs() async -> Set<String>
}
```

## 호출부 계약

- `CreateLearningProject.callAsFunction`:
  1. `githubRepoURL`을 정규화한다.
  2. `beginCreation(githubRepoURL:)`이 `false`를 반환하면 즉시
     `LearningProjectError.duplicateCreationInProgress`를 던지고 `register`를 호출하지 않는다.
  3. `register`가 실패하면 `endCreation(githubRepoURL:)`을 호출해 상태를 해제한 뒤 원래 오류를
     다시 던진다.
  4. `register`가 성공하면 `attachProjectID(receipt.projectID, toGithubRepoURL:)`를 호출한 뒤
     `receipt`를 반환한다.
- `FetchLearningProjects.callAsFunction`:
  1. 기존과 동일하게 `repository.fetchProjects(...)`를 호출한다.
  2. `activeProjectIDs()`를 조회해 반환된 `items`에서 해당 `projectID`를 가진 항목을 제외한다.
  3. `hasNext`는 서버 응답 값을 그대로 유지한다(페이지네이션 총 개수 보정은 이 기능의 범위
     밖 — 가정 참고).

## 구현 계약(Composition)

`RepositoryCreationStateRepositoryAdapter`(actor, `Composition/Adapter/Adapters/`)가 위 프로토콜을
구현하고, 추가로 다음 내부 동작을 가진다(Domain 계약에는 노출하지 않음):

- 모든 조회·기록 메서드 진입 시 900초를 초과한 레코드를 lazy expiry로 정리한다.
- `start(observeGenerationOutcomes:)` 메서드로 `ObserveGenerationOutcomesUseCase` 스트림을
  구독해 각 `GenerationOutcome` 수신 시 `endCreation(projectID:)`를 호출한다. 구독 방식은
  기존 `GenerationCompletionReminderCoordinator.start(observeGenerationOutcomes:)`(actor +
  스트림 구독)와 유사하지만, 그 타입은 어떤 Domain 계약도 구현하지 않는 `Adapter/Factories/`의
  순수 outcome 구독자인 반면 이 타입은 `RepositoryCreationStateRepository`를 구현하는 계약
  구현체이므로 기존 `*Adapter` 명명 관례(`BookmarkRepositoryAdapter` 등)를 따라
  `Adapter/Adapters/`에 위치하고 `*Adapter` 접미어를 사용한다.
- `FetchLearningProjects`가 `hasNext`를 그대로 유지하는 것은 spec.md의 가정에 명시된 대로,
  이 기능이 클라이언트 측 필터만 수행하고 서버 페이지네이션 총 개수 보정에는 관여하지 않기
  때문이다.
