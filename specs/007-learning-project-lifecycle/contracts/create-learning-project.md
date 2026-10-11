# 계약: CreateLearningProject

**명세**: [spec.md](../spec.md) FR-005~010 | **데이터 모델**: [data-model.md](../data-model.md)
`LearningProjectRegistration`, `LearningProjectError` | **006 계약**:
[create-learning-project.md](../../006-domain-usecase-requirements/contracts/create-learning-project.md)

## Domain 계약

```swift
// sources/Projects/Domain/DomainLearningProject/Contracts/LearningProjectRepository.swift
public protocol LearningProjectRepository: Sendable {
    func register(githubRepoUrl: String, quizLevel: QuizLevel) async throws -> LearningProjectRegistration
    // fetchProjects/fetchProjectDetail/deleteProject는 다른 3개 계약 파일에서 이어서 정의
}
```

```swift
// sources/Projects/Domain/DomainLearningProject/UseCases/CreateLearningProject.swift
public struct CreateLearningProject: Sendable {
    public init(repository: LearningProjectRepository)
    public func callAsFunction(githubRepoUrl: String, quizLevel: QuizLevel) async throws -> LearningProjectRegistration
}
```

`callAsFunction`은 입력을 그대로 `repository.register`에 위임하고 결과를 그대로 반환한다
— 재등록·복원 판단(FR-007, FR-008)은 서버가 수행하며 UseCase가 재해석하지 않는다.

## Data 계약(참고)

```swift
// sources/Projects/Data/DataLearningProject/Contracts/LearningProjectRemote.swift
public protocol LearningProjectRemote: Sendable {
    func registerProject(_ request: RegisterProjectRequestDTO) async throws -> RegisterProjectResponseDTO
    // fetchProjects/fetchProjectDetail/deleteProject는 다른 3개 계약 파일에서 이어서 정의
}
```

`POST /api/v1/projects`(Bearer 인증)에 대응한다(FR-005). 오류는
`DataLearningProjectError`로 던진다.

## 재등록·다중 사용자 규칙 (FR-007, FR-008 — 서버 책임, 이 계약은 값을 그대로 전달만 함)

| 시나리오 | UseCase 관찰 동작 |
|---|---|
| 동일 사용자가 같은 Repository 재등록(quizLevel 동일/변경 무관) | `repository.register`가 기존 `projectId`/`status`를 반환 → UseCase가 그대로 반환, `quizLevel`은 요청값 보존(research.md 결정 7) |
| 삭제했던 Repository를 동일 사용자가 재등록 | `repository.register`가 복원된 `projectId`/진행 상태를 반영한 `status`를 반환 → UseCase가 그대로 반환 |

## 오류 계약

| Domain 케이스 | 서버 코드 | 조건 |
|---|---|---|
| `invalidRequest` | 400 `COMMON-001` | `githubRepoUrl` 누락, GitHub에 없는 저장소, 문제를 낼 수 없다고 판정된 저장소(FR-009) |
| `unauthorized` | 401 `COMMON-002` | 인증되지 않은 요청 |
| `unexpected` | 500 `COMMON-005` | 서버 내부 오류 |

## FR-025 테스트 매트릭스

- 성공(신규 등록): Fake가 새 `projectId`·`status: .ready` 반환 → 그대로 반환.
- 성공(재등록 멱등): Fake가 기존 `projectId` 반환 → 새 등록과 구분 없이 그대로 반환(FR-007
  회귀 고정, SC-003).
- 성공(삭제 후 복원): Fake가 복원된 `projectId`·진행 상태 반영 `status` 반환 → 그대로
  반환(FR-008 회귀 고정, SC-003).
- 오류 1: Fake가 `.invalidRequest` 던짐 → UseCase가 그대로 던짐.
- 오류 2: Fake가 `.unauthorized` 던짐 → UseCase가 그대로 던짐.

## 제외 책임(FR-010, spec.md와 동일)

생성 완료 대기, FCM 이벤트 수신, Polling/Timer 관리, Timeout 감시, 재시도 자체, 생성 요청
정보의 로컬 영속화, 실제 서버 호출 구현(Composition Adapter, 범위 밖).
