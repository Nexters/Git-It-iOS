# 계약: 생성 결과 원격 알림 payload 인식

**소유**: Data `QuizGenerationOutcomeDTO.init?(rawPayload:deliveredAt:)`
**소비**: `PushQuizGenerationOutcomeSource.ingest`(백그라운드 수신·알림 표시·알림 탭),
`GenerationOutcomeRepositoryAdapter.deliveredOutcomes`(알림 센터 읽기)

## 판정 순서

1. `projectId`가 없거나 `""`이면 → 인식하지 않음(`nil`)
2. `type == "QUIZ_READY"` → 완료(`completed`)
3. `type == "QUIZ_REJECTED"` → 실패(`failed`)
4. `status == "completed"` → 완료
5. `status == "failed"` → 실패
6. 그 밖 → 인식하지 않음(`nil`)

값은 정확히 일치할 때만 인정한다(대소문자·밑줄 포함). 다른 키는 판정에 영향을 주지 않는다.

## 판정표

| # | 입력 payload(판정에 쓰는 키만) | 결과 |
|---|---|---|
| 1 | `projectId: "6abbb1b4f55054fd8fbb4ca3"`, `type: "QUIZ_READY"` + 전달 계층 키 | 완료 |
| 2 | `projectId: "6abbacabf55054fd8fbb479d"`, `type: "QUIZ_REJECTED"` + 전달 계층 키 | 실패 |
| 3 | `projectId: "6abbaf3ef55054fd8fbb4a78"`, `type: "QUIZ_REJECTED"` + 전달 계층 키 | 실패 |
| 4 | `projectId: "p"`, `status: "completed"` | 완료 |
| 5 | `projectId: "p"`, `status: "failed"` | 실패 |
| 6 | `projectId: "p"`, `type: "QUIZ_REJECTED"`, `status: "completed"` | 실패(`type` 우선) |
| 7 | `projectId: "p"`, `type: "QUIZ_UNKNOWN"`, `status: "completed"` | 완료(`type` 미인식 → `status`) |
| 8 | `projectId: "p"`, `type: "quiz_ready"` | 인식하지 않음 |
| 9 | `projectId: "p"`, `type: "QUIZ_FAILED"` | 인식하지 않음 |
| 10 | `type: "QUIZ_READY"` (`projectId` 없음) | 인식하지 않음 |
| 11 | `projectId: ""`, `type: "QUIZ_READY"` | 인식하지 않음 |
| 12 | `projectId: "p"` (결과 키 없음) | 인식하지 않음 |

1~3은 2026-09-29 실기기 관찰 원문이다. 테스트는 전달 계층 키(`aps`, `gcm.message_id`,
`google.c.sender.id`, `google.c.fid`, `google.c.a.e`)를 포함한 원문 형태로 검증한다.

## 인식 이후 (변경 없음)

인식한 결과는 기존 규칙으로 반영한다(FR-006).
- 기록에 있는 프로젝트면 완료·실패로 전이한다.
- 기록에 없으면 보존했다가 재시도한다.
- 같은 결과가 중복 도착하면 한 번만 반영한다.
- 포그라운드면 목록 갱신 계기로 쓴다.

인식하지 못한 payload는 `ingest` 경로에서 "생성 결과 payload 파싱 실패" debug 로그를 남긴다(R3).
