# 데이터 모델: 학습 프로젝트 생명주기 UseCase 구현

**날짜**: 2026-08-19 | **명세**: [spec.md](./spec.md) | **조사**: [research.md](./research.md)

이 문서는 spec.md `핵심 엔터티`와 006 `data-model.md`의 개념 모델을 이 기능이 실제로
구현할 Swift 타입 수준으로 확정한다. 필드명은 서버·GitHub API의 wire 이름을 보존하되,
Domain 모델은 `naming.md` §3에 따라 공급자·저장 기술 용어를 노출하지 않는다. 모든 타입은
`Sendable`을 채택한다(Swift Concurrency 경계를 넘는 값).

## 1. Domain 모델 (`DomainLearningProject`)

### ExternalRepository

`FetchExternalRepository`가 GitHub 공개 API로 확인해 반환하는, 아직 등록되지 않은 외부
Repository 정보(FR-001~003).

| 필드 | 타입 | 설명 |
|---|---|---|
| `canonicalURL` | `String` | `CreateLearningProject`의 `githubRepoUrl` 입력으로 그대로 전달됨 |
| `ownerName` | `String` | GitHub URL에서 파싱한 소유자 이름 |
| `repositoryName` | `String` | GitHub URL에서 파싱한 저장소 이름 |
| `imageURL` | `String?` | 저장소 소유자 아바타 등 |
| `starCount` | `Int` | GitHub star 수 |
| `techStack` | `[String]` | 참고용 기술 스택(등록 후 서버가 다시 확정) |

**불변조건**: `canonicalURL`은 빈 문자열이 될 수 없다(파싱에 성공한 URL만 이 타입으로
구성됨, FR-001).

### ExternalRepositoryError

`FetchExternalRepository` 실패를 나타내는 Domain 오류(FR-004). `CaseIterable, Equatable,
Error, Sendable` 채택(`AuthenticationError` 관례와 동일).

| 케이스 | 의미 |
|---|---|
| `invalidURLFormat` | 입력 문자열에서 소유자·저장소 식별 정보를 파싱할 수 없음(GitHub API 호출 전 실패) |
| `offline` | 네트워크에 연결할 수 없어 GitHub API 호출 자체가 이루어지지 못함 |
| `other` | Private Repository, 저장소 없음, rate limit, 5xx 등 나머지 모든 실패 |

### QuizLevel

| 케이스 | 의미 |
|---|---|
| `l1`, `l2`, `l3` | 문제 난이도. 직급과 무관, 깊이만 구분 |

`CaseIterable, Equatable, Sendable` 채택. wire 값(`L1`/`L2`/`L3`)과의 매핑은 Data 계층
DTO(§2 `QuizLevelDTO`)가 소유하며 Domain은 wire 표기를 노출하지 않는다.

### QuizGenerationStatus

| 케이스 | 의미 |
|---|---|
| `ready` | 등록 직후 |
| `analyzed` | 저장소 분석 완료 |
| `anchored` | 문제 근거 확정 |
| `rejected` | 문제를 낼 수 없다고 판정 |
| `failed` | 생성 실패 |
| `completed` | 학습 가능 — 목록·상세 노출 조건 |

`CaseIterable, Equatable, Sendable` 채택.

### LearningProjectRegistration

`CreateLearningProject` 성공 응답(FR-006~008).

| 필드 | 타입 | 설명 |
|---|---|---|
| `projectId` | `String` | 등록된(또는 기존/복원된) 프로젝트 id |
| `status` | `QuizGenerationStatus` | 서버 응답 그대로 |
| `quizLevel` | `QuizLevel` | 최초 등록 또는 재등록 요청에 사용된 값(research.md 결정 7 — 서버 응답 필드가 아니라 재등록 시 값이 바뀌지 않는다는 서버 계약을 근거로 보존된 값) |

### LearningProjectSummary

`FetchLearningProjects` 목록 항목(FR-012~014). `status`는 이 응답에 없다 — `COMPLETED`가
아닌 프로젝트는 서버가 애초에 목록에서 제외한다(FR-014, 클라이언트 재필터링 금지).

| 필드 | 타입 | 설명 |
|---|---|---|
| `projectId` | `String` | |
| `repositoryName` | `String` | |
| `repositoryImageURL` | `String?` | |
| `techStack` | `[String]` | |
| `currentSetLabel` | `String` | |
| `currentSetTitle` | `String` | |
| `nextSetId` | `String` | 서버가 계산해 반환(이어 풀기 진입점) |
| `nextQuestionId` | `String` | 서버가 계산해 반환 |
| `overallProgressPercent` | `Int` | |

### LearningProjectPage

`FetchLearningProjects` 반환 값 전체(FR-011, FR-013).

| 필드 | 타입 | 설명 |
|---|---|---|
| `items` | `[LearningProjectSummary]` | 생성 순서(오래된 순) |
| `hasNext` | `Bool` | 다음 페이지 존재 여부 |

### LearningProjectSetProgress

`LearningProjectDetail.sets[]` 항목(FR-017).

| 필드 | 타입 | 설명 |
|---|---|---|
| `setId` | `String` | |
| `label` | `String` | 예: "Set 1" |
| `title` | `String` | |
| `problemCount` | `Int` | |
| `completedCount` | `Int` | |

### LearningProjectDetail

`FetchLearningProjectDetail` 반환 값(FR-016~019).

| 필드 | 타입 | 설명 |
|---|---|---|
| `projectId` | `String` | |
| `repositoryURL` | `String` | GitHub 링크 |
| `repositoryName` | `String` | |
| `repositoryImageURL` | `String?` | |
| `starCount` | `Int` | |
| `techStack` | `[String]` | |
| `overallProgressPercent` | `Int` | |
| `nextQuestionId` | `String?` | 서버 응답 그대로(모든 세트 완료 시에도 값이 있을 수 있음, 계약 참고) |
| `sets` | `[LearningProjectSetProgress]` | |

**계산 프로퍼티**: `nextSet: LearningProjectSetProgress?` — `sets`에서
`completedCount < problemCount`인 첫 세트(FR-019, research.md 결정 9). 모두 완료했으면
`nil`이며, 이 경우 `nextQuestionId`가 재풀이 대상 세트의 첫 문제를 가리키는 것으로
처리한다(006 계약 문서의 "모든 세트를 완료했으면" 규칙).

### LearningProjectError

`CreateLearningProject`/`FetchLearningProjects`/`FetchLearningProjectDetail`/
`DeleteLearningProject` 공통 Domain 오류(FR-009, FR-015, FR-018, FR-022).
`CaseIterable, Equatable, Error, Sendable` 채택.

| 케이스 | 매핑 원본 | 사용 UseCase |
|---|---|---|
| `invalidRequest` | 400 `COMMON-001` | `CreateLearningProject`(FR-009) |
| `unauthorized` | 401 `COMMON-002` | 4개 UseCase 전체(FR-015 등) |
| `notFound` | 404 `PROJECT-001` | `FetchLearningProjectDetail`, `DeleteLearningProject`(FR-018, FR-022 — 소유권·존재·삭제·미완료 사유를 구분하지 않는 동일 케이스) |
| `unexpected` | 500 `COMMON-005` 및 그 밖의 미분류 실패 | 4개 UseCase 전체(spec.md에 명시적 FR은 없으나, 원칙 2 "비동기 작업은 오류 경로를 처리" 충족을 위한 안전망) |

## 2. Data DTO·모델 (`DataLearningProject`)

DTO는 서버·GitHub API 응답의 wire 형식을 1:1로 표현한다(Codable). Domain 모델로의 변환은
이 계획의 범위 밖(Composition Adapter, research.md 결정 6)이므로 DTO에 변환 메서드를
추가하지 않는다.

### GitHubRepositoryResponseDTO

GitHub 공개 API `GET /repos/{owner}/{repo}` 응답의 부분 표현(등록 미리보기에 필요한
최소 필드만, data-model.md 006 "참고용" 서술과 동일).

| 필드(camelCase 프로퍼티) | wire 키(`CodingKeys`) | 타입 |
|---|---|---|
| `fullName` | `full_name` | `String` |
| `htmlURL` | `html_url` | `String` |
| `ownerAvatarURL` | `owner.avatar_url`(nested) | `String?` |
| `starCount` | `stargazers_count` | `Int` |
| `language` | `language` | `String?` |
| `topics` | `topics` | `[String]` |

### RegisterProjectRequestDTO / QuizLevelDTO

`POST /api/v1/projects` 요청 본문(FR-005). `RegisterProjectRequest` 스키마와 1:1.

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `githubRepoUrl` | `String` | 예 | |
| `quizLevel` | `QuizLevelDTO?` | 아니오(서버 스키마상), 이 기능은 항상 값을 채워 보냄(spec.md 가정) | `L1`\|`L2`\|`L3` |

`QuizLevelDTO: String, Codable`은 `L1`/`L2`/`L3` raw value를 그대로 가진다.

### RegisterProjectResponseDTO / QuizGenerationStatusDTO

`POST /api/v1/projects` 200 응답 `data`(FR-006). `RegisterProjectResponse` 스키마와
1:1 — **`quizLevel` 필드가 없다**(research.md 결정 7).

| 필드 | 타입 |
|---|---|
| `projectId` | `String` |
| `status` | `QuizGenerationStatusDTO` |

`QuizGenerationStatusDTO: String, Codable`은 `READY`/`ANALYZED`/`ANCHORED`/`REJECTED`/
`FAILED`/`COMPLETED` raw value를 그대로 가진다.

### ProjectListResponseDTO / ProjectListItemDTO

`GET /api/v1/projects` 200 응답 `data`(FR-011~013).

`ProjectListResponseDTO`: `items: [ProjectListItemDTO]`, `hasNext: Bool`.

`ProjectListItemDTO` 필드: `projectId`, `repositoryName`, `repositoryImageUrl`,
`techStack: [String]`, `currentSetLabel`, `currentSetTitle`, `nextSetId`, `nextQuestionId`,
`overallProgressPercent: Int` — 전부 서버 예시 응답과 동일한 키.

### ProjectDetailResponseDTO / ProjectSetSummaryDTO

`GET /api/v1/projects/{projectId}` 200 응답 `data`(FR-016~017).

`ProjectDetailResponseDTO` 필드: `projectId`, `repositoryUrl`, `repositoryName`,
`repositoryImageUrl`, `starCount: Int`, `techStack: [String]`, `overallProgressPercent: Int`,
`nextQuestionId: String?`, `sets: [ProjectSetSummaryDTO]`.

`ProjectSetSummaryDTO` 필드: `setId`, `label`, `title`, `problemCount: Int`,
`completedCount: Int`.

### DataExternalRepositoryError

`ExternalRepositoryRemote` 실패를 나타내는 Data 오류. `CaseIterable, Equatable, Error,
Sendable` 채택. `invalidURLFormat`에 대응하는 케이스는 없다 — URL 파싱은 Domain이
`ExternalRepositoryRemote` 호출 전에 이미 완료한다(research.md 결정 4).

| 케이스 | 의미 |
|---|---|
| `offline` | 네트워크 연결 불가 |
| `other` | GitHub 404(Private·존재하지 않음)·403(rate limit)·5xx 등 나머지 |

### DataLearningProjectError

`LearningProjectRemote` 실패를 나타내는 Data 오류. `CaseIterable, Equatable, Error,
Sendable` 채택. 서버 오류 코드(`COMMON-001`, `COMMON-002`, `PROJECT-001`, `COMMON-005`)와
1:1 대응한다.

| 케이스 | 서버 코드 |
|---|---|
| `invalidRequest` | `COMMON-001` |
| `unauthorized` | `COMMON-002` |
| `notFound` | `PROJECT-001` |
| `serverError` | `COMMON-005` |
| `unexpected` | 그 밖의 미분류 실패(디코딩 실패, 알 수 없는 상태 코드 등) |

## 3. 관계 요약

```text
ExternalRepository (Domain)  ──입력──▶  CreateLearningProject UseCase
LearningProjectRegistration  ──projectId──▶  FetchLearningProjectDetail 조회 키
LearningProjectSummary.nextSetId/nextQuestionId  ──이어 풀기 진입점(참고, 소비는 후속 스펙)
LearningProjectDetail.nextSet  ──sets[]에서 계산(FR-019)
```

`LearningProjectRegistration`·`LearningProjectSummary`·`LearningProjectDetail`은 서로
필드가 겹치지 않는 별도 타입이며 상속·프로토콜 공유를 강제하지 않는다(research.md 결정 8).
