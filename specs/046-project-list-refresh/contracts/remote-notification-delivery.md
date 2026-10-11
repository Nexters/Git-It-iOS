# 계약: 원격 알림 전달 경로

> 045(`feature/fix-generation-stuck`)에서 이관한 계약이며 `756696d`·`0a76670`에 구현되었다. 목록 자동 갱신은 이 경로를 바꾸지 않고, 파싱에 성공한 결과를 Domain `ProjectGeneration.outcomeArrivals()`로 다시 알린다([domain-contracts.md](./domain-contracts.md)).

**명세**: [../spec.md](../spec.md) | **조사**: [../research.md](../research.md) R1~R4·R10, L1

## 경로별 동작

| 경로(`route`) | 플랫폼 콜백 | 전달 시각 | 결과 반영 | 기존 동작 |
|---|---|---|---|---|
| `background` | `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)` | 콜백 호출 시각 | 예 | 유지(시각만 추가) |
| `presentation` | `userNotificationCenter(_:willPresent:)` | `notification.date` | 예 | **추가**. 표시 옵션(`[.banner, .list, .sound]`)은 유지 |
| `opened` | `userNotificationCenter(_:didReceive:)` | `response.notification.date` | 예 | **추가**. 앱이 종료된 상태에서 실행될 때도 포함(FR-009, FR-010) |

같은 결과가 여러 경로로 오면 두 번째부터는 기록을 바꾸지 않는다(FR-012).

## 계층별 시그니처

| 계층 | 타입 | 변경 |
|---|---|---|
| Infrastructure | `PushNotificationCallbacks.ingestGenerationOutcomePayload` | `@Sendable ([String: String], RemoteNotificationDelivery) async -> Void` |
| Infrastructure | `RemoteNotificationDelivery` | **신규**. `route`, `deliveredAt` |
| Data `DataNotification` | `NotificationAppCallbacks.ingestRemoteMessagePayload` | `@Sendable ([String: String], RemoteMessageDelivery) async -> Void` |
| Data `DataNotification` | `RemoteMessageDelivery` | **신규**. Infrastructure 값을 옮겨 담는 Data 소유 타입 |
| Data `DataNotification` | `NotificationAppDelegate` | `UNUserNotificationCenterDelegate` 콜백은 Infrastructure 기본 구현이 소유하므로, 이 delegate는 전달 정보 변환만 한다 |
| Data `DataLearningProject` | `PushQuizGenerationOutcomeSource.ingest(rawPayload:deliveredAt:)` | `deliveredAt` 인자 **추가** |
| Composition | `AppComposition`, `LearningProjectAssembly` | 콜백을 연결할 때 `RemoteMessageDelivery.deliveredAt`을 `ingest`에 넘긴다 |

## 설정 전 도착 슬롯

- `configure(_:)` 전에 도착한 결과를 담는 대기 슬롯을 단일 값에서 **최대 8개 FIFO 목록**으로 바꾼다. `configure` 시점에 도착 순서대로 모두 전달한다.
- 백그라운드 콜백의 `completionHandler`와 탭 콜백의 완료는 기존처럼 결과 전달 요청 뒤에 호출한다. 탭 콜백은 `async` 변형을 쓴다.

## 진단 로그(FR-018)

| 위치 | 기록 내용 |
|---|---|
| Infrastructure `FirebaseMessagingAppDelegate` | 경로, 전달 시각, 슬롯 보관 여부 |
| Data `PushQuizGenerationOutcomeSource` | 파싱 성공·실패, 버퍼 보관·전달 |
| Data `LocalPendingGenerationStore` | 기록 저장 후 상태별 개수 |

subsystem은 기존 값 `com.nexters.hytime.gitit`를 유지하고, 식별자와 시각은 `privacy: .public`으로 남긴다.

## 알림 센터 경로 (2026-09-28 추가)

| 경로 | 계기 | 전달 시각 | 도착 알림(목록 갱신 계기) |
|---|---|---|---|
| 알림 센터 | 회원 앱 활성화의 `synchronize()` | 시스템 전달 시각 | 방출하지 않음(FR-025) |

| 계층 | 시그니처 |
|---|---|
| Infrastructure | `protocol DeliveredNotificationClient { func deliveredRemoteNotifications() async -> [DeliveredRemoteNotification] }`, 구현 `NotificationCenterDeliveredNotificationClient` |
| Data | `protocol DeliveredRemoteMessageReader { func deliveredMessages() async -> [DeliveredRemoteMessage] }`, `NotificationFactory.deliveredRemoteMessageReader()` |
| Composition | `GenerationOutcomeRepositoryAdapter(source:deliveredMessages:)` |

- 앱은 알림 센터의 알림을 지우거나 바꾸지 않는다(FR-024).
- Data client는 읽은 원격 알림 개수를 진단 로그로 남긴다.
