# 계약: FetchBookmarkedQuestions

**날짜**: 2026-08-19 | **명세**: [spec.md](../spec.md) FR-040~042 |
**데이터 모델**: [data-model.md](../data-model.md) `BookmarkedQuestion` |
**도메인 문서**: [fetch-bookmarked-questions.md](../../../sources/docs/git-it-domain-usecases/fetch-bookmarked-questions.md)

사용자가 북마크한 문제 목록을 조회한다.

## 엔드포인트

`GET /api/v1/projects/bookmarks` (인증 필요: Bearer)

## 요청

| 파라미터 | 위치 | 타입 | 설명 |
|---|---|---|---|
| `projectId` | query | string(선택) | 생략 시 전체 프로젝트(FR-040) |

## 성공 응답 (200)

`BookmarkedQuestionListResponse`:

| 필드 | 타입 | 설명 |
|---|---|---|
| `totalCount` | int32 | 필터 적용 후 기준 총 개수 |
| `bookmarks[]` | `BookmarkedQuestion[]` | `projectId`, `projectName`, `setId`, `setLabel`, `problemNumber`, `questionId`, `question`. **`setId`는 필수** — 문제 풀이는 오직 `GET /api/v1/projects/{projectId}/sets/{setId}`로만 가능하다(FR-041) |
| `availableProjects[]` | `AvailableProjectResponse[]` | `projectId` 필터와 무관하게 북마크가 있는 프로젝트 전체(필터 UI용, FR-042) |

## 오류

| 상태 | 코드 | 조건 |
|---|---|---|
| 401 | `COMMON-002` | 인증되지 않은 요청 |
| 500 | `COMMON-005` | 서버 내부 오류 |

## 제외 책임

개별 문제의 북마크 상태 변경, 북마크 목록 로컬 캐싱, 프로젝트별 필터 UI 상태 관리
(도메인 문서 `제외 책임`).
