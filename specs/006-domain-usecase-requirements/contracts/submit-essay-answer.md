# 계약: SubmitEssayAnswer

**날짜**: 2026-08-19 | **명세**: [spec.md](../spec.md) FR-032~036 |
**데이터 모델**: [data-model.md](../data-model.md) `Question`, `Rubric`, `MyAnswer` |

서술형 문제에 대한 답변을 제출하고 자가채점용 해설·기준을 받는다.

## 엔드포인트

`POST /api/v1/projects/{projectId}/questions/{questionId}/answers/essay` (인증 필요: Bearer)

## 요청

| 필드 | 위치 | 타입 | 설명 |
|---|---|---|---|
| `projectId`, `questionId` | path | string | FR-032 |
| `text` | body | string(최대 2000자) | 서술형 답안(FR-032) |

## 성공 응답 (200)

`SubmitEssayAnswerResponse`: `questionId`, `explanation`, `rubric`(`Rubric` — 기준별
배점, 핵심 포인트, 만점·부분점수·0점 예시)(FR-033).

**서버는 채점하지 않는다**(FR-034) — 학습자가 `rubric`을 보고 스스로 채점한다. 같은
문제를 다시 제출하면 이전 답변이 누적되지 않고 최신 제출로 덮어써진다(FR-035). 이
응답에는 진행률 필드가 없다 — 최신 진행률은 `FetchLearningProjectDetail`/
`FetchLearningProjects`를 재호출해야 한다(FR-036).

## 오류

| 상태 | 코드 | 조건 |
|---|---|---|
| 400 | `COMMON-001` | `text` 누락(비어 있음), 또는 객관식 문제 id로 호출(FR-035) |
| 401 | `COMMON-002` | 인증되지 않은 요청 |
| 404 | `PROJECT-001` \| `QUIZ-005` | 내 프로젝트가 아니거나 문제를 찾을 수 없음 |
| 500 | `COMMON-005` | 서버 내부 오류 |

## 제외 책임

사용자 자가채점 판단, 입력 UI 상태 관리, 답변의 로컬 영속화, 화면 내 글자 수 표시
(도메인 문서 `제외 책임`).
