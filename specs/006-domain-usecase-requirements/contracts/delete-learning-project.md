# 계약: DeleteLearningProject

**날짜**: 2026-08-19 | **명세**: [spec.md](../spec.md) FR-020~022 |
**데이터 모델**: [data-model.md](../data-model.md) `LearningProject` |
**도메인 문서**: [delete-learning-project.md](../../../sources/docs/git-it-domain-usecases/delete-learning-project.md)

더 이상 학습하지 않을 프로젝트를 삭제한다.

## 엔드포인트

`DELETE /api/v1/projects/{projectId}` (인증 필요: Bearer)

## 요청

| 파라미터 | 위치 | 타입 | 설명 |
|---|---|---|---|
| `projectId` | path | string | 삭제할 프로젝트 id(FR-020) |

## 성공 응답 (200)

`data: null` — 별도 반환 필드 없음.

삭제 후 시스템은 이 프로젝트를 목록·상세 결과에서 제외해야 한다(FR-021). **단, 동일
사용자가 같은 Repository를 재등록하면 복원된다** — 삭제는 재등록 경로를 막지 않는다
(`create-learning-project.md` 계약 참고).

## 오류

| 상태 | 코드 | 조건 |
|---|---|---|
| 401 | `COMMON-002` | 인증되지 않은 요청 |
| 404 | `PROJECT-001` | 존재하지 않음, 본인 소유 아님, 이미 삭제됨 — 사유를 구분하지 않고 동일하게 404(FR-022) |
| 500 | `COMMON-005` | 서버 내부 오류 |

## 제외 책임

삭제 확인 UI, 화면 이동, 클라이언트 로컬 데이터 정리, 서버 내부 종속 데이터 삭제 방식
결정(도메인 문서 `제외 책임`).
