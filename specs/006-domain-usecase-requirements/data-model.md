# 데이터 모델: Git-It 학습 도메인 UseCase 요구사항

**날짜**: 2026-08-19 | **명세**: [spec.md](./spec.md) | **조사**: [research.md](./research.md)

이 문서는 spec.md `핵심 엔터티`를 필드 단위로 확장한 **개념 모델**이다(research.md §2).
필드명은 `Git-It-server-scheme.json`의 서버 응답 필드명을 정본으로 보존했으며, Swift
타입(`struct`/`enum`/접근 제어자)은 이 문서가 결정하지 않는다 — 후속 UseCase별 구현
계획이 각 패키지(Domain/Data)의 명명 규칙에 따라 정한다.

## ExternalRepository

`FetchExternalRepository`가 GitHub 공개 API로 확인해 반환하는, 아직 Git-It 서버에
등록되지 않은 외부 Repository 정보. (FR-001~004)

| 필드 | 타입/형식 | 설명 |
|---|---|---|
| canonical Repository URL | string | `CreateLearningProject`의 `githubRepoUrl` 입력으로 그대로 전달된다 |
| 소유자·저장소 이름 | string | GitHub URL에서 식별 |
| 메타데이터(이름, 이미지 URL, star 수, 기술 스택 등) | — | `LearningProject` 상세 응답과 동일한 항목 구성(참고용, 등록 후 서버가 다시 확정) |

**관계**: 등록(`CreateLearningProject`) 요청의 입력 재료. 등록 자체를 수행하거나
영속화하지 않는다(FR-002 제외 책임).

## LearningProject

사용자가 학습 중인 프로젝트. (FR-005~021)

| 필드 | 타입/형식 | 설명 |
|---|---|---|
| `projectId` | string | 사용자별로 소유되는 식별자. 사용자당 Repository 하나에 하나만 존재(FR-007) |
| `repositoryUrl` | string | GitHub 링크 (상세 조회에만 포함) |
| `repositoryName` | string | 저장소 이름 |
| `repositoryImageUrl` | string | 저장소 아바타/이미지 |
| `starCount` | int32 | GitHub star 수 (상세 조회에만 포함) |
| `techStack` | string[] | 기술 스택 목록 |
| `quizLevel` | `QuizLevel` | 최초 등록 시점에 고정됨. 재등록으로 변경되지 않음(FR-007). **목록·상세 응답에는 노출되지 않는다** — 필요하면 `FetchLearningSet` 응답의 `level`로만 확인 가능(알려진 서버 API 제약, 예외·경계 사례 참고) |
| `status` | `QuizGenerationStatus` | 등록 응답(`CreateLearningProject`)에만 포함. 목록·상세 응답에는 없음 — `COMPLETED`가 아니면 애초에 목록·상세에 노출되지 않는 방식으로 간접 표현됨(FR-013, FR-018) |
| `overallProgressPercent` | int32 | 전체 진행률 |
| `currentSetLabel`, `currentSetTitle` | string | 목록 조회 전용 요약 |
| `nextSetId`, `nextQuestionId` | string | 목록 조회는 서버가 둘 다 계산해 반환(FR-012). 상세 조회는 `nextQuestionId`만 있어 `sets[]`로 다음 세트를 계산해야 함(FR-019) |
| `sets` | `LearningSet 요약[]` | 상세 조회 전용. 각 항목: `setId`, `label`, `title`, `problemCount`, `completedCount` |

**식별/유일성**: `projectId`는 (사용자, Repository) 조합당 하나. 문제 콘텐츠는
(Repository, `quizLevel`) 조합 단위로 여러 사용자 사이에 재사용되지만, `LearningProject`
레코드 자체는 사용자 간 공유되지 않는다.

**상태 전이**: 삭제(`DeleteLearningProject`)는 소프트 삭제이며, 동일 사용자가 같은
Repository를 재등록하면 이전 `projectId`·`quizLevel`·진행 상태 그대로 복원된다(FR-008,
FR-021).

## QuizGenerationStatus

`LearningProject`의 문제 생성 진행 상태. (FR-006, FR-013, FR-017~019)

| 값 | 의미 |
|---|---|
| `READY` | 등록 직후 |
| `ANALYZED` | 저장소 분석 완료 |
| `ANCHORED` | 문제 근거(Source) 확정 |
| `REJECTED` | 문제를 낼 수 없다고 판정 |
| `FAILED` | 생성 실패 |
| `COMPLETED` | 학습 가능 — 이 상태여야만 목록·상세 조회에 노출되고 `FetchLearningSet`을 호출할 수 있다 |

`COMPLETED` 이전 상태를 사용자에게 보여주는 흐름은 이 10개 UseCase의 범위 밖이다(spec.md
`가정`).

## QuizLevel

사용자가 선택하는 문제 난이도. (FR-005, FR-007)

| 값 | 의미 |
|---|---|
| `L1` \| `L2` \| `L3` | 문제 깊이만 구분, 직급과 무관 |

문제 콘텐츠 공유·재생성의 단위 경계이지만, 한 사용자의 한 Repository에는 하나의
`QuizLevel`만 유효하다(`LearningProject.quizLevel` 참고).

## LearningSet

프로젝트에 걸린 문제 묶음. (FR-022~026)

| 필드 | 타입/형식 | 설명 |
|---|---|---|
| `setId` | string | 세트 식별자. `GET /api/v1/projects/{projectId}/sets/{setId}`의 필수 조회 키 — 문제 풀이는 오직 이 경로로만 가능하다(tacit-knowledge.md TK-20260819-001) |
| `label` | string | 예: "Set 1" |
| `title` | string | 세트 제목 |
| `description` | string | 세트 설명 |
| `orientation` | string | 풀기 전 안내(문제로 낼 가치가 없는 사실) |
| `level` | `QuizLevel` | 이 세트가 속한 난이도 — **프로젝트의 `quizLevel`을 확인할 수 있는 유일한 응답 경로** |
| `questions` | `Question[]` | 생성 순서 그대로, 필터링 없음(FR-023) |

## Question

세트에 속한 개별 문제. (FR-023~035)

| 필드 | 타입/형식 | 설명 |
|---|---|---|
| `questionId` | string | 답변 제출·북마크의 조회 키 |
| `format` | `MULTIPLE_CHOICE` \| `ESSAY` | 제출 대상 UseCase(`SubmitChoiceAnswer`/`SubmitEssayAnswer`)와 `choices` 유무를 결정 |
| `text` | string | 문제 본문 |
| `choices` | string[] | 서술형이면 빈 배열 |
| `sources` | `Source[]` | 인용한 코드 위치 |
| `myAnswer` | `MyAnswer?` | 없으면 미답변(이어 풀 지점), 세트 전원 존재 시 재풀이 가능 상태(FR-024) |

### Source (Question의 부속 타입)

| 필드 | 타입/형식 | 설명 |
|---|---|---|
| `file` | string | 레포 루트 기준 상대 경로 |
| `startLine`, `endLine` | int32 | 인용 범위 |
| `symbol` | string | 식별자 |
| `summary` | string? | 설명(없으면 null) |
| `url` | string | 커밋 고정 GitHub 링크 |

## MyAnswer

사용자가 이미 제출한 답변 상태(세트 조회 응답에 포함). (FR-024)

| 필드 | 타입/형식 | 설명 |
|---|---|---|
| `selectedIndex` | int32? | 객관식만, 서술형은 null |
| `text` | string? | 서술형만, 객관식은 null |
| `correct` | bool? | 서술형은 항상 null(자가채점이므로) |
| `answeredAt` | date-time | 제출 시각 |

## Rubric

서술형 답변 자가채점 기준(`SubmitEssayAnswer` 응답 전용). (FR-032~034)

| 필드 | 타입/형식 | 설명 |
|---|---|---|
| `criteria` | `RubricCriterion[]` | 판단 기준별 배점. 합이 만점 |
| `keyPoints` | string[] | 답안에 들어가야 할 핵심 |
| `fullMarkExample` | string | 만점 답안 예시 |
| `partialExample` | string | 부분 점수 답안 예시 |
| `zeroExample` | string | 0점 답안 예시 |

### RubricCriterion (Rubric의 부속 타입)

| 필드 | 타입/형식 | 설명 |
|---|---|---|
| `text` | string | 정답 나열이 아닌 판단 기준 |
| `points` | int32 | 이 기준의 배점 |

## BookmarkedQuestion

사용자가 북마크한 문제(`FetchBookmarkedQuestions` 응답 항목). (FR-039~042)

| 필드 | 타입/형식 | 설명 |
|---|---|---|
| `projectId`, `projectName` | string | 소속 프로젝트 |
| `setId` | string | 풀이 진입에 필수(tacit-knowledge.md TK-20260819-001) |
| `setLabel` | string | 예: "Set 1" |
| `problemNumber` | int32 | 세트 내 문제 번호(1부터) |
| `questionId`, `question` | string | 문제 식별자·본문 |

**부속 응답**: `availableProjects`(`AvailableProjectResponse[]` — `projectId`,
`projectName`)는 `projectId` 필터와 무관하게 북마크가 있는 프로젝트 전체 목록(FR-041).
