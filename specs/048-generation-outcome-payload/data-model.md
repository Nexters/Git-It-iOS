# 데이터 모델: 생성 결과 원격 알림 payload 인식과 로컬 결과 알림 제거

**기능**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md)

## 1. 생성 결과 원격 알림 payload (서버 소유, 변경 없음)

알림 원격 메시지의 `userInfo`는 전달 계층에서 문자열 사전(`[String: String]`)으로 바뀌어 Data에
도착한다. 해석 규칙은 [contracts/generation-outcome-payload.md](./contracts/generation-outcome-payload.md)를 따른다.

| 키 | 필수 | 값 | 의미 |
|---|---|---|---|
| `projectId` | 예 | 비어 있지 않은 문자열 | 결과가 속한 프로젝트 식별자. 등록 응답의 `projectId`와 같은 값 |
| `type` | 서버 현행 형식 | `QUIZ_READY` \| `QUIZ_REJECTED` | 생성 완료 \| 생성 불가(실패) |
| `status` | 호환 형식 | `completed` \| `failed` | 생성 완료 \| 생성 실패. 서버가 보낸 관찰은 없음 |
| `aps`, `gcm.message_id`, `google.c.*` | 아니오 | 전달 계층 값 | 해석하지 않음 |

## 2. `QuizGenerationOutcomeDTO` (Data, 공개 형태 유지)

| 필드 | 타입 | 규칙 |
|---|---|---|
| `projectID` | `String` | payload `projectId`. 빈 문자열이면 DTO를 만들지 않는다(신규) |
| `status` | `RawStatus` (`completed`, `failed`) | `type`을 먼저 인식하고, 인식하지 못하면 `status`로 정한다(R1) |
| `deliveredAt` | `Date` | 전달 시각. 변경 없음 |

`RawStatus`의 이름과 케이스는 유지한다(R4). 서버 `type` 값과의 대응은 DTO 내부에만 둔다.

## 3. 생성 기록 저장 (Data, 결과 대기 대기열만 제거)

| 저장 키 | 이전 | 이후 |
|---|---|---|
| `generationState` | 생성 기록 목록 | 변경 없음 |
| `pendingGenerationReminders` | 결과 대기 프로젝트 목록(최대 32) | 코드에서 읽지도 쓰지도 않는다. 이미 저장된 값은 무시한다(R6) |

네임스페이스 `com.nexters.hytime.gitit.sharedSession`은 유지한다.

## 4. Domain 모델 변화

| 모델·계약 | 변화 |
|---|---|
| `GenerationReminder`, `GenerationReminder.Kind` | 삭제 |
| `GenerationReminderScheduler` | 삭제 |
| `PendingGenerationRepository` | `enqueueReminder(projectID:)`, `drainReminderProjectIDs()` 삭제. 나머지 유지 |
| `GenerationWaitPolicy` | `reminderValidity`, `isReminderValid(_:now:)` 삭제. `retentionLimit`(3600초), `expiryDate(for:)`, `isExpired(_:now:)` 유지 |
| `GenerationOutcome`, `GenerationRecord`, `GenerationState`, `ProjectGenerationState` | 변경 없음 |

### 생성 기록 상태 전이 (변경 없음)

```text
(요청) ──beginGeneration──▶ inProgress ──결과 도착: completed──▶ completed(ready)
                                  │
                                  ├──결과 도착: failed─────────▶ failed
                                  └──보관 기한(3600초) 경과─────▶ 기록 삭제
```

이전에는 `completed`·`failed`로 넘어간 뒤 결과 대기 등록이 있고, 권한이 있으며, 300초 안이면 로컬 알림을
예약했다. 이 부수 효과가 없어진다.

## 5. 알림 권한 (Data 이름 변경, 값 유지)

| 이전 | 이후 | 값 |
|---|---|---|
| `ReminderAuthorizationSetting` | `NotificationPermissionSetting` | `notDetermined`, `authorized`, `denied` |
| `ReminderAuthorizationStatus` | `NotificationPermissionRequestResult` | `authorized`, `declined`, `previouslyDenied` |

Domain의 `NotificationAuthorizationStatus`(`notDetermined`, `authorized`, `denied`)와 Composition의 대응은
그대로다. 계약은 [contracts/notification-permission.md](./contracts/notification-permission.md)를 따른다.
