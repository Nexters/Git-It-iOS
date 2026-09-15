# Composition 책임 정리 요구사항

**상태**: 초안

**작성일**: 2026-09-15

**근거 시점**: branch `feature/screen-type-refactor`, commit `bee2388`

**목적** — 조립 경계인 Composition에 들어와 있는 비즈니스 정책·영속·런타임 제어 흐름을 원래 소유 패키지로 되돌립니다.

**전제** — Domain↔Data 경계 구조는 현행을 유지합니다. Adapter 자체는 Composition에 남습니다.

## 1. 현상

[composition.md](../package-rules/composition.md)는 이미 세 가지를 금지하고 있습니다.

- 비즈니스 규칙을 Adapter 내부에 구현하지 않는다
- 데이터 캐시·저장·동기화 정책을 Composition에 구현하지 않는다
- Infrastructure의 외부 라이브러리 구체 API를 Data 구현이 아닌 Composition이 직접 사용하지 않는다

현재 코드는 세 가지 모두를 위반합니다. 즉 이 문서는 새 규칙을 만드는 것이 아니라 **기존 규칙으로 코드를 되돌리는** 요구사항입니다.

### 1.1 위반 목록

Composition 프로덕션 코드 2,451줄의 구성입니다.

| 경로 | 줄수 | 실제 성격 | 위반 |
| --- | --- | --- | --- |
| `Adapter/Adapters/` 16개 | ~1,000 | Domain↔Data 변환 | — (일부 예외는 아래) |
| `Adapter/Assemblies/` 5개 + `App/Assemblies/` + `ShareExtension/Assemblies/` | ~600 | 조립 | — (`bootstrap` 제외) |
| `Adapter/Codings/` 3개 | 189 | Keychain·UserDefaults 직렬화 | 저장 정책 |
| `Adapter/Layouts/` 3개 | 55 | Keychain namespace·key 스키마 | 저장 정책 |
| `Adapter/Migrations/SessionKeychainMigration.swift` | 49 | 저장소 마이그레이션 | 저장 정책 |
| `Adapter/Resolvers/SessionAvailabilityResolver.swift` + `Models/SessionAvailability.swift` | 52 | 세션 유효성 판정 | 비즈니스 규칙 |
| `Adapter/Factories/GenerationCompletionReminderCoordinator.swift` | 108 | 리마인드 등록·완료 판정·알림 예약 | 비즈니스 규칙 |
| `Adapter/Adapters/RepositoryCreationStateRepositoryAdapter.swift` | 107 | UserDefaults 직접 IO + 만료 정책 + URL 정규화 | 저장 정책 + 비즈니스 규칙 |

### 1.2 개별 사례

**`GenerationCompletionReminderCoordinator`** — 등록된 프로젝트 집합을 보유하고, 생성 결과가 완료인지 판정하고, 알림 권한을 확인하고, 예약 시각을 `GenerationWaitPolicy`로 계산하고, **한국어 알림 제목·본문을 하드코딩**합니다(`"세트 생성 완료"`, `"학습 세트 생성이 완료됐어요. 지금 확인해보세요."`). 조립 객체가 아니라 앱 수명 내내 사는 정책 actor입니다.

**`RepositoryCreationStateRepositoryAdapter`** — `UserDefaultsStore`(Infrastructure)를 직접 생성해 읽고 씁니다. Data를 거치지 않습니다. 900초 만료 정책과 GitHub URL 정규화 규칙도 이 안에 있습니다.

**`SessionAvailabilityResolver`** — Keychain에서 세션 레코드를 읽고 access token 만료 시각을 현재 시각과 비교해 `signInRequired` 여부를 판정합니다. 만료 판정은 Domain 규칙입니다.

**`AppComposition`** — `FirebaseMessagingPushClient`를 직접 생성합니다(`PushClientBox`). 외부 라이브러리 구체 구현을 Composition이 직접 사용하는 사례입니다.

**`AppComposition.bootstrap`** — 마커 저장 → 푸시 클라이언트 활성화 → AppDelegate 구성 → 관측 2종 시작을 정해진 순서로 실행합니다. 앱 기동 순서라는 런타임 제어 흐름이며 App의 책임입니다.

**`AppComposition.registerCurrentDevice`** — deviceID를 Keychain에서 읽거나 생성하고, `Bundle.main`과 `ProcessInfo`에서 앱·OS 버전을 조회하고, 푸시 토큰을 받아 `MemberDeviceInfo`를 구성해 Domain을 호출합니다. UseCase 본체입니다.

### 1.3 같은 개념이 네 패키지에 흩어져 있습니다

`GenerationProgress` 하나를 예로 들면 모델은 `Domain/LearningProject/Models/`, 저장은 `Data/LearningProject/`의 store, 어댑터는 `Composition/Adapter/Adapters/GenerationProgressRepositoryAdapter.swift`, 대기 정책 `GenerationWaitPolicy`는 다시 Domain에 있습니다. 반면 같은 종류의 로컬 상태인 `RepositoryCreationState`는 Data를 건너뜁니다. 동일 문제에 두 개의 다른 경로가 존재합니다.

## 2. 문제 정의

1. Composition이 조립 외의 책임을 갖는 만큼, 정책 변경이 조립 코드 변경과 뒤섞여 리뷰 단위가 커집니다.
2. Composition에 있는 정책은 Domain 테스트 대상이 아니므로 비즈니스 규칙 테스트가 조립 테스트에 섞입니다.
3. 로컬 상태를 저장하는 경로가 두 가지여서 새 상태를 추가할 때 참고할 정본이 없습니다.

## 3. 요구사항

### FR-1 저장·직렬화 코드를 Data로 이동

- `Adapter/Codings/` 3개, `Adapter/Layouts/` 3개, `Adapter/Migrations/` 1개를 해당 도메인의 Data 모듈로 이동한다.
  - 세션 관련(`SessionRecordKeychainCoding`, `SessionKeychainLayout`, `SessionKeychainMigration`, `AppleIdentityKeychainLayout`) → `DataAuthentication`
  - 생성 리마인드·공유 세션 마커(`PendingGenerationReminderCoding`, `SharedSessionStateMarkerCoding`, `SharedSessionLayout`) → 해당 도메인의 Data 모듈
- 이동 후 Composition은 이들의 구체 타입을 조립 대상으로만 사용한다. 저장 키·네임스페이스·인코딩 형식을 Composition이 정의하지 않는다.

### FR-2 `RepositoryCreationStateRepositoryAdapter`를 분해

- UserDefaults 직접 IO를 Data 모듈의 store 구현으로 옮긴다. Composition이 `UserDefaultsStore`를 직접 생성하지 않는다.
- 900초 만료 판정과 GitHub URL 정규화 규칙을 Domain으로 옮긴다.
- Composition에는 Domain 계약과 Data store를 잇는 변환만 남긴다.
- 이 요구사항은 [AsyncStream 재설계 요구사항](./async-stream-redesign-requirements.md) FR-4의 상태 통합과 충돌하지 않아야 한다. FR-4를 먼저 수행하면 이 어댑터 자체가 사라질 수 있으므로 **순서를 확인한 뒤 착수한다.**

### FR-3 `GenerationCompletionReminderCoordinator`를 Domain으로 이동

- 리마인드 등록 대상 집합 관리, 완료 판정, 예약 시각 계산을 Domain UseCase로 옮긴다.
- 알림 문구는 Composition·Domain 어디에도 하드코딩하지 않는다. 표시 문자열의 소유 위치를 결정하고 그에 따라 배치한다.
- 알림 권한 확인과 예약 요청은 Domain 계약(`NotificationAuthorizationGateway` 계열)을 통해서만 수행한다.
- Composition에는 Domain 계약을 `InfrastructureLocalNotification`에 잇는 Adapter만 남긴다.

### FR-4 `SessionAvailabilityResolver`의 판정 규칙을 Domain으로 이동

- access token 만료 판정과 `signInRequired` / `appLaunchRequired` 분기를 Domain으로 옮긴다.
- `SessionAvailability` 타입의 소유 패키지를 결정한다. ShareExtension(App)이 이 타입을 사용하므로, App이 참조할 수 있는 패키지에 두어야 한다.
- Composition에는 Data 저장소 조회와 Domain 계약 연결만 남긴다.

### FR-5 외부 라이브러리 직접 사용 제거

- `AppComposition`이 `FirebaseMessagingPushClient`를 직접 생성하지 않는다. 푸시 클라이언트 구현 선택은 Infrastructure가 제공하는 계약(`PushMessagingClient`)의 팩토리를 통해 수행한다.
- Composition 코드에서 외부 라이브러리 타입 이름이 등장하지 않는다.

### FR-6 앱 기동 제어 흐름을 App으로 이동

- `AppComposition.bootstrap`이 수행하는 순서 있는 기동 절차를 App이 소유하는 타입으로 옮긴다.
- Composition은 기동에 필요한 개별 조각(푸시 클라이언트, 관측 시작 함수, 마커 저장)을 제공하고, 실행 순서는 결정하지 않는다.
- `PushNotificationAppDelegate` 구성도 App이 수행한다.

### FR-7 `registerCurrentDevice`를 UseCase로 승격

- deviceID 발급·보관 계약을 Domain에 정의하고, 그 구현은 Data에 둔다.
- 앱 버전·OS 버전 조회는 App 또는 Infrastructure가 제공하는 값으로 주입받는다. Composition이 `Bundle.main`이나 `ProcessInfo`를 직접 읽지 않는다.
- `MemberDeviceInfo` 구성과 등록 호출을 Domain UseCase로 옮긴다.

### FR-8 로컬 상태 저장 경로 단일화

- 로컬에 보관하는 상태는 예외 없이 `Domain 계약 → Composition Adapter → Data store → Infrastructure 저장 API` 경로를 따른다.
- Composition이 Infrastructure 저장 API를 직접 호출하는 지점이 없어야 한다.

## 4. 비범위

- Domain↔Data Adapter 구조 자체 (현행 유지)
- `CompositionAdapter` target 분할 — [패키지 의존성 원칙 강제 요구사항](./package-dependency-enforcement-requirements.md) FR-7이 소유
- UseCase 개수 통합 — [UseCase 통합 요구사항](./usecase-consolidation-requirements.md)이 소유
- 생성 상태 모델 통합 — [AsyncStream 재설계 요구사항](./async-stream-redesign-requirements.md)이 소유

## 5. 수용 기준

- [ ] `sources/Projects/Composition/` 아래에 `Codings/`, `Layouts/`, `Migrations/`, `Resolvers/` 폴더가 없다.
- [ ] Composition 프로덕션 코드에서 `UserDefaults`, `UserDefaultsStore`, `KeychainStore`를 직접 생성하거나 읽고 쓰는 지점이 없다.
- [ ] Composition 프로덕션 코드에서 `Bundle.main`, `ProcessInfo`를 읽는 지점이 없다.
- [ ] Composition 프로덕션 코드에 외부 라이브러리 타입 이름(`Firebase*`)이 없다.
- [ ] Composition 프로덕션 코드에 사용자에게 표시되는 문자열 리터럴이 없다.
- [ ] `AppComposition`에 순서 의존적인 기동 절차를 실행하는 클로저가 없다.
- [ ] 이동한 정책 각각에 대해 이동 전 테스트가 보장하던 항목이 이동 후 소유 패키지의 테스트로 유지된다.
- [ ] Composition 프로덕션 코드 줄수가 현재(2,451줄) 대비 감소했고, 남은 코드가 Adapter와 Assembly로만 구성된다.

## 6. 영향 범위

| 패키지 | 영향 |
| --- | --- |
| Composition | `Adapter/` 전반, `App/Assemblies/AppComposition.swift`, `App/Factories/PushNotificationAppDelegate.swift`, `ShareExtension/Assemblies/` |
| Domain | 리마인드 정책, 세션 유효성 판정, 생성 상태 만료 정책, 기기 등록 UseCase, deviceID 계약 |
| Data | 신규 store·coding·migration 소유, 각 모듈의 저장 스키마 |
| Infrastructure | `PushMessagingClient` 팩토리 진입점 |
| App | 기동 절차 소유 타입, `GitItApp`, `ShareViewController` |

**리스크** — FR-1은 Keychain·UserDefaults의 **키와 네임스페이스**를 옮깁니다. 값이 그대로 유지되지 않으면 기존 사용자의 로그인 세션이 끊깁니다. 이동 시 키 문자열을 변경하지 않아야 하며, 기존 저장 값을 읽을 수 있는지 검증하는 테스트가 필요합니다. `SessionKeychainMigration`이 이미 레거시 저장소를 다루고 있으므로 이동 과정에서 마이그레이션 경로가 깨지지 않는지 함께 확인합니다.

## 7. 작업 순서 제안

1. FR-5 — 외부 라이브러리 직접 사용 제거. 범위가 작고 독립적입니다.
2. FR-1 — 저장·직렬화 이동. 키 보존 검증을 이 단계에 집중합니다.
3. FR-4, FR-7 — 판정 규칙과 기기 등록 이동.
4. FR-3 — 리마인드 정책 이동.
5. FR-6 — 기동 절차 이동. 위 단계에서 조각이 정리된 뒤 수행합니다.
6. FR-2, FR-8 — 생성 상태 경로 단일화. [AsyncStream 재설계 요구사항](./async-stream-redesign-requirements.md) FR-4와 순서를 맞춥니다.

## 관련 문서

- [Composition 패키지 규칙](../package-rules/composition.md)
- [Domain 패키지 규칙](../package-rules/domain.md)
- [Data 패키지 규칙](../package-rules/data.md)
- [아키텍처](../architecture.md)
- [AsyncStream 재설계 요구사항](./async-stream-redesign-requirements.md)
- [패키지 의존성 원칙 강제 요구사항](./package-dependency-enforcement-requirements.md)
