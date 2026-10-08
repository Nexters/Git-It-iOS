# 계약: FetchLearningProjects

**날짜**: 2026-08-19 | **명세**: [spec.md](../spec.md) FR-011~015 |
**데이터 모델**: [data-model.md](../data-model.md) `LearningProject` |

내가 학습 중인 프로젝트 목록을 페이지 단위로 조회한다.

## 엔드포인트

`GET /api/v1/projects` (인증 필요: Bearer)

## 요청

| 파라미터 | 위치 | 타입 | 기본값 | 설명 |
|---|---|---|---|---|
| `page` | query | int32 | 0 | 0부터 시작(FR-011) |
| `size` | query | int32 | 10 | 페이지 크기(FR-011) |

## 성공 응답 (200)

`items[]`(생성 순서, 오래된 순) 각 항목:

| 필드 | 타입 | 설명 |
|---|---|---|
| `projectId` | string | |
| `repositoryName`, `repositoryImageUrl`, `techStack` | — | |
| `currentSetLabel`, `currentSetTitle` | string | 현재 세트 요약 |
| `nextSetId`, `nextQuestionId` | string | **서버가 직접 계산해 반환** — 이어 풀기 진입점으로 그대로 사용(FR-012) |
| `overallProgressPercent` | int32 | |

+ `hasNext`(bool, FR-013): 다음 페이지 존재 여부.

**노출 규칙(FR-014)**: `QuizGenerationStatus`가 `COMPLETED`가 아닌 프로젝트는 이 목록에
포함되지 않는다 — `status` 필드 자체가 이 응답에 없다(data-model.md 참고).

## 오류

| 상태 | 코드 | 조건 |
|---|---|---|
| 401 | `COMMON-002` | 인증되지 않은 요청(FR-015) |
| 500 | `COMMON-005` | 서버 내부 오류 |

## 제외 책임

목록 UI 상태 관리, 무한 스크롤 이벤트 감지, 프로젝트 목록 로컬 캐싱, 프로젝트 생성 상태
감시(도메인 문서 `제외 책임`).
