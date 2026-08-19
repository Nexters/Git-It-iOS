# 데이터 모델: GitHub·Git-It 프로젝트 API Composition Adapter 구축

**날짜**: 2026-08-20 | **명세**: [spec.md](./spec.md) | **조사**: [research.md](./research.md)

이 기능은 새 Domain·Data 모델을 도입하지 않는다 — 007이 이미 정의한 모델·DTO·오류 타입을
그대로 소비한다. 이 문서는 이 기능이 실제로 추가하는 구조물인 Composition Adapter 4종의
구성(생성자 의존성, 책임, 오류 매핑 표)만 다룬다.

## 1. GitHub Composition Adapter

### ExternalRepositoryRemoteAdapter (Data↔Infrastructure)

`DataLearningProject`의 `ExternalRepositoryRemote` 프로토콜을 구현한다(007
[fetch-external-repository.md](../007-learning-project-lifecycle/contracts/fetch-external-repository.md)).

| 생성자 의존성 | 타입 | 용도 |
|---|---|---|
| `httpClient` | `HTTPClient`(`InfrastructureNetworkClient`) | `GET /repos/{owner}/{name}` 전송(base URL: `https://api.github.com`로 구성된 인스턴스를 주입받음, research.md 결정 3) |

**오류 매핑**(`HTTPClientError`/상태 코드 → `DataExternalRepositoryError`):

| 원인 | `DataExternalRepositoryError` |
|---|---|
| `HTTPClientError.connectionFailed` | `offline` |
| `HTTPClientError`의 그 밖의 모든 케이스(`invalidURL`·`requestEncodingFailed`·`timedOut`·`cancelled`·`responseDecodingFailed`) | `other` |
| GitHub 응답 상태 코드가 200~299가 아님(404·403·5xx 등) | `other` |

### ExternalRepositoryLookupAdapter (Domain↔Data)

`DomainLearningProject`의 `ExternalRepositoryLookup` 프로토콜을 구현한다.

| 생성자 의존성 | 타입 | 용도 |
|---|---|---|
| `remote` | `ExternalRepositoryRemote`(`ExternalRepositoryRemoteAdapter`) | GitHub 응답 DTO 조회 |

**변환**: `GitHubRepositoryResponseDTO` → `ExternalRepository`(007 data-model.md §1). **오류
매핑**: `DataExternalRepositoryError` → `ExternalRepositoryError`(케이스명 1:1 대응 —
`offline`→`offline`, `other`→`other`. `invalidURLFormat`은 이 Adapter가 던지지 않는다, 007
research.md 결정 4).

## 2. Git-It 서버 Composition Adapter

### LearningProjectRemoteAdapter (Data↔Infrastructure)

`DataLearningProject`의 `LearningProjectRemote` 프로토콜을 구현한다(007
[create-learning-project.md](../007-learning-project-lifecycle/contracts/create-learning-project.md)
외 3개 계약 파일).

| 생성자 의존성 | 타입 | 용도 |
|---|---|---|
| `httpClient` | `HTTPClient`(`InfrastructureNetworkClient`) | `/api/v1/projects` 4개 엔드포인트 전송(base URL: Git-It 서버로 구성된 인스턴스를 주입받음, research.md 결정 3) |
| `sessionStorage` | `LoginSessionStorage`(`DataAuthentication`, 001에서 이미 정의) | 요청 직전 `load()?.accessToken`으로 `Authorization: Bearer` 헤더 구성(research.md 결정 2) |

**오류 매핑**(HTTP 상태 코드 + `code` 필드 → `DataLearningProjectError`):

| 상태 코드 | `code` | `DataLearningProjectError` |
|---|---|---|
| 400 | `COMMON-001` | `invalidRequest` |
| 401 | `COMMON-002` | `unauthorized` |
| 404 | `PROJECT-001` | `notFound` |
| 500 | `COMMON-005` | `serverError` |
| 그 밖의 상태 코드, 또는 `HTTPClientError`(연결 실패·타임아웃·취소·인코딩/디코딩 실패) | — | `unexpected` |

### LearningProjectRepositoryAdapter (Domain↔Data)

`DomainLearningProject`의 `LearningProjectRepository` 프로토콜을 구현한다.

| 생성자 의존성 | 타입 | 용도 |
|---|---|---|
| `remote` | `LearningProjectRemote`(`LearningProjectRemoteAdapter`) | 등록·목록·상세·삭제 DTO 조회 |

**변환**: `RegisterProjectResponseDTO`→`LearningProjectRegistration`,
`ProjectListResponseDTO`→`LearningProjectPage`, `ProjectDetailResponseDTO`→
`LearningProjectDetail`(007 data-model.md §1). **오류 매핑**: `DataLearningProjectError` →
`LearningProjectError`(`invalidRequest`→`invalidRequest`, `unauthorized`→`unauthorized`,
`notFound`→`notFound`, `serverError`/`unexpected`→`unexpected`).

## 3. 관계 요약

```text
FetchExternalRepository(Domain UseCase, 007)
  └─ 생성자 주입 ─▶ ExternalRepositoryLookupAdapter(Domain↔Data, 이 기능)
                       └─ 생성자 주입 ─▶ ExternalRepositoryRemoteAdapter(Data↔Infrastructure, 이 기능)
                                            └─ 생성자 주입 ─▶ HTTPClient(Infrastructure, 003)

CreateLearningProject / FetchLearningProjects / FetchLearningProjectDetail / DeleteLearningProject
(Domain UseCase, 007)
  └─ 생성자 주입 ─▶ LearningProjectRepositoryAdapter(Domain↔Data, 이 기능)
                       └─ 생성자 주입 ─▶ LearningProjectRemoteAdapter(Data↔Infrastructure, 이 기능)
                                            ├─ 생성자 주입 ─▶ HTTPClient(Infrastructure, 003)
                                            └─ 생성자 주입 ─▶ LoginSessionStorage(Data, 001 — 프로덕션 구현은 범위 밖)
```

4개 Adapter 모두 비즈니스 규칙을 포함하지 않으며(FR-012), 요청·응답 변환과 오류 매핑만
수행한다.
