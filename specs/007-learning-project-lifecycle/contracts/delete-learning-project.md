# 계약: DeleteLearningProject

**명세**: [spec.md](../spec.md) FR-020~022 | **데이터 모델**: [data-model.md](../data-model.md)
`LearningProjectError` | **006 계약**:
[delete-learning-project.md](../../006-domain-usecase-requirements/contracts/delete-learning-project.md)

## Domain 계약

```swift
// LearningProjectRepository(동일 프로토콜에 추가 — 이 4개 계약 파일이 함께 정의하는
// 하나의 프로토콜이다, research.md 결정 3)
public protocol LearningProjectRepository: Sendable {
    func deleteProject(projectId: String) async throws
}
```

```swift
// sources/Projects/Domain/DomainLearningProject/UseCases/DeleteLearningProject.swift
public struct DeleteLearningProject: Sendable {
    public init(repository: LearningProjectRepository)
    public func callAsFunction(projectId: String) async throws
}
```

## Data 계약(참고)

```swift
public protocol LearningProjectRemote: Sendable {
    func deleteProject(projectId: String) async throws
}
```

`DELETE /api/v1/projects/{projectId}`(Bearer 인증)에 대응한다(FR-020). 성공 응답은
`data: null`이므로 반환 값이 없다.

## 삭제 후 상태 규칙 (FR-021)

이 UseCase는 로컬 캐시·상태를 전혀 유지하지 않으므로 "삭제된 프로젝트를 계속 유효한 것으로
취급"할 상태 자체가 없다 — 성공 후 별도 무효화 로직을 추가하지 않는다(FR-021 `MUST NOT`을
아무것도 하지 않음으로 충족). 삭제 후 `FetchLearningProjectDetail`이 같은 `projectId`로
`notFound`를 반환하는지는 이 UseCase가 아니라 서버·Repository 구현의 책임이며, 시나리오
3 "독립 테스트"의 회귀 확인은 두 UseCase를 조합한 통합 계약 테스트(quickstart.md)에서
검증한다.

## 오류 계약

| Domain 케이스 | 서버 코드 | 조건 |
|---|---|---|
| `unauthorized` | 401 `COMMON-002` | 인증되지 않은 요청 |
| `notFound` | 404 `PROJECT-001` | 존재하지 않음, 본인 소유 아님, 이미 삭제됨 — 사유 구분 없이 동일 케이스(FR-022) |
| `unexpected` | 500 `COMMON-005` | 서버 내부 오류 |

## FR-025 테스트 매트릭스

- 성공: Fake가 오류 없이 반환 → UseCase가 오류 없이 완료.
- 오류: Fake가 `.notFound` 던짐(존재하지 않음·소유권 없음·이미 삭제 어떤 이유든 동일
  케이스) → UseCase가 그대로 던짐(FR-022 회귀 고정, SC-003).

## 제외 책임(spec.md와 동일)

삭제 확인 UI, 화면 이동, 클라이언트 로컬 데이터 정리, 서버 내부 종속 데이터 삭제 방식
결정, 실제 서버 호출 구현(Composition Adapter, 범위 밖).
