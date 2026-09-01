# 데이터 모델: 생성 리마인드 명명·경계 리팩터링

**기능 브랜치**: `feature/generation-reminder-refactoring`

**날짜**: 2026-09-01

**명세**: [spec.md](./spec.md) | **조사**: [research.md](./research.md)

이 기능은 새 데이터를 도입하지 않는다. 아래는 기존 개념이 어느 경계에서 어떤 타입으로
표현되는지와, 이 리팩터링이 바꾸는 이름·소유 위치를 기록한다. 필드 구성과 값 의미는
변경하지 않는다(FR-018).

---

## 1. 생성 결과

학습 세트 생성이 완료 또는 실패했다는 사실. 세 경계가 각자의 타입으로 소유하며 경계에서
변환된다.

### 1.1 Domain 모델

**타입**: `GenerationOutcome` *(현재 `LearningProjectGenerationOutcome`)*

**위치**: `Domain/LearningProject/Models/LearningProject/GenerationOutcome.swift`

| 필드 | 타입 | 의미 |
| --- | --- | --- |
| `projectID` | `String` | 대상 학습 프로젝트 식별자 |
| `status` | `Status` | 생성 결과 상태 |

**중첩 타입** `Status`: `completed`, `failed`

**변경**: 이름만 바꾼다. 필드·케이스·`Equatable`/`Sendable` 준수는 그대로 둔다.

**검증 규칙**: 없음. 값 객체이며 생성 시 제약이 없다.

### 1.2 Data 전송 모델

**타입**: `GenerationOutcomeDTO` *(현재 `ProjectGenerationOutcomeDTO`)*

**위치**: `Data/LearningProject/DTOs/GenerationOutcomeDTO.swift`

| 필드 | 타입 | 의미 |
| --- | --- | --- |
| `projectID` | `String` | push payload의 `projectId` 값 |
| `status` | `RawStatus` | push payload의 `status` 값 |

**중첩 타입** `RawStatus: String`: `completed`, `failed`

**검증 규칙**(변경 없음):

- `projectId` 키가 없으면 생성 실패(`nil`)
- `status` 키가 없으면 생성 실패
- `status` 값이 `RawStatus`에 없으면 생성 실패

**외부 계약 고정**: payload 키 `projectId`, `status`와 값 `completed`/`failed`는 서버가
소유하므로 **변경하지 않는다**(명세 `가정`의 외부 계약 항목).

### 1.3 경계 변환

`GenerationOutcomeDTO` → `GenerationOutcome` 변환은
`Composition/Adapter/Adapters/GenerationOutcomeRepositoryAdapter.swift`가 소유한다.

| 입력 `RawStatus` | 출력 `Status` |
| --- | --- |
| `completed` | `completed` |
| `failed` | `failed` |

**변경**: 현재 이 변환에는 프로젝트 소유 enum에 대한 미지 케이스 분기가 있어 새 케이스가
추가되어도 컴파일러가 경고하지 않고 이벤트를 조용히 폐기한다(`nil` 반환). 이 분기를
제거해 전수 분기로 만들고, 변환 결과가 `Optional`이 아니게 한다(FR-019).

---

## 2. 생성 결과 관찰 계약

생성 결과가 도착할 때마다 전달하는 무한 수명 계약. 1회 조회 계약과 수명이 다르다.

| 경계 | 현재 이름 | 변경 후 이름 | 연산 |
| --- | --- | --- | --- |
| Domain 계약 | `LearningProjectGenerationOutcomeRepository` | `GenerationOutcomeRepository` | `outcomes() async -> AsyncStream<GenerationOutcome>` |
| Domain UseCase 계약 | `LearningProjectOutcomesUseCase` | `ObserveGenerationOutcomesUseCase` | `callAsFunction() async -> AsyncStream<GenerationOutcome>` |
| Domain UseCase 구현 | `LearningProjectOutcomes` | `ObserveGenerationOutcomes` | 위 계약 위임 |
| Data 계약 | `ProjectGenerationOutcomeRemote` | `GenerationOutcomeStream` | `outcomes() -> AsyncStream<GenerationOutcomeDTO>` |
| Data 구현 | `PushProjectGenerationOutcomeRemote` | `PushGenerationOutcomeStream` | 위 계약 + `ingest(rawPayload:)` |

**수명**: 구독은 소비자가 스트림을 폐기할 때 종료된다. `PushGenerationOutcomeStream`은
구독별 continuation을 `UUID` 키로 보관하고 `onTermination`에서 제거한다(변경 없음).

**멀티캐스트**: 하나의 `ingest`가 모든 활성 구독에 전달된다(변경 없음). 현재 구독자는
Home 화면, 등록 화면, 리마인드 스케줄러 셋이다.

---

## 3. 리마인드 등록 대상

사용자가 알림 수신을 수락한 프로젝트 식별자 집합.

| 경계 | 현재 이름 | 변경 후 이름 |
| --- | --- | --- |
| Domain 계약 | `GenerationReminderRegistry` | `GenerationReminderRegistry` *(유지)* |
| Composition 어댑터 | `GenerationReminderRegistryAdapter` | *(삭제)* |
| Composition 구현 | `GenerationCompletionReminderCoordinator` | `GenerationReminderScheduler` |

**변경**:

- 어댑터는 변환 없이 위임만 하므로 삭제하고, 스케줄러가 `GenerationReminderRegistry`를 직접
  구현한다(FR-013).
- 집합의 상태 전이는 그대로 둔다: `register(projectID:)`로 추가, 생성 결과 수신 시 `remove`로
  1회 소비. 같은 식별자에 완료 이벤트가 두 번 와도 발송은 1회다.

**소유**: 스케줄러 actor 내부 `Set<String>`. 앱 실행 동안만 유지되며 영속화하지 않는다
(변경 없음).

---

## 4. 알림 권한 결과

허용 · 방금 거부 · 이미 거부 세 상태. 두 경계가 각자의 타입으로 소유한다.

| 경계 | 현재 이름 | 변경 후 이름 |
| --- | --- | --- |
| Infrastructure | `LocalNotificationAuthorizationOutcome` (최상위) | `LocalNotificationAuthorizationOutcome` (최상위, 파일만 분리) |
| Domain | `NotificationAuthorizationOutcome` | `NotificationAuthorizationOutcome` *(유지)* |

**케이스**(양쪽 동일, 변경 없음): `authorized`, `declined`, `previouslyDenied`

**경계 변환**: `Composition/Adapter/Adapters/NotificationAuthorizationGatewayAdapter.swift`가
1:1로 매핑한다. 현재 이 변환에는 테스트가 없어 세 분기를 뒤바꿔도 실패하지 않는다.
FR-017에 따라 각 분기를 검증하는 테스트를 추가한다.

**파일 분리 이유**: 최상위 enum과 프로토콜이 한 파일에 있어 "파일 하나에 타입 하나" 규칙을
위반한다(FR-003). Swift는 protocol 내부에 타입을 중첩할 수 없으므로(언어 제약,
[research.md](./research.md) R-010) 프로토콜 안에 중첩하는 대신
`Infrastructure/PushMessaging/Local/Models/LocalNotificationAuthorizationOutcome.swift`로
파일만 분리한다. 이름은 바꾸지 않는다
([file-vocabulary.md §2.4](../../docs/conventions/file-vocabulary.md#24-중첩할-수-없는-타입)).

---

## 5. 로컬 알림 요청 *(신규 경계 값)*

알림 식별자와 표시 문구를 담아 기술 계층에 전달하는 값. 이 기능에서 새로 분리된다.

**타입**: `LocalNotificationRequest`

**위치**: `Infrastructure/PushMessaging/Models/LocalNotificationRequest.swift`

| 필드 | 타입 | 의미 |
| --- | --- | --- |
| `identifier` | `String` | 알림 요청 식별자 |
| `title` | `String` | 알림 제목 |
| `body` | `String` | 알림 본문 |

**소유 경계**:

- **값 생성**: Composition의 `GenerationReminderScheduler`. 식별자 형식
  `"generation-completed-<projectID>"`와 문구 내용은 형식·내용 모두 현재와 동일하게 유지하되
  생성 위치만 옮긴다(명세 `가정`의 동작 무변경 범위).
- **값 소비**: Infrastructure의 `UserNotificationCenterLocalClient`가 받아
  `UNNotificationRequest`로 변환해 발송한다.

**변경 전 상태**: 식별자와 문구가 `UserNotificationCenterLocalClient` 내부에 하드코딩되어
있고, 계약 연산 이름이 `presentGenerationCompletedNotification(projectID:)`로 서비스 개념을
담고 있다.

**변경 후 계약**:

```text
LocalNotificationClient
  requestAuthorization() async -> LocalNotificationAuthorizationOutcome
  isAuthorized() async -> Bool
  present(_ request: LocalNotificationRequest)
```

---

## 6. 이름 변경 요약

| # | 현재 | 변경 후 | 글자 수 |
| --- | --- | --- | --- |
| 1 | `LearningProjectGenerationOutcome` | `GenerationOutcome` | 32 → 17 |
| 2 | `LearningProjectGenerationOutcomeRepository` | `GenerationOutcomeRepository` | 42 → 27 |
| 3 | `LearningProjectGenerationOutcomeRepositoryAdapter` | `GenerationOutcomeRepositoryAdapter` | 49 → 34 |
| 4 | `ProjectGenerationOutcomeDTO` | `GenerationOutcomeDTO` | 27 → 20 |
| 5 | `ProjectGenerationOutcomeRemote` | `GenerationOutcomeStream` | 30 → 23 |
| 6 | `PushProjectGenerationOutcomeRemote` | `PushGenerationOutcomeStream` | 34 → 27 |
| 7 | `LearningProjectOutcomes` | `ObserveGenerationOutcomes` | 23 → 25 |
| 8 | `LearningProjectOutcomesUseCase` | `ObserveGenerationOutcomesUseCase` | 30 → 32 |
| 9 | `GenerationCompletionReminderCoordinator` | `GenerationReminderScheduler` | 39 → 27 |
| 10 | `LocalNotificationAuthorizationOutcome` | *(이름 변경 없음, 파일만 `Local/Models/`로 분리)* | 38 → 38 |

최장 이름 49자 → 34자로 SC-002의 40자 상한을 충족한다. 7·8번은 글자 수가 늘지만
`docs/conventions/naming.md` §3.3이 요구하는 조회·관찰 수명 구분을 되살리는 변경이므로
길이보다 우선한다(§2.2 “짧은 이름 자체가 목표는 아닙니다”).

---

## 7. 삭제 대상

| 대상 | 위치 | 근거 |
| --- | --- | --- |
| `TextField` (UI 컴포넌트) | `UI/Component/Controls/TextField.swift` | production 참조 0 (R-007) |
| `TextFieldTests` | `UI/Tests/Component/Unit/Controls/TextFieldTests.swift` | 삭제 대상의 전용 테스트 |
| `GenerationReminderRegistryAdapter` | `Composition/Adapter/Adapters/` | 변환 없는 순수 위임 |
| `PushNotificationAppDelegate` typealias | `Composition/Adapter/Factories/` | Infrastructure 타입을 공개 API로 승격 (R-001) |
| `Delegate.notificationOptionSelected(accepted:)` | `Feature/ProjectRegistration/Reducers/` | 소비자가 무시하는 출력 |
| `Constant.bellIconSize` | `Feature/ProjectRegistration/Screens/NotificationOptionSheet.swift:47` | 선언만 되고 미사용 |
| `CancelID.submission` | `Feature/ProjectRegistration/Reducers/` | 취소 호출이 저장소에 없음 |
| `waitUntilObservationFinished()` | Composition 스케줄러 | 테스트 전용 production API (FR-010) |
