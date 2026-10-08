# 빠른 검증: 생성 결과 원격 알림 payload 인식과 로컬 결과 알림 제거

**기능**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md)

## 1. 자동 검증

```sh
project_build_runner=$(./.tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

기대 결과: 모든 scheme 통과. 다음 테스트 묶음을 확인한다.

| 확인 | 근거 |
|---|---|
| `QuizGenerationOutcomeDTOTests`가 [판정표](./contracts/generation-outcome-payload.md#판정표) 12건을 검증 | SC-001, SC-003 |
| `PushQuizGenerationOutcomeSourceTests`가 관찰 원문 payload를 결과로 전달 | FR-003 |
| `GenerationOutcomeRepositoryAdapterTests`가 알림 센터 경로의 `type` payload를 결과로 변환 | FR-003 |
| `ProjectGenerationTests`의 결과 반영·보존·중복·만료 테스트가 통과하고, 결과 도착 시 로컬 예약 계약이 없음 | SC-004, SC-007 |
| `QuizGenerationProgressFeatureTests`가 권한 4상태의 홈 이동·요청·설정 열기를 검증 | SC-008 |
| `AppSettingTests`, `NotificationPermissionFeature` 관련 테스트 통과 | SC-009 |

## 2. 잔여 참조 검색 (SC-010)

```sh
grep -rnE "GenerationReminderScheduler|GenerationReminderContent|\bGenerationReminder\b|enqueueReminder|drainReminderProjectIDs|appendReminder|pendingGenerationReminders|pendingReminderLimit|ReminderEntry|reminderValidity|isReminderValid|reminderScheduler|ReminderNotification\b|LocalNotificationRequest|isAuthorized\(\)|LocalReminderNotifier|localReminderNotifier|reminderNotifier|ReminderNotificationClient|ReminderAuthorization(Setting|Status)|generationReminderPreferenceSelected|isReminderEnabled|LocalizedText\.GenerationReminder" sources/Projects --include='*.swift' --include='*.xcstrings'
```

기대 결과: 0건. Feature 시트 타입 `GenerationReminderSheet`와 키 `ProjectRegistration.GenerationReminderSheet.*`는
유지 대상이다(research R7). 그래서 도메인 모델 `GenerationReminder`는 앞뒤 `\b` 경계로 검색해 `GenerationReminderSheet`와 `acceptGenerationReminder`를 제외하고, 제거 대상 타입
`GenerationReminderScheduler`(`…Adapter`, `…AdapterTests`, `Spy…` 포함)는 경계 없는 부분 문자열로 검색한다.
이 패턴은 단위별 검색(T020·T029·T034·T040·T053)의 합집합이다.

## 3. 실기기 검증 (SC-005)

**전제**:
- 개발 빌드를 설치한 iPhone이 Mac과 같은 네트워크에 있거나 케이블로 연결되어 있다.
- Console.app에서 기기를 선택하고 "정보 메시지 포함"과 "디버그 메시지 포함"을 켰다.
- 검색어는 `PushQuizGenerationOutcomeSource`와 `LocalPendingGenerationStore`다.

| # | 조작 | 기대 결과 |
|---|---|---|
| 1 | 문제를 만들 수 없는 저장소를 등록하고 진행 화면에서 기다린다 | `QUIZ_REJECTED` 알림 도착 시 "파싱 성공 … status=failed" 로그. 진행 화면이 실패 상태가 된다 |
| 2 | 1 직후 앱 홈과 공유 확장에서 다른 저장소를 등록한다 | 홈 잠금 없음. 공유 확장에서 생성 중 안내 없이 등록 진행 |
| 3 | 정상 저장소를 등록하고 "홈에서 기다리기"(권한 허용 상태)를 누른 뒤 앱을 백그라운드로 보낸다 | 서버 알림 "프로젝트 준비 완료" 하나만 표시된다. 같은 결과의 앱 로컬 알림은 없다 |
| 4 | 3의 알림을 누르지 않고 앱 아이콘으로 복귀한다 | 기록이 완료로 바뀌고 목록에 프로젝트가 보인다 |
| 5 | 설정에서 알림을 끈 뒤 등록하고 "홈에서 기다리기"를 누른다 | 권한 시트가 보이고, "리마인드 알림 설정하기"를 누르면 시스템 설정이 열린다 |
| 6 | 설정 화면의 알림 권한 표시와 설정 이동 | 변경 전과 같다 |

수행하지 못한 항목은 PR 미검증 범위에 적는다.
