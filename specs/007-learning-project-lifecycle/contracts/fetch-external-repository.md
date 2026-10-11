# 계약: FetchExternalRepository

**명세**: [spec.md](../spec.md) FR-001~004 | **데이터 모델**: [data-model.md](../data-model.md)
`ExternalRepository`, `ExternalRepositoryError` | **006 계약**:
[fetch-external-repository.md](../../006-domain-usecase-requirements/contracts/fetch-external-repository.md)

## Domain 계약

```swift
// sources/Projects/Domain/DomainLearningProject/Contracts/ExternalRepositoryLookup.swift
public protocol ExternalRepositoryLookup: Sendable {
    /// URL 파싱은 호출자(UseCase)가 이미 끝낸 뒤 소유자·저장소 이름으로 호출한다.
    /// `.invalidURLFormat`은 이 메서드가 던지지 않는다(research.md 결정 4).
    func repository(owner: String, name: String) async throws -> ExternalRepository
}
```

```swift
// sources/Projects/Domain/DomainLearningProject/UseCases/FetchExternalRepository.swift
public struct FetchExternalRepository: Sendable {
    public init(lookup: ExternalRepositoryLookup)
    public func callAsFunction(url: String) async throws -> ExternalRepository
}
```

`callAsFunction`은 `url`에서 소유자·저장소 이름을 파싱한다(FR-001). 파싱에 성공하면
`lookup.repository(owner:name:)`을 호출해 결과를 그대로 반환/재던짐한다. 파싱에 실패하면
`lookup`을 호출하지 않고 `ExternalRepositoryError.invalidURLFormat`을 던진다.

## Data 계약(참고 — Composition Adapter가 향후 `ExternalRepositoryLookup`을 구현할 때 위임)

```swift
// sources/Projects/Data/DataLearningProject/Contracts/ExternalRepositoryRemote.swift
public protocol ExternalRepositoryRemote: Sendable {
    func repository(owner: String, name: String) async throws -> GitHubRepositoryResponseDTO
}
```

`GET https://api.github.com/repos/{owner}/{name}`에 대응한다(FR-002, Git-It 서버가 아닌
GitHub 공개 API). 오류는 `DataExternalRepositoryError`(`.offline`/`.other`)로 던진다.

## 오류 계약

| Domain 케이스 | 조건 | 테스트로 검증할 경로 |
|---|---|---|
| `invalidURLFormat` | URL에서 소유자·저장소를 파싱할 수 없음 | `lookup`을 호출하지 않았음을 Fake로 검증(FR-001) |
| `offline` | `lookup`이 `.offline`을 던짐 | UseCase가 동일 케이스를 그대로 던짐 |
| `other` | `lookup`이 `.other`를 던짐(Private·존재하지 않음·rate limit·5xx 등 구분 없이) | UseCase가 동일 케이스를 그대로 던짐 |

## 성공 계약

`lookup`이 `ExternalRepository`를 반환하면 UseCase는 값을 그대로 반환한다(변형하지 않음).

## FR-025 테스트 매트릭스

- 성공: 파싱 가능한 URL + Fake가 `ExternalRepository` 반환 → 그대로 반환.
- 오류 1: 파싱 불가 URL(예: 빈 문자열, GitHub 도메인이 아닌 URL) → `.invalidURLFormat`,
  Fake 호출 안 됨.
- 오류 2: Fake가 `.offline` 던짐 → UseCase가 `.offline` 그대로 던짐.
- 오류 3: Fake가 `.other` 던짐 → UseCase가 `.other` 그대로 던짐.

## 제외 책임(spec.md와 동일)

학습 프로젝트 생성, Repository 정보의 로컬 영속화, Private Repository 인증, URL 자동
정규화, 화면 입력 상태 관리, 실제 GitHub API 호출 구현(Composition Adapter, 범위 밖).
