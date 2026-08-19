# 계약: FetchLearningProjectDetail

**날짜**: 2026-08-19 | **명세**: [spec.md](../spec.md) FR-016~019 |
**데이터 모델**: [data-model.md](../data-model.md) `LearningProject`, `LearningSet` 요약 |
**도메인 문서**: [fetch-learning-project-detail.md](../../../sources/docs/git-it-domain-usecases/fetch-learning-project-detail.md)

특정 학습 프로젝트의 상세 정보를 조회한다.

## 엔드포인트

`GET /api/v1/projects/{projectId}` (인증 필요: Bearer)

## 요청

| 파라미터 | 위치 | 타입 | 설명 |
|---|---|---|---|
| `projectId` | path | string | 조회할 프로젝트 id(FR-016) |

## 성공 응답 (200)

| 필드 | 타입 | 설명 |
|---|---|---|
| `projectId`, `repositoryUrl`, `repositoryName`, `repositoryImageUrl`, `starCount`, `techStack` | — | Repository 기본 정보(FR-017) |
| `overallProgressPercent` | int32 | 전체 진행률 |
| `nextQuestionId` | string? | 다음 문제 id(있는 경우) — **`nextSetId`는 이 응답에 없다** |
| `sets[]` | — | `setId`, `label`, `title`, `problemCount`, `completedCount` |

## 다음 세트 판단 규칙 (FR-019)

상세 응답에는 `nextSetId`가 없으므로, `sets[]`에서 `completedCount < problemCount`인
첫 세트를 다음에 풀 세트로 판단한다. 모든 세트를 완료했으면 `nextQuestionId`는 재풀이
대상 세트의 첫 문제를 가리키는 것으로 처리한다.

## 오류

| 상태 | 코드 | 조건 |
|---|---|---|
| 401 | `COMMON-002` | 인증되지 않은 요청 |
| 404 | `PROJECT-001` | 존재하지 않음, 본인 소유 아님, 삭제됨, 또는 `QuizGenerationStatus`가 `COMPLETED`가 아님(FR-017·FR-018) — 사유를 구분하지 않고 동일하게 404 |
| 500 | `COMMON-005` | 서버 내부 오류 |

## 제외 책임

프로젝트 생성 완료 감지, 세트 문제 상세 조회, 상세 데이터 로컬 캐싱, 화면 조합과
Navigation(도메인 문서 `제외 책임`).
