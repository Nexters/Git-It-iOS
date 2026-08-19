# 계약: CreateLearningProject

**날짜**: 2026-08-19 | **명세**: [spec.md](../spec.md) FR-005~010 |
**데이터 모델**: [data-model.md](../data-model.md) `LearningProject`, `QuizGenerationStatus`, `QuizLevel` |
**도메인 문서**: [create-learning-project.md](../../../sources/docs/git-it-domain-usecases/create-learning-project.md)

확인된 외부 Repository를 학습 프로젝트로 등록한다.

## 엔드포인트

`POST /api/v1/projects` (인증 필요: Bearer)

## 요청

`RegisterProjectRequest`:

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `githubRepoUrl` | string | 예 | canonical Repository URL(FR-005) |
| `quizLevel` | `L1`\|`L2`\|`L3` | 서버 스키마상 아님(클라이언트는 항상 채워 보냄, spec.md 가정) | 사용자가 선택한 난이도. **최초 등록 시점에만 유효** — 이미 프로젝트가 있으면 재전송해도 무시된다(FR-007) |

## 성공 응답 (200)

`RegisterProjectResponse`:

| 필드 | 타입 | 설명 |
|---|---|---|
| `projectId` | string | 등록된(또는 기존) 프로젝트 id |
| `status` | `QuizGenerationStatus` | `READY`\|`ANALYZED`\|`ANCHORED`\|`REJECTED`\|`FAILED`\|`COMPLETED`. `COMPLETED`가 아니면 아직 풀 문제 없음(FR-006) |

## 재등록·다중 사용자 규칙 (FR-007, FR-008)

| 시나리오 | 결과 |
|---|---|
| 동일 사용자가 같은 Repository를 (같은 또는 다른 `quizLevel`로) 다시 등록 | 새 프로젝트 생성 안 함. 기존 `projectId`·`quizLevel`·`status` 그대로 반환. **사용자당 Repository 하나에는 프로젝트가 하나만 존재** |
| 동일 사용자가 삭제(`DeleteLearningProject`)했던 Repository를 다시 등록 | 삭제됐던 프로젝트를 복원 — 이전 `projectId`·`quizLevel`과 진행 상태(진행률, `myAnswer`) 그대로 반환 |
| 다른 사용자가 이미 등록된 (Repository, `quizLevel`) 조합을 처음 등록 | 문제 콘텐츠는 재사용하되, 그 사용자만의 새 `projectId` 발급 |
| 다른 사용자가 같은 Repository를 아직 생성되지 않은 `quizLevel`로 등록 | 그 레벨의 문제 생성이 새로 트리거됨 |

## 오류

| 상태 | 코드 | 조건 |
|---|---|---|
| 400 | `COMMON-001` | `githubRepoUrl` 누락, GitHub에 없는 저장소, 문제를 낼 수 없다고 판정된 저장소(FR-009) |
| 401 | `COMMON-002` | 인증되지 않은 요청 |
| 500 | `COMMON-005` | 서버 내부 오류 |

## 제외 책임

생성 완료 대기, FCM 이벤트 수신, Polling/Timer 관리, Timeout 감시, 재시도 자체, 생성
요청 정보의 로컬 영속화(FR-010).
