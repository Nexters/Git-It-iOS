# Infrastructure 패키지 타입 목록

[인덱스로 돌아가기](README.md) · [단어 사전](glossary.md)

타입 52개, 관심사 폴더 21개. 항목은 파일 경로와 선언 줄 순서다. 각 항목은 `이름` 종류 · 접근 수준 · 파일 링크, 한 줄 설명, 그리고 이름을 이루는 단어와 정의로 구성된다.

| 종류 | 개수 |
|---|---|
| actor | 2 |
| class | 7 |
| enum | 15 |
| protocol | 4 |
| struct | 24 |

## Authentication/AppleAuthentication/Errors

- **`AppleAuthorizationError`** `enum` · public · [AppleAuthorizationError.swift:1](../../../sources/Projects/Infrastructure/Authentication/AppleAuthentication/Errors/AppleAuthorizationError.swift#L1) · 채택: Error, Equatable, Sendable  
  Apple 로그인 인가 과정에서 AppleAuthorizationProvider가 던지는 실패 사유를 열거한 오류 타입으로, cancelled·invalidCallback·expiredAttempt·missingCredential·unavailable 다섯 case를 가진다. 사용자 취소, 콜백의 state·attemptID 불일치, 시도 만료, identityToken·authorizationCode 누락, 플랫폼 오류를 구분한다.  
  단어: `Apple` 외부 고정 명칭(Apple 플랫폼·Sign in with Apple). 여기서는 Apple ID 로그인 인가 흐름을 가리킨다. · `Authorization` 인가·권한 부여. 여기서는 ASAuthorizationController를 통해 사용자가 Apple ID 자격 증명 사용을 허가하는 과정. · `Error` 오류. 여기서는 그 인가 과정이 실패한 사유를 담는 Swift Error 열거형.

## Authentication/AppleAuthentication/Models

- **`AppleAuthorizationAttempt`** `struct` · public · [AppleAuthorizationAttempt.swift:3](../../../sources/Projects/Infrastructure/Authentication/AppleAuthentication/Models/AppleAuthorizationAttempt.swift#L3) · 채택: CustomDebugStringConvertible, CustomStringConvertible, Equatable, Sendable  
  AppleAuthorizationProvider가 인가를 시작할 때 만드는 1회 시도 기록으로 id·nonce·state 문자열과 만료 시각(expiresAt)을 보유한다. description과 debugDescription은 값을 노출하지 않고 "<redacted>"로 가린다.  
  단어: `Apple` 외부 고정 명칭(Apple 플랫폼). 여기서는 Apple ID 로그인 인가를 가리킨다. · `Authorization` 인가·권한 부여. 여기서는 Apple ID 자격 증명을 얻기 위한 인가 요청. · `Attempt` 시도. 여기서는 nonce·state·만료 시각을 묶은 단일 인가 시도 단위.
- **`AppleCredential`** `struct` · public · [AppleCredential.swift:3](../../../sources/Projects/Infrastructure/Authentication/AppleAuthentication/Models/AppleCredential.swift#L3) · 채택: CustomDebugStringConvertible, CustomStringConvertible, Equatable, Sendable  
  Apple 인가 성공 시 ASAuthorizationAppleIDCredential에서 옮겨 담는 자격 증명 값 객체로 userID, identityToken·authorizationCode(Data?), email, fullName, 요청한 Scope 목록을 보유한다. description·debugDescription은 민감 정보를 숨기고 "<redacted>"만 출력한다.  
  단어: `Apple` 외부 고정 명칭(Apple 플랫폼). 여기서는 Sign in with Apple로 발급된 값을 가리킨다. · `Credential` 자격 증명. 여기서는 사용자 식별자·토큰·인가 코드·이메일·이름을 묶은 Apple ID 로그인 결과.
- **`AppleCredential.Scope`** `enum` · public · [AppleCredential.swift:25](../../../sources/Projects/Infrastructure/Authentication/AppleAuthentication/Models/AppleCredential.swift#L25) · 채택: CaseIterable, Equatable, Sendable  
  AppleCredential에 중첩된 열거형으로 Apple 로그인 시 요청할 정보 범위를 email·fullName 두 case로 나타낸다. AppleCredential.requestedScopes의 원소 타입이며 기본값은 두 case 모두다.  
  단어(단일): `Scope` 범위·권한 범위. 여기서는 Apple 로그인에서 요청하는 사용자 정보 항목(이메일, 전체 이름).
- **`AppleCredentialState`** `enum` · public · [AppleCredentialState.swift:4](../../../sources/Projects/Infrastructure/Authentication/AppleAuthentication/Models/AppleCredentialState.swift#L4) · 채택: Equatable, Sendable  
  Apple ID 자격 증명의 현재 유효 상태를 나타내는 열거형으로 authorized·revoked·notFound·transferred에 조회 실패를 뜻하는 temporarilyUnavailable을 더해 다섯 case를 가진다. AppleCredentialStateProvider.state(for:)의 반환 타입이다.  
  단어: `Apple` 외부 고정 명칭(Apple 플랫폼). 여기서는 Apple ID 자격 증명을 가리킨다. · `Credential` 자격 증명. 여기서는 사용자의 Apple ID 로그인 자격 증명. · `State` 상태. 여기서는 그 자격 증명이 유효·철회·미발견·이전·일시 조회 불가 중 어느 상태인지.

## Authentication/AppleAuthentication/Providers

- **`AppleAuthorizationProvider`** `class` · public · [AppleAuthorizationProvider.swift:6](../../../sources/Projects/Infrastructure/Authentication/AppleAuthentication/Providers/AppleAuthorizationProvider.swift#L6) · 채택: NSObject, Sendable, ASAuthorizationControllerDelegate · 그래프 미수집(grep 보강)  
  ASAuthorizationController를 구동해 Apple ID 로그인을 수행하는 final class로, 주입된 randomValue·now 클로저로 AppleAuthorizationAttempt를 만들고(beginAuthorization·startAuthorization) 델리게이트 콜백에서 state·attemptID·만료를 검증해(complete·cancel) authorize(expiresIn:)의 CheckedContinuation을 재개한다. 내부 상태는 Mutex<State>로 보호하며 Data 패키지의 AppleSignInSource가 생성해 사용한다.  
  단어: `Apple` 외부 고정 명칭(Apple 플랫폼). 여기서는 AuthenticationServices 기반 Apple ID 로그인을 가리킨다. · `Authorization` 인가·권한 부여. 여기서는 ASAuthorizationController로 자격 증명 사용 허가를 받는 흐름. · `Provider` 제공자. 여기서는 그 인가 흐름을 시작·완료·취소해 AppleCredential을 제공하는 객체.
- **`AppleAuthorizationProvider.State`** `struct` · private · [AppleAuthorizationProvider.swift:84](../../../sources/Projects/Infrastructure/Authentication/AppleAuthentication/Providers/AppleAuthorizationProvider.swift#L84)  
  AppleAuthorizationProvider가 Mutex로 보호하는 가변 상태 묶음으로, 진행 중인 ASAuthorizationController, 현재 AppleAuthorizationAttempt, 그리고 attemptID와 CheckedContinuation 쌍(pendingContinuation)을 보유한다.  
  단어(단일): `State` 상태. 여기서는 인가 컨트롤러·현재 시도·대기 중 continuation을 한 Mutex 아래 묶은 내부 가변 상태.
- **`AppleCredentialStateProvider`** `struct` · public · [AppleCredentialStateProvider.swift:4](../../../sources/Projects/Infrastructure/Authentication/AppleAuthentication/Providers/AppleCredentialStateProvider.swift#L4) · 채택: Sendable  
  userID로 Apple ID 자격 증명 상태를 조회하는 구조체로, 기본 init은 ASAuthorizationAppleIDProvider.getCredentialState를 continuation으로 감싼 liveState를 쓰고 internal init은 테스트용 stateLookup 클로저를 주입받는다. state(for:)는 조회 실패 시 .temporarilyUnavailable로 대체하며, Data 패키지의 AppleSignInSource가 사용한다.  
  단어: `Apple` 외부 고정 명칭(Apple 플랫폼). 여기서는 Apple ID 자격 증명을 가리킨다. · `Credential` 자격 증명. 여기서는 userID로 식별되는 Apple ID 로그인 자격 증명. · `State` 상태. 여기서는 그 자격 증명의 유효·철회 등 현재 상태(AppleCredentialState). · `Provider` 제공자. 여기서는 플랫폼 API를 호출해 그 상태 값을 비동기로 돌려주는 객체.
- **`AppleCredentialStateProvider.PlatformState`** `enum` · public · [AppleCredentialStateProvider.swift:20](../../../sources/Projects/Infrastructure/Authentication/AppleAuthentication/Providers/AppleCredentialStateProvider.swift#L20) · 채택: Sendable  
  ASAuthorizationAppleIDProvider.CredentialState를 옮겨 담는 중간 열거형으로 authorized·revoked·notFound·transferred 네 case를 가진다. liveState에서 플랫폼 값을 이 타입으로 바꾼 뒤 static map(_:)으로 AppleCredentialState로 변환한다.  
  단어: `Platform` 플랫폼. 여기서는 AuthenticationServices가 돌려주는 Apple 플랫폼 원본 상태. · `State` 상태. 여기서는 플랫폼 자격 증명 상태를 앱 타입으로 옮기기 전 단계의 상태 값.

## Authentication/Keychain/Errors

- **`KeychainStoreError`** `enum` · public · [KeychainStoreError.swift:1](../../../sources/Projects/Infrastructure/Authentication/Keychain/Errors/KeychainStoreError.swift#L1) · 채택: Error, Equatable, Sendable  
  KeychainStore의 save·load·delete·removeAll이 Security 프레임워크 호출 실패 시 던지는 오류로 unavailable 한 case만 가진다.  
  단어: `Keychain` 외부 고정 명칭(Apple Keychain 보안 저장소). 여기서는 Security 프레임워크의 SecItem API. · `Store` 저장소. 여기서는 Keychain에 값을 저장·조회·삭제하는 KeychainStore. · `Error` 오류. 여기서는 그 저장소 연산이 실패했음을 알리는 Swift Error.

## Authentication/Keychain/Models

- **`KeychainAccessGroup`** `struct` · public · [KeychainAccessGroup.swift:1](../../../sources/Projects/Infrastructure/Authentication/Keychain/Models/KeychainAccessGroup.swift#L1) · 채택: Hashable, Sendable  
  Keychain 항목의 kSecAttrAccessGroup 값을 감싸는 rawValue 문자열 래퍼로, KeychainStore 생성자와 AppGroupKeychainStore.accessGroup에서 앱 그룹 공유 접근 그룹을 지정하는 데 쓰인다.  
  단어: `Keychain` 외부 고정 명칭(Apple Keychain). 여기서는 Keychain 항목 속성을 가리킨다. · `Access` 접근. 여기서는 여러 앱·확장이 같은 항목에 접근할 수 있게 하는 권한. · `Group` 그룹·묶음. 여기서는 Keychain 접근 그룹 식별자 문자열.
- **`KeychainAccessibility`** `enum` · public · [KeychainAccessibility.swift:1](../../../sources/Projects/Infrastructure/Authentication/Keychain/Models/KeychainAccessibility.swift#L1) · 채택: Equatable, Sendable  
  Keychain 항목의 접근 가능 조건을 나타내는 열거형으로 whenUnlockedThisDeviceOnly·afterFirstUnlockThisDeviceOnly 두 case를 가진다. KeychainStore는 새 항목에 afterFirstUnlockThisDeviceOnly를 쓰며 InMemoryBackend가 저장된 값을 노출한다.  
  단어: `Keychain` 외부 고정 명칭(Apple Keychain). 여기서는 Keychain 항목 속성을 가리킨다. · `Accessibility` 접근 가능성. 여기서는 기기 잠금 상태에 따라 항목을 읽을 수 있는 조건(kSecAttrAccessible).
- **`KeychainNamespace`** `struct` · public · [KeychainNamespace.swift:1](../../../sources/Projects/Infrastructure/Authentication/Keychain/Models/KeychainNamespace.swift#L1) · 채택: Hashable, Sendable  
  Keychain 항목의 kSecAttrService 값을 감싸는 rawValue 문자열 래퍼로, KeychainStore의 save·load·delete에서 key와 함께 항목을 식별하는 이름 공간으로 쓰인다.  
  단어: `Keychain` 외부 고정 명칭(Apple Keychain). 여기서는 Keychain 항목 속성을 가리킨다. · `Namespace` 이름 공간. 여기서는 key 충돌을 막기 위해 항목을 묶는 서비스 이름(kSecAttrService).

## Authentication/Keychain/Stores

- **`AppGroupKeychainStore`** `enum` · public · [AppGroupKeychainStore.swift:5](../../../sources/Projects/Infrastructure/Authentication/Keychain/Stores/AppGroupKeychainStore.swift#L5)  
  case 없는 네임스페이스 열거형으로, 팀 식별자 접두어와 "com.nexters.hytime.gitit.shared"를 합친 공유 KeychainAccessGroup 상수와 그 그룹으로 KeychainStore를 만드는 makeShared()를 제공한다. Data 패키지 StorageFactory가 앱 그룹 공유 저장 위치에 사용한다.  
  단어: `App` 애플리케이션. 여기서는 App Group(앱 그룹) 공유 컨테이너의 첫 단어. · `Group` 그룹. 여기서는 앱과 확장이 데이터를 공유하는 Apple App Group. · `Keychain` 외부 고정 명칭(Apple Keychain). 여기서는 접근 그룹이 지정된 Keychain 저장. · `Store` 저장소. 여기서는 공유 접근 그룹용 KeychainStore를 만들어 주는 팩토리 역할.
- **`KeychainStore`** `class` · public · [KeychainStore.swift:7](../../../sources/Projects/Infrastructure/Authentication/Keychain/Stores/KeychainStore.swift#L7) · 채택: Sendable  
  Security 프레임워크의 SecItemAdd·SecItemUpdate·SecItemCopyMatching·SecItemDelete로 generic password 항목을 저장·조회·삭제·전체 삭제하는 final class로, KeychainNamespace를 service, key를 account, 선택적 KeychainAccessGroup을 접근 그룹으로 매핑한다. internal init으로 InMemoryBackend를 주입하면 실제 Keychain 대신 메모리 백엔드로 동작한다.  
  단어: `Keychain` 외부 고정 명칭(Apple Keychain). 여기서는 SecItem API로 접근하는 보안 저장소. · `Store` 저장소. 여기서는 Data 값을 key·namespace로 저장·조회·삭제하는 객체.
- **`KeychainStore.InMemoryBackend`** `class` · public · [KeychainStore.swift:26](../../../sources/Projects/Infrastructure/Authentication/Keychain/Stores/KeychainStore.swift#L26) · 채택: Sendable  
  KeychainStore에 중첩된 메모리 대체 백엔드로, accessGroup·namespace·key를 합친 storageKey로 [String: Data] 사전에 값을 보관하고 fileprivate save·load·delete·removeAll을 KeychainStore가 호출한다. 마지막으로 기록된 accessibility와 사용된 accessGroups 집합을 public 읽기 전용으로 노출한다.  
  단어: `In` 안에. 여기서는 InMemory(메모리 내)라는 관용 표현의 첫 부분. · `Memory` 메모리. 여기서는 Keychain 대신 프로세스 메모리에 값을 두는 방식. · `Backend` 후단·실제 저장 구현. 여기서는 KeychainStore가 위임하는 저장 구현체.
- **`KeychainStore.InMemoryBackend.State`** `struct` · private · [KeychainStore.swift:97](../../../sources/Projects/Infrastructure/Authentication/Keychain/Stores/KeychainStore.swift#L97)  
  InMemoryBackend가 Mutex로 보호하는 가변 상태 묶음으로, 마지막 KeychainAccessibility, 접근 그룹 문자열 집합(accessGroups), storageKey별 Data 사전(values)을 보유한다.  
  단어(단일): `State` 상태. 여기서는 메모리 백엔드가 Mutex 아래 보관하는 accessibility·accessGroups·values 묶음.

## Authentication/RandomGenerator/Errors

- **`SecureRandomGeneratorError`** `enum` · public · [SecureRandomGeneratorError.swift:4](../../../sources/Projects/Infrastructure/Authentication/RandomGenerator/Errors/SecureRandomGeneratorError.swift#L4) · 채택: Error, Equatable, Sendable  
  SecureRandomGenerator.value(length:)가 던지는 오류로, 길이가 0 이하일 때의 invalidLength와 SecRandomCopyBytes 실패 시의 unavailable 두 case를 가진다.  
  단어: `Secure` 안전한·암호학적으로 안전한. 여기서는 Security 프레임워크의 난수 생성. · `Random` 무작위. 여기서는 예측 불가능한 난수 값. · `Generator` 생성기. 여기서는 난수 문자열을 만드는 SecureRandomGenerator. · `Error` 오류. 여기서는 그 생성기가 실패한 사유를 담는 Swift Error.

## Authentication/RandomGenerator/Providers

- **`SecureRandomGenerator`** `struct` · public · [SecureRandomGenerator.swift:4](../../../sources/Projects/Infrastructure/Authentication/RandomGenerator/Providers/SecureRandomGenerator.swift#L4) · 채택: Sendable  
  SecRandomCopyBytes로 얻은 바이트를 base64로 인코딩한 뒤 +·/를 -·_로 바꾸고 =를 제거해 요청한 길이의 URL-safe 난수 문자열을 만드는 구조체이며, internal init으로 bytes 클로저를 주입할 수 있다. AppleAuthorizationProvider가 attempt의 id·nonce·state 생성에 기본값으로 사용한다.  
  단어: `Secure` 안전한·암호학적으로 안전한. 여기서는 Security 프레임워크 SecRandomCopyBytes 기반 난수. · `Random` 무작위. 여기서는 nonce·state에 쓰는 예측 불가능한 값. · `Generator` 생성기. 여기서는 지정 길이의 난수 문자열을 만들어 주는 객체.

## Cache/Stores

- **`InMemoryCache`** `actor` · public · [InMemoryCache.swift:1](../../../sources/Projects/Infrastructure/Cache/Stores/InMemoryCache.swift#L1)  
  Hashable & Sendable 키와 Sendable 값을 [Key: Value] 사전에 보관하는 제네릭 actor로, store(_:forKey:)·value(forKey:)·removeValue(forKey:)·removeAll()을 제공한다. actor 격리로 동시 접근을 직렬화한다.  
  단어: `In` 안에. 여기서는 InMemory(메모리 내)라는 관용 표현의 첫 부분. · `Memory` 메모리. 여기서는 디스크가 아닌 프로세스 메모리에 값을 두는 방식. · `Cache` 캐시·임시 저장. 여기서는 키로 값을 빠르게 넣고 꺼내는 임시 저장소.

## LocalNotification/Clients

- **`LocalNotificationAuthorizationClient`** `class` · public · [LocalNotificationAuthorizationClient.swift:7](../../../sources/Projects/Infrastructure/LocalNotification/Clients/LocalNotificationAuthorizationClient.swift#L7) · 채택: NotificationAuthorizationClient, Sendable  
  UNUserNotificationCenter를 사용해 NotificationAuthorizationClient를 구현하는 final class로, 알림 권한 요청·권한 여부·설정 상태 조회와 LocalNotificationRequest의 즉시 발송(present)·지연 예약(schedule)·예약 취소(cancel)를 수행하며 os.Logger로 디버그 로그를 남긴다. Data 패키지 NotificationFactory가 ReminderNotificationClient에 주입한다.  
  단어: `Local` 로컬·기기 내. 여기서는 서버 푸시가 아닌 앱이 직접 예약하는 로컬 알림. · `Notification` 알림. 여기서는 UserNotifications 프레임워크의 사용자 알림. · `Authorization` 인가·권한. 여기서는 알림 표시 권한의 요청과 상태 조회. · `Client` 클라이언트. 여기서는 UNUserNotificationCenter를 호출하는 구현 객체.
- **`NotificationAuthorizationClient`** `protocol` · public · [NotificationAuthorizationClient.swift:5](../../../sources/Projects/Infrastructure/LocalNotification/Clients/NotificationAuthorizationClient.swift#L5) · 채택: Sendable  
  알림 권한과 로컬 알림 발송을 추상화한 프로토콜로 requestAuthorization·isAuthorized·authorizationSetting과 present·schedule(_:at:)·cancel(identifier:) 여섯 요구사항을 정의한다. LocalNotificationAuthorizationClient가 채택한다.  
  단어: `Notification` 알림. 여기서는 사용자 알림. · `Authorization` 인가·권한. 여기서는 알림 권한 요청·조회 계약. · `Client` 클라이언트. 여기서는 권한 처리와 알림 발송·예약을 담당하는 구현체의 계약.

## LocalNotification/Models

- **`LocalNotificationRequest`** `struct` · public · [LocalNotificationRequest.swift:3](../../../sources/Projects/Infrastructure/LocalNotification/Models/LocalNotificationRequest.swift#L3) · 채택: Sendable, Equatable  
  로컬 알림 하나를 기술하는 값 객체로 identifier·title·body 세 문자열을 보유한다. LocalNotificationAuthorizationClient가 UNMutableNotificationContent와 UNNotificationRequest로 변환해 발송·예약한다.  
  단어: `Local` 로컬·기기 내. 여기서는 앱이 직접 만드는 로컬 알림. · `Notification` 알림. 여기서는 사용자에게 표시할 알림. · `Request` 요청. 여기서는 식별자·제목·본문을 담은 알림 발송 요청 데이터.
- **`NotificationAuthorizationSetting`** `enum` · public · [NotificationAuthorizationSetting.swift:3](../../../sources/Projects/Infrastructure/LocalNotification/Models/NotificationAuthorizationSetting.swift#L3) · 채택: Sendable, Equatable  
  시스템 알림 설정의 현재 권한 상태를 notDetermined·authorized·denied 세 case로 나타내는 열거형으로, authorizationSetting()이 UNAuthorizationStatus를 이 타입으로 매핑해 반환한다.  
  단어: `Notification` 알림. 여기서는 사용자 알림. · `Authorization` 인가·권한. 여기서는 알림 표시 권한. · `Setting` 설정. 여기서는 시스템 설정에 저장된 권한 값(미결정·허용·거부).
- **`NotificationAuthorizationStatus`** `enum` · public · [NotificationAuthorizationStatus.swift:3](../../../sources/Projects/Infrastructure/LocalNotification/Models/NotificationAuthorizationStatus.swift#L3) · 채택: Sendable, Equatable  
  requestAuthorization() 호출의 결과를 authorized·declined·previouslyDenied 세 case로 나타내는 열거형으로, 이번 요청에서 거부된 경우와 이전에 이미 거부돼 있던 경우를 구분한다.  
  단어: `Notification` 알림. 여기서는 사용자 알림. · `Authorization` 인가·권한. 여기서는 알림 권한 요청. · `Status` 상태·결과. 여기서는 권한 요청 직후의 결과(허용·거절·이미 거부됨).

## NetworkClient/Clients

- **`HTTPBodyCoding`** `protocol` · public · [HTTPBodyCoding.swift:5](../../../sources/Projects/Infrastructure/NetworkClient/Clients/HTTPBodyCoding.swift#L5) · 채택: Sendable  
  HTTP 본문의 인코딩·디코딩을 추상화한 프로토콜로 Encodable을 Data로 바꾸는 encode와 Data를 Decodable 타입으로 바꾸는 decode를 요구한다. HTTPClient가 요청 본문 작성과 응답 본문 해석에 사용하며 StandardJSONBodyCoding이 채택한다.  
  단어: `HTTP` HyperText Transfer Protocol. 여기서는 HTTP 요청·응답. · `Body` 본문. 여기서는 HTTP 메시지 본문 데이터. · `Coding` 부호화(인코딩·디코딩). 여기서는 Swift 값과 Data 사이의 상호 변환 계약.
- **`HTTPClient`** `struct` · public · [HTTPClient.swift:5](../../../sources/Projects/Infrastructure/NetworkClient/Clients/HTTPClient.swift#L5) · 채택: Sendable  
  baseURL·HTTPBodyCoding·공통 HTTPHeaders·응답 타임아웃·HTTPTransport를 생성자로 받아 HTTPRequest를 전송하는 구조체로, RequestURLBuilder로 URL을 만들고 HTTPTransportRequest로 변환해 보낸 뒤 2xx면 본문을 디코딩하고 아니면 raw Data로 HTTPResponse를 돌려준다. 타임아웃·취소·연결 실패를 HTTPClientError로 정규화하며 Data 패키지 RequestClientFactory가 생성한다.  
  단어: `HTTP` HyperText Transfer Protocol. 여기서는 HTTP 요청·응답 프로토콜. · `Client` 클라이언트. 여기서는 요청을 조립해 전송하고 응답을 해석하는 호출 측 객체.
- **`RequestURLBuilder`** `struct` · internal · [RequestURLBuilder.swift:5](../../../sources/Projects/Infrastructure/NetworkClient/Clients/RequestURLBuilder.swift#L5)  
  baseURL에 path를 붙이고 HTTPRequest.QueryItem 목록을 +&=?#를 제외한 허용 문자로 퍼센트 인코딩해 최종 URL을 만드는 internal 구조체로, scheme·host가 없으면 HTTPClientError.invalidURL을 던진다. HTTPClient가 내부 프로퍼티로 보유한다.  
  단어: `Request` 요청. 여기서는 HTTP 요청. · `URL` Uniform Resource Locator, 요청 주소 문자열. 여기서는 base·path·query를 합친 최종 요청 주소. · `Builder` 빌더·조립기. 여기서는 부분 값을 합쳐 URL을 만들어 주는 객체.
- **`StandardJSONBodyCoding`** `struct` · public · [StandardJSONBodyCoding.swift:5](../../../sources/Projects/Infrastructure/NetworkClient/Clients/StandardJSONBodyCoding.swift#L5) · 채택: HTTPBodyCoding  
  JSONEncoder·JSONDecoder에 ISO 8601 날짜 전략을 적용해 HTTPBodyCoding을 구현하는 구조체이며, Data 패키지 RequestClientFactory가 HTTPClient의 bodyCoding으로 주입한다.  
  단어: `Standard` 표준·기본. 여기서는 별도 커스터마이징 없는 기본 JSON 코딩 방식. · `JSON` JavaScript Object Notation. 여기서는 HTTP 본문 직렬화 형식. · `Body` 본문. 여기서는 HTTP 메시지 본문. · `Coding` 부호화(인코딩·디코딩). 여기서는 Foundation JSON 코더로 수행하는 변환.

## NetworkClient/Errors

- **`HTTPClientError`** `enum` · public · [HTTPClientError.swift:3](../../../sources/Projects/Infrastructure/NetworkClient/Errors/HTTPClientError.swift#L3) · 채택: Error, Equatable, Sendable  
  HTTPClient·HTTPTransport·RequestURLBuilder가 typed throws로 던지는 오류로 invalidURL·requestEncodingFailed·connectionFailed·timedOut·cancelled·responseDecodingFailed 여섯 case를 가진다.  
  단어: `HTTP` HyperText Transfer Protocol. 여기서는 HTTP 통신. · `Client` 클라이언트. 여기서는 HTTPClient와 그 전송 계층. · `Error` 오류. 여기서는 URL 조립·인코딩·연결·타임아웃·취소·디코딩 실패를 구분하는 Swift Error.

## NetworkClient/Models

- **`HTTPHeaders`** `struct` · public · [HTTPHeaders.swift:3](../../../sources/Projects/Infrastructure/NetworkClient/Models/HTTPHeaders.swift#L3) · 채택: Equatable, Sendable, ExpressibleByDictionaryLiteral  
  헤더 이름을 소문자로 정규화해 [String: String]에 보관하는 HTTP 헤더 컬렉션으로, 딕셔너리 리터럴 초기화, 대소문자 무관 subscript, 정렬된 names·all, 다른 헤더로 덮어쓰는 overridden(by:)를 제공한다. HTTPRequest·HTTPResponse·HTTPTransportRequest/Response가 헤더 타입으로 사용한다.  
  단어: `HTTP` HyperText Transfer Protocol. 여기서는 HTTP 메시지. · `Headers` 헤더들. 여기서는 이름-값 쌍으로 이루어진 HTTP 헤더 필드 집합.
- **`HTTPMethod`** `enum` · public · [HTTPMethod.swift:3](../../../sources/Projects/Infrastructure/NetworkClient/Models/HTTPMethod.swift#L3) · 채택: Sendable  
  get·post·put·patch·delete·head 여섯 HTTP 메서드를 열거하고 internal requestValue로 대문자 문자열("GET" 등)을 돌려준다. HTTPRequest와 HTTPTransportRequest의 method 타입이며 URLSessionTransport가 URLRequest.httpMethod에 쓴다.  
  단어: `HTTP` HyperText Transfer Protocol. 여기서는 HTTP 요청. · `Method` 메서드·방식. 여기서는 GET·POST 등 HTTP 요청 메서드.

## NetworkClient/Models/HTTPRequest

- **`HTTPRequest.QueryItem`** `struct` · public · [HTTPRequest+QueryItem.swift:4](../../../sources/Projects/Infrastructure/NetworkClient/Models/HTTPRequest/HTTPRequest+QueryItem.swift#L4) · 채택: Equatable, Sendable  
  HTTPRequest에 extension으로 중첩된 값 객체로 URL 쿼리 문자열의 name·value 한 쌍을 보유한다. HTTPRequest.queryItems의 원소이며 RequestURLBuilder가 퍼센트 인코딩해 URL에 붙인다.  
  단어: `Query` 질의·조회 문자열. 여기서는 URL의 ? 뒤 쿼리 부분. · `Item` 항목. 여기서는 쿼리 문자열을 이루는 name=value 한 쌍.
- **`HTTPRequest`** `struct` · public · [HTTPRequest.swift:3](../../../sources/Projects/Infrastructure/NetworkClient/Models/HTTPRequest/HTTPRequest.swift#L3) · 채택: Sendable  
  HTTPClient 호출자가 작성하는 요청 기술 값 객체로 HTTPMethod, baseURL 기준 path, QueryItem 배열, HTTPHeaders, 선택적 responseTimeout(Duration?)을 var 프로퍼티로 보유한다. 본문은 포함하지 않고 send(_:body:expecting:)에서 별도로 전달한다.  
  단어: `HTTP` HyperText Transfer Protocol. 여기서는 HTTP 통신. · `Request` 요청. 여기서는 메서드·경로·쿼리·헤더·타임아웃으로 기술한 상위 수준 요청.

## NetworkClient/Models/HTTPResponse

- **`HTTPResponse.Body`** `enum` · public · [HTTPResponse+Body.swift:6](../../../sources/Projects/Infrastructure/NetworkClient/Models/HTTPResponse/HTTPResponse+Body.swift#L6) · 채택: Sendable  
  HTTPResponse에 extension으로 중첩된 열거형으로 2xx 응답에서 디코딩된 Value를 담는 decoded와 그 외 상태 코드에서 원본 Data를 담는 raw 두 case를 가진다. HTTPClient.send가 상태 코드에 따라 선택해 채운다.  
  단어(단일): `Body` 본문. 여기서는 HTTP 응답 본문이 디코딩된 값인지 원본 바이트인지 구분한 표현.
- **`HTTPResponse`** `struct` · public · [HTTPResponse.swift:3](../../../sources/Projects/Infrastructure/NetworkClient/Models/HTTPResponse/HTTPResponse.swift#L3) · 채택: Sendable  
  HTTPClient.send가 돌려주는 제네릭 응답 값 객체로 statusCode, HTTPHeaders, 그리고 Body(decoded(Value) 또는 raw(Data))를 보유한다. Value는 호출자가 expecting으로 지정한 Decodable & Sendable 타입이다.  
  단어: `HTTP` HyperText Transfer Protocol. 여기서는 HTTP 통신. · `Response` 응답. 여기서는 상태 코드·헤더·본문을 담은 상위 수준 응답.

## NetworkClient/Transports

- **`HTTPTransport`** `protocol` · public · [HTTPTransport.swift:3](../../../sources/Projects/Infrastructure/NetworkClient/Transports/HTTPTransport.swift#L3) · 채택: Sendable  
  HTTPTransportRequest를 받아 HTTPTransportResponse를 돌려주는 send 하나를 typed throws(HTTPClientError)로 요구하는 전송 계층 프로토콜이다. HTTPClient가 생성자로 주입받으며 URLSessionTransport가 기본 구현이다.  
  단어: `HTTP` HyperText Transfer Protocol. 여기서는 HTTP 통신. · `Transport` 전송 계층. 여기서는 실제 네트워크로 요청을 보내고 응답을 받는 저수준 계약.
- **`HTTPTransportRequest`** `struct` · public · [HTTPTransportRequest.swift:5](../../../sources/Projects/Infrastructure/NetworkClient/Transports/HTTPTransportRequest.swift#L5) · 채택: Sendable  
  HTTPClient가 HTTPRequest를 해석해 만든 전송용 요청 값 객체로 완성된 URL, HTTPMethod, 병합된 HTTPHeaders, 인코딩된 body(Data?), 확정된 responseTimeout(Duration)을 보유한다. HTTPTransport.send의 입력이다.  
  단어: `HTTP` HyperText Transfer Protocol. 여기서는 HTTP 통신. · `Transport` 전송 계층. 여기서는 HTTPTransport 구현체에 넘기는 저수준 단계. · `Request` 요청. 여기서는 URL·본문·타임아웃까지 확정된 전송 직전 요청.
- **`HTTPTransportResponse`** `struct` · public · [HTTPTransportResponse.swift:5](../../../sources/Projects/Infrastructure/NetworkClient/Transports/HTTPTransportResponse.swift#L5) · 채택: Sendable  
  HTTPTransport.send가 돌려주는 전송 계층 응답 값 객체로 statusCode, HTTPHeaders, 디코딩 전 원본 body(Data)를 보유한다. HTTPClient가 이를 HTTPResponse로 변환한다.  
  단어: `HTTP` HyperText Transfer Protocol. 여기서는 HTTP 통신. · `Transport` 전송 계층. 여기서는 HTTPTransport 구현체가 반환하는 저수준 단계. · `Response` 응답. 여기서는 디코딩되지 않은 원본 바이트 본문을 가진 응답.
- **`URLSessionTransport`** `struct` · internal · [URLSessionTransport.swift:5](../../../sources/Projects/Infrastructure/NetworkClient/Transports/URLSessionTransport.swift#L5) · 채택: HTTPTransport  
  URLSession(waitsForConnectivity를 끈 구성)으로 HTTPTransport를 구현하는 internal 구조체로, HTTPTransportRequest를 URLRequest로 옮겨 session.data(for:)를 호출하고 HTTPURLResponse의 상태 코드·헤더·본문을 HTTPTransportResponse로 돌려준다. URLError의 cancelled·timedOut과 Task 취소를 HTTPClientError로 매핑하며 HTTPClient의 기본 transport다.  
  단어: `URLSession` 외부 고정 명칭(Foundation URLSession 네트워킹 API). 여기서는 실제 요청을 보내는 세션 객체. · `Transport` 전송 계층. 여기서는 HTTPTransport 프로토콜의 URLSession 기반 구현.

## PushMessaging/Remote/AppDelegates

- **`FirebaseMessagingAppDelegate`** `class` · public · [FirebaseMessagingAppDelegate.swift:11](../../../sources/Projects/Infrastructure/PushMessaging/Remote/AppDelegates/FirebaseMessagingAppDelegate.swift#L11) · 채택: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate · 그래프 미수집(grep 보강)  
  앱 실행 시 FirebaseApp을 구성하고 UNUserNotificationCenter delegate 등록과 원격 알림 등록을 수행하며, APNs 기기 토큰 수신과 didReceiveRemoteNotification 수신을 PushNotificationCallbacks로 전달하는 UIApplicationDelegate 구현. configure(_:) 전에 도착한 토큰·payload는 Mutex로 보호되는 State의 대기 슬롯에 보관했다가 configure 시점에 전달하고, 포그라운드 알림 표시 옵션(banner·list·sound)을 결정하며 PushMessagingAppDelegate가 base로 감싼다.  
  단어: `Firebase` 외부 고정 명칭. Google의 모바일 백엔드 플랫폼으로, 여기서는 FirebaseCore·FirebaseMessaging SDK를 사용하는 구현임을 나타냄 · `Messaging` 메시징·메시지 전송. 여기서는 Firebase Cloud Messaging(FCM) 모듈을 가리킴 · `App` Application의 축약, 애플리케이션. 여기서는 iOS 앱 프로세스 · `Delegate` 위임자·대리인. 여기서는 UIApplication의 생명주기·알림 이벤트를 위임받는 UIApplicationDelegate 객체(App+Delegate는 iOS 관용 표현 AppDelegate)
- **`FirebaseMessagingAppDelegate.PendingDelivery`** `struct` · private · [FirebaseMessagingAppDelegate.swift:99](../../../sources/Projects/Infrastructure/PushMessaging/Remote/AppDelegates/FirebaseMessagingAppDelegate.swift#L99)  
  configure(_:) 호출 시 State에서 꺼낸 대기 중 APNs 토큰(apnsToken: Data?)과 payload([String: String]?)를 한 값으로 묶어 withLock 클로저 밖으로 반환하기 위한 내부 값 타입. 반환 직후 callbacks.forwardAPNsToken과 ingestGenerationOutcomePayload로 전달된다.  
  단어: `Pending` 보류·대기 중. 여기서는 콜백이 설정되기 전에 도착해 전달을 기다리던 항목 · `Delivery` 전달·배송. 여기서는 콜백으로 넘길 토큰과 payload의 한 회분 묶음
- **`FirebaseMessagingAppDelegate.State`** `struct` · private · [FirebaseMessagingAppDelegate.swift:104](../../../sources/Projects/Infrastructure/PushMessaging/Remote/AppDelegates/FirebaseMessagingAppDelegate.swift#L104)  
  Mutex(State())로 보호되는 delegate의 가변 내부 상태. 등록된 callbacks(PushNotificationCallbacks?)와 configure 전에 도착한 pendingAPNsToken(Data?), pendingPayload([String: String]?) 대기 슬롯을 보관한다.  
  단어(단일): `State` 상태. 여기서는 콜백과 대기 슬롯을 담아 잠금으로 보호하는 delegate의 내부 상태
- **`PushMessagingAppDelegate`** `class` · public · [PushMessagingAppDelegate.swift:6](../../../sources/Projects/Infrastructure/PushMessaging/Remote/AppDelegates/PushMessagingAppDelegate.swift#L6) · 채택: NSObject, UIApplicationDelegate  
  FirebaseMessagingAppDelegate 인스턴스를 private base로 보유하고 configure(_:)와 UIApplicationDelegate 메서드 세 개(didFinishLaunchingWithOptions·didRegisterForRemoteNotificationsWithDeviceToken·didReceiveRemoteNotification)를 그대로 위임하는 공급자 중립 래퍼. Data 패키지의 NotificationAppDelegate가 이 타입을 base로 사용한다.  
  단어: `Push` 밀어 보내기. 여기서는 서버가 기기로 능동적으로 보내는 푸시 알림 · `Messaging` 메시징·메시지 전달. 여기서는 푸시 메시지 전달 기능 영역(InfrastructurePushMessaging 모듈의 관심사) · `App` Application의 축약, 애플리케이션. 여기서는 iOS 앱 프로세스 · `Delegate` 위임자·대리인. 여기서는 UIApplication 이벤트를 위임받는 UIApplicationDelegate 객체(App+Delegate는 iOS 관용 표현 AppDelegate)

## PushMessaging/Remote/Clients

- **`FirebaseMessagingPushClient`** `class` · public · [FirebaseMessagingPushClient.swift:8](../../../sources/Projects/Infrastructure/PushMessaging/Remote/Clients/FirebaseMessagingPushClient.swift#L8) · 채택: NSObject, PushMessagingClient, Sendable, MessagingDelegate · 그래프 미수집(grep 보강)  
  Firebase Messaging으로 FCM 등록 토큰을 제공하는 PushMessagingClient 구현. init에서 FirebaseApp을 구성하고 Messaging delegate가 되어, fcmToken이 없으면 CheckedContinuation을 State에 대기시켰다가 didReceiveRegistrationToken에서 재개하고, 최초 발급 이후의 토큰은 registrationTokenRefreshes()의 AsyncStream 구독자에게 yield하며, setAPNsToken으로 APNs 토큰을 Messaging에 설정한다.  
  단어: `Firebase` 외부 고정 명칭. Google의 모바일 백엔드 플랫폼으로, 여기서는 FirebaseMessaging SDK 기반 구현임을 나타냄 · `Messaging` 메시징·메시지 전송. 여기서는 Firebase Cloud Messaging(FCM) 모듈 · `Push` 밀어 보내기. 여기서는 서버가 기기로 보내는 푸시 알림 · `Client` 클라이언트·의뢰자. 여기서는 외부 푸시 서비스에 접근해 토큰을 얻는 접근 객체
- **`FirebaseMessagingPushClient.State`** `struct` · private · [FirebaseMessagingPushClient.swift:47](../../../sources/Projects/Infrastructure/PushMessaging/Remote/Clients/FirebaseMessagingPushClient.swift#L47)  
  Mutex(State())로 보호되는 클라이언트의 가변 내부 상태. 토큰 발급을 기다리는 pendingContinuations([CheckedContinuation<String, Never>]), 구독 UUID별 refreshContinuations([UUID: AsyncStream<String>.Continuation]), 최초 토큰 발급 여부 hasIssuedInitialToken을 보관한다.  
  단어(단일): `State` 상태. 여기서는 대기 continuation과 갱신 구독, 최초 발급 여부를 담아 잠금으로 보호하는 클라이언트의 내부 상태
- **`PushMessagingClient`** `protocol` · public · [PushMessagingClient.swift:5](../../../sources/Projects/Infrastructure/PushMessaging/Remote/Clients/PushMessagingClient.swift#L5) · 채택: Sendable  
  푸시 메시징 공급자에 독립적인 클라이언트 계약. registrationToken() async throws -> String, setAPNsToken(_ token: Data), registrationTokenRefreshes() -> AsyncStream<String>을 요구하며 Data 패키지의 RemoteMessageClient가 pushClient로 주입받는다.  
  단어: `Push` 밀어 보내기. 여기서는 서버가 기기로 보내는 푸시 알림 · `Messaging` 메시징·메시지 전달. 여기서는 푸시 메시지 전달 기능 영역 · `Client` 클라이언트·의뢰자. 여기서는 푸시 서비스에서 등록 토큰을 얻고 APNs 토큰을 넘기는 접근 객체의 계약
- **`PushMessagingClientFactory`** `enum` · public · [PushMessagingClientFactory.swift:5](../../../sources/Projects/Infrastructure/PushMessaging/Remote/Clients/PushMessagingClientFactory.swift#L5)  
  정적 함수 make()로 FirebaseMessagingPushClient 인스턴스를 any PushMessagingClient 타입으로 반환하는 case 없는 enum 네임스페이스. Data 패키지 RemoteMessageClient의 init 기본 인자에서 호출된다.  
  단어: `Push` 밀어 보내기. 여기서는 서버가 기기로 보내는 푸시 알림 · `Messaging` 메시징·메시지 전달. 여기서는 푸시 메시지 전달 기능 영역 · `Client` 클라이언트·의뢰자. 여기서는 PushMessagingClient 프로토콜을 따르는 접근 객체 · `Factory` 공장·제조소. 여기서는 구현체를 생성해 프로토콜 타입으로 돌려주는 정적 생성 지점

## PushMessaging/Remote/Models

- **`PushNotificationCallbacks`** `struct` · public · [PushNotificationCallbacks.swift:5](../../../sources/Projects/Infrastructure/PushMessaging/Remote/Models/PushNotificationCallbacks.swift#L5) · 채택: Sendable  
  앱 delegate가 푸시 이벤트를 상위 계층으로 넘길 때 호출하는 두 클로저 forwardAPNsToken(@Sendable (Data) -> Void)과 ingestGenerationOutcomePayload(@Sendable ([String: String]) async -> Void)를 담는 값 타입. FirebaseMessagingAppDelegate.configure(_:)에 전달되며 Data의 NotificationAppDelegate가 NotificationAppCallbacks로부터 만든다.  
  단어: `Push` 밀어 보내기. 여기서는 서버가 기기로 보내는 푸시 · `Notification` 알림·통지. 여기서는 APNs를 통해 도착하는 원격 알림 · `Callbacks` 콜백·되부름 함수들. 여기서는 토큰 수신과 payload 수신 시 호출될 클로저 묶음
- **`RemoteNotificationPayload`** `struct` · public · [RemoteNotificationPayload.swift:5](../../../sources/Projects/Infrastructure/PushMessaging/Remote/Models/RemoteNotificationPayload.swift#L5)  
  didReceiveRemoteNotification의 userInfo([AnyHashable: Any])를 받아 String 키만 남기고 값을 String(describing:)으로 바꾼 userInfoStrings([String: String])를 보관하는 값 타입. FirebaseMessagingAppDelegate가 로그 출력과 콜백 전달, 대기 슬롯 저장에 사용한다.  
  단어: `Remote` 원격. 여기서는 기기 밖 서버에서 발송된 · `Notification` 알림·통지. 여기서는 APNs 원격 알림 · `Payload` 적재물·실린 데이터. 여기서는 알림에 실려 온 userInfo 데이터를 문자열 사전으로 정규화한 것

## Storage/Stores

- **`AppGroupUserDefaults`** `enum` · public · [AppGroupUserDefaults.swift:5](../../../sources/Projects/Infrastructure/Storage/Stores/AppGroupUserDefaults.swift#L5)  
  App Group 공유 UserDefaults 관련 상수와 생성 함수를 모은 case 없는 enum 네임스페이스. appGroupIdentifier("group.com.nexters.hytime.gitit")와 sharedSessionNamespace 상수, suiteName으로 UserDefaults?를 만드는 makeShared()를 제공하며 Data의 StorageFactory가 appGroup 위치의 UserDefaultsStore를 만들 때 호출한다.  
  단어: `App` Application의 축약, 애플리케이션. 여기서는 iOS 앱 · `Group` 그룹·묶음. App+Group은 Apple 고정 명칭 App Group으로, 앱과 확장이 데이터를 공유하는 컨테이너 · `UserDefaults` 외부 고정 명칭. Foundation의 키-값 기본 설정 저장소로, 여기서는 App Group suite로 만든 공유 인스턴스
- **`UserDefaultsStore`** `actor` · public · [UserDefaultsStore.swift:3](../../../sources/Projects/Infrastructure/Storage/Stores/UserDefaultsStore.swift#L3)  
  namespace 접두어("\(namespace).")를 붙인 키로 Data를 UserDefaults에 저장·조회·삭제하는 actor. store(_:forKey:)·value(forKey:)·removeValue(forKey:)와 접두어가 일치하는 키 전체를 지우는 removeAll()을 제공하며, Data의 StorageFactory가 .standard 또는 App Group UserDefaults를 주입해 생성한다.  
  단어: `UserDefaults` 외부 고정 명칭. Foundation의 키-값 기본 설정 저장소로, 여기서는 실제 저장 대상 백엔드 · `Store` 저장소·보관하다. 여기서는 네임스페이스 키로 Data를 넣고 꺼내는 저장 객체
