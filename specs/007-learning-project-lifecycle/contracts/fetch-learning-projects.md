# 계약: FetchLearningProjects

**명세**: [spec.md](../spec.md) FR-011~015 | **데이터 모델**: [data-model.md](../data-model.md)
`LearningProjectPage`, `LearningProjectSummary`, `LearningProjectError` | **006 계약**:
[fetch-learning-projects.md](../../006-domain-usecase-requirements/contracts/fetch-learning-projects.md)

## Domain 계약

```swift
// LearningProjectRepository(create-learning-project.md에서 시작한 동일 프로토콜에 추가)
public protocol LearningProjectRepository: Sendable {
    func fetchProjects(page: Int, size: Int) async throws -> LearningProjectPage
}
```

```swift
// sources/Projects/Domain/DomainLearningProject/UseCases/FetchLearningProjects.swift
public struct FetchLearningProjects: Sendable {
    public init(repository: LearningProjectRepository)
    public func callAsFunction(page: Int, size: Int) async throws -> LearningProjectPage
}
```

기본값 `page = 0`, `size = 10`(FR-011)은 UseCase의 `callAsFunction` 파라미터 기본값으로
제공한다.

## Data 계약(참고)

```swift
public protocol LearningProjectRemote: Sendable {
    func fetchProjects(page: Int, size: Int) async throws -> ProjectListResponseDTO
}
```

`GET /api/v1/projects?page&size`(Bearer 인증)에 대응한다(FR-011). `COMPLETED`가 아닌
프로젝트를 서버가 이미 제외하므로(FR-014) 이 계약도, UseCase도 별도 필터링을 추가하지
않는다.

## 오류 계약

| Domain 케이스 | 서버 코드 | 조건 |
|---|---|---|
| `unauthorized` | 401 `COMMON-002` | 인증되지 않은 요청(FR-015) |
| `unexpected` | 500 `COMMON-005` | 서버 내부 오류 |

## FR-025 테스트 매트릭스

- 성공: Fake가 `items`(진행률·`nextSetId`/`nextQuestionId` 포함) + `hasNext` 반환 →
  그대로 반환(FR-012, FR-013).
- 필터링 비-회귀: Fake 응답에 `COMPLETED`가 아닌 프로젝트가 애초에 없는 상태를 가정하고,
  UseCase가 추가로 항목을 제거하지 않음을 반환 개수 비교로 검증(FR-014, "중복 필터링
  금지"의 관찰 가능한 증거).
- 오류: Fake가 `.unauthorized` 던짐 → UseCase가 그대로 던짐.

## 제외 책임(spec.md와 동일)

목록 UI 상태 관리, 무한 스크롤 이벤트 감지, 프로젝트 목록 로컬 캐싱, 프로젝트 생성 상태
감시, 실제 서버 호출 구현(Composition Adapter, 범위 밖).
