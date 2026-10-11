# 계약: GitHub Composition Adapter

**명세**: [spec.md](../spec.md) 시나리오 1, FR-001~004, FR-010·FR-011·FR-012·FR-014~016 | **데이터
모델**: [data-model.md](../data-model.md) §1

## Data↔Infrastructure Adapter

```swift
// sources/Projects/Composition/Composition/LearningProjectLifecycle/ExternalRepositoryRemoteAdapter.swift
public struct ExternalRepositoryRemoteAdapter: ExternalRepositoryRemote {
    public init(httpClient: HTTPClient)
    public func repository(owner: String, name: String) async throws -> GitHubRepositoryResponseDTO
}
```

`GET {baseURL}/repos/{owner}/{name}`을 `httpClient.send(...)`로 전송한다(FR-002). 200~299
응답은 `GitHubRepositoryResponseDTO`로 디코딩해 반환하고, 그 밖의 모든 실패는
`DataExternalRepositoryError`로 던진다(data-model.md §1 오류 매핑 표, FR-004·FR-010).
재시도하지 않으며(FR-015) 요청·응답을 기록하지 않는다(FR-016).

## Domain↔Data Adapter

```swift
// sources/Projects/Composition/Composition/LearningProjectLifecycle/ExternalRepositoryLookupAdapter.swift
public struct ExternalRepositoryLookupAdapter: ExternalRepositoryLookup {
    public init(remote: ExternalRepositoryRemote)
    public func repository(owner: String, name: String) async throws -> ExternalRepository
}
```

`remote.repository(owner:name:)`를 호출해 `GitHubRepositoryResponseDTO`를 받으면
`ExternalRepository`로 변환해 반환한다(FR-003). `remote`가 `DataExternalRepositoryError`를
던지면 대응하는 `ExternalRepositoryError`로 변환해 다시 던진다(data-model.md §1 오류 매핑 표).

## FR-014 테스트 매트릭스

**`ExternalRepositoryRemoteAdapter`** — Fake `HTTPTransport`를 주입한 실제 `HTTPClient`로
검증(007 FR-025 방식과 달리 Test Double이 아니라 실제 `HTTPClient`·`RequestURLBuilder`·
`HTTPBodyCoding` 코드가 실행된다):

- 성공: Fake transport가 200 + GitHub 응답 예시 JSON 반환 → `GitHubRepositoryResponseDTO`로
  정확히 디코딩됨을 확인.
- 오류 1: Fake transport가 404/403/5xx 반환 → `DataExternalRepositoryError.other`.
- 오류 2: Fake transport가 `HTTPClientError.connectionFailed` 던짐 →
  `DataExternalRepositoryError.offline`.
- 오류 3: Fake transport가 `HTTPClientError.timedOut`/`.cancelled`/`.responseDecodingFailed`
  던짐 → `DataExternalRepositoryError.other`.
- 요청 검증: 실제로 구성된 `HTTPTransportRequest`의 URL이 `https://api.github.com/repos/{owner}/{name}`과
  일치하는지 확인(SC-003 회귀 고정).

**`ExternalRepositoryLookupAdapter`** — Fake `ExternalRepositoryRemote`로 검증:

- 성공: Fake가 `GitHubRepositoryResponseDTO` 반환 → `ExternalRepository`로 정확히 변환.
- 오류 1: Fake가 `.offline` 던짐 → `ExternalRepositoryError.offline`.
- 오류 2: Fake가 `.other` 던짐 → `ExternalRepositoryError.other`.

## 제외 책임(spec.md와 동일)

`invalidURLFormat` 판별(007 Domain UseCase 책임), 로그인·세션·토큰 발급(범위 밖), Feature/UI
소비, App 수준 DI Container 등록.
