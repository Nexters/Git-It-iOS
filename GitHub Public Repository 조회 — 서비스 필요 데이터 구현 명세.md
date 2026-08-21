# GitHub Public Repository 조회 — 서비스 필요 데이터 구현 명세

**문서 ID**: `U02-GITHUB-REPOSITORY-LOOKUP`  
**대상 기능**: U02 Repository 확인  
**구현 대상**: `DataLearningProject`  
**API**: `GET https://api.github.com/repos/{owner}/{repo}`  
**인증**: 없음 — Public Repository 전용  
**상태**: 구현 가능

## 1. 목적

사용자가 입력한 GitHub Repository가 조회 가능한 Public Repository인지 확인하고, Git-It의 프로젝트 등록 화면에서 필요한 최소 Repository 정보만 획득한다.

GitHub API의 전체 응답을 모델링하지 않는다.

서비스에서 필요한 데이터만 DTO로 decoding하고 나머지 JSON 필드는 무시한다.

---

## 2. 요청

```http
GET https://api.github.com/repos/{owner}/{repo}
```

### Path Parameter

| 이름 | 타입 | 필수 | 설명 |
|---|---|---:|---|
| `owner` | `String` | O | Repository 소유자 |
| `repo` | `String` | O | Repository 이름 |

### Headers

```http
Accept: application/vnd.github+json
X-GitHub-Api-Version: 2022-11-28
```

### 인증 정책

GitHub Public Repository 조회에는 Git-It 인증 정보를 전달하지 않는다.

특히 다음 값을 GitHub 요청에 포함해서는 안 된다.

```text
Git-It accessToken
Git-It refreshToken
Apple identity token
```

GitHub API와 Git-It API는 서로 다른 base URL 및 인증 정책을 사용한다.

---

## 3. 서비스에서 필요한 응답 데이터

GitHub 전체 Repository 응답 중 다음 데이터만 소비한다.

| GitHub JSON | Swift | 필수 | 서비스 용도 |
|---|---|---:|---|
| `html_url` | `String` | O | 프로젝트 등록에 사용할 canonical Repository URL |
| `owner.avatar_url` | `String?` | X | Repository 표시 이미지 |
| `stargazers_count` | `Int` | O | Star 수 표시 |
| `topics` | `[String]` | O | 기술 스택 표시 |

현재 Domain 모델은 다음 값을 필요로 한다.

```text
ExternalRepository
├── canonicalURL
├── ownerName
├── repositoryName
├── imageURL?
├── starCount
└── techStack[]
```

`ownerName`과 `repositoryName`은 입력 GitHub URL에서 파싱된 `owner/repo` 값을 사용한다.

따라서 GitHub 응답의 다음 데이터는 현재 서비스 구현에 필요하지 않다.

```text
id
node_id
name
description
homepage
default_branch
visibility
fork
license
permissions
clone_url
ssh_url
git_url
size
forks_count
watchers_count
open_issues_count
created_at
updated_at
pushed_at
commits_url
issues_url
pulls_url
branches_url
...
```

전체 Repository wire schema를 Data 모델에 복제하지 않는다.

---

## 4. Response DTO

서비스 요구사항 기준 DTO는 다음 수준으로 제한한다.

```swift
public struct GitHubRepositoryResponseDTO: Decodable, Equatable, Sendable {

    public let htmlURL: String
    public let ownerAvatarURL: String?
    public let starCount: Int
    public let topics: [String]

}
```

Nested `owner.avatar_url`을 decoding해야 하므로 실제 decoder 구현에서는 owner 전용 nested key를 사용한다.

권장 wire mapping:

```text
htmlURL        ← html_url
ownerAvatarURL ← owner.avatar_url
starCount      ← stargazers_count
topics         ← topics
```

---

## 5. Nullability

### `owner.avatar_url`

Domain의 `imageURL`이 optional이므로 DTO에서도 optional로 유지한다.

```swift
ownerAvatarURL: String?
```

이미지 URL이 없거나 사용할 수 없더라도 Repository 조회 자체를 실패시키지 않는다.

### `topics`

서비스에서는 기술 스택 배열로 사용하므로 응답 누락에 안전하게 대응한다.

```swift
topics = decodeIfPresent([String].self) ?? []
```

topics가 없다고 Repository 조회를 실패시키지 않는다.

---

## 6. Domain Mapping

```text
GitHubRepositoryResponseDTO
            ↓
ExternalRepository
```

매핑은 다음과 같다.

| Domain | 원천 |
|---|---|
| `canonicalURL` | `dto.htmlURL` |
| `ownerName` | 요청 전 URL에서 파싱한 owner |
| `repositoryName` | 요청 전 URL에서 파싱한 repo |
| `imageURL` | `dto.ownerAvatarURL` |
| `starCount` | `dto.starCount` |
| `techStack` | `dto.topics` |

현재 Composition Adapter도 이 구조로 Domain 모델을 생성하고 있다. 

---

## 7. `language` 처리

현재 `GitHubRepositoryResponseDTO`에는 다음 필드가 존재한다.

```swift
language: String?
```

하지만 현재 `ExternalRepository` Domain에는 대응 필드가 없고 실제 adapter에서도 사용하지 않는다.

따라서 **현재 서비스 요구사항만 기준으로 하면 `language`는 DTO에서 제거 가능하다.**

서비스에서 이후 다음과 같이 language를 기술 스택에 포함시키기로 별도 결정하지 않는 이상:

```text
language + topics → techStack
```

현재 명세에서는 사용하지 않는다.

---

## 8. `full_name` 처리

현재 DTO에는 `full_name`도 존재하지만 실제 Domain mapping에서는 사용하지 않는다.

현재 계약은 URL에서 미리 파싱한:

```text
owner
repo
```

를 각각 `ownerName`, `repositoryName`으로 사용한다.

따라서 현재 서비스 요구사항만 기준으로 하면 `full_name` 역시 필수 decoding 대상이 아니다.

향후 Repository rename/transfer 후 반환되는 canonical owner/repository까지 갱신하는 요구사항이 추가될 경우 별도 계약으로 확장한다.

---

## 9. Repository URL Validation

GitHub API 호출 전에 최소한 다음 형식을 검증한다.

```text
https://github.com/{owner}/{repo}
```

파싱 결과:

```text
owner
repo
```

둘 중 하나라도 획득하지 못하면 GitHub API를 호출하지 않는다.

```text
invalid URL
→ API request 0회
→ invalidURLFormat
```

`.git` 제거 등 URL 자동 보정 범위는 현재 미확정 제품 결정이므로 이 API 명세에서 추가 정의하지 않는다.

---

## 10. 오류 처리

서비스에서 필요한 오류 수준만 구분한다.

```text
invalidURLFormat
offline
repositoryUnavailable
other
```

### URL 오류

GitHub 요청 이전에 URL 파싱이 실패한 경우:

```text
invalidURLFormat
```

### 네트워크 연결 실패

```text
offline
```

사용자 입력 URL은 유지한다.

### Repository 조회 불가

다음과 같은 경우 하나의 의미로 처리한다.

```text
404
Private Repository
삭제된 Repository
접근할 수 없는 Repository
```

→

```text
repositoryUnavailable
```

클라이언트에서 원인을 추론하여 사용자에게 노출하지 않는다.

### 기타

```text
403
5xx
decoding failure
기타 예상하지 못한 오류
```

현재 제품 정책이 추가 확정되기 전에는:

```text
other
```

로 처리할 수 있다.

GitHub rate limit에 대한 최종 사용자 문구와 재시도 정책은 현재 미확정 상태다.

---

## 11. 기능 요구사항

- **FR-GH-001**: Repository URL에서 `owner`, `repo`를 파싱할 수 있어야 한다.
- **FR-GH-002**: URL 파싱 실패 시 GitHub API 호출은 0회여야 한다.
- **FR-GH-003**: Repository 확인은 `GET /repos/{owner}/{repo}`를 사용해야 한다.
- **FR-GH-004**: GitHub 요청에 Git-It Bearer token을 포함해서는 안 된다.
- **FR-GH-005**: 성공 응답에서 `html_url`을 canonical Repository URL로 보존해야 한다.
- **FR-GH-006**: `owner.avatar_url`을 optional 이미지 URL로 보존해야 한다.
- **FR-GH-007**: `stargazers_count`를 손실 없이 보존해야 한다.
- **FR-GH-008**: `topics`를 서버 반환 순서 그대로 보존해야 한다.
- **FR-GH-009**: 서비스에서 사용하지 않는 GitHub 응답 필드를 DTO에 추가할 필요가 없다.
- **FR-GH-010**: GitHub DTO를 Feature에 직접 노출해서는 안 된다.
- **FR-GH-011**: 조회 불가능한 Repository를 등록 가능한 `ExternalRepository`로 생성해서는 안 된다.
- **FR-GH-012**: 실패 시 사용자가 입력한 Repository URL을 보존해야 한다.

---

## 12. 테스트 요구사항

### URL Parsing

- 정상 `https://github.com/facebook/react`
- owner 누락
- repo 누락
- GitHub가 아닌 host
- 잘못된 URL

### Request

- method가 `GET`
- path가 `/repos/{owner}/{repo}`
- `Accept` header 존재
- API version header 존재
- `Authorization` header 없음

### DTO

다음 최소 JSON으로 decoding 가능해야 한다.

```json
{
  "html_url": "https://github.com/facebook/react",
  "owner": {
    "avatar_url": "https://avatars.githubusercontent.com/u/69631"
  },
  "stargazers_count": 0,
  "topics": [
    "javascript",
    "react"
  ]
}
```

### Optional 데이터

다음 응답도 성공해야 한다.

```json
{
  "html_url": "https://github.com/example/repository",
  "owner": {
    "avatar_url": null
  },
  "stargazers_count": 0,
  "topics": []
}
```

### 추가 필드

GitHub 응답에 서비스가 사용하지 않는 필드가 수십 개 포함돼도 decoding 결과에 영향을 주지 않아야 한다.

Swift `Decodable`은 정의하지 않은 JSON key를 기본적으로 무시하므로 전체 wire schema를 구현할 필요가 없다.

---

## 13. 성공 기준

- **SC-GH-001**: Public Repository 정상 조회가 성공한다.
- **SC-GH-002**: GitHub 요청에 Git-It 인증 정보 전송이 0건이다.
- **SC-GH-003**: Repository 표시 및 등록에 필요한 필드 손실이 0건이다.
- **SC-GH-004**: 불필요한 GitHub 응답 필드가 Domain으로 전달되는 경우가 0건이다.
- **SC-GH-005**: `owner.avatar_url`이 없는 Repository에서도 조회가 성공한다.
- **SC-GH-006**: `topics=[]`에서도 조회가 성공한다.
- **SC-GH-007**: 조회 불가능한 Repository가 등록 가능한 상태가 되는 경우가 0건이다.

---

## 14. 현재 코드 대비 변경 범위

현재 `GitHubRepositoryResponseDTO`는 다음 값을 가지고 있다.

```text
fullName
htmlURL
ownerAvatarURL
starCount
language
topics
```

현재 서비스 Domain에서 실제 사용하는 값은:

```text
htmlURL
ownerAvatarURL
starCount
topics
```

이며 `fullName`, `language`는 현재 adapter에서 사용하지 않는다.  

따라서 서비스 필요 데이터만 엄격하게 유지한다면 DTO는 다음 네 필드로 축소할 수 있다.

```swift
GitHubRepositoryResponseDTO
├── htmlURL
├── ownerAvatarURL?
├── starCount
└── topics
```

Domain에는 기존 `ExternalRepository` 계약을 유지한다.

---

## 15. 범위 밖

다음 데이터와 API는 이 기능에서 구현하지 않는다.

```text
Repository id
node_id
license
permissions
fork 정보
watcher/fork/open issue 통계
clone/SSH URL
branch/tag
commit
issue
pull request
contributor
subscriber
repository size
created/updated/pushed date
GitHub GraphQL
Private Repository 인증
```

필요한 기능이 실제 제품 요구사항으로 추가될 때 해당 API와 DTO를 별도 명세한다.