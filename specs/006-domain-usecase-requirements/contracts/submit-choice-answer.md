# 계약: SubmitChoiceAnswer

**날짜**: 2026-08-19 | **명세**: [spec.md](../spec.md) FR-028~031, FR-036 |
**데이터 모델**: [data-model.md](../data-model.md) `Question`, `MyAnswer` |

객관식 문제에 대한 답변을 제출하고 채점 결과를 받는다.

## 엔드포인트

`POST /api/v1/projects/{projectId}/questions/{questionId}/answers/choice` (인증 필요: Bearer)

## 요청

| 필드 | 위치 | 타입 | 설명 |
|---|---|---|---|
| `projectId`, `questionId` | path | string | FR-028 |
| `selectedIndex` | body | int32 | 0부터 시작하는 선택지 번호(FR-028) |

## 성공 응답 (200)

`SubmitChoiceAnswerResponse`: `questionId`, `correct`(bool), `answerIndex`(정답 index),
`explanation`(FR-029).

같은 문제를 다시 제출하면 이전 답변이 누적되지 않고 최신 제출로 덮어써지며, 세트
재조회 시 최신 상태가 사용된다(FR-030). **이 응답에는 진행률 필드가 없다** — 최신
진행률은 `FetchLearningProjectDetail`/`FetchLearningProjects`를 재호출해야 한다(FR-036).

## 오류

| 상태 | 코드 | 조건 |
|---|---|---|
| 400 | `COMMON-001` | 선택지 범위를 벗어난 index, 또는 서술형 문제 id로 호출(FR-031) |
| 401 | `COMMON-002` | 인증되지 않은 요청 |
| 404 | `PROJECT-001` \| `QUIZ-005` | 내 프로젝트가 아니거나 문제를 찾을 수 없음 |
| 500 | `COMMON-005` | 서버 내부 오류 |

## 제외 책임

선택지 UI 상태 관리, 정답 표시 UI, 재시도 UI, 답변의 로컬 영속화(도메인 문서
`제외 책임`).
