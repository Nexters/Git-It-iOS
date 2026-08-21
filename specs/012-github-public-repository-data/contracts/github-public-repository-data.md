# 계약: GitHub Public Repository Data

**명세**: [spec.md](../spec.md) | **데이터 모델**: [data-model.md](../data-model.md)

## 공개 Swift 계약

다음 선언 형태를 `DataLearningProject`가 제공한다. 이는 구현 방향을 고정하는 공개 계약이며
구체 HTTP 요청 변환·전송 구현은 포함하지 않는다.

```swift
public struct GitHubRepositoryRequest: Equatable, Sendable {
    public init(owner: String, repository: String)

    public let scheme: String
    public let host: String
    public let method: String
    public let path: String
    public let headers: [String: String]
}

public struct GitHubRepositoryResponseDTO: Decodable, Equatable, Sendable {
    public init(
        htmlURL: String,
        ownerAvatarURL: String?,
        starCount: Int,
        topics: [String]
    )

    public let htmlURL: String
    public let ownerAvatarURL: String?
    public let starCount: Int
    public let topics: [String]
}

public enum DataExternalRepositoryError: CaseIterable, Equatable, Error, Sendable {
    /// 네트워크 연결 실패를 표현하며 실제 기술 오류 매핑은 Composition이 담당한다.
    case offline

    /// 그 밖의 실패를 표현하며 실제 기술 오류 매핑은 Composition이 담당한다.
    case other
}

public protocol ExternalRepositoryRemote: Sendable {
    func repository(
        _ request: GitHubRepositoryRequest
    ) async throws -> GitHubRepositoryResponseDTO
}
```

## Request 계약

`GitHubRepositoryRequest(owner: "facebook", repository: "react")` 결과는 다음과 정확히
일치해야 한다.

| 필드 | 기대값 |
|---|---|
| `scheme` | `https` |
| `host` | `api.github.com` |
| `method` | `GET` |
| `path` | `/repos/facebook/react` |
| `headers["Accept"]` | `application/vnd.github+json` |
| `headers["X-GitHub-Api-Version"]` | `2022-11-28` |

headers에는 `Authorization`과 세 종류의 금지 credential 값이 없어야 한다.

## Response decoding 계약

- `html_url`, `owner.avatar_url`, `stargazers_count`, `topics`를 네 공개 필드로 매핑한다.
- `owner.avatar_url` 누락·`null`은 `nil`, `topics` 누락·`null`은 `[]`다.
- `owner` 컨테이너 누락·`null`, `html_url` 또는 `stargazers_count` 누락·잘못된 타입은
  decoding failure다.
- 추가 wire 필드는 결과에 영향을 주지 않는다.
- `full_name`, `language`는 공개 저장 데이터가 아니다.

## Remote 오류 계약

`ExternalRepositoryRemote` 구현체는 성공 시 DTO 하나를 반환하고 실패 시 성공 값을 반환하지
않는다. 계약상 호출자가 구분하는 오류는 `DataExternalRepositoryError.offline`과 `.other`
두 케이스다. 현재 계약 테스트는 지정된 오류의 손실 없는 전달만 확인하며 기술 오류·HTTP
상태의 실제 분류와 변환은 후속 Composition Adapter 계약에서 다룬다. 두 enum case의 공개
문서 주석은 이 의미와 책임 경계를 코드에 남겨야 한다.

## 자동화 테스트 매트릭스

### `GitHubRepositoryRequestTests`

- 대표 owner/repository에서 scheme·host·method·path·두 header가 정확하다.
- `Authorization` header와 Git-It access/refresh token, Apple identity token이 없다.

### `GitHubRepositoryResponseDTOTests`

- 정상 최소 JSON과 추가 필드 포함 JSON이 네 필드를 손실 없이 디코딩한다.
- avatar key 누락·`null`, topics 누락·`null`·빈 배열, star 0을 각각 검증한다.
- owner 누락·`null`, 필수 필드 누락·잘못된 타입은 실패한다.
- Mirror 또는 공개 API 검증으로 저장 필드가 네 개뿐이며 `full_name`, `language`가 없음을 확인한다.

### `DataExternalRepositoryErrorTests`

- `allCases == [.offline, .other]`이고 두 케이스가 서로 다르다.

### `ExternalRepositoryRemoteContractTests`

- actor Probe가 Request를 한 번 기록하고 예정 DTO를 그대로 반환한다.
- `.offline`과 `.other`를 던지는 Probe에서 각각 같은 오류가 관찰되고 성공 DTO는 반환되지 않는다.

## 제외 책임

- Domain `ExternalRepository` 변환과 `invalidURLFormat`
- Infrastructure `HTTPRequest`, `HTTPMethod`, `HTTPHeaders` 생성
- 실제 네트워크 전송, 상태·기술 오류 매핑, 재시도와 로깅
- Private Repository 인증과 App DI
