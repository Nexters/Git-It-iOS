# 계약: FetchLearningProjectDetail

**명세**: [spec.md](../spec.md) FR-016~019 | **데이터 모델**: [data-model.md](../data-model.md)
`LearningProjectDetail`, `LearningProjectSetProgress`, `LearningProjectError` | **006 계약**:
[fetch-learning-project-detail.md](../../006-domain-usecase-requirements/contracts/fetch-learning-project-detail.md)

## Domain 계약

```swift
// LearningProjectRepository(동일 프로토콜에 추가)
public protocol LearningProjectRepository: Sendable {
    func fetchProjectDetail(projectId: String) async throws -> LearningProjectDetail
}
```

```swift
// sources/Projects/Domain/DomainLearningProject/UseCases/FetchLearningProjectDetail.swift
public struct FetchLearningProjectDetail: Sendable {
    public init(repository: LearningProjectRepository)
    public func callAsFunction(projectId: String) async throws -> LearningProjectDetail
}
```

## Data 계약(참고)

```swift
public protocol LearningProjectRemote: Sendable {
    func fetchProjectDetail(projectId: String) async throws -> ProjectDetailResponseDTO
}
```

`GET /api/v1/projects/{projectId}`(Bearer 인증)에 대응한다(FR-016).

## 다음 세트 판단 규칙 (FR-019)

`LearningProjectDetail.nextSet`은 `sets`에서 `completedCount < problemCount`인 첫 세트다
(data-model.md 참고, 계산 프로퍼티로 모델이 소유). UseCase는 이 계산을 직접 수행하지 않고
`repository.fetchProjectDetail`이 반환한 `LearningProjectDetail`을 그대로 반환한다 — 계산
결과는 값을 소비하는 시점(`detail.nextSet`)에 자동으로 성립한다.

## 오류 계약

| Domain 케이스 | 서버 코드 | 조건 |
|---|---|---|
| `unauthorized` | 401 `COMMON-002` | 인증되지 않은 요청 |
| `notFound` | 404 `PROJECT-001` | 존재하지 않음, 본인 소유 아님, 삭제됨, 또는 문제 생성이 `COMPLETED`가 아님 — 사유 구분 없이 동일 케이스(FR-018) |
| `unexpected` | 500 `COMMON-005` | 서버 내부 오류 |

## FR-025 테스트 매트릭스

- 성공(진행 중 세트 존재): Fake가 `sets`에 `completedCount < problemCount`인 세트를
  포함해 반환 → `detail.nextSet`이 그 세트와 일치.
- 성공(모두 완료): Fake가 모든 세트에서 `completedCount == problemCount`로 반환 →
  `detail.nextSet == nil`(재풀이 판단은 `nextQuestionId`로, FR-019 "모든 세트를 완료했으면"
  규칙).
- 오류: Fake가 `.notFound` 던짐(소유권·삭제·미완료 등 어떤 이유든 동일 케이스) → UseCase가
  그대로 던짐(FR-018 회귀 고정, SC-003).

## 제외 책임(spec.md와 동일)

프로젝트 생성 완료 감지, 세트 문제 상세 조회, 상세 데이터 로컬 캐싱, 화면 조합과
Navigation, 실제 서버 호출 구현(Composition Adapter, 범위 밖).
