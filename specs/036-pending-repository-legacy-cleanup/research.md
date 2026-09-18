# 조사: 레거시 이관 코드 제거, 생성 대기 Repository, Infrastructure 의존의 Data 한정, Home 관찰 재개

**기능**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md) | **날짜**: 2026-09-17

이 문서는 기술 맥락의 미확정 항목과 명세가 계획 단계로 넘긴 결정을 해소한다. 코드 근거의 경로는
`sources/Projects/` 기준이다.

## R1. 생성 대기 Repository 계약의 모양

- 결정: Domain `LearningProject/Contracts/PendingGenerationRepository.swift`에 의도 단위 연산을 가진
  계약 하나를 둔다. 연산은 생성 대기 상태 조회, 생성 시작(중복이면 `false`), 프로젝트 식별자 연결,
  생성 결과 반영, 대기 해제(URL·프로젝트 식별자), 상태 변화 관찰, 완료 알림 대기 기록, 완료 알림 대기
  흡수다. 시그니처는 [contracts/pending-generation-repository.md](./contracts/pending-generation-repository.md)가
  정본이다.
- 근거:
  - 현재 `CreateLearningProject`의 "중복 확인 후 기록"은 `GenerationStateCoordinator` actor가 직렬화한다
    (`Domain/LearningProject/UseCases/TrackGeneration/GenerationStateCoordinator.swift:43-52`). 계약이
    `currentState()`/`record(_:)`만 가지면 조회와 기록 사이에 같은 URL의 두 요청이 모두 통과할 수 있다.
    의도 단위 연산은 구현이 조회·변환·기록을 한 번에 직렬화하게 한다.
  - 명세 FR-004·FR-005·FR-006은 생성 요청과 목록 조회가 이 계약을 대기 확인의 유일한 경계로 쓰라고
    요구한다.
  - 명세 035 FR-020과 D-ARCH-004는 Domain 계약에 `Store` 접미어와 `load`/`save` 연산 이름을 금지하고
    `Repository` 접미어를 허용한다.
- 검토한 대안:
  - `currentState()`/`record(_:)` 유지: 동시 생성 요청의 중복 차단이 깨져 기각.
  - 변환 클로저를 받는 `update(_:)` 연산: Domain 규칙이 클로저로 경계를 넘고 테스트 더블이 규칙을
    재현해야 해 기각.
  - `TrackGeneration`을 계속 게이트웨이로 사용: 명확화 답변(Repository를 Pending Check Gateway로 사용)과
    FR-006에 어긋나 기각.

## R2. 상태 전이 규칙, 만료 정리, 직렬화의 위치

- 결정:
  - 상태 전이 규칙은 기존 Domain 모델(`GenerationState.beginning`, `attachingProjectID`, `finishing`,
    `removing`, `purgingExpired`)에 그대로 둔다.
  - 조회·변환·기록의 직렬화는 Data 저장 actor `LocalPendingGenerationStore`의 `modifyState(_:)`가
    담당한다(DTO 단위 변환 클로저, actor 격리 안에서 실행).
  - Composition `PendingGenerationRepositoryAdapter`는 DTO↔모델 변환과 Domain 모델 메서드 호출만 하며,
    생성 시 `GenerationWaitPolicy`와 `now`를 받아 조회·시작 전에 만료 기록을 정리한다.
- 근거:
  - 현재 `purged()`는 모든 공개 연산 앞에서 만료 기록을 제거한다(`GenerationStateCoordinator.swift:112-114`).
    같은 의미를 유지하려면 Repository 조회·시작이 정리된 상태를 기준으로 해야 한다.
  - Data는 Domain에 의존할 수 없으므로(아키텍처 3.1) 모델 규칙을 Data가 호출할 수 없다. 규칙은 Domain,
    원자성은 저장 actor, 변환은 Adapter라는 기존 책임 분담(아키텍처 3.3)을 유지한다.
  - 생성 상태 조회는 매번 App Group 저장소를 다시 읽는다. 현재 코디네이터는 시작 시 한 번만 읽어
    실행 중인 앱이 Share Extension의 기록을 보지 못한다.
- 검토한 대안:
  - 정리·전이를 Adapter에 새로 구현: Domain 규칙 중복으로 기각.
  - Domain 내부 actor가 계약을 구현: Domain이 스스로 구현하는 계약은 경계가 아니어서 추상화 컨벤션
    근거 A에 맞지 않아 기각.

## R3. 상태 변화 관찰(AsyncStream)의 위치

- 결정: `AsyncStream` 사용은 유지한다(명세에서 삭제 요구를 되돌림). 여러 구독자에게 상태를 나눠 보내는
  책임은 `GenerationStateCoordinator`에서 `LocalPendingGenerationStore`로 옮긴다. 저장 actor는 기록이
  성공할 때마다 새 상태를 구독자에게 보낸다. 구독자 등록과 해제는 `Mutex`로 보호되어 `AsyncStream`
  생성 클로저 안에서 동기로 끝난다(`Data/LearningProject/Sources/PushQuizGenerationOutcomeSource.swift:15-23`과
  같은 방식). Adapter는 DTO 스트림을 모델 스트림으로 변환하고 만료 정리를 적용한다.
- 근거:
  - 생성 요청(`CreateLearningProject`)이 Repository로 직접 기록해도 App 루트·Home·생성 진행 화면·완료
    알림 예약이 변화를 받아야 한다(FR-008). 기록 주체와 알림 주체가 같아야 누락이 없다.
  - 현재 `states()`는 구독자 등록을 별도 `Task`로 미뤄 등록 전 변경을 놓치거나 해제 후 등록되는 경합이
    있다(`GenerationStateCoordinator.swift:30-41`). 동기 등록으로 옮기면 함께 해소된다.
  - 앱과 Share Extension은 프로세스가 달라 스트림은 같은 프로세스 안의 기록만 전달한다. 다른 프로세스
    기록은 다음 조회에서 반영된다(명세 예외·경계 사례).
- 검토한 대안:
  - 코디네이터 유지 후 Repository 기록 뒤 코디네이터에 알림: 기록 경로가 둘이 되어 FR-006과 충돌해 기각.
  - 파일 시스템·Darwin notification으로 프로세스 간 알림: 명세 범위 밖이라 기각.

## R4. TrackGeneration과 ScheduleGenerationReminder의 역할

- 결정:
  - `TrackGenerationUseCase` 공개 연산(`begin`, `attachProjectID`, `end(githubRepoURL:)`, `end(projectID:)`,
    `current()`, `states()`)은 유지해 Feature·App 변경을 Home 관찰 수정으로 한정한다.
  - `TrackGeneration`은 `PendingGenerationRepository`와 `GenerationOutcomeRepository`를 받아, 연산은 Repository에
    위임하고 최초 사용 시 생성 결과 관찰을 한 번 시작해 결과를 `finishGeneration`으로 반영한다.
    `GenerationStateCoordinator`는 결과 관찰 시작을 한 번만 보장하는 역할로 축소하거나 `TrackGeneration`
    내부로 흡수한다.
  - `CreateLearningProject`와 `FetchLearningProjects`는 `trackGeneration` 대신 `PendingGenerationRepository`를
    받는다.
  - `ScheduleGenerationReminder`는 `pendingReminders: PendingGenerationReminders?` 대신
    `PendingGenerationRepository`를 받아 `drainReminderProjectIDs()`로 흡수한다.
- 근거:
  - App 루트·Home·생성 진행 화면은 `TrackGenerationUseCase`를 직접 받는다(조사: `AppRootFeature.swift:175`,
    `HomeFeature.swift:275`, `QuizGenerationProgressFeature.swift:214`). UseCase API를 바꾸면 Feature·App·
    테스트 더블 3종(`TrackGenerationUseCaseMock`, `StubTrackGenerationUseCase` 2개)이 함께 바뀌어 범위가
    커진다.
  - 생성 결과 반영은 푸시가 도착한 프로세스에서 한 번만 일어나야 하므로 한 번만 시작하는 보장이 필요하다.
- 검토한 대안: `TrackGenerationUseCase` 제거 후 소비처가 Repository를 직접 사용: Feature가 Domain 계약을
  직접 받게 되어 Feature 규칙(UseCase 경유)에 어긋나 기각.

## R5. Share Extension 완료 알림 대기 기록 경로

- 결정: `GenerationReminderAssembly.makePendingReminderEnqueue(sharedDefaults:)`를 제거한다.
  `ShareExtensionComposition.enqueueGenerationReminder`는 Share Extension용 `LearningProjectAssembly`가 만든
  `PendingGenerationRepository` 인스턴스의 `enqueueReminder(projectID:)`에 연결한다. 공개 프로퍼티 이름과
  클로저 타입(`@Sendable (String) async -> Void`)은 유지해 App·Feature 변경을 만들지 않는다.
- 근거: FR-007은 Data 저장 구현을 Domain 계약 없이 호출하는 경로를 금지한다. Share Extension의 기존
  테스트(`Composition/Tests/ShareExtension/ShareExtensionCompositionTests.swift:43`)가 이 경로를 검증한다.
- 검토한 대안: 새 Domain UseCase 추가: 권한 확인은 이미 Feature에서 하고 기록은 한 연산이라 UseCase가
  단순 위임이 되어 기각.

## R6. 저장 위치와 형식 호환

- 결정: 저장 좌표를 바꾸지 않는다.
  - 생성 진행 기록: namespace `com.nexters.hytime.gitit.sharedSession`, key `generationState`,
    값 `GenerationStateDTO` JSON.
  - 완료 알림 대기: 같은 namespace, key `pendingGenerationReminders`, 값 `[{projectID, requestedAt}]` JSON,
    상한 32.
  - App Group 저장소를 만들 수 없으면 기록은 무시하고 조회는 빈 값을 돌려준다. 현재 생성 진행 기록이
    `.standard`로 대체 저장하던 경로(`LearningProjectAssembly.swift:35`의 `sharedDefaults ?? .standard`)는
    제거한다.
- 근거: FR-003·FR-009·FR-023. `UserDefaultsStore`는 `"<namespace>.<key>"` 키에 JSON `Data`를 저장한다
  (`Infrastructure/Storage/Stores/UserDefaultsStore.swift:17-50`). 좌표 상수 테스트
  (`Data/Tests/LearningProject/Layouts/GenerationReminderStorageCoordinateTests.swift`,
  `Data/Tests/Authentication/Layouts/SessionStorageCoordinateTests.swift`)로 고정한다.
- 검토한 대안: 두 값을 하나의 key로 합침: 이전 버전 값을 읽으려면 변환 코드가 필요해 FR-009와 충돌해 기각.
- 알려진 영향: App Group을 만들 수 없던 기기에서 `.standard`에 남은 생성 진행 기록은 읽지 않는다. 정상
  배포 구성에서는 App Group이 항상 존재하므로 영향이 없다고 본다.

## R7. 이관 코드 제거 범위

- 결정: 다음을 제거한다.
  - Data: `LearningProject/Stores/GenerationStateMigration.swift`,
    `LearningProject/DTOs/GenerationState/LegacyGenerationProgressDTO.swift`,
    `LearningProject/DTOs/GenerationState/LegacyRepositoryCreationStateDTO.swift`,
    `Authentication/Migrations/SessionStorageMigration.swift`(폴더가 비면 폴더도), 테스트
    `Tests/LearningProject/Stores/GenerationStateMigrationTests.swift`,
    `Tests/Authentication/Migrations/SessionStorageMigrationTests.swift`.
  - `LocalGenerationStateStore`의 `migration` 인자와 `hasAttemptedMigration` 상태(이 타입은 U3에서
    `LocalPendingGenerationStore`로 대체된다).
  - Infrastructure: `Authentication/Keychain/Stores/AppGroupKeychainStore.swift`의 `makeLegacy()`.
  - Composition: `AuthenticationAssembly.migrateSessionKeychain(sharedKeychainStore:)`와
    `AppComposition.swift:162` 호출, `LearningProjectAssembly`의 `GenerationStateMigration` 조립.
  - 문서: `docs/conventions/file-vocabulary/shape-vocabulary.md` Data 행의 `Migrations/`,
    `docs/review/domain-data-infra-design-review.md`의 이관 항목 설명.
- 근거: FR-011~FR-013, SC-004.
- 검토한 대안: 이관 코드를 유지하되 호출만 제거: 사용하지 않는 공개 타입이 남아 기각.

## R8. Data의 기술 재구현 제거 방식

- 결정:
  - `Data/LearningProject/Models/HTTPMethod.swift`, `AuthenticationEndpoint.Method`, `MemberEndpoint.Method`,
    `GitHubRepositoryRequest.method` 문자열, 각 Remote의 method 변환 함수를 제거한다.
  - Endpoint와 요청 값 타입은 서비스 경로·query·서비스 헤더 값만 공개하고, 전송 방식(method)은 Data 내부
    확장(`internal`)에서 Infrastructure `HTTPMethod`로 직접 정의한다. 예: `AuthenticationEndpoint`의
    `internal var transportMethod: InfrastructureNetworkClient.HTTPMethod`.
  - 요청 헤더 조립(`AuthorizedRequestHeaders`, `AuthenticationEndpoint.headers(accessToken:)`,
    `MemberEndpoint.headers(accessToken:)`)은 공개 선언에서 내리고 Remote 내부에서 `HTTPHeaders`로 바로
    만든다. 서비스 고유 헤더 값(GitHub `Accept`·`X-GitHub-Api-Version`)은 Data 상수로 남긴다.
  - Endpoint 테스트의 method 단언은 Remote 테스트의 전송 요청 단언으로 대체하고, 기대 method·경로·
    query·헤더 값은 바꾸지 않는다.
- 근거: FR-014~FR-016, SC-005·SC-006, 점검 결과 DS-05·OK-12. 조사 결과 Remote 테스트가 이미
  `HTTPTransportRequest`의 method·path·query·headers를 단언한다
  (`Data/Tests/Member/Remotes/MemberRemoteTests.swift`, `Data/Tests/LearningProject/Remotes/*`).
- 검토한 대안: Endpoint 공개 프로퍼티를 Infrastructure `HTTPMethod`로 교체: Data 공개 선언에 Infrastructure
  타입이 노출되어 FR-020과 충돌해 기각.
- 정리 대상: `ProjectRemote`는 `ProjectEndpoint`를 쓰지 않고 요청을 직접 만든다. `QuizGenerationEndpoint`는
  테스트만 사용한다. 이 기능은 method 표현 제거에 필요한 범위만 바꾸고 미사용 Endpoint 정리는 하지 않는다.

## R9. Data 기술 능력 역할 Protocol의 소유 target과 이름

- 결정: 새 Data target 두 개를 둔다.
  - `DataShared`(`sources/Projects/Data/Shared/`): 여러 Data target이 쓰는 기술 능력 계약과 실제 구현.
    - `KeyValueStorage`: 키 기반 값 저장(명확화 답변 A). 실제 구현은 `UserDefaultsStore`를 감싼다.
    - `SecureValueStorage`: 보안 저장. 실제 구현은 `KeychainStore`를 감싼다.
    - `RequestTransport`: 요청 전송. 실제 구현은 `URLSessionTransport`를 감싼다.
    - 생성 진입점 `StorageFactory`·`RequestClientFactory`(`Factories/`)가 App Group·기기 저장소, 공유
      access group, 응답 제한 시간을 고른다.
  - `DataNotification`(`sources/Projects/Data/Notification/`): 알림 권한·예약과 푸시 수신.
    - `LocalReminderNotifier`: 알림 권한 확인·요청과 예약. 실제 구현은 `LocalNotificationAuthorizationClient`를
      감싼다.
    - `RemoteMessageReceiver`: 푸시 토큰 조회·갱신 관찰과 APNs 토큰 전달. 실제 구현은 `PushMessagingClient`를
      감싼다.
    - `NotificationAppDelegate`: App이 `@UIApplicationDelegateAdaptor`로 쓰는 Data 소유 클래스. 내부에
      Infrastructure `PushMessagingAppDelegate`를 두고 `UIApplicationDelegate` 콜백을 위임한다.
  - Apple 로그인 제공자(`AppleAuthorizationProvider`, `AppleCredentialStateProvider`)는 대체 주입 지점이 없어
    Protocol 없이 `DataAuthentication`의 concrete 타입(예: `AppleSignInRemote`) 내부로 옮긴다.
  - 최종 이름은 [contracts/data-capability-contracts.md](./contracts/data-capability-contracts.md)가 정본이다.
- 근거:
  - 명확화 답변 A(Q1·Q2): Data가 기술 이름 없는 역할 Protocol을 정의하고 Infrastructure를 감싼 실제 구현과
    공개 생성 진입점을 Data에 둔다.
  - 현재 Data target끼리는 의존이 없고 공유 target도 없다. 네 기능 target이 같은 계약을 쓰려면 공유
    target이 필요하다(조사: `DataModuleName.swift`).
  - 알림·푸시는 `DataLearningProject`(알림 예약), `CompositionApp`(푸시·앱 델리게이트),
    `CompositionShareExtension`(권한 확인)에서 함께 쓰여 기능 target 하나에 넣으면 교차 의존이 생긴다.
  - D-ARCH-004와 네이밍 컨벤션(`naming/protocol-contract.md` L5·L8, `naming/examples.md` L16)은 Data 공개
    이름에 HTTP·Keychain·UserDefaults·URLSession·Firebase를 금지한다.
- 추가 결정(작업 분해 중 확정):
  - Data target 간에 Infrastructure 타입을 주고받는 선언(`RequestClientFactory.makeClient`,
    `RequestTransportBridge`)은 `package` 접근 수준으로 두고, Data target에 `-package-name GitItData`를 설정한다.
    `public`이면 Data 공개 선언에 Infrastructure 타입이 드러나고(FR-020), `internal`이면 기능 target이 쓸 수 없다.
  - Apple 로그인 Data 타입 이름은 `AppleSignInSource`·`AppleSignInCredential`·`AppleSignInState`·
    `AppleSignInError`로 한다. 서비스 자체를 가리키는 `Apple`은 D-ARCH-004 예외이고, `Source`는 Data 형태 어휘
    `Sources/`와 맞는다.
  - `CompositionShared`는 `HTTPClientFactory.swift` 하나만 가져 U6 뒤 소스가 없는 target이 되므로 제거한다.
- 검토한 대안:
  - Infrastructure 계약을 Data가 typealias로 재공개: Data 공개 선언에 Infrastructure 타입이 드러나 기각.
  - Data target 간 공유 선언을 `@_spi` 공개로 둠: 비공식 기능이고 공개 선언 검사를 우회하는 형태라 기각.
  - 기능 target마다 계약 복제: 같은 계약이 4벌 생겨 기각.
  - 알림·푸시를 `DataShared`에 포함: `DataShared`가 UIKit·Firebase 경로에 의존하게 되어 저장·전송만 쓰는
    target의 의존이 커져 기각.

## R10. RequestTransport 요청 값에 method를 두지 않는 방식

- 결정: `RequestTransport`의 요청 값 `TransportRequest`는 `url`, `headerFields`, `body`만 공개하고 전송 방식을
  공개하지 않는다. 푸시 수신(`RemoteMessageReceiver`)은 현재 대체 주입 지점이 없으므로 Composition 공개 API에
  주입 인자를 추가하지 않는다(명세 FR-021). 실제 구현은 Data 내부에서 Infrastructure 요청을 그대로 전달한다. Composition 테스트
  더블은 URL 경로별 응답 스크립트와 요청 기록(`url`, `body`)만 제공한다.
- 근거: FR-014·FR-015(Data 공개 선언에 HTTP method 개념 금지)와 Q2 답변(전송 대체 주입 유지)을 함께
  만족한다. 조사 결과 Composition Adapter 테스트는 응답 스크립트와 경로 확인에 `RecordingHTTPTransport`를
  쓰며, method 단언은 Data Remote 테스트가 담당한다.
- 검토한 대안: `TransportRequest.method: String` 공개: SC-005와 충돌해 기각.
- 후속 확인: 구현 시 Composition 테스트 12개 파일에서 method 단언이 발견되면 해당 단언을 Data Remote
  테스트로 옮긴다(tasks에서 파일별로 확인).

## R11. Infrastructure 의존 강제와 추상화 컨벤션

- 결정:
  - `tools/package-dependencies/config/allowed-dependencies`의 `Composition: Domain Data Infrastructure`를
    `Composition: Domain Data`로 바꾸고, `docs/architecture.md` 3.1 표·`docs/assets/package-dependency-graph.dot`
    (L46 `Composition -> Infrastructure`)·7.1 금지 목록에 `Composition → Infrastructure`, `App → Infrastructure`를
    함께 반영한다. 검사기는 3.1 표와 설정의 일치를 확인하므로 같은 단위에서 바꾼다.
  - `tools/package-dependencies/tests/test-package-dependencies.sh` fixture(L31·L42 규칙 복사,
    L105 `.fromInfrastructure`, L238-240 Composition import)를 새 규칙으로 갱신하고, Composition의
    Infrastructure import가 `import-package` 위반으로 보고되는 회귀 사례를 추가한다.
  - `docs/conventions/abstraction/protocol-criteria.md`에 "Composition이 Infrastructure를 볼 수 없어 Data가
    기술 능력 계약을 소유하고 Composition·테스트가 대체 구현을 주입하는 경우"를 근거로 추가하고,
    `test-double-injection.md` 표(L18-23)와 `structure-baseline.md` 3.1(L55-56)을 새 계약으로 갱신한다.
- 근거: FR-018·FR-019·FR-024, SC-007·SC-008. 조사 결과 검사기는 Tuist manifest의 `.from<패키지>`와 Swift
  import를 모두 판정하고 3.1 표와 설정의 일치도 확인한다(`tools/package-dependencies/core/judge.sh` L85-175).
- 검토한 대안: 설정만 바꾸고 추상화 컨벤션은 그대로 둠: 현재 컨벤션은 "테스트 더블은 Protocol 근거가
  아니다"(`test-double-injection.md` L5-6)라서 R9 계약이 컨벤션 위반이 되어 기각.

## R12. Home 생성 결과 관찰 재개

- 결정:
  - `HomeFeature.State.generationOutcomeObservation`과 `.idle` 조건 분기를 제거한다.
  - `.view(.task)`마다 관찰 Effect를 `.cancellable(id: CancelID.generationOutcomes, cancelInFlight: true)`로
    시작한다. 화면이 사라지면 `HomeScreen`의 `.task { await send(.task).finish() }` 취소로 Effect가 끝나고,
    다시 나타나면 새 관찰이 시작된다. 보이는 동안 `.task`가 다시 오면 이전 관찰을 취소하고 하나만 유지한다.
  - 사라진 동안 끝난 결과는 구독 직후 전달되는 현재 상태로 반영되고, 이미 반영한 결과는
    `appliedOutcomeProjectIDs`(`HomeFeature.swift:192-198`)가 중복 처리를 막는다.
- 근거: FR-025·FR-026, SC-012. TCA 컨벤션 `tca/effect/cancellation.md` 표(L7-13)는 장기 관찰에
  `cancelInFlight`와 소유 State 제거 시 취소를 허용하고, `tca/state/shape.md` L5-6은 Effect 실행 여부를
  별도 상태 플래그로 중복 관리하지 않도록 한다.
- 검토한 대안:
  - `onDisappear` Action을 추가해 상태를 `.idle`로 되돌림: 화면 lifecycle Action과 상태 플래그가 늘고
    `.task` 취소와 순서 경합이 생겨 기각.
  - 관찰을 App 루트로 올림: Home 소유 관심사를 이동해 범위가 커져 기각.
- 테스트 영향: `Feature/Tests/Home/Home/HomeFeatureGenerationOutcomeTests.swift:12`의 "재호출 시 중복 구독하지
  않는다"는 "재호출 시 이전 관찰을 대체해 하나만 유지한다"로 기대 동작이 바뀐다. `StubTrackGenerationUseCase`의
  `establishedSubscriptionCount()`로 동시 구독 수를 검증한다.

## R13. 실행 순서와 integration unit

- 결정: 아키텍처 3.1 의존 표(`App → Feature, Composition, Domain`, `Composition → Domain, Data, Infrastructure`,
  `Feature → Domain, UI`, `Data → Infrastructure`)의 위상 순서 Infrastructure → Domain → Data → Composition →
  Feature → App을 따르되, 공개 API 이전이 함께 compile되어야 하는 단위는 integration unit으로 묶는다.
  단위 구성은 [plan.md](./plan.md)의 "실행 단위"가 정본이다.
- 근거: Constitution 원칙 7. Data 공개 initializer 변경은 Composition 조립 코드와 함께 바뀌어야 compile되고,
  허용 의존성 설정은 아키텍처 3.1 표와 함께 바뀌어야 검사기가 통과한다.
