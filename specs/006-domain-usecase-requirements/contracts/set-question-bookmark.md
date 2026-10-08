# 계약: SetQuestionBookmark

**날짜**: 2026-08-19 | **명세**: [spec.md](../spec.md) FR-037~039 |
**데이터 모델**: [data-model.md](../data-model.md) `Question` |

문제의 북마크 상태를 사용자가 원하는 최종 상태로 설정한다.

## 엔드포인트

`POST /api/v1/projects/{projectId}/questions/{questionId}/bookmark` (인증 필요: Bearer)

## 요청

| 필드 | 위치 | 타입 | 설명 |
|---|---|---|---|
| `projectId`, `questionId` | path | string | FR-037 |
| `bookmarked` | body | bool | 원하는 최종 상태. **toggle이 아니다** — 현재 UI 상태로부터 추론하지 않고 항상 명시적으로 전송(FR-038) |

## 성공 응답 (200)

`{ "bookmarked": bool }` — 설정된 최종 상태를 그대로 반환.

## 오류

| 상태 | 코드 | 조건 |
|---|---|---|
| 400 | `COMMON-001` | `bookmarked` 값 누락(FR-039) |
| 401 | `COMMON-002` | 인증되지 않은 요청 |
| 404 | `PROJECT-001` \| `QUIZ-005` | 내 프로젝트가 아니거나 문제를 찾을 수 없음(FR-039) |
| 500 | `COMMON-005` | 서버 내부 오류 |

## 제외 책임

Toggle 상태 추론, 북마크 목록 조회, 북마크 상태의 로컬 영속화, 버튼 애니메이션과 UI
상태 관리(도메인 문서 `제외 책임`).
