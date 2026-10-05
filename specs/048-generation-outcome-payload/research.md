# 조사: 생성 결과 원격 알림 payload 인식과 로컬 결과 알림 제거

**기능**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md) | **작성일**: 2026-09-30

## R1. 서버 payload 해석 규칙

- **결정**: `QuizGenerationOutcomeDTO.init?(rawPayload:deliveredAt:)`는 다음 순서로 판정한다.
  1. 최상위 `projectId`가 없거나 빈 문자열이면 `nil`이다.
  2. 최상위 `type`이 `QUIZ_READY`면 완료, `QUIZ_REJECTED`면 실패다.
  3. `type`이 없거나 위 두 값이 아니면 최상위 `status`를 본다. `completed`는 완료, `failed`는 실패다.
  4. 둘 다 인식하지 못하면 `nil`이다.
  값은 대소문자와 밑줄까지 정확히 일치해야 한다. `aps`, `gcm.*`, `google.c.*` 같은 나머지 키는 보지 않는다.
- **근거**:
  - 2026-09-29 실기기 관찰 3건이 모두 `type` 키였다(spec 배경 표).
  - FR-004는 두 키가 함께 있으면 `type`을 따르도록 요구한다.
  - FR-005는 `type`을 모르더라도 `status`를 인식하면 결과로 보도록 한다.
  - `projectId` 빈 문자열 거절은 spec 예외 사례를 따른다. 지금은 빈 문자열도 통과한다.
- **검토한 대안**:
  - `status` 형식을 제거하는 안은 기각했다. FR-004가 호환을 요구하고, 기존 테스트와 `xcrun simctl push`
    예시(046 quickstart)가 이 형식을 쓴다.
  - 대소문자를 무시하는 안은 기각했다. 서버 고정 명칭은 원문 표기를 보존한다(`docs/conventions/naming.md` §7).

## R2. 인식 규칙의 위치와 네 수신 경로

- **결정**: 판정은 Data의 `QuizGenerationOutcomeDTO` 한 곳에만 둔다.
- **근거**: 네 경로가 모두 이 초기화를 거치므로 여기만 고치면 FR-003이 충족된다.
  - 백그라운드 수신, 알림 표시, 알림 탭: `FirebaseMessagingAppDelegate` → `NotificationAppDelegate` →
    `PushQuizGenerationOutcomeSource.ingest`
  - 알림 센터 읽기: `GenerationOutcomeRepositoryAdapter.deliveredOutcomes`
  - 서버 payload 형식은 Data가 소유한다(`docs/package-rules/data.md` "서비스가 정의한 요청과 응답 형식은
    Data가 소유한 DTO로 표현").
- **검토한 대안**: Composition Adapter에서 `type`을 해석하는 안은 기각했다. Adapter는 Data와 Domain 사이의
  변환만 하고 서버 형식을 해석하지 않는다.

## R3. 인식 실패 진단 로그(FR-007)

- **결정**: `PushQuizGenerationOutcomeSource.ingest`의 기존 "생성 결과 payload 파싱 실패" 로그를
  유지한다. 알림 센터 경로에는 로그를 추가하지 않는다.
- **근거**:
  - 표시·탭·백그라운드 세 경로는 이미 rawPayload 전체를 debug 수준으로 남긴다. 2026-09-29 원인 규명도
    이 로그로 했다.
  - 알림 센터 경로는 앱이 활성화될 때마다 결과가 아닌 알림까지 전부 다시 읽는다. 그래서 인식하지 못한
    항목을 매번 남기면 같은 로그가 반복된다.
  - Composition은 로깅 관행이 없다(`Composition/**`에 `os.Logger` 사용처 없음).
- **검토한 대안**: 알림 센터 경로 판정을 Data로 옮겨 로그를 남기는 안은 기각했다. Data 공개 API가
  바뀌는데 얻는 진단 가치가 작다.

## R4. `RawStatus` 이름

- **결정**: `QuizGenerationOutcomeDTO.RawStatus`(`completed`, `failed`) 이름과 케이스를 유지한다.
  서버 `type` 값과의 대응은 DTO 내부의 비공개 대응표로 둔다.
- **근거**:
  - 네이밍 컨벤션 8은 rename과 동작 변경을 분리하라고 한다.
  - 공개 케이스는 결과 종류를 나타내며 기존 소비자(Composition Adapter)가 그대로 쓴다.
- **검토한 대안**: `RawStatus`를 `Outcome` 등으로 바꾸는 안은 이번 범위에서 뺐다. 필요하면 별도 rename 변경으로 한다.

## R5. 로컬 결과 알림 제거 범위(FR-010, FR-011)

- **결정**: 아래 표의 제거와 유지를 적용한다. 2026-09-30 전수 조사 결과를 따른다.

| 패키지 | 제거 | 유지 |
|---|---|---|
| Domain | `GenerationReminderScheduler`, `GenerationReminder`, `PendingGenerationRepository.enqueueReminder`·`drainReminderProjectIDs`, `GenerationWaitPolicy.reminderValidity`·`isReminderValid`, `ProjectGeneration`의 `reminderScheduler`·`reminderProjectIDs`·`absorbPendingReminders`·`scheduleReminderIfRegistered`·예약 취소 | `GenerationWaitPolicy.retentionLimit`·`expiryDate`·`isExpired`, 결과 반영·중복 도착·보존 결과·도착 알림·만료 타이머 |
| Data | `LocalPendingGenerationStore`의 결과 대기 대기열(`pendingGenerationRemindersKey`, `pendingReminderLimit`, `appendReminder`, `drainReminderProjectIDs`, `ReminderEntry`), `LocalReminderNotifier`의 `isAuthorized`·`schedule`·`cancel`, `ReminderNotification` | 생성 기록 저장(`namespace`, `stateKey`), 권한 조회·요청, 원격 메시지 수신·알림 센터 읽기 |
| Infrastructure | `NotificationAuthorizationClient`의 `isAuthorized`·`present`·`schedule`·`cancel`, `LocalNotificationRequest` | `requestAuthorization`, `authorizationSetting`, `InfrastructureLocalNotification` 모듈, 원격 푸시 |
| Composition | `GenerationReminderSchedulerAdapter`, `PendingGenerationRepositoryAdapter`의 대기열 메서드, `LearningProjectAssembly`의 `reminderContent`·`reminderNotifier`·`GenerationReminderContent`, `ConcernUseCaseAssembly`의 `generationReminder`·`GenerationReminderContent`, `AppComposition.Environment`의 결과 알림 문구 4개, `ShareExtensionComposition.live`의 `reminderNotifier` | `NotificationAuthorizationAdapter`, `ConcernUseCaseAssembly`의 권한 조회용 notifier |
| App | `GitItApp`의 결과 알림 문구 전달, `App/GitIt/Localization/LocalizedText.swift`·`Localizable.xcstrings`(결과 알림 문구 4개가 전부) | `AppRootFeature`의 기기 등록·권한 설정 흐름 |

- **근거**:
  - 결과가 기록에 반영되는 입력은 `GenerationOutcomeRepository` 하나뿐이다. 예약만 막으면 표의 제거
    항목에 도달하는 입력이 없다.
  - 설정 화면의 권한 조회·요청은 `AppSetting` → `NotificationAuthorizationAdapter` → `LocalReminderNotifier`
    → `NotificationAuthorizationClient`를 거치므로 권한 두 기능은 남긴다.
  - 원격 푸시 등록(`registerForRemoteNotifications`)은 권한과 무관해 영향이 없다.
- **검토한 대안**: 예약만 막고 코드를 남기는 안은 기각했다(2026-09-30 명확화).

## R6. 공유 저장소에 남은 결과 대기 대기열(FR-014)

- **결정**: 저장 키 `pendingGenerationReminders`의 기존 값은 지우는 이전 작업 없이 무시한다. 코드에서
  키 상수와 읽기·쓰기를 모두 없앤다.
- **근거**:
  - 값은 최대 32개 항목(`pendingReminderLimit`)의 작은 목록이다.
  - 읽는 코드가 없으면 동작에 영향이 없다.
  - 앱과 공유 확장 두 프로세스가 같은 App Group을 쓰므로, 일회성 삭제를 넣으면 실행 시점과 재실행 여부를
    다뤄야 하는 복잡도가 생긴다.
- **검토한 대안**: 앱 시작 시 한 번 `removeValue`를 부르는 안은 기각했다. 얻는 것은 수백 바이트 정리뿐인데
  이전 작업 코드와 테스트가 남는다.

## R7. "홈에서 기다리기" 흐름(FR-012, FR-013)

- **결정**: `QuizGenerationProgressFeature`의 권한 확인, 시트, 권한 요청, 시스템 설정 열기 흐름은 그대로
  둔다. 제거하는 것은 두 가지다.
  - `Delegate.generationReminderPreferenceSelected`와 `finishWaiting(isReminderEnabled:)` 인자
  - `ProjectRegistrationRouterFeature`의 같은 이름 delegate 전달과 `AppRootFeature`의 무시 분기
  시트 타입 `GenerationReminderSheet`와 문구 키 `ProjectRegistration.GenerationReminderSheet.*`는 유지한다.
- **근거**:
  - 선택값은 `AppRootFeature`에서 `.none`으로 버려져 동작에 쓰이지 않는다.
  - 시트는 서버 결과 알림 권한을 얻는 유일한 흐름이다(2026-09-30 명확화).
  - 시트 문구 "리마인드 알림"은 서버 알림에도 맞다. 사용자 노출 문구를 바꾸지 않으므로 키 이름도 유지한다.
- **검토한 대안**: 시트 타입과 키를 `NotificationPermissionSheet` 등으로 바꾸는 안은 이번 범위에서 뺐다.
  문구가 그대로라 이름이 거짓이 아니며, 바꾸면 Feature 현지화 키 이전이 따라온다.

## R8. 알림 권한 계약 이름(FR-015)

- **결정**: 로컬 알림 예약 기능을 덜어낸 뒤, 권한 조회·요청만 남은 Data 계약과 그 참조를 권한 책임
  이름으로 바꾼다. Infrastructure 이름(`NotificationAuthorizationClient`, `NotificationAuthorizationSetting`,
  `NotificationAuthorizationStatus`)은 이미 권한 책임을 드러내므로 유지한다.
- **용어 구분 근거**: Data는 Infrastructure를 import하고, Infrastructure에 이미
  `NotificationAuthorizationSetting`·`NotificationAuthorizationStatus`가 있다. Data가 같은 이름을 쓰면
  같은 파일에서 모듈 한정자로 구분해야 하므로 Data 경계는 `Permission`을 쓴다. Composition
  `NotificationAuthorizationAdapter`는 Domain 계약 `NotificationAuthorization`의 이름을 따르므로 유지한다.
- **`Requester` 범위**: 이 계약의 조회(`authorizationSetting()`)는 요청 전후의 권한 상태 확인이고,
  계약의 목적은 권한을 얻는 것이다. 그래서 요청 책임을 이름으로 드러낸다. 조회만 쓰는 사용처가
  생기면 계약을 나누는 것을 다시 검토한다.

| 현재 | 변경 | 위치 |
|---|---|---|
| `LocalReminderNotifier` | `NotificationPermissionRequester` | Data 계약 |
| `ReminderNotificationClient` | `NotificationPermissionClient` | Data 구현 |
| `ReminderAuthorizationSetting` | `NotificationPermissionSetting` | Data 모델 |
| `ReminderAuthorizationStatus` | `NotificationPermissionRequestResult` | Data 모델 |
| `NotificationFactory.localReminderNotifier()` | `NotificationFactory.notificationPermissionRequester()` | Data 생성 진입점 |
| `NotificationAuthorizationAdapter(reminderNotifier:)` | `NotificationAuthorizationAdapter(permissionRequester:)` | Composition |
| `ConcernUseCaseAssembly` 인자 `reminderNotifier` | `notificationPermissionRequester` | Composition |
| `ReminderNotificationClientTests` | `NotificationPermissionClientTests` | Data 테스트 |
| `GenerationReminderStorageCoordinateTests` | `PendingGenerationStorageCoordinateTests` | Data 테스트 |

- **근거**:
  - 남는 책임은 "현재 알림 권한 설정 조회"와 "권한 요청"이다(`docs/conventions/naming.md` §2.1).
  - Feature의 `NotificationPermissionFeature`와 같은 어휘를 쓴다.
  - 요청 결과는 설정값(`Setting`)과 구분되는 한 번의 요청 결과이므로 `RequestResult`로 드러낸다.
  - 저장 좌표 테스트는 결과 대기 키를 지운 뒤 생성 기록 좌표만 검증하므로 대상 이름으로 바꾼다.
  - 네이밍 컨벤션 8에 따라 이 rename은 다른 동작 변경과 섞지 않은 별도 커밋이다.
- **검토한 대안**:
  - `NotificationAuthorizer`는 기각했다. 권한을 부여하는 주체로 읽힌다.
  - `NotificationPermissionAccess`는 기각했다. 책임이 모호하다.

## R9. 이전 명세 기록(FR-008, FR-016)

- **결정**:
  - FR-008에 따라 `specs/046-project-list-refresh/spec.md`의 payload 가정과
    `specs/046-project-list-refresh/device-verification.md`의 "서버 payload" 표를 고친다. 가정 문장에는
    정정 표시와 이 명세 링크를 붙이고, 표에는 관찰 결과를 채운다.
  - FR-016에 따라 020·021·023 명세 본문은 고치지 않는다. 대체 관계는 이 명세(spec 배경·FR-016)와 이 조사에
    기록한다.
- **근거**:
  - 046은 현재 유효한 계약(FR-002·FR-015·FR-023)을 가진 최근 명세라 잘못된 가정이 남으면 후속 작업이 따른다.
  - 020·021·023은 폐기된 기능의 역사 기록이다.
- **대체 관계**: 020(로컬 결과 알림 도입), 021(생성 결과 알림 리팩터링의 `GenerationReminderScheduler`·
  `status` 외부 계약 고정), 023(결과 알림 즉시 예약)의 로컬 결과 알림 규칙과 021의 payload `status` 고정 가정은
  048이 대체한다.

## R10. 실행 단위와 위상 순서

- **결정**: 8개 커밋 단위로 나눈다. 순서와 파일은 [plan.md](./plan.md) "실행 단위"를 따른다. 로컬 결과
  알림 제거(U1~U3)를 payload 인식(U5)보다 먼저 둔다.
- **근거**:
  - payload 인식이 먼저 들어가면 중간 커밋에서 로컬 결과 알림이 실제로 예약되어 중복 알림이 생긴다.
  - 제거는 상위 사용처부터 걷어내야 커밋마다 compile된다. 따라서 Domain·Composition·App → Data →
    Infrastructure 순서로 진행한다.
- **검토한 대안**: 패키지 위상 순서(Infrastructure 먼저)대로 제거하는 안은 기각했다. 하위 계약의 메서드를
  먼저 지우면 상위 구현이 compile되지 않아 모든 패키지를 한 커밋에 묶어야 한다.
