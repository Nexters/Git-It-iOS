# 경계 계약 변경

이 명세는 패키지 경계를 넘는 계약을 새로 만들거나 옮긴다. 서버 API와 저장 값의 형식은
바꾸지 않는다.

## 1. 새로 만드는 Domain 계약

### `DeviceIdentifierRepository` (`DomainMember`)

요구하는 쪽은 기기 등록 UseCase, 제공하는 쪽은 Composition Adapter(구현은 `DataMember`)다.

- deviceID를 돌려준다. 저장된 값이 없으면 새로 발급해 보관한 뒤 그 값을 돌려준다.
- 같은 기기에서 두 번 호출하면 같은 값이 나온다.
- 발급에 실패하면 오류를 던진다.

### 리마인드 예약 계약 (`DomainLearningProject`)

요구하는 쪽은 생성 완료 리마인드 정책, 제공하는 쪽은 Composition Adapter다.

- 식별자와 예약 시각을 받아 로컬 알림을 예약한다.
- 표시 문구는 인자에 없다. 구현이 조립 시점에 주입받은 값을 쓴다.

기존 `NotificationAuthorizationGateway`는 그대로 쓴다. 권한 확인은 정책이 이 계약으로 한다.

## 2. 옮기는 공개 타입

| 타입 | 이전 | 이후 |
| --- | --- | --- |
| `SessionAvailability` | `CompositionAdapter` | `DomainAuthentication` |
| `SharedSessionStateMarkerCoding` | `CompositionAdapter` | `DataAuthentication` |
| `PendingGenerationReminderCoding` | `CompositionAdapter` | `DataLearningProject` |
| `SharedSessionLayout`의 App Group 좌표 | `CompositionAdapter` | `InfrastructureStorage`·`InfrastructureAuthentication` |

`SessionRecordKeychainCoding`, `SessionKeychainLayout`, `AppleIdentityKeychainLayout`,
`SessionKeychainMigration`은 Composition 밖에서 참조되지 않으므로 공개 범위를 넓히지 않고
`DataAuthentication`으로 옮긴다.

## 3. 바뀌는 Composition 공개 표면

| 항목 | 변경 |
| --- | --- |
| `AppComposition.bootstrap` | 제거. 기동 조각을 개별 프로퍼티로 공개한다 |
| `AppComposition.registerCurrentDevice` | 유지하되 내부가 Domain UseCase 호출로 바뀐다 |
| `AppComposition.init` | 앱 버전·OS 버전·리마인드 표시 문구를 인자로 받는다 |
| `PushNotificationAppDelegate` | 외부 라이브러리 타입 별칭에서 Infrastructure가 감싼 타입으로 |

`AppCompositionPublicSurfaceTests`가 공개 프로퍼티 목록을 고정하고 있으므로 이 변경과 함께
갱신한다.

## 4. Infrastructure가 새로 공개하는 진입점

| 항목 | 내용 |
| --- | --- |
| 푸시 클라이언트 생성 진입점 | `PushMessagingClient` 구현을 만들어 돌려준다. 외부 라이브러리 타입을 노출하지 않는다 |
| AppDelegate 기반 타입 | 외부 라이브러리 AppDelegate를 감싼 프로젝트 타입 |
| App Group 공유 저장소 생성 | 공유 `UserDefaults`와 공유·레거시 `KeychainStore`를 만든다 |
