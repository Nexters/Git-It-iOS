# 계약: FetchLearningSet

**날짜**: 2026-08-19 | **명세**: [spec.md](../spec.md) FR-023~027 |
**데이터 모델**: [data-model.md](../data-model.md) `LearningSet`, `Question`, `MyAnswer` |

특정 학습 세트의 문제와 현재 풀이 상태를 조회한다.

## 엔드포인트

`GET /api/v1/projects/{projectId}/sets/{setId}` (인증 필요: Bearer)

## 요청

| 파라미터 | 위치 | 타입 | 설명 |
|---|---|---|---|
| `projectId` | path | string | FR-023 |
| `setId` | path | string | FR-023 |

## 성공 응답 (200)

`LearningSetResponse`: `setId`, `title`, `description`, `orientation`, `level`,
`questions[]`(생성 순서, 필터링 없음 — FR-024).

각 `Question`은 `myAnswer`(있으면 `selectedIndex`/`text`/`correct`/`answeredAt`, 없으면
null)를 포함한다. `myAnswer`가 없는 첫 문제가 이어 풀 지점이며, 전원 존재하면 재풀이
가능 상태다(FR-025). **정답·해설·채점 기준은 포함되지 않는다**(FR-026) — 답변 제출
응답에서만 제공된다.

## 오류

| 상태 | 코드 | 조건 |
|---|---|---|
| 401 | `COMMON-002` | 인증되지 않은 요청 |
| 404 | `PROJECT-001` | 내 프로젝트가 아님(FR-027) |
| 404 | `QUIZ-006` | 그 프로젝트 저장소에 없는 세트, 또는 문제 생성이 아직 끝나지 않음(FR-027) |
| 500 | `COMMON-005` | 서버 내부 오류 |

## 제외 책임

풀이 진행 상태의 로컬 저장, 이어 풀 위치의 별도 영속화, 문제 답변 제출, 화면 내 문제
이동 상태 관리(도메인 문서 `제외 책임`).
