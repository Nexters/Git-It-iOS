# 데이터 모델: GitHub Public Repository Data 계약

**날짜**: 2026-08-21 | **명세**: [spec.md](./spec.md) | **조사**:
[research.md](./research.md)

이 기능은 `DataExternalRepository`가 소유할 요청·응답·오류·Remote 계약만 정의한다. 모든 공개
값 타입은 불변이며 `Sendable`이다. Domain 모델과 Infrastructure 타입은 포함하지 않는다.

## 1. `GitHubRepositoryRequest`

파싱이 끝난 `owner`와 `repository`로 GitHub Repository endpoint를 표현하는 기술 중립적
요청 값이다.

| 공개 필드 | 타입 | 고정 규칙 |
|---|---|---|
| `scheme` | `String` | `https` |
| `host` | `String` | `api.github.com` |
| `method` | `String` | `GET` |
| `path` | `String` | `/repos/{owner}/{repository}` |
| `headers` | `[String: String]` | 아래 두 필드만 포함 |

필수 headers:

| 이름 | 값 |
|---|---|
| `Accept` | `application/vnd.github+json` |
| `X-GitHub-Api-Version` | `2022-11-28` |

### 생성·검증 규칙

- public initializer는 `owner: String`, `repository: String`만 받는다.
- `owner`와 `repository`는 upstream Domain에서 검증·파싱된 값으로 간주하며 Data가 URL 자동
  보정 또는 형식 오류를 다시 판단하지 않는다.
- arbitrary header initializer를 제공하지 않으므로 `Authorization`, Git-It access/refresh
  token, Apple identity token을 요청 값에 넣을 수 없다.
- `Equatable`, `Sendable`을 채택한다.

## 2. `GitHubRepositoryResponseDTO`

GitHub `GET /repos/{owner}/{repo}` 응답에서 서비스가 소비하는 최소 wire 데이터만 평탄화한다.

| 공개 필드 | Swift 타입 | wire 원천 | 규칙 |
|---|---|---|---|
| `htmlURL` | `String` | `html_url` | 필수 |
| `ownerAvatarURL` | `String?` | `owner.avatar_url` | `owner`는 필수, 내부 값은 선택 |
| `starCount` | `Int` | `stargazers_count` | 필수, `0` 허용 |
| `topics` | `[String]` | `topics` | 누락·`null`은 `[]`, 순서 보존 |

### 디코딩 불변조건

- `html_url`, `owner`, `stargazers_count`가 누락되거나 `null` 또는 호환되지 않는 타입이면
  디코딩에 실패한다.
- `owner.avatar_url`이 누락되거나 `null`이면 `ownerAvatarURL == nil`이다.
- `topics`가 누락되거나 `null`이면 빈 배열이고, 값이 있으면 순서와 문자열을 그대로 보존한다.
- 정의하지 않은 추가 키는 무시한다.
- `full_name`, `language`를 포함한 미사용 필드는 공개 저장 데이터에 없다.
- `Decodable`, `Equatable`, `Sendable`을 채택하며 `Encodable`은 채택하지 않는다.
- 공개 initializer는 네 공개 필드만 받는다.

## 3. `DataExternalRepositoryError`

Repository Remote 실패를 Data 경계에서 구분하는 연관값 없는 오류다.

| 케이스 | 의미 |
|---|---|
| `offline` | 네트워크 연결 실패를 표현하는 Data 오류 |
| `other` | 그 밖의 실패를 표현하는 Data 오류 |

`CaseIterable`, `Equatable`, `Error`, `Sendable`을 채택한다. URL 형식 오류 케이스는 없다.
각 case의 의미와 실제 `HTTPClientError`·상태 코드를 변환하는 책임이 후속 Composition에 있음을
공개 문서 주석으로 남긴다. 이 기능은 두 case의 구분과 지정된 오류의 전달만 검증한다.

## 4. `ExternalRepositoryRemote`

Data가 필요로 하는 외부 Repository 조회 능력이다.

| 항목 | 내용 |
|---|---|
| 입력 | `GitHubRepositoryRequest` |
| 성공 | `GitHubRepositoryResponseDTO` |
| 실패 계약 | `DataExternalRepositoryError.offline` 또는 `.other` |
| 동시성 | 프로토콜 자체가 `Sendable` |

연산은 조회 하나만 제공하며 캐시·저장·재시도·취소 정책을 추가하지 않는다.

## 5. 관계

```text
upstream에서 파싱한 owner/repository
                │
                ▼
GitHubRepositoryRequest ──입력──▶ ExternalRepositoryRemote
                                      │
                      ┌───────────────┴───────────────┐
                      ▼                               ▼
       GitHubRepositoryResponseDTO      DataExternalRepositoryError
       (4개 최소 응답 필드)             (offline | other)
```

## 6. 요구사항 추적

| 요구사항 | 담당 계약 |
|---|---|
| FR-001~003 | `GitHubRepositoryRequest`, `ExternalRepositoryRemote` |
| FR-004~010 | `GitHubRepositoryResponseDTO` custom decoding |
| FR-011~013 | `DataExternalRepositoryError`, Remote 실패 계약 |
| FR-014~015 | 패키지 의존성 부재와 Composition 제외 경계 |
| FR-016 | Request·DTO·Error·Remote 계약 테스트 |
