# 계약: Data 기술 능력 역할 Protocol과 생성 진입점

**요구사항**: FR-014~FR-023, SC-005·SC-007·SC-009~SC-011 | **결정**: [research.md](../research.md) R8~R10

Infrastructure에 의존할 수 있는 프로젝트 target을 Data로 한정하면서, Composition·앱·테스트가 기술 구현을
바꿔 끼우는 지점을 Data 소유 계약으로 옮긴다. 이름에는 HTTP, Keychain, UserDefaults, URLSession, Firebase,
APNs 같은 기술·공급자 이름을 쓰지 않는다(D-ARCH-004). 서비스 자체를 가리키는 Apple·GitHub는 예외다.

## 1. 새 Data target

| Target | 소스 폴더 | 의존 | 테스트 target |
|--------|-----------|------|---------------|
| `DataShared` | `sources/Projects/Data/Shared/` | `InfrastructureNetworkClient`, `InfrastructureAuthentication`, `InfrastructureStorage` | `DataSharedTests` (`Data/Tests/Shared/`) |
| `DataNotification` | `sources/Projects/Data/Notification/` | `InfrastructureLocalNotification`, `InfrastructurePushMessaging` | `DataNotificationTests` (`Data/Tests/Notification/`) |

- 기존 Data target 의존 변경:
  - `DataAuthentication`, `DataMember`, `DataExternalRepository`, `DataLearningProject`, `DataLegalConsent`는
    `DataShared`에 의존한다.
  - Infrastructure 직접 의존은 내부 구현에 필요한 것만 남긴다. 예: `HTTPClient` 응답 처리를 쓰는 Remote는
    `InfrastructureNetworkClient`를 유지할 수 있다.
- Data target 간에 Infrastructure 타입(`HTTPClient` 등)을 주고받는 선언은 `public`이 아니라 `package` 접근
  수준을 쓴다. 이를 위해 `sources/Tuist/ProjectDescriptionHelpers/Target+Module.swift`의 `module`에 선택 인자
  `packageName`을 추가하고, 모든 Data 프로덕션·테스트 target에 `-package-name GitItData`를 설정한다.
- Data 패키지 안의 target 간 의존은 같은 패키지 의존이라 허용 의존성 검사 대상이 아니다
  (`tools/package-dependencies/core/rules-policy.sh` L9-19).
- manifest: `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`에 target을 추가한다.
  `tools/package-dependencies/config/source-roots`와 `AllTestsScheme.swift`에도 추가한다.

## 2. `DataShared` 계약

### 2.1 키 기반 값 저장

```swift
public protocol KeyValueStorage: Sendable {
    func value<Value: Codable & Sendable>(_ type: Value.Type, forKey key: String) async -> Value?
    func setValue<Value: Codable & Sendable>(_ value: Value, forKey key: String) async
    func removeValue(forKey key: String) async
    func removeAllValues() async
}
```

- 인스턴스는 하나의 namespace에 묶인다. 실제 키는 `"<namespace>.<key>"`, 값은 JSON이다(현재
  `UserDefaultsStore` 형식과 같음).
- 실제 구현(`internal`)은 Infrastructure `UserDefaultsStore`를 감싼다.

### 2.2 보안 저장

```swift
public protocol SecureValueStorage: Sendable {
    func data(forKey key: String) throws(SecureValueStorageError) -> Data?
    func setData(_ data: Data, forKey key: String) throws(SecureValueStorageError)
    func removeData(forKey key: String) throws(SecureValueStorageError)
}

public enum SecureValueStorageError: Error, Equatable, Sendable {
    case unavailable
    case accessDenied
    case unexpected
}
```

- 인스턴스는 하나의 namespace에 묶인다. 실제 구현(`internal`)은 Infrastructure `KeychainStore`를 감싸고
  `KeychainStoreError`를 `SecureValueStorageError`로 바꾼다.
- 정확한 오류 case는 구현 시 `KeychainStoreError` case와 Composition Adapter의 현재 오류 변환
  (`AuthenticationRepositoryAdapter.swift:54`, `LoginSessionRepositoryAdapter.swift:48-89`)을 대조해 확정하며,
  Domain 오류 결과가 바뀌지 않아야 한다.

### 2.3 요청 전송

```swift
public protocol RequestTransport: Sendable {
    func send(_ request: TransportRequest) async throws(RequestTransportError) -> TransportResponse
}

public struct TransportRequest: Equatable, Sendable {
    public let url: URL
    public let headerFields: [String: String]
    public let body: Data?
}

public struct TransportResponse: Equatable, Sendable {
    public init(statusCode: Int, headerFields: [String: String] = [:], body: Data)
}

public enum RequestTransportError: Error, Equatable, Sendable {
    case cancelled
    case timedOut
    case connectionFailed
}
```

- 실제 구현(`internal`)은 Infrastructure `URLSessionTransport`를 감싼다. 테스트 더블을 주입하면 Data 내부
  어댑터가 `HTTPTransport`로 연결한다.
- 전송 방식(method)은 공개하지 않는다(R10).

### 2.4 생성 진입점

위치: `sources/Projects/Data/Shared/Factories/`

```swift
public enum StorageLocation: Sendable {
    case appGroup
    case device
}

public enum StorageFactory {
    public static func keyValueStorage(namespace: String, location: StorageLocation) -> any KeyValueStorage
    public static func secureValueStorage(namespace: String, location: StorageLocation) -> any SecureValueStorage
}

public enum RequestClientFactory {
    public static let defaultResponseTimeout: Duration
    package static func makeClient(
        baseURL: URL,
        transport: (any RequestTransport)?,
        responseTimeout: Duration,
    ) -> HTTPClient
}

package struct RequestTransportBridge: HTTPTransport {
    package init(transport: any RequestTransport)
}
```

- `.appGroup` 키 기반 값 저장은 App Group 저장소를 만들 수 없으면 기록을 무시하고 조회에 `nil`을 돌려주는
  구현을 반환한다.
- `.appGroup` 보안 저장은 공유 access group(`AppGroupKeychainStore.accessGroup`)을 사용한다.
- App Group 식별자와 access group 상수는 이 기능에서 Infrastructure에 그대로 둔다(점검 결과 DS-10은 범위 밖).
- Remote 생성 인자는 `HTTPClient` 대신 `baseURL: URL`, `transport: (any RequestTransport)?`,
  `responseTimeout: Duration`이다. `HTTPClient`는 Data 내부에서 `RequestClientFactory.makeClient`로 만든다.
- 기존 `init(client: HTTPClient, ...)`는 `internal`로 남겨 Data Remote 테스트가 `@testable`로 Infrastructure
  `HTTPTransport` 더블을 계속 주입한다.
- 파일 위치: `Data/Shared/Remotes/RequestTransportBridge.swift`, `Data/Shared/Factories/RequestClientFactory.swift`.

## 3. `DataNotification` 계약

```swift
public protocol LocalReminderNotifier: Sendable {
    func requestAuthorization() async -> ReminderAuthorizationStatus
    func isAuthorized() async -> Bool
    func schedule(_ reminder: ReminderNotification, at date: Date) async
    func cancel(identifier: String) async
}

public enum ReminderAuthorizationStatus: Equatable, Sendable {
    case authorized
    case declined
    case previouslyDenied
}

public struct ReminderNotification: Equatable, Sendable {
    public init(identifier: String, title: String, body: String)
}

public protocol RemoteMessageReceiver: Sendable {
    func registrationToken() async throws -> String
    func registrationTokenRefreshes() -> AsyncStream<String>
    func setDeviceToken(_ token: Data)
}

@MainActor
public final class NotificationAppDelegate: NSObject, UIApplicationDelegate {
    public func configure(_ callbacks: NotificationAppCallbacks)
}

public struct NotificationAppCallbacks: Sendable {
    public init(
        forwardDeviceToken: @escaping @Sendable (Data) -> Void,
        ingestRemoteMessagePayload: @escaping @Sendable ([String: String]) async -> Void,
    )
}

public enum NotificationFactory {
    public static func localReminderNotifier() -> any LocalReminderNotifier
    public static func remoteMessageReceiver() -> any RemoteMessageReceiver
}
```

- 연산 목록은 현재 Infrastructure `NotificationAuthorizationClient`(`requestAuthorization`, `isAuthorized`,
  `present`, `schedule`, `cancel`)와 `PushMessagingClient`, `PushNotificationCallbacks` 중 Composition이 실제로
  쓰는 것만 옮긴다. 구현 시 Composition 사용처(`GenerationReminderSchedulerAdapter.swift`,
  `NotificationAuthorizationAdapter.swift`, `AppComposition.swift:52-86·211-230`)와 대조해 확정한다.
- `NotificationAppDelegate`는 Infrastructure `PushMessagingAppDelegate`를 내부에 두고 콜백을 위임한다.
  Data가 `UIKit`을 import하는 것은 플랫폼 앱 델리게이트 타입을 소유하기 위한 예외로 기록한다
  ([plan.md](../plan.md) 복잡성 추적).
- Composition `App/Factories/PushNotificationAppDelegate.swift` typealias는 `NotificationAppDelegate`를
  가리키도록 바뀐다. App의 `@UIApplicationDelegateAdaptor(PushNotificationAppDelegate.self)`는 그대로 둔다.

## 4. 기존 Data 공개 initializer 전환

| 타입 | 변경 전 | 변경 후 |
|------|---------|---------|
| `AuthenticationRemote`, `MemberRemote`, `ProjectRemote`, `LearningSetRemote`, `AnswerRemote`, `BookmarkRemote` | `client: HTTPClient` | `baseURL: URL`, `transport: (any RequestTransport)?`, `responseTimeout: Duration` |
| `ExternalRepositoryRemote` | `client: HTTPClient` | 같은 전환(인증 없음) |
| `SessionRecordStorageCoding`, `AppleIdentityStore`, `LocalDeviceIdentifierStore` | `keychainStore: KeychainStore` | `storage: any SecureValueStorage` |
| `SharedSessionStateMarkerCoding` | `userDefaults: UserDefaults` | `storage: any KeyValueStorage` |
| `LocalPolicyConsentStore` | `store: UserDefaultsStore<[PolicyConsentRecordDTO]>` | `storage: any KeyValueStorage` |
| `LocalPendingGenerationStore`(신규) | — | `storage: any KeyValueStorage` |
| `AppleIdentityStorageLayout.namespace`, `SessionStorageLayout.namespace`, `LocalDeviceIdentifierStore.namespace` | `KeychainNamespace` | `String` |

- 저장 좌표(namespace·key)와 값 형식은 바꾸지 않는다([data-model.md](../data-model.md)).
- Apple 로그인은 Protocol 없이 `DataAuthentication` concrete 타입이 `AppleAuthorizationProvider`·
  `AppleCredentialStateProvider`를 내부에서 만든다. Composition `AuthenticationRepositoryAdapter`는 이 타입과
  Data 오류만 사용한다.

| Data 공개 타입 | 위치 | 역할 |
|----------------|------|------|
| `AppleSignInSource` (actor) | `Data/Authentication/Sources/AppleSignInSource.swift` | Apple 인증 요청과 자격 상태 조회. 연산은 `AuthenticationRepositoryAdapter`의 현재 사용처와 대조해 확정 |
| `AppleSignInCredential` | `Data/Authentication/Models/AppleSignInCredential.swift` | 사용자 식별자, identity token |
| `AppleSignInState` | `Data/Authentication/Models/AppleSignInState.swift` | Composition이 쓰는 자격 상태 case만 |
| `AppleSignInError` | `Data/Authentication/Errors/AppleSignInError.swift` | 현재 `AppleAuthorizationError` 변환 분기와 같은 Domain 오류를 낼 수 있는 case |

## 5. Composition 공개 API 전환

| 공개 API | 변경 전 인자 | 변경 후 인자 |
|----------|--------------|--------------|
| `AppComposition.live` | `keychainStore: KeychainStore`, `transport: (any HTTPTransport)?` | `secureStorage: (any SecureValueStorage)?`, `transport: (any RequestTransport)?` |
| `ShareExtensionComposition.live` | `keychainStore`, `sharedDefaults: UserDefaults?`, `localNotificationClient`, `transport` | `secureStorage`, `sharedStorage: (any KeyValueStorage)?`, `reminderNotifier: (any LocalReminderNotifier)?`, `transport` |
| `AuthenticationAssembly.init` | `keychainStore`, `policyConsentStore`, `sharedDefaults`, `transport`, `responseTimeout` | Data 계약 타입과 `Duration`만 사용 |
| `SessionAvailabilityAssembly.init`, `CurrentSessionRepositoryAdapter.init`, `DeviceIdentifierRepositoryAdapter.init`, `MemberAssembly.makeRegisterCurrentDevice` | `keychainStore: KeychainStore` | `secureStorage: any SecureValueStorage` |
| `ExternalRepositoryAssembly.init`, `LearningProjectAssembly.init`, `MemberAssembly.init` | `transport: (any HTTPTransport)?`, `responseTimeout = HTTPClient.defaultResponseTimeout`, `sharedDefaults` | `transport: (any RequestTransport)?`, `responseTimeout = RequestClientFactory.defaultResponseTimeout`, `sharedStorage` |
| `GenerationReminderAssembly.init` | `localNotificationClient`, `pendingReminderCoding` | `reminderNotifier: (any LocalReminderNotifier)?`, `pendingGenerations` |
| `CompositionShared` `makeHTTPClient` | 공개 전역 함수 | 제거 |
| `CompositionShared` target | `Composition/Shared/Factories/HTTPClientFactory.swift` 하나만 가진 target | 소스가 없어지므로 target, 의존, `source-roots` 행, `docs/package-rules/composition.md` 표 행을 제거 |

- 인자가 `nil`이면 Data 생성 진입점의 실제 구현을 사용한다. 기본값 식에 Infrastructure 타입을 쓰지 않는다.
- 최종 인자 이름은 구현 시 Composition 공개 표면 테스트
  (`Composition/Tests/App/Assemblies/AppCompositionPublicSurfaceTests.swift`)와 함께 확정한다.

## 6. 테스트 더블 배치

| 더블 | 위치 | 대체하는 기존 더블 |
|------|------|--------------------|
| `InMemoryKeyValueStorage` | Data 공유 테스트 지원은 target 간 공유가 불가하므로 사용하는 테스트 target의 `TestDoubles/`에 둔다 | `UserDefaults(suiteName:)` 실사용 테스트 일부 |
| `InMemorySecureValueStorage` | 같음 | `KeychainStore(backend: InMemoryBackend())` |
| `RecordingRequestTransport` | Composition 테스트 target `TestDoubles/` | Composition `RecordingHTTPTransport` 4벌 |
| `SpyLocalReminderNotifier` | `Composition/Tests/ShareExtension/TestDoubles/` 등 | `SpyNotificationAuthorizationClient` |

- Data Remote 테스트는 method·헤더 단언을 위해 계속 Infrastructure `HTTPTransport` 더블(`StubHTTPTransport`)을
  Data 내부 연결로 주입할 수 있다(Data 테스트 target은 Infrastructure 의존 허용).
- 실제 저장 기술을 쓰는 좌표·형식 테스트(`UserDefaults(suiteName:)`, Keychain in-memory backend)는
  `DataSharedTests`로 모아 실제 구현이 기존 키·형식으로 기록하는지 검증한다.
