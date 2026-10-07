# AsyncStream 재설계 요구사항

**상태**: 초안

**작성일**: 2026-09-15

**근거 시점**: branch `feature/screen-type-refactor`, commit `bee2388`

**목적** — 프로덕션에서 실제 값을 흘리지 않거나, 값을 흘려도 구독 시점에 따라 유실되는 `AsyncStream` 파이프라인을 제거하거나 신뢰 가능한 관측 모델로 교체합니다.

**전제** — Domain↔Data 경계 구조(Adapter 경유)는 현행을 유지합니다. 이 문서의 요구사항은 그 경계를 바꾸지 않는 범위에서 성립합니다.

## 1. 현상

프로덕션 `AsyncStream`은 세 갈래뿐입니다.

| # | 스트림 | 소스 | 구독자 수 |
| --- | --- | --- | --- |
| S1 | `AuthenticationRepository.authorizationChanges()` → `AuthenticationOutcomesUseCase` | `AppleCredentialStateProvider.changes()` | 1 (`AppRootFeature`) |
| S2 | `AppComposition.deviceTokenRefreshes` (`AsyncStream<Void>`) | `FirebaseMessagingPushClient.registrationTokenRefreshes()` | 1 (`AppRootFeature`) |
| S3 | `ObserveGenerationOutcomesUseCase` | `PushQuizGenerationOutcomeSource` | 5 |

### 1.1 S1은 프로덕션에서 이벤트를 내지 않습니다

`AppleCredentialStateProvider`에서 continuation에 값을 넣는 유일한 경로는 `receiveRevocation(for:)`이고, 그 호출처는 `Infrastructure/Tests/Authentication/AppleAuthentication/Providers/AppleCredentialStateProviderTests.swift:17` 한 곳뿐입니다. 프로덕션 조립 경로(`AuthenticationAssembly`)에는 이 메서드를 호출하는 코드가 없습니다.

그 결과 `AuthenticationOutcomes`(98줄, 세션 복원·무효 세션 정리·오류 분류를 모두 담당)와 `AppRootFeature`의 `CancelID.authenticationOutcomes` Effect가 한 번도 동작하지 않습니다.

부수적으로 `AppleCredentialStateProvider.changes()`는 continuation을 배열에 append만 하고 `onTermination`에서 제거하지 않습니다(`Providers/AppleCredentialStateProvider.swift:40-53`).

### 1.2 S2는 스트림일 필요가 없습니다

`AsyncStream<Void>`는 값을 싣지 않는 신호이고, `AppRootFeature`는 이를 받아 `.effect(.deviceTokenRefreshed)` 하나만 보냅니다. 앱 수명 동안 발생 횟수는 0~수회입니다.

### 1.3 S3는 replay가 없어 구독 시점에 이벤트를 잃습니다

전달 경로가 4겹입니다.

```text
PushQuizGenerationOutcomeSource (Data)
  → GenerationOutcomeRepositoryAdapter (Composition, 재래핑 + Task 1)
  → ObserveGenerationOutcomes (Domain, 순수 위임)
  → 구독자 (Task 1 추가)
```

구독자는 `AppRootFeature`, `HomeFeature`, `QuizGenerationProgressFeature`, `GenerationCompletionReminderCoordinator`, `RepositoryCreationStateRepositoryAdapter` 5곳입니다.

`AsyncStream`은 구독 이후의 이벤트만 전달하므로, 푸시가 화면 진입 전이나 앱 비활성 구간에 도착하면 그 구독자에게는 사라집니다. 이 결함은 코드에 이미 두 가지 흔적을 남겼습니다.

- `QuizGenerationProgressFeature`는 `createLearningProject` 호출 **이전에** `observeGenerationOutcomes()`를 먼저 구독합니다(`QuizGenerationProgress/QuizGenerationProgressFeature.swift:187`). 구독 순서를 사람이 손으로 맞춰야 정확해지는 구조입니다.
- `HomeFeature`는 화면 진입 시점에 구독하므로(`Home/HomeFeature.swift:259-263`) 그 이전 이벤트를 받지 못하고, 이를 메우기 위해 `RepositoryCreationStateRepository`(UserDefaults, 15분 만료)와 `TrackGenerationProgress`(UserDefaults)라는 별도 상태 저장소 두 개가 존재합니다.

## 2. 문제 정의

1. 동작하지 않는 스트림 파이프라인이 Domain·Composition·Infrastructure 세 패키지에 걸쳐 유지 비용을 발생시킵니다.
2. 이벤트 전달 모델이 "구독 시점 이후만"이라는 성질을 갖는데, 소비자가 필요로 하는 것은 "지금 생성이 어떤 상태인가"라는 최신 상태입니다. 모델과 요구가 어긋나 보상 저장소가 두 개 생겼습니다.
3. 같은 생성 상태가 `GenerationProgress`, `RepositoryCreationState`, 푸시 이벤트 세 가지 표현으로 흩어져 정합성을 보장할 지점이 없습니다.

## 3. 요구사항

### FR-1 Apple 자격 증명 변경 관측 제거

- `AuthenticationRepository`에서 `authorizationChanges()`를 제거한다.
- `AppleCredentialStateProvider.changes()`와 `receiveRevocation(for:)`, 내부 `continuations` 저장소를 제거한다.
- `AuthenticationOutcomesUseCase`와 `AuthenticationOutcomes`를 제거하고, 그 안의 세션 복원·무효 세션 정리 로직 중 살아 있어야 하는 것은 `RestoreSession`으로 흡수한다.
- `AppComposition.authenticationOutcomes`, `AppRootFeature`의 해당 주입·Effect·`CancelID`·`EffectEvent.authenticationOutcomeReceived`를 제거한다.

### FR-2 자격 증명 상태를 폴링으로 대체

- 앱이 foreground로 전환될 때 `AuthenticationRepository.authorizationStatus()`를 1회 조회하고, 결과가 `.reauthenticationRequired`이면 기존 `AuthenticationOutcomes`가 수행하던 세션 정리와 동일한 처리를 수행한다.
- 이 조회의 트리거는 `AppRootFeature`의 기존 `applicationBecameActive` 액션을 사용한다.

### FR-3 기기 토큰 갱신을 콜백으로 대체

- `AppComposition.deviceTokenRefreshes`의 타입을 `@Sendable () -> AsyncStream<Void>`에서 갱신 콜백 등록 형태로 바꾼다.
- `AppRootFeature`는 스트림 순회 Effect 대신 콜백에서 `deviceTokenRefreshed`를 받는다.
- `AppRootFeature.init`의 `deviceTokenRefreshes` 기본값(`AsyncStream { $0.finish() }`)처럼 주입 누락을 런타임에 무해하게 만드는 기본값을 두지 않는다.

### FR-4 생성 상태를 replay 가능한 단일 관측 대상으로 통합

- 생성 상태의 정본을 소유하는 단일 타입을 둔다. 이 타입은 최신 상태를 보유하고, 구독 시 **현재 상태를 먼저 1회 전달한 뒤** 이후 변경을 전달한다.
- 관측 계약은 Domain이 소유하고, 상태 표현은 `GenerationProgress`와 생성 결과를 하나의 값으로 합친다.
- `RepositoryCreationStateRepository`와 `TrackGenerationProgressUseCase`가 각각 보유하던 상태를 이 단일 상태로 대체한다.
- 구독자는 구독 순서와 무관하게 동일한 결과를 얻어야 한다. `QuizGenerationProgressFeature`가 요청 전에 미리 구독하는 코드를 제거할 수 있어야 한다.

### FR-5 중간 재래핑 계층 축소

- `ObserveGenerationOutcomes`처럼 저장소 호출을 그대로 반환하는 위임 전용 UseCase를 남기지 않는다. (구체 통합 방침은 [UseCase 통합 요구사항](./usecase-consolidation-requirements.md)을 따른다.)
- 스트림이 패키지 경계를 넘을 때 값 변환이 필요 없는 구간에서는 `AsyncStream`을 다시 감싸지 않는다.

### FR-6 구독 해제 보장

- 스트림을 제공하는 모든 타입은 `continuation.onTermination`에서 자신의 구독 레지스트리에서 해당 구독을 제거해야 한다.
- 구독 해제 후 소스에 값을 넣어도 레지스트리가 증가하지 않음을 검증하는 테스트를 둔다.

## 4. 비범위

- Domain↔Data Adapter 경계 구조 변경 (현행 유지)
- 푸시 페이로드 스키마 변경
- 로컬 알림 문구·정책 변경 (→ [Composition 책임 정리 요구사항](./composition-responsibility-requirements.md))

## 5. 수용 기준

- [ ] `grep -rn "AsyncStream" sources/Projects --include=*.swift` 결과에서 프로덕션 스트림이 FR-4의 생성 상태 관측 하나로 줄어든다.
- [ ] 프로덕션 코드 경로에서 호출되지 않는 `public` 스트림 진입점이 없다.
- [ ] 생성 완료 푸시가 구독보다 먼저 도착한 상황을 재현하는 테스트가 있고, 구독자가 완료 상태를 관측한다.
- [ ] `HomeFeature`가 화면 재진입 시 이전에 놓친 생성 완료를 관측한다는 테스트가 있다.
- [ ] `QuizGenerationProgressFeature`에서 "요청 전에 먼저 구독"하는 순서 의존 코드가 사라진다.
- [ ] Apple 자격 증명 재인증 요구 상황에서 세션이 정리된다는 기존 보장이 `RestoreSession` 또는 FR-2 경로의 테스트로 유지된다.

## 6. 영향 범위

| 패키지 | 영향 |
| --- | --- |
| Domain | `AuthenticationRepository`, `AuthenticationOutcomes*`, `GenerationOutcomeRepository`, `GenerationProgressRepository`, `RepositoryCreationStateRepository`, `TrackGenerationProgress*`, `ObserveGenerationOutcomes*` |
| Data | `QuizGenerationOutcomeSource`, `PushQuizGenerationOutcomeSource`, `GenerationProgressStore` |
| Composition | `AuthenticationRepositoryAdapter`, `GenerationOutcomeRepositoryAdapter`, `GenerationProgressRepositoryAdapter`, `RepositoryCreationStateRepositoryAdapter`, `LearningProjectAssembly`, `AppComposition` |
| Infrastructure | `AppleCredentialStateProvider`, `FirebaseMessagingPushClient` |
| Feature | `HomeFeature`, `QuizGenerationProgressFeature`, `ProjectRegistrationRouterFeature`, `MainShellRouterFeature` |
| App | `AppRootFeature`, `AppRootView`(프리뷰 Noop 구현) |

**리스크** — FR-4는 생성 흐름 전체의 상태 정본을 바꾸므로 프로젝트 등록·홈 목록·리마인드 알림 세 흐름을 동시에 회귀 검증해야 합니다.

## 7. 작업 순서 제안

1. FR-1, FR-2 — 죽은 경로 제거. 다른 요구사항과 독립이며 즉시 회수됩니다.
2. FR-3 — 단독 적용 가능.
3. FR-6 — 남는 스트림에 선적용.
4. FR-4, FR-5 — 상태 모델 통합. 가장 크며 위 항목이 끝난 뒤 착수합니다.

## 관련 문서

- [아키텍처](../architecture.md)
- [UseCase 통합 요구사항](./usecase-consolidation-requirements.md)
- [Composition 책임 정리 요구사항](./composition-responsibility-requirements.md)
- [TCA 컨벤션](../conventions/tca/README.md)
