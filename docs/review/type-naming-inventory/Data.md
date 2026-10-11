# Data 패키지 타입 목록

[인덱스로 돌아가기](README.md) · [단어 사전](glossary.md)

타입 136개, 관심사 폴더 53개. 항목은 파일 경로와 선언 줄 순서다. 각 항목은 `이름` 종류 · 접근 수준 · 파일 링크, 한 줄 설명, 그리고 이름을 이루는 단어와 정의로 구성된다.

| 종류 | 개수 |
|---|---|
| actor | 2 |
| class | 3 |
| enum | 41 |
| protocol | 6 |
| struct | 84 |

## Authentication/Codings

- **`SessionRecordStorageCoding`** `struct` · public · [SessionRecordStorageCoding.swift:6](../../../sources/Projects/Data/Authentication/Codings/SessionRecordStorageCoding.swift#L6) · 채택: Sendable  
  SecureValueStorage를 주입받아 StoredSessionRecord를 JSONEncoder/JSONDecoder로 직렬화하고 SessionStorageLayout.Key.sessionRecord 키로 load·save·delete하는 저장 코딩 래퍼입니다. RequestCredentialProvider와 Composition의 SignInRepositoryAdapter·UserInfoRepositoryAdapter가 세션 레코드 영속화에 사용합니다.  
  단어: `Session` 회기·접속 세션. 여기서는 로그인 후 유지되는 인증 세션 · `Record` 기록·레코드. 여기서는 토큰과 만료 시각 등을 담은 StoredSessionRecord 값 · `Storage` 저장소. 여기서는 주입받는 SecureValueStorage(보안 저장소) · `Coding` 부호화·인코딩/디코딩. 여기서는 레코드를 JSON Data로 변환해 저장소에 넣고 꺼내는 책임
- **`SharedSessionStateMarkerCoding`** `struct` · public · [SharedSessionStateMarkerCoding.swift:6](../../../sources/Projects/Data/Authentication/Codings/SharedSessionStateMarkerCoding.swift#L6) · 채택: Sendable  
  KeyValueStorage를 주입받아 "stateMarker" 키에 schemaVersion·isSignedIn·updatedAt을 가진 Marker를 저장하고, schemaVersion(1)이 일치할 때만 로그인 여부(Bool?)를 돌려주는 코딩 래퍼입니다. Composition의 AuthenticationAssembly·SessionAvailabilityAssembly·SignInRepositoryAdapter와 ShareExtension 구성에서 SessionStorageLayout.sharedSessionNamespace 저장소와 함께 앱·확장 간 로그인 상태 공유에 사용합니다.  
  단어: `Shared` 공유된. 여기서는 앱과 Share Extension이 함께 읽는 공유 저장소 영역 · `Session` 인증 세션. 여기서는 로그인 세션의 존재 여부 · `State` 상태. 여기서는 로그인됨/아님(isSignedIn) 상태 · `Marker` 표식·마커. 여기서는 세션 전체가 아니라 상태만 알리는 가벼운 표식 값 · `Coding` 인코딩/디코딩. 여기서는 Marker를 KeyValueStorage에 넣고 꺼내는 책임
- **`SharedSessionStateMarkerCoding.Marker`** `struct` · private · [SharedSessionStateMarkerCoding.swift:43](../../../sources/Projects/Data/Authentication/Codings/SharedSessionStateMarkerCoding.swift#L43) · 채택: Codable, Sendable  
  SharedSessionStateMarkerCoding 내부에 private으로 중첩된 저장 형식으로 schemaVersion(Int)·isSignedIn(Bool)·updatedAt(Date) 세 필드를 가집니다. save에서 생성되어 KeyValueStorage에 기록되고 loadSignedInState에서 다시 디코딩됩니다.  
  단어(단일): `Marker` 표식·마커. 여기서는 공유 저장소에 기록되는 로그인 상태 표식의 실제 Codable 값

## Authentication/DTOs/APIResponse

- **`APIResponseDTO`** `struct` · public · [APIResponseDTO.swift:1](../../../sources/Projects/Data/Authentication/DTOs/APIResponse/APIResponseDTO.swift#L1) · 채택: Decodable, Sendable  
  Payload 제네릭을 가진 서버 공통 응답 봉투(envelope)로 success·data(Payload?)·code·message·errors([FieldErrorDTO]?) 필드를 가집니다. AuthenticationRemote가 모든 인증 API 응답과 오류 본문을 이 형식으로 디코딩합니다.  
  단어: `API` Application Programming Interface. 여기서는 Git It 백엔드 서버 API · `Response` 응답. 여기서는 서버가 돌려주는 HTTP 응답 본문 · `DTO` Data Transfer Object. 여기서는 서버 JSON을 그대로 옮기는 디코딩 전용 구조체
- **`FieldErrorDTO`** `struct` · public · [FieldErrorDTO.swift:1](../../../sources/Projects/Data/Authentication/DTOs/APIResponse/FieldErrorDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  서버 응답의 필드 단위 검증 오류 하나를 나타내며 field(String)와 message(String?)를 가집니다. APIResponseDTO.errors 배열 요소이자 ServerAPIError.fieldErrors로 전달됩니다.  
  단어: `Field` 필드·항목. 여기서는 요청 본문에서 오류가 난 개별 필드 이름 · `Error` 오류. 여기서는 그 필드에 대한 서버 검증 오류 · `DTO` Data Transfer Object. 여기서는 서버 JSON 오류 항목을 옮기는 디코딩 전용 구조체

## Authentication/DTOs

- **`AppleLoginRequestDTO`** `struct` · public · [AppleLoginRequestDTO.swift:1](../../../sources/Projects/Data/Authentication/DTOs/AppleLoginRequestDTO.swift#L1) · 채택: CustomDebugStringConvertible, CustomStringConvertible, Encodable, Equatable, Sendable  
  Apple 로그인 API 요청 본문으로 idToken(String) 하나를 가지며 description/debugDescription에서 토큰을 <redacted>로 가립니다. AuthenticationRemote.appleLogin이 AuthenticationEndpoint.appleLogin의 body로 인코딩합니다.  
  단어: `Apple` 외부 고정 명칭(Apple). 여기서는 Sign in with Apple 경로 · `Login` 로그인. 여기서는 서버에 Apple 자격으로 로그인하는 행위 · `Request` 요청. 여기서는 HTTP 요청 본문 · `DTO` Data Transfer Object. 여기서는 서버로 보낼 JSON을 담는 인코딩 전용 구조체
- **`EmptyResponseData`** `struct` · internal · [EmptyResponseData.swift:4](../../../sources/Projects/Data/Authentication/DTOs/EmptyResponseData.swift#L4) · 채택: Decodable, Sendable  
  필드가 없는 빈 Decodable 구조체로, AuthenticationRemote가 verifyAccessToken처럼 data가 없는 응답의 Payload 타입으로 쓰고 오류 본문을 APIResponseDTO<EmptyResponseData>로 디코딩할 때도 사용합니다. 접근 수준은 internal입니다.  
  단어: `Empty` 비어 있는. 여기서는 필드가 하나도 없는 응답 페이로드 · `Response` 응답. 여기서는 서버 HTTP 응답 · `Data` 데이터. 여기서는 APIResponseDTO의 data 필드 자리에 오는 페이로드
- **`LoginResponseDTO`** `struct` · public · [LoginResponseDTO.swift:1](../../../sources/Projects/Data/Authentication/DTOs/LoginResponseDTO.swift#L1) · 채택: CustomDebugStringConvertible, CustomStringConvertible, Decodable, Equatable, Sendable  
  로그인 API 응답 페이로드로 accessToken·refreshToken(String)과 needsCuration(Bool)을 가지며 description에서 두 토큰을 <redacted>로 가립니다. AuthenticationRemote.appleLogin의 반환 타입입니다.  
  단어: `Login` 로그인. 여기서는 Apple 로그인 API 호출 · `Response` 응답. 여기서는 로그인 성공 시 서버가 주는 페이로드 · `DTO` Data Transfer Object. 여기서는 서버 JSON을 옮기는 디코딩 전용 구조체

## Authentication/Endpoints

- **`AuthenticationEndpoint`** `struct` · public · [AuthenticationEndpoint.swift:3](../../../sources/Projects/Data/Authentication/Endpoints/AuthenticationEndpoint.swift#L3) · 채택: Equatable, Sendable  
  인증 API 엔드포인트 정의로 transportMethod(HTTPMethod)와 path를 가지며 static 인스턴스 appleLogin(POST /api/v1/auth/login/apple)·verifyAccessToken(GET /api/v1/auth/token)을 제공합니다. headers(accessToken:)로 Accept·Content-Type과 선택적 Bearer Authorization 헤더를 만들고, AuthenticationRemote가 HTTPRequest를 구성할 때 사용합니다.  
  단어: `Authentication` 인증. 여기서는 로그인·토큰 검증 관련 서버 API 영역 · `Endpoint` 엔드포인트·종단점. 여기서는 HTTP 메서드와 경로 한 쌍으로 정의된 API 주소

## Authentication/Errors

- **`AppleSignInError`** `enum` · public · [AppleSignInError.swift:3](../../../sources/Projects/Data/Authentication/Errors/AppleSignInError.swift#L3) · 채택: Error, Equatable, Sendable  
  AppleSignInSource.authorize()가 던지는 typed throws 오류로 cancelled(사용자 취소)와 unavailable(그 외 실패·토큰 누락) 두 case를 가집니다. Composition의 AuthenticationRepositoryAdapter가 Domain 오류로 변환합니다.  
  단어: `Apple` 외부 고정 명칭(Apple). 여기서는 Sign in with Apple · `SignIn` Sign + In, 로그인. 여기서는 Apple 인증 창을 통한 로그인 시도 · `Error` 오류. 여기서는 로그인 시도가 실패한 이유
- **`AuthenticationServiceError`** `enum` · public · [AuthenticationServiceError.swift:1](../../../sources/Projects/Data/Authentication/Errors/AuthenticationServiceError.swift#L1) · 채택: CaseIterable, Equatable, Error, Sendable  
  AuthenticationRemote가 던지는 인증 서비스 오류로 invalidRequest·unauthorized·temporarilyUnavailable·transport·unexpectedStatus case를 가지며, init(from: ServerAPIError)가 HTTP 상태 400→invalidRequest, 401→unauthorized, 5xx→temporarilyUnavailable, 그 외→unexpectedStatus로 변환합니다. Composition의 SignInRepositoryAdapter가 처리합니다.  
  단어: `Authentication` 인증. 여기서는 인증 서버 API 호출 · `Service` 서비스. 여기서는 인증 API를 제공하는 원격 서비스 · `Error` 오류. 여기서는 원격 호출·응답 해석 실패를 분류한 값
- **`ServerAPIError`** `struct` · public · [ServerAPIError.swift:1](../../../sources/Projects/Data/Authentication/Errors/ServerAPIError.swift#L1) · 채택: Equatable, Error, Sendable  
  서버가 오류 응답으로 돌려준 정보를 담는 구조체로 httpStatus(Int)·code·message(String?)·fieldErrors([FieldErrorDTO]?)를 가집니다. AuthenticationRemote가 raw 오류 본문을 APIResponseDTO<EmptyResponseData>로 디코딩해 만들고, 곧바로 AuthenticationServiceError(from:)로 변환합니다.  
  단어: `Server` 서버. 여기서는 Git It 백엔드 · `API` Application Programming Interface. 여기서는 서버 HTTP API · `Error` 오류. 여기서는 서버가 명시적으로 반환한 오류 응답 내용

## Authentication/Layouts

- **`AppleIdentityStorageLayout`** `enum` · public · [AppleIdentityStorageLayout.swift:3](../../../sources/Projects/Data/Authentication/Layouts/AppleIdentityStorageLayout.swift#L3)  
  Apple 사용자 식별자를 보관하는 보안 저장소의 배치 정보를 모은 케이스 없는 네임스페이스 enum으로 namespace 상수 "com.nexters.hytime.gitit.authentication"과 중첩 Key enum을 가집니다. Composition의 ConcernUseCaseAssembly가 저장소 namespace로, AppleIdentityStore가 Key로 사용합니다.  
  단어: `Apple` 외부 고정 명칭(Apple). 여기서는 Sign in with Apple 사용자 · `Identity` 신원·식별. 여기서는 Apple 사용자 ID · `Storage` 저장소. 여기서는 SecureValueStorage 기반 보안 저장소 · `Layout` 배치·구성. 여기서는 저장소 namespace와 키 이름의 정의
- **`AppleIdentityStorageLayout.Key`** `enum` · public · [AppleIdentityStorageLayout.swift:7](../../../sources/Projects/Data/Authentication/Layouts/AppleIdentityStorageLayout.swift#L7) · 채택: String  
  AppleIdentityStorageLayout에 중첩된 String raw value enum으로 appleUserID case 하나를 가집니다. AppleIdentityStore가 rawValue를 보안 저장소 키로 사용합니다.  
  단어(단일): `Key` 키·열쇠. 여기서는 보안 저장소에서 Apple 사용자 ID를 찾는 문자열 키
- **`SessionStorageLayout`** `enum` · public · [SessionStorageLayout.swift:3](../../../sources/Projects/Data/Authentication/Layouts/SessionStorageLayout.swift#L3)  
  세션 저장소 배치 정보를 모은 케이스 없는 네임스페이스 enum으로 namespace "com.nexters.hytime.gitit.session", sharedSessionNamespace "com.nexters.hytime.gitit.sharedSession" 상수와 중첩 Key enum을 가집니다. Composition의 App·Member·Authentication·ShareExtension 어셈블리가 저장소를 만들 때 namespace를 참조하고 SessionRecordStorageCoding이 Key를 사용합니다.  
  단어: `Session` 인증 세션. 여기서는 로그인 세션 레코드 · `Storage` 저장소. 여기서는 보안 저장소와 앱·확장 공유 KeyValue 저장소 · `Layout` 배치·구성. 여기서는 두 namespace와 키 이름의 정의
- **`SessionStorageLayout.Key`** `enum` · public · [SessionStorageLayout.swift:7](../../../sources/Projects/Data/Authentication/Layouts/SessionStorageLayout.swift#L7) · 채택: String  
  SessionStorageLayout에 중첩된 String raw value enum으로 sessionRecord case 하나를 가집니다. SessionRecordStorageCoding이 rawValue를 StoredSessionRecord 저장 키로 사용합니다.  
  단어(단일): `Key` 키·열쇠. 여기서는 보안 저장소에서 세션 레코드를 찾는 문자열 키

## Authentication/Models

- **`AppleSignInCredential`** `struct` · public · [AppleSignInCredential.swift:3](../../../sources/Projects/Data/Authentication/Models/AppleSignInCredential.swift#L3) · 채택: CustomDebugStringConvertible, CustomStringConvertible, Equatable, Sendable  
  Apple 인증 성공 결과로 userID와 identityToken(String)을 가지며 description은 "AppleSignInCredential(<redacted>)"로 내용을 가립니다. AppleSignInSource.authorize()가 Infrastructure의 AppleCredential을 UTF-8 문자열 토큰으로 변환해 만듭니다.  
  단어: `Apple` 외부 고정 명칭(Apple). 여기서는 Sign in with Apple · `SignIn` Sign + In, 로그인. 여기서는 Apple 인증 창 로그인 · `Credential` 자격 증명. 여기서는 사용자 ID와 identity token 쌍
- **`AppleSignInState`** `enum` · public · [AppleSignInState.swift:3](../../../sources/Projects/Data/Authentication/Models/AppleSignInState.swift#L3) · 채택: Equatable, Sendable  
  저장된 Apple 사용자 ID의 자격 상태로 authorized·reauthenticationRequired·temporarilyUnavailable case를 가집니다. AppleSignInSource.state(forUserID:)가 Infrastructure의 AppleCredentialState(revoked·notFound·transferred는 reauthenticationRequired로)를 이 값으로 요약하고, AuthenticationRepositoryAdapter가 사용합니다.  
  단어: `Apple` 외부 고정 명칭(Apple). 여기서는 Apple ID 자격 · `SignIn` Sign + In, 로그인. 여기서는 Apple 로그인 자격 · `State` 상태. 여기서는 자격이 유효한지·재인증이 필요한지의 상태
- **`StoredSessionRecord`** `struct` · public · [StoredSessionRecord.swift:5](../../../sources/Projects/Data/Authentication/Models/StoredSessionRecord.swift#L5) · 채택: Codable, Equatable, Sendable  
  보안 저장소에 영속되는 세션 레코드로 accessToken·refreshToken, accessTokenExpiresAt·refreshTokenExpiresAt(Date?), needsCuration(Bool), acceptedLegalVersions([String]), acceptedAt(Date?)를 가집니다. SessionRecordStorageCoding이 JSON으로 저장하고 RequestCredentialProvider와 Composition의 SignInRepositoryAdapter·UserInfoRepositoryAdapter가 읽습니다.  
  단어: `Stored` 저장된. 여기서는 보안 저장소에 영속된 형태임을 나타냄 · `Session` 인증 세션. 여기서는 로그인 후 유지되는 토큰 세션 · `Record` 기록·레코드. 여기서는 토큰·만료·약관 동의 정보를 묶은 값

## Authentication/Remotes

- **`AuthenticationRemote`** `struct` · public · [AuthenticationRemote.swift:7](../../../sources/Projects/Data/Authentication/Remotes/AuthenticationRemote.swift#L7) · 채택: Sendable  
  RequestClientFactory로 만든 HTTPClient와 RequestCredential을 주는 클로저를 보유하고 appleLogin(idToken:)→LoginResponseDTO, verifyAccessToken()을 제공하는 인증 원격 접근자입니다. 응답을 APIResponseDTO 봉투로 디코딩해 payload를 꺼내고, raw 오류 본문은 ServerAPIError를 거쳐, HTTPClientError는 직접 AuthenticationServiceError로 변환하며 Composition의 SignInRepositoryAdapter가 사용합니다.  
  단어: `Authentication` 인증. 여기서는 로그인·토큰 검증 서버 API · `Remote` 원격. 여기서는 네트워크 너머 서버에 요청을 보내는 접근 계층

## Authentication/Sources

- **`AppleSignInSource`** `actor` · public · [AppleSignInSource.swift:6](../../../sources/Projects/Data/Authentication/Sources/AppleSignInSource.swift#L6)  
  Infrastructure의 AppleAuthorizationProvider·AppleCredentialStateProvider를 클로저로 감싼 actor로 authorize()는 AppleCredential을 AppleSignInCredential로 변환하고 취소는 AppleSignInError.cancelled, 그 외·토큰 누락은 unavailable로 던집니다. state(forUserID:)는 AppleCredentialState를 AppleSignInState로 요약하며 Composition의 AuthenticationRepositoryAdapter가 사용합니다.  
  단어: `Apple` 외부 고정 명칭(Apple). 여기서는 Sign in with Apple 플랫폼 기능 · `SignIn` Sign + In, 로그인. 여기서는 Apple 인증 창을 통한 로그인 · `Source` 출처·소스. 여기서는 플랫폼 인증 결과를 가져오는 데이터 소스

## Authentication/Stores

- **`AppleIdentityStore`** `struct` · public · [AppleIdentityStore.swift:6](../../../sources/Projects/Data/Authentication/Stores/AppleIdentityStore.swift#L6) · 채택: Sendable  
  SecureValueStorage를 주입받아 Apple 사용자 ID 문자열을 UTF-8 Data로 AppleIdentityStorageLayout.Key.appleUserID 키에 load·save·delete하는 저장소 래퍼입니다. Composition의 AuthenticationRepositoryAdapter·SignInRepositoryAdapter가 사용합니다.  
  단어: `Apple` 외부 고정 명칭(Apple). 여기서는 Apple ID 사용자 · `Identity` 신원·식별. 여기서는 Apple 사용자 ID 문자열 · `Store` 저장소. 여기서는 보안 저장소에 값을 넣고 꺼내는 접근 객체
- **`RequestCredentialProvider`** `class` · public · [RequestCredentialProvider.swift:7](../../../sources/Projects/Data/Authentication/Stores/RequestCredentialProvider.swift#L7) · 채택: Sendable  
  SessionRecordStorageCoding과 now 클로저를 가진 final class로 credential()은 저장된 레코드의 accessToken을 RequestCredential.available로 돌려주고 만료됐거나 없으면 .signedOut을 반환하며, credentialRejected()와 만료 시 레코드를 삭제하고 invalidations() AsyncStream 구독자(Mutex로 보호)에 알립니다. Composition의 AuthenticationAssembly·SessionAvailabilityAssembly·SignInRepositoryAdapter가 사용합니다.  
  단어: `Request` 요청. 여기서는 서버 HTTP 요청 · `Credential` 자격 증명. 여기서는 요청에 실을 access token 상태(RequestCredential) · `Provider` 제공자. 여기서는 저장된 세션에서 자격을 읽어 제공하고 무효화를 알리는 객체

## ExternalRepository/DTOs

- **`GitHubRepositoryResponseDTO`** `struct` · public · [GitHubRepositoryResponseDTO.swift:1](../../../sources/Projects/Data/ExternalRepository/DTOs/GitHubRepositoryResponseDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  GitHub 저장소 조회 API 응답으로 htmlURL·ownerLogin·repositoryName·ownerAvatarURL(String?)·starCount(Int)·topics([String])를 가지며, 커스텀 init(from:)이 중첩 owner 객체를 평탄화해 디코딩합니다. ExternalRepositoryRemote.repository의 반환 타입입니다.  
  단어: `GitHub` 외부 고정 명칭(GitHub). 여기서는 GitHub REST API · `Repository` 저장소. 여기서는 GitHub의 git 저장소 · `Response` 응답. 여기서는 저장소 조회 API 응답 본문 · `DTO` Data Transfer Object. 여기서는 GitHub JSON을 옮기는 디코딩 전용 구조체
- **`GitHubRepositoryResponseDTO.CodingKeys`** `enum` · private · [GitHubRepositoryResponseDTO.swift:43](../../../sources/Projects/Data/ExternalRepository/DTOs/GitHubRepositoryResponseDTO.swift#L43) · 채택: String, CodingKey  
  GitHubRepositoryResponseDTO에 private으로 중첩된 CodingKey enum으로 htmlURL→"html_url", owner, repositoryName→"name", starCount→"stargazers_count", topics 키를 매핑합니다. 커스텀 init(from:)의 최상위 컨테이너 키로 사용됩니다.  
  단어(단일): `CodingKeys` 외부 고정 명칭(Swift Codable 관례, Coding + Keys). 여기서는 GitHub JSON 최상위 필드 이름 매핑
- **`GitHubRepositoryResponseDTO.OwnerCodingKeys`** `enum` · private · [GitHubRepositoryResponseDTO.swift:51](../../../sources/Projects/Data/ExternalRepository/DTOs/GitHubRepositoryResponseDTO.swift#L51) · 채택: String, CodingKey  
  GitHubRepositoryResponseDTO에 private으로 중첩된 CodingKey enum으로 owner 중첩 객체의 login과 avatarURL→"avatar_url" 키를 매핑합니다. init(from:)의 nestedContainer(forKey: .owner)에 사용됩니다.  
  단어: `Owner` 소유자. 여기서는 GitHub 저장소 소유자 객체 · `CodingKeys` 외부 고정 명칭(Swift Codable 관례, Coding + Keys). 여기서는 owner 하위 JSON 필드 이름 매핑

## ExternalRepository/Errors

- **`ExternalRepositoryFetchError`** `enum` · public · [ExternalRepositoryFetchError.swift:1](../../../sources/Projects/Data/ExternalRepository/Errors/ExternalRepositoryFetchError.swift#L1) · 채택: CaseIterable, Equatable, Error, Sendable  
  외부 저장소 조회 실패를 offline(connectionFailed·timedOut)과 other(그 외) 두 case로 나눈 오류입니다. ExternalRepositoryRemote가 HTTPClientError를 이 값으로 변환해 던지고 Composition의 ExternalRepositoryLookupAdapter가 처리합니다.  
  단어: `External` 외부의. 여기서는 앱 밖 서비스(GitHub)에 있는 저장소 · `Repository` 저장소. 여기서는 git 저장소 · `Fetch` 가져오기. 여기서는 네트워크로 저장소 정보를 조회하는 동작 · `Error` 오류. 여기서는 조회 실패 원인 분류

## ExternalRepository/Models

- **`ExternalRepositoryLocation`** `struct` · public · [ExternalRepositoryLocation.swift:3](../../../sources/Projects/Data/ExternalRepository/Models/ExternalRepositoryLocation.swift#L3) · 채택: Equatable, Sendable  
  외부 저장소의 위치를 owner와 name 두 String으로 나타내는 값 타입으로 GitHubRepositoryURLParser.location(from:)이 만들고 Composition의 ExternalRepositoryLocatorAdapter가 사용합니다. Domain 패키지의 sources/Projects/Domain/ExternalRepository/Models/ExternalRepositoryLocation.swift에도 같은 이름의 별개 타입이 존재합니다.  
  단어: `External` 외부의. 여기서는 GitHub 같은 외부 서비스 · `Repository` 저장소. 여기서는 git 저장소 · `Location` 위치. 여기서는 소유자와 이름으로 특정되는 저장소 좌표

## ExternalRepository/Parsers

- **`GitHubRepositoryURLParser`** `struct` · public · [GitHubRepositoryURLParser.swift:5](../../../sources/Projects/Data/ExternalRepository/Parsers/GitHubRepositoryURLParser.swift#L5) · 채택: Sendable  
  문자열 URL을 공백 제거·https:// 보정 후 URLComponents로 해석해 host가 github.com 또는 www.github.com이고 경로 세그먼트가 2개 이상이면 owner·name(.git 접미사 제거)으로 ExternalRepositoryLocation을 만드는 파서입니다. Composition의 ExternalRepositoryLocatorAdapter·ExternalRepositoryAssembly가 사용합니다.  
  단어: `GitHub` 외부 고정 명칭(GitHub). 여기서는 github.com 호스트 · `Repository` 저장소. 여기서는 git 저장소 페이지 · `URL` Uniform Resource Locator. 여기서는 사용자가 입력한 저장소 주소 문자열 · `Parser` 해석기·파서. 여기서는 URL에서 owner/name을 추출하는 객체

## ExternalRepository/Remotes

- **`ExternalRepositoryRemote`** `struct` · public · [ExternalRepositoryRemote.swift:7](../../../sources/Projects/Data/ExternalRepository/Remotes/ExternalRepositoryRemote.swift#L7) · 채택: Sendable  
  RequestClientFactory로 만든 HTTPClient를 보유하고 repository(_ request: GitHubRepositoryRequest)로 GET 요청을 보내 GitHubRepositoryResponseDTO를 돌려주는 원격 접근자입니다. raw 응답과 HTTPClientError를 ExternalRepositoryFetchError(offline/other)로 변환하고 취소는 CancellationError로 다시 던지며 Composition의 ExternalRepositoryLookupAdapter·ExternalRepositoryAssembly가 사용합니다.  
  단어: `External` 외부의. 여기서는 GitHub 같은 외부 서비스 · `Repository` 저장소. 여기서는 git 저장소 · `Remote` 원격. 여기서는 네트워크로 외부 API에 요청을 보내는 접근 계층

## ExternalRepository/Requests

- **`GitHubRepositoryRequest`** `struct` · public · [GitHubRepositoryRequest.swift:1](../../../sources/Projects/Data/ExternalRepository/Requests/GitHubRepositoryRequest.swift#L1) · 채택: Equatable, Sendable  
  init(owner:repository:)로 scheme "https", host "api.github.com", path "/repos/{owner}/{repository}", headers(Accept: application/vnd.github+json, X-GitHub-Api-Version: 2022-11-28)를 고정 생성하는 GitHub 저장소 조회 요청 값입니다. ExternalRepositoryRemote.repository가 path와 headers를 HTTPRequest로 옮기며 Composition의 ExternalRepositoryLookupAdapter가 만듭니다.  
  단어: `GitHub` 외부 고정 명칭(GitHub). 여기서는 api.github.com REST API · `Repository` 저장소. 여기서는 조회 대상 git 저장소 · `Request` 요청. 여기서는 저장소 조회 HTTP 요청의 주소·헤더 정의

## LearningProject/Contracts

- **`QuizGenerationOutcomeSource`** `protocol` · public · [QuizGenerationOutcomeSource.swift:1](../../../sources/Projects/Data/LearningProject/Contracts/QuizGenerationOutcomeSource.swift#L1) · 채택: Sendable  
  퀴즈 생성 결과(QuizGenerationOutcomeDTO)를 AsyncStream으로 내보내는 outcomes() 하나만 요구하는 Data 계층 계약. Data의 PushQuizGenerationOutcomeSource가 구현하고, Composition의 GenerationOutcomeRepositoryAdapter가 생성자로 주입받아 도메인 GenerationOutcome으로 변환한다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 GitHub 저장소로부터 생성되는 학습 퀴즈 · `Generation` 생성. 여기서는 서버가 퀴즈를 만드는 비동기 생성 작업 · `Outcome` 결과·성과. 여기서는 생성 작업의 최종 결과(완료 또는 실패) · `Source` 출처·공급원. 여기서는 결과 이벤트를 스트림으로 공급하는 주체

## LearningProject/DTOs/APIResponse

- **`APIResponseDTO`** `struct` · public · [APIResponseDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/APIResponse/APIResponseDTO.swift#L1) · 채택: Decodable, Sendable  
  제네릭 Payload를 감싸는 서버 API 공통 응답 봉투로 success, data(Payload?), code, message, errors([FieldErrorDTO]?)를 보유한다. LearningProjectRequestExecutor가 모든 LearningProject 응답을 APIResponseDTO<Payload>로 디코딩하고 data를 꺼내거나 code·message·errors로 ServerAPIError를 만든다.  
  단어: `API` Application Programming Interface, 응용 프로그램 인터페이스. 여기서는 Git It 서버의 HTTP API · `Response` 응답. 여기서는 서버가 돌려주는 공통 응답 봉투(envelope) · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 성공 여부·페이로드·오류 정보를 담는 응답 전송 객체
- **`FieldErrorDTO`** `struct` · public · [FieldErrorDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/APIResponse/FieldErrorDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  서버 유효성 오류 한 건을 나타내며 오류가 난 field 이름과 선택적 message를 보유한다. APIResponseDTO.errors 배열의 요소이고 ServerAPIError.fieldErrors로 전달된다.  
  단어: `Field` 필드·항목. 여기서는 요청 본문 중 유효성 오류가 발생한 필드 이름 · `Error` 오류. 여기서는 서버가 보고한 필드 단위 검증 오류 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 필드별 오류 정보를 담는 응답 전송 객체

## LearningProject/DTOs/Answer

- **`RubricCriterionResponseDTO`** `struct` · public · [RubricCriterionResponseDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/Answer/RubricCriterionResponseDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  서술형 채점 루브릭의 기준 한 항목으로 기준 설명 text와 배점 points를 보유한다. RubricResponseDTO.criteria 배열의 요소다.  
  단어: `Rubric` 루브릭·채점 기준표. 여기서는 서술형 답안을 채점하는 기준 체계 · `Criterion` 기준(단수). 여기서는 루브릭을 이루는 개별 채점 기준 한 항목 · `Response` 응답. 여기서는 서술형 답안 제출 응답에 포함된 데이터 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 채점 기준 항목을 담는 응답 전송 객체
- **`RubricResponseDTO`** `struct` · public · [RubricResponseDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/Answer/RubricResponseDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  서술형 답안 채점 결과 루브릭으로 criteria([RubricCriterionResponseDTO]), keyPoints, fullMarkExample, partialExample, zeroExample을 보유하고 criteria의 text를 개행으로 이어 붙인 feedback 계산 속성을 제공한다. score·feedback만 받아 기준 하나짜리 루브릭을 만드는 편의 init도 있으며 SubmitEssayAnswerResponseDTO.rubric으로 쓰인다.  
  단어: `Rubric` 루브릭·채점 기준표. 여기서는 서술형 답안의 채점 기준·핵심 포인트·예시 답안을 묶은 결과 · `Response` 응답. 여기서는 서술형 답안 제출 응답에 포함된 데이터 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 루브릭 전체를 담는 응답 전송 객체
- **`SubmitChoiceAnswerRequestDTO`** `struct` · public · [SubmitChoiceAnswerRequestDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/Answer/SubmitChoiceAnswerRequestDTO.swift#L1) · 채택: Encodable, Equatable, Sendable  
  객관식 답안 제출 요청 본문으로 선택한 보기 인덱스 selectedIndex 하나를 보유한다. Composition의 QuizAnswerRepositoryAdapter가 생성해 AnswerRemote의 객관식 제출 요청 body로 보낸다.  
  단어: `Submit` 제출하다. 여기서는 사용자의 답안을 서버에 제출하는 동작 · `Choice` 선택·보기. 여기서는 보기 중 하나를 고르는 객관식 문제 형식 · `Answer` 답·답안. 여기서는 사용자가 문제에 제출하는 답안 · `Request` 요청. 여기서는 서버로 보내는 제출 요청 본문 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 객관식 답안 제출 요청 전송 객체
- **`SubmitChoiceAnswerResponseDTO`** `struct` · public · [SubmitChoiceAnswerResponseDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/Answer/SubmitChoiceAnswerResponseDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  객관식 답안 제출 응답으로 questionID, 정답 여부 correct, 정답 보기 인덱스 answerIndex, 해설 explanation을 보유한다. AnswerRemote의 객관식 제출 메서드가 expecting 타입으로 디코딩해 반환한다.  
  단어: `Submit` 제출하다. 여기서는 답안 제출 동작의 결과 · `Choice` 선택·보기. 여기서는 객관식 문제 형식 · `Answer` 답·답안. 여기서는 제출된 객관식 답안 · `Response` 응답. 여기서는 제출 요청에 대한 서버 응답 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 정답 여부와 해설을 담는 응답 전송 객체
- **`SubmitChoiceAnswerResponseDTO.CodingKeys`** `enum` · private · [SubmitChoiceAnswerResponseDTO.swift:26](../../../sources/Projects/Data/LearningProject/DTOs/Answer/SubmitChoiceAnswerResponseDTO.swift#L26) · 채택: String, CodingKey  
  SubmitChoiceAnswerResponseDTO의 JSON 키 매핑으로 questionID 프로퍼티를 서버 키 "questionId"에 대응시키고 correct, answerIndex, explanation은 이름을 그대로 쓴다.  
  단어(단일): `CodingKeys` Coding + Keys, Swift Codable 표준의 외부 고정 명칭. 인코딩·디코딩 시 프로퍼티 이름과 JSON 키를 대응시키는 열거형
- **`SubmitEssayAnswerRequestDTO`** `struct` · public · [SubmitEssayAnswerRequestDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/Answer/SubmitEssayAnswerRequestDTO.swift#L1) · 채택: Encodable, Equatable, Sendable  
  서술형 답안 제출 요청 본문으로 답안 문자열 text 하나를 보유한다. QuizAnswerRepositoryAdapter가 생성해 AnswerRemote의 서술형 제출 요청 body로 보낸다.  
  단어: `Submit` 제출하다. 여기서는 답안을 서버에 제출하는 동작 · `Essay` 서술·논술. 여기서는 자유 서술형 문제 형식 · `Answer` 답·답안. 여기서는 사용자가 작성한 서술형 답안 · `Request` 요청. 여기서는 서버로 보내는 제출 요청 본문 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 서술형 답안 제출 요청 전송 객체
- **`SubmitEssayAnswerResponseDTO`** `struct` · public · [SubmitEssayAnswerResponseDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/Answer/SubmitEssayAnswerResponseDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  서술형 답안 제출 응답으로 questionID, 해설 explanation, 채점 결과 rubric(RubricResponseDTO)을 보유한다. AnswerRemote의 서술형 제출 메서드가 expecting 타입으로 디코딩해 반환한다.  
  단어: `Submit` 제출하다. 여기서는 답안 제출 동작의 결과 · `Essay` 서술·논술. 여기서는 서술형 문제 형식 · `Answer` 답·답안. 여기서는 제출된 서술형 답안 · `Response` 응답. 여기서는 제출 요청에 대한 서버 응답 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 해설과 루브릭 채점 결과를 담는 응답 전송 객체
- **`SubmitEssayAnswerResponseDTO.CodingKeys`** `enum` · private · [SubmitEssayAnswerResponseDTO.swift:16](../../../sources/Projects/Data/LearningProject/DTOs/Answer/SubmitEssayAnswerResponseDTO.swift#L16) · 채택: String, CodingKey  
  SubmitEssayAnswerResponseDTO의 JSON 키 매핑으로 questionID를 서버 키 "questionId"에 대응시키고 explanation, rubric은 이름을 그대로 쓴다.  
  단어(단일): `CodingKeys` Coding + Keys, Swift Codable 표준의 외부 고정 명칭. 인코딩·디코딩 시 프로퍼티 이름과 JSON 키를 대응시키는 열거형

## LearningProject/DTOs/Bookmark

- **`AvailableProjectResponseDTO`** `struct` · public · [AvailableProjectResponseDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/Bookmark/AvailableProjectResponseDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  북마크 목록 응답에 함께 오는 프로젝트 요약으로 projectID와 repositoryName(서버 키 projectName)을 보유한다. BookmarkedQuestionListResponseDTO.availableProjects 배열의 요소다.  
  단어: `Available` 이용 가능한. 여기서는 북마크 목록에서 선택할 수 있는(북마크가 속한) 프로젝트 · `Project` 프로젝트. 여기서는 GitHub 저장소 하나를 등록해 만든 학습 프로젝트 · `Response` 응답. 여기서는 북마크 목록 조회 응답에 포함된 데이터 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 프로젝트 식별자와 이름을 담는 응답 전송 객체
- **`AvailableProjectResponseDTO.CodingKeys`** `enum` · private · [AvailableProjectResponseDTO.swift:13](../../../sources/Projects/Data/LearningProject/DTOs/Bookmark/AvailableProjectResponseDTO.swift#L13) · 채택: String, CodingKey  
  AvailableProjectResponseDTO의 JSON 키 매핑으로 projectID를 "projectId"에, repositoryName을 서버 키 "projectName"에 대응시킨다.  
  단어(단일): `CodingKeys` Coding + Keys, Swift Codable 표준의 외부 고정 명칭. 인코딩·디코딩 시 프로퍼티 이름과 JSON 키를 대응시키는 열거형
- **`BookmarkQuestionRequestDTO`** `struct` · public · [BookmarkQuestionRequestDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/Bookmark/BookmarkQuestionRequestDTO.swift#L1) · 채택: Encodable, Equatable, Sendable  
  문제 북마크 설정·해제 요청 본문으로 원하는 북마크 상태 bookmarked(Bool) 하나를 보유한다. QuizBookmarkRepositoryAdapter가 생성해 BookmarkRemote.setBookmark의 body로 보낸다.  
  단어: `Bookmark` 북마크·즐겨찾기. 여기서는 문제를 나중에 다시 보도록 표시하는 동작 · `Question` 문제·질문. 여기서는 학습 세트 안의 퀴즈 문제 하나 · `Request` 요청. 여기서는 서버로 보내는 북마크 변경 요청 본문 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 북마크 상태 값을 담는 요청 전송 객체
- **`BookmarkQuestionResponseDTO`** `struct` · public · [BookmarkQuestionResponseDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/Bookmark/BookmarkQuestionResponseDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  문제 북마크 설정·해제 응답으로 서버가 확정한 북마크 상태 bookmarked(Bool) 하나를 보유한다. BookmarkRemote.setBookmark가 expecting 타입으로 디코딩해 반환한다.  
  단어: `Bookmark` 북마크·즐겨찾기. 여기서는 문제 북마크 변경 동작 · `Question` 문제·질문. 여기서는 북마크 대상 퀴즈 문제 · `Response` 응답. 여기서는 북마크 변경 요청에 대한 서버 응답 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 확정된 북마크 상태를 담는 응답 전송 객체
- **`BookmarkedQuestionListResponseDTO`** `struct` · public · [BookmarkedQuestionListResponseDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/Bookmark/BookmarkedQuestionListResponseDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  북마크된 문제 목록 조회 응답으로 totalCount, availableProjects([AvailableProjectResponseDTO]), bookmarks([BookmarkedQuestionResponseDTO])를 보유한다. BookmarkRemote.fetchBookmarks(projectID:)가 expecting 타입으로 디코딩해 반환한다.  
  단어: `Bookmarked` 북마크된(과거분사·상태). 여기서는 이미 북마크 표시가 된 문제 · `Question` 문제·질문. 여기서는 퀴즈 문제 · `List` 목록. 여기서는 북마크된 문제들의 묶음 · `Response` 응답. 여기서는 목록 조회 요청에 대한 서버 응답 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 총 개수·프로젝트 목록·북마크 목록을 담는 응답 전송 객체
- **`BookmarkedQuestionResponseDTO`** `struct` · public · [BookmarkedQuestionResponseDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/Bookmark/BookmarkedQuestionResponseDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  북마크된 문제 한 건으로 projectID, projectName, setID, setLabel, problemNumber, questionID, question 본문을 보유하며 projectName·setLabel·problemNumber·question은 init 기본값을 가진다. BookmarkedQuestionListResponseDTO.bookmarks 배열의 요소다.  
  단어: `Bookmarked` 북마크된(상태). 여기서는 북마크 표시가 된 문제 한 건 · `Question` 문제·질문. 여기서는 퀴즈 문제 · `Response` 응답. 여기서는 북마크 목록 조회 응답에 포함된 데이터 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 문제 위치와 본문을 담는 응답 전송 객체
- **`BookmarkedQuestionResponseDTO.CodingKeys`** `enum` · private · [BookmarkedQuestionResponseDTO.swift:35](../../../sources/Projects/Data/LearningProject/DTOs/Bookmark/BookmarkedQuestionResponseDTO.swift#L35) · 채택: String, CodingKey  
  BookmarkedQuestionResponseDTO의 JSON 키 매핑으로 projectID·setID·questionID를 각각 "projectId"·"setId"·"questionId"에 대응시키고 나머지는 이름을 그대로 쓴다.  
  단어(단일): `CodingKeys` Coding + Keys, Swift Codable 표준의 외부 고정 명칭. 인코딩·디코딩 시 프로퍼티 이름과 JSON 키를 대응시키는 열거형

## LearningProject/DTOs

- **`EmptyResponseData`** `struct` · internal · [EmptyResponseData.swift:4](../../../sources/Projects/Data/LearningProject/DTOs/EmptyResponseData.swift#L4) · 채택: Decodable, Sendable  
  저장 프로퍼티가 없는 빈 페이로드 타입으로, data 필드가 없는 응답(ProjectRemote.deleteProject 등)의 expecting 타입과 서버 오류 봉투를 APIResponseDTO<EmptyResponseData>로 디코딩할 때 쓰인다. LearningProjectRequestExecutor는 envelope.data가 nil이면 EmptyResponseData()를 Payload로 캐스팅해 반환한다.  
  단어: `Empty` 비어 있는. 여기서는 필드가 하나도 없는 페이로드 · `Response` 응답. 여기서는 서버 응답 봉투의 data 자리 · `Data` 데이터·자료. 여기서는 APIResponseDTO의 data 필드에 들어가는 페이로드
- **`QuizGenerationOutcomeDTO`** `struct` · public · [QuizGenerationOutcomeDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/QuizGenerationOutcomeDTO.swift#L1) · 채택: Equatable, Sendable  
  푸시 알림으로 전달된 퀴즈 생성 결과로 projectID와 status(RawStatus)를 보유하며, Decodable 대신 [String: String] 푸시 페이로드의 "projectId"·"status" 키에서 만드는 실패 가능 init을 제공한다. PushQuizGenerationOutcomeSource가 생성해 스트림으로 내보내고 GenerationOutcomeRepositoryAdapter가 도메인 GenerationOutcome으로 변환한다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 저장소로부터 생성되는 학습 퀴즈 · `Generation` 생성. 여기서는 서버의 비동기 퀴즈 생성 작업 · `Outcome` 결과·성과. 여기서는 생성 작업이 완료 또는 실패로 끝난 결과 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 푸시 페이로드를 옮겨 담은 전송 객체
- **`QuizGenerationOutcomeDTO.RawStatus`** `enum` · public · [QuizGenerationOutcomeDTO.swift:24](../../../sources/Projects/Data/LearningProject/DTOs/QuizGenerationOutcomeDTO.swift#L24) · 채택: String, Sendable  
  푸시 페이로드의 status 문자열을 그대로 옮긴 열거형으로 completed와 failed 두 케이스를 가진다. QuizGenerationOutcomeDTO.status의 타입이며 rawPayload init에서 RawStatus(rawValue:)로 파싱된다.  
  단어: `Raw` 가공되지 않은·원시. 여기서는 서버·푸시가 보낸 문자열 값을 도메인 변환 없이 그대로 담은 것 · `Status` 상태. 여기서는 퀴즈 생성 작업의 종료 상태(완료·실패)
- **`QuizGenerationStatusResponseDTO`** `struct` · public · [QuizGenerationStatusResponseDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/QuizGenerationStatusResponseDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  퀴즈 생성 상태 조회 응답으로 status 문자열 하나만 보유한다. production 코드의 Remote·Adapter 어디에서도 참조되지 않으며 Data 테스트(QuizGenerationStatusResponseDTOTests)에서 디코딩만 검증된다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 생성 대상 학습 퀴즈 · `Generation` 생성. 여기서는 퀴즈 생성 작업 · `Status` 상태. 여기서는 생성 작업의 현재 진행 상태 문자열 · `Response` 응답. 여기서는 상태 조회 요청에 대한 서버 응답 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 상태 문자열을 담는 응답 전송 객체

## LearningProject/DTOs/GenerationState

- **`GenerationRecordDTO`** `struct` · public · [GenerationRecordDTO.swift:3](../../../sources/Projects/Data/LearningProject/DTOs/GenerationState/GenerationRecordDTO.swift#L3) · 채택: Codable, Equatable, Sendable  
  로컬에 보관하는 퀴즈 생성 요청 기록 한 건으로 githubRepoURL, projectID?, requestedAt, status(String), finishedAt?를 보유한다. GenerationStateDTO.records의 요소이며 Composition의 PendingGenerationRepositoryAdapter가 도메인 GenerationRecord와 상호 변환한다.  
  단어: `Generation` 생성. 여기서는 저장소 등록 후 진행되는 퀴즈 생성 작업 · `Record` 기록. 여기서는 생성 요청 한 건의 진행 상태 기록 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 로컬 저장소에 Codable로 저장되는 기록 전송 객체
- **`GenerationStateDTO`** `struct` · public · [GenerationStateDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/GenerationState/GenerationStateDTO.swift#L1) · 채택: Codable, Equatable, Sendable  
  진행 중인 퀴즈 생성 기록들의 묶음으로 records([GenerationRecordDTO])만 보유한다. LocalPendingGenerationStore가 LocalKeyValueStorage에 저장·갱신하고 stateChanges() 스트림으로 변경을 알리며, PendingGenerationRepositoryAdapter가 도메인 GenerationState와 상호 변환한다.  
  단어: `Generation` 생성. 여기서는 퀴즈 생성 작업 · `State` 상태. 여기서는 대기·진행 중인 생성 기록 전체의 현재 상태 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 로컬 저장용 상태 전송 객체

## LearningProject/DTOs/LearningSet

- **`LearningSetResponseDTO`** `struct` · public · [LearningSetResponseDTO.swift:3](../../../sources/Projects/Data/LearningProject/DTOs/LearningSet/LearningSetResponseDTO.swift#L3) · 채택: Decodable, Equatable, Sendable  
  학습 세트 상세 조회 응답으로 setID, title, description, orientation, level, questions([QuestionResponseDTO])를 보유한다. LearningSetRemote.fetchLearningSet(projectID:setID:)가 expecting 타입으로 디코딩해 반환한다.  
  단어: `Learning` 학습. 여기서는 저장소 코드를 이해하기 위한 학습 활동 · `Set` 집합·묶음. 여기서는 프로젝트 하나에서 생성된 문제 묶음(학습 세트) · `Response` 응답. 여기서는 세트 상세 조회 요청에 대한 서버 응답 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 세트 메타데이터와 문제 목록을 담는 응답 전송 객체
- **`LearningSetResponseDTO.CodingKeys`** `enum` · private · [LearningSetResponseDTO.swift:34](../../../sources/Projects/Data/LearningProject/DTOs/LearningSet/LearningSetResponseDTO.swift#L34) · 채택: String, CodingKey  
  LearningSetResponseDTO의 JSON 키 매핑으로 setID를 "setId"에 대응시키고 title, description, orientation, level, questions는 이름을 그대로 쓴다.  
  단어(단일): `CodingKeys` Coding + Keys, Swift Codable 표준의 외부 고정 명칭. 인코딩·디코딩 시 프로퍼티 이름과 JSON 키를 대응시키는 열거형
- **`MyAnswerResponseDTO`** `struct` · public · [MyAnswerResponseDTO.swift:3](../../../sources/Projects/Data/LearningProject/DTOs/LearningSet/MyAnswerResponseDTO.swift#L3) · 채택: Decodable, Equatable, Sendable  
  사용자가 이미 제출한 답안 정보로 selectedIndex?, text?, correct?, answeredAt(Date)을 보유하며 객관식·서술형을 옵셔널 필드로 함께 표현한다. QuestionResponseDTO.myAnswer로 쓰인다.  
  단어: `My` 나의. 여기서는 현재 로그인한 사용자 본인이 제출한 · `Answer` 답·답안. 여기서는 문제에 대해 제출한 답안 · `Response` 응답. 여기서는 학습 세트 조회 응답에 포함된 데이터 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 기존 제출 답안을 담는 응답 전송 객체
- **`QuestionResponseDTO`** `struct` · public · [QuestionResponseDTO.swift:3](../../../sources/Projects/Data/LearningProject/DTOs/LearningSet/QuestionResponseDTO.swift#L3) · 채택: Decodable, Equatable, Sendable  
  학습 세트 안의 문제 한 건으로 questionID, format, text, choices([String]), sources([SourceResponseDTO]), myAnswer(MyAnswerResponseDTO?)를 보유한다. LearningSetResponseDTO.questions 배열의 요소다.  
  단어: `Question` 문제·질문. 여기서는 학습 세트에 속한 퀴즈 문제 하나 · `Response` 응답. 여기서는 학습 세트 조회 응답에 포함된 데이터 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 문제 본문·보기·출처·기존 답안을 담는 응답 전송 객체
- **`QuestionResponseDTO.CodingKeys`** `enum` · private · [QuestionResponseDTO.swift:34](../../../sources/Projects/Data/LearningProject/DTOs/LearningSet/QuestionResponseDTO.swift#L34) · 채택: String, CodingKey  
  QuestionResponseDTO의 JSON 키 매핑으로 questionID를 "questionId"에 대응시키고 format, text, choices, sources, myAnswer는 이름을 그대로 쓴다.  
  단어(단일): `CodingKeys` Coding + Keys, Swift Codable 표준의 외부 고정 명칭. 인코딩·디코딩 시 프로퍼티 이름과 JSON 키를 대응시키는 열거형
- **`SourceResponseDTO`** `struct` · public · [SourceResponseDTO.swift:3](../../../sources/Projects/Data/LearningProject/DTOs/LearningSet/SourceResponseDTO.swift#L3) · 채택: Decodable, Equatable, Sendable  
  문제의 출처가 된 저장소 코드 위치로 file, startLine, endLine, symbol, summary?, url을 보유한다. QuestionResponseDTO.sources 배열의 요소다.  
  단어: `Source` 출처·근원. 여기서는 문제가 만들어진 근거인 저장소 소스 코드 구간 · `Response` 응답. 여기서는 학습 세트 조회 응답에 포함된 데이터 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 파일·줄 범위·심벌·링크를 담는 응답 전송 객체

## LearningProject/DTOs/ProjectDetail

- **`ProjectDetailResponseDTO`** `struct` · public · [ProjectDetailResponseDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/ProjectDetail/ProjectDetailResponseDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  프로젝트 상세 조회 응답으로 projectID, repositoryURL, repositoryName, repositoryImageURL?, starCount, techStack, overallProgressPercent, nextQuestionID?, sets([ProjectSetSummaryDTO])를 보유한다. ProjectRemote.fetchProjectDetail(projectID:)가 expecting 타입으로 디코딩해 반환한다.  
  단어: `Project` 프로젝트. 여기서는 GitHub 저장소 하나를 등록해 만든 학습 프로젝트 · `Detail` 상세. 여기서는 프로젝트 한 건의 상세 정보 화면용 데이터 · `Response` 응답. 여기서는 상세 조회 요청에 대한 서버 응답 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 저장소 정보·진행률·세트 요약을 담는 응답 전송 객체
- **`ProjectDetailResponseDTO.CodingKeys`** `enum` · private · [ProjectDetailResponseDTO.swift:41](../../../sources/Projects/Data/LearningProject/DTOs/ProjectDetail/ProjectDetailResponseDTO.swift#L41) · 채택: String, CodingKey  
  ProjectDetailResponseDTO의 JSON 키 매핑으로 projectID·repositoryURL·repositoryImageURL·nextQuestionID를 각각 "projectId"·"repositoryUrl"·"repositoryImageUrl"·"nextQuestionId"에 대응시키고 나머지는 이름을 그대로 쓴다.  
  단어(단일): `CodingKeys` Coding + Keys, Swift Codable 표준의 외부 고정 명칭. 인코딩·디코딩 시 프로퍼티 이름과 JSON 키를 대응시키는 열거형
- **`ProjectSetSummaryDTO`** `struct` · public · [ProjectSetSummaryDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/ProjectDetail/ProjectSetSummaryDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  프로젝트 상세에 포함되는 학습 세트 요약으로 setID, label, title, problemCount, completedCount를 보유하며 두 개수는 init 기본값 0을 가진다. ProjectDetailResponseDTO.sets 배열의 요소다.  
  단어: `Project` 프로젝트. 여기서는 세트가 속한 학습 프로젝트 · `Set` 집합·묶음. 여기서는 프로젝트 안의 문제 묶음(학습 세트) · `Summary` 요약. 여기서는 세트의 제목과 진행 개수만 담은 요약 정보 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 세트 요약을 담는 응답 전송 객체
- **`ProjectSetSummaryDTO.CodingKeys`** `enum` · private · [ProjectSetSummaryDTO.swift:29](../../../sources/Projects/Data/LearningProject/DTOs/ProjectDetail/ProjectSetSummaryDTO.swift#L29) · 채택: String, CodingKey  
  ProjectSetSummaryDTO의 JSON 키 매핑으로 setID를 "setId"에 대응시키고 label, title, problemCount, completedCount는 이름을 그대로 쓴다.  
  단어(단일): `CodingKeys` Coding + Keys, Swift Codable 표준의 외부 고정 명칭. 인코딩·디코딩 시 프로퍼티 이름과 JSON 키를 대응시키는 열거형

## LearningProject/DTOs/ProjectList

- **`ProjectListItemDTO`** `struct` · public · [ProjectListItemDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/ProjectList/ProjectListItemDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  프로젝트 목록의 항목 한 건으로 projectID, repositoryName, repositoryImageURL?, techStack, currentSetLabel, currentSetTitle, nextSetID?, nextQuestionID?, overallProgressPercent를 보유한다. ProjectListResponseDTO.items 배열의 요소다.  
  단어: `Project` 프로젝트. 여기서는 등록된 학습 프로젝트 · `List` 목록. 여기서는 사용자의 프로젝트 목록 조회 결과 · `Item` 항목. 여기서는 목록을 이루는 프로젝트 한 건 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 목록 항목을 담는 응답 전송 객체
- **`ProjectListItemDTO.CodingKeys`** `enum` · private · [ProjectListItemDTO.swift:41](../../../sources/Projects/Data/LearningProject/DTOs/ProjectList/ProjectListItemDTO.swift#L41) · 채택: String, CodingKey  
  ProjectListItemDTO의 JSON 키 매핑으로 projectID·repositoryImageURL·nextSetID·nextQuestionID를 각각 "projectId"·"repositoryImageUrl"·"nextSetId"·"nextQuestionId"에 대응시키고 나머지는 이름을 그대로 쓴다.  
  단어(단일): `CodingKeys` Coding + Keys, Swift Codable 표준의 외부 고정 명칭. 인코딩·디코딩 시 프로퍼티 이름과 JSON 키를 대응시키는 열거형
- **`ProjectListResponseDTO`** `struct` · public · [ProjectListResponseDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/ProjectList/ProjectListResponseDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  페이지 단위 프로젝트 목록 조회 응답으로 items([ProjectListItemDTO])와 다음 페이지 존재 여부 hasNext를 보유한다. ProjectRemote.fetchProjects(page:size:)가 expecting 타입으로 디코딩해 반환한다.  
  단어: `Project` 프로젝트. 여기서는 등록된 학습 프로젝트 · `List` 목록. 여기서는 페이지네이션된 프로젝트 목록 · `Response` 응답. 여기서는 목록 조회 요청에 대한 서버 응답 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 항목 배열과 페이지 정보를 담는 응답 전송 객체

## LearningProject/DTOs/RegisterProject

- **`QuizLevelDTO`** `enum` · public · [QuizLevelDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/RegisterProject/QuizLevelDTO.swift#L1) · 채택: String, Decodable, Encodable, Equatable, Sendable  
  서버에 보내는 퀴즈 난이도 값으로 l1·l2·l3 케이스가 각각 "L1"·"L2"·"L3" 문자열에 대응한다. RegisterProjectRequestDTO.quizLevel의 타입이며 ProjectGenerationRepositoryAdapter가 도메인 QuizLevel에서 변환해 넣는다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 생성될 학습 퀴즈 · `Level` 수준·난이도. 여기서는 L1~L3 세 단계의 퀴즈 난이도 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 난이도 코드를 서버 문자열로 직렬화하는 전송 객체
- **`RegisterProjectRequestDTO`** `struct` · public · [RegisterProjectRequestDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/RegisterProject/RegisterProjectRequestDTO.swift#L1) · 채택: Encodable, Equatable, Sendable  
  프로젝트 등록 요청 본문으로 githubRepoURL(서버 키 githubRepoUrl)과 quizLevel(QuizLevelDTO)을 보유한다. ProjectGenerationRepositoryAdapter가 생성해 ProjectRemote.registerProject의 POST body로 보낸다.  
  단어: `Register` 등록하다. 여기서는 GitHub 저장소를 학습 프로젝트로 등록하는 동작 · `Project` 프로젝트. 여기서는 등록될 학습 프로젝트 · `Request` 요청. 여기서는 서버로 보내는 등록 요청 본문 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 저장소 URL과 난이도를 담는 요청 전송 객체
- **`RegisterProjectRequestDTO.CodingKeys`** `enum` · private · [RegisterProjectRequestDTO.swift:13](../../../sources/Projects/Data/LearningProject/DTOs/RegisterProject/RegisterProjectRequestDTO.swift#L13) · 채택: String, CodingKey  
  RegisterProjectRequestDTO의 JSON 키 매핑으로 githubRepoURL을 서버 키 "githubRepoUrl"에 대응시키고 quizLevel은 이름을 그대로 쓴다.  
  단어(단일): `CodingKeys` Coding + Keys, Swift Codable 표준의 외부 고정 명칭. 인코딩·디코딩 시 프로퍼티 이름과 JSON 키를 대응시키는 열거형
- **`RegisterProjectResponseDTO`** `struct` · public · [RegisterProjectResponseDTO.swift:1](../../../sources/Projects/Data/LearningProject/DTOs/RegisterProject/RegisterProjectResponseDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  프로젝트 등록 응답으로 새 projectID와 등록 요청 처리 상태 requestStatus(서버 키 status)를 보유한다. ProjectRemote.registerProject가 expecting 타입으로 디코딩해 반환한다.  
  단어: `Register` 등록하다. 여기서는 저장소 등록 동작의 결과 · `Project` 프로젝트. 여기서는 새로 등록된 학습 프로젝트 · `Response` 응답. 여기서는 등록 요청에 대한 서버 응답 · `DTO` Data Transfer Object, 계층 간 데이터 전달 전용 객체. 여기서는 생성된 프로젝트 ID와 요청 상태를 담는 응답 전송 객체
- **`RegisterProjectResponseDTO.CodingKeys`** `enum` · private · [RegisterProjectResponseDTO.swift:13](../../../sources/Projects/Data/LearningProject/DTOs/RegisterProject/RegisterProjectResponseDTO.swift#L13) · 채택: String, CodingKey  
  RegisterProjectResponseDTO의 JSON 키 매핑으로 projectID를 "projectId"에, requestStatus를 서버 키 "status"에 대응시킨다.  
  단어(단일): `CodingKeys` Coding + Keys, Swift Codable 표준의 외부 고정 명칭. 인코딩·디코딩 시 프로퍼티 이름과 JSON 키를 대응시키는 열거형

## LearningProject/Endpoints

- **`AnswerEndpoint`** `enum` · public · [AnswerEndpoint.swift:1](../../../sources/Projects/Data/LearningProject/Endpoints/AnswerEndpoint.swift#L1) · 채택: Equatable, Sendable  
  퀴즈 답안 제출 API의 접속 지점을 choice(객관식)·essay(서술형) 두 case로 표현하고, request 계산 속성에서 POST `/api/v1/projects/{projectID}/questions/{questionID}/answers/choice\|essay` 경로의 LearningProjectRequest를 만든다. AnswerRemote가 submitChoiceAnswer·submitEssayAnswer에서 사용한다.  
  단어: `Answer` 답·답안. 여기서는 퀴즈 문항에 대해 사용자가 제출하는 객관식·서술형 답안 · `Endpoint` API 끝점·접속 지점. 여기서는 답안 제출 서버 API의 HTTP 메서드와 경로 조합
- **`AuthorizedRequestHeaders`** `struct` · internal · [AuthorizedRequestHeaders.swift:3](../../../sources/Projects/Data/LearningProject/Endpoints/AuthorizedRequestHeaders.swift#L3) · 채택: Equatable, Sendable  
  액세스 토큰을 받아 `Authorization: Bearer …`, `Accept`, `Content-Type`(application/json) 세 헤더를 담은 HTTPHeaders를 headers 속성으로 보유한다. LearningProjectRequestExecutor가 자격 증명이 available일 때 요청 헤더를 만들 때만 사용한다.  
  단어: `Authorized` 인증·권한이 부여된. 여기서는 Bearer 액세스 토큰이 포함된 상태 · `Request` 요청. 여기서는 학습 프로젝트 서버로 보내는 HTTP 요청 · `Headers` 머리말·헤더 목록. 여기서는 HTTP 요청 헤더 사전(HTTPHeaders)
- **`BookmarkEndpoint`** `enum` · public · [BookmarkEndpoint.swift:1](../../../sources/Projects/Data/LearningProject/Endpoints/BookmarkEndpoint.swift#L1) · 채택: Equatable, Sendable  
  북마크 API 접속 지점을 set(projectID, questionID)과 list(projectID?) 두 case로 표현하며, set은 POST `…/questions/{questionID}/bookmark`, list는 GET `/api/v1/projects/bookmarks`(projectID가 있으면 `projectId` 쿼리 포함) LearningProjectRequest를 만든다. BookmarkRemote가 사용한다.  
  단어: `Bookmark` 책갈피·즐겨찾기. 여기서는 퀴즈 문항을 저장해 두는 북마크 기능 · `Endpoint` API 끝점·접속 지점. 여기서는 북마크 설정·목록 조회 서버 API의 메서드와 경로 조합
- **`LearningProjectRequest`** `struct` · public · [LearningProjectRequest.swift:5](../../../sources/Projects/Data/LearningProject/Endpoints/LearningProjectRequest.swift#L5) · 채택: Equatable, Sendable · 그래프 미수집(grep 보강)  
  학습 프로젝트 API 요청 한 건을 HTTPMethod(transportMethod, internal)·path·queryItems로 표현하는 값이며 basePath `/api/v1/projects` 상수를 제공한다. 각 Endpoint enum이 이 값을 만들고 LearningProjectRequestExecutor가 HTTPRequest로 변환해 전송한다.  
  단어: `Learning` 학습. 여기서는 Git 저장소를 바탕으로 퀴즈를 만들어 학습하는 기능 영역 · `Project` 프로젝트. 여기서는 학습 대상으로 등록한 Git 저장소 프로젝트 · `Request` 요청. 여기서는 서버 API로 보낼 메서드·경로·쿼리 조합
- **`LearningSetEndpoint`** `enum` · public · [LearningSetEndpoint.swift:1](../../../sources/Projects/Data/LearningProject/Endpoints/LearningSetEndpoint.swift#L1) · 채택: Equatable, Sendable  
  학습 세트 조회 API 접속 지점을 detail(projectID, setID) 한 case로 표현하고 GET `/api/v1/projects/{projectID}/sets/{setID}` LearningProjectRequest를 만든다. LearningSetRemote.fetchLearningSet이 사용한다.  
  단어: `Learning` 학습. 여기서는 프로젝트로 생성된 퀴즈를 푸는 학습 기능 · `Set` 집합·묶음. 여기서는 프로젝트 하나에서 생성된 퀴즈 묶음(학습 세트) · `Endpoint` API 끝점·접속 지점. 여기서는 학습 세트 상세 조회 서버 API의 메서드와 경로
- **`ProjectEndpoint`** `enum` · public · [ProjectEndpoint.swift:1](../../../sources/Projects/Data/LearningProject/Endpoints/ProjectEndpoint.swift#L1) · 채택: Equatable, Sendable  
  프로젝트 API 접속 지점을 register(POST basePath)·list(page, size 쿼리 GET)·detail(projectID GET)·delete(projectID DELETE) 네 case로 표현하고 request에서 LearningProjectRequest를 만든다. ProjectRemote는 같은 요청을 직접 생성하므로 현재 이 enum은 ProjectEndpointTests에서만 참조된다.  
  단어: `Project` 프로젝트. 여기서는 학습 대상으로 등록·조회·삭제하는 Git 저장소 프로젝트 · `Endpoint` API 끝점·접속 지점. 여기서는 프로젝트 등록·목록·상세·삭제 서버 API의 메서드와 경로
- **`QuizGenerationEndpoint`** `enum` · public · [QuizGenerationEndpoint.swift:1](../../../sources/Projects/Data/LearningProject/Endpoints/QuizGenerationEndpoint.swift#L1) · 채택: Equatable, Sendable  
  퀴즈 생성 API 접속 지점을 status(projectID, GET `…/{projectID}/status`)와 retry(projectID, POST `…/{projectID}/quiz-generation/retry`) 두 case로 표현한다. Data와 Composition의 production 코드에서는 호출되지 않으며 QuizGenerationEndpointTests에서만 참조된다.  
  단어: `Quiz` 퀴즈·문제. 여기서는 프로젝트 소스로부터 서버가 만드는 학습 문제 · `Generation` 생성. 여기서는 서버의 퀴즈 생성 작업 · `Endpoint` API 끝점·접속 지점. 여기서는 퀴즈 생성 상태 조회·재시도 서버 API의 메서드와 경로

## LearningProject/Errors

- **`LearningProjectServiceError`** `enum` · public · [LearningProjectServiceError.swift:1](../../../sources/Projects/Data/LearningProject/Errors/LearningProjectServiceError.swift#L1) · 채택: CaseIterable, Equatable, Error, Sendable  
  학습 프로젝트 서버 통신에서 Data 계층이 던지는 오류를 invalidRequest·unauthorized·temporarilyUnavailable·transport·unexpectedStatus·projectUnavailable·questionUnavailable·learningSetUnavailable로 분류하며, init(from: ServerAPIError)가 HTTP 상태와 서버 코드(400, 401, 404+PROJECT-001/QUIZ-005/QUIZ-006, 5xx)를 case로 매핑한다. LearningProjectRequestExecutor가 던지고 Composition의 LearningProject 어댑터들이 Domain 오류로 변환한다.  
  단어: `Learning` 학습. 여기서는 퀴즈 생성·풀이 학습 기능 영역 · `Project` 프로젝트. 여기서는 학습 대상 Git 저장소 프로젝트 · `Service` 서비스·서버 측 기능. 여기서는 학습 프로젝트 서버 API 서비스 · `Error` 오류. 여기서는 서버 응답·전송 실패를 Data 언어로 분류한 오류
- **`ServerAPIError`** `struct` · public · [ServerAPIError.swift:1](../../../sources/Projects/Data/LearningProject/Errors/ServerAPIError.swift#L1) · 채택: Equatable, Error, Sendable  
  서버가 실패 응답 봉투로 돌려준 httpStatus·code·message·fieldErrors([FieldErrorDTO]?)를 그대로 담는 오류 값이다. LearningProjectRequestExecutor.serverError가 raw 응답을 디코드해 만들고 LearningProjectServiceError(from:)의 입력이 되며, DataMember 모듈에도 같은 이름·구조의 별도 타입이 있다.  
  단어: `Server` 서버. 여기서는 Git It 백엔드 API 서버 · `API` Application Programming Interface. 서버가 제공하는 HTTP 인터페이스 · `Error` 오류. 여기서는 서버가 응답 본문으로 알린 상태 코드·오류 코드·메시지 묶음

## LearningProject/Remotes

- **`AnswerRemote`** `struct` · public · [AnswerRemote.swift:7](../../../sources/Projects/Data/LearningProject/Remotes/AnswerRemote.swift#L7) · 채택: Sendable  
  답안 제출 서버 통신을 담당하는 원격 접근 타입으로, public init은 baseURL·transport·responseTimeout·credential·credentialRejected를 받아 RequestClientFactory로 HTTPClient를 만들고 내부 init은 LearningProjectRequestExecutor를 구성한다. submitChoiceAnswer·submitEssayAnswer가 AnswerEndpoint로 요청해 SubmitChoiceAnswerResponseDTO·SubmitEssayAnswerResponseDTO를 반환하며 Composition의 QuizAnswerRepositoryAdapter가 사용한다.  
  단어: `Answer` 답·답안. 여기서는 퀴즈 문항에 제출하는 객관식·서술형 답안 · `Remote` 원격·서버 측. 여기서는 답안 제출 서버 API를 호출하는 원격 데이터 접근 객체
- **`BookmarkRemote`** `struct` · public · [BookmarkRemote.swift:7](../../../sources/Projects/Data/LearningProject/Remotes/BookmarkRemote.swift#L7) · 채택: Sendable  
  북마크 서버 통신을 담당하는 원격 접근 타입으로 AnswerRemote와 같은 생성 경로로 LearningProjectRequestExecutor를 구성한다. setBookmark(projectID, questionID, BookmarkQuestionRequestDTO)와 fetchBookmarks(projectID?)가 BookmarkEndpoint로 요청해 BookmarkQuestionResponseDTO·BookmarkedQuestionListResponseDTO를 반환하며 Composition의 QuizBookmarkRepositoryAdapter가 사용한다.  
  단어: `Bookmark` 책갈피·즐겨찾기. 여기서는 퀴즈 문항 북마크 설정과 목록 · `Remote` 원격·서버 측. 여기서는 북마크 서버 API를 호출하는 원격 데이터 접근 객체
- **`LearningProjectRequestExecutor`** `struct` · internal · [LearningProjectRequestExecutor.swift:7](../../../sources/Projects/Data/LearningProject/Remotes/LearningProjectRequestExecutor.swift#L7) · 채택: Sendable  
  HTTPClient·credential 클로저·credentialRejected 클로저를 보유하고 send(_:expecting:)·send(_:body:expecting:)에서 LearningProjectRequest를 AuthorizedRequestHeaders가 붙은 HTTPRequest로 바꿔 APIResponseDTO<Payload> 봉투를 받은 뒤 data(없으면 EmptyResponseData)를 꺼낸다. raw 실패 응답은 ServerAPIError→LearningProjectServiceError로, HTTPClientError는 LearningProjectServiceError로 변환하고 unauthorized면 credentialRejected를 호출하며, Answer·Bookmark·LearningSet·ProjectRemote가 공유한다.  
  단어: `Learning` 학습. 여기서는 퀴즈 생성·풀이 학습 기능 영역 · `Project` 프로젝트. 여기서는 학습 대상 Git 저장소 프로젝트 · `Request` 요청. 여기서는 LearningProjectRequest로 표현된 서버 API 요청 · `Executor` 실행자. 여기서는 요청 전송·봉투 해석·오류 변환을 실제로 수행하는 객체
- **`LearningSetRemote`** `struct` · public · [LearningSetRemote.swift:7](../../../sources/Projects/Data/LearningProject/Remotes/LearningSetRemote.swift#L7) · 채택: Sendable  
  학습 세트 조회 서버 통신을 담당하는 원격 접근 타입으로 다른 Remote와 같은 생성 경로로 LearningProjectRequestExecutor를 구성한다. fetchLearningSet(projectID, setID)가 LearningSetEndpoint.detail로 요청해 LearningSetResponseDTO를 반환하며 Composition의 QuizSetRepositoryAdapter가 사용한다.  
  단어: `Learning` 학습. 여기서는 프로젝트로 생성된 퀴즈를 푸는 학습 기능 · `Set` 집합·묶음. 여기서는 프로젝트 하나에서 생성된 퀴즈 묶음(학습 세트) · `Remote` 원격·서버 측. 여기서는 학습 세트 서버 API를 호출하는 원격 데이터 접근 객체
- **`ProjectRemote`** `struct` · public · [ProjectRemote.swift:7](../../../sources/Projects/Data/LearningProject/Remotes/ProjectRemote.swift#L7) · 채택: Sendable  
  프로젝트 서버 통신을 담당하는 원격 접근 타입으로 registerProject(RegisterProjectRequestDTO)·fetchProjects(page, size)·fetchProjectDetail(projectID)·deleteProject(projectID)를 제공하며, ProjectEndpoint 대신 LearningProjectRequest를 메서드 안에서 직접 만들어 LearningProjectRequestExecutor로 보낸다. Composition의 ProjectRepositoryAdapter·ProjectGenerationRepositoryAdapter·LearningProjectAssembly가 사용한다.  
  단어: `Project` 프로젝트. 여기서는 학습 대상으로 등록·조회·삭제하는 Git 저장소 프로젝트 · `Remote` 원격·서버 측. 여기서는 프로젝트 서버 API를 호출하는 원격 데이터 접근 객체

## LearningProject/Sources

- **`PushQuizGenerationOutcomeSource`** `class` · public · [PushQuizGenerationOutcomeSource.swift:7](../../../sources/Projects/Data/LearningProject/Sources/PushQuizGenerationOutcomeSource.swift#L7) · 채택: QuizGenerationOutcomeSource, Sendable  
  푸시 알림으로 도착한 퀴즈 생성 결과를 스트림으로 흘려보내는 QuizGenerationOutcomeSource 구현체다. outcomes()는 UUID 키로 continuation을 Mutex<State>에 등록한 AsyncStream<QuizGenerationOutcomeDTO>를 돌려주고, ingest(rawPayload:)는 [String: String] payload를 QuizGenerationOutcomeDTO로 파싱해 모든 구독자에 yield하며 os.Logger로 파싱 성패를 기록한다. AppComposition이 생성해 NotificationAppCallbacks.ingestRemoteMessagePayload에 연결한다.  
  단어: `Push` 밀어 보냄·푸시 알림. 여기서는 서버가 APNs로 보내는 원격 푸시 메시지 · `Quiz` 퀴즈·문제. 여기서는 프로젝트로부터 생성되는 학습 문제 · `Generation` 생성. 여기서는 서버의 퀴즈 생성 작업 · `Outcome` 결과. 여기서는 생성 완료·실패 상태와 프로젝트 ID · `Source` 원천·공급원. 여기서는 결과 이벤트를 AsyncStream으로 공급하는 객체
- **`PushQuizGenerationOutcomeSource.State`** `struct` · private · [PushQuizGenerationOutcomeSource.swift:42](../../../sources/Projects/Data/LearningProject/Sources/PushQuizGenerationOutcomeSource.swift#L42)  
  PushQuizGenerationOutcomeSource가 Mutex로 보호하는 내부 상태로, 구독 ID(UUID)별 AsyncStream<QuizGenerationOutcomeDTO>.Continuation 사전 continuations 하나만 보유한다.  
  단어(단일): `State` 상태. 여기서는 결과 스트림 구독자 continuation 목록을 담는 내부 가변 상태

## LearningProject/Stores

- **`LocalPendingGenerationStore`** `actor` · public · [LocalPendingGenerationStore.swift:7](../../../sources/Projects/Data/LearningProject/Stores/LocalPendingGenerationStore.swift#L7)  
  KeyValueStorage에 퀴즈 생성 진행 상태(GenerationStateDTO, stateKey)와 미처리 리마인더 목록(pendingGenerationRemindersKey, 최대 32건)을 보관하는 actor로, namespace `com.nexters.hytime.gitit.sharedSession`을 공개한다. state()·stateChanges()(AsyncStream)·modifyState(transform)(저장 후 구독자 broadcast)·appendReminder(projectID, requestedAt)(중복 제거·상한 유지)·drainReminderProjectIDs()를 제공하고 exclusively로 Task를 직렬화하며, Composition의 PendingGenerationRepositoryAdapter·LearningProjectAssembly·ConcernUseCaseAssembly가 사용한다.  
  단어: `Local` 기기 내부·로컬. 여기서는 앱 그룹 KeyValueStorage에 저장되는 기기 내부 데이터 · `Pending` 보류·진행 중. 여기서는 아직 끝나지 않은 퀴즈 생성 작업 · `Generation` 생성. 여기서는 서버의 퀴즈 생성 작업 · `Store` 저장소·보관하는 것. 여기서는 생성 상태와 리마인더 대기 목록을 읽고 쓰는 저장 객체
- **`LocalPendingGenerationStore.ReminderEntry`** `struct` · private · [LocalPendingGenerationStore.swift:68](../../../sources/Projects/Data/LearningProject/Stores/LocalPendingGenerationStore.swift#L68) · 채택: Codable, Sendable  
  LocalPendingGenerationStore가 pendingGenerationRemindersKey 아래 배열로 저장하는 리마인더 항목으로 projectID와 requestedAt(Date)을 보유한다. appendReminder가 추가하고 drainReminderProjectIDs가 projectID만 꺼내 반환한다.  
  단어: `Reminder` 상기시키는 것·알림. 여기서는 퀴즈 생성 완료를 나중에 알려 주기 위해 기록한 리마인더 · `Entry` 항목·기입 한 건. 여기서는 저장 배열의 원소 하나

## LegalConsent/DTOs

- **`PolicyConsentRecordDTO`** `struct` · public · [PolicyConsentRecordDTO.swift:3](../../../sources/Projects/Data/LegalConsent/DTOs/PolicyConsentRecordDTO.swift#L3) · 채택: Codable, Equatable, Sendable  
  약관 문서 하나에 대한 동의 기록으로 documentIdentifier·version·acceptedAt(Date)을 보유하는 Codable 저장 모델이다. LocalPolicyConsentStore가 배열로 저장·조회하고 Composition의 PolicyConsentRepositoryAdapter가 Domain 모델과 상호 변환한다.  
  단어: `Policy` 정책·약관. 여기서는 서비스 이용약관·개인정보 처리방침 같은 법적 문서 · `Consent` 동의. 여기서는 사용자가 해당 문서 버전에 동의한 사실 · `Record` 기록. 여기서는 문서 식별자·버전·동의 시각을 묶은 기록 한 건 · `DTO` Data Transfer Object. 여기서는 KeyValueStorage에 Codable로 저장되는 전송·저장용 구조

## LegalConsent/Layouts

- **`PolicyConsentStorageLayout`** `enum` · public · [PolicyConsentStorageLayout.swift:3](../../../sources/Projects/Data/LegalConsent/Layouts/PolicyConsentStorageLayout.swift#L3)  
  case가 없는 이름 공간용 enum으로 약관 동의 저장소의 namespace 상수 `com.nexters.hytime.gitit.legalConsent`만 공개한다. Composition의 ConcernUseCaseAssembly가 LocalPolicyConsentStore에 넘길 KeyValueStorage를 만들 때 namespace로 사용한다.  
  단어: `Policy` 정책·약관. 여기서는 서비스 이용약관·개인정보 처리방침 같은 법적 문서 · `Consent` 동의. 여기서는 사용자의 약관 동의 · `Storage` 저장 공간. 여기서는 동의 기록이 놓이는 KeyValueStorage · `Layout` 배치·구성. 여기서는 저장소 namespace 같은 저장 위치 규약

## LegalConsent/Stores

- **`LocalPolicyConsentStore`** `struct` · public · [LocalPolicyConsentStore.swift:3](../../../sources/Projects/Data/LegalConsent/Stores/LocalPolicyConsentStore.swift#L3) · 채택: Sendable  
  KeyValueStorage의 `records` 키 아래 [PolicyConsentRecordDTO]를 보관하는 저장 객체로 records()·saveRecord(_:)(같은 documentIdentifier 기록을 교체 후 추가)·removeAll()(storage.removeAllValues)을 제공한다. Composition의 PolicyConsentRepositoryAdapter와 ConcernUseCaseAssembly가 사용한다.  
  단어: `Local` 기기 내부·로컬. 여기서는 기기 내부 KeyValueStorage에 저장되는 데이터 · `Policy` 정책·약관. 여기서는 서비스 이용약관·개인정보 처리방침 같은 법적 문서 · `Consent` 동의. 여기서는 사용자의 약관 동의 기록 · `Store` 저장소·보관하는 것. 여기서는 동의 기록을 읽고 쓰는 저장 객체

## Member/DTOs/APIResponse

- **`APIResponseDTO`** `struct` · public · [APIResponseDTO.swift:1](../../../sources/Projects/Data/Member/DTOs/APIResponse/APIResponseDTO.swift#L1) · 채택: Decodable, Sendable  
  서버 공통 응답 봉투를 표현하는 제네릭 Decodable 구조로 success·data(Payload?)·code·message·errors([FieldErrorDTO]?)를 보유한다. DataMember 모듈에서 MemberRemote가 모든 응답을 APIResponseDTO<Payload>로 디코드하며, DataLearningProject 모듈에도 같은 이름·구조의 별도 타입이 있다.  
  단어: `API` Application Programming Interface. 서버가 제공하는 HTTP 인터페이스 · `Response` 응답. 여기서는 서버가 돌려주는 공통 응답 봉투 · `DTO` Data Transfer Object. 서버 API와 주고받는 전송용 자료 구조
- **`FieldErrorDTO`** `struct` · public · [FieldErrorDTO.swift:1](../../../sources/Projects/Data/Member/DTOs/APIResponse/FieldErrorDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  서버 유효성 오류 한 건을 field(필드 이름)와 message?로 표현하는 Decodable 구조다. DataMember 모듈의 APIResponseDTO.errors와 ServerAPIError.fieldErrors 원소로 쓰이며, DataLearningProject 모듈에도 같은 이름의 별도 타입이 있다.  
  단어: `Field` 필드·항목. 여기서는 서버가 오류를 지적한 요청 본문의 필드 이름 · `Error` 오류. 여기서는 특정 필드에 대한 서버 유효성 검증 오류 · `DTO` Data Transfer Object. 서버 API와 주고받는 전송용 자료 구조

## Member/DTOs

- **`DeviceInfoRequestDTO`** `struct` · public · [DeviceInfoRequestDTO.swift:1](../../../sources/Projects/Data/Member/DTOs/DeviceInfoRequestDTO.swift#L1) · 채택: Encodable, Equatable, Sendable  
  기기 등록 요청 본문으로 deviceID·deviceType·appVersion·osVersion·deviceToken?을 보유하며 CodingKeys로 deviceID를 JSON 키 `deviceId`에 매핑한다. MemberRemote.registerDeviceInfo의 body로 전송되고 Composition의 DeviceRegistrationRepositoryAdapter가 만든다.  
  단어: `Device` 기기·장치. 여기서는 앱이 설치된 iOS 기기 · `Info` Information의 축약, 정보. 여기서는 기기 식별자·종류·앱/OS 버전·푸시 토큰 · `Request` 요청. 여기서는 서버로 보내는 기기 등록 요청 본문 · `DTO` Data Transfer Object. 서버 API와 주고받는 전송용 자료 구조
- **`DeviceInfoRequestDTO.CodingKeys`** `enum` · private · [DeviceInfoRequestDTO.swift:29](../../../sources/Projects/Data/Member/DTOs/DeviceInfoRequestDTO.swift#L29) · 채택: String, CodingKey  
  DeviceInfoRequestDTO의 Encodable 키 매핑 enum으로 deviceID를 `deviceId`로 바꾸고 deviceType·appVersion·osVersion·deviceToken은 이름 그대로 JSON 키로 쓴다.  
  단어(단일): `CodingKeys` Swift Codable이 요구하는 외부 고정 명칭(Coding + Keys). 여기서는 DeviceInfoRequestDTO 속성과 JSON 키의 대응표
- **`EmptyResponseData`** `struct` · internal · [EmptyResponseData.swift:4](../../../sources/Projects/Data/Member/DTOs/EmptyResponseData.swift#L4) · 채택: Decodable, Sendable  
  속성이 없는 Decodable 구조로, 응답 봉투의 data가 비어 있는 API(registerDeviceInfo·curateMember·updatePosition·updateCareerLevel·withdrawMember)의 Payload 자리 표시자이자 실패 응답 봉투를 APIResponseDTO<EmptyResponseData>로 디코드할 때 쓰인다. MemberRemote.payload(from:)는 data가 nil이면 이 값을 대신 반환한다.  
  단어: `Empty` 비어 있는. 여기서는 본문 data가 없는 응답 · `Response` 응답. 여기서는 서버 응답 봉투 · `Data` 자료·데이터. 여기서는 응답 봉투의 data 필드 자리

## Member/DTOs/MemberProfile

- **`MemberProfileResponseDTO`** `struct` · public · [MemberProfileResponseDTO.swift:1](../../../sources/Projects/Data/Member/DTOs/MemberProfile/MemberProfileResponseDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  회원 프로필 조회 응답으로 name·email?·position?·careerLevel?·thisWeekSolvedCount·thisMonthSolvedCount·streakDays·weeklyChart([WeeklyChartItemDTO])를 보유한다. MemberRemote.fetchProfile(GET /api/v1/members/me)이 반환한다.  
  단어: `Member` 회원·구성원. 여기서는 로그인한 Git It 회원 · `Profile` 프로필·개요 정보. 여기서는 이름·이메일·직군·경력과 풀이 통계 · `Response` 응답. 여기서는 프로필 조회 서버 응답 본문 · `DTO` Data Transfer Object. 서버 API와 주고받는 전송용 자료 구조
- **`WeeklyChartItemDTO`** `struct` · public · [WeeklyChartItemDTO.swift:1](../../../sources/Projects/Data/Member/DTOs/MemberProfile/WeeklyChartItemDTO.swift#L1) · 채택: Decodable, Equatable, Sendable  
  주간 풀이 차트의 막대 하나를 dayLabel(요일 라벨)과 count(풀이 수)로 표현하는 Decodable 구조로 MemberProfileResponseDTO.weeklyChart 배열의 원소다.  
  단어: `Weekly` 주 단위의. 여기서는 최근 한 주 풀이 통계 · `Chart` 도표·차트. 여기서는 요일별 풀이 수 막대 차트 · `Item` 항목. 여기서는 차트의 요일 하나에 해당하는 데이터 점 · `DTO` Data Transfer Object. 서버 API와 주고받는 전송용 자료 구조

## Member/DTOs/Preference

- **`CareerLevelDTO`** `struct` · public · [CareerLevelDTO.swift:1](../../../sources/Projects/Data/Member/DTOs/Preference/CareerLevelDTO.swift#L1) · 채택: Codable, Equatable, Sendable  
  경력 수준을 rawValue 문자열 하나로 감싸며 singleValueContainer로 문자열 그대로 인코드·디코드하는 Codable 값이다. CareerLevelRequestDTO·CurationRequestDTO에 포함되고 Composition의 UserInfoRepositoryAdapter가 Domain 값과 변환한다.  
  단어: `Career` 경력·직업 이력. 여기서는 개발 경력 · `Level` 수준·단계. 여기서는 경력 연차 구간을 나타내는 서버 문자열 값 · `DTO` Data Transfer Object. 서버 API와 주고받는 전송용 자료 구조
- **`CareerLevelRequestDTO`** `struct` · public · [CareerLevelRequestDTO.swift:1](../../../sources/Projects/Data/Member/DTOs/Preference/CareerLevelRequestDTO.swift#L1) · 채택: Encodable, Equatable, Sendable  
  경력 수준 변경 요청 본문으로 careerLevel(CareerLevelDTO) 하나를 보유한다. MemberRemote.updateCareerLevel(POST /api/v1/members/me/career-level)의 body이며 UserInfoRepositoryAdapter가 만든다.  
  단어: `Career` 경력·직업 이력. 여기서는 개발 경력 · `Level` 수준·단계. 여기서는 경력 연차 구간 · `Request` 요청. 여기서는 경력 수준 갱신 서버 요청 본문 · `DTO` Data Transfer Object. 서버 API와 주고받는 전송용 자료 구조
- **`CurationRequestDTO`** `struct` · public · [CurationRequestDTO.swift:1](../../../sources/Projects/Data/Member/DTOs/Preference/CurationRequestDTO.swift#L1) · 채택: Encodable, Equatable, Sendable  
  회원 큐레이션(직군·경력 기반 맞춤 설정) 요청 본문으로 position(PositionDTO)과 careerLevel(CareerLevelDTO)을 보유한다. MemberRemote.curateMember(POST /api/v1/members/me/curation)의 body이며 UserInfoRepositoryAdapter가 만든다.  
  단어: `Curation` 선별·맞춤 구성. 여기서는 직군과 경력으로 회원 맞춤 설정을 등록하는 서버 기능 · `Request` 요청. 여기서는 큐레이션 등록 서버 요청 본문 · `DTO` Data Transfer Object. 서버 API와 주고받는 전송용 자료 구조
- **`PositionDTO`** `struct` · public · [PositionDTO.swift:1](../../../sources/Projects/Data/Member/DTOs/Preference/PositionDTO.swift#L1) · 채택: Codable, Equatable, Sendable  
  직군을 rawValue 문자열 하나로 감싸며 singleValueContainer로 문자열 그대로 인코드·디코드하는 Codable 값이다. PositionRequestDTO·CurationRequestDTO에 포함되고 UserInfoRepositoryAdapter가 Domain 값과 변환한다.  
  단어: `Position` 직위·직군. 여기서는 회원의 개발 직군을 나타내는 서버 문자열 값 · `DTO` Data Transfer Object. 서버 API와 주고받는 전송용 자료 구조
- **`PositionRequestDTO`** `struct` · public · [PositionRequestDTO.swift:1](../../../sources/Projects/Data/Member/DTOs/Preference/PositionRequestDTO.swift#L1) · 채택: Encodable, Equatable, Sendable  
  직군 변경 요청 본문으로 position(PositionDTO) 하나를 보유한다. MemberRemote.updatePosition(POST /api/v1/members/me/position)의 body이며 UserInfoRepositoryAdapter가 만든다.  
  단어: `Position` 직위·직군. 여기서는 회원의 개발 직군 · `Request` 요청. 여기서는 직군 갱신 서버 요청 본문 · `DTO` Data Transfer Object. 서버 API와 주고받는 전송용 자료 구조

## Member/Endpoints

- **`MemberEndpoint`** `struct` · public · [MemberEndpoint.swift:3](../../../sources/Projects/Data/Member/Endpoints/MemberEndpoint.swift#L3) · 채택: Equatable, Sendable  
  회원 API 접속 지점을 private init으로 봉인한 뒤 static 상수 fetchProfile(GET /api/v1/members/me)·registerDeviceInfo(POST …/device)·curateMember(POST …/curation)·updatePosition(POST …/position)·updateCareerLevel(POST …/career-level)·withdrawMember(DELETE /api/v1/members/me)로 열거하며 path(public)·transportMethod(internal)와 headers(accessToken:)(Bearer·Accept·Content-Type)를 제공한다. MemberRemote가 HTTPRequest를 만들 때 사용한다.  
  단어: `Member` 회원·구성원. 여기서는 로그인한 Git It 회원과 관련된 서버 자원 · `Endpoint` API 끝점·접속 지점. 여기서는 회원 프로필·기기·큐레이션·탈퇴 서버 API의 메서드·경로·헤더 조합

## Member/Errors

- **`MemberServiceError`** `enum` · public · [MemberServiceError.swift:1](../../../sources/Projects/Data/Member/Errors/MemberServiceError.swift#L1) · 채택: CaseIterable, Equatable, Error, Sendable  
  회원 서버 통신에서 Data 계층이 던지는 오류를 invalidRequest·unauthorized·temporarilyUnavailable·transport·unexpectedStatus·memberUnavailable로 분류하며 init(from: ServerAPIError)가 400·401·404+MEMBER-001·5xx를 case로 매핑한다. MemberRemote가 던지고 Composition의 DeviceRegistration·UserInfo·WithdrawalRepositoryAdapter가 Domain 오류로 변환한다.  
  단어: `Member` 회원·구성원. 여기서는 로그인한 Git It 회원 · `Service` 서비스·서버 측 기능. 여기서는 회원 서버 API 서비스 · `Error` 오류. 여기서는 서버 응답·전송 실패를 Data 언어로 분류한 오류
- **`ServerAPIError`** `struct` · public · [ServerAPIError.swift:1](../../../sources/Projects/Data/Member/Errors/ServerAPIError.swift#L1) · 채택: Equatable, Error, Sendable  
  서버가 실패 응답 봉투로 돌려준 httpStatus·code·message·fieldErrors([FieldErrorDTO]?)를 그대로 담는 오류 값이다. MemberRemote.serverError가 raw 응답을 디코드해 만들고 MemberServiceError(from:)의 입력이 되며, DataLearningProject 모듈에도 같은 이름·구조의 별도 타입이 있다.  
  단어: `Server` 서버. 여기서는 Git It 백엔드 API 서버 · `API` Application Programming Interface. 서버가 제공하는 HTTP 인터페이스 · `Error` 오류. 여기서는 서버가 응답 본문으로 알린 상태 코드·오류 코드·메시지 묶음

## Member/Remotes

- **`MemberRemote`** `struct` · public · [MemberRemote.swift:7](../../../sources/Projects/Data/Member/Remotes/MemberRemote.swift#L7) · 채택: Sendable  
  회원 서버 통신을 담당하는 원격 접근 타입으로 public init은 baseURL·transport·responseTimeout·credential·credentialRejected로 HTTPClient를 만들고, fetchProfile·registerDeviceInfo·curateMember·updatePosition·updateCareerLevel·withdrawMember를 제공한다. 내부 send가 MemberEndpoint를 HTTPRequest로 바꿔 APIResponseDTO 봉투를 해석하고 ServerAPIError·HTTPClientError를 MemberServiceError로 변환하며 unauthorized면 credentialRejected를 호출한다. Composition의 Member 어댑터들과 MemberAssembly가 사용한다.  
  단어: `Member` 회원·구성원. 여기서는 로그인한 Git It 회원 · `Remote` 원격·서버 측. 여기서는 회원 서버 API를 호출하는 원격 데이터 접근 객체

## Member/Stores

- **`LocalDeviceIdentifierStore`** `struct` · public · [LocalDeviceIdentifierStore.swift:6](../../../sources/Projects/Data/Member/Stores/LocalDeviceIdentifierStore.swift#L6) · 채택: Sendable  
  SecureValueStorage에 기기 식별자를 보관하는 저장 객체로 namespace `com.nexters.hytime.gitit.device`와 key `deviceID`를 공개하고, loadOrCreate()가 저장된 UTF-8 문자열을 돌려주거나 없으면 UUID 문자열을 새로 만들어 저장 후 반환한다. Composition의 DeviceIdentifierRepositoryAdapter가 사용한다.  
  단어: `Local` 기기 내부·로컬. 여기서는 기기 내부 보안 저장소(SecureValueStorage)에 저장되는 데이터 · `Device` 기기·장치. 여기서는 앱이 설치된 iOS 기기 · `Identifier` 식별자. 여기서는 기기를 구분하기 위해 앱이 생성한 UUID 문자열 · `Store` 저장소·보관하는 것. 여기서는 기기 식별자를 읽고 생성·저장하는 저장 객체

## Notification/AppDelegates

- **`NotificationAppDelegate`** `class` · public · [NotificationAppDelegate.swift:7](../../../sources/Projects/Data/Notification/AppDelegates/NotificationAppDelegate.swift#L7) · 채택: NSObject, UIApplicationDelegate  
  @MainActor UIApplicationDelegate로 InfrastructurePushMessaging의 PushMessagingAppDelegate를 base로 감싸며, configure(NotificationAppCallbacks)에서 forwardDeviceToken·ingestRemoteMessagePayload를 PushNotificationCallbacks로 변환해 넘기고 didFinishLaunching·didRegisterForRemoteNotificationsWithDeviceToken·didReceiveRemoteNotification을 base로 위임한다. Composition은 typealias PushNotificationAppDelegate로 노출한다.  
  단어: `Notification` 알림. 여기서는 APNs 원격 푸시 알림 · `App` Application의 축약, 앱. 여기서는 UIApplication 수명 주기 · `Delegate` 위임 객체. 여기서는 UIApplicationDelegate 콜백을 받는 객체

## Notification/Clients

- **`ReminderNotificationClient`** `struct` · internal · [ReminderNotificationClient.swift:6](../../../sources/Projects/Data/Notification/Clients/ReminderNotificationClient.swift#L6) · 채택: LocalReminderNotifier  
  InfrastructureLocalNotification의 NotificationAuthorizationClient를 감싸 LocalReminderNotifier를 구현하는 내부 타입으로, 권한 요청·조회 결과를 ReminderAuthorizationStatus·ReminderAuthorizationSetting으로 매핑하고 schedule은 ReminderNotification을 LocalNotificationRequest로 변환해 예약하며 cancel(identifier:)를 위임한다. NotificationFactory.localReminderNotifier()가 생성한다.  
  단어: `Reminder` 상기시키는 것·알림. 여기서는 퀴즈 생성 완료 등을 나중에 알려 주는 로컬 리마인더 · `Notification` 알림. 여기서는 iOS 로컬 알림 · `Client` 클라이언트·이용 주체. 여기서는 Infrastructure 로컬 알림 API를 호출하는 객체
- **`RemoteMessageClient`** `struct` · internal · [RemoteMessageClient.swift:6](../../../sources/Projects/Data/Notification/Clients/RemoteMessageClient.swift#L6) · 채택: RemoteMessageReceiver  
  InfrastructurePushMessaging의 PushMessagingClient(기본값 PushMessagingClientFactory.make())를 감싸 RemoteMessageReceiver를 구현하는 내부 타입으로 registrationToken()·registrationTokenRefreshes()를 위임하고 setDeviceToken(Data)은 pushClient.setAPNsToken을 호출한다. NotificationFactory.remoteMessageReceiver()가 생성한다.  
  단어: `Remote` 원격. 여기서는 서버에서 기기로 오는 원격 푸시 · `Message` 메시지. 여기서는 푸시 메시징 서비스의 등록 토큰과 메시지 수신 · `Client` 클라이언트·이용 주체. 여기서는 Infrastructure 푸시 메시징 API를 호출하는 객체

## Notification/Contracts

- **`LocalReminderNotifier`** `protocol` · public · [LocalReminderNotifier.swift:5](../../../sources/Projects/Data/Notification/Contracts/LocalReminderNotifier.swift#L5) · 채택: Sendable  
  로컬 리마인더 알림의 기술 이름 없는 역할 계약으로 requestAuthorization()→ReminderAuthorizationStatus·isAuthorized()·authorizationSetting()→ReminderAuthorizationSetting·schedule(_ reminder: ReminderNotification, at: Date)·cancel(identifier:)를 요구한다. ReminderNotificationClient가 구현하고 Composition의 GenerationReminderSchedulerAdapter·NotificationAuthorizationAdapter·ShareExtensionComposition이 사용한다.  
  단어: `Local` 기기 내부·로컬. 여기서는 기기 자체에서 예약·발송하는 로컬 알림 · `Reminder` 상기시키는 것·알림. 여기서는 퀴즈 생성 완료 등을 알려 주는 리마인더 · `Notifier` 알리는 것·통지자. 여기서는 알림 권한과 예약·취소를 담당하는 역할
- **`RemoteMessageReceiver`** `protocol` · public · [RemoteMessageReceiver.swift:5](../../../sources/Projects/Data/Notification/Contracts/RemoteMessageReceiver.swift#L5) · 채택: Sendable  
  원격 푸시 메시지 수신 측의 기술 이름 없는 역할 계약으로 registrationToken() async throws→String·registrationTokenRefreshes()→AsyncStream<String>·setDeviceToken(Data)를 요구한다. RemoteMessageClient가 구현하고 Composition의 AppComposition이 사용한다.  
  단어: `Remote` 원격. 여기서는 서버에서 기기로 오는 원격 푸시 · `Message` 메시지. 여기서는 푸시 메시징 등록 토큰과 수신 메시지 · `Receiver` 수신자. 여기서는 등록 토큰을 제공하고 APNs 기기 토큰을 받아들이는 역할

## Notification/Factories

- **`NotificationFactory`** `enum` · public · [NotificationFactory.swift:5](../../../sources/Projects/Data/Notification/Factories/NotificationFactory.swift#L5)  
  case가 없는 생성 진입점 enum으로 localReminderNotifier()는 LocalNotificationAuthorizationClient를 주입한 ReminderNotificationClient를, remoteMessageReceiver()는 RemoteMessageClient()를 각각 역할 계약 타입으로 반환한다. Composition의 AppComposition·ConcernUseCaseAssembly·LearningProjectAssembly가 사용한다.  
  단어: `Notification` 알림. 여기서는 로컬 리마인더 알림과 원격 푸시 메시지 · `Factory` 공장·생성기. 여기서는 Infrastructure 구현을 숨기고 역할 계약 구현체를 만드는 진입점

## Notification/Models

- **`NotificationAppCallbacks`** `struct` · public · [NotificationAppCallbacks.swift:5](../../../sources/Projects/Data/Notification/Models/NotificationAppCallbacks.swift#L5) · 채택: Sendable  
  앱 델리게이트가 호출할 콜백 두 개, forwardDeviceToken((Data) -> Void)과 ingestRemoteMessagePayload(([String: String]) async -> Void)를 묶은 값이다. AppComposition이 만들어 NotificationAppDelegate.configure에 넘긴다.  
  단어: `Notification` 알림. 여기서는 APNs 원격 푸시 알림 · `App` Application의 축약, 앱. 여기서는 UIApplicationDelegate 수준의 앱 이벤트 · `Callbacks` 되부름·콜백 함수들. 여기서는 기기 토큰 전달과 원격 메시지 payload 반입 클로저
- **`ReminderAuthorizationSetting`** `enum` · public · [ReminderAuthorizationSetting.swift:3](../../../sources/Projects/Data/Notification/Models/ReminderAuthorizationSetting.swift#L3) · 채택: Equatable, Sendable  
  현재 알림 권한 설정 상태를 notDetermined·authorized·denied 세 case로 표현한다. LocalReminderNotifier.authorizationSetting()의 반환값이며 ReminderNotificationClient가 Infrastructure 값에서 매핑한다.  
  단어: `Reminder` 상기시키는 것·알림. 여기서는 로컬 리마인더 알림 · `Authorization` 권한 부여·허가. 여기서는 iOS 알림 권한 · `Setting` 설정·현재 설정 값. 여기서는 사용자가 정해 둔 알림 권한 상태
- **`ReminderAuthorizationStatus`** `enum` · public · [ReminderAuthorizationStatus.swift:3](../../../sources/Projects/Data/Notification/Models/ReminderAuthorizationStatus.swift#L3) · 채택: Equatable, Sendable  
  알림 권한 요청의 결과를 authorized·declined·previouslyDenied 세 case로 표현한다. LocalReminderNotifier.requestAuthorization()의 반환값이며 ReminderNotificationClient가 Infrastructure 값에서 매핑한다.  
  단어: `Reminder` 상기시키는 것·알림. 여기서는 로컬 리마인더 알림 · `Authorization` 권한 부여·허가. 여기서는 iOS 알림 권한 요청 · `Status` 상태·결과. 여기서는 권한 요청 직후의 허용·거절·이전 거부 결과
- **`ReminderNotification`** `struct` · public · [ReminderNotification.swift:3](../../../sources/Projects/Data/Notification/Models/ReminderNotification.swift#L3) · 채택: Equatable, Sendable  
  예약할 로컬 리마인더 알림의 내용을 identifier·title·body로 표현하는 값이다. LocalReminderNotifier.schedule(_:at:)의 입력이며 Composition의 GenerationReminderSchedulerAdapter가 만들고 ReminderNotificationClient가 LocalNotificationRequest로 변환한다.  
  단어: `Reminder` 상기시키는 것·알림. 여기서는 퀴즈 생성 완료 등을 알려 주는 리마인더 · `Notification` 알림. 여기서는 iOS 로컬 알림 한 건의 식별자·제목·본문

## Shared/Contracts

- **`KeyValueStorage`** `protocol` · public · [KeyValueStorage.swift:3](../../../sources/Projects/Data/Shared/Contracts/KeyValueStorage.swift#L3) · 채택: Sendable  
  Codable & Sendable 값을 문자열 키로 비동기 조회(value)·저장(setValue)·삭제(removeValue)·전체 삭제(removeAllValues)하는 키-값 저장소 계약이다. Data의 LocalPendingGenerationStore·LocalPolicyConsentStore·SharedSessionStateMarkerCoding과 Composition 어셈블리가 sharedStorage 등으로 주입받아 사용한다.  
  단어: `Key` 키·식별자. 여기서는 값을 찾는 문자열 키(forKey) · `Value` 값. 여기서는 키에 대응해 저장되는 Codable & Sendable 값 · `Storage` 저장소. 여기서는 키-값 저장·조회·삭제 동작을 정의하는 계약
- **`RequestTransport`** `protocol` · public · [RequestTransport.swift:3](../../../sources/Projects/Data/Shared/Contracts/RequestTransport.swift#L3) · 채택: Sendable  
  TransportRequest를 받아 TransportResponse를 돌려주는 send 메서드 하나를 정의하며 실패는 RequestTransportError로 typed throw하는 전송 계층 계약이다. Composition 어셈블리와 Data Remote들이 선택적으로 주입받고, RequestClientFactory가 RequestTransportBridge로 감싸 HTTPClient의 전송 계층으로 사용한다.  
  단어: `Request` 요청. 여기서는 서버로 보낼 네트워크 요청 · `Transport` 전송·운반. 여기서는 요청을 보내고 응답을 받아오는 전송 계층
- **`SecureValueStorage`** `protocol` · public · [SecureValueStorage.swift:5](../../../sources/Projects/Data/Shared/Contracts/SecureValueStorage.swift#L5) · 채택: Sendable  
  Data를 문자열 키로 동기 조회(data)·저장(setData)·삭제(removeData)하며 실패를 SecureValueStorageError로 typed throw하는 보안 저장소 계약이다. Composition의 Authentication·Member 어셈블리와 어댑터가 세션·Apple identity·디바이스 식별자 보관용 secureStorage로 주입받아 사용한다.  
  단어: `Secure` 안전한·보안의. 여기서는 Keychain 같은 보안 영역에 보관되는 · `Value` 값. 여기서는 키로 보관되는 Data 값 · `Storage` 저장소. 여기서는 보안 값의 저장·조회·삭제 동작을 정의하는 계약

## Shared/Errors

- **`RequestTransportError`** `enum` · public · [RequestTransportError.swift:3](../../../sources/Projects/Data/Shared/Errors/RequestTransportError.swift#L3) · 채택: Error, Equatable, Sendable  
  cancelled·timedOut·connectionFailed 세 케이스를 가지는 RequestTransport.send의 typed throw 오류다. RequestTransportBridge가 이 값을 InfrastructureNetworkClient의 HTTPClientError로 1:1 변환한다.  
  단어: `Request` 요청. 여기서는 전송 중이던 네트워크 요청 · `Transport` 전송. 여기서는 RequestTransport 전송 계층 · `Error` 오류. 여기서는 전송 계층에서 발생하는 취소·시간 초과·연결 실패
- **`SecureValueStorageError`** `enum` · public · [SecureValueStorageError.swift:3](../../../sources/Projects/Data/Shared/Errors/SecureValueStorageError.swift#L3) · 채택: Error, Equatable, Sendable  
  unavailable 단일 케이스만 가지는 SecureValueStorage 메서드의 typed throw 오류다. LocalSecureValueStorage가 KeychainStore의 load·save·delete 실패를 모두 이 값으로 바꿔 던진다.  
  단어: `Secure` 안전한·보안의. 여기서는 Keychain 기반 보안 저장소 · `Value` 값. 여기서는 보안 저장소에 보관되는 Data 값 · `Storage` 저장소. 여기서는 SecureValueStorage 계약 · `Error` 오류. 여기서는 보안 저장소를 사용할 수 없음을 나타내는 오류

## Shared/Factories

- **`RequestClientFactory`** `enum` · public · [RequestClientFactory.swift:6](../../../sources/Projects/Data/Shared/Factories/RequestClientFactory.swift#L6)  
  케이스 없는 네임스페이스 enum으로, public defaultResponseTimeout(HTTPClient.defaultResponseTimeout)과 package makeClient(baseURL:transport:responseTimeout:)를 제공한다. makeClient는 StandardJSONBodyCoding으로 HTTPClient를 만들고 transport가 주어지면 RequestTransportBridge로 감싸 주입하며, Data의 AnswerRemote·ProjectRemote·BookmarkRemote·LearningSetRemote 등이 호출한다.  
  단어: `Request` 요청. 여기서는 서버로 보내는 HTTP 요청 · `Client` 클라이언트·의뢰자. 여기서는 InfrastructureNetworkClient의 HTTPClient · `Factory` 공장·생성기. 여기서는 정적 메서드로 HTTPClient 인스턴스를 만드는 네임스페이스
- **`StorageFactory`** `enum` · public · [StorageFactory.swift:7](../../../sources/Projects/Data/Shared/Factories/StorageFactory.swift#L7)  
  namespace와 StorageLocation을 받아 KeyValueStorage(UserDefaultsStore 기반 LocalKeyValueStorage, 만들 수 없으면 UnavailableKeyValueStorage)와 SecureValueStorage(KeychainStore 기반 LocalSecureValueStorage)를 만드는 정적 팩터리 enum이다. appGroup이면 AppGroupUserDefaults·AppGroupKeychainStore의 공유 인스턴스를, device면 기본 UserDefaultsStore·KeychainStore를 쓰며 Composition 어셈블리들이 호출한다.  
  단어: `Storage` 저장소. 여기서는 KeyValueStorage와 SecureValueStorage 구현체 · `Factory` 공장·생성기. 여기서는 위치와 네임스페이스에 맞는 저장소 인스턴스를 만드는 정적 메서드 모음

## Shared/Models

- **`RequestCredential`** `enum` · public · [RequestCredential.swift:3](../../../sources/Projects/Data/Shared/Models/RequestCredential.swift#L3) · 채택: Equatable, Sendable  
  available(String)과 signedOut 두 케이스로 요청에 붙일 자격 증명의 유무를 나타낸다. RequestCredentialProvider가 반환하고 Data Remote들(LearningProjectRequestExecutor, AuthenticationRemote, MemberRemote 등)이 credential 클로저로 받아 available의 문자열을 액세스 토큰으로 Authorization 헤더에 쓴다.  
  단어: `Request` 요청. 여기서는 인증이 필요한 서버 요청 · `Credential` 자격 증명. 여기서는 요청에 첨부할 액세스 토큰과 로그아웃 상태
- **`StorageLocation`** `enum` · public · [StorageLocation.swift:3](../../../sources/Projects/Data/Shared/Models/StorageLocation.swift#L3) · 채택: Sendable  
  appGroup과 device 두 케이스로 저장소를 만들 영역을 지정한다. StorageFactory가 이 값에 따라 App Group 공유 UserDefaults·Keychain을 쓸지 앱 기본 UserDefaults·Keychain을 쓸지 분기한다.  
  단어: `Storage` 저장소. 여기서는 StorageFactory가 만드는 UserDefaults·Keychain 저장소 · `Location` 위치·장소. 여기서는 저장소가 놓이는 영역(App Group 공유 컨테이너 또는 기기의 앱 기본 영역)
- **`TransportRequest`** `struct` · public · [TransportRequest.swift:5](../../../sources/Projects/Data/Shared/Models/TransportRequest.swift#L5) · 채택: Equatable, Sendable  
  url·headerFields([String: String])·body(Data?)를 보유하는 전송 계층 요청 값이다. RequestTransport.send의 입력이며 RequestTransportBridge가 HTTPTransportRequest의 URL·헤더·본문을 옮겨 만든다.  
  단어: `Transport` 전송. 여기서는 RequestTransport 전송 계층 · `Request` 요청. 여기서는 전송 계층이 보내는 URL·헤더·본문 묶음
- **`TransportResponse`** `struct` · public · [TransportResponse.swift:5](../../../sources/Projects/Data/Shared/Models/TransportResponse.swift#L5) · 채택: Equatable, Sendable  
  statusCode(Int)·headerFields(기본값 빈 사전)·body(Data)를 보유하는 전송 계층 응답 값이다. RequestTransport.send의 반환값이며 RequestTransportBridge가 HTTPHeaders로 옮겨 HTTPTransportResponse로 변환한다.  
  단어: `Transport` 전송. 여기서는 RequestTransport 전송 계층 · `Response` 응답. 여기서는 전송 계층이 돌려주는 상태 코드·헤더·본문 묶음

## Shared/Remotes

- **`RequestTransportBridge`** `struct` · package · [RequestTransportBridge.swift:5](../../../sources/Projects/Data/Shared/Remotes/RequestTransportBridge.swift#L5) · 채택: HTTPTransport  
  any RequestTransport를 보유하고 InfrastructureNetworkClient의 HTTPTransport로 적응시키는 어댑터다. send에서 HTTPTransportRequest를 TransportRequest로, TransportResponse를 HTTPTransportResponse로, RequestTransportError를 HTTPClientError로 변환하며 RequestClientFactory.makeClient가 생성한다.  
  단어: `Request` 요청. 여기서는 네트워크 요청 · `Transport` 전송. 여기서는 Data의 RequestTransport 계약 · `Bridge` 다리·연결. 여기서는 RequestTransport와 Infrastructure의 HTTPTransport 두 계약을 잇는 어댑터

## Shared/Stores

- **`LocalKeyValueStorage`** `struct` · internal · [LocalKeyValueStorage.swift:6](../../../sources/Projects/Data/Shared/Stores/LocalKeyValueStorage.swift#L6) · 채택: KeyValueStorage  
  UserDefaultsStore를 보유하는 KeyValueStorage 구현으로, 값을 JSONEncoder로 Data로 바꿔 저장하고 JSONDecoder로 되돌려 조회하며 인코딩 실패 시 저장을 건너뛰고 디코딩 실패 시 nil을 돌려준다. StorageFactory.keyValueStorage(store:)가 생성한다.  
  단어: `Local` 지역의·로컬. 여기서는 기기 안 UserDefaults에 저장하는 구현 · `Key` 키. 여기서는 UserDefaultsStore에 넘기는 문자열 키 · `Value` 값. 여기서는 JSON으로 인코딩·디코딩되는 Codable 값 · `Storage` 저장소. 여기서는 KeyValueStorage 계약의 구현체
- **`LocalSecureValueStorage`** `struct` · internal · [LocalSecureValueStorage.swift:6](../../../sources/Projects/Data/Shared/Stores/LocalSecureValueStorage.swift#L6) · 채택: SecureValueStorage  
  namespace 문자열을 KeychainNamespace로 감싸고 KeychainStore로 Data를 load·save·delete하는 SecureValueStorage 구현이며, 모든 Keychain 오류를 SecureValueStorageError.unavailable로 바꿔 던진다. StorageFactory.secureValueStorage가 생성한다.  
  단어: `Local` 지역의·로컬. 여기서는 기기 Keychain에 저장하는 구현 · `Secure` 안전한·보안의. 여기서는 Keychain 보안 영역 · `Value` 값. 여기서는 Keychain에 보관되는 Data · `Storage` 저장소. 여기서는 SecureValueStorage 계약의 구현체
- **`UnavailableKeyValueStorage`** `struct` · internal · [UnavailableKeyValueStorage.swift:3](../../../sources/Projects/Data/Shared/Stores/UnavailableKeyValueStorage.swift#L3) · 채택: KeyValueStorage  
  조회는 항상 nil을 돌려주고 저장·삭제·전체 삭제는 아무 것도 하지 않는 KeyValueStorage의 no-op 구현이다. StorageFactory가 UserDefaultsStore를 만들 수 없을 때(App Group UserDefaults가 nil일 때) 대체 저장소로 반환한다.  
  단어: `Unavailable` 사용 불가한. 여기서는 실제 저장소를 만들 수 없는 상태를 대신하는 무동작 구현 · `Key` 키. 여기서는 무시되는 문자열 키 · `Value` 값. 여기서는 저장되지 않고 버려지는 값 · `Storage` 저장소. 여기서는 KeyValueStorage 계약의 대체 구현체
